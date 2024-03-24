# Lecture 04: Storage

## Latency numbers that are important

- **L1 cache reference:** 1 ns $\equiv 1$ sec
- **L2 cache reference:** 4 ns $\equiv 4$ sec
- **DRAM access:** 100 ns $\equiv 100$ sec
- **SSD access:** 16'000 ns $\equiv 4.4$ hours
- **HDD access:** 2'000'000 ns $\equiv 3.3$ weeks
- **Network storage:** $\approx$ 50'000'000 ns $\equiv$ 1.5 years
- **Tape archives:** 1'000'000'000 ns $\equiv$ 31.7 years

## Disks

Disks are slow especially for random access, thus relative placement of pages
on disk has major performance implications.

Disks are sector-addressable, and generally have block sizes of 512B or 4096B.

When accesising a disk page, we must consider the following:

- **Seek time:** move arms to position on head track
- **Rotational delay:** waiting for block to rotate under the head
- **Transfer time:** actually moving data to/from disk surface

The total overhead is the sum of these three. An important optimization is
**prefetching**.

> **Prefetching:** IBM DB2 supports both sequential and list prefetch
> (prefetching a list of pages). In general, the prefetch size is 32 4KB pages,
> but this can be set by the user. For some sequential type database utilities
> (e.g., COPY, RUNSTATS), DB2 prefetches up to 64 4KB pages. For a
> smaller buﬀer pool (i.e., less than 1000 buﬀers), the prefetch quantity is
> adjusted downward to 16 or 8 pages. The prefetch size can be conﬁgured by
> the user; for certain environments, it may be best to prefetch 1000 pages at
> a time! Sybase ASE supports asynchronous prefetching of up to 256 pages,
> and uses this capability to reduce latency during indexed access to a table
> in a range scan. Oracle 8 uses prefetching for sequential scan, retrieving
> large objects, and certain index scans. Microsoft SQL Server supports
> prefetching for sequential scan and for scans along the leaf level of a B+
> tree index, and the prefetch size can be adjusted as a scan progresses. SQL
> Server also uses asynchronous prefetching extensively. Informix supports
> prefetching with a user-deﬁned prefetch size.

*Source: R&G Chap. 9 page 323*

## Flash

Outperforms disk by orders of magnitude, and supports random reads nearly 
equally as fast as sequential reads. In the context of DBMS, there is normally
a secondary storage layer or caching layer.

Data organization is also in pages similarly to disks, which are then organized
in flash blocks $\rightarrow$ maintain the block API that is compatible with
disk layout!

Like RAM, time to retrieve a disk page is unrelated to location
on flash

### Internals

SSDs have processors for IOps which are connected cia channels to NAND flash
package, which each has multiple dies. The blocks in these dies are organized
into planes.

There are several different types of flash, with varying lifespans between 1k 
and 100k operations *(read, write, erase)*.

- **Single-level cell:** one bit per cell. Only two voltage levels to 
distinguish between, and as a consequence faster reads and writes. Better 
endurance and reliability, but is more expensive than the following counterparts
- **Multi-level cell:** two bits per cell by disinguishing voltages meaning four
possible states per cell, essentially doubling density. This has endurance
implications since there are more states to distinguish.
- **Triple-level cell:** like multi-level cell but with three bits stored per
cell $\rightarrow$ eight states. Less endurance, higher density.

The flash processor needs to handle lifecycle of cells so that we don't write
repeatedly to the same cells and thus reduce lifespan. 

### Accessing flash

Access time depends on device organization, driver efficiency and bandwidth of
flash packages. The flash device has a flash translation layer which provides
a similar interface to HDDs, and tunes performance and device lifetime.

Enterprise SSDs will have 64GB of DRAM on them to mitigate the cost of reading
and writing.

## Disk Manager

> The lowest level of software in the DBMS architecture discussed in Section 1.8,
> called the disk space manager, manages space on disk. Abstractly, the disk
> space manager supports the concept of a page as a unit of data and provides
> commands to allocate or deallocate a page and read or write a page. The size
> of a page is chosen to be the size of a disk block and pages are stored as disk
> blocks so that reading or writing a page can be done in one disk I/O.

The disk manager is responsible for hiding the lower level details of the 
hardware/OS, allowing software to think of the data as a collection of pages.

### Keeping track of free blocks

It's unlikely that allocations will happen sequentially. In any case, we end up
with holes in the data when things are deallocated. How does the disk manager
deal with this?

- Maintain a list of free blocks. Pointer to the first known free block is 
stored somewhere known on disk
- Maintain a bitmap, one bit for each block on disk. Allows for very quick
allocation and deallocation compared to using a list.

### Why avoid the OS?

Ideally the DBMS should be able to do its own thing. This also allows for

- portability across OSs
- on a filesystem, the max file size could be for example 4GB while the DB needs
more than that
- OS files typically cannot span across different disks which is often necessary
for DBMS

## Buffer Manager

Data needs to be in DRAM for the DBMS to actually do something with it. The
buffer manager hides the fact that noe all data is actually present in DRAM in a
similar way to hardware caches. This allows us to reduce IO latency.

The buffer manager keeps track of pages $\rightarrow$ array of fixed size pages
called a buffer pool.
An entry is called a frame *(contains some metadata)*.

On requesting a page from disk that doesn't exist in the pool, a copy of it is 
placed into a frame. Dirty pages are written back on eviction $\rightarrow$ 
writeback policy.

Moreover, the buffer manager also maintains an in-memory page table that maps 
page IDs to a copy of the page in buffer pool frames.

It is implemented as a hash table using latches in the bucket linked lists to
ensure mutex.

#### Page Metadata

- **Dirty flag**
- **Pin / reference counter:** marker or counter indicating if a page is being
referenced by higher levels of DBMS.

## Buffer replacement

If we request a page from disk that isn't present in the pool, we need to find
a frame to put it in - what happens if there are no frames left?

- We evict some frame *(following some policy)* and write it back to disk
- We place the desired page in this now empty frame.
- We pin this page and return its address to the caller

A pin / reference counter allows us to know if we can evict a page from memory
without it currently being referenced by some caller.

$$
\text{pin count} = 0 \Leftrightarrow \text{page is candidate for replacement}
$$

A good buffer replacement policy should be

- correct
- accurate
- fast

As well as having low metadata overhead.

### FIFO

Implemented using a linked list of pages. Doesn't retain frequently used pages
or temporal locality *(a page used recently is likely to be used again soon)*.

### LRU

One of the more widely used policies. We implement it by maintaining a timestamp
of when each page was last accessed. When we need to evict a page, we evict the
one with the oldest timestamp.

### Clock

Approximates LRU without needing a timestamp per page *(lower metadata 
overhead)*.

- Each page has a reference bit which is `1` *iff* is it currently being
referenced.
- We organize pages in a circular buffer with a clock hand - upon sweeping we
evict if the ref bit if `0`. If the bit if `1`, we set it to `0`.

Equivalent to

```c
do {
    if (pincount == 0 && ref bit is off)
        choose current page for replacement;
    else if (pincount == 0 && ref bit is on)
        turn off ref bit;
    advance current frame;
} until a page is chosen for replacement;
```

LRU and clock to have a problem however - they are susceptible to sequential
flooding which happens when a query performs a sequential scan that reads every
page and pollutes the buffer pool with pages that are read once and then never
again *(protecting against this is called scan resistence)*.

### LRU-K

Addresses sequential flooding problems. 

- Track the history of the last k references to each page as timestamps and
compute the interval between subsequent accesses.

$$
LRU-1 \equiv LRU
$$

LRU-K is scan resistant.

### 2Q

We maintain both a FIFO and an LRU queue.

- Some pages are accessed only once in a sequential scan
- Some pages are accessed frequently

Therefore we use the following approach

- Maintain all pages in FIFO queue
- When a page that is currently in the FIFO is referenced again, we upgrade it
to the LRU queue
- When we need to evict, we prioritize evicting from the FIFO over the LRU.

