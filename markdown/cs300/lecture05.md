# Lecture 05: Tree Indexing

## $B^+$ Trees

The most widely-used index structure. It is a height-balancing ordered tree
data structure allowing for searches and sequential accesses.

Insertions and deletions in $O(log_F(N))$ where $N$ is the number of leaf
nodes, and $F$ is the fanout. Just a generalization of a binary search tree,
with a fanout that can differ from 2. It is optimized for systems that read and
write large blocks of data.

Every node other than the root is at least half-full by property. With
`d <= num_keys <+ 2*d`. `d` is called the order of the tree.

Every inner node with `k` keys has `k+1` non-null children. Leaf-nodes should
always have sibling pointers, and often-times we give inner-nodes sibling 
pointers as well. Inner-nodes store only keys, and leaf-nodes store `<k, v>` 
OR `<k, v*>` pairs.

### Lookup

Lookup is down how you would expect from a binary search tree.

### Insertion

The idea is to find the correct leaf $L$

- If $L$ has enough space, we just insert into the leaf. We are done
- If not, we split $L$ into $L_1$ and $L_2$, evenly redistributing their keys,
and copying upt he middle key. We then insert an index entry pointing to $L_2$
into the parent of $L$.
- This can happens recursively, except when we split an index node, we **push
up** the middle key.

The splits will grow the tree. Splitting the root will increase the height of 
the tree.

Minimum occupancy is guaranteed for both index splits and leaf splits.

- **Copying up:** When a node splits, the key that separates the two new nodes
is duplicated (copied) and moved up to the parent node. For example when we 
split a leaf, and the key appears in both a leaf node and an inner node one
level up.
- **Pushing up:** When a node splits, the median key (the one that causes the 
split) is removed from the original node and pushed up to the parent node. When
we split an inner node, and we select new keys.

### Deletion

$B^+$ trees aren't optimized for deletion.

Start at the root, and find the leaf $L$ where the entry belongs, and remove it.

- If $L$ is at least half-full, we're done.
- If $L$ has $d-1$ entries, try to redistribute by borrowing from sibling nodes
(adjacent with the same parent).
- If redistribution fails, merge $L$ and sibling.
- On merge, delete entry from the parent of L, and make an entry either pointing
to $L$ or to its sibling.
- Propagate the merge to the root as needed. Possible that height decreases.

## Clustered $B^+$ tree

Traverse to the leftmost leaf page and then retrieve tuples from all leaf 
pages. This is always better than sorting data for each query.

For a non-clustered index, retrieving in the order they appear leads to 
redundant reads. A better idea is to find all pages that the query needs (using
the index), and then sort them on their page ID and read them.

## Node size for a $B^+$ tree

The slower the storage device, and larger the optimal node size of the tree is:
having a high-fanout for HDDs is important because sequential access is hugely
beneficial. This is less important for flash or in-memory $B^+$ trees.

## Intra-node searching

We have a few options here

- Linear search. We can increase performance with SIMD instructions
- Binary search
- Interpolation: approximate the desired key based on a known distribution of 
keys within the node. This requires certain information beforehand, which we
can't always guarantee.

## Concurrent accesses

Simple page or latch locking isn't enough as they only protect against single 
page changes - this doesn't hold as sometimes pages depend on each other.

We can use **lock coupling** (hand-over-hand locking) attempts to solve this
problem. But consider the following situation:

> When a leaf is split, the entry is propagates up, potentially going all the way
up to the root - but we've only got a lock for one level up.

Naive lock coupling can result in deadlocks!

An alternative is to use **restart locking** or **optimistic locking**

1. Try to insert using simple lock coupling
2. If we do not split the inner node, then everything is fine
3. Otherwise, release all latches
4. Restart the operation, but now hold the latches all the way up to the root
of the tree.
5. The operations can now be executed safely.

## In practice

An average fanout of a $B^+$ tree is 134. At a height of just 4, we get
$134^4 = 322,417,936$ entries!

Since the top levels are relatively small, we can actually hold them in memory.

- Level 1: 1 page, 8KB
- Level 2: 134 pages, 1MB
- Level 3: 17,956 pages, 140MB

