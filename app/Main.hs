{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (main) where

import Compiler

import qualified Data.Text.IO as T
import qualified System.Environment as Env
import qualified System.IO as Env
import qualified System.Exit as Env

main :: IO ()
main = do
  filepath <- Env.getArgs >>= \case
    [filepath] -> pure filepath
    other -> stringFatal $ show other
  res <- compileFile filepath
  putStrLn res

instance Compiler IO where
  readFile = T.readFile
  stringFatal msg = do
    _ <- Env.hPutStrLn Env.stderr msg
    Env.exitFailure
