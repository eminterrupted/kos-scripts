@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local rcsList            to Ship:ModulesNamed("ModuleRCSFX").
local disableAtStage     to Stage:Number - 1.

// Parse Params
if _params:length > 0 
{
    set rcsList to _params[0].
    if _params:Length > 1 set disableAtStage to _params[1].
}

if rcsList:Length = 0
{
    OutMsg("ERROR: No RCS modules on vessel!").
    wait 1.
}
else
{
    OutMsg("Disabling RCS modules below stage " + disableAtStage).
    OutStr("----------------------------------------").
    cr().
    for m in rcsList
    {
        OutStr("Part UID    : " + m:Part:UID).
        OutStr("Module Part : " + m:Part:Name).
        OutStr("Stage Active: " + m:Part:Stage).
        if m:Part:Stage <= disableAtStage
        {
            OutStr("RCS Status  : {0}  ":Format(m:GetField("RCS"))).
            wait 0.25.
            SetField(m, "RCS", False).
            OutStr("RCS Status  : {0}  ":Format(m:GetField("RCS")), g_line).
        }
        cr().        
    }
    OutStr("----------------------------------------").
    OutMsg("RCS modules above stage " + disableAtStage + " have been successfully disabled.").
}