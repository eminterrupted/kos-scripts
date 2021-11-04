@lazyGlobal off.
clearScreen.

parameter tgtPe,
          tgtAp,
          tgtInc,
          tgtLAN.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/kslib/lib_l_az_calc.ks").

local tVal to 0.
lock steering to heading(0, 90, 0).

launch_pad_gen().

ag10 off.

// Initiate countdown
launch_countdown(10).

// Launch commit
set tVal to 1.
lock throttle to tVal.
launch_pad_holdowns_retract().
if missionTime <= 0.01 stage.  // Release launch clamps at T-0.
ag10 off.   // Reset ag10 (is true to initiate launch)