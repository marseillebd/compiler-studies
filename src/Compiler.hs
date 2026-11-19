module Compiler where

import Prelude hiding (readFile)

import Data.Text (Text)

class Monad m => Compiler m where
  readFile :: FilePath -> m Text
  stringFatal :: String -> m any

