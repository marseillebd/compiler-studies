module Compiler where

compileFile :: FilePath -> String -> String
compileFile _filepath "" = unlines
  [ "int main(int argc, char* argv[], char* env[]) {"
  , "  return 0;"
  , "}"
  ]
