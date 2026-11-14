module Compiler where

import Prelude hiding (readFile)

import Syntax

import Data.Text (Text)

import qualified Parser as P
import qualified Text.Megaparsec as P

class Monad m => Compiler m where
  readFile :: FilePath -> m Text
  stringFatal :: String -> m any

  startModule :: String -> m ()
  define :: Text -> Define -> m ()

compileFile :: Compiler m => FilePath -> m ()
compileFile filepath = do
  input <- readFile filepath
  compileText filepath input

compileText :: Compiler m => FilePath -> Text -> m ()
compileText filepath input = do
  ast <- case P.run P.topLevel filepath input of
    Left err -> stringFatal $ P.errorBundlePretty err
    Right ok -> pure ok
  mapM_ topLevel ast

data Define = Define
  { decl :: String -> String -- the C declaration to be emitted, parameterized by the name
  , defn :: String -> String -- the C definition to be emitted, parameterized by the name
  }

topLevel :: Compiler m => Syntax -> m ()
topLevel (Group (Call (Ident funcName) _) [Stmts stmts]) = do
  define funcName Define
    { decl = \name -> "int " ++ name ++ "();"
    , defn = \name -> unlines
      [ "int " ++ name ++ "() {"
      , "  int out;"
      , "  " ++ statements "out" stmts
      , "  return out;"
      , "}"
      ]
    }
topLevel (Group (Ident "var") (Ident varName : Ident "=" : expr)) = do
  define varName Define
    { decl = \name -> "extern int " ++ name ++ ";"
    , defn = \name -> "int " ++ name ++ " = " ++ expression expr ++ ";"
    }
topLevel _other = pure ()

statements :: String -> [Syntax] -> String
statements _ [] = ""
statements resultVar [IntLit i] = concat
  [ resultVar, " = ", show i, ";" ]
statements _ other = errorWithoutStackTrace $ show other

expression :: [Syntax] -> String
expression [IntLit i] = show i
expression other = errorWithoutStackTrace $ show other
