{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (main) where

import Prelude hiding (read)

import Compiler

import Data.Foldable (Foldable(toList))
import Data.List (isPrefixOf)
import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Monad (forM_)
import Control.Monad.Reader (asks)
import System.Exit (exitSuccess, exitFailure)

import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified IOInstances as IO
import qualified Data.Map.Ordered as OMap
import qualified Text.Megaparsec as MP
import qualified Reader as R
import qualified Syntax as S
import qualified Backend.C as B_C
import qualified Backend.X64 as X64
import qualified Backend.X64_Gas as Gas

import System.Environment (getArgs)

main :: IO ()
main = IO.runIOCompiler $ do
  opts <- liftIO $ getArgs >>= parseArgs
  filepath <- case opts.inputFiles of
    [filepath] -> pure filepath
    other -> stringFatal $ show other
  emitter <- case opts.target of
    "c" -> pure $ \ir -> do
      let c = foldl (\z def -> B_C.definition def z) B_C.empty ir
      liftIO $ T.putStrLn (B_C.emit c)
    "gas" -> pure $ \ir -> do
      let it = mconcat $ X64.definition <$> ir
      liftIO $ T.putStr $ T.unlines . toList $ Gas.unGas it
    other -> stringFatal $ show other
  input <- Compiler.readFile filepath
  syntax <- case R.run R.topLevel filepath input of
    Left err -> stringFatal $ MP.errorBundlePretty err
    Right ok -> pure ok
  asts <- IO.runIOParser (S.parseTopLevel syntax) filepath
  emitter asts

data Options = Options
  { target :: String
  , inputFiles :: [FilePath]
  }

emptyOptions :: Options
emptyOptions = Options
  { target = "c"
  , inputFiles = []
  }

parseArgs :: [String] -> IO Options
parseArgs = go emptyOptions
  where
  go acc [] = pure acc
  go acc ("--":xs) = pure $ acc{ inputFiles = acc.inputFiles ++ xs }
  go acc (x:xs)
    | "--" `isPrefixOf` x = goLong acc (drop 2 x) xs
    | "-" `isPrefixOf` x = goShort acc (drop 1 x) xs
    | otherwise = go acc{ inputFiles = acc.inputFiles ++ [x] } xs
  goShort acc [] args = go acc args
  goShort _ ('h':_) _ = help >> exitSuccess
  goShort _ _ _ = help >> exitFailure
  goLong acc "help" _ = help >> exitSuccess
  goLong acc "target" (x:xs) = go acc{ target = x } xs
  goLong acc long xs
    | "target=" `isPrefixOf` long = go acc{ target = drop 7 long } xs
  goLong acc "help" _ = help >> exitSuccess
  goLong _ _ _ = help >> exitFailure
  help = do
    putStrLn "usage: bc [--target <TARGET>] <FILE...>"

