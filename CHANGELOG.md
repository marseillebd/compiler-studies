# Revision history for compiler-studies

Abdulaziz goes from integers to expressions and function calls.
I am more interested in modules, type checking, multiple backends, and so on.
So, I need to fill-in some gaps in the paper, but I'm not certain about the order.

tentative roadmap:
- **even later**:
  - primitive Bpp module (bool, byte, int, uint, addr)
  - sort out primitive modules from user-defined, and make them act the same to the user
  - export/import (which means graph algos) (doesn't make sense until function calls, or at least variable names)
  - multiple namespaces
- **later**: (variables, and that means we have to typecheck)
  - operator desugaring (for `::` typing)
  - call functions
  - use single variables
  - compile single variables
  - type check (`int` and `() -> int` only)

## 0.0.2.0 -- ????-??-??

TODO: (all about architecture)

* multiple backends (C, and x64 with GNU as syntax)
* interpreter (kinda, I took a lot of shortcuts)
* compile a library instead of an executable:
  this should make it easier to target environments with a "non-standard" host,
  like a bootloader, or WASM in the browser, or plugins for editors/games/&c.
* split reader and parser apart from "Compiler" backend
* Compile multiple functions (all `() -> int`)

* ISSUE: no tests for the top-level functions
* ISSUE: test files are included in package-level data files, instead of local to test

## 0.0.1.0 -- 2026-11-09

* Compile a main function with only an integer to C code
* Parser that can _just_ handle a hello world

## 0.0.0.0 -- 2026-11-05

* Compiles an empty file.
