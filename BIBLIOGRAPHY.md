# Theory
- [An Incremental Approach to Compiler Construction](http://scheme2006.cs.uchicago.edu/11-ghuloum.pdf)

# Systems

- [GNU as `.type` directive](https://sourceware.org/binutils/docs/as/Type.html)
  took way too long for me to find, and I'm generally disappointed in the state of GNU as docs.
  The long and short is that `.type "{function,object,common,tls_object"}` lets you save some info in ELF about what the symbol identifies.
  Then, Oracle has [some docs](https://docs.oracle.com/cd/E23824_01/html/819-0690/chapter6-79797.html#chapter6-35166)
    that describe what's going on inside the ELF file, basically the type is part of the `st_info` field, and there are `STT_*` macros to define each type.
It took me way to 

# Libraries

Major:
- [megaparsec](https://hackage.haskell.org/package/megaparsec)

Executables and Tests:
- [optparse-applicative](https://hackage.haskell.org/package/optparse-applicative)
- [tasty](https://hackage-content.haskell.org/package/tasty),
  [tasty-golden](https://hackage-content.haskell.org/package/tasty-golden),
  and probably tasty-hunit and tasty-property

Where are the batteries?
- [primitive](https://hackage.haskell.org/package/primitive)
- [process](https://hackage.haskell.org/package/process)
- [filepath](https://hackage-content.haskell.org/package/filepath),
  [directory](https://hackage-content.haskell.org/package/directory), and
  [temporary](https://hackage.haskell.org/package/temporary)

