{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module IOInstances where

import Prelude hiding (read)

import Compiler

import Control.Monad (forM_)
import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Monad.Reader (ReaderT, runReaderT, MonadReader, ask, asks)
import Data.IORef (IORef)
import Data.Map.Ordered (OMap)
import Data.Text (Text)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import Control.Monad.Writer (execWriterT, tell)

import qualified Syntax as S
import qualified Data.IORef as IO
import qualified Data.Map.Ordered as OMap
import qualified Data.Text as T
import qualified Data.Text.IO as T

------------------------------------

newtype IOParser a = IOParser { unIOParser :: ReaderT FilePath IO a }
  deriving (Functor, Applicative, Monad, MonadIO, MonadReader FilePath)

runIOParser :: MonadIO io => IOParser a -> FilePath -> io a
runIOParser action path = liftIO . flip runReaderT path $
  unIOParser action

instance S.Parser IOParser where
  currentFilepath = ask

------------------------------------

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
  , definitions :: IORef (OMap (String, Text) Define)
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

stringIOCompiler :: IOCompiler String
stringIOCompiler = execWriterT $ do
  allDefs <- read =<< asks (.definitions)
  forM_ (OMap.assocs allDefs) $ \((modName, defName), theDef) -> do
    let mangledName = modName ++ "_" ++ T.unpack defName
    tell $ theDef.decl mangledName
  tell ""
  forM_ (OMap.assocs allDefs) $ \((modName, defName), theDef) -> do
    let mangledName = modName ++ "_" ++ T.unpack defName
    tell $ theDef.defn mangledName
  tell ""
  tell $ unlines
    [ "int main() {"
    , "  return Main_main();"
    , "}"
    ]

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

