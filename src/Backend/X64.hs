module Backend.X64 where

import Syntax

import Data.Text (Text)

import qualified Backend.C as C

class Monoid r => X64 r where
  exportFunction :: Text -> r
  movi :: Register -> Integer -> r
  ret :: r
  -- TODO: more instructions, ofc

data Register
  = Rax | Eax | Ax | Ah | Al
  -- TODO

instance Show Register where
  show = \case
    Rax -> "rax"
    Eax -> "eax"
    Ax -> "ax"
    Ah -> "ah"
    Al -> "al"

definition :: X64 r => Definition -> r
definition def = mconcat
  [ exportFunction (C.mangle def)
  , statements (Just Rax) def.defn
  , ret
  ]

statements :: X64 r => Maybe Register -> [Statement] -> r
statements (Just reg) [ExprStmt expr] = expression reg expr

expression :: X64 r => Register -> Expression -> r
expression reg (IntExpr i) = movi reg i
