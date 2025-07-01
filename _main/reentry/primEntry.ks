@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/util").

sas off. 

local sval to ship:srfRetrograde.
lock steering to sval.

until ship:altitude < Body:ATM:Height {
  print "waiting for reentry".
  wait 0.01.
  set sval to ship:srfRetrograde.
}

print "Reentry staging".

until stage:number = 1 {
  wait until stage:ready. stage. wait until Ship:Thrust < 0.25.
}

until ship:altitude <= 7250 {
  print "Waiting for fairing jettison alt {0} ":Format(Round(Ship:Altitude - 7250)).
  wait 0.01. set sval to ship:srfretrograde.
}

local fairings to ship:PartsTaggedPattern("descent\|frg").
local jettCount to 0.
print "Fairing jettison [{0}/{1}]":Format(jettCount, fairings:Length).
for p in fairings {
    local m to p:GetModule("ModuleProceduralFairing").
  m:DoEvent("jettison fairing").
  set jettCount to jettCount + 1.
  print "Fairing jettison [{0}/{1}]":Format(jettCount, fairings:Length).
}

print "Fairing jettison Complete":Format(jettCount, fairings:Length).

until alt:radar <= 0.1 {
  print "Final descent: {0} ":Format(Round(Alt:Radar)).
  wait 0.01.
}

local recStr to "Attempting recovery in {0}s ".
local g_TS to Time:Seconds + 3.
until Time:Seconds >= g_TS {
    print recStr:Format(Round(Time:Seconds - g_TS, 2)).
}

print "Recovering... ".
try_vessel_recovery(ship, 2).
