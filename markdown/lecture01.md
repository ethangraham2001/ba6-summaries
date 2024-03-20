# Lecture 01: Introduction

## Declarative Language vs. Imperative Language

We can think of a declarative language, like SQL, as one wherein we specify
*"what we want the result to look like"* instead of specifying the exact steps
and we expect the result to be returned. This differs from an imperative
language, like C or anything other general purpose programming language, wherein
we specify all the steps and logic to be executed.

## What we want in a DBMS

A DBMS is expected to provide efficient, reliable, convenient and safe
multi-user storage/access to massive amounts of persistent data. We should be
able to keep our physical data indepent of low-level implementation, and 
accessible through high-level query languages/APIs.

### DBMS vs Filesystem

A file system suffers from problems of unpredictability.
If two users are editing the same file and both changes are saved at the same 
time, in general we don't know which change will survive. Similarly, if a user
is updating a file and the power goes out, knowing which changes will survive is
undefined. So how do we write data over a subsystem when it can only promise you
undefined behavior?

So what more could we want than a filesystem? 

- Simple and efficient ad-hoc queries
- Concurrency control
- Recovery
- Benefits of being able to model the data; i.e. being able to connect the
conceptual to the physical in a non-binding way.

DBMS offers the following intellectual contributions:

- **Representation** through data modeling
- **Languages and systems** for querying data, which allows for complex queires
over massive amounts of data.
- **Concurrency control** for data manpulation, allowing for controlled accesses
and transactional semantics.
- **Reliability** of data storage, maintaining semantics even after pulling the
plug on it.

A data-intensive application sits on top of a DBMS, i.e. it is built with the
underlying system in mind.

## DBMS Architecture

Conceptual design -> Logical design -> physical design -> Database
storage.

### Describing data

A **data model** is a collection of concepts used for describing data, hiding
low-level storage detail. We represent it relationally, hierarchically, 
as a graph, etc... A hierarchical data model would be something like JSON, with
nested information *(not everything can fit in a structured table!)*.

### Relational data model

This is the model we are interested for the time being. We think of it as a set
of records

- **Relation** which is a table with rows and columns
- **Schema** which describes the structure of the data *(the columns)*

We can think of the schema as a type, and the data as a variable *(link with
imperative programming languages)*.

## Levels of abstraction (from high to low)

- **External schema** is what the user sees
- **Logical schema** which is conceptual. This is what the application will see.
Think of it as a view in Django, for example.
- **Physical schema** which is internal, is the data is physically stored on 
disk. This includes files, indexes, ... Relations are stored as unordered files, 
with indexes on columns for example.

A DBMS cares about data indepdendence types

- **Data independence:** We can change the schema at one level of the DB without
changing the schema at the level above it.
- **Logical data independence** we can change the conceptual schema without
changing the user views
- **Physical data independence** we can change the internal schema without
having to change the conceptual schema or user views.

## ER Model

This is the conceptual design, therefore we concern ourselves with the 
following:

- What are the entities and relationships?
- What information about these entities and relationships should we store?
- What integrity constraints should hold? I.e. we should be doing something when
something doesn't hold, i.e. relationship points to an entity that doesn't exist

The ER diagram can be mapped to a relational schema; i.e. the ER isn't 
implemented directly as it is purely conceptual, but is realized via 
implementation.

### The entity, and the entity set

- **Entity** is a real-world object that is distinguishable from others, and is
stored in a DB using a set of attributes
- **Entity set** is a collection of similar entities *(e.g. employees)* which
all have the same set of attributes. Each entity in a set has a *key* and each
attribute has a *domain*.

### Relationship and relationship set

- **Relationship** is an association among two or more entities; a row 
contains the keys of the entities participating. It can contain attributes which
provide information about the relationship *(e.g. `since` which gives 
information on when the relationship started)*.

## Contraints in ER model

### Key constraints

This is where we introduce the following 

- Many-to-many: employee can work in many departments. A department can have 
many employees
- One-to-many: each department has at most one manager
- One-to-one: Each driver can drive at most one vehicle, and each vehicle has
at most one driver.

## Participation constraints

We introduce

- total participation: every employee should work in at least one department
- partial participation: there could be some employees who are not managers

## Weak Entity

## Design Considerations

A weak entity is one who can be identified uniquely only by considering the 
primary key of another owner entity. The owner set and the weak entity set
must participate in a one-to-many relationship (one owner, many weak entities),
and weak entity set must have total participation in this relationship.

### ISA hierarchies

Think of it as inheritance. For example *contract employees ISA employees*, 
signifying that a contracted employee is an employee. This allows us to add
descriptive attributes to subclasses without needing to add them to the parent
class. We define

- **Overlap contraints:** "can an hourly employee be a contract employee as
well?" -> allow or disallow
- **Covering contraints:** does every employee entity also have to be either
an hourly or contract employee? -> yes or no


### Aggregation

We can treat a relationship set as an entity set for the purpose of 
participation in other relationships.


### Entity vs. Attribute

If we consider that an `Employee` has a single `Address`, then it could make 
sense to have it as an attribute of `Employee`. However, in the case that an 
`Employee` has multiple, we should make a new table for `Address` and have
them both participate in a relationship, perhaps `Lives_at`.

### Final Notes

The above considerations are important during design, and are all subjective.


