module Main (main) where

import Control.Exception
import Paths_compiler_studies
import System.Directory
import System.FilePath
import System.IO.Temp
import Test.Hspec.Megaparsec
import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.Golden

import System.Exit (ExitCode(..))
import Control.Monad (when)
import Reader (Syntax(..), Arglist(..))
import Data.Text (Text)

import qualified Compiler
import qualified IOInstances as IO
import qualified Reader as R
import qualified Syntax as S
import qualified Interpreter as I
import qualified Text.Megaparsec as MP

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
  [ readerTests
  , parserTests
  , interpreterTests
  , goldenTests dataDir tmpDir
  ]

------------------------------------

goldenTests :: FilePath -> FilePath -> TestTree
goldenTests dataDir tmpDir = testGroup "integration"
  [ -- testEmpty dataDir tmpDir
  ]

-- testEmpty :: FilePath -> FilePath -> TestTree
-- testEmpty dataDir tmpDir = goldenVsFile "empty file" golden cFile $ do
--   cProgram <- IO.runIOCompiler $ do
--     Compiler.compileText "nowhere" ""
--     IO.stringIOCompiler
--   writeFile cFile cProgram
--   where
--   golden = dataDir </> "test" </> "golden" </> "empty.c"
--   cFile = tmpDir </> "empty.c"

------------------------------------

readerTests :: TestTree
readerTests = testGroup "reader"
  [ let parse = R.run R.ident ""
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
  , let parse = R.run R.intLit ""
    in testGroup "integers"
    [ testCase "a basic integer" $
        parse "42" `shouldParse` 42
    , testCase "negative integer" $
        parse "-2" `shouldParse` (-2)
    ]
  , testGroup "whitespace"
    [ testCase "standard blank line" $
        R.run R.endLine "" "  \n" `shouldParse` ()
    , testCase "empty blank line" $
        R.run R.endLine "" "" `shouldParse` ()
    , testCase "near-empty blank line" $
        R.run R.endLine "" "\n" `shouldParse` ()
    , testCase "comment-only line" $
        R.run R.endLine "" "   # hello\n" `shouldParse` ()
    , testCase "comment-only line eof" $
        R.run R.endLine "" "   # hello" `shouldParse` ()
    ]
  , let parse = R.run R.topLevel ""
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

parserTests :: TestTree
parserTests = testGroup "parser"
  [ let shouldBe = mkTester (R.topLevel, S.parseTopLevel)
    in testGroup "topLevel"
    [ testCase "empty" $
      "" `shouldBe` []
    , testCase "define `() -> int`" $
      "main() {\n  42\n}" `shouldBe` [S.Definition
        { S.name = "main"
        , S.defn = [S.ExprStmt $ S.IntExpr 42]
        }]
    ]
  ]
  where
  mkTester :: (Eq a, Show a) => (R.Parser b, b -> IO.IOParser a) -> Text -> a -> Assertion
  mkTester (reader, parser) input expected = do
    syntax <- case R.run reader "" input of
      Left e -> assertFailure $ MP.errorBundlePretty e
      Right ok -> pure ok
    actual <- IO.runIOParser (parser syntax) ""
    actual @?= expected

interpreterTests :: TestTree
interpreterTests = testGroup "interpreter"
  [ testCase "forty-two" $
    "main() {\n  42\n}" `shouldBe` I.IntVal 42
  , testCase "siz-seven" $
    "main() {\n  67\n}" `shouldBe` I.IntVal 67
  ]
  where
  shouldBe input expected = do
    syntax <- case R.run R.topLevel "" input of
      Left e -> assertFailure $ MP.errorBundlePretty e
      Right ok -> pure ok
    ast <- IO.runIOParser (S.parseTopLevel syntax) ""
    let actual = I.evalEntrypoint "main" ast
    actual @?= expected
