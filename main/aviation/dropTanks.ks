@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_disp").

disp_main(scriptPath()).

local avgClock      to list(0, 0).
local dClock        to 0.
local dropTanks     to list().
local flowRate      to 0.
local pClock        to time:seconds.
local prevFuel      to 0.
global stgDecoupler  to lex().
global stgTanks      to lex().

if stgTanks:keys:length > 0
{
    disp_msg("Drop tank triggers initialized").
}

local tClock to 0.
wait 0.01.
until false
{
    if mod(tClock, 10) = 0 
    {
        set dClock  to time:seconds - pClock.
        set avgClock to util_avg_values(list(dClock, 10)).
        set pClock  to time:seconds.
        print avgClock at (2, 35).
    }
    set tClock to tClock + 1.
    
    set dropTanks to get_drop_tanks().
    set stgDecoupler to dropTanks[0].
    set stgTanks to dropTanks[1].

    local key to stgTanks:keys:length - 1.
    if key < 0
    {
        disp_info().
        disp_info2().
        break.
    }

    local res to stgTanks[key]:resources[0].
    if res:amount <= 0.1
    {
        for dc in stgDecoupler[key]
        {
            local dcModule to choose "ModuleAnchoredDecoupler" if dc:hasModule("ModuleAnchoredDecoupler") else "ModuleDecouple".
            if dc:children:length > 0 
            {
                util_do_event(dc:getModule(dcModule), "decouple").
                disp_info("External Tank Loop ID[" + key + "] dropped").
            }
        }
    }
    else
    {
        print "FuelTank: " + stgTanks[key]:tag at (2, 29).
        print "resAmount: " + res:amount at (2, 30).
        print "resCapacity: " + res:capacity at (2, 31).
    }
    disp_avionics().
}

disp_msg("All drop tanks jettisoned").
wait 2.

disp_msg("Avionics mode").
until false
{
    disp_avionics().
}

// Functions

global function get_drop_tanks
{
    local dcList    to lex().
    local tList     to lex().
    
    for t in ship:partsTaggedPattern("dropTank") 
    {
        local loopId to t:tag:split(".")[1]:toNumber.
        
        if t:typeName = "decoupler" 
        {
            if not dcList:hasKey(loopId)
            {
                set dcList[loopId] to list(t).
            }
            else
            {
                dcList[loopId]:add(t).
            }

            set tList[loopId] to t:children[0].
        }
    }
    return list(dcList, tList).
}

local function util_avg_values
{
    parameter avgList.

    local avg to 0.
    if not (defined avgVals) global avgVals to list().
    
    if avgList:length >= avgList[1] {
        avgList:remove(9).
    }

    avgList:add(avgList[0]).
    for i in avgList
    {
        set avg to avg + i.
    }

    if avg <> 0 {
        return avg / avgList:length.
    }
    else
    {
        return 0.
    }
}