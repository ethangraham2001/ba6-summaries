# Lecture 08: Query Processing II

## Index Nested Loops Join (INLJ)

We spoke in the previous lecture about the simple nested loop join. This is 
very similar to that, but we leverage the fact that an index exists on one of
the relation (which we make the inner relation) to amortize the cost scanning
the whole relation. This yields a cost of 

$$
M + M \times p_R \times search \; cost
$$

Where the search cost is the cost of finding tuples in `S` that are such that
`r_i == s_j`. Since the cost of finding these tuples is less than $N$, this
is normally better SNLJ.

- Clustered index: One IO per page of matching `S` tuples
- Unclustered index: can be as high as One IO per matching S tuple, which is
no better than the simple nested loop join.

### When to use it?

INLJ is particularly good for highly selective queries, because a scan can 
filter out most tuples in the relation, vastly reducing the IOs needed.

## Recap: Two-phase hash join

### Phase 1: partitioning

Read the whole `R` and `S` relations, and build a hash on it with `h_1()` which
creates partitions that are written to disk. There will be $B-1$ such 
partitions, with $B$ the number of slots in the buffer.

### Phase 2: matching

Read $R_1$, the first partition of `R` relation, and build a hash index on it
with `h_2() != h_1`. We then read $S_1$ page-by-page, and use the hash index to 
find matches.

We repeat for $R_2, S_2$ etc...

### Total cost

$$
3 \times (M + N)
$$

- In partitioning phase, we read and write both relations yielding 
$2 \times (M + N)$
- In matching phase, we read and write both relations

We note that we need each $R_i < B-1$ for the second phase to fit into memory.
We get a relation

$$
f \times M / (B-1) \leq B-2
$$

Where $f$ is the fudge factor (accounts for uneven distributions of partition
sizing). The $B-2$ comes from the fact that wehave one page for $S_i$,
one page for the output, and the rest for $R_i$ partitions.

### Problems with hash joining

- Requires partitions to fit in memory. If this isn't satisfied, we can do
recursive partitioning, although this is rarely used
- If hash function isn't great, we can get hash table overflow. To avoid it,
use a better hash function. To resolve it, repartition using a different hash
function.

## Hybrid hash join algorithm

- This is a generalization of the previous case. We partition `S` into $k$ 
buckets, with $t$ of them staying in memory and the rest going to disk.

- We partition `R` into $k$ buckets, the first $t$ buckets join with `S` 
immediately, and the remaining $k - t$ go to disk. 

We can finally join the remaining $k - t$ buckets.

$$
(R_{t + 1}, S_{t + 1}), \dots (R_k, S_k)
$$

### Implication

We can fit $t$ partitions in memory that we don't have to write back to disk,
which reduces IO cost.

### Choosing $k$ and $t$

- $k$ large, but satisfying $k \leq B$ (one page per bucket in memory)
- $\frac t k$ large but satisfying $\frac t k \times N \leq B$ (first $t$ 
buckets in memory)
- Together: $\frac t k \times N + k - t \leq B$

### Cost

Grace join cost is $3 (M + N)$. In the hybrid join case, we save 2 IO for
$\frac t k$ fraction of buckets $\rightarrow$ we save
$2 \frac t k (M + N)$ IOs

Thus we get a total cost of

$$
(3 - 2 \frac t k) \times (M + N) =
(3 - 2 \frac B N) \times (M + N) =
$$

## Classic hash join vs. Grace hash join vs. Hybrid hash join

- **Classic hash join:** build a hash table on the outer relation `R` in memory,
and probe it with the inner relation `S`. This is suitable for smaller 
relations that will fit in memory.
- **Grace hash join:** Partition both `R` and `S` with a hash function, and 
store these partitions on-disk. Each partition pair $(R_i, S_i)$ is then joined
separately. This allows us to join on larger datasets that don't fit in memory.
- **Hybrid hash join:** We partition `S` and keep *part of it* in memory (as
much as we are able, we write the rest to disk). We partition `R` similarly,
and instantly join the first part with the parts of `S` that are in memory,
before writing them to disk. We finally join with the parts of `S` that are 
stored on disk.

## Sort-Merge Join

- Scan `R` and sort
- Scan `S` and sort
- Merge `R` and `S`

This is useful if one or both inputs are already sorted on join attributes,
or if the output is required to be sorted on join attributes.

