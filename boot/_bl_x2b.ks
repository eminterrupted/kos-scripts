@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/loadDep").

local TDEngs to Ship:PartsTaggedPattern("thrustDiff.*").
local TDEng to "".
local TDMod to "".
local TLimit to 0. 
local TLimits to list(54, 100).
local TLimitRange to TLimits[1] - TLimits[0].

local ShipResources to GetResourcesFromEngines(TDEngs).
lock FuelRemaining to ShipResources:PctRemaining.

if TDEngs.Length > 0 
{ 
    OutMsg("Adjusting Thrust Differential...").

    set TDEng to TDEngs[0]. 
    set TDMod to TDEng:GetModule("ModuleEnginesRF").

    lock throttle to t_Val.
    set t_Val to 1.

    set TLimit to TLimits[0] + (FuelRemaining * TLimitRange).
    until FuelRemaining < 0.01
    {
        set ShipResources to GetResourcesFromEngines(TDEngs).
        set TLimit to TLimits[0] + (FuelRemaining * TLimitRange).
        //TDMod:SetField("Thrust Limiter", TLimit).
        OutInfo("{0, -15}:   {1, 5}   ":format("FuelRemaining", Round(FuelRemaining, 3))).
        OutInfo("{0, -15}: {1, 5}%  ":format("ThrustLimiter", Round(TLimit)), 1).
        wait 0.01.
    }
}
else
{
    OutMsg("No engines tagged 'thrustDiff.*'").
}
