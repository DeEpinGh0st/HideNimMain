import osproc
import json
import strutils
import os


proc getErrorInfo(output: string): void = 
    while true:
        let output = readLines(output)
        if output.len == 0:
            break
        echo output
    quit(0)

proc compileLib() =
  if dirExists("dllcache"):
    removeDir("dllcache")
  # 定义要执行的编译命令
  let nimCmd = "nim c -d:release -d=mingw --app=lib --nomain --cpu=amd64 --nimcache=dllcache dll.nim"
  # 执行编译命令并捕获输出
  echo "[*] Compiling origin C files"
  let originimProcess = execCmdEx(nimCmd, workingDir = ".")
  if originimProcess.exitCode != 0:
    getErrorInfo(originimProcess.output)
  echo "[*] Compiling origin C files successful"
  # 编译修改dll
  # 解析json字符串
  let jsonnode = parseFile("./dllcache/Dll.json")
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
  let linkCmd = linkCmdItem.strip(leading=true,trailing=true, chars = {'\"'}).replace("Dll.dll","Dll-x.dll")
  let linkProcess = execCmdEx(linkCmd, workingDir = ".")
  if linkProcess.exitCode != 0:
    getErrorInfo(linkProcess.output)
  echo "[*] Linking patch C files successful"
  echo "[+] Done"

when isMainModule:
    compileLib()
