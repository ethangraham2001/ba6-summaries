# Lecture 07: Query Processing I

## Steps in query processing

(From highest level to the lowest)

(SQL Query)
- **Parse and rewrite query**
- **Select logical plan:** generates parse tree which is nodes that "look like"
relational algebra.
- **Select physical plan:** similar to logical plan, but also include 
implementation details
- Query execution
(Disk)

### Physical query plan

Processing model for operators (scheduling decisions). Pipelines execution,
materializes intermediate tuples. Various implementation details for all
operators, and the physical query plan selects the best one.

### Processing model

The DBMS processing model defines how the system executes a query plan.

- Iterator model (volcano, pipelined)
- Materialization model

## Iterator model (Lazy)

Operators implement a `Next()` api. On each invocation, will return either a
tuple of an `EOF`. The operator should be able to call `Next()` on their 
children until they return, retrieve their tuples and process them. Calling
`Next()` on the children **returns a single tuple.**

Operators should also implement `Open()` and `Close()` apis.

### Pros

- Pull-based which means no synchronization issues
- Can save cost of immediately writing to data
- Can save cost of reading intermediate data from disk
- Early output: can start providing output to the caller immediately
- Flexible, easily supports complex queries with nested operations

### Cons

- Execution overhead: each tuple fetch can involve repeated function calls
and context switches.

It is used by almost every DBMS. A problem with it is that many operators 
block until their children have emitted **all** tuples.

## Materialization model (Eager)

Each operator processes its inputs all at once and then emits output all at 
once. This allows DBMS to push down hints (like `LIMIT`) to avoid scanning too
many tuples. 

We can think of this as an `Output()` api, which **returns all tuples at once**.

This model is better for transaction processing workloads, because queries only
access a small number of tuples at a time.

### Pros

- Lower execution / coordination overhead and fewer function calls
- Potential optimizations can be unlocked if we have access to the entire
intermediate result.

### Cons

- High memory usage, since large intermediate results need to be stored in 
memory
- Latency, since we must wait for each operation to complete before moving on

## Physical query plan

- **Top-down:** Start at the root and pull data up from children. Tuples are
always passed with function calls
- **Bottom-up:** Start with leaf nodes and push data up to the parents. Allows
for tigher control of caches and registers in pipelines, and is more amenable 
dynamic query re-optimization.

We now go over how we can implement and optimize relational-algebra operators.
**The metric we optimize for is IO cost.**

### Access methods

Three basic approaches

- sequential scan
- index scan
- multi-index scan, use multiple indexes on a set of tables

### Simple selection

Assume the following SQL query, for example. Which is a range query. We want to
optimize this for disk IO, as this will be the dominant factor in the overall
execution time.

```sql
SELECT * 
    FROM Reserves R
    WHERE R.rname < 'C%'
```

The best approach to follow depends on available indexes, available access 
paths, as well as the expected size of the output (measured in number of tuples
or number of pages). We approximate the output size as **the size of R times
a reduction factor**, which is also known as selectivity.

- **No index, unsorted:** must scan the whole relation, thus the IO cost is as
many pages that exist in the table.
- **No index, sorted:** Cost of binary search + number of pages containing the 
results. This case is rare; an index will likely exist in this case.
- **Index on selection attribute:** Use index to find qualifying data entries,
retrieve corresponding records.

#### Clustered vs. unclustered

Assume an example, with the same SQL query as previously, and assume that 10% 
of tuples qualify for the selection. Assuming 100'000 total tuples, that makes
10'000. And lets also assume 1K total pages.

- In the clustered case, since everything is sorted, the 10'000 tuples fit on 
100 contiguous pages. Therefore the total IO cost is a little over 100 
considering the $B^+$ tree lookup.
- In the unclustered case, since we are looking up the tuples in-order by 
reading through the $B^+$ tree, we un up reading up to 10'000 pages (i.e. 
random access).

#### Optimization for the unclustered case

We locate all of the qualifying data entries by reading the index, and them 
**sort based on the selected attribute**. This optimization means that we only
read every qualifying data page once.

### General selection

This is a combination of some conditions. For example
`(age < 25 AND rname = "Paul") OR bid = 5 OR sid = 3`. We want to convert this
into CNF (conjunctive normal form) so that we can push the predicates lower 
down into the individual sub-queries $\rightarrow$ we can perform 
selections/projections sooner, and thus have smaller amounts of data to work 
with.

- A B+ tree **matches** a conjunction of terms that involve only attributes in
a prefix of the search key. For example an index on `<a, b, c>` matches 
`a=5 AND b=5` but not `b=3`.
- A hash index must have all attributes in search keys

#### First approach

Similar to using an index for simple selection

1. Pick a set of conjuncts with a matching index
2. retrieve tuples using it
3. Apply the conjuncts that do not match the index (if any)

If we use the example `(age < 25 AND rname = "Paul") OR bid = 5 OR sid = 3`

- Simplest approach is to scan and check each tuple
- Another approach is to use a B+Tree on `day`, then check 

#### Second approach

Asssume we have two or more matching indexes. This is better for unclustered
indexes than the first approach!

1. Get `rid`s of data records matching each index
2. Insersect the sets of `rid`s
3. Retrieve the records and apply any remaining terms

### Important note

B+Trees on strings, such as names, are generally a pretty terrible idea. It
means that we have to generate all possible strings.

## Projection

Consider the example 

```sql
SELECT DISTINCT
    R.sid, R.bid
FROM Reserves R
```

We need to be removing duplicates here! This is quite a challenge... Naively,

- Scan `R`, extract only needed attributes
- Sort the resulting set
- Remove adjacent duplicates

Assuming that there are, for example, 1000 pages, and that only 25% of them 
qualify, we a cost of 

- 1000 pages read
- 250 pages written back
- 2 * 2 * 250 IOs for sorting
- 250 reads again for duplicate removal

This results in a total cost of 2500 IOs.

### Optimization 1: project on the fly

We can modify the general external merge sort algorithm Pass 0 (as seen 
previously) to get of unwanted fields on the fly. Assuming 20 buffer pages and
the same selectivity as before

- 1000 pages read (unchanged)
- Write out 250 pages in ~13 runs of 250 IOs with the projections
- Merge 13 runs (250 IOs)

This yields 1500 IOs, which is better than before.

### Optimization 2: use hashing

This requires that enough buffer memory be available. We leverage two-phases:
one for partitioning and one for duplicate removal

#### Partitioning phase

- Read `R` using one input buffer
- For each tuple, discard any unwanted fields and apply a hash function `h1` to 
choose one of `B-1` output buffers

This will result in `B-1` partitions of tuples with no unwanted fields. From 
there

#### Duplicate removal phase

- For each partition, read it and build an in-memory hash table. Use a 
different hash function `h2`, s.t. `h2 != h1` on all fields. Discard duplicates
during this phase by matching results.
- If partition does not fit into memory, apply hash-based algorithm recursively
to this partition.

The number of pages per partition, assuming that `h1` distributes uniformly, is
`T / (B-1)` where `T` is the number of pages after projection. We can make the
further assumption that `B >= T / (B-1)` for simplicity, which means that every 
partition fits into memory. This yields a cost of

- 1000 pages read
- Write partitions of projected tuples in 250 IOs
- Perform duplication elimination on each partition in 250 IOs

Total: 1500 IOs.

### Final notes on projection

The sort-based approach is standard as it handles skewed data efficiently, and
the result is sorted. If all wanted attributes are indexed, then we can just use
an index-only scan.

## Joins

In this lecture, we only go over one-pass algorithms. The next lecture covers
more elaborate algorithms.

Let

- $M$ pages in `R`, $p_R$ tuples per page
- $N$ pages in `S`, $p_S$ tuples per page

### Simple Nested Loops Join (SNLJ)

For reach tuple in the outer relation `R`, scan the entire inner relation `S`.
This yields a cost of

$$
M + M \times p_R \times N
$$

We process every tuple of `R`, and for every tuple in it we read `N` in its 
entirety. (Note that here we are ignoring CPU and writing output cost).

> The entirety of the inner table is read for every single tuple in the outer
table. This is very inefficient.

This approach is very expensive. **We also note here that the choice of
outer and inner relations is very important, and has a huge impact on the total
IO cost!!**

### Page-oriented Nested Loops Join

Process on page-by-page basis rather than tuple-by-tuple. For each page in `R`,
get each page in `S`, and write out matching pairs of tuples `<r, s>`.

The cost of this is

$$
M + M \times N
$$

> The outer table is read by page, meaning that the inner table only has to be
read in its entirety once per page instead of once per tuple! Significantly
reduces IO

### Block Nested Loop Joins (BLNJ)

Page oriented nested loop does not exploit extra buffers, so the idea here is
to use one page for input, one for output, and the remaining to fetch outer 
block from `R`. This is just a generalization of page-oriented nested loops.

The cost is

$$
M \times num_{blocks \; outer} \times N(inner \; scan)
$$

> since the outer table is read by block, the inner table has to be read 
entirely once per block instead of once per page! Vastly reduces IO

### Hash Join

We scan `R`, and build buckets in main memory. We then scan `S`, probe, and 
join.

The cost is that of the outer scan, then that of the inner scan. Thus 

$$
M + N
$$

This does however assume that we have enough available memory to store $M$ plus
the hash table.

### Sort Merge Join

Scan `R` and sort in main memory, then do the same with `S`. We then merge the 
two. The cost is the same as for a hash join

$$
M + N
$$

This assumes that if we want to do this in a single pass that we must be able
to store `R` and `S` in memory. In general this is not the case, and thus it 
usually is not a one-pass algorithm.

