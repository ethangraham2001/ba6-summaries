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
            // if `x` is a variable, return the singleton set
            case x: Variable => Set(x)
            // all variables in `f` and `a` remain free
            case Application(f, a) => f.free.union(a.free)
            // the free variables in `e` excluding `x` the parameter of the abstraction
            case Abstraction(x, e) => e.free.excl(x)
```

### $\alpha$ conversion

We can rename any variable in any term as long as it doesn't cause any 
occurrence to be bound by another abstraction

- $\lambda a. \lambda b.a$ can be converated to $\lambda c. \lambda b.c$ but
not to $\lambda b. \lambda b.b$.

Two terms are called $\alpha$ equivalent if they only differ in the choice of
bound variables, e.g. $\lambda a.a$ is $\alpha$ to $\lambda b.b$.

### Capture-avoiding Substitution

This is the act of substituting an unbound variable inside of a lambda body.
We write $e[x \rightarrow e']$, which means substituting $x$ for $e'$ in 
expression $e$. For example, $x[x\rightarrow e'] = e'$ which makes sense as 
replacing $x$ by $e'$ in the identity abstraction should yield $e'$.

In scala, we could write

```scala
trait Term:
    def free: Set[String] = ...
    def replace(x: Variable, e: Term): Term =
        this match
            // x[e -> x] = e
            case y: Variable => if (x == y) then e else this

            // when applying a function, replace any occurrences in the body of
            // x with e, and any occurrences in the argument
            case Application(f, a) => Application(f.replace(x, e), a.replace(x, e))
            
            case Abstraction(y, ee) => if x == y then this else
                // if the term has y as a free variable, it will be bound afterwards
                // which we don't want, so we replace y with a fresh variable
                val r = if e.free.contains(y) then e.replace(y, Variable.fresh()) else e
                Abstraction(y, ee.replace(x, r))
object Variable:
def fresh() = Variable(UUID.randomUUID.toString)
```

### $\beta$ reduction

Describes function calls, intuitively giving us a mental model to understanding
applications in a purely functional setting $\rightarrow$ we substitute 
arguments computed at the call-site for their corresonding parameters in the
callee.

## Inference Rules

Logical statements of the form

$$
\frac{
    p_1 p_2 \dots p_n
} {
    q
}
$$

A rule without any premise is called an axiom. We define

- **small step** or structural operational semantics which are inference rules
describing state transitions
- **big step** or natural semantics which are inference rules describing
relations.

## Extending Lambda Calculus with Types

We have the following static semantics, where $\Gamma$ can be thought of as the
context; a mapping of terms to type.

$$
\frac{
    \Gamma \vdash e_1 : \tau \rightarrow \sigma
    \,
    \Gamma \vdash e_2 : \tau
}{
    \Gamma \vdash e_1 e_2
}
$$

Think of this one like

```scala
val function[A, B]: (A => B)
val term: A = ...

function(term) // has type B
```

$$
\frac{
    \Gamma, x:\tau \vdash e:\sigma
}{
    \Gamma \vdash \lambda x: \tau .e : \tau \rightarrow \sigma
}
$$

Sort of equivalent to 

```scala
val e: B // may contain x's
val function(x: A) = e // type is A => B
```



$$
\frac{
    x : \tau \in \Gamma
}{
    \Gamma \vdash x : \tau
}
$$

*If a mapping is in $\Gamma$, then $\Gamma$ shows the mapping*

