# Marseille Bouchard's Compiler Studies

I'm going to get over my analysis paralysis and write a compiler.

I've noticed: a compiler is really an interpreter that computes a set of definitions.
This is even more salient when the compiler supports metaprogramming in the same language as the program itself.
The result of compilation is usually thought of as being serialized in a form that the target runtime (an interpreter os OS) can reconstitute, and then call into.
However, the result could just as easily be an interface file, which makes promises that other programs/libraries should be able to rely on,
  or indeed just about anything that describes the source accurately, if not always fully precicely.

# Preliminaries

Following Abdulaziz Ghuloum's "An Incremental Approach to Compiler Construction",
there are a few decisions to be made:
  intended audience, source language (to be compiled), host language (in which the compicompiler is written), and target language (on which the compiled program/library will run).

The intended audience is me. That was easy.

The source language is, well, I want to make a lot, so it realy doesn't matter what I choose.
Forth, Scheme, C, a toy dependently-typed language, it doesn't really matter.
The only thing is that I'm going to be putting off working on anything I want to get right, because that's when perfectionism slips in and messes up learning.

The target language is C, at least for now.
No, this doesn't exercise algorithms for register allocation or whatever, but I'm not so concerned.
Abdulaziz doesn't exercice instruction selection, linking, and so on.
A great many compilers (especially experimental ones) use C as a backend anyway.
That said, I plan on using a quite restricted subset of C, so the output is very close to a portable assembly anyway.

Finally, development language: it's Haskell.
I'm incredibly familiar with it, it has lots of tools to write languages in.
It's statically typed and garbage-collected, which is easy to embed a dynamically-typed and/or manually-managed in rather than the reverse, not to mention purity.
The only downside is that I need to be on my guard to avoid premature abstraction.

I seem recently to have gotten into a rut of trying to puick the "best" tool, so here's why I'm not using some other choices.
- Scheme: untyped, but also I recently tried to navigate around merely reading a file whose path came from the command line arguments.
  That was unnecessarily painful, even accounting for me being a bit of a beginner outside the repl.
- C: sure it's got loads of implementations, but at a certain point I have to ask: who cares?
  There's just so much ceremony around writing basic things, and too much pull to care about the performance.
- Rust: incentives to care too much about both abstraction _and_ performance, and it still only has a single (viable) implementation.
- OCaml: a close runner-up, but the lack of typeclasses is genuinely frustrating.
  While dependencies could theoretically be injected via the module system, that seems to be unidiomatic, probably for good reasons.
  I would like the strict-by-default, but honestly choosing OCaml for that would be emphasizing performance at the cost of the in-this-case-more-important familiarity

Now then, let's look at libraries and techniques:
- parsing: **I'm thinking** flatparse, because it's so byte-oriented (and fast).
  It might be "low-level", but as long as there's combinators, it's not hard to get up to higher levels.
  Just be sure to write my parsers like I'd write my grammar, which basically means primarily applicative.
- `primitive` can be used to implement an interpreter for a B- or C-like interpreter

# Methodology

At all times, we compile a _subset_ of the final language.

We're going to take _very_ small steps.
That means starting from a "hello world" that creates an empty library (to be linked to a startup script like `crt0` or by `dlopen` for embedding).
In the next library, we can start emitting functions or values that can be linked with, along with names.
This means we need to address the namespace problem: see "Namespaces vs Visibility" below.
We can even start emitting `.h` files or some other sort of interface file, potentially.
Only now do we get to Abdulaziz's "hello world" of integers.

# Namespaces vs Visibility

...and vs translation units, and whatever a "module" is.

All global definitions have fully-qualified names, but we refer to them by short names; name resolution translates between the two.
Separately, we would like to restrict access to a name from within other definitions, thus allowing encapsulation.
These independent concepts, qualified names and visibility, are normally conflated and controlled by a single "module" construct.
Meanwhile, Template Haskell has this thing where it splits up modules into sections wherever there's a top-level splice, releaving a subtlety that modules (and namespaces) are built in sections.

In line with "the compiler is an interpreter that evaluates a set of definitions", I say:
- there's a command to set the namespace
- the same namespace can be set twice: each time a new section is introduced
- visibility is public/private within a section (and perhaps can be adjusted based on build settings, like test/bench/example/etc).
- within a section, each definition is made unqualified, but the compiler qualifies it
- when a section imports a module, it can only import the sections that have previously been defined

I'm thinking this bears a lot of resemblance to `local-in` syntax,
  so that every "module" is a sequence of `local-in` statements.

So, as the compiler runs, it builds up:
- a table mapping module names to lists of sections
- dependencies between sections based on import statements
- names in the definitions are qualified and checked for visibility

# Build Settings

We know that we can select a frontend `-std=c11`, that we select a target `gcc-aarch64`, but a less-well-known thing is something I might call "route" or "pathway".
Take ghc, where we can target native x64 but we can select llvm or ghc's own code generator as different ways to get there.

