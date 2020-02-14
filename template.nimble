# Package
version       = "0.0.1"
author        = "D-Nice"
description   = "Template repo"
license       = "Apache-2.0"
srcDir        = "src"

# Dependencies
requires "nim >= 1.0.0"

import
  sugar,
  sequtils,
  strutils

func srcPaths: seq[string] =
  ## add additional src dirs here, but ensure src is top
  const dirs =
    @[
      "src",
    ]
  for dir in dirs:
    result.add(dir.listFiles.filter(x => x[dir.len .. x.high].endsWith(".nim")))

func testPaths: seq[string] =
  const dir = "tests/"
  return dir.listFiles.filter(x =>
    x[dir.len .. x.high].startsWith('t') and
    x.endsWith(".nim")
  )

# Nimscript Tasks

## checks
const checkCmd = "nim c -cf -w:on --hints:off -o:/dev/null --styleCheck:"
task check_src, "Compile src with all checks on":
  for src in srcPaths():
    exec checkCmd & "error " & src
task check_tests, "Compile tests with all checks on":
  for test in testPaths():
    exec checkCmd & "error " & test
task check_all, "Compile check everything and run tests":
  exec "nimble check_src && nimble check_tests"

## docs
task docs, "Deploy doc html + search index to public/ directory":
  let
    deployDir = projectDir() & "/public/"
    genDocCmd = "nim doc --out:$1 --index:on $2" % [deployDir, srcPaths()[0]]
    genTheIndexCmd = "nim buildIndex -o:$1/theindex.html $1" % [deployDir]
    deployJsFile = deployDir & "dochack.js"
    docHackJsSource = "https://nim-lang.github.io/Nim/dochack.js"
  mkDir deployDir
  exec genDocCmd
  exec genTheIndexCmd
  when defined Linux:
    exec "ln -sf " & srcPaths()[0][4 .. ^4] & "html public/index.html"
  if not fileExists deployJsFile:
    withDir deployDir:
      exec "curl -LO " & docHackJsSource
