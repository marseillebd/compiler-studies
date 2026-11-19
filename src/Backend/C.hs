module Backend.C where

import Syntax

import Data.Text (Text)

import qualified Data.Text as T

-- FIXME ofc I'll need a monad with gensym, and maybe even an indent tracker

emit :: C -> Text
emit c = T.unlines $
  c.decls <> c.defns

data C = C
  { decls :: [Text]
  , defns :: [Text]
  }

empty :: C
empty = C [] []

definition :: Definition -> C -> C
definition def c = c
  { decls = c.decls <>
    [ "int " <> mangle def <> "();" ]
  , defns = c.defns <> [ T.unlines
    [ "int " <> mangle def <> "() {"
    , "  int out;"
    , "  " <> statements (Just "out") def.defn
    , "  return out;"
    , "}"
    ] ]
  }

statements :: Maybe Text -> [Statement] -> Text
statements _ [] = ""
statements (Just outvar) [ExprStmt expr] = mconcat
  [ outvar, " = ", expression expr, ";" ]
statements _ other = errorWithoutStackTrace $ show other

expression :: Expression -> Text
expression (IntExpr i) = T.show i

mangle :: Definition -> Text
mangle def = mconcat ((<> "_") <$> def.namespace) <> def.name
