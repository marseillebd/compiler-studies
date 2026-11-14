{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (main) where

import Prelude hiding (read)

import Compiler

import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Monad (forM_)
import Control.Monad.Reader (asks)

import qualified Data.Text as T
import qualified IOInstances as IO
import qualified Data.Map.Ordered as OMap
import qualified Text.Megaparsec as MP
import qualified Reader as R
import qualified Syntax as S

import System.Environment (getArgs)

main :: IO ()
main = IO.runIOCompiler $ do
  filepath <- liftIO getArgs >>= \case
    [filepath] -> pure filepath
    other -> stringFatal $ show other
  input <- Compiler.readFile filepath
  syntax <- case R.run R.topLevel filepath input of
    Left err -> stringFatal $ MP.errorBundlePretty err
    Right ok -> pure ok
  asts <- IO.runIOParser (S.parseTopLevel syntax) filepath
  do
    forM_ asts topLevel
    -- FIXME instead of compileFile just going all the way to output,
    -- it should just be the frontend: collect syntax and import/exports, organize module-section ordering, name resolution and other static analysis,
    -- and the result should really be a list of definitions in the language core
    -- It would be the responsibility of the backend to actually emit stuff.
    allDefs <- IO.read =<< asks (.definitions)
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

