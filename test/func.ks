@lazyGlobal off.
clearScreen.

parameter param is 0.

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/vessel").

print "BurnDur: " + BurnDur(param).