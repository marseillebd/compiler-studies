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
  compileFile filepath
  allDefs <- read =<< asks (.definitions)
  forM_ (OMap.assocs allDefs) $ \(defName, theDef) -> do
    liftIO $ putStrLn theDef

------ The Monad ------

newtype IOCompiler a = IOCompiler { unIOCompiler :: ReaderT Env IO a }
  deriving (Functor, Applicative, Monad, MonadReader Env, MonadIO)
runIOCompiler :: IOCompiler a -> IO a
runIOCompiler action = do
  moduleCell <- new "Main"
  defsCell <- new OMap.empty
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
    write cell name
  define name body = do
    curMod <- asks (.currentModule) >>= read
    defsCell <- asks (.definitions)
    update defsCell $ (OMap.|> ((curMod, name), body))

------ Helpers for Mutable State ------

class Monad m => Ref m ref where
  new :: a -> m (ref a)
  read :: ref a -> m a
  write :: ref a -> a -> m ()
  update :: ref a -> (a -> a) -> m ()
  update ref f = write ref =<< f <$> read ref

instance MonadIO m => Ref m IORef where
  new v = liftIO $ IO.newIORef v
  read cell = liftIO $ IO.readIORef cell
  write cell v = liftIO $ IO.writeIORef cell v

