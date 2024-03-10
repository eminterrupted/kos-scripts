@LazyGlobal off.
clearscreen.

RunOncePath("0:/lib/depLoader").

Core:DoEvent("Open Terminal").

local ascAngle to 86.
local jettAlt to 10000.
local launchCommit to false.
local spinAt to 72.
local tgtAlt to 192500.
local tgtHdg to 30.


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
    print "P1: Setting up throttle".
    local tVal to  1.
    lock throttle to tVal.
    print "P2: Engine ignition".
    until stage:number = 3 {
        stage.
        wait 3.
    }
    print "P3: Liftoff".
    local sVal to heading(tgtHdg, ascAngle, 0).
    lock Steering to sVal.
    print "P4: Waiting for MECO".
    local continueFlag to false.
    local steerFlag to true.

    until continueFlag
    {
        if Ship:Apoapsis >= tgtAlt
        {
            set tVal to 0.
            set continueFlag to true.
        }
        else if ship:availableThrust <= 0.001
        {
            set tVal to 0.
            if Stage:Number > 3
            {
                set tVal to 1.
                until Stage:Number = 2
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
        else if MissionTime > spinAt and steerFlag
        {
            print "P6.5: Unlocking steering".
            unlock Steering.
            set steerFlag to false.
        }
    }
    print "P7: Waiting until Apoapsis".
    wait until ETA:Apoapsis <= 5.
    print "P8: Staging".
    until Stage:Number = 1
    {
        stage.
        wait 1.
    }
    print "P9: Arming chutes".
    for m in Ship:ModulesNamed("RealChuteModule") {
    m:DoEvent("Arm parachute").
    }
    print "P10: Waiting until <10km".
    wait until ship:altitude <= jettAlt.
    print "P11: Fairing jettison".
    for p in ship:partsTaggedPattern("Reentry|Fairing") {
    p:GetModule("ProceduralFairingDecoupler"):DoEvent("jettison fairing").
    }
    print "P12: Final descent".

    wait until Alt:Radar <= 25.
    set Warp to 0.
    wait until Alt:Radar <= 1.
    wait 3.

    print "P13: Attempting recovery".
    TryRecoverVessel().
}
else
{
    print " ".
    print "* * * * * * * * * *".
    print "* Aborting launch *".
    print "* * * * * * * * * *".
    print " ".
}