@lazyGlobal off.
clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

DispMain(scriptPath()).

local calcPath to Path("0:/log/data/eng/response/engResponseCurves.json").

local atmPres to 0.
local curStg is stage:number.
local throtPos to throttle.

local doneTE to 0.
local startTS to 0.

local doneFlag to false.
local isThrotUp to false.
local mergeFlag to true.
local monitorResponse to true.
local quitFlag to false.

local engObj to lex().
local wrkObj to lex().

local id to "".
local idStr to { parameter _stg, _uid. return "{0}:{1}:{2}":format(ship:name:replace(" ","_"):replace("'","_"), _stg, _uid). }.
local logStr to "".

if params:length > 0 
{
    set calcPath to params[0].
}

local actEngs to GetEngines("Active", false).

if exists(calcPath) 
{
    set engObj to readJson(calcPath).
}
else
{
    set engObj to lex("Engine", lex()).
    writeJson(engObj, calcPath).
}

OutMsg("Beginning profiling").
until quitFlag
{
    local msgs to CheckMsgQueue().
    if msgs:length > 2
    {
        if msgs[2]:matchesPattern("^monitorResponse=[{true}|{false}]{1}")
        {
            set monitorResponse to msgs[2]:split("=")[1].
            msgs:remove(2).
            msgs:remove(1).
            msgs:remove(0).
        }
    }
    
    if monitorResponse
    {
        if throttle <> throtPos
        {
            set startTS to time:seconds.
            set isThrotUp to choose true if throttle > throtPos else false.
            local stThrot to round(throtPos, 2).
            local tgtThrot to round(throttle, 2).

            set wrkObj to engObj["Engine"]:copy.
            set doneFlag to false.

            until doneFlag
            {
                if stage:number <> curStg
                {
                    set actEngs to GetEngines("active", false).
                    set curStg to stage:number.
                }

                set doneFlag to true.
                set atmPres to body:atm:atmospherePressure(altitude).
                local curThr to 0.
                local pctThr to 0.
                local throtThr to 0.
                local thisEng to lex().
                // local fuelFlow to 0.
                // local maxFuelFlow to 0.
                // local massFlow to 0.
                // local maxMassFlow to 0.

                for eng in actEngs
                {
                    set curThr to round(eng:thrust, 3).
                    set throtThr to round(eng:availableThrustAt(atmPres) * throttle, 3).
                    set pctThr to round(curThr / throtThr, 5).
                    
                    set logStr to "{0},{1},{2},{3],{4},{5},{6},{7},{8},{9},{10}":format(
                        time:seconds, 
                        eng:name, 
                        stThrot, 
                        tgtThrot, 
                        curThr,
                        throtThr,
                        pctThr,
                        eng:fuelFlow, 
                        eng:maxFuelFlow, 
                        eng:massFlow, 
                        eng:maxMassFlow
                    ).

                    set id to idStr(eng:stage, eng:uid).

                    if wrkObj:hasKey(eng:name)
                    {
                        if wrkObj[eng:name]["Tracked"]:contains(id)
                        {
                            set thisEng to choose wrkObj[eng:name]["Up"]["Data"][id] if isThrotUp else wrkObj[eng:name]["Down"]["Data"][id].
                        }
                        else
                        {
                            set thisEng to lex(
                                "Avg", 0
                                ,"Min", 999
                                ,"Max", 0 
                                ,"DataPoints", 0
                                ,"Data", list()
                            ).
                            set wrkObj[eng:name]["Up"]["Data"][id] to thisEng.
                            set wrkObj[eng:name]["Down"]["Data"][id] to thisEng.
                            wrkObj[eng:name]["Tracked"]:add(id).
                        }
                    }
                    else
                    {
                        set wrkObj[eng:name] to lex(
                            "Up", lex(
                                "Avg", 0
                                ,"Min", 999
                                ,"Max", 0
                                ,"DataPoints", 0
                                ,"Data", lex(
                                    id, lex()
                                )
                            )
                            ,"Down", lex(
                                "Avg", 0
                                ,"Min", 999
                                ,"Max", 0
                                ,"DataPoints", 0
                                ,"Data", lex(
                                    id, lex()
                                )
                            )
                            ,"Tracked", list()
                        ).

                        set thisEng to lex(
                            "Avg", 0
                            ,"Min", 999
                            ,"Max", 0
                            ,"DataPoints", 0
                            ,"Data", list()
                        ).
                        wrkObj[eng:name]["Tracked"]:add(id).
                    }

                    thisEng["Data"]:add(logStr). // Debug

                    if CheckValDeviation(curThr, round(eng:availableThrustAt(atmPres) * tgtThrot, 3), 0.05) 
                    {
                        set doneTE to round(time:seconds - startTS, 3).

                        set thisEng["Avg"] to ((thisEng["Avg"]  * thisEng["DataPoints"]) + doneTE) / (thisEng["DataPoints"] + 1).
                        set thisEng["Min"] to min(thisEng["Min"], doneTE).
                        set thisEng["Max"] to max(thisEng["Max"], doneTE).
                        set thisEng["DataPoints"] to thisEng["DataPoints"] + 1.

                        if isThrotUp
                        {
                            set wrkObj[eng:name]["Up"]["Data"][id] to thisEng.
                            set wrkObj[eng:name]["Up"]["Avg"] to ((wrkObj[eng:name]["Up"]["Avg"]  * wrkObj[eng:name]["Up"]["DataPoints"]) + doneTE) / (wrkObj[eng:name]["Up"]["DataPoints"] + 1).
                            set wrkObj[eng:name]["Up"]["Min"] to min(wrkObj[eng:name]["Up"]["Min"], doneTE).
                            set wrkObj[eng:name]["Up"]["Max"] to max(wrkObj[eng:name]["Up"]["Max"], doneTE).
                            set wrkObj[eng:name]["Up"]["DataPoints"] to wrkObj[eng:name]["Up"]["DataPoints"] + 1.
                        }
                        else
                        {
                            set wrkObj[eng:name]["Down"]["Data"][id] to thisEng.
                            set wrkObj[eng:name]["Down"]["Avg"] to ((wrkObj[eng:name]["Down"]["Avg"]  * wrkObj[eng:name]["Down"]["DataPoints"]) + doneTE) / (wrkObj[eng:name]["Down"]["DataPoints"] + 1).
                            set wrkObj[eng:name]["Down"]["Min"] to min(wrkObj[eng:name]["Down"]["Min"], doneTE).
                            set wrkObj[eng:name]["Down"]["Max"] to max(wrkObj[eng:name]["Down"]["Max"], doneTE).
                            set wrkObj[eng:name]["Down"]["DataPoints"] to wrkObj[eng:name]["Down"]["DataPoints"] + 1.
                        }
                        set doneFlag to true.
                    }
                    
                    GetInputChar().
                    if g_termChar = terminal:input:endCursor
                    {
                        OutMsg("Aborting profiling current burn...").
                        set mergeFlag to false.
                        set doneFlag to true.
                    }
                    else if g_termChar = terminal:input:deleteright
                    {
                        OutMsg("Quitting profiling...").
                        set mergeFlag to false.
                        set doneFlag to true.
                        set quitFlag to true.
                    }
                }
            }
            set throtPos to throttle.
            if mergeFlag {
                set engObj["Engine"] to wrkObj.
                writeJson(engObj, calcPath).
            }
        }
    }

    GetInputChar().
    if g_termChar = terminal:input:endcursor or g_termChar = terminal:input:deleteright
    {
        OutMsg("Quitting profiling...").
        set quitFlag to true.
    }
}