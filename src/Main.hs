import Options.Applicative
import Cabal.Simple
import Cabal.Haddock
import qualified Data.Set as Set
import Text.Printf
import System.Directory
import System.FilePath
import Data.Foldable (forM_)

import Distribution.Simple.Compiler hiding (Flag)
import Distribution.Package --must not specify imports, since we're exporting moule.
import Distribution.PackageDescription
import Distribution.PackageDescription.Parse
import Distribution.Simple.Program
import Distribution.Simple.Setup
import Distribution.Simple.Utils hiding (info)
import Distribution.Verbosity
import Distribution.Text

optParser =
  (,,)
    <$> many (strOption (long "package-db" <> metavar "DB-PATH" <> help "Additional package database"))
    <*> strOption (short 'o' <> metavar "OUTPUT-PATH" <> help "Directory where html files will be placed")
    <*> many (argument str (metavar "PACKAGE-PATH"))

getPackageNames
  :: [FilePath]       -- ^ package directories
  -> IO [PackageName] -- ^ package names
getPackageNames = mapM $ \dir -> do
  cabalFile <- findPackageDesc dir
  desc <- readPackageDescription normal cabalFile
  let
    name = pkgName . package . packageDescription $ desc
  return name

-- Depending on whether PackageId refers to a "local" package, return
-- a relative path or the hackage url
computePath :: [PackageName] -> (PackageId -> FilePath)
computePath names =
  let pkgSet = Set.fromList names in \pkgId ->

  if pkgName pkgId `Set.member` pkgSet
    then
      ".." </> (display $ pkgName pkgId)
    else
      printf "http://hackage.haskell.org/packages/archive/%s/%s/doc/html"
        (display $ pkgName pkgId)
        (display $ pkgVersion pkgId)

main = do
  (pkgDbArgs, dest, pkgDirs) <- execParser $
    info (helper <*> optParser) idm

  -- make all paths absolute, since we'll be changing directories
  -- but first create dest — canonicalizePath will throw an exception if
  -- it's not there
  createDirectoryIfMissing True {- also parents -} dest
  dest <- canonicalizePath dest
  pkgDirs <- mapM canonicalizePath pkgDirs

  pkgNames <- getPackageNames pkgDirs

  let
    configFlags =
      (defaultConfigFlags defaultProgramConfiguration)
        { configPackageDBs = map (Just . SpecificPackageDB) pkgDbArgs }
    haddockFlags =
      defaultHaddockFlags 
        { haddockDistPref = Distribution.Simple.Setup.Flag dest }

  -- generate docs for every package
  forM_ pkgDirs $ \dir -> do
    setCurrentDirectory dir

    lbi <- configureAction simpleUserHooks configFlags []
    haddockAction lbi simpleUserHooks haddockFlags [] (computePath pkgNames)

  -- generate documentation index
  regenerateHaddockIndex normal defaultProgramConfiguration dest
    [(iface, html)
    | pkg <- pkgNames
    , let pkgStr = display pkg
          html = pkgStr
          iface = dest </> pkgStr </> pkgStr <.> "haddock"
    ]
