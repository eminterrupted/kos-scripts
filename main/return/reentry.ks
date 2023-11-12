@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/libLoader").
runOncePath("0:/lib/sci").

set g_MainProcess to ScriptPath().
DispMain().

SAS off.

local chuteStatus to "N/A".
local fairings to ship:PartsTaggedPattern("fairing\|reentry").
local jettAlt to 5000.

local gemBDBChute to choose Ship:PartsNamed("ROC-GeminiParachuteBDB")[0] if Ship:PartsNamed("ROC-GeminiParachuteBDB"):Length > 0 else Core:Part.
local parachutes to ship:modulesnamed("RealChuteModule").
local payloadStage to g_StageLimit.
local reentryTgt to (ship:body:atm:height * 0.425).
local retroFire to false.
local retroStage to payloadStage.
local retroType to 1. // 1 = Mnv, 0 = Manual at Apo
local spinStab to false.
local stagingAlt to ship:body:atm:height.
local ts to time:seconds.

set r_Val to 180.
set s_Val to ship:facing.
lock steering to s_Val.

set t_Val to 0.
lock throttle to t_Val.


///Params
//retroFire: bool, fire rockets to deorbit
//spinStab: bool, stages to fire spin stablization motors
//stagingAlt:scalar, altitude of CSM jetison 
//retroStage:scalar, stage number of the retro rocket fire
if params:length > 0 
{
    set stagingAlt to params[0].
    if params:length > 1 set retroFire to params[1].
    if params:length > 2 set retroType to params[2].
    if params:length > 3 set retroStage to params[3].
    if params:length > 4 set spinStab to params[4].
}
local startAlt to stagingAlt + 2500.

if fairings:length > 0
{
    if fairings[0]:Tag:Split("|"):Length > 2 
    {
        set jettAlt to ParseStringScalar(fairings[0]:Tag:Split("|")[2], 5000).
    }
}
OutMsg("Fairings present: {0} ({1})":Format(fairings:Length, jettAlt)).
wait 3.

local mode to "descent".
local doneFlag to choose false if Ship:VerticalSpeed > 0 else true.

if retroFire
{
    OutMsg("Retro burn initiated").
    if retroType = 1
    {
        SetNextStageLimit(retroStage).
        ExecNodeBurn(NextNode).
    }
}


// OutMsg("Enter: Warp to Ap | Home: Update Reentry Alt").
// OutInfo("Down: Wait until descent | Up: Wait until ascent").
// OutInfo("End: Begin reentry procedures now | PageDown: Skip reentry burn", 1).

until doneFlag
{
    OutMsg("Enter: Continue to Ap | Home: Update Reentry Alt").
    OutInfo("Down: Wait until descent | Up: Wait until ascent").
    OutInfo("End: Begin reentry procedures now | PageDown: Skip reentry burn", 1).
    GetTermChar().
    if g_TermChar <> ""
    {
        OutInfo("retroFire: " + retroFire, 1).
        if g_TermChar = terminal:input:enter
        {
            //InitWarp(time:seconds + eta:apoapsis, "apoapsis").
            set mode to "ap".
        }
        else if g_TermChar = Terminal:Input:HomeCursor
        {
            //InitWarp(time:seconds + eta:periapsis, "periapsis").
            local workingAlt to stagingAlt.
            local updateDoneFlag to False.
            set g_TermChar to "".

            until updateDoneFlag
            {
                GetTermChar().
                OutMsg("Update staging altitude target [{0}]":Format(workingAlt)).
                set workingAlt to UpdateTermScalar(workingAlt, list(250, 1000, 5000, 10000)).
                if g_TermChar = Terminal:Input:Enter
                {
                    set updateDoneFlag to True.
                    set stagingAlt to workingAlt.
                    OutMsg("Staging Altitude Target updated! [{0}]":Format(stagingAlt)).
                    OutInfo().
                    OutInfo("",1).
                }
            }
        }
        else if g_TermChar = Terminal:Input:UpCursorOne
        {
            set mode to "ascent".
        }
        else if g_TermChar = Terminal:Input:DownCursorOne
        {
            set mode to "descent".
        }
        else if g_TermChar = terminal:input:endcursor
        {
            set mode to "immediate".
            OutInfo("Immediate reentry procedure mode").
            OutInfo("", 1).
            wait 0.5.
        }
        else if g_TermChar = terminal:input:PageDownCursor
        {
            set retroFire to false.
            OutInfo("retroFire: " + retroFire, 1).
        }
        set g_TermChar to "".
    }

    if mode = "descent" 
    {
        if ship:VerticalSpeed <= 0 set doneFlag to true.
    }
    else if mode = "ascent" 
    {
        if ship:VerticalSpeed >= 0 set doneFlag to true.
    }
    else if mode = "ap"
    {
        if eta:Apoapsis <= 15 set doneFlag to true.
    }
    else if mode = "pe"
    {
        if eta:Periapsis <= 15 set doneFlag to true.
    }
    else if mode = "immediate"
    {
        set doneFlag to true.
    }

    // DispTelemetry().
    wait 0.01.
}
OutInfo().
OutInfo("", 1).

OutMsg("Beginning Reentry Procedure").
wait 1.

if retroFire and ship:periapsis > reentryTgt
{
    OutInfo("Target reentry alt: " + round(reentryTgt) + " (" + round(ship:periapsis) + ")", 1).
    set s_Val to ship:retrograde.
    local settleTime to 5.
    local progCounter to 0.
    local progTimer to time:seconds + 2.5.
    local progMarker to "".
    set ts to time:seconds + settleTime.
    until time:seconds >= ts
    {
        if not GetSteeringError(0.050)
        {
            set ts to time:seconds + settleTime.
            set progCounter to progTimer - time:seconds.
            if progCounter <= 0 
            {
                set progMarker to "".
                set progTimer to time:seconds + 2.5.
            }
            else if progCounter >= 2 set progMarker to "".
            else if progCounter >= 1.5 set progMarker to ".".
            else if progCounter >= 1 set progMarker to "..".
            else if progCounter >= 0.5 set progMarker to "...".
            OutMsg("Retro alignment in progress" + progMarker).
            set progCounter to 0.
        }
        else
        {
            OutInfo("Settle time remaining: " + round(ts - time:seconds, 2)).
        }

        // DispTelemetry().
        wait 0.05.
    }
    OutInfo().
    OutInfo("", 1).

    // if stage:number > payloadStage
    // {
    //     OutMsg("[" + stage:number + "] Staging to payloadStage [" + payloadStage + "] for retro fire").
    //     until false 
    //     {
    //         if stage:number = payloadStage break.
    //         wait 0.50.
    //         if stage:ready stage.
    //         wait 0.50.
    //     }
    // }
    
    if spinStab
    {
        OutMsg("Initiating spin stabilization").
        unlock steering.
        set ts to time:seconds + 7.5.
        until time:seconds > ts 
        {
            set ship:control:roll to 0.5.
            // DispTelemetry().
            wait 0.01.
        }
        OutMsg("Spin stabilization complete").
    }

    OutMsg("Firing retro rockets to stage " + retroStage).
    set t_Val to 1.
    until stage:number <= retroStage
    {
        stage.
        wait until stage:ready.
    }
    wait 0.05.
    local perfObj to GetEnginePerformanceData(GetActiveEngines()).
    until perfObj:ThrustAvailPres <= 0.1 or ship:periapsis <= reentryTgt
    {
        if stage = 1 set t_Val to 0.
        else if ship:periapsis <= reentryTgt + 10000
        {
            set t_Val to Max(0, Min(1, (ship:periapsis - reentryTgt) / 10000)).
        }
        // DispTelemetry().
    }
    set t_Val to 0.
    OutMsg("Retro fire complete").
    wait 1.
    if spinStab
    {
        OutMsg("Stabilizing spin").
        set ts to time:seconds + 7.5.
        until time:seconds > ts
        {
            set ship:control:roll to -1.
            // DispTelemetry().
            wait 0.01.
            set ship:control:neutralize to true.
        }
    }
    OutInfo("", 1).
}

set s_Val to lookDirUp(ship:retrograde:vector, Sun:Position).

OutMsg("Waiting until altitude <= " + startAlt).
Terminal:Input:Clear.   // Clear the terminal input so we don't auto warp from an old keypress


OutInfo("Press Home to take control, End to relinquish").
until ship:altitude <= startAlt
{
    GetTermChar().
    
    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutInfo("Control released").
        unlock steering.
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        OutInfo("Control locked").
        lock steering to s_Val.
    }
    else
    {
        // set s_Val to Ship:Retrograde. 
        set r_Val to g_rollCheckObj:DEL:UPDATE:Call(g_TermChar).
        set s_Val to LookDirUp(-Ship:Velocity:Orbit, -Body:Position) + r(0, 0, r_Val).
        Terminal:Input:Clear().
    }
    set g_TermChar to "".
    DispReentryTelemetry().
}

if warp > 0 set warp to 0.
wait until kuniverse:timewarp:issettled.

OutMsg("Arming Parachute(s)").
if parachutes:length > 0 
{
    if parachutes[0]:name = "RealChuteModule" 
    {
        set chuteStatus to "CHUTE_FOUND".
        for c in parachutes 
        {
            if DoEvent(c, "arm parachute")
            {
                set chuteStatus to "ARMED(E)".
            }
            else
            {
                if DoAction(c, "arm parachute", True) 
                {
                    set chuteStatus to "ARMED(A)".
                }
                else
                {
                    set chuteStatus to "ARM_AUTO_ERR".
                    when Alt:Radar < 20000 then
                    {
                        if not DoEvent(c, "deploy parachute")
                        {
                            DoAction(c, "deploy parachute", True).
                        }
                    }
                }
            }
        }
    }
    else if parachutes[0]:name = "ModuleParachute"
    {
        when parachutes[0]:getField("safe to deploy?") = "Safe" then 
        {
            for c in parachutes
            {
                if not DoEvent(c, "deploy chute")
                {
                    DoAction(c, "deploy chute", True).
                }
            }
        }
    }
}
wait 1.

// Science data collection
local dataDrive to Core:Part.
if Ship:PartsNamedPattern("SampleReturnCapsule"):Length > 0
{
    set dataDrive to Ship:PartsNamedPattern("SampleReturnCapsule")[0].
}
local sciTransferResult to TransferSciData(Core:Part).
if sciTransferResult
{
    wait 2.
}
else
{
    
}

for m in ship:ModulesNamed("ModuleRCSFX")
{
    if not m:getField("RCS")
    {
        m:SetField("RCS", true).
    }
}
RCS on.

// Staging
if stage:number > 1
{
    // set s_Val to body:position.
    // OutMsg("Waiting until staging altitude: " + stagingAlt).
    // until ship:altitude <= stagingAlt
    // {
    //     set s_Val to GetSteeringDir("body-sun").
    //     DispTelemetry().
    // }

    // if warp > 0 set warp to 0.
    // wait until kuniverse:timewarp:issettled.
    // set s_Val to GetSteeringDir("body-sun").
    // wait 5.

    OutMsg("Staging").
    until stage:number <= 1 
    {
        stage.
        wait 5.
    }
}

// set ts to time:seconds + 5.
OutMsg("Waiting for reentry interface").
until ship:altitude <= body:atm:height + 1000
{
    GetTermChar().
    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutInfo("Control released").
        unlock steering.
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        OutInfo("Control locked").
        lock steering to s_Val.
    }
    else
    {
        // set s_Val to Ship:SrfRetrograde. 
        set r_Val to g_rollCheckObj:DEL:UPDATE:Call(g_TermChar).
        set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val).
        Terminal:Input:Clear().
    }
    set g_TermChar to "".
    
    DispReentryTelemetry().
    
    // DispGeneric().
    // if CheckWarpKey()
    // {
    //     OutInfo("Warping to atmospheric reentry: " + body:atm:height).
    //     WarpToAlt(body:atm:height + 1000).
    //     terminal:input:clear.
    // }
}
OutInfo().

until ship:altitude <= body:atm:height
{
    GetTermChar().
    
    set r_Val to g_rollCheckObj:DEL:UPDATE:Call(g_TermChar).
    set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val).
    
    DispReentryTelemetry().
}

OutMsg("Reentry Interface").

until ship:groundspeed <= 1500 and ship:altitude <= 20000
{
    GetTermChar().

    set r_Val to g_rollCheckObj:DEL:UPDATE:Call(g_TermChar).

    if g_TermChar = Terminal:Input:HomeCursor
    {
        OutInfo("Control released").
        unlock steering.
    }
    else if g_TermChar = Terminal:Input:EndCursor
    {
        OutInfo("Control locked").
        lock steering to s_Val.
    }
    else
    {
        Terminal:Input:Clear().
        set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val). 
    }
    set g_TermChar to "".
    
    // set s_Val to ship:SrfRetrograde.
    DispReentryTelemetry().
}
wait 1.

if gemBDBChute:UID <> Core:Part:UID DoEvent(gemBDBChute:GetModule("ModuleDecouple"), "decouple").
unlock steering.
OutMsg("Control released | Parachute Status: [{0}]":Format(chuteStatus)).

until ALT:RADAR <= jettAlt
{
    DispReentryTelemetry().
}

for f in fairings
{
    local m to f:GetModule("ProceduralFairingDecoupler").
    if not DoEvent(m, "jettison fairing")
    {
        DoAction(m, "jettison fairing", true).
    }
}
LIGHTS on.

until alt:radar <= 500
{
    DispReentryTelemetry().
}

// Deploy the Mercury capsule landing bag if present
local aniMods to Ship:ModulesNamed("ModuleAnimateGeneric").
if aniMods:Length > 0
{
    for m in aniMods
    {
        if DoEvent(m, "Deploy Landing Bag")
        {
            OutMsg("Landing bag deploy").
            Break.
        }
    }
}

until alt:radar <= 25
{
    DispReentryTelemetry().
}
if Kuniverse:Timewarp:Warp > 0 
{
    set Kuniverse:Timewarp:Warp to 0.
}
until alt:radar <= 5
{
    DispReentryTelemetry().
}
OutMsg("Preparing for recovery").
wait 1.

TryRecoverVessel(Ship, 30).