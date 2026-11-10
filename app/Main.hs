{-# LANGUAGE GeneralizedNewtypeDeriving #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (main) where

import Compiler

import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Monad (forM_)
import Control.Monad.Reader (ReaderT, runReaderT, MonadReader, asks)
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Data.Text (Text)
import Data.Map.Ordered (OMap)

import qualified Data.Text.IO as T
import qualified Data.Map.Ordered as OMap

import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)
import System.Exit (exitFailure)

main :: IO ()
main = runIOCompiler $ do
  filepath <- liftIO getArgs >>= \case
    [filepath] -> pure filepath
    other -> stringFatal $ show other
  compileFile filepath
  allDefs <- liftIO . readIORef =<< asks (.definitions)
  forM_ (OMap.assocs allDefs) $ \(defName, theDef) -> do
    liftIO $ putStrLn theDef

newtype IOCompiler a = IOCompiler { unIOCompiler :: ReaderT Env IO a }
  deriving (Functor, Applicative, Monad, MonadReader Env, MonadIO)
runIOCompiler :: IOCompiler a -> IO a
runIOCompiler action = do
  moduleCell <- newIORef "main"
  defsCell <- newIORef OMap.empty
  let st = Env
        { currentModule = moduleCell
        , definitions = defsCell
        }
  runReaderT action.unIOCompiler st

data Env = Env
  { currentModule :: IORef String
  , definitions :: IORef (OMap (String, Text) String)
  }

instance Compiler IOCompiler where
  readFile = liftIO . T.readFile
  stringFatal msg = do
    _ <- liftIO $ hPutStrLn stderr msg
    liftIO exitFailure

  startModule name = do
    cell <- asks (.currentModule)
    liftIO $ writeIORef cell name
  define name body = do
    curMod <- asks (.currentModule) >>= liftIO . readIORef
    defsCell <- asks (.definitions)
    defs <- liftIO $ readIORef defsCell
    let defs' = defs OMap.|> ((curMod, name), body)
    liftIO $ writeIORef defsCell defs'
