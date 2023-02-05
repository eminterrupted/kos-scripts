// #TODO Write the whole damn thing
@LazyGlobal off.
ClearScreen.

parameter param is list().

RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/sci").

DispMain(ScriptPath()).

OutMsg("Collecting recon film").
CollectSamples().
wait 1.
OutMsg("Complete").
