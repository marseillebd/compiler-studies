module Parser where

import Control.Monad (when, void)
import Data.Text (Text)
import Data.Void (Void)
import Syntax

import Data.Function ((&))
import Control.Monad.State (StateT, evalStateT, gets, modify)

import qualified Data.Text as T
import qualified Text.Megaparsec as P
import qualified Text.Megaparsec.Char as P
import qualified Text.Megaparsec.Char.Lexer as P
import qualified Control.Monad.Combinators as P

type Parser a = StateT Indent (P.Parsec Void Text) a
type Result a = Either (P.ParseErrorBundle Text Void) a

run :: Parser a -> FilePath -> Text -> Result a
run lang filename input = P.runParser (evalStateT lang $ Indent []) filename input

newtype Indent = Indent { unIndent :: [P.Pos] }
peekLevel :: Indent -> P.Pos
peekLevel s = case unIndent s of { it : _ -> it; [] -> P.pos1 }
popLevel :: Indent -> Indent
popLevel s = case unIndent s of { _ : rest -> Indent rest; _ -> s }
pushLevel :: P.Pos -> Indent -> Indent
pushLevel newLvl s = Indent (newLvl : unIndent s)



------------ Combinations ------------

topLevel :: Parser [Syntax]
topLevel = do
  P.indentLevel >>= modify . pushLevel
  blankLines
  exprs <- expression `P.sepEndBy` nextline
  blankLines
  P.eof
  pure exprs

expression :: Parser Syntax
expression = do
  term `P.sepEndBy1` lws >>= \case
    [t] -> pure t
    t:ts -> pure $ Group t ts
    [] -> errorWithoutStackTrace "expression should never match zero syntax values"


term :: Parser Syntax
term = foldl (&) <$>
  primary <*> P.many postfix

postfix :: Parser (Syntax -> Syntax)
postfix = P.choice
  [ (\args f -> Call f args) <$> arglist
  ]

primary :: Parser Syntax
primary = P.choice
  [ Ident <$> ident
  , IntLit <$> intLit
  , stmtlist
  ]

stmtlist :: Parser Syntax
stmtlist = do
  open '{'
  stmts <- checkAhead endLine >>= \case
    False -> stmtline
    True -> do
      indent
      stmts <- stmtline1 `P.sepBy` nextline
      dedent
      pure $ concat stmts
  close '}'
  pure $ Stmts stmts

stmtline :: Parser [Syntax]
stmtline = do
  _ <- P.optional semicolon
  expression `P.sepEndBy` semicolon

stmtline1 :: Parser [Syntax]
stmtline1 = do
  expression `P.sepEndBy1` semicolon

------------ Postfixes ------------

arglist :: Parser Arglist
arglist = do
  open '('
  -- TODO
  close ')'
  pure Arglist{positional = []} -- TODO

------------ Identifiers ------------

ident :: Parser Text
ident = P.try $ T.cons <$>
  initIdent <*> identBody

initIdent :: Parser Char
initIdent = do
  c <- P.satisfy isInitIdentChar
  when (c == ':') $ do
    void . P.try . P.lookAhead $ P.satisfy isBodyIdentChar
  when (isSign c) $ do
    P.notFollowedBy $ P.satisfy isDecimal
  pure c

identBody :: Parser Text
identBody = P.takeWhileP Nothing isBodyIdentChar

------------ Numbers ------------

intLit :: Parser Integer
intLit = P.try $ do
  sign <- ((:[]) <$> P.satisfy isSign) P.<|> pure ""
  digits <- P.takeWhile1P Nothing isDecimal
  pure . read $ sign ++ T.unpack digits

------------ Whitespace ------------

semicolon :: Parser ()
semicolon = P.try $
  lws0 >> skipChar ';' >> lws0

open :: Char -> Parser ()
open c = skipChar c >> lws0

close :: Char -> Parser ()
close c = P.try $ lws0 >> skipChar c

------------ Whitespace ------------

lws :: Parser ()
lws = skipWhile1 (== ' ')

lws0 :: Parser ()
lws0 = skipWhile (== ' ')

comment :: Parser ()
comment = skipChar '#' *> skipWhile (/= '\n')

eol :: Parser ()
eol = void P.newline P.<|> P.eof

blankLines :: Parser ()
blankLines = do
  P.eof P.<|> (endLine *> blankLines) P.<|> pure ()

endLine :: Parser ()
endLine = P.try $ do
  P.optional lws *> P.optional comment *> eol

indent :: Parser ()
indent = P.try $ do
  endLine >> blankLines
  gets peekLevel >>= P.indentGuard lws0 GT >>= modify . pushLevel


nextline :: Parser ()
nextline = P.try $ do
  endLine -- this takes us through the end of this line
  blankLines -- this skips any blank lines
  _ <- P.indentGuard lws0 EQ =<< gets peekLevel
  pure ()

dedent :: Parser ()
dedent = P.try $ do
  endLine >> blankLines
  modify popLevel
  _ <- P.indentGuard lws0 EQ =<< gets peekLevel
  pure ()

------------ Character Classes ------------

isSign :: Char -> Bool
isSign '+' = True
isSign '-' = True
isSign _ = False

isDecimal :: Char -> Bool
isDecimal c = '0' <= c && c <= '9'

isInitIdentChar :: Char -> Bool
isInitIdentChar c
  | 'a' <= c && c <= 'z' = True
  | 'A' <= c && c <= 'Z' = True
  | c `T.elem` "~!@$%^&*-_=+|:<>/?" = True
  | otherwise = False

isBodyIdentChar :: Char -> Bool
isBodyIdentChar c
  | isInitIdentChar c = True
  | '0' <= c && c <= '9' = True
  | otherwise = False

------------ Helper Combinators ------------
-- These are here to make the main parsers look more like BNF.
-- They might already be implemented elsewhere, but it's faster to write them than find them.

skipChar :: Char -> Parser ()
skipChar c = void $ P.char c

skipWhile :: (Char -> Bool) -> Parser ()
skipWhile p = void $ P.takeWhileP Nothing p

skipWhile1 :: (Char -> Bool) -> Parser ()
skipWhile1 p = void $ P.takeWhile1P Nothing p

checkAhead :: Parser () -> Parser Bool
checkAhead p = P.observing (P.lookAhead $ P.try p) >>= \case
  Right _ -> pure True
  Left _ -> pure False
