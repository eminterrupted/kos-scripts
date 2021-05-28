@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_disp").

disp_main(scriptPath(), false).

local avgClock      to list(0, 0).
local boosters     to list().
local dClock        to 0.
local flowRate      to 0.
local pClock        to time:seconds.
local prevFuel      to 0.
global stgDecoupler  to lex().
global stgTanks      to lex().

if stgTanks:keys:length > 0
{
    disp_msg("Booster triggers initialized").
}

local tClock to 0.
wait 0.01.
until false
{
    disp_msg("currentStage: " + stage:number).
    if mod(tClock, 10) = 0 
    {
        set dClock  to time:seconds - pClock.
        set avgClock to util_avg_values(list(dClock, 10)).
        set pClock  to time:seconds.
        print "avgClock Delta Per Update: " + avgClock at (2, 15).
    }
    set tClock to tClock + 1.
    
    set boosters to get_boosters().
    set stgDecoupler to boosters[0].
    set stgTanks to boosters[1].

    local key to stgTanks:keys:length - 1.
    if key < 0
    {
        disp_info().
        disp_info2().
        break.
    }

    local res to stgTanks[key]:resources[0].
    if res:amount <= 0.001
    {
        for dc in stgDecoupler[key]
        {
            if dc:children:length > 0 
            {
                util_do_event(dc:getModule("ModuleAnchoredDecoupler"), "decouple").
                disp_info("External Booster Loop ID[" + key + "] dropped").
            }
        }
        stgDecoupler:remove(key).
        stgTanks:remove(key).
    }
    else
    {
        print "Booster              : " + stgTanks[key]:parent:tag at (2, 10).
        print "Booster Fuel Amount  : " + res:amount at (2, 11).
        print "Booster Fuel Capacity: " + res:capacity at (2, 12).
        if res:amount < res:capacity
        {
            local resFuel to res:amount.
            set flowRate  to (resFuel - prevFuel) / dClock.
            set prevFuel  to resFuel.
            
            disp_info("Current booster fuel flow rate    : " + round(flowRate, 2) + "u/s     ").
            disp_info2("Time to next booster separation event: " + round(resFuel / flowRate, 1) + "s     ").
        }
    }
}

disp_msg("Current stage: " + stage:number).
wait 2.

// Functions

global function get_boosters
{
    local dcList    to lex().
    local tList     to lex().
    
    for t in ship:partsTaggedPattern("booster") 
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