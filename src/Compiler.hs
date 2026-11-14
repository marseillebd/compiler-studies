module Compiler where

import Prelude hiding (readFile)

import qualified Syntax as S

import Data.Text (Text)
import Reader (Syntax(..))

import qualified Reader as P
import qualified Text.Megaparsec as P

class Monad m => Compiler m where
  readFile :: FilePath -> m Text
  stringFatal :: String -> m any

  startModule :: String -> m ()
  define :: Text -> Define -> m ()

data Define = Define
  { decl :: String -> String -- the C declaration to be emitted, parameterized by the name
  , defn :: String -> String -- the C definition to be emitted, parameterized by the name
  }

topLevel :: Compiler m => S.Definition -> m ()
topLevel (S.Definition funcName stmts) = do
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

statements :: String -> [S.Statement] -> String
statements _ [] = ""
statements resultVar [S.ExprStmt expr] = concat
  [ resultVar, " = ", expression expr, ";" ]
statements _ other = errorWithoutStackTrace $ show other

expression :: S.Expression -> String
expression (S.IntExpr i) = show i
