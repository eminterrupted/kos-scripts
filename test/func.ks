@lazyGlobal off.
clearScreen.

parameter param.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_mnv").
runOncePath("0:/lib/lib_nav").
runOncePath("0:/lib/lib_vessel").


local availDv to 0.
local elapsedTime to 0.


//local curMass to 0.
//local dryMass to 0.
//local wetMass to 0.

// print "ship:stagedDeltaV".
// print "-----------------".
// set elapsedTime to time:seconds.
// set availDv to ves_available_dv().
// set elapsedTime to time:seconds - elapsedTime.
// print "[VALUE]".
// print availDv.
// print " ".
// print "[LATENCY]".
// print " Round-trip: " + round(elapsedTime, 2).
// print "  _________________________  ".
// print " ".

// print "Calculated DeltaV".
// print "-----------------".
// set elapsedTime to time:seconds.
// set availDv to ves_available_dv_next().
// set elapsedTime to time:seconds - elapsedTime.
// print "[VALUE]".
// print availDv.
// print " ".
// print "[LATENCY]".
// print " Round-trip: " + round(elapsedTime, 2).
// print "  _________________________  ".
// print " ".

// print "Burn Duration (500 dV Sample)".
// print "-----------------------------".
// set elapsedTime to time:seconds.
// local burnDur to mnv_burn_dur(1584.1).
// local pass1 to time:seconds - elapsedTime.
// local fullDur to burnDur["Full"].
// local halfDur to burnDur["Half"].
// print "[DURATION]".
// print "Full: " + round(fullDur, 1).
// print "Half: " + round(halfDur, 1).
// print " ".
// print "[LATENCY]".
// print "Round-trip: " + round(pass1, 2).
// print "  _________________________  ".
// print " ".

print " ".
print " ".
print "ves_mass_for_parts Function Test".
print "--------------------------".
set elapsedTime to time:seconds.
print ves_mass_for_parts(param).
set elapsedTime to time:seconds - elapsedTime.
print " ".
print "[LATENCY]".
print "Round-trip: " + round(elapsedTime, 2).
print "  _________________________  ".
print " ".

// print " ".
// print " ".
// print "Stage Stats Function Test".
// print "--------------------------".
// set elapsedTime to time:seconds.
// print ves_stage_stats(param).
// set elapsedTime to time:seconds - elapsedTime.
// print " ".
// print "[LATENCY]".
// print "Round-trip: " + round(elapsedTime, 2).
// print "  _________________________  ".
// print " ".

// print " ".
// print " ".
// print "ves_stage_fuel_mass_next test".
// print "-----------------------------".
// set elapsedTime to time:seconds.
// print ves_stage_fuel_mass_next(param, list("LiquidFuel", "Oxidizer")).
// set elapsedTime to time:seconds - elapsedTime.
// print " ".
// print "[LATENCY]".
// print "Round-trip: " + round(elapsedTime, 2).
// print "  _________________________  ".
// print " ".
//  print " ".
//  print " ".
//  print "Mass".
//  print "----".
//  for p in ship:parts
//  {
//      set curMass to curMass + p:mass.
//      set wetMass to wetMass + p:wetmass.
//      set dryMass to dryMass + p:drymass.
//      print "CurMass: " + round(curMass, 3) + " | WetMass: " + round(wetMass, 3) + " | DryMass: " + round(dryMass, 3) + " | PartMass: " + round(p:mass, 3) + " | PartName: " + p:name.
//  }
// print " ".
// print "Ship:mass: " + round(ship:mass * 1000).

//
//print " ".
//print "ROBOTICS".
//print "--------".
//local ts to time:seconds. 
//print "Toggle".
//ves_toggle_robotics(ship:modulesNamed("ModuleRoboticServoHinge")).
//set ts to time:seconds - ts.
//print "Toggle completed in " + round(ts, 2).