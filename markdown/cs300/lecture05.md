# Lecture 05: Tree Indexing

## Recall: 3 alternatives for DB indexing data entries `k*`

### Alternative 1: data record with key value `k`

- In this alternative, each data record in the database is associated directly 
with its key value (k). The key value serves as the primary means of accessing 
and identifying the record.
- When a search or retrieval operation is performed, the database system 
directly accesses the data record associated with the specified key value.
- This approach is straightforward and efficient for retrieving individual 
records when the key value is known. However, it may not be suitable for 
efficiently querying data based on criteria other than the primary key, as it 
lacks indexing structures optimized for such queries.
- This alternative is commonly used in scenarios where primary key lookups 
dominate the access patterns, and the database schema is simple or denormalized.

### Alternative 2: `<k, rid of data record with search key value k>`

- In this alternative, a mapping is established between each distinct key value 
`k` and the Record ID `rid` of the data record(s) associated with that key value
- When a search operation is performed using a key value `k`, the database 
system first consults the index to obtain the corresponding `rid`(s) of the data 
record(s) matching that key value.
- Subsequently, the database system uses the obtained `rid`(s) to directly 
access the corresponding data record(s) in the database.
- This approach provides efficient lookup capabilities for retrieving data 
records based on their key values, leveraging the index structure to quickly 
locate the relevant records. However, it may still face limitations when dealing 
with range queries or non-key-based searches.

### Alternative 3: `<k, list of rids of data records with search key k>`

- In this alternative, instead of mapping each key value to a single `rid`, a 
list of `rid`s is maintained for each distinct key value `k`. This allows for 
handling scenarios where multiple data records share the same key value (e.g., 
in cases of one-to-many relationships).
- When a search operation is performed using a key value `k`, the database 
system retrieves the list of `rid`s associated with that key value.
- Subsequently, the database system can access each data record using its 
corresponding `rid` from the retrieved list.
- This approach is suitable for scenarios where multiple records may have the 
same key value (e.g., in a one-to-many relationship), enabling efficient
retrieval of related records based on the shared key value.
- However, managing and querying lists of `rid`s may introduce overhead, 
especially in scenarios with large datasets or frequent updates.

## Why we need $B^+$ trees

The cost of maintaining a sorted file and performing binary searches can be
expensive for a large DB. The idea is to create a smaller index file that we
can binary search on.

A $B^+$ tree is a

- self-balancing *(height balanced)* ordered tree data structure that allows for
searched and sequential access.
- Insertions and deletions in $O(log_F(N))$ where $F$ is the fanout, and $N$ is
the number of leaf nodes *(data entries)*

It's a generaliztion of a binary search tree that is optimized for systems that
read and write large blocks of data.

We also constrain a $B^+$ to having at least $d$ children keys, and at most $2d$ 
children - therefore a $B^+$ is always at least half full. There are root
nodes, inner nodes, and leaf nodes.o

Every inner node with $k$ keys has $k+1$ non-null children, as these inner keys
correspond the to the "border" between ranges. There are pointers between 
different leaf nodes so that we can scan ranges after finding the start point. 
Sometimes we will also add sibling pointers to the inner nodes to facilitate
accessing other keys on that level without having to go up the tree to a higher
level.

All nodes in the tree are actually just pages in the DB linked together with
pointers. The leaf nodes are a linked list of pages with `prev` and `next` 
pointers.

Leaf nodes contain `<key, value>` pairs of either of the following two forms

- `<key, value>` directly
- `<key, *value>` i.e. a pointer to a data page if the value is too large.

$B^+$ trees are optimized for lookup and insertion. We generally don't optimize
for deletion as it is an uncommon operation.

### Lookup

Lookup is just binary searching for correct leaf node.

### Insertion

We look for the correct leaf node $L$ and insert if there's enough space. If
there isn't enough space in $L$, we split it into $L_1$ and $L_2$ and distribute
the keys so that they both are at least half full.

