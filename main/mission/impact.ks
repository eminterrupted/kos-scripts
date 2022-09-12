@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").
runOncePath("0:/lib/land").

DispMain(scriptPath()).

local orientation to "pro-sun".

if params:length > 0 
{
    set orientation to params[0].
}

lock steering to sVal.

until false
{
    local ttAtm to TimeToImpact(velocity:orbit:mag, ship:altitude - body:atm:height).
    local tti to TimeToImpact(velocity:orbit:mag, ship:altitude).
    local localGrav to GetLocalGravityOnVessel().
    local curAcc to GetTotalThrust(GetEngines("active")) / ship:mass.

    // if g_termChar = terminal:input:enter
    // {
    //     warpTo(time:seconds + min(tti - 180, ttAtm - 360)).
    // }
    DispImpactTelemetry(localGrav, curAcc, tti, ttAtm).
}



global function DispImpactTelemetry
{
    parameter _locGrav to 0,
              _curAcc to 0,
              tti to 0,
              ttAtm to 0.

    set g_line to 10.

    print "IMPACT UPLINK" at (0, g_line).
    print "-------------" at (0, cr()).
    print "ALTITUDE     : " + round(ship:altitude) + "m  " at (0, cr()).
    print "RADAR ALT    : " + round(alt:radar) + "m  " at (0, cr()). 
    print "CUR VELOCITY : " + round(ship:velocity:orbit:mag, 1) + "m/s  " at (0, cr()).
    print "VERT SPEED   : " + round(verticalSpeed, 1) + "m/s  " at (0, cr()).
    print "LOCAL GRAVITY: " + round(_locGrav, 2) + "m/s  " at (0, cr()).
    print "CUR ACCEL    : " + round(_curAcc, 2) + "m/s " at (0, cr()).
    cr().
    if body:atm:height > 0 
    {
        print "ATM HEIGHT   : " + body:atm:height + "m " at (0, cr()).
        print "ATM INTERFACE: " + round(ship:altitude - body:atm:height) + "m " at (0, cr()).
        cr().
        print "TIME TO ATM ENTRY : " + TimeSpan(ttAtm):full + "  " at (0, cr()).
    }
    print "TIME TO IMPACT    : " + TimeSpan(tti):full + "  " at (0, cr()).
}