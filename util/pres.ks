@LazyGlobal off.
ClearScreen.

parameter logVals to false.
runOncePath("0:/lib/libLoader").
RunOncePath("0:/lib/vessel").

local logPath to Path("0:/data/test/PressureLogs/Pres_{0}.csv":Format(Ship:Name:Replace(" ","_"))).
local logObj to list().
if Exists(logPath)
{
    set logObj to ReadJson(logObj).
}
else
{

}

local l_line to 8.
//print "Pressure Tracker v0.01".
OutMsg("Waiting for liftoff...").
PresDisp().
wait until Ship:Status <> "PRELAUNCH".

OutMsg("Launch commenced").

until Ship:Altitude >= Body:Atm:Height
{
    PresDisp().
}

// DispClr(3,15).
OutMsg("Reached space!").
wait 1.


local function PresDisp
{
    set g_line to l_line.
    local curPres to Ship:Body:Atm:AltitudePressure(Ship:Altitude).
    print "{0, -15}): {1} ":Format("ALTITUDE (M)", round(Ship:Altitude)) at (2, cr()).
    print "{0, -15}): {1} ":Format("AOA (DEG)", round(GetAoA()[0], 4)) at (2, cr()).
    cr().
    print "{0, -15}): {1} ":Format("PRESSURE (BAR)", round(curPres, 6)) at (2, cr()).
    print "{0, -15}): {1} ":Format("PRESSURE (KPA)", round(curPres * Constant:ATMtoKPA, 6)) at (2, cr()).
    print "{0, -15}): {1} ":Format("Q-PRES (IDK)",  round(Ship:Q, 6)) at (2, cr()).
    if logVals 
    {
        
    }
    wait 0.01.
}


local function GetAoA
{
    return pitch_for(Ship, Ship:Facing) - pitch_for(Ship, Ship:Velocity:Surface:Mag).
}