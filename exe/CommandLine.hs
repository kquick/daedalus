{-# Language BlockArguments #-}
module CommandLine ( Command(..)
                   , Options(..), Backend(..)
                   , getOptions
                   , options
                   , throwOptError
                   ) where

import Control.Monad(when)
import Control.Exception(throwIO)
import System.FilePath(takeExtension)
import System.Exit(exitSuccess)
import SimpleGetOpt

data Command =
    DumpRaw
  | DumpTC
  | DumpSpec
  | DumpNorm
  | DumpRuleRanges
  | DumpCore
  | DumpVM
  | DumpGen
  | CompileHS
  | CompileCPP
  | Interp (Maybe FilePath)
  | ShowHelp

data Backend = UseInterp | UsePGen Bool

data Options =
  Options { optCommand   :: Command
          , optParserDDL :: FilePath
          , optEntries   :: [String]
          , optBackend   :: Backend
          , optForceUTF8 :: Bool
          , optShowJS    :: Bool
          , optInline    :: Bool
          , optOutDir    :: Maybe FilePath
          }

simpleCommand :: Command -> ArgDescr Options
simpleCommand x = NoArg \o -> Right o { optCommand = x }

options :: OptSpec Options
options = OptSpec
  { progDefaults = Options { optCommand   = DumpTC
                           , optParserDDL = ""
                           , optBackend   = UseInterp
                           , optEntries   = []
                           , optForceUTF8 = True
                           , optShowJS    = False
                           , optInline    = False
                           , optOutDir    = Nothing
                           }
  , progOptions =
      [ Option ['s'] ["spec"]
        "Dump specialised type-checked AST"
        $ simpleCommand DumpSpec

      , Option ['t'] ["dump-tc"]
        "Dump type-checked AST"
        $ simpleCommand DumpTC

      , Option ['r'] ["dump-raw"]
        "Dump parsed AST"
        $ simpleCommand DumpRaw

      , Option [] ["dump-core"]
        "Dump core AST"
       $ simpleCommand DumpCore

      , Option [] ["dump-vm"]
        "Dump VM AST"
       $ simpleCommand DumpVM

      , Option [] ["dump-gen"]
        "Dump parser-generator automaton-based parser"
       $ simpleCommand DumpGen

      , Option ['n'] ["norm"]
        "Dump normalised type-checke AST"
        $ simpleCommand DumpNorm

      , Option ['i'] ["interp"]
        "Parse this file"
        $ OptArg "FILE" \s o -> Right o { optCommand = Interp s }

      , Option [] ["json"]
        "Show semantics values as JSON."
        $ NoArg \o -> Right o { optShowJS = True }

      , Option ['g'] ["gen"]
        "Use parser-generator backend when interpreting"
        $ NoArg \o -> Right o { optBackend = UsePGen False}

      , Option [] ["gen-metrics"]
        "Use parser-generator backend when interpreting and print metrics"
        $ NoArg \o -> Right o { optBackend = UsePGen True}

      , Option [] ["no-utf8"]
        "Use the locale settings instead of using UTF8 for output."
       $ NoArg \o -> Right o { optForceUTF8 = False }

      , Option [] ["compile-hs"]
        "Generate Haskell code."
        $ NoArg \o -> Right o { optCommand = CompileHS }

      , Option [] ["compile-c++"]
        "Generate C++ code"
        $ NoArg \o -> Right o { optCommand = CompileCPP }

      , Option [] ["inline"]
        "Do aggressive inlining on Core"
        $ NoArg \o -> Right o { optInline = True }

      , Option [] ["entry"]
        "Generate a library containg this parser."
        $ ReqArg "[MODULE.]NAME"
          \s o -> Right o { optEntries = s : optEntries o }

      , Option [] ["rule-ranges"]
        "Output the file ranges of all rules in the input"
        $ NoArg \o -> Right o { optCommand = DumpRuleRanges }

      , Option [] ["out-dir"]
        "Save output in this directory."
        $ ReqArg "DIR" \s o -> Right o { optOutDir = Just s }

      , Option ['h'] ["help"]
        "Show this help"
        $ simpleCommand ShowHelp
      ]

  , progParamDocs =
      [ ("FILE", "The DDL specification to process.") ]

  , progParams = \s o -> Right o { optParserDDL = s }
  }



getOptions :: IO Options
getOptions =
  do opts <- getOpts options
     case optCommand opts of
       ShowHelp -> dumpUsage options >> exitSuccess
       _ | let file = optParserDDL opts
         , takeExtension file == ".test" -> getOptionsFromFile file
         | otherwise ->
            do when (null (optParserDDL opts)) (dumpUsage options)
               pure opts

getOptionsFromFile :: FilePath -> IO Options
getOptionsFromFile file =
  do inp <- readFile file
     case getOptsFrom options (lines inp) of
       Left err   -> throwIO err
       Right opts -> pure opts

throwOptError :: [String] -> IO a
throwOptError err = throwIO (GetOptException err)
