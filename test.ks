@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
runOncePath("0:/lib/deploader").
runOncePath("0:/lib/module").
runOncePath("0:/lib/term").

// Declare Variables
local _init to false.
local _resetSize to false.
local _showTerm to false.

// Parse Params
if _params:length > 0 
{
  set _init to _params[0].
  if _params:length > 1 set _resetSize to _params[1].
  if _params:length > 2 set _showTerm to _params[2].
}

if _init 
{
    init_term(true, _resetSize, _showTerm).
}