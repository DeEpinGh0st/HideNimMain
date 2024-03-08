import winim/lean

proc NimMain() {.nimcall, importc.}

proc bingo(): string {.cdecl, exportc, dynlib.} = 
    return "Hello, world from Nim DLL!"

proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
  NimMain()

  if fdwReason == DLL_PROCESS_ATTACH:
    MessageBox(0, "Hello, world !", "Nim is Powerful", 0)

  return true