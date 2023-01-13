@LazyGlobal off.
ClearScreen.

Parameter params is list().

RunOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

OutMsg("Running reentry routine").

local tgtAlt to body:Atm:height + 25000.
local descentFairing to choose true if Ship:PartsTaggedPattern("fairing.reentry.\d*"):Length > 0 else false.
local descentFairingAlt to Ship:PartsTaggedPattern("fairing.reentry.\d*")[0]:Tag:Replace("fairing.reentry.",""):ToNumber(5000).

if params:Length > 0
{
    set tgtAlt to body:Atm:height + params[0].
    if params:Length > 1 set descentFairing to params[1].
    if params:Length > 2 set descentFairingAlt to params[2].
}

rcs on.
set s_Val to Ship:Facing.
lock Steering to s_Val.

set t_Val to 0.
lock Throttle to t_Val.

OutMsg("Waiting until {0}m":Format(tgtAlt)).
until ship:Altitude < tgtAlt
{
    set s_Val to ship:retrograde.
    wait 0.01.
}

OutMsg("Staging").
until Stage:Number = 1
{
    wait until Stage:Ready.
    Stage.
    wait 0.25.
}

OutMsg("Arming parachutes").
for m in Ship:ModulesNamed("RealChuteModule")
{
    m:DoAction("arm parachute", true).
}
wait 1.

OutMsg("Waiting for reentry interface").
until ship:Altitude < body:Atm:height
{
    set s_Val to ship:srfretrograde.
    wait 0.01.
}

OutMsg("Reentry interface").
until ship:Altitude < descentFairingAlt
{
    set s_Val to ship:srfretrograde.
    wait 0.01.
}

if descentFairing
{
    OutMsg("Fairings jettison").
    JettisonFairings("fairing.reentry").
}
wait 2.

OutMsg("Releasing control").
unlock Steering.
unlock Throttle.
wait 2.
