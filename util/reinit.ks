@LazyGlobal off. 
ClearScreen.

parameter _script is "",
          _params is list().

if exists(Path("state.txt")) DeletePath("state.txt").

if _script:Length > 0 RunPath(_script, _params).