module Compiler where

import Prelude hiding (readFile)

import Syntax

import Data.Text (Text)

import qualified Parser as P
import qualified Text.Megaparsec as P

class Monad m => Compiler m where
  readFile :: FilePath -> m Text
  stringFatal :: String -> m any

compileFile :: Compiler m => FilePath -> m String
compileFile filepath = do
  input <- readFile filepath
  ast <- case P.run P.topLevel filepath input of
    Left err -> stringFatal $ P.errorBundlePretty err
    Right ok -> pure ok
  unlines <$> mapM topLevel ast

topLevel :: Compiler m => Syntax -> m String
topLevel (Group (Call (Ident "main") _) [Stmts stmts]) = pure $ unlines
  [ "int main(int argc, char* argv[], char* env[]) {"
  , "  int out;"
  , "  " ++ statements "out" stmts
  , "  return out;"
  , "}"
  ]
topLevel other = pure $ "//: " ++ show other

statements :: String -> [Syntax] -> String
statements _ [] = ""
statements resultVar [IntLit i] = concat
  [ resultVar, " = ", show i, ";" ]
