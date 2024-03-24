# Lecture 03: Storage, Files and Indexing

## File and access layer

We used to store tables as files on a filesystem, however now we prefer storing
them on a partition directly on-disk to take control away from the filesystem.

For this lecture we consider

$$
file \equiv table
$$

When we store on disk, we have to choose whether we should store by row or by
column. This will affect access speed, as disk-access is sped up immensely if
accesses are sequential.

- If we tend to access certain fields frequently based on some predicate, then
storing by column is a better option
- If we frequently access all fields of a table, then storing by row may be
better.

## File Organization

File storage is done by block $\equiv$ page, which is the minimal access unit.
Therefore, whenever we read anything from disk it will come in a block, and the
whole block comes with it. There are different block sizes at every level of the
cache/memory hierarchy - for example, L1 cache block size will be smaller than
disk block size. Typical block sizes on disk are 4KB and 8KB.

### Page format: N-ary storage model *(row storage model)*

The page starts with a ***page header***. At the end of the page, we store 
pointers to specific records to speed up access times - note that this is only
useful if the records have variable-length fields, otherwise we can just 
calculate address based on start address of the page in the fixed-length case.

A page is just a collection of slots, where each slot stores one record. With a
format following. Each record has a record header - if any attributes in the 
record are variable-length, this is where it will be stated. Each slot has a
**`rid`/record id** which has the property that we can identify the address in 
memory of the record using it.

Table names, schemas and other metadata (such as statistical information used
by the query optimizer) are stored in the **system catalogue/data dictionary/
metadata repository** which itself is often stored in the DB as a table itself.

#### Bitmasking

Imagine the following table

| Packed |
| ------ |
| record 1  |
| record 2  |
| ...       |
| record N  |
|  |  | N   |
| --------  | -------- | -------- |

Where the $N$ at the bottom is in the page header and lists how many records are
stored in the page. Here, all records are packed together, thus we can imagine
that it would become cumbersome to delete a record if we had to repack 
afterwards. To help with this, we use a bitmask to indicate which slots are free
and which slots aren't.

| Packed |
| ------ |
| record 1 |
| empty |
| ... |
| record M |
| 1 | ... | 0 | 1 | M |
| -------- | -------- | -------- | -------- |-------- |

Where the bitmask is stored in reverse order, i.e. $M, \dots 2, 1$

#### Variable length fields

We could, for instance, use a special delimiter symbol like $\$$ to delimit
fields. However, this becomes problematic if we want to use that symbol in the
fields.

A better solution is to use a field of offsets which indicates where the 
different fields start. This also provides a clean way of dealing with `NULL`
values.

These variable-length fields can introduce internal fragmentation if they shrink
in size *(when a field changes)* or even more problematic, they run out of space
when a field grows and a record may no longer fit in a page.

### Column store

Here we store columns individually so speed up sequential accesses of these
fields without needing to read entire rows from disk when unneeded. We always
store alongside row-id so that we can reconstruct entire tuples. The problem
here, or cource, is that we have to `JOIN` which can be expensive for large 
amounts of data.

#### Partition Attributes Across (PAX)

Idea is to decompose a slotted page internally into mini-pages per attribute,
which is friendlier, bringing only relevant attributes to it, and is compatible
with slotted pages.

## Alternate organizations

### Heap file using linked lists

We have a header page that points to two doubly-linked lists for each of the
following:

- Full pages: data page with `next` and `prev` pointers
- Free pages: data page with `next` and `prev` pointers

However, this is slow if free pages aren't contiguous. Recall, sequential 
accesses on-disk are orders of magnitude faster than random accesses.

### Heap file using directory

Here we add a level of indirection through a directory which is a collection of
directory pages that have pointers to data pages. The directory entry can 
contain the number of free bytes in the page it is pointing to.

### Sorted File

Searching is easier $O(log(B))$, but insertion is more expensive
$log(B) + 2 \times \frac B 2$.

## Indexing

**idea:** add a redundant data structure that allows us to go to a piece of 
data quicker $\rightarrow$ it's just a copy of data in a different order so that
we can speed up certain queries that we know we will be making. Indexes are 
built on keys, for example $key_1$, and have no speedup whatsoever for another
arbitrary $key_2$.

### B-Tree indexing

We create several levels of indirection, with a root node and inner nodes. The
lowest level of the tree *(above the leaves)* points to leaves which are the
data. The inner nodes are stored s.t. we can easily search for values based on
some ordering. These inner nodes and root node are pages themselves.

***This is good in general for range selection***

### Alternative 1: primary key indexing

This corresponds to how the data is organized on disk

### Alternatives 2 & 3: secondary key indexing

Here we index based on some non-primary key attribute, which doesn't correspond
to how data is organized on-disk.

> Two data entries are said to be duplicates if they have the same value for the
> search key ﬁeld associated with the index. A primary index is guaranteed not
> to contain duplicates, but an index on other (collections of) ﬁelds can contain
> duplicates. In general, a secondary index contains duplicates. If we know
> that no duplicates exist, that is, we know that the search key contains some
> candidate key, we call the index a unique index.

### Index Classification

We distinguish between clustered and unclustered indexes, as well as dense 
versus sparse indexing. We can also choose to either index based on key, or
a non-key.

- **key:** index on the primary key, which is ordered.
- **non-key:** we index on some non-primary key, which gives us a path to the
data allowin for quicker retrieval, but doesn't correspond to how the data is
ordered on-disk.

When the file is orgainized close to the indexing we say that it is clustered,
otherwise we say that it is unclustered *(straight lines vs. crossing lines 
between last inner-node and leaves of B-tree)*. Access times vary a lot based
on whether or not the indexing is clustered.

### Hash Table

We use buckets here instead of a B-Tree. We hash the value of the key, which
points to a data page, or potentially a chain of linked data pages corresponding
to that value. In the case of secondary key indexing, we can have duplicates,
and thus we have different pointers to different buckets stored in a separate
table of pointers. Primary key indexing points straight to the first data page
in the chain without any intermediate pointer table.

***This in general is good for equality selections.***

### Composite Search key

This is for searching on a key combination. We may use two separate indexes
for this. For example

```sql
Select sID
From Student
Where sName = ‘Mary’ And GPA > 3.9
```

Contains an equality on `sName = Mary` and a range search for `GPA > 3.9` based
on two separate keys *(neither of which are the primary key since they aren't
unique. We may have a `GPA` B-tree and `sName` hash table for example if we do
this type of search frequently.

We can also build an index on the two of them in combination. However then we
must choose if we order `<sName, GPA>` or `<GPA, sName>`, and then choose 
whether use a hash table or B-tree.

## Final Note

> One size does not fit all!

