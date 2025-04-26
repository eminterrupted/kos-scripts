@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/kslib/lib_loader.ks").
RunOncePath("0:/env/types/_init.ks").
RunOncePath("0:/env/global/_init.ks").
RunOncePath("0:/lib/util.ks").
RunOncePath("0:/lib/control.ks").
RunOncePath("0:/lib/module.ks").
RunOncePath("0:/lib/string.ks").
RunOncePath("0:/lib/term.ks").

// Declare Variables
local _inputFiles is list().
local _generateHash is False.
local _hashType is 0.

// Parse Params
if _params:length > 0 {

  set _inputFiles to _params.
}

for _file in _inputFiles {
    if Exists(_file) {
        
        local inFile to Open(_inputFile).
        local inContent to inFile:ReadAll().
        print inContent:String.
    }
}