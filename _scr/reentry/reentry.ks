@LazyGlobal off.
ClearScreen.

Parameter params is list().

RunOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

OutMsg("Running reentry routine").

local tgtAlt to body:atm:height + 25000.
local descentFairing to false.
local descentFairingAlt to 5000.

if params:length > 0
{
    set tgtAlt to body:atm:height + params[0].
    if params:length > 1 set descentFairing to params[1].
}

rcs on.
lock steering to s_Val.

OutMsg("Waiting until {0}m":Format(tgtAlt)).
until ship:altitude < tgtAlt
{
    set s_Val to ship:retrograde.
    wait 0.01.
}

OutMsg("Arming parachutes").
for m in Ship:ModulesNamed("RealChuteModule")
{
    m:DoAction("arm parachute", true).
}
wait 1.

OutMsg("Waiting for reentry interface").
until ship:altitude < body:atm:height
{
    set s_Val to ship:srfretrograde.
    wait 0.01.
}

OutMsg("Reentry interface").
until ship:altitude < descentFairingAlt
{
    set s_Val to ship:srfretrograde.
    wait 0.01.
}

if descentFairing
{
    OutMsg("Fairings jettison").
    JettisonFairings("reentryFairingJettison").
}
wait 2.

OutMsg("Releasing control").
wait 2.
