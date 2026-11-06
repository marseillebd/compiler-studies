module Main (main) where

import Test.Tasty
import Test.Tasty.Golden
import System.Process
import System.FilePath
import System.IO.Temp
import System.Directory
import Control.Exception
import Paths_compiler_studies

import System.Exit (ExitCode(..))
import Control.Monad (when)

import qualified Compiler

main :: IO ()
main = do
  dataDir <- getDataDir
  tmpDir <- createTempDirectory "." "test"
  putStrLn "===================================="
  putStr "test directory: " >> print tmpDir
  putStrLn "===================================="
  catch (defaultMain $ testEmpty dataDir tmpDir) $ \exn -> do
    when (exn == ExitSuccess) $ removeDirectoryRecursive tmpDir
    throwIO exn

testEmpty :: FilePath -> FilePath -> TestTree
testEmpty dataDir tmpDir = goldenVsFile "empty file" golden output $ do
  librt <- getDataFileName "data/librt-x64-linux.a"
  writeFile asmFile $ Compiler.compileFile "nowhere" ""
  callProcess "as" [ asmFile, "-o", objFile ]
  callProcess "ld" [ objFile, librt, "-o", exeFile]
  writeFile output =<<
    readCreateProcess (proc exeFile [] ) ""
  where
  golden = dataDir </> "test" </> "golden" </> "empty.txt"
  asmFile = tmpDir </> "empty.s"
  objFile = tmpDir </> "empty.o"
  exeFile = tmpDir </> "empty.exe"
  output = tmpDir </> "empty.txt"
