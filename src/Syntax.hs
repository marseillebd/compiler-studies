module Syntax where

import Control.Monad (forM)
import Reader (Syntax(..))
import Data.Text (Text)

-- what Haskell calls a "section in a module"
-- modules control visibility of each definition, even against other modules in the same namespace
-- the order of definitions in a module does not matter
-- the order of modules in a file(s) matters: only earlier modules are available to import from
data Module = Module
  { definitions :: [Definition]
  }
  deriving (Eq, Show)

data Definition = Definition
  { namespace :: [Text]
  , name :: Text
  , defn :: [Statement]
  }
  deriving (Eq, Show)

data Statement
  = ExprStmt Expression
  deriving (Eq, Show)

data Expression
  = IntExpr Integer
  deriving (Eq, Show)

------------------------------------

class Monad m => Parser m where
  currentFilepath :: m FilePath

parseTopLevel :: Parser m => [Syntax] -> m [Definition]
parseTopLevel defs = forM defs $ \case
  Group (Call (Ident name) _) [Stmts stmts] -> do
    defn <- forM stmts parseStatement
    pure $ Definition
      { namespace = ["Main"]
      , name
      , defn
      }

parseStatement :: Parser m => Syntax -> m Statement
parseStatement (IntLit i) = pure $ ExprStmt $ IntExpr i


