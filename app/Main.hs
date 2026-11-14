{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (main) where

import Prelude hiding (read)

import Compiler

import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Monad (forM_)
import Control.Monad.Reader (ReaderT, runReaderT, MonadReader, asks)
import Data.Text (Text)
import Data.Map.Ordered (OMap)
import Data.IORef (IORef)

import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Data.Map.Ordered as OMap
import qualified Data.IORef as IO

import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)
import System.Exit (exitFailure)

main :: IO ()
main = runIOCompiler $ do
  filepath <- liftIO getArgs >>= \case
    [filepath] -> pure filepath
    other -> stringFatal $ show other
  -- FIXME instead of compileFile just going all the way to output,
  -- it should just be the frontend: collect syntax and import/exports, organize module-section ordering, name resolution and other static analysis,
  -- and the result should really be a list of definitions in the language core
  -- It would be the responsibility of the backend to actually emit stuff.
  compileFile filepath
  allDefs <- read =<< asks (.definitions)
  forM_ (OMap.assocs allDefs) $ \((modName, defName), theDef) -> do
    let mangledName = modName ++ "_" ++ T.unpack defName
    liftIO . putStrLn $ theDef.decl mangledName
  liftIO $ putStrLn ""
  forM_ (OMap.assocs allDefs) $ \((modName, defName), theDef) -> do
    let mangledName = modName ++ "_" ++ T.unpack defName
    liftIO . putStrLn $ theDef.defn mangledName
  liftIO $ putStrLn ""
  liftIO $ putStrLn $ unlines
    [ "int main() {"
    , "  return Main_main();"
    , "}"
    ]


------ The Monad ------

