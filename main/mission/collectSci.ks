@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/sci").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

local multiScan to true.
local orientation to "pro-sun".
local sciAction to "ideal".
local scanCov to false.
local sciList to GetSciModules().

if params:length > 0
{
    set sciAction to params[0].
    if params:length > 1 set multiScan to params[1].
    if params:length > 2 set orientation to params[2].
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

ag10 off.
panels on.
DispMain(scriptPath():name).

if not multiScan
{
    OutMsg("Operating in single-scan mode").
    OutInfo("Collecting science report").
    DeploySciList(sciList).
    RecoverSciList(sciList, sciAction).
    OutInfo("Science collected").
    wait 1.
    OutInfo().
}
else
{
    if addons:scansat:available
    {
        set scanCov to choose true if addons:scansat:getCoverage(ship:body, "Biome") >= 75 else false.
    }

    if scanCov 
    {
        scanned_biome_sci_report().
    }
    else
    {
        manual_sci_report().
    }

    ag10 off.
    OutMsg("Science mission complete!").
    wait 2.5.

    //-- Functions --//
    // Manually runs a crew report every 15 seconds
    local function manual_sci_report 
    {
        ag10 off.
        until ag10
        {
            set sVal to GetSteeringDir(orientation).
            local sciInterval to time:seconds + 15.
            until time:seconds >= sciInterval 
            {   
                set sVal to ship:prograde + r(0, 0, rVal).
                OutMsg("Next science report in " + round(sciInterval - time:seconds) + "s").
                DispOrbit().
                wait 0.1.
            }
            if warp > 0 set warp to 0.
            OutMsg("Collecting science report").
            DeploySciList(sciList).
            RecoverSciList(sciList, sciAction).
            if terminal:input:hasChar
            {
                if terminal:input:getChar() = terminal:input:return 
                {
                    break.
                }
            }
        }
    }

    local function scanned_biome_sci_report 
    {
        local biomeList to list().
        local curBiome  to "".

        OutHUD("Press End to terminate Science mission").

        until CheckInputChar(terminal:input:endCursor)
        {
            set curBiome to addons:scansat:getBiome(ship:body, ship:geoposition).
            set sVal to GetSteeringDir(orientation).
            OutMsg("Scanning for unresearched biomes").
            if not biomeList:contains(curBiome)
            {
                OutInfo("Collecting science: " + curBiome).
                DeploySciList(sciList).
                RecoverSciList(sciList, sciAction).
                biomeList:add(curBiome).
            }
            else
            {
                OutInfo("Current biome " + curBiome + "    ").

                local line to 17.
                print "Biomes researched: " at (0, line).
                for b in biomeList
                {
                    set line to line + 1.
                    print b + "          " at (2, line).
                }
            }
            wait 1.
        }
    }
}

OutMsg("Science scans completed!").
wait 2.5.