@LazyGlobal off.
clearscreen.

parameter _params is list().

RunOncePath("0:/lib/depLoader").

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
local seSpoolTime to 0.
local seSpinAt to 0.
local tgtAlt to Ship:Body:SOIRadius.
local tgtHdg to 30.

local mainEngs to list().
local padStage to Stage:Number - 1.
local shipEngs to GetShipEngines().

// TODO: Create some sort of display output
// Main loop
until g_Runmode < 0 or g_Abort
{    
    // Prelaunch checks
    if g_Program = 0
    {
        set g_RunMode to 1.

        // Check to see if we are actually in prelaunch
        if Ship:Status = "PRELAUNCH"
        {
            // Get the stage of the launch pad
            set g_Runmode to 5.
            for m in Ship:ModulesNamed("LaunchClamp")
            {
                set padStage to min(padStage, m:Part:Stage).
            }

            // Find the main engines and populate mainEngs with them. 
            set g_Runmode to 10.
            for engStg in shipEngs:IGNSTG:Keys
            {
                if engStg >= padStage 
                {
                    for eng in shipEngs:IGNSTG[engStg]
                    {
                        mainEngs:Add(eng).
                        
                        // While we have the MEs handy, we should determine MECO
                        set MECO to Max(MECO, GetEngineBurnTime(eng)).
                    }
                }
            }

            // Get the burn time for the engine(s)
            for eng in mainEngs
            {
                set meSpoolTime to Max(meSpoolTime, eng:GetModule("ModuleEnginesRF"):GetField("Effective Spool-Up Time")).
            }

            set g_Program to 10.
            set g_RunMode to 1.
        }
        else
        {
            set g_Program to 30.
            set g_Runmode to 1.
        }
        
    }
    else if g_Runmode = 10
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
        set seSpoolTime to Max(seSpoolTime, eng:GetModule("ModuleEnginesRF"):GetField("Effective Spool-Up Time")).
    }
}
if sePresent
{
    set seIgnitionTime to MECO - (seSpoolTime * 1.08).
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

    print "P8: Waiting to RSO".

    wait until Ship:Altitude <= 25000.
    core:part:GetModule("ModuleRangeSafety"):DoEvent("Range Safety").
}
else
{
    print " ".
    print "* * * * * * * * * *".
    print "* Aborting launch *".
    print "* * * * * * * * * *".
    print " ".
}