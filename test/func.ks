@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").

parameter param is 0, param2 is "vac".

print "Stage DV: " + round(AvailStageDV(param, param2), 2).