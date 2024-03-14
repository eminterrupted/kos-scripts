@LazyGlobal off.
clearscreen.

parameter params is list().

RunOncePath("0:/lib/depLoader.ks").

Core:DoEvent("Open Terminal").

// Local vars
local ascAngle to 88.25.
local hsEngs to lex().
local hsFlag to false.
local launchCommit to false.
local MECO to -1.
local meSpoolTime to 0.
local rollFlag to false.
local seIgnitionTime to -1.
local sePresent to false.
local hsSpoolTime to 0.
local seSpinAt to 0.
local tgtAlt to Ship:Body:SOIRadius.
local tgtHdg to 30.

local MESpoolTime to 0.

local multistage to false.

local ts_MEStarted  to 0.
local ts_MEAbortBy  to 0.
local ts_SEIgnition to 0.

local mainEngs to list().
local padStage to Stage:Number - 1.
local shipEngs to GetShipEngines().
local upperEngs to list().

// TODO: Create some sort of display output
// Main loop
until g_Runmode < 0 or g_Abort
{    
    // Initialize and increment
    if g_Program = 0
    {
        SetProgram(3).
    }

    // Prelaunch checks
    else if g_Program = 3
    {

        // Main
        if g_Runmode > 2
        {
            SetRunmode(3).
            for m in Ship:ModulesNamed("LaunchClamp")
            {
                set padStage to min(padStage, m:Part:Stage).
            }

            // Find the main engines and populate mainEngs with them. 
            SetRunmode(4).
            for engStg in shipEngs:IGNSTG:Keys
            {
                SetRunmode(5).
                if engStg >= padStage 
                {
                    SetRunmode(6).
                    for engUID in shipEngs:IGNSTG[engStg]:UID
                    {
                        SetRunmode(7).
                        local eng to shipEngs:ENGUID[engUID]:ENG.
                        mainEngs:Add(eng).
                        
                        // While we have the MEs handy, we should determine MECO and spool time
                        set MECO to Max(MECO, shipEngs:ENGUID[engUID]:RATEDBURNTIME).
                        if engStg > padStage 
                        {
                            SetRunmode(8).
                            set MESpoolTime to Min(MESpoolTime, shipEngs:ENGUID[engUID]:SPOOLTIME * -1.05).
                            //set meSpoolTime to Max(meSpoolTime, shipEngs:ENGUID[engUID]:SPOOLTIME).
                        }
                    }
                }
                else
                {
                    SetRunMode(11).
                    set multiStage to True.
                }
            }

            // Next
            SetProgram(12). // 12: Setup Hotstaging
        }
        else if g_Runmode > 1
        {

        }
        else if g_RunMode > 0
        {
            // Next
            SetProgram(30). // 30: Begin vertical ascent
        }
        else if g_Runmode < 0
        {
            if g_ErrorCodeRef:CODES[g_ErrorCode]:Type = "FATAL"
            {
                set g_Abort     to True.
                set g_AbortCode to g_Program.
            }
        }
        else
        {
            if Ship:Status = "PRELAUNCH"
            {
                SetRunmode(3). // Do the checks
            }
            else
            {
                if Stage:Number > g_StageStop
                {
                    for i in range(Stage:Number - 1, g_StageStop, -1)
                    {
                        if ship:Engs:IGNSTG:HasKey(i)
                        {
                            set multistage to True.
                            break.
                        }
                    }
                }
                SetProgram(30). // Bypass the checks since we are already airborn
            }
        }
    }
        

    // Setup Hotstaging
    else if g_Program = 12
    {
        if g_Runmode > 0
        {   
            SetRunmode(2).
            for eng in Ship:PartsTaggedPattern("HS|HotStage")
            {
                if eng:IsType("Engine")
                {

                    if hsEngs:HasKey(eng:Stage) 
                    {
                        hsEngs[eng:Stage]:Add(eng).
                    }
                    else
                    {
                        set hsEngs[eng:Stage] to list(eng).
                    }
                    set hsFlag to true.
                    set hsSpoolTime to Max(hsSpoolTime, shipEngs:ENGUID[eng:UID]:SPOOLTIME).
                }
            }
            // Setup the countdown timers
            SetProgram(16).
        }
        else if g_Runmode < 0
        {
            set g_Abort to True.
            set g_AbortCode to g_Program.
        }
        else
        {
            SetRunmode(1).
        }
    }

    
    // TODO - uhh, most everything below. You haven't really progressed beyond here, lady. 

    // Setup the countdown timers
    else if g_Program = 16
    {
        if g_Runmode > 0
        {

        }
        else if g_Runmode < 0
        {

        }
        else
        {
            SetRunmode(1).
        }
    }
    UpdateState(True).

    // TODO: Write Abort Handler here
    if g_Abort
    {

    }

}

// Calculate MECO
local mainEngs to list().
local shipEngs to GetShipEngines().
local padStage to Stage:Number - 1.
for m in Ship:ModulesNamed("LaunchClamp")
{
    set padStage to min(padStage, m:Part:Stage).
}

for eng in Ship:Engines
{
    if eng:stage > padStage
    {
        print "[{0}] GettingBurnTime":Format(eng:Config).
        mainEngs:Add(eng).
        set MECO to Max(MECO, GetEngineBurnTime(eng)).
        set meSpoolTime to Max(meSpoolTime, eng:GetModule("ModuleEnginesRF"):GetField("Effective Spool-Up Time")).
    }
    else
    {
        set sePresent to true.
    }

    if eng:Tag:MatchesPattern("HS|HotStage")
    {
        if hsEngs:HasKey(eng:Stage) 
        {
            hsEngs[eng:Stage]:Add(eng).
        }
        else
        {
            set hsEngs[eng:Stage] to list(eng).
        }
        set hsFlag to true.
        set hsSpoolTime to Max(hsSpoolTime, eng:GetModule("ModuleEnginesRF"):GetField("Effective Spool-Up Time")).
    }
}
if sePresent
{
    set seIgnitionTime to MECO - (hsSpoolTime * 1.08).
    set seSpinAt to seIgnitionTime - 12.
}
else
{
    set seIgnitionTime to 999999999.
}

print "MECO values: ".
print " - MECO: {0}":Format(MECO).

print "Press Enter to go to space!".
print "Or backspace to not go to space".
until false
{
    GetTermChar().
    
    if g_TermChar = Terminal:Input:Enter
    {
        set launchCommit to true.
        break.
    }
    else if g_TermChar = Terminal:Input:Backspace
    {
        break.
    }
    else
    {
        set g_TermChar to "".
    }
}

if launchCommit
{
    set g_Program to 10.


    local sVal to Ship:Facing. //heading(tgtHdg, ascAngle, 0).
    lock Steering to sVal.
    print "P1: Setting up throttle".
    local tVal to  1.
    lock throttle to tVal.
    print "P2: Engine ignition".
    // until stage:number = 1

    until Ship:VerticalSpeed > 0.1 
    {
        stage.
        wait meSpoolTime + 0.05.
    }
    print "P3: Liftoff".
    print "P4: Waiting for MECO".
    local continueFlag to false.
    local steerFlag to true.

    set sVal to heading(tgtHdg, ascAngle, 0).

    until continueFlag
    {
        if MissionTime >= seIgnitionTime
        {
            if hsEngs:HasKey(Stage:Number - 1)
            {
                for eng in hsEngs[Stage:Number - 1]
                {
                    eng:Activate.
                }
            }
            set seIgnitionTime to Time:Seconds + 999999.
        }
        else if MissionTime >= MECO or Ship:AvailableThrust <= 0.001
        {
            if Stage:Number > g_StageStop
            {
                set tVal to 1.
                for eng in mainEngs
                {
                    eng:Shutdown.
                }
                until Stage:Number = g_StageStop
                {
                    print "P5: Staging".
                    stage.
                    wait 0.25.
                }
                print "P6: Waiting until alt target or SECO".
            }
            else
            {
                set continueFlag to true.
            }
        }
        else if MissionTime > seSpinAt and steerFlag
        {
            print "P6.5: Unlocking steering".
            unlock Steering.
            set Ship:Control:Roll to 1.
            set steerFlag to false.
            set rollFlag to true.
        }
    }
    print "P7: Waiting until Apoapsis".

    wait until ETA:Apoapsis <= 5.
}
else
{
    print " ".
    print "* * * * * * * * * *".
    print "* Aborting launch *".
    print "* * * * * * * * * *".
    print " ".
}