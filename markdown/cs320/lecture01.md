# Lecture 01: Introduction

## Def. Language

Formally, a langauge is a set of words over an alphabet.

$$
\Sigma = \lbrace a, b \rbrace
$$

$$
L = \lbrace b, ab, aab, \dots \rbrace
$$

Compilers are translators from a human-readable programming language, and a
computer executable language.

Compilters that translate to other high-level languages are called transpilers.

## Front-end and Back-end

We can think of programming languages as having a front-end and a back-end.

`a.c` $\rightarrow$ Syntax analysis $\left\| \rightarrow \right \|$ Semantic analysis 
$\rightarrow$ Optimizations $\rightarrow$ Code generation $\rightarrow$ `a.s`

With the separation in the middle representing the split between back and front
ends. All the arrows will have some intermediate representation as we pass
through different steps of the compilation process.

### Syntax Analysis

This stage takes the original file as input, and involves

- **tokenizing** with the tokenizer (a.k.a. lexer) i.e. we split the stream into
tokens
- **Preprocessing** i.e. replacing specific patterns in the token stream. This
is frowned upon today
- **Parsing** which transforms a token stream into an AST

### Semantic Analysis

This stage takes the AST as input and is all about finding meaning in the AST.
We label the AST with types, and see if everything makes sense.

- **Name resolution** which is binding identifiers to their names
- **Type checking** which verifies that an operations operands *agree* with the
operation's signature
- **Abstract interpretation** which checks flow-sensitive properties of the
program *(e.g. definite assignment)*

### Optimizations and Code Generation

These last two steps vary widely depending on the source and target. Often
involve specialized internal representations.

