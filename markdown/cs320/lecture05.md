# Lecture 05: Semantics

Grammars are about syntax, not about meaning

$$
S \rightarrow \texttt{nat} | \texttt{add } S \, S
$$

Doesn't tell us what `nat` or `add` mean; for example `add 38 add 3 1`.

## Semantics: Rewriting

We can express the semantics of `add` with the following rewrite rules

- $n \rightarrow \left| n \right|$ where the brackets are a function mapping
`nat` tokens to $\mathbb N$
- $\texttt{add } v_1 \, v_2 \rightarrow v_1 + v_2$ where 
$v_1, v_2 \in \mathbb N$

## CK Machine

The rules from the previous paragraph are applied with a CK machine.

- **C**: control term, the expression being evaluated
- **K**: continuation, the remainder of the program.

A transition function describes how the machine goes from one state to the next.
Transition functions are of the form `(control_term, continuation)`

The sequence of states from beginning to end is called a derivation. In the case
of addition, we would write $\rightarrow_{add}$ for the semantics of `add`.

## Properties of semantics

### Confluence

if $\forall e,\, e \rightarrow^\star x$ and $e \rightarrow^\star y$ 
$\exists z$ s.t. $x \rightarrow^\star z$ and $y \rightarrow^\star z$, then
$\rightarrow^\star$ is confluent.

### Normal Forma

When a term can no longer be rewritten further. $8_{\mathbb N}$ for example, 
but not `add 1 3`. Semantics can be:

- **weakly normalizing:** if for every term there exists a normal form
- **Strongly normalizing:** if it is weakly normalizing and confluent
- **deterministic:** if for any state, all position transitions lead to the same
successor state.

We are particularly interested in **values** which are a particular normal form.
Other irreducible terms denote runtime errors in practice.

### Undefined Behavoir, Nasal Demons

A machine is stuck if it reaches a state `(C, K)` where `C` is not a value,
`K` is non-empty, and no further reduction rules apply.

## Lambda Calculus

Minimal formal language for expressing computation.

$\lambda X.S$ is called an *abstraction*. It is a function taking exactly one
parameter and having a body made of any arbitrary expression. $\lambda a.a$ is
the identity function.

We need to apply abstractions, which involves

- $\alpha$ conversion: renaming a variable in a term
- $\beta$ reduction: replaces occurrences of a parameter by its argument.

A variable is **bound** if it occurs in the body of an abstraction whose
parameter has the same name. Otherwise, it is called **free**.

```scala
val f = (a: Unit) => (b: Unit) => a
val g = (b: Unit) => (b: Unit) => a // a is not found!
```

here, 

$$
f \equiv \lambda a. \lambda b.a, \,\, g \equiv \lambda b.\lambda b.a
$$

```scala
// binding in scala
trait Term:
    def free: Set[Variable] =
        this match
    case x: Variable => Set(x)
    case Application(f, a) => f.free.union(a.free)
    case Abstraction(x, e) => e.free.excl(x)
```

### $\alpha$ conversion

We can rename any variable in any term as long as it doesn't cause any 
occurrence to be bound by another abstraction

- $\lambda a. \lambda b.a$ can be converated to $\lambda c. \lambda b.c$ but
not to $\lambda b. \lambda b.b$.

Two terms are called $\alpha$ equivalent if they only differ in the choice of
bound variables, e.g. $\lambda a.a$ is $\alpha$ to $\lambda b.b$.

