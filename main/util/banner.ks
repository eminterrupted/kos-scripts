@LazyGlobal off.
ClearScreen.

parameter param to list().

RunOncePath("0:/lib/disp").

local str to "Sample String".
local pos to 0.
local errLvl to 0.

if param:length > 0
{
    set str to param[0].
    if param:length > 1 set pos to param[1].
    if param:length > 2 set errLvl to param[2].
}

DispMain(ScriptPath()).

OutTee(str, pos, errLvl).

wait 2.