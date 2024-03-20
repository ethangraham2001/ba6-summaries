# Lecture 02 relational model

This is the model that has prevailed for most use cases.

- Models complex data in a very simple structure that is easy to reason about
- We can make arbitrarily complex queries with relative ease

Recently, NoSQL DBs have been gaining in popularity

- Function as key value stores
- Skips the transaction part -> great scalability for analytic workloads

## Basics

- **Schema:** structural description of the relations in a database.
- **Instance:** Actual contents at a given point in time. Includes
cardinality *(number of rows)* and arity/degree *(number of attributes)*

We introduce a `NULL` value that indicates an unknown or undefined attribute,
but this introduces complexity. If I filter for `gpa >= 3.4`, where does `NULL`
sit in the predicate?

## Keys

- **Superkey:** set of attributes s.t. no two distinct tuples can have the same
values in all key fields *(not necessarily minimal)*
- **Key:** Which is a minimal superkey
- **Candidate key:** If there are multiple keys, each is refered to as a 
candidate key.
- **Primary key:** the candidate key that is chosen by the DBA *(database 
admin)*

We note that everything is checked when we insert something

- Check all new values being inserted against the schema
- check all previous values for duplicates

This is a huge performance stop in the critical path of execution. Integrity
constraints are expensive, and an insert isn't completed until the check has
finished. Ideally, this should happen very quickly.

In SQL, consider the following:

```sql
CREATE TABLE Person
    (ssn CHAR(9),
     name CHAR(20),
     licence_num CHAR(10),
     PRIMARY KEY(ssn),
     UNIQUE(licence_num))
```

Where `UNIQUE(licence_num)` tells us that although it isn't the primary key, it
should be unique for all instances.

### Foreign Keys

Set of fields in one relation that is used to refer to a tuple in another 
relation *(corresponds to primary key of the other relation)*. Works like a
pointer. If all foreign key constraints are enforced, we achieve referential
integrity which basically means no dangling pointers.

Referential integrity is hard to maintain as data changes... "if a `Student` is
deleted, should we delete all `Enrolled` tuples that depend on it? Do we change
these `Enrolled` to include a default `sid`?

### Integrity Constraints -> IC
 
Condition that must be true for any instance of the database. A **legal** 
instance of a relation is one that satisfies all specified ICs.

## Relational Algebra

***"Mathematics is the best query language"***

A query is applied to relation instances, and the result of said query is also
a relation instance. Schemas in the input are fixed, and the schema for the
result is as well.

### Operations

#### Selection $\sigma$

For example

$$
\sigma_{rating < 9}(s_2)
$$

will select all rows in table $s_2$ that have a rating lower than 9.

#### Projection $\pi$

For example

$$
\pi_{sname, rating}(s_2)
$$

selects colums `sname` and `rating` from $s_2$. The projection operator removes 
duplicates because the output should always be a set.

#### Cross product $\times$

$$
S_1 \times R_1
$$

will yield each row of $S_1$ paired with each row of $R_1$. These two tables
may have a naming conflict *(an attribute with the same name)* -> in this case
we should rename the attribute for one/both of them.

#### Join

Compound operator that involves cross product, selection, and sometimes 
projection.

- Compute $R \times S$
- Select rows where attributes that appear in both relations have equal values
- project all unique attributes and one copy of each of the common ones *(for
example $R$ and $S$ both have an attribute `sid`, in this case we will remove
one duplicate).

#### Condition Join or Theta-Join

$$
R \bowtie_C S = \sigma_C (R \times S)
$$

The output schema is the same as that of the cross product, we just select rows
that satisfy some condition.

We also define the equi-join which is a special case of the theta-join wherein
we have a conjunction of equalities.

$$
S_1 \bowtie_{S_1.age = S_2.age}
$$

#### Division operator

$A / B$ contains all tuples $x$ such that for every tuple $y \in B$, 
$\exists xy \in A$


