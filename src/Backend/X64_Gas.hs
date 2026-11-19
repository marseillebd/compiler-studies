module Backend.X64_Gas where

import Backend.X64

import Data.Text (Text)
import Data.Sequence (Seq)
import Data.String (IsString(..))

import qualified Data.Sequence as Seq
import qualified Data.Text as T

newtype Gas = Gas { unGas :: Seq Text }
  deriving(Semigroup, Monoid)

instance IsString Gas where
  fromString = Gas . Seq.singleton . fromString

instance X64 Gas where
  exportFunction name = Gas $ Seq.fromList
    [ "\t.text"
    , "\t.p2align 4,,15"
    , "\t.global " <> name
    , "\t.type " <> name <> ", @function"
    , name <> ":"
    ]

  movi dst val = Gas $ Seq.singleton $ mconcat
    [ "\tmov"
    , " $", T.pack (show val)
    , ", ", gasReg dst
    ]
  ret = "\tret"

gasReg :: Register -> Text
gasReg = ("%" <>) . T.pack . show

