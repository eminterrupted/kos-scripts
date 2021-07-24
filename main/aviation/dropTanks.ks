@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_disp").

disp_main(scriptPath()).

local avgClock      to list(0, 0).
local dClock        to 0.
local dropTanks     to list().
local pClock        to time:seconds.
global stgDecoupler  to lex().
global stgTanks      to lex().

if stgTanks:keys:length > 0
{
    disp_msg("Drop tank triggers initialized").
}

wait 0.01.
until false
{
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