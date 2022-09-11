@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/disp").
runOncePath("0:/lib/sci").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/util").
runOncePath("0:/lib/scansat").

//sciAction:
/// "transmit" - immediately transmit experiment results
/// "ideal" - transmit only if there is untransmitted science and transmitting will result in maximum possible reward benefit
/// "collect" - works in cases where a science container is present. collect all science data into available container
local sciAction to "ideal".

//sciMode:
/// biome: Run experiments in specific biomes
/// full: continuosly loop experiment for each biome
/// single: run once
local sciMode to "single".

//scanParams:
/// A semi-colon delimited list of biomes to research. Used with the "biome" sciMode.
local scanParams to list(). // Formatted as list. If the first token is "biomes", the second token should be a semi-colon delimited list of biomes

local orientation to "pro-sun".
local scanCov to false.
local sciList to GetSciModules().

if params:length > 0
{
    set sciMode to params[0].
    if params:length > 1 set sciAction to params[1].
    if params:length > 2 set orientation to params[2].
    if params:length > 3 set scanParams to params[3].
}

set sVal to GetSteeringDir(orientation).
lock steering to sVal.

ag10 off.
panels on.
DispMain(scriptPath():name).

DeployPartSet("sciDeploy", "deploy").

if sciMode = "single"
{
    OutMsg("Operating in single-scan mode").
    OutInfo("Collecting science report").
    DeploySciList(sciList).
    RecoverSciList(sciList, sciAction).
    OutInfo("Science collected").
    wait 1.
    OutInfo().
}
else if sciMode = "biome"
{
    OutMsg("Operating in selected biome-scan mode").
    OutInfo("Eligible biomes: {0}":format(scanParams)).
    PerformBiomeScan(scanParams).
    OutInfo("Science from all biomes collected").
    wait 1.
    OutInfo().
}
else if sciMode = "full"
{
    OutMsg("Operating in continuous biome-scan mode").
    OutInfo("Eligible biomes: All").
    PerformMultiscan().
    OutInfo("Science collection terminated").
    wait 1.
    OutInfo().
}

Breakpoint().


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
            set curBiome to GetBiome().
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
            wait 1.
        }
        deletePath(biomePath).
    }

    DeployPartSet("scienceDeploy", "retract").
}



local function PerformBiomeScan
{
    parameter _biomes to "".


    local biomeReportPath to path("biomeReport.json").
    local biomeReportFlat to list("", "").
    local remainingBiomes to _biomes:split(";").
    local researchedBiomes to list().
    local biomeReportExp to list(remainingBiomes, researchedBiomes).
    
    if exists(biomeReportPath) 
    {
        set biomeReportFlat to readJson(biomeReportPath).
        set remainingBiomes to biomeReportFlat[0]:split(";").
        if biomeReportFlat:length > 1 set researchedBiomes to biomeReportFlat[1]:split(";").
        set biomeReportExp to list(remainingBiomes, researchedBiomes).
    }

    if remainingBiomes[0] = ""
    {
        OutTee("[WARN] No biomes provided for PerformBiomeScan()!", 0, 1).
        DispSci(sciMode, sciAction, "Deploying Experiments").
        DeploySciList(sciList).
        RecoverSciList(sciList, sciAction).
    }
    else
    {
        if addons:scansat:available
        {
            set scanCov to choose true if addons:scansat:getCoverage(ship:body, "Biome") >= 75 else false.
        }

        if scanCov 
        {
            local curBiome  to "".
            local doneFlag to false.
            set g_line to 10.

            DispSci(sciMode, sciAction, "Beginning biome search", biomeReportExp).
            OutHUD("Press End to terminate Science mission").
            
            until CheckInputChar(terminal:input:endCursor) or doneFlag
            {
                set curBiome to GetBiome().
                set sVal to GetSteeringDir(orientation).
                OutMsg("Scanning for required biomes").
                OutInfo("Current biome: {0}":format(curBiome)).
                
                if remainingBiomes:contains(curBiome)
                {
                    OutInfo("Biome reached: {0}":format(curBiome)).
                    DispSci(sciMode, sciAction, "Deploying Experiments", biomeReportExp).
                    DeploySciList(sciList).
                    RecoverSciList(sciList, sciAction).
                    OutInfo2().
                    researchedBiomes:add(curBiome).
                    remainingBiomes:remove(remainingBiomes:indexOf(curBiome)).
                    if remainingBiomes:length = 0 
                    {
                        set doneFlag to true.
                        deletePath(biomeReportPath).
                    }
                    else
                    {
                        set biomeReportFlat to list(remainingBiomes:join(";"), researchedBiomes:join(";")).
                        set biomeReportExp to list(remainingBiomes, researchedBiomes).
                        writeJson(biomeReportFlat, biomeReportPath).
                    }
                }
                else
                {
                    DispSci(sciMode, sciAction, "Performing biome search", biomeReportExp).
                }
                wait 0.01.
            }
        }
        else
        {
            OutTee("[WARN] Biome data incomplete! Performing one-time manual sci report", 0, 1).
            DispSci(sciMode, sciAction, "Deploying experiments", biomeReportExp).
            DeploySciList(sciList).
            RecoverSciList(sciList, sciAction).
        }
    }
}