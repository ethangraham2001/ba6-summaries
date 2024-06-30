# Lecture 02: Relational Model

This model no longer captures conteptual level. This is the logical design that
eventually maps down to the physical design. This is the most widely used model
pretty much everywhere because it can be reasoned about very nicely. Other 
alternatives that haven't reached the same level of popularity are:

- Object-oriented: used by some IBM and Oracle stuff
- Key-value store / NoSQL: hugely used for many things when less-structured
data is desired (blob stores).
- graph-data model: social networks and stuff can be modeled nicely by this
(Facebook TAO, Linkedin Voldemort).

## Basics of relational model

- **Schema:** structural description
- **Instance:** actual contents at a given point in time
- **Cardinality** number of rows
- **Arity/Degree** number of attributes per-row

Implementations have to handle the `NULL` value. For example, in the GPA case,
is `NULL` greater than 3.4 or not? Should we even return these rows?

### Keys

- **Superkey:** A set of attributes for which no two distinct tuples can have
the same values
- **Key:** A minimal superkey
- **Candidate key:** when there are multiple keys, they are candidate keys
- **Primary key:** the candidate key that is chosen by the DBA (db-admin)

Selecting primary key is done during table creation (e.g. SQL)

```sql
CREATE TABLE Students
    (sid CHAR(20),
    name CHAR(20),
    login CHAR(10),
    age INTEGER,
    gpa FLOAT,
    PRIMARY KEY(sid))
```

We can also use the `UNIQUE` keyword (language-specific probably) that tells us
that although the attribute isn't the primary key, it should be unique (e.g. a 
key)

```sql
CREATE TABLE Person
    (ssn CHAR(9),
    name CHAR(20),
    licence# CHAR(10),
    PRIMARY KEY(ssn),
    UNIQUE(licence#))
```

### Enforcing referential integrity

We don't want dangling references, for example. We should be rejecting 
insertions or updates that aren't valid, e.g. referencing something that doesn't
exist.

### Integrity constraints

A condition that must be true for any instance of the database, e.g. domain
constraints. These are specified at creation of schema, checked when anything
is modified. A **legal** instance is one that satisfies all specified ICs.

## Relational Algebra

Mathematical, operational version of SQL. Very simple, only 5 composable 
operators.

- **Selection $\sigma$:** select a subset of rows
- **Projection $\pi$:** select a subset of columns
- **Cross-product $\times$:** combine two relations (may require renaming)
- **Set-difference $-$**
- **Union $\bigcup$**

Note that projection will handle duplicate elimination. Up to the implementation
to handle this, not our concern as the caller.

We can define more operations such as intersection $\bigcap$, but this can
be equivalently defined using $-$ and $\bigcup$

We can also define the join operator which is a compound of cross-product,
selection, and sometimes projection.

Most common type is the natural join, selecting rows where $r_1$ and $r_2$ have
equal values.

We also define the division operator, which is a rather complex one. Useful for
"for all" queries. *"find `sid` of all sailors who have reserved all boats*"
It isn't an essential operation, just a sometimes useful shorthand.

