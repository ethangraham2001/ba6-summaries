# Lecture 04: The Storage Layer

## Latency numbers

- L1 cache reference: 1ns
- L2 cache reference: 4ns
- DRAM: 100ns
- SSD: 16'000ns
- HDD: 2'000'000ns
- Network storage: ~50'000'000ns
- Tape archives: 1'000'000'000ns

Acknowledge these, and write efficient code.

## Magnetic disk overhead

When reading from a magnetic disk, there are three main sources of delay

- **Seek:** Position the head over the proper track. ~5/15ms
- **Rotational Delay:** Wait for the desired sector to rotate under the head.
~4/8ms
- **Transfer time** Transfer a block of bits (sectors). ~25-50$\mu s$

Sequential access on disk is better than random access! Knowing this, sometimes
disks will do prefetching with the insight that we are most likely to fetch
sectors following the one that we have just read.

Since the seek and rotational delays are far greater than that of the transfer
time, we optimize disk utilization by minimizing these delays.

### Example

1. **Random access:** Seek delay + rotational delay + transfer time 
$\approx$ 9ms $\rightarrow$ 451 KB/s
2. **Random access on same track:** Rotational delay + transfer time $\approx$
4ms $\rightarrow$ 1.03 MB/s
3. **Read next block on same track:** transfer time only $\approx$ 0.08 ms
$\rightarrow$ 50 MB/s

## Flash Disks

Orders of magnitude quicker than an HDD in terms of IO performance. Internally,
they have processors for IO operations which are connected via channels to NAND
flash packages, each of which has multiple dies, each of which has multiple
blocks organized into pages. These dies can be access independently 
$\rightarrow$ high parallelism. 

The processor allows us to implement a caching layer, which further speeds up
accesses. Moreover, the lack of any mechanical parts eliminates the rotational
and seeking delays associated to magnetic disk drives.

### Explanation of NAND flash

Flash memory stores data as electrical charges, with an initial state `1`. On
erasure, all bits in a block are set to this state. On a write, bits will be 
set to the `0` state.

There is no way to directly set a bit to `1`, we have to erase the whole block
and write back.

NAND flash supports:

- `READ` at page granularity
- `WRITE` at page granularity, setting bits to `0`
- `ERASE` at page granularity, setting all bits in the page to `1`

Efficient firmware design is critical to handle the erase-before-write 
limitation.

### Accessing a flash page

The access time depends on a few factors

- Device organization (internal parallelism) which needs to be exploited by the
flash's internal processor.
- driver efficiency (software)
- bandwidth of the flash packages

There exists a flash translation layer (FTL) which provides a similar interface
to that of an HDD, as well as complex firmware (device drivers). It tunes 
performance and device lifetime, which is important as NAND flashes can only
sustain a certain number of `READ/WRITE` operations before dying.

## Disk management

### Redundant Array of Indexpensive Disks (RAID)

- **RAID 0** is partitioning data across disks. There is no redundancy. Great 
performance because of cumulative bandwidth utilization
- **RAID 1** is duplicating data across disk. Deals well with disk loss, but isn't
good for data corruption. Reads can be parallalized which is a nice-to-have,
and writes are equivalent to writing to a single disk. This is expensive, 
however, as all data is duplicated across multiple disks. This is used in 
critical infrastructure (such as storing sensitive information that shouldn't
be lost)
- **RAID 5** uses parity as a mechanism for fault tolerance (we store the 
parity of some stripes in a different disk to where they are stored). If one
disk fails, we can still reconstruct its data by XOR-ing all remaining drives.

#### Example of RAID 5 reconstructing.

Consider the following storage layout

- `disk_0: parity[0-2]`
- `disk_1: stripe_0`
- `disk_2: stripe_1`
- `disk_3: stripe_2`

With the parity in disk 0 storing the XOR of stripes 0 to 2. If `disk_1` fails,
we can reconstruct `stripe_0 = parity[0-2] ^ stripe_1 ^ stripe_2`.

#### RAID 5 speed

In the previous example, we used four drives with rotating parity. Effectively,
in that case, we can speed up reads threefold (assuming uniform distribution of
accesses). In general this becomes $N - 1$ parallelism on reads, where $N$ is
the number of available drives. Writes are tricker, as parity needs to be
calculated.

RAID 5 is reliable, affordable, and is widely used in datacenter environments.

## Buffer management

This is like a caching layer for the DB. We don't want to rely on the OS for 
this; the DB wants to do things its own way. By caching effectively, we can
reduce IO slow-downs.

- Specialized prefetching
- Control over buffer replacement policy
- Control over flushing data to disk
- Control over threads and process scheduling (convoy problem: OS scheduling
conflicts with DBMS locking)

Data needs to be in RAM for the DBMS to be able to operate on it.

At a high level, the buffer manager keeps track of pages by maintaining a fixed
size array of them. When a page is requested, an exact copy is placed into
one of these frames *(array entry)* 

The buffer manager must also maintain related metadata, namely a page table 
that maps page IDs to a copy of the page in a buffer pool frame. It also must
keep flags, such as a `DIRTY` flag, or a pin/reference counter.

## Buffer replacement policies

When memory full, we need to evict pages. Our goals are correctness, accuracy,
speed, and low metadata overhead.

### Clock policy

Equates to doing the following.

```c
do {
    if (pincount == 0 && ref_bit == OFF)
        page_to_replace = current_page;
    else if (pincount == 0 && ref_bit == ON)
        ref_bit == 0;
    current_page++;
    current_page %= num_pages;
} while (!page_is_chosen)
```

We cycle around available pages until we find one that hasn't been used in the
last cycle, and remove that one.

The problem with LRU and Clock buffer replacement policies is that they aren't
scan resistent *(susceptible to sequential flooding, when a query performs a
sequential scan that reads every page, polluting the buffer pool with pages 
that are read once and never again)*

LRU-K and 2Q minimize this issue

### LRU-K

We keep track of the K last references to each page as timestamps and compute
the interval between subsequent accesses. DBMS uses this history to estimate
the next time that the page will be accessed. We have the equivalence
LRU-K $\equiv$ LRU when $K = 1$

LRU-K is scan resistent.

### 2Q

Maintain a FIFO and LRU.

- Maintain all pages in a FIFO queue
- When a page that is currently in the FIFO is references again, upgrade it to
the LRU queue
- Prefer evicting from the FIFO queue (unless it is empty, obviously)

Hot pages will be in the LRU, and read-once pages will be in the FIFO.

