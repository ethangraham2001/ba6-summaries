# Lecture 02: Formal Languages

## Recall: Formal Definition

$$
\Sigma = \lbrace a, b \rbrace
$$

$$
L = \lbrace b, ab, aab, \dots \rbrace
$$

We can write that

$$
L \subseteq \Sigma^{\star}
$$

### Keene Star

Given a set $\Sigma$, $\Sigma^{\star}$ is the minimal set s.t.

- $\varepsilon \in \Sigma^{\star}$ where $\varepsilon$ is the empty word
- $w \cdot s \in \Sigma^{\star}$ for $w \in \Sigma^{\star}$ and $s \in \Sigma$

$\Sigma^\star$ is infinite, even if $\Sigma$ is finite.

### Definitions

- $s$ appears at least once in $w \Rightarrow s \in w$
- $v = w \Leftrightarrow |v| = |w|$ and $\forall i, \, 0 \leq i < |v|$ we have
$v_i = w_i$
- $w \cdot \varepsilon = \varepsilon \cdot w = w$
- Concatenation is associative!
- $\left( \Sigma^\star, \cdot, \varepsilon \right)$ is a monoid
- $u$ is a prefix of $w$ if $u \cdot v = w$ for some $v$
- $v$ is a suffic of $w$ if $u \cdot v = w$ for some $u$

### Scala uwu

```scala
enum Word[Alphabet]:
    case Nil
    case Cons(a: Alphabet, w: Word[Alphabet])

    def apply(i: BigInt): Alphabet =
        this match
            case Cons(a, w) => if (i == 0) then a else w(i - 1) // indexing into the word
            case Nil() => throw IllegalArgumentException()

val w = Word.Cons(0, Word.Cons(1, Word.Nil()))
println(w(1))
```

