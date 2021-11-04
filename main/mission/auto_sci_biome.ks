@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/bak/lib_sci").
runOncePath("0:/lib/bak/lib_vessel").
runOncePath("0:/lib/util").

local scanCov to false.
local sciList to sci_modules().

local rVal to 0.
local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.


ag10 off.
ves_activate_solar().
disp_main(scriptPath():name).

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
disp_msg("Science mission complete!").
wait 2.5.



//-- Functions --//
// Manually runs a crew report every 15 seconds
local function manual_sci_report 
{
    ag10 off.
    until ag10
    {
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        local sciInterval to time:seconds + 15.
        until time:seconds >= sciInterval 
        {   
            set sVal to ship:prograde + r(0, 0, rVal).
            disp_msg("Next science report in " + round(sciInterval - time:seconds) + "s").
            disp_orbit().
            wait 0.1.
        }
        if warp > 0 set warp to 0.
        disp_msg("Collecting science report").
        sci_deploy_list(sciList).
        sci_recover_list(sciList, "ideal").
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

    until ag10
    {
        set curBiome to addons:scansat:getBiome(ship:body, ship:geoposition).
        set sVal to lookDirUp(ship:prograde:vector, sun:position) + r(0, 0, rVal).
        disp_msg("Scanning for unresearched biomes").
        if not biomeList:contains(curBiome)
        {
            disp_info("Collecting science: " + curBiome).
            sci_deploy_list(sciList).
            sci_recover_list(sciList, "ideal").
            biomeList:add(curBiome).
        }
        else
        {
            disp_info("Current biome " + curBiome + "    ").

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