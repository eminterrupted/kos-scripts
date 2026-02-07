@LazyGlobal off.
ClearScreen.

parameter params to list().

RunOncePath("0:/lib/libLoader.ks").
RunOncePath("0:/lib/aero.ks").

set g_MainProc to ScriptPath().
DispMain().

local dtTaggedParts to Ship:PartsTaggedPattern("droptank\|\d*").
local dropThreshPct to 0.01.

if params:length > 0
{
    set dropThreshPct to params[0].
    if params:length > 1 set dtTaggedParts to params[1].
}

if dtTaggedParts:Length = 0
{
    OutMsg("No drop tanks detected, goodbye.mp3").
}
else
{
    OutMsg("Triggering DropTanks at Res Pct Rem: {0}%":Format(Round(dropThreshPct, 4) * 2)).
    wait 1.
    OutMsg("Waiting for AG7 to begin automatic drop function").

    local iterCount to 0.
    local tgtCount to 300.
    
    until AG7 or iterCount >= tgtCount
    {
        local curCount to g_ActiveEngines:Length.
        wait 0.02.
        set g_ActiveEngines to GetActiveEngines().
        if curCount > 0
        {
            set iterCount to iterCount + 1.
        }
        else
        {
            set iterCount to 0.
        }
        OutInfo("IterCount: {0}[/{1}]":Format(iterCount, tgtCount)).
    }
    local msgStr to choose "AG7 Activated" if AG7 else "iterCount Release".
    OutMsg(msgStr).
    OutInfo().

    local engResList to UniqueSet().
    for eng in g_ActiveEngines
    {
        for cres in eng:ConsumedResources:Values
        {
            if not engResList:Contains(cres:Name)
            {
                engResList:Add(cres:Name).
            }
        }
    }

    local dtSet to lexicon(
        "ID", lexicon(
            0, lexicon(
                "UIDSET", list()
                ,"DCPARTS", list()
                ,"DCMODULES", list()
                ,"TESTPARTS", list()
                ,"TESTRES", list()
            )
        )
    ).

    for dtPart in Ship:PartsTaggedPattern("droptank\|\d*")
    {
        local dtTagSpl to dtPart:Tag:Split("|").
        local dtTagIdx to Abs(dtTagSpl[dtTagSpl:Length - 1]:ToNumber(0)).

        if not dtSet:ID:HasKey(dtTagIdx)
        {
            dtSet:ID:Add(dtTagIdx, lexicon(
                "UIDSET", list()
                ,"DCPARTS", list()
                ,"DCMODULES", list()
                ,"TESTPARTS", list()
                ,"TESTRES", list()
            )).
        }

        if dtPart:IsType("Decoupler")
        {
            from { local i to 0. local doneFlag to false.} until i = g_PartInfo:ModRef:Decoupler:Length or doneFlag step { set i to i + 1.} do
            {
                for moduleName in g_PartInfo:ModRef:Decoupler
                {
                    if dtPart:HasModule(moduleName)
                    {
                        local m to dtPart:GetModule(moduleName).
                        dtSet:ID[dtTagIdx]:DCMODULES:Add(m).
                        dtSet:ID[dtTagIdx]:DCPARTS:Add(dtPart).
                        dtSet:ID[dtTagIdx]:UIDSET:Add(dtPart:UID).
                        set doneFlag to true.
                    }
                }
            }
        }

        // Find the reference part if we don't already have one for this stage
        local testResourceFound to false.
        
        if dtPart:Resources:Length > 0
        {
            for dtRes in dtPart:Resources
            {
                if engResList:Contains(dtRes:Name)
                {
                    dtSet:ID[dtTagIdx]:TESTRES:Add(dtRes).
                    dtSet:ID[dtTagIdx]:TESTPARTS:Add(dtPart).
                    set testResourceFound to true.
                }
            }
        }

        if testResourceFound
        {
            // TODO: What happens when resources have been located in the directly-tagged part vs needing to look for resources in the downstream part tree
        }
        else
        {
            local dtChildren to dtPart:Children.

            from { local i to 0. local doneFlag to false.} until i = dtChildren:Length or doneFlag step { set i to i + 1.} do
            {
                local child to dtChildren[i].
                if child:Resources:Length > 0
                {
                    for chRes in child:Resources
                    {
                        if engResList:Contains(chRes:Name)
                        {
                            dtSet:ID[dtTagIdx]:TESTRES:Add(chRes).
                            dtSet:ID[dtTagIdx]:TESTPARTS:Add(child).
                            set doneFlag to true.
                        }
                    }
                }
            }
        }
    }

    local conditionDelegate to 
    {
        parameter _setId to 0.

        local loopFlag to false.
        local aggAmt to 0.
        local aggCap to 0.
        local aggThresh to 0.

        for testRes in dtSet:ID[_setId]:TESTRES
        {
            local threshVal to testRes:Capacity * dropThreshPct.
            
            set aggThresh to aggThresh + threshVal.
            set aggAmt to aggAmt + testRes:Amount.
            set aggCap to aggCap + testRes:Capacity.

            if testRes:Amount > threshVal or loopFlag
            {
                set loopFlag to true.
            }
        }

        OutInfo("Drop Tank Agg [AmtPct | Thresh]: [{0} | {1}] ":Format(Round(aggAmt / aggCap, 4) * 100,  Round(aggThresh, 4) * 100)).
        return not loopFlag.
    }.

    local actionDelegate to 
    { // parameter _stg to Stage:Number. local LastStage to _stg. wait until Stage:Ready. Stage. wait 0.01. return Stage:Number <> LastStage. }.
        parameter _setId to 0.

        local dtResult to 0.
        
        local pSet to Ship:PartsTaggedPattern("droptank\|\d*"). 

        if pSet:Length > 0
        {

            OutMsg().
            OutInfo().
            OutMsg("Dropping tanks for set: {0}":Format(_setId)).
            for p0 in pSet 
            {
                if p0:IsType("Decoupler") 
                {
                    // look for sep engines to fire
                    for m1 in p0:ModulesNamed("ModuleEnginesFX")
                    {
                        if m1:Part:IsType("Engine") 
                        {
                            local eng to m1:Part.
                            if not eng:Ignition or eng:Flameout
                            {
                                if eng:Ignitions > 0
                                {
                                    eng:Activate.
                                }
                            }
                        }
                    }

                    // Fire the decoupler event
                    for dcTypeName in g_ModEvents:Decoupler:Keys
                    {
                        if p0:HasModule(dcTypeName)
                        {
                            set dtResult to dtResult + DoEvent(p0:GetModule(dcTypeName), g_modEvents:Decoupler[dcTypeName]:Decouple).
                        }
                    }
                }
            }
        }

        return dtResult.

        // local mSet to list().// dtSet:ID[_setId]:DCMODULES.
        // if mSet:Length > 0
        // {

        //     for m in mSet
        //     {
        //         for p in m:Part:PartsNamedPattern("sep|spin")
        //         {
        //             if p:IsType("Engine") p:Activate.
        //         }
        //         DoEvent(m, g_ModEvents:Decoupler[m:Name]:Decouple).
        //     }
        // }
    }.

    local actDel to actionDelegate@.
    local chkDel to conditionDelegate@.

    from { local i to 0.} until i = dtSet:ID:Keys:Length step { set i to i + 1.} do
    {
        local doneFlag to false.
        until doneFlag
        {
            set doneFlag to chkDel:Call(i).
        }
        actDel:Call(i).
    }

    OutMsg("All tanks dropped, bye now").
}