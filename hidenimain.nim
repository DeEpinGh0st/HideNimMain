import osproc
import json
import strutils
import os
import argparse


proc getErrorInfo(output: string): void = 
    while true:
        let output = readLines(output)
        if output.len == 0:
            break
        echo output
    quit(0)

proc compileLib(dllName: var string, arch: string = "i386"): void =
  if dirExists("dllcache"):
    removeDir("dllcache")
  dllName = dllName.split('.')[0]
  let nimCmd = "nim c -d:release -d=mingw --app=lib --nomain --cpu=" & arch & " -o:out/" & dllName & ".dll --nimcache=dllcache " & dllName & ".nim"
  echo "[*] Compiling origin C files"
  let originimProcess = execCmdEx(nimCmd, workingDir = ".")
  if originimProcess.exitCode != 0:
    getErrorInfo(originimProcess.output)
  echo "[*] Compiling origin C files successful"
  # 编译修改dll
  let jsonnode = parseFile("./dllcache/" & dllName & ".json")
  let compileCmdItem =jsonnode["compile"]
  var compileFile = ($compileCmdItem[len(compileCmdItem)-1][0]).strip(leading=true,trailing=true, chars = {'\"'})
  var fileContent = readFile(compileFile)
  fileContent = fileContent.replace("N_LIB_EXPORT N_CDECL(void, NimMain)(void)","N_LIB_PRIVATE N_CDECL(void, NimMain)(void)")
  writeFile(compileFile,fileContent)
  echo "[*] Patching origin C files successful"
  let compileCmd = $compileCmdItem[len(compileCmdItem)-1][1]
  let compileCmdClean =  compileCmd.strip(leading=true,trailing=true, chars = {'\"'})
  let nimProcess = execCmdEx(compileCmdClean, workingDir = ".")
  if nimProcess.exitCode != 0:
    getErrorInfo(nimProcess.output)
  echo "[*] Compiling patch C files successful"
  let linkCmdItem = $jsonnode["linkcmd"]
  let linkCmd = linkCmdItem.strip(leading=true,trailing=true, chars = {'\"'}).replace(dllName & ".dll",dllName & "-nomain.dll")
  let linkProcess = execCmdEx(linkCmd, workingDir = ".")
  if linkProcess.exitCode != 0:
    getErrorInfo(linkProcess.output)
  echo "[*] Linking patch C files successful"
  echo "[+] Done"
  quit(0)

when isMainModule:
  const banner = """                                                                         
  _    _   _       _          _   _   _               __  __           _         
 | |  | | (_)     | |        | \ | | (_)             |  \/  |         (_)        
 | |__| |  _    __| |   ___  |  \| |  _   _ __ ___   | \  / |   __ _   _   _ __  
 |  __  | | |  / _` |  / _ \ | . ` | | | | '_ ` _ \  | |\/| |  / _` | | | | '_ \ 
 | |  | | | | | (_| | |  __/ | |\  | | | | | | | | | | |  | | | (_| | | | | | | |
 |_|  |_| |_|  \__,_|  \___| |_| \_| |_| |_| |_| |_| |_|  |_|  \__,_| |_| |_| |_|
Author: S0cke3t
Github: https://github.com/DeEpinGh0st/HideNimMain
                                                """
  var p = newParser:
    help(banner & "\nHide the exported NimMain in a DLL")
    arg("name", help="Specify the dll name.", nargs = 1)
    option("-a","--arch", help="Specify the dll arch i386 or amd64.")
  try:
    var
      objName,arch: string
    var opts = p.parse()
    objName = opts.name
    arch = opts.arch
    if arch == "":
      echo "[!] No arch specified, redirect to i386"
      compileLib(objName)
    compileLib(objName,arch)
  except ShortCircuit as err:
    if err.flag == "argparse_help":
      echo err.help
      quit(1)
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)
