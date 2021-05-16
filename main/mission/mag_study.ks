@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

local sciList to sci_modules().
local rVal to 0.
local sVal to ship:prograde + r(0, 0, rVal).
lock steering to sVal.

ag10 off.
disp_main(scriptPath():name).
ves_activate_solar().

disp_msg("Running mag study").

//Triggers
when ship:altitude >= info:altForSci[ship:body:name] then 
{
    sci_deploy_list(sciList).
    sci_recover_list(sciList, "transmit").
    disp_info("Science recovered from high " + ship:body:name + " orbit").
}

when ship:altitude < info:altForSci[ship:body:name] then
{
    sci_deploy_list(sciList).
    sci_recover_list(sciList, "transmit").
    disp_info("Science recovered from low " + ship:body:name + " orbit").
}

when ag10 then
{
    manual_sci_report().
    disp_info("Science recovered from " + ship:body:name + " orbit").
    ag10 off.
    preserve.
}

until false 
{
    disp_orbit().
    wait 0.01.
}

//-- Functions --//
// Manually runs a crew report every 15 seconds
local function manual_sci_report 
{
    sci_deploy_list(sciList).
    sci_recover_list(sciList, "transmit").
}