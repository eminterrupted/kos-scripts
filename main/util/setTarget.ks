@LazyGlobal off. 
ClearScreen.

parameter tgt.

RunOncePath("0:/lib/disp").
RunOncePath("0:/lib/util").
RunOncePath("0:/lib/vessel").

DispMain(ScriptPath()).

set tgt to GetOrbitable(tgt).

OutMsg("Setting target: " + tgt:name).
Set Target to tgt.
Wait 1.