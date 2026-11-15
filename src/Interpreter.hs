module Interpreter where

import Syntax

import Data.Text (Text)
import Data.List (find)

data Value
  = IntVal Integer
  | Unit
  deriving (Eq, Show)

evalEntrypoint :: Text -> [Definition] -> Value
evalEntrypoint entryName defs =
  case find (\def -> def.name == entryName) defs of
    Nothing -> error "unimplemented"
    Just Definition{defn} -> evalStmts defn

evalStmts :: [Statement] -> Value
evalStmts = foldl (\_ -> evalStmt) Unit

evalStmt :: Statement -> Value
evalStmt (ExprStmt expr) = evalExpr expr

evalExpr :: Expression -> Value
evalExpr (IntExpr i) = IntVal i
