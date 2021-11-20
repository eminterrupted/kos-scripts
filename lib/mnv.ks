@lazyGlobal off.

// Dependencies
// #include "0:/lib/burnCalc"

// *~ Variables ~* //


// *~ Functions ~* //
// #region

// ExecNodeBurn :: <node> -> <none>
// Given a node object, executes it
global function ExecNodeBurn
{
    parameter mnvNode is node().

    local dv to mnvNode:deltaV:mag.
    local burnDur to CalcBurnDur(dv).
    local fullDur to burnDur[0].
    local halfDur to burnDur[1].
    local fullStagesDict to burnDur[2]["Full"].
    local halfStagesDict to burnDur[2]["Half"].

    local totalStages to fullStagesDict:keys:length.
    local halfStages to halfStagesDict:keys:length.
    local additionalFullDur to 0.
    local additionalHalfDur to 0.
    local averageStageTime to 0.51.

    if totalStages > 1 
    {
        set additionalFullDur to totalStages * averageStageTime.
    }
    if halfStages > 1
    {
        set additionalHalfDur to halfStages * averageStageTime.
    }

    set fullDur to fullDur + additionalFullDur.
    set halfDur to halfDur + additionalHalfDur.

    
}
// #endregion