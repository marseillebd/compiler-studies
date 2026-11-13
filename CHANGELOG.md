# Revision history for compiler-studies

Abdulaziz goes from integers to expressions and function calls.
I am more interested in modules, type checking, multiple backends, and so on.
So, I need to fill-in some gaps in the paper, but I'm not certain about the order.

tentative roadmap:
- **even later**:
  - type checking
  - primitive Bpp module (bool, byte, int, uint, addr)
  - operator desugaring (for `::` typing)
- **later**:
  - multiple backends (C and QBE, later x64)
  - sort out primitive modules from user-defined, and make them act the same to the user
- **v0.0.4**: emit QBE or x64(gas) code
- **v0.0.3**: export/import (which means graph algos) (doesn't make sense until function calls, or at least variable names)
- **v0.0.2**: multiple namespaces, compile a library or exe

## 0.0.2.0 -- ????-??-??

* Compile multiple functions (all `() -> int`)

## 0.0.1.0 -- 2026-11-09

* Compile a main function with only an integer to C code
* Parser that can _just_ handle a hello world

## 0.0.0.0 -- 2026-11-05

* Compiles an empty file.
