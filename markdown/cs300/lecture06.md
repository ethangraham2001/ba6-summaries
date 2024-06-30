# Lecture 06: Hashing and Sorting

Hash tables have $O(n)$ space complexity, and an average access complexity
$O(1)$, worst case $O(n)$. This is nice. 

Hashing in general is a very efficient way to check for equality.

- Beneficial for equality selections
- Useful in `JOIN` implementations.

## Hash table design considerations

1. **Design hash function:** How do we map a large key space into a smaller
domain? There is also a trade-off between being fast and having a good
collision rate.
2. **Hashing scheme:** how to handle collisions after hashing. Trade-off
between allocating a large hash tabl evs. additional instructions required
to `GET`/`PUT` keys.

## Static hash tables

We just allocate a huge array of buckets that has one slot for every element
that will be stored.

This however assumes that

1. The number of elements is known ahead of time and is static
2. Each key is unique


### Linear probe hash tables

This is a single giant table of slots. Collisions are resolved by lineary
searching for the next free slot. This means that determining presence of an
element involves hashing the key, and lineary searching for it.

Insertions and deletions are just generalizations of lookup. Deletion, in
particular involves adding a tombstone in the place of deleted elements 
(instead of moving all elements up). 

### Linked list hash tables (non-unique keys)

This is the classic solution, where hash tables are arrays of linked lists,
i.e. we have a separate storage area for each key.

## Dynamic hash tables

We need to be able to resize hash tables.

### Chained hashing

Maintain a linked lits of buckets for each slot in the hash table, and maintain
a directory of pointers to buckets.

However, linked lists can grow forever which is space-inefficient and requires
pointer chasing. Constant time lookups become impossible.

### Extendible hashing

Splits buckets incrementally instead of letting the linked list grow forever.
We do this with a directory of pointers to bucket. 

- Directories have a **global depth** `gd`. The `gd` LSBs of the hash point
to a bin in the directory table.
- Bins have a **local depth** `ld`. The `ld` bits are shared by all bin 
members.

### Linear Hashing

Maintains a pointer that tracks the next bucket to split - when a bucket
overflows, we split this one.

This avoids a directory by using temporary overflow pages, and avoids long
overflow chains by choosing the bucket to split in a round-robin fashion. 
Handles duplicates and collision nicely.

## Sorting

### Two-way external sort

- Break data up into $N$ pages
- We have a finite number of buffer pool pages $B$

This is a divide and conquer approach.

#### Simplified case

- **Pass 0:** Read one page of data into memory, sort it in one run, and write
it back to disk. Repeat until the whole table has been sorted into runs
- **Passes 1, 2, ...:** Recursively merge pairs of runs into runs twice as long.
This needs at least 3 buffer pages (2 for input, 1 for output).

We do a total of $1 + \lceil log_2 N \rceil$ passes, with a total IO cost of
$2N \times (1 + \lceil log_2 N \rceil) = 2N \times num_{passes}$.

#### General case

- **Pass 0:** Use $B$ buffer pages to produce $\lceil \frac N B \rceil$ sorted
runs of siye $B$.
- **Passes 1, 2, ...:** Merge $B-1$ runs (k-way merge).

This yields $1 + \lceil log_{B-1} \lceil \frac N B \rceil \rceil$ passes, with 
with a total IO cost 
$2N \times (1 + \lceil log_{B-1} \lceil \frac N B \rceil \rceil)$.

#### Double buffering optimization

We want to be overlapping IO and CPU.

Prefetch the next run in the background (DMA) and store it in a second buffer
while the system processes the current run $\rightarrow$ better resource 
utilization, reduced response time.

### $B^+$ for sorting

If the table has a $B^+$ index on it, then we can just traverse in-order.

#### Clustered case

Traverse from left to right and retrieve records from all leaf pages. This is
always better than external sorting, and all disk acesses are sequential!

#### Unclustered case

Chase each pointer to the page that contains the data. In general, this will 
be one IO per data record. **Always worse than sorting!**

