@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/libLoader.ks").
runOncePath("0:/lib/sci.ks").

set g_MainProc to ScriptPath().
DispMain().

SAS off.

local presLog to "0:/data/log/Earth_Pressure.csv".

local chuteStatus to "N/A".
local fairings to ship:PartsTaggedPattern("^(ARE|reentry|return|descent)\|(FRNG|fairing)").
local jettAlt to 5000.
local mainChuteDeployAlt to 2500.

local gemBDBChute to choose Ship:PartsNamed("ROC-GeminiParachuteBDB")[0] if Ship:PartsNamed("ROC-GeminiParachuteBDB"):Length > 0 else Core:Part.
local parachutes to ship:modulesnamed("RealChuteModule").
local payloadStage to g_StageLimit.
local reentryTgt to (ship:body:atm:height * 0.425).
local retroFire to false.
local retroStage to payloadStage.
local retroType to 1. // 1 = Mnv, 0 = Manual at Apo
local spinStab to false.
local stagingAlt to ship:body:atm:height.
local stopStage to 1.
local ts to Time:Seconds.

set r_Val to 180.
set s_Val to ship:facing.
lock steering to s_Val.

// set t_Val to 0.
// lock throttle to t_Val.


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

LogPressure(True).

if retroFire or HasNode
{
    OutMsg("Retro burn initiated").
    if retroType = 1 or HasNode
    {
        SetNextStageLimit(Max(stopStage + 1, retroStage)).
        ExecNodeBurn_Next(NextNode, 2).
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
        if g_TermChar = Terminal:Input:Enter
        {
            //InitWarp(Time:Seconds + eta:apoapsis, "apoapsis").
            set mode to "ap".
        }
        else if g_TermChar = Terminal:Input:HomeCursor
        {
            //InitWarp(Time:Seconds + eta:periapsis, "periapsis").
            local workingAlt to stagingAlt.
            local updateDoneFlag to False.
            set g_TermChar to "".

            until updateDoneFlag
            {
                GetTermChar().
                OutMsg("Update staging altitude target [{0}]":Format(workingAlt)).
                if g_TermChar = Terminal:Input:Enter
                {
                    set updateDoneFlag to True.
                    set stagingAlt to workingAlt.
                    OutMsg("Staging Altitude Target updated! [{0}]":Format(stagingAlt)).
                    OutInfo().
                    OutInfo("",1).
                }
                else
                {
                    set workingAlt to UpdateTermScalar(workingAlt, list(250, 1000, 5000, 10000)).
                }
                set g_TermChar to "".
            }
            set startAlt to stagingAlt + 2500.
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

set s_Val to lookDirUp(ship:srfretrograde:vector, -Body:Position).
lock steering to s_Val. 

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
        set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val).
        Terminal:Input:Clear().
    }
    set g_TermChar to "".
    DispReentryTelemetry().
    // if Ship:Altitude <= Body:ATM:Height
    // {
        LogPressure().
    // }
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
            else if not c:Part:Name:MatchesPattern("Gemini")
            {
                if DoAction(c, "arm parachute", True) 
                {
                    set chuteStatus to "ARMED(A)".
                }
                else
                {
                    set chuteStatus to "ARM_AUTO_ERR".
                    when Alt:Radar < 10000 then
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
wait 0.05.

// Science data collection
local dataDrive to Core:Part.
if Ship:PartsNamedPattern("SampleReturnCapsule"):Length > 0
{
    set dataDrive to Ship:PartsNamedPattern("SampleReturnCapsule")[0].
}
local sciTransferResult to TransferSciData(Core:Part).
if sciTransferResult
{
    wait 0.325.
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
local proAng to vAng(Ship:Facing:ForeVector, s_Val:Vector).
local lastAng to proAng.
local angDiff to lastAng - proAng.
set doneFlag to False.
set g_TS0 to 0.
if Stage:Number > stopStage
{
    until doneFlag
    {
        set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val).
        set lastAng to proAng.
        set proAng to vAng(Ship:Facing:ForeVector, s_Val:Vector).
        set angDiff to lastAng - proAng.
        OutMsg("Aligning to retrograde ({0}/0.25)":Format(Round(angDiff, 2))).
        if Body:ATM:AltitudePressure(Ship:Altitude) > 0.001 
        {
            set doneFlag to True.
        }
        if Ship:ModulesNamed("ModuleRCSFX"):Length = 0
        {
            set doneFlag to True.
        }
        if proAng < 1 and angDiff < 0.250
        {
            if g_TS0 = 0
            {
                set g_TS0 to Time:Seconds + 3.25.
            }
            else if Time:Seconds > g_TS0 
            {
                set doneFlag to True.
            }
            OutInfo("Settle time for retro staging: [{0}]":Format(Round(g_TS0 - Time:Seconds, 2))).
        }
        else
        {
            set g_TS0 to 0.
            OutInfo().
        }
    }
    set doneFlag to False.
}

OutMsg("Aligned to retro").

if stage:number > 1
{
    // Do we need to spin stabilize the capsule?
    local spinDCs to Ship:PartsTaggedPattern("SpinDC\|\d*").

    if spinDCs:Length > 0
    {
        for dc in spinDCs
        {
            if dc:Stage = Stage:Number - 1
            {
                OutMsg("Initiating Spin-Stabilization").
                local spinTime to dc:Tag:Split("|")[1]:ToNumber(1).
                set Ship:Control:Roll to 1.
                set g_TS to Time:Seconds + spinTime.
                until Time:Seconds > g_TS
                {
                    OutInfo("Time remaining: {0}s":Format(Round(g_TS - Time:Seconds, 2))).
                }
                OutInfo().
                set Ship:Control:Roll to 0.
                break.
            }
        }
    }

    set ts to Time:Seconds.
    until Stage:Number <= 1 
    {
        OutMsg("Staging [{0}->{1}]":Format(Stage:Number, Stage:Number - 1)).
        until ts and Ship:Thrust <= 0.02 and Stage:Ready
        {
            OutInfo("TS: {0}s | THR: {1}kn | RDY: {2} ":Format(Round(Time:Seconds - ts, 2), Round(Ship:Thrust, 2), Stage:Ready)).
        }
        wait 0.325.
        stage.
        set ts to Time:Seconds + 5.
    }
    set Ship:Control:Fore to 1.
    wait 6.
    set Ship:Control:Fore to 0.
}

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

// TODO: Module[AdjustableCoMShifter] 
// -- Fields: com offset limit
// -- Events: turn descent mode on / off
// -- Actions: toggle descent mode

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
    else if g_TermChar:MatchesPattern("(Q|q|W|w|E|e)")
    {
        if g_TermChar = char(87) // W (Fast Stop)
        {
            set Ship:Control:Roll to 0.
            set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val). 
        }
        else 
        {
            if g_TermChar = char(119) // w (Coast Stop)
            {
                set Ship:Control:Roll to 0.
            }
            else if g_TermChar = char(81) // Q (Fast Roll)
            {
                set Ship:Control:Roll to Ship:Control:Roll - 0.1.
            }
            else if g_TermChar = char(113) // q (Slow Roll)
            {
                set Ship:Control:Roll to Ship:Control:Roll - 0.25.
            }
            else if g_TermChar = char(69) // E (Fast Roll)
            {
                set Ship:Control:Roll to Ship:Control:Roll + 0.1.
            }
            else if g_TermChar = char(101) // e (Slow Roll)
            {
                set Ship:Control:Roll to Ship:Control:Roll + 0.25.
            }
            OutInfo("Roll: {0} ":Format(Ship:Control:Roll)).
            set s_Val to -Ship:Velocity:Surface.
        }
    }
    else
    {
        Terminal:Input:Clear().
        set s_Val to LookDirUp(-Ship:Velocity:Surface, -Body:Position) + r(0, 0, r_Val). 
    }
    set g_TermChar to "".
    
    // set s_Val to ship:SrfRetrograde.
    // LogPressure().
    DispReentryTelemetry().
}
wait 0.05.

unlock steering.
OutMsg("Control released | Parachute Status: [{0}]":Format(chuteStatus)).

until ALT:RADAR <= jettAlt + 500
{
    LogPressure().
    DispReentryTelemetry().
}

local oldWarp to Warp.
if Warp > 0
{
    set Warp to 0.
}

until ALT:RADAR <= jettAlt
{
    LogPressure().
    DispReentryTelemetry().
}

local fairingMod to "ProceduralFairingDecoupler".
local dcMod to "ProceduralDecoupler".
for f in fairings
{
    if f:HasModule(fairingMod)
    {
        local m to f:GetModule("ProceduralFairingDecoupler").
        if not DoEvent(m, "jettison fairing")
        {
            DoAction(m, "jettison fairing", true).
        }
    }
    else if f:HasModule(dcMod)
    {
        if not DoEvent(m, "Decouple")
        {
            DoAction(m, "decouple", true).
        }
    }
}
Lights on.

until ALT:RADAR <= jettAlt - 500
{
    LogPressure().
    DispReentryTelemetry().
}

if oldWarp > 0
{
    set Warp to oldWarp.
}

until Alt:Radar <= mainChuteDeployAlt
{
    LogPressure().
    DispReentryTelemetry().
}
if gemBDBChute:UID <> Core:Part:UID DoEvent(gemBDBChute:GetModule("ModuleDecouple"), "decouple").

if warp > 1 
{
    set warp to 1.
}
local mercRCSParts to Ship:PartsNamedPattern("ROC-MercuryRCS(2)?BDB").
if mercRCSParts:Length > 0
{
    local m to mercRCSParts[0]:GetModule("ModuleDecouple").
    if DoEvent(m, "Jettison Nose Unit") = 2
    {
        DoEvent(m, "Decouple").
    }
}

until Alt:Radar <= 500
{
    LogPressure().
    DispReentryTelemetry().
}

// Deploy the Mercury capsule landing bag if present\
if Ship:PartsNamed("ROC-MercuryHS"):Length > 0
{
    DoEvent(Ship:PartsNamed("ROC-MercuryHS")[0]:GetModule("ModuleAnimateGeneric"), "Deploy Landing Bag").
}

until Alt:Radar <= 25
{
    LogPressure().
    DispReentryTelemetry().
}
if Kuniverse:Timewarp:Warp > 0 
{
    set Kuniverse:Timewarp:Warp to 0.
}
until Alt:Radar <= 5
{
    LogPressure().
    DispReentryTelemetry().
}
OutMsg("Preparing for recovery").
wait 0.25.

TryRecoverVessel(Ship, 30).

local function LogPressure
{
    parameter _init is False.

    return False.
}