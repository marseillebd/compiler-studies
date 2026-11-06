module Compiler where

compileFile :: FilePath -> String -> String
compileFile _filepath "" = unlines
  [ ".text"
  ]
