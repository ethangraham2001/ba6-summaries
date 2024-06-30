# Lecture 01: Introduction

## Referential integrity, foreign-key constraints

A foreign key is a column or set of columns in some table that uniquely 
identifies a row in another table. We want to ensure that a foreign key in a 
row isn't mapping to invalid data.

- **Contraint enforcement:** DBMS checks that when a foreign key is defined that
the row it maps to is valid. An insertion or update violating this will be 
rejected.
- **Referential actions:** `CASCADE`, `SET NULL`, `RESTRICT`, or `NO ACTION`

## Conceptual design

Before anything is implemented.

- What are entities / relationships
- What info do we store?
- What integrity constraints hold? What do we do on violation

We do this with an ER diagram that maps to a relational schema. Ultimately 
everything is just rows in tables.

## Key constraints

- many-to-many: thin line
- one-to-many: arrow pointing from the "one"
- one-to-one: arrow from every participating entity

## Participation contraints

- total: thick line $\rightarrow$ everyone must participate. Thick arrow thus
implies total participation + one-to-many which is equivalent to each entity
participating exactly once.
- Partial: thin line. Means that not every entity in the set has to participate.

## Weak Entities

Entity that can be uniquely identified uniquely by considering the primary key
of another (owner) entity.

## ISA

Idea of inheritance. *A ISA B* $\rightarrow$ A inherits from B. Every A is
considered to be a B.

- **Overlap constraints:** Can someone ISA from multiple things? 
(allow/disallow)
- **Covering constraints:** Does every entity have to participate in the ISA?

## Aggregation

Treat relationship set as an entity set so that is can participate in another
relation.

