# Lecture 03: Automata

## Language Concatenation

Given two langauges $L_1, L_2 \subseteq \Sigma^\star$

$$
L_1 \cdot L_2 = \lbrace w_1 \cdot w_2 | w_1 \in L_1, w_2 \in L_2 \rbrace
$$

## Language Exponentiation

Given $L \subseteq \Sigma^\star$

- $L^0 = \lbrace \varepsilon \rbrace$
- $L^{n+1} = L \cdot L^n$

## Characteristic Functions

$$
1_L(w) = 0 \Leftrightarrow w \notin L
$$

$$
1_L(w) = 1 \Leftrightarrow w \in L
$$

This function is computable iff. we can build a machine that computed its 
result.

```scala
// recognizes words like aaaa...aab
def recognize(w: IndexedSeq[Int]): Boolean =
    w.headOption match
        case Some('a') => recognize(w.drop(1))
        case Some('b') => w.length == 1
        case _ => false

println(recognize("aab".codePoints().toArray.toIndexedSeq)) // true
```

We can think of this as a state machine - each recursive call updates the state
of the algorithm. It is just a finite state automaton.

## Recall ToC: Finite State Automaton

An FSA is a tuple $A = (\Sigma, Q, F, q_0, \delta)$ where

- $\Sigma$ is an alphabet
- $Q$ is a finite set of states
- $q_0 \in Q$ is an initial state
- $F \subseteq Q$ denotes a set of accepting states
- $\delta: Q \times \Sigma \rightarrow \wp(Q)$

We define deterministic and non-deterministic finite-automata, the difference
lying in the transition function. Non-deterministic FSA allow for $\varepsilon$
transitions, as well as multiple transitions for the same input symbol.

We also define a **configuration**; a pair $(q, i)$ where

- $q \in Q$
- $0 \leq i < |w|$

The execution semantics of an automaton are given by the relation 
$\rightarrow_w$ between configureations

$$
(q, i) \rightarrow_w (q', i + 1)
$$

$\rightarrow_w^\star$ is the reflexive transitive closure of $\rightarrow_w$,
which means all transitions possible after repeatedly applying $\rightarrow_w$.

An automaton **accepts** $w$ iff $\exists (q_0, 0) \rightarrow_w^\star$ such 
that $q \in F$.

A DFA is an NFA. We can convert an NFA to a DFA *(usually with loads more 
states)*, therefore the two are equivalent.

### Characteristic Function of Concatenation

$$
1_{L_1 \cdot L_2}(w) = 0 \Leftrightarrow
\forall i \in [0, |w|[, 
1_{L_1}(w_{[0, i [}) = 1 \Rightarrow
1_{L_2}(w_{[i, |w| [}) = 0 \Rightarrow
$$

$$
1_{L_1 \cdot L_2}(w) = 1 \Leftrightarrow
\exists i \textit{ such that }
1_{L_1}(w_{[ 0, i [}) = 1 \textit{ and }
1_{L_2}(w_{[i, |w| [}) = 1 \Rightarrow
$$

