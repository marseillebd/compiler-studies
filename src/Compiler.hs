module Compiler where

import Prelude hiding (readFile)

import Syntax

import Data.Text (Text)

import qualified Data.Text as T
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
topLevel _other = pure ()

statements :: String -> [Syntax] -> String
statements _ [] = ""
statements resultVar [IntLit i] = concat
  [ resultVar, " = ", show i, ";" ]
statements _ other = errorWithoutStackTrace $ show other


