# Lecture 03: Storage

A database is just sort of a file of records. We need to provide an api for

- creation
- deletion
- insertion
- modification
- retrieval (single record, range queries, as well as all records)

## File organization

We can think of a table as a file. This table is split up into pages. This is
how things are stored on persistent storage (by blocks). As we move up from 
disk all the way to L1 cache, the page sizes get smaller at every step.

A page itself consists of multiple records.

## N-ary storage model

This is the row-storage model. Every page is just a collection of slots which
stores / maps a record each: the slot either stores the record, or stores a 
pointer to it.

We store a record header: if there are variable-sized attributes, this is where
that information is kept. We need to be able to keep the length of fields in
real-time. We can also store pointers to each stored record in the footer. This
allow for more efficient lookup (as opposed to scanning through all fields
until the right one is found).

### Fixed-length records

Fixed-length records are nice because we always know the starting address of
record $N$ given their layout in-page. We have a couple of options to consider
w.r.t retrieval

- **Packed:** Always append. Less efficient for removal because we need to shift
all records upwards to maintain it. (excl. if removal of last record). We 
maintain a counter with how many pages are present, meaning that insertion is
easy.
- **Unpacked, bitmapped:** We can remove without shifting, updating the bitmap 
to indicate that the slot is now free (conversely if we add). Requires a scan
through the bitmap when we want to insert.

### Variable-length records

This is more of a hassle. A couple popular ways to handle this is

- **Delimiter symbols:** but what happens when the symbol is required by the
record somehow?
- **Array of field offsets:** typically better, and gives direct access to the
fields (stored as a `(len, data)` pair). Handled `NULL` values pretty elegantly
since we can just store a 0 length.

The latter of these two is implemented by reserving the *bottom* of the page 
for the slot array (grows up) and the top of the array for the actual data
(grows down). 

This does entail a fair amount of book-keeping and moving stuff around. What
happens if a field grows and no longer fits in the table? Nightmare. We might
also encounter the case where the record size > table size.

## Column-Store

We store by attribute in this case. Sometimes it is incredibly inefficient to
be fetching by row if we only need a couple select attributes.

The problem with this model is that we have to reconstruct rows via `JOIN` 
operations - this becomes cumbersome if we have to reconstruct massive rows.

## Partition Attributes Across (PAX)

We make minipages within a page. This is compatible wiht slotted pages and is
cache-friendly. It's sort of a mixture between column store and row store.

If we partition it in such a way that relevant attributes are in the same page,
then we will only bring relevant attributes into cache when we load from disk
or memory.

## Heap File

Append-based. The two ways that are suggested for implementing this are 

- Linked list of data pages: one for free pages, and one for full pages
- Page directory with pointers to data pages: we can include additional 
information such as number of free bytes on the page.

The directory is much smaller (in terms of raw bytes stored) than a linked list
of pages. This can make lookup more efficient in terms of IO.

### Avg. costs as a function of $B$, the number of data pages

- **Scan all records:** $B$
- **Equality search:** $0.5B$ (assuming exactly one match, we read through half 
of all data pages on average)
- **Range search:** $B$
- **Insertion:** $2$ (one read and one write)
- **Deletion:** $0.5B + 1$ (must read and write)

### Avg. costs of an ordered file, as a function of $B$ the number of data pages

Note that this is implemented as a tree!

- **Scan all records:** $B$
- **Equality search:** $log_2(B)$ 
- **Range search:** $log_2(B) + num_{matches}$
- **Insertion:** $log_2(B) + 2 \times B/2$ (search for the part of the tree to
insert into, read half of the pages and then write them back to maintain the 
tree)
- **Deletion:** $log_2(B) + 2 \times B/2$ (same idea as for insertion)

## Indexing

Speed up lookups for a given key (that isn't necessarily the primary key!)

- Hashed-based indexes are great for equality searches. Note that this doesn't
work well at all for inequality searches.
- Tree-based indexes are great for range searches

## Data representation in an index

There are a few ways that we can do this.

1. Actual data record with key `k`
2. `<k, rid of matching data record>`
3. `<k, list of rids of matching data records>`

### Option 1

The index structure becomes similar to the file organization itself. **At most
one index can have this structure, logically**. This is expensive to maintain,
as insertions and deletions need to modify the whole data file.

### Options 2 and 3

Easier to maintain as the index doesn't have to reflect the file organization.

### Clustered vs unclustered

The cost (in page IOs) of retrieving range scanned records for a clustered 
index is the number of pages in the file with matching records. For an 
unclustered index, it is approximately the number of matching index data 
entries.

Clustered indexes are more efficient for range searches, but are difficult to 
maintain. We can either organize on the fly, or do insertions / deletions
sloppily and reorganize later on.

### Dense vs sparse index

Dense means there is at least one entry per key value, whereas sparse indexes
have one entry per data pages in the file. Sparse indexes are always clustered,
and are smaller than dense indexes. However, we must note that there are some
optimizations that can be done on dense indexes that cannot be done for sparse
indexes.

- **Dense:** at least one entry per key value (could be more)
- **Sparse:** one entry per data page *(not per key-value pair)*. These are
smaller than dense indexes, and are always clustered (since the key is for a 
whole page).

## Composite search keys

We sarch on field combinations. 
- For an equality queery, we look for all fields to match the query
- For range query, we have some (or multiple) non-constant fields

Let's say that we have two fields that are using for the composite query, let
them be `<a, b>`. In which order should we build the index?? There is always
a trade-off.

## System catalogs

This falls into the category of metadata. We store information, as relations,
about the tables that are held in the system / db. 

