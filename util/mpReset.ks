@lazyGlobal off.
clearScreen.

copypath("0:/boot/_bl", "/boot/_bl.ks").
set core:bootfilename to "/boot/_bl.ks".

runpath("0:/main/setup/setupPlan", false).

reboot.