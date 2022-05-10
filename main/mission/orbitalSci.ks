@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/sci").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").

//multiscan: 
/// true: continuosly loop experiment for each biome
/// false: run once
local multiScan to true.
local tgtBiome to "Any".
local orientation to "pro-sun".

//sciAction:
/// "transmit" - immediately transmit experiment results
/// "ideal" - transmit only if there is untransmitted science and transmitting will result in maximum possible reward benefit
/// "collect" - works in cases where a science container is present. collect all science data into available container
local sciAction to "ideal".
local scanCov to false.
local sciList to GetSciModules().

if params:length > 0
{
    set multiScan to params[0].
    if params:length > 1 set sciAction to params[1].
    if params:length > 2 set tgtBiome to params[2].
    if params:length > 3 set orientation to params[3].
}

local sVal to GetSteeringDir(orientation).
lock steering to sVal.

ag10 off.
panels on.
DispMain(scriptPath():name).

DeployPartSet("sciDeploy", "deploy").

if multiScan
{
    PerformMultiscan().
}
else
{
    OutMsg("Operating in single-scan mode").
    OutInfo("Collecting science report").
    DeploySciList(sciList).
    RecoverSciList(sciList, sciAction).
    OutInfo("Science collected").
    wait 1.
    OutInfo().
}

OutMsg("Science scans completed!").
wait 2.5.

local function PerformMultiscan
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
        until false
        {
            set sVal to GetSteeringDir(orientation).
            if warp > 3 set warp to 3.
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
            local sciInterval to time:seconds + 60.
            until time:seconds >= sciInterval 
            {   
                set sVal to GetSteeringDir(orientation).
                OutMsg("Next science report in " + round(sciInterval - time:seconds) + "s").
                DispOrbit().
                wait 0.1.
            }
        }
    }

    local function scanned_biome_sci_report 
    {
        local biomeList to list().
        local curBiome  to "".
        local line to 17.
        local biomePath to path("sciBiomes.json").

        print "Biomes researched: " at (0, line).
        OutHUD("Press End to terminate Science mission").
        if exists(biomePath) {
            set biomeList to readJson(biomePath).
        }
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
                writeJson(biomeList, biomePath).
            }
            else
            {
                OutInfo("Current biome " + curBiome + "    ").
                set line to 18.
                for b in biomeList
                {
                    print "- " + b + "          " at (0, line).
                    set line to line + 1.
                }
            }
            if curBiome = tgtBiome 
            {
                OutMsg("Target biome (" + curBiome + ") scanned, ending science mission"). 
                break.
            }
            wait 1.
        }
        deletePath(biomePath).
    }

    DeployPartSet("scienceDeploy", "retract").
}