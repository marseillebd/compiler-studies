module Main (main) where

import Compiler

main :: IO ()
main = do
  putStrLn $ compileFile "nowhere" ""
