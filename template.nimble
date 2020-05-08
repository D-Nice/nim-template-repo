import
  sugar,
  sequtils,
  strutils
from os import `/`

const vFile = "version.txt"
when (thisDir() / "src" / vFile).fileExists:
  const vPath = thisDir() / "src" / vFile
when (thisDir() / vFile).fileExists:
  const vPath = thisDir() / vFile

# Package
version       = vPath.staticRead.splitLines[0]
author        = "D-Nice"
description   = "Template repo"
license       = "Apache-2.0"
srcDir        = "src"
installExt    = @["nim", "txt"]

# Dependencies
requires "nim >= 1.0.0"

const pkgName = projectName()[0 .. projectName().rfind('_') - 1]

func listAllNimFiles(dir: string): seq[string] =
  var ldir = if dir == "": "." else: dir
  result.add ldir.listFiles.filter(x => x[ldir.len .. x.high].endsWith(".nim"))
  for sdir in ldir.listDirs:
    result.add sdir.listAllNimFiles

proc srcPaths: seq[string] =
  if srcDir != "":
    result.add srcDir.listAllNimFiles
  else:
    result.add pkgName & ".nim"
    result.add pkgName.listAllNimFiles
  for dir in installDirs:
    result.add dir.listAllNimFiles
  if result.len == 0:
    ## workaround for installing as nimble dep
    ## so that there's no out of bound errors
    result = @[""]

func testPaths: seq[string] =
  ## files in `/tests` starting with t are tests
  const dir = "tests/"
  return dir.listFiles.filter(x =>
    x[dir.len .. x.high].startsWith('t') and
    x.endsWith(".nim")
  )

let main = srcPaths()[0]

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
    genDocCmd = "nim doc --out:$1 --index:on $2" % [deployDir, main]
    genTheIndexCmd = "nim buildIndex -o:$1/theindex.html $1" % [deployDir]
    deployJsFile = deployDir & "dochack.js"
    docHackJsSource = "https://nim-lang.github.io/Nim/dochack.js"
  mkDir deployDir
  exec genDocCmd
  exec genTheIndexCmd
  when defined Linux:
    exec "ln -sf " & pkgName & ".html public/index.html"
  if not fileExists deployJsFile:
    withDir deployDir:
      exec "curl -LO " & docHackJsSource

## extras
task compileStaticHard, "Compile statically with hardening flags":
  exec """nim c --passC:"-pie -fPIE -fstack-clash-protection -fstack-protector-all -Wstack-protector --param ssp-buffer-size=4 -ftrapv" --passL:"-static" -d:release --opt:size """ & main

task i, "Install any dev nimble or distro deps":
  exec "nimble install cligen" # nimble deps
  exec "apt-get update && apt-get install -y binutils upx-ucl"

task compressBin, "Compress the size of the produced binary for distribution":
  if binDir == "":
    echo "Please specify a binDir in your package first..."
    quit 1
  exec "strip -s " & binDir / pkgName
  exec "upx --best " & binDir / pkgName
