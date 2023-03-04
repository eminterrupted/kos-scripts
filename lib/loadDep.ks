// Config Values
set Config:IPU to 1024.

// Global vars
runOncePath("0:/lib/globals.ks").

// External libs
runOncePath("0:/kslib/lib_navball.ks").

// KUSP libs
runOncePath("0:/lib/disp.ks").
runOncePath("0:/lib/util.ks").
runOncePath("0:/lib/engines.ks").
runOncePath("0:/lib/vessel.ks").
runOncePath("0:/lib/data.ks").

DispMain(ScriptPath()).