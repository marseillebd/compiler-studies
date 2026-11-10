module Main (main) where

import Syntax

import Control.Exception
import Paths_compiler_studies
import System.Directory
import System.FilePath
import System.IO.Temp
import System.Process
import Test.Hspec.Megaparsec
import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.Golden

import System.Exit (ExitCode(..))
import Control.Monad (when)

import qualified Compiler
import qualified Parser as P

main :: IO ()
main = do
  dataDir <- getDataDir
  tmpDir <- createTempDirectory "." "test"
  let happyPath = defaultMain $ testMain dataDir tmpDir
  happyPath `catch` \exn -> do
    when (exn == ExitSuccess) $ removeDirectoryRecursive tmpDir
    throwIO exn

testMain :: FilePath -> FilePath -> TestTree
testMain dataDir tmpDir = testGroup "all"
  [ parserTests
  , goldenTests dataDir tmpDir
  ]

------------------------------------

goldenTests :: FilePath -> FilePath -> TestTree
goldenTests dataDir tmpDir = testGroup "integration"
  [ testEmpty dataDir tmpDir
  ]

testEmpty :: FilePath -> FilePath -> TestTree
testEmpty dataDir tmpDir = goldenVsFile "empty file" golden output $ do
  librt <- getDataFileName "data/librt-x64-linux.a"
  writeFile asmFile $ Compiler.compileFile "nowhere" ""
  callProcess "as" [ asmFile, "-o", objFile ]
  callProcess "ld" [ objFile, librt, "-o", exeFile]
  writeFile output =<<
    readCreateProcess (proc exeFile [] ) ""
  where
  golden = dataDir </> "test" </> "golden" </> "empty.txt"
  asmFile = tmpDir </> "empty.s"
  objFile = tmpDir </> "empty.o"
  exeFile = tmpDir </> "empty.exe"
  output = tmpDir </> "empty.txt"

------------------------------------

parserTests :: TestTree
parserTests = testGroup "parser"
  [ let parse = P.run P.ident ""
    in testGroup "identifiers"
    [ testCase "asciinum identifier" $
        parse "xyz23" `shouldParse` "xyz23"
    , testCase "plus is identifier" $
        parse "+" `shouldParse` "+"
    , testCase "colon is not an identifier" $
        parse `shouldFailOn` ":"
    , testCase "colon may be in identifier" $
        parse "::" `shouldParse` "::"
    , testCase "do not start with (optinoal sign and) digit" $
        parse `shouldFailOn` "+2"
    ]
  , let parse = P.run P.intLit ""
    in testGroup "integers"
    [ testCase "a basic integer" $
        parse "42" `shouldParse` 42
    , testCase "negative integer" $
        parse "-2" `shouldParse` (-2)
    ]
  , testGroup "whitespace"
    [ testCase "standard blank line" $
        P.run P.endLine "" "  \n" `shouldParse` ()
    , testCase "empty blank line" $
        P.run P.endLine "" "" `shouldParse` ()
    , testCase "near-empty blank line" $
        P.run P.endLine "" "\n" `shouldParse` ()
    , testCase "comment-only line" $
        P.run P.endLine "" "   # hello\n" `shouldParse` ()
    , testCase "comment-only line eof" $
        P.run P.endLine "" "   # hello" `shouldParse` ()
    ]
  , let parse = P.run P.topLevel ""
    in testGroup "files"
    [ testCase "empty file" $
        parse "" `shouldParse` []
    , testCase "comments-only file" $
        parse "# hello\n   # world" `shouldParse` []
    , testCase "one-int file" $
        parse "23" `shouldParse` [IntLit 23]
    , testCase "one-int file with comments" $
        parse "# here's an integer!\n23" `shouldParse` [IntLit 23]
    , testCase "one-int file with extra newlines" $
        parse "23\n\n" `shouldParse` [IntLit 23]
    , testCase "call something" $
        parse "main()" `shouldParse` [Call (Ident "main") (Arglist [])]
    , testCase "one-line block" $
        parse "{ f 42 ; }" `shouldParse`
        [ Stmts [ Group (Ident "f") [IntLit 42] ]
        ]
    , testCase "multi-line block" $
        parse "{\n  42\n\n}" `shouldParse`
        [ Stmts [ IntLit 42 ]
        ]
    ]
  ]
