@lazyGlobal off.
clearScreen.

local altFlyingHigh to 18000.
local altSpaceLow to body:atm:height.
local altSpaceHigh to 625000.
local lastStage to 2.
local runmode to 0.
local ts to 0.

print "MISSION: " + ship:name at (0, 0).
print "------------------------------" at (0, 1).

for m in ship:modulesNamed("ModuleGenerator")
{
    if m:hasEvent("activate generator") 
    {
        m:doEvent("activate generator").
        outLine("External power activated").
        break.
    }
}

// logSci("launchpad").
wait 1.

outLine("Standing by...").
outLine("Runmode: " + runmode, 4).
outLine("Situ   : " + status:toupper, 5).
until missionTime > 0 
{
    wait 0.1.
}
if ship:availablethrust > 0 
{
    outLine("Liftoff at " + time:full).
    set runmode to 1.
}
else 
{
    set runmode to -1.
}

wait 1.

if runmode = 1
{
    until runmode = -1
    {
        outLine("MET    : " + round(missionTime, 1)).
        outLine("Runmode: " + runmode, 4).
        outLine("Situ   : " + status, 5).

        if alt:radar > 100 and ship:availableThrust < 0.1 and eta:apoapsis <= 30 and runmode < 90 
        {
            set runmode to 90.
        }
        else if runmode = 1
        {
            if alt:radar >= 10
            {
                // clrHost().
                
                // logSci("low altitude").
                set runmode to 10.
            }
        }
        else if runmode = 10
        {
            if ship:altitude >= altFlyingHigh
            {
                clrHost().
                logSci("high altitude").
                set runmode to 15.
            }
        }
        else if runmode = 15
        {
            if ship:altitude >= altSpaceLow
            {
                clrHost().
                logSci("space low").
                set runmode to 20.
            }
        }
        else if runmode = 20
        {
            if ship:altitude >= altSpaceHigh
            {
                clrHost().
                logSci("space high").
                set runmode to 90.
            }
        }
        else if runmode = 90
        {
            until stage:number = 1 stage.   
            set ts to time:seconds + eta:apoapsis.
            set runmode to 92.
        }
        else if runmode = 92
        {
            if time:seconds > ts
            {
                set runmode to 95.       
            }
        }
        else if runmode = 95
        {
            local parachutes to ship:modulesNamed("RealChuteModule").
            if parachutes:length > 0 
            {
                for m in parachutes
                {
                    if m:hasEvent("arm parachute") m:doEvent("arm parachute").
                }
            }
        
            set runmode to 99.
        }
        else if runmode = 99
        {
            if alt:radar <= 1 
            {
                outLine("Mission complete").
                set runmode to -1.
            }
        }

        if ship:availableThrust <= 0.1 and stage:number > lastStage
        {
            print "Staging".
            until stage:ready
            {
                wait 0.01.
            }
            stage.
        }

        wait 0.05.
    }
}
else
{
    outLine("CAUTION: Launch failed! No thrust").
}

// Functions
local function logSci
{
    parameter situ, 
              sciMods to ship:ModulesNamed("ModuleScienceExperiment").

    local sciVal to 0.
    local sciXmt to 0.
    local transmitSci to false.

    local line to 7.

    local function cr
    {
        set line to line + 1.
        return line.
    }

    outLine("------------------------------", line).
    outLine((situ + " science subroutine"):toupper, cr()).
    for m in sciMods
    {
        local keepData to false.
        if m:hasData
        {
            if m:data[0]:scienceValue > 0 
            {
                set keepData to true.
            }
            else 
            {
                m:reset().
            }
        }
        
        if not keepData
        {    
            m:deploy.
            wait until m:hasData.
            
            local sci to m:data[0].
            local dataVal to round(sci:scienceValue, 1).
            local dataXmt to round(sci:transmitValue, 1).
                
            outLine("* Running " + sci:title, cr()).
            
            if dataVal > 0
            {
                set sciVal to sciVal + dataVal.
                if dataXmt > 0 and ship:electricCharge > 30 and transmitSci
                {
                    set sciXmt to sciXmt + dataXmt.
                    outLine("  " + dataXmt + " science transmitted", cr()).
                    m:transmit.
                }
                else
                {
                    outLine("  " + dataVal + " science stowed", cr()).
                }
            }
            else
            {
                m:reset().
            }
        }
    }
    cr().
    outLine(round(sciVal, 1) + " total science recorded", cr()).
    outLine(round(sciXmt, 1) + " total science received", cr()).
    outLine("------------------------------", cr()).
}

local function outLine
{
    parameter str,
              line is 3.

    print str + "                              " at (0, line).
}

local function clrHost
{
    local line to 7.
    until line >= terminal:height 
    {
        outLine("                              ", line).
        set line to line + 1.
    }
}