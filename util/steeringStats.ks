@lazyGlobal off.
clearScreen.

parameter resetAll is false,
          resetPids is false,
          showAngVecs is false,
          showFaceVecs is false.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").

if resetAll steeringManager:resettodefault.
if resetPids steeringManager:resetPids.
if showAngVecs 
{
    set steeringManager:showangularvectors to true.
}
else
{
    set steeringManager:showangularvectors to false.
}
if showFaceVecs
{
    set steeringManager:showfacingvectors to true.
}
else
{
    set steeringManager:showfacingvectors to false.
}


local dirIdx to 0.
local dirList to list(ship:prograde, ship:retrograde, VesNormal(), VesBinormal(), VesTangent(), VesLocalVertical()).
local dirName to list("prograde", "retrograde", "vesNormal", "vesBinormal", "vesTangent", "vesLocalVertical").
local settleTS to time:seconds.
local ts to time:seconds.

print "Steering Manager Stats v0.01b" at (0, 0).
print "-----------------------------" at (0, 1).


print "Settings" at (0, 6).
print "--------" at (0, 7).

print "Stats" at (0, 29).
print "-----" at (0, 30).

local sVal to dirList[dirIdx].
lock steering to sVal.

until dirIdx = dirList:length
{
    set sVal to dirList[dirIdx].
    
    // State
    print "Direction            : " + dirName[dirIdx] + "   " at (0, 4).
    
    // Settings
    print "[General]" at (0, 8).
    print "MaxStoppingTime      : " + round(steeringManager:maxStoppingTime, 2) at (0, 9).
    print "Torque Epsilon Max   : " + round(steeringManager:torqueEpsilonMax, 5) at (0, 10).
    print "Torque Epsilon Min   : " + round(steeringManager:torqueEpsilonMin, 5) at (0, 11).

    print "[Pitch]" at (0, 13).
    print "Torque Adjust        : " + round(steeringManager:pitchtorqueadjust, 5) at (0, 14).
    print "Torque Factor        : " + round(steeringManager:pitchtorquefactor, 5) at (0, 15).
    print "Settle Time (TS)     : " + round(steeringManager:pitchts, 2) at (0, 16).

    print "[Yaw]" at (0, 18).
    print "Torque Adjust        : " + round(steeringManager:yawtorqueadjust, 5) at (0, 19).
    print "Torque Factor        : " + round(steeringManager:yawtorquefactor, 5) at (0, 20).
    print "Settle Time (TS)     : " + round(steeringManager:yawts, 2) at (0, 21).

    print "[Roll]" at (0, 23).
    print "Torque Adjust        : " + round(steeringManager:rolltorqueadjust, 5) at (0, 24).
    print "Torque Factor        : " + round(steeringManager:rolltorquefactor, 5) at (0, 25).
    print "Settle Time (TS)     : " + round(steeringManager:rollts, 2) at (0, 26).
    print "Ctrl Angle Range     : " + round(steeringManager:rollcontrolanglerange, 5) at (0, 27).
    
    // Stats
    print "Angle Error          : " + round(steeringManager:angleerror, 5) at (0, 31).
    print "Average Duration     : " + round(steeringManager:averageduration, 2) at (0, 32).
    
    print "Pitch Error          : " + round(steeringManager:pitcherror, 5) at (0, 34).
    print "Roll Error           : " + round(steeringManager:rollerror, 5) at (0, 35).
    print "Yaw Error            : " + round(steeringManager:yawerror, 5) at (0, 36).

    print "CheckSteering output : " + CheckSteering() at (0, 38).
    
    if CheckSteering()
    {
        if time:seconds >= settleTS
        {
            print "State                : Vessel settled!    " at (0, 2).
            print "Elapsed settling time: " + round(time:seconds - ts, 2) + "  " at (0, 3).
            wait 2.5.
            set dirIdx to dirIdx + 1.
            set ts to time:seconds.
        }
        else 
        {
            print "State                : Settling        " at (0, 2).
            print "Settle time          : " + round(settleTS - time:seconds, 2) + "  " at (0, 3).
        }
    }
    else
    {
        print "State                : " + "Steering        " at (0, 2).
        print "Elapsed settling time: " + round(time:seconds - ts, 1) + "  " at (0, 3).
        set settleTS to time:seconds + 5.
    }
}
