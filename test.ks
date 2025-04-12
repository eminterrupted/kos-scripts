@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
runOncePath("0:/_kslib/lib_loader.ks").
runOncePath("0:/_lib/type_loader.ks").
runOncePath("0:/_lib/util.ks").
runOncePath("0:/_lib/control.ks").
runOncePath("0:/_lib/module.ks").
runOncePath("0:/_lib/term.ks").

// Declare Variables
local _boxType to "Base".
local _style to "Normal".

// Parse Params
if _params:length > 0 
{
  set _boxType to _params[0].
  if _params:length > 1 set _style to _params[1].
}

// if _init 
// {
//     init_term(true, _resetSize, _showTerm).
// }

local boxDat to Shapes:Box:Base:Copy.
local boxStyle to Styles[_style]:Copy.

draw_box_data(boxDat, boxStyle).