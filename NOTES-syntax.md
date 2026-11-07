So, the minimal compiler can just use s-expressions, great, but how about a front-end for s-expressions?

Before beginning in earnest, let's require every combination t obe non-empty, and its first element must be a syntactic keyword.
Thus, an ordinary lisp expressions like `(+ 1 a)` or `()` become `(GROUP + 1 a)` and `(GROUP)`.
The first thing I want is function-call syntax:
  - `foo(a + b, c)` --> `(APPLY f (GROUP a + b) c)`
There are other reasons to use delimiters specially, like lists (sidenote, lisp already has a special case `'(a b c)`) and tuples:
  - `[a + b, c]` --> `(LIST (GROUP a + b) c)`
  - `(a + b, c)` --> `(TUPLE (GROUP a + b) c)`
A tricky one is that I want both blocks and records. One one line, it's easy:
  - `{a + b; c}` --> `(BLOCK (GROUP a + b) c)`
  - `{f : a + b, g : c}` --> `(ASSOCS (f (GROUP a + b)) (g c))`
However, I also want lines ending in an open bracket to begin an indent, with each indented line being an "argument" to the other.
My current choice is simply to accept `:` as an extra keyword/punctuation, which also opens up keyword arguments and keyword entries in tuples:
I've already shown the prior choice, so this one looks like:
  - `(a + b, kw : c)` --> `(TUPLE (GROUP a + b) (ASSOC kw c))`
  - `foo(a + b, kw : c)` --> `(APPLY foo (GROUP a + b) (ASSOC kw c))`

Notice that a `GROUP` doesn't imply any particular semantics.
Instead, the language after parsing can interpret it on its own, and in context,
  perhaps re-writing infix operators, creating a function call or type application, and so on.

Ok, I've been working on the BNF, and I see a couple things:
- parenthesis without commas is an ordinary grouping operation
- parentheses can have positional and/or keyword arguments in that order, and I think I'll call those "bundles"
- square brackets are easy, because they only have positionals
- curly brackets with commas are associations
- curly brackets without them are blocks, and may have semicolons

Actually, I think bundles are bad. There are really three things going on: tuples, associative maps, and function arguments.
Only the last is really a "bundle", but there's a much more prevalant name for this idea already.

```
toplevel ::= [ expression { nl expression } ]

expression ::= term { ws term }

term    ::= primary { postfix }
postfix ::= '.' identifier                 # field access into an aggregate
         |  '.' lcurly identlist rcurly    # taking a slice of an aggregate
         |  lround  arglist   rround       # function call
         |  lsquare arglist   rsquare      # collection indexing
         |  lcurly  assoclist rcurly       # updating fields in an aggregate

primary ::= identifier | integer | float | string
         |  lround  expression rround
         |  lround  entrylist  rround
         |  lsquare entrylist  rsquare
         |  lcurly  assoclist  rcurly
         |  lcurly  stmtlist   rcurly

entry ::= expression
assoc ::= expression colon      expression
       |             ws? ':' ws identifier

# the various lists

arglist ::= [ ',' ]                                 # zero
         |  argline                                 # one or more
         |  indent argline { nl argline } dedent    # per-line
argline ::= [comma] argument { comma argument } [comma]
argument ::= entry | assoc
# The arglist is subject to the condition that all entries come before all assocs.
# It's possible but verbose to express this in bnf,
#   and real parsers will probably accept mixed entries/assocs on a first pass,
#   since you wouldn't need to deal with error recorvery during the parsing itself

entrylist ::= ','                                                 # zero
           |  comma entry | entry comma                           # one
           |  [comma] entry comma entry { comma entry } [comma]   # two or more
           |  indent entryline { nl entryline } dedent            # per-line
entryline ::= [comma] entry { comma entry } [comma]
# the thing that separates an entrylist from an expression is that entrylists must have at least one comma

assoclist ::= ','                                                 # zero
           |  comma assoc | assoc comma                           # one
           |  [comma] assoc comma assoc { comma assoc } [comma]   # two or more
           |  indent assocline { nl assocline } dedent            # per-line
assocline ::= [comma] assoc { comma assoc } [comma]
# assoclists mirror entrylists, since arglists are essentially a fusion of the two

stmtlist ::= [ ';' ]                                       # zero
          |  stmtline                                      # one or more
          |  indent [ stmtline { nl stmtline } ] dedent    # per-line
stmtline ::= expression { semicolon expression } [semicolon]
# statements do not need a semicolon to distinguish them from assoclists, since assoclists always have at least one comma

identlist ::= [comma]                                    # empty
           |  identline                                  # one or more
           |  indent indentline { indentline } dedent    # per-line
identline ::= [comma] identifier { comma identifier } [comma]

# Punctuation

lround = '(' ws?
rround = ws? ')'
lsquare = '[' ws?
rsquare = ws? ']'
lcurly = '{' ws?
rcurly = ws? '}'

comma = ws? ',' ws?
semicolon = ws? ';' ws?
colon ::= ws ':' ws

# TODO atoms
# but like, integers start with optional sign followed by a digit
# floats are integers followed by a period+mantisa and optional exponent
# probably it's best not to allow a number immediately before a period, say for field access/slice
# identifiers have numbers, digits, and a bunch of symbols (notably incl `+, -, :`), just as long as they don't conflict with numbers or the `:` punctuation
# strings are pretty normal; ``"I will `probability` add templates too"``.
```
