module Syntax where

import Data.Text (Text)

data Syntax
  = Ident Text
  | IntLit Integer
  | Group Syntax [Syntax]
  | Call Syntax Arglist
  | Stmts [Syntax]
  deriving (Eq, Show)

data Arglist = Arglist
  { positional :: [Syntax]
  -- , keyword :: Map Text Syntax TODO
  }
  deriving (Eq, Show)
