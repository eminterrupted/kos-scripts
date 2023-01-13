@LazyGlobal off.
ClearScreen.

parameter params is list().

wait until Ship:Unpacked.
wait until HomeConnection:IsConnected.

RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/aero").

DispMain().
//InitDisp().

local dropTanks  to Ship:PartsTaggedPattern("DropTank.\d*").
local dtObj      to lexicon().
local f_DropTank to (dropTanks:Length > 0).
lock  testResPct to 0.
// local f_Staging  to false.

if params:length > 0 
{
    set f_DropTank to params[0].
    if params:length > 1 set f_DropTank to params[1].
}

if f_DropTank
{
    if dropTanks:Length > 0
    {
        local minSet to 99.
        local maxSet to -1.
        local setIdx to 0.

        local setList to UniqueSet().
        local setQueue to Queue().
        local sortedSets to list().

        //local dtObj to lexicon().
        local tanksLoaded to false. // True when we have the dtObj fully loaded

        //from { local i to 0.} until i = dropTanks:Length step { set i to i + 1.} do
        until tanksLoaded
        {
            OutMsg("Checking SetIdx: [{0}]":Format(setIdx)).
            local regex to "DropTank.{0}":Format(setIdx).
            local setParts to Ship:PartsTaggedPattern(regex).
            if setParts:length > 0 
            { 
                OutInfo("SetParts found").
                local setKey to setIdx:ToString.
                
                // set the min / max sets. Should be fine to set both and have the min / max functions do the right thing
                set maxSet to max(maxSet, setIdx).
                set minSet to min(minSet, setIdx).

                if not dtObj:HasKey(setKey)
                {
                    set dtObj[setKey] to Lexicon(
                        "PART", list()
                        ,"RESOURCE", Lexicon()
                        ,"DECOUPLER", Lexicon(
                            "MODULE", list(),
                            "UID", UniqueSet()
                        )
                    ).
                }
                for dt in setParts
                {
                    // :PART
                    dtObj[setKey]["PART"]:Add(dt).


                    // :RESOURCE
                    local resPart to "".
                    if dt:HasSuffix("Resources") 
                    {  
                        set resPart to dt.
                    }
                    else if dt:Children:Length > 0
                    {
                        local doneFlag to false.
                        local _p to dt:Children[0].
                        until doneFlag
                        {
                            if _p:HasSuffix("Resources") 
                            { 
                                set resPart to _p.
                                set doneFlag to true.
                            }
                            else 
                            { 
                                if _p:Children:Length > 0 
                                { 
                                    set _p to _p:Children[0].
                                }
                                else
                                {
                                    set doneFlag to true.
                                }
                            }
                        }
                    }

                    if resPart <> ""
                    {
                        for res in resPart:Resources
                        {
                            if dtObj[setKey]["RESOURCE"]:HasKey(res:Name) 
                            {
                                dtObj[setKey]["RESOURCE"][res:Name]:add(res).
                            }
                            else
                            {
                                set dtObj[setKey]["RESOURCE"][res:Name] to list(res).
                            }
                        }
                    }

                    // :DECOUPLER
                    if dt:decoupledin > -1
                    {
                        local dc to dt:Decoupler.
                        if dtObj[setKey]["DECOUPLER"]["UID"]:Contains(dc:UID)
                        {
                            // No-op
                        }
                        else
                        {
                            local dcMod to choose dc:GetModule("ModuleDecouple")    if dc:HasModule("ModuleDecouple") 
                                else choose dc:GetModule("ModuleAnchoredDecoupler") if dc:HasModule("ModuleAnchoredDecoupler") 
                                else "".
                            if dcMod <> "" 
                            { 
                                dtObj[setKey]["DECOUPLER"]["MODULE"]:Add(dcMod).
                                dtObj[setKey]["DECOUPLER"]["UID"]:Add(dc:UID).
                            }
                        }
                    }
                }
            }
            else 
            { 
                OutInfo("No parts found for SetIdx!":Format(setIdx)).
                if setIdx > 10
                {
                    OutInfo("SetIdx > 10, exiting loop").
                    set tanksLoaded to true. // Only support up to 11 drop tank sets, which is a lot 
                } 
            }
            set setIdx to setIdx + 1.
        }
        local currentSetKey to (0):ToString.
        
        global lock testResPct to dtObj[currentSetKey]["RESOURCE"]:Values[0][0]:amount / dtObj[currentSetKey]["RESOURCE"]:Values[0][0]:capacity.
        OutInfo("testResPct current value: {0}     ":Format(Round(testResPct, 5))).
        
        // Set up the first trigger
        when testResPct < 0.025 then
        {
            OutMsg("Drop tank trigger activated").
            for dcMod in dtObj[currentSetKey]["DECOUPLER"]["MODULE"]
            {
                if dcMod:HasEvent("decouple") dcMod:DoEvent("decouple").
            }
            unlock testResPct.
            dtObj:Remove(currentSetKey).
            if dtObj:Keys:Length > 0 
            {
                OutInfo("Preserving Drop Tank Trigger").
                Preserve.
            }
        }

        OutMsg("DropTankDropper successfully set up!").
        wait 1.
    }
    else
    {

    }
}
OutInfo("testResPct post-loop Value: {0}   ":Format(Round(testResPct, 5))).
Breakpoint().

OutMsg("Entering wait mode").
until false
{
    if testResPct > 0.025
    {
        print "Resource Percentage Remaining: {0}    ":Format(Round(testResPct, 4) * 100) at (2, 10).
        wait 0.01.
    }
    else 
    {
        OutMsg("testResPct below threshold, exiting wait loop").
        Breakpoint().
    }
}
OutInfo("...aaaaaaand we're done").