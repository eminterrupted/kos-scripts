@lazyGlobal off.

//-- Dependencies --//
runOncePath("0:/lib/lib_util").

//-- Variables --//
local sepList to list(
    "sepMotor1", 
    "sepMotorJr",
    "B9_Engine_T2_SRBS",
    "B9_Engine_T2A_SRBS",
    "B9_Engine_T2_SRBS_Jr",
    "B9_Engine_T2A_SRBS_Jr",
    "B9.Engine.T2.SRBS",
    "B9.Engine.T2A.SRBS",
    "B9.Engine.T2.SRBS.Jr",
    "B9.Engine.T2A.SRBS.Jr"
).

//-- Functions --//

//#region -- DeltaV
// Returns available deltaV on the vessel
global function ves_available_dv
{
    local availDv to 0.
    local dvStgObj to lex().

    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until stg <= -1 step { set stg to stg - 1.} do
    {
        local dvStg to ship:stageDeltaV(stg):current.
        set dvStgObj[stg] to dvStg.
        set availDv to availDv + dvStg.
    }
    set dvStgObj["availDv"] to availDv.
    return dvStgObj.
}

// Returns available deltaV on the vessel
global function ves_available_dv_next
{
    local availDv to 0.
    local dvStgObj to lex().
    //local massStats to ves_mass_stats().
    
    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until stg < 0 step { set stg to stg - 1.} do
    {
        local stgStats to ves_stage_stats(stg).
        local dvStg to mnv_stage_dv_next(stgStats).
        set dvStgObj[stg] to dvStg.
        set availDv to availDv + dvStg.
    }
    set dvStgObj["availDv"] to availDv.
    return dvStgObj.
}

// Creates an object of parts and masses by stage and decoupledIn
global function ves_mass_stats
{
    local stgObj to lex().
    local dcInObj to lex().

    for p in ship:parts 
    {   
        if not stgObj:hasKey(p:stage) set stgObj[p:stage] to lex("CurMass", 0, "DryMass", 0, "WetMass", 0, "Parts", list()).
        if not dcInObj:hasKey(p:stage) set dcInObj[p:stage] to lex("CurMass", 0, "DryMass", 0, "WetMass", 0, "Parts", list()).
        
        stgObj[p:stage]["parts"]:add(p).
        set stgObj[p:stage]["CurMass"] to stgObj[p:stage]["CurMass"]  + p:mass.
        set stgObj[p:stage]["DryMass"] to stgObj[p:stage]["DryMass"]  + p:dryMass.
        set stgObj[p:stage]["WetMass"] to stgObj[p:stage]["WetMass"]  + p:wetMass.

        dcInObj[p:decoupledIn]["parts"]:add(p).
        set dcInObj[p:decoupledIn]["CurMass"] to dcInObj[p:decoupledIn]["CurMass"]  + p:mass.
        set dcInObj[p:decoupledIn]["DryMass"] to dcInObj[p:decoupledIn]["DryMass"]  + p:dryMass.
        set dcInObj[p:decoupledIn]["WetMass"] to dcInObj[p:decoupledIn]["WetMass"]  + p:wetMass.
    }
    return lex("stg", stgObj, "decoupledIn", dcInObj).
}

//#region -- Engines
// Returns a list of active engines
global function ves_active_engines
{
    local engineList to list().
    local activeList to list().
    list engines in engineList.
    for e in engineList
    {
        if e:ignition and not e:flameout
        {
            activeList:add(e).
        }
    }
    return activeList.
}

// Returns list containing a list of active engines, overall thrust, average isp
global function ves_active_engines_stats
{
    local activeEngs    to list().
    local engList       to list().
    local activeIsp     to 0.
    local activeThrust  to 0.
    local relThrust     to 0.

    list engines in engList. 
    for e in engList 
    {
        if e:ignition and not e:flameout
        {
            activeEngs:add(e).
            set activeThrust to activeThrust + e:availableThrust.
            set relThrust to relThrust + (e:availableThrust / e:visp).
        }
    }
    if activeThrust = 0 
    {
        return list(list(), 0, 0).
    }
    else 
    {
        set activeIsp to activeThrust / relThrust.
        return list(activeEngs, activeThrust, activeIsp).
    }
}

// Returns summed thrust for provided engines at the current throttle 
global function ves_active_thrust
{
    parameter engList is list().
    
    if engList:length = 0 
    {
        list engines in engList.
    }

    local curThrust to 0.
    for e in engList
    {
        if e:ignition and not sepList:contains(e:name)
        {
            set curThrust to curThrust + e:thrust.
        }
    }
    return curThrust.
}

// Returns the current TWR based on active engines
global function ves_active_twr
{
    local curThr to ves_active_thrust().
    return curThr / ship:mass.
}

// Returns list containing a list of active engines, overall thrust, average isp
global function ves_parts_engines_stats
{
    parameter engList.

    local relThrust   to 0.
    local totalIsp    to 0.
    local totalThrust to 0.

    list engines in engList. 
    for e in engList 
    {
        set totalThrust to totalThrust + e:availableThrust.
        set relThrust to relThrust + (e:availableThrust / e:visp).
        
    }
    if totalThrust = 0 
    {
        return list(list(), 0, 0).
    }
    else 
    {
        set totalIsp to totalThrust / relThrust.
        return list(totalThrust, totalIsp).
    }
}

// Returns an object of data about a given stage's engines
global function ves_stage_stats
{
    parameter stg.

    local engList   to ves_stage_engines_next(stg).
    local engStats  to lex(
        "Engines", lex(),
        "Stage", lex(
            "Resources", lex()
        )
    ).

    local engActive     to false.
    local fuelMass      to 0.
    local stgAvailThr   to 0.
    local stgCurThr     to 0.
    local stgDecoupledIn to -1.
    local stgDv         to 0.
    local stgFuelFlow   to 0.
    local stgFuelMass   to 0.
    local stgMass       to lex().
    local stgMassFlow   to 0.
    local stgMaxThr     to 0.
    local stgPossThr    to 0.
    local stgRelThr     to 0.
        
    for e in engList 
    {
        if e:ignition and not e:flameout 
        {
            set engActive to true. 
        }
        else
        {
            set engActive to false.
        }

        set engStats["Engines"][e:uid] to lex(
            "Active", engActive,
            "AvailThr", e:availableThrust,
            "CurThr", e:thrust,
            "MaxThr", e:maxThrust,
            "PossThr", e:possibleThrust,
            "ISP", e:visp,
            "SLISP", e:slisp,
            "ExhVel", e:visp * constant:g0,
            "MaxFuelFlow", e:maxFuelFlow,
            "MaxMassFlow", e:maxMassFlow,
            "Resources", e:consumedResources,
            "DecoupledIn", e:decoupledIn,
            "Stage", e:stage
        ).

        set stgDecoupledIn to e:decoupledIn. 

        // Stage calculations
        //set stgDecoupledIn  to e:decoupledIn. 

        set stgAvailThr     to stgAvailThr + e:availableThrust.
        set stgCurThr       to stgCurThr + e:thrust.
        set stgMaxThr       to stgMaxThr + e:maxThrust.
        set stgPossThr      to stgPossThr + e:possibleThrust.

        set stgFuelFlow     to stgFuelFlow + e:maxFuelFlow.
        set stgMassFlow     to stgMassFlow + e:maxMassFlow.

        // Resources
        set engStats["Engines"][e:uid]["FuelMass"] to lex().
        for r in e:consumedResources:keys
        {
            local rName to "".
            if r = "LH2" set rName to "LqdHydrogen".
            else if r = "Liquid Fuel" set rName to "LiquidFuel".
            else if r = "Solid Fuel" set rName to "SolidFuel".
            else set rName to r.
            
            if not engStats["Stage"]["Resources"]:hasKey(rName)
            {
                set engStats["Stage"]["Resources"][rName] to e:consumedResources[r].
                if not engStats["Engines"][e:uid]["FuelMass"]:hasKey(rName) 
                {
                    set fuelMass to ves_stage_fuel_mass_next(e:decoupledIn, list(rName))[rName].
                    set engStats["Engines"][e:uid]["FuelMass"][rName] to fuelMass.
                    set stgFuelMass to stgFuelMass + fuelMass.
                }
            }
        }

        // ISP
        if not sepList:contains(e:name)
        {
            set stgRelThr to stgRelThr + (e:possibleThrust / e:visp).
        }
    }
    
    set engStats["Stage"]["Number"] to stg. 
    set engStats["Stage"]["AvailThr"] to stgAvailThr.
    set engStats["Stage"]["CurThr"] to stgCurThr.
    set engStats["Stage"]["MaxThr"] to stgMaxThr.
    set engStats["Stage"]["PossThr"] to stgPossThr.
    set engStats["Stage"]["ISP"] to choose stgPossThr / stgRelThr if stgRelThr > 0 and stgPossThr > 0 else 0.
    set engStats["Stage"]["ExhVel"] to engStats["Stage"]["ISP"] * constant:g0.
    set engStats["Stage"]["FuelFlow"] to stgFuelFlow.
    set engStats["Stage"]["MassFlow"] to stgMassFlow.

    set stgMass to ves_stage_mass(stg, stgDecoupledIn, engStats["Stage"]["Resources"]:keys).
    set engStats["Stage"]["CurMass"] to stgMass["Current"].
    set engStats["Stage"]["DryMass"] to stgMass["Current"] - stgMass["FuelMass"].
    set engStats["Stage"]["WetMass"] to stgMass["Wet"].
    set engStats["Stage"]["ShipMass"] to stgMass["Ship"].
    set engStats["Stage"]["FuelMass"] to stgMass["FuelMass"].

    return engStats.
}

// Returns whether any engine is on (true / false)
global function ves_engines_on
{
    local engList to list().
    list engines in engList.
    for e in engList
    {
        if e:ignition and not e:flameout
        {
            return true.
        }
    }
    return false.
}

// Returns engines in a given set of parts
global function ves_parts_engines
{
    parameter pList.

    local engList to list().

    for p in pList
    {
        if p:typeName = "engine" engList:add(p).
    }

    return engList.
}

// Returns a list of engines that are in the currently activated stage
global function ves_stage_engines
{
    local engList to list().
    local stgList to list().
    list engines in engList.

    for e in engList 
    {
        if e:stage >= stage:number 
        {
            stgList:add(e).
        }
    }
    return stgList.
}

// Returns a list of engines that are decoupled in the provided stage
global function ves_stage_engines_next
{
    parameter stg.

    local engList to list().
    local stgList to list().
    list engines in engList.

    for e in engList 
    {
        if e:stage = stg
        {
            stgList:add(e).
        }
    }
    return stgList.
}

// Returns the aggregate exhaust velocity for a given stage
global function ves_stage_exh_vel
{
    parameter stg.

    local stgIsp to ves_stage_isp(stg).
    return constant:g0 * stgIsp.
}

// Returns the aggregate exhaust velocity for a given decoupledIn stage
global function ves_stage_exh_vel_next
{
    parameter stg.

    local stgIsp to ves_stage_isp_next(stg).
    return constant:g0 * stgIsp.
}

// Returns isp for a given stage
global function ves_stage_isp
{
    parameter stg.

    local engRelThr    to 0.
    local engStgThr    to 0.
    local sepRelThr    to 0.
    local sepStgThr    to 0.

    local engStgList   to list().
    local sepStgList   to list().
    local stgList       to list().
    list engines in engStgList.

    for e in engStgList 
    {
        if e:stage = stg and not sepList:contains(e:name)
        {
            stgList:add(e).
            set engStgThr to engStgThr + e:possibleThrust.
            set engRelThr to engRelThr + (e:possibleThrust / e:visp).
        }
        else if e:stage = stg
        {
            sepStgList:add(e).
            set sepStgThr to sepStgThr + e:possibleThrust.
            set sepRelThr to choose sepRelThr + (e:possibleThrust / e:isp) if e:isp > 0 else 0.
        }
    }
    
    if engStgList:length > 0 
    {
        if engStgThr = 0 
        {
            return 0.
        }
        else
        {
            return engStgThr / engRelThr.
        }
    }
    else if sepStgList:length > 0 
    {
        if sepStgThr = 0 
        {
            return 0.
        }
        else
        {
            return sepStgThr / sepRelThr.
        }
    }
    else 
    {
        return 0.
    }
}

// Returns isp for a given stage
// using decoupledIn for stage info
global function ves_stage_isp_next
{
    parameter stg.

    local relThr    to 0.
    local stgThr    to 0.
    
    local engList   to list().
    list engines in engList.

    for e in engList 
    {
        if e:stage = stg and not sepList:contains(e:name)
        {
            set stgThr to stgThr + e:possibleThrust.
            set relThr to relThr + (e:possibleThrust / e:visp).
        }
    }
    
    if stgThr = 0 
    {
        return 0.
    }
    else
    {
        return stgThr / relThr.
    }
}

// Returns the possible aggregate thrust for a given stage
global function ves_stage_thrust
{
    parameter stg.

    local stgThr    to 0.
    
    local engList   to list().
    list engines in engList.

    for e in engList
    {
        if e:stage = stg and not sepList:contains(e:name)
        {
            set stgThr to stgThr + e:possibleThrust.
        }
    }
    return stgThr.
}

// Returns the possible aggregate thrust for a given decoupledIn stage
global function ves_stage_thrust_next
{
    parameter stg.

    local stgThr    to 0.
    
    local engList   to list().
    list engines in engList.

    for e in engList
    {
        if e:decoupledIn = stg and not sepList:contains(e:name)
        {
            set stgThr to stgThr + e:possibleThrust.
        }
    }
    return stgThr.
}
//#endregion

//#region -- Boosters and Drop Tanks
// Boosters
// Returns any boosters via tag "boosters.[loopId]"
global function ves_get_boosters
{
    local dcLex   to lex().
    local tankLex to lex().
    
    for t in ship:partsTaggedPattern("booster") 
    {
        local loopId to t:tag:split(".")[1]:toNumber.
        
        if t:typeName = "decoupler" 
        {
            if not dcLex:hasKey(loopId)
            {
                set dcLex[loopId] to list(t).
            }
            else
            {
                dcLex[loopId]:add(t).
            }

            set tankLex[loopId] to t:children[0].
        }
    }
    return list(dcLex, tankLex).
}

// Checks booster resources and stages when booster res falls below threshold
global function ves_update_booster
{
    parameter boosterObj. // Idx 0 is DCs, 1 is tanks

    local boosterDC to boosterObj[0].
    local boosterTanks to boosterObj[1].

    if boosterDC:length > 0
    {
        local boosterId     to boosterDC:keys:length - 1.
        local boosterRes    to choose boosterTanks[boosterId]:resources[1] if boosterTanks[boosterId]:name:matchesPattern("Size1p5.Tank.05") else boosterTanks[boosterId]:resources[0].
        if boosterRes:amount < 0.001
        {
            for dc in boosterDC[boosterId]
            {
                if dc:children:length > 0 
                {
                    boosterDC:remove(boosterId).
                    boosterTanks:remove(boosterId).
                }
            }
            ves_safe_stage("booster").
        }
        if boosterDC:length > 0 
        {
            return true.
        }
        else 
        {
            return false.
        }
    }
    else 
    {
        return false.
    }
}


// Returns all drop tanks (decouplers tagged with dropTank.<n>) and their child tanks for monitoring
global function ves_get_drop_tanks
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

// Drop tanks - checks the amount of fuel left in drop tanks and releases them when empty
global function ves_update_droptank
{
    parameter dropTanksObj.

    local dropTanksDC   to dropTanksObj[0].
    local dropTanks     to dropTanksObj[1].

    if dropTanksDC:keys:length > 0
    {
        local dropTankId to dropTanksDC:length - 1.
        local dropTankRes to dropTanks[dropTankId]:resources[0].
        
        if dropTankRes:amount < 0.001
        {
            for dc in dropTanksDC[dropTankId]
            {
                local dcModule to choose "ModuleAnchoredDecoupler" if dc:hasModule("ModuleAnchoredDecoupler") else "ModuleDecouple".
                if dc:children:length > 0 
                {
                    util_do_event(dc:getModule(dcModule), "decouple").
                    dropTanksDC:remove(dropTankId).
                    dropTanks:remove(dropTankId).
                }
            }
        }

        if dropTanksDC:length > 0 
        {
            return true.
        }
        else 
        {
            return false.
        }
    }
    else 
    {
        return false.
    }
}
//#endregion

//#region -- Mass
// Mass of fuel that can be burned in a stage. 
// [stg(int), fuels(list) -> stgFuelObj(lex)]
global function ves_stage_fuel_mass
{
    parameter stg,
              fuels.

    local fuelMass      to 0.
    local fuelObj       to lex().
    local fuelRatio     to 1.
    local stgFuelObj    to lex().
    local thisRatio     to 1.

    for p in ship:parts
    {
        fuelObj:clear().
        set fuelRatio to 1.
        if p:decoupledIn = stg - 1
        {
            if p:resources:length > 0
            {
                for r in p:resources 
                {
                    if fuels:contains(r:name)
                    {
                        set thisRatio to r:amount / r:capacity.
                        set fuelObj[r:name] to lex(
                            "ratio", thisRatio
                        ).
                        if thisRatio < fuelRatio set fuelRatio to thisRatio.
                    }
                }

                for r in p:resources
                {
                    if fuels:contains(r:name)
                    {
                        set fuelMass to ((r:capacity * fuelRatio) * r:density).
                        if stgFuelObj:hasKey(r:name)
                        {
                            
                            set stgFuelObj[r:name] to stgFuelObj[r:name] + fuelMass.
                        }
                        else
                        {
                            set stgFuelObj[r:name] to fuelMass.
                        }
                    }
                }
            }
        }
    }
    return stgFuelObj.
}

// Attempting to take payload decouplers into account
global function ves_stage_fuel_mass_next
{
    parameter stg,
              fuels.

    local fuelsCopy     to fuels:copy().
    local fuelMass      to 0.
    //local fuelObj       to lex().
    //local fuelRatio     to 1.
    local stgFuelObj    to lex().
    //local stgFuelMass   to 0.
    //local stgRes        to 0.
    local stgResAmt     to 0.
    local stgResCap     to 0.
    local thisRatio     to 1.

    
    for r in ship:resources 
    {
        if fuels:contains(r:name) 
        {
            for p in r:parts 
            {
                local fuelRatio to 1.
                
                if p:decoupledIn = stg
                {
                    // print "Found: " + p:name.
                    for pRes in p:resources
                    {
                        if pRes:name = r:name
                        {   
                            // print "Resource: " + r:name.
                            // print "Amount  : " + pRes:amount.
                            // print "Capacity: " + pRes:capacity.
                            set stgResAmt to stgResAmt + pRes:amount.
                            set stgResCap to stgResCap + pRes:capacity.
                        }
                    }

                    set thisRatio to stgResAmt / stgResCap.
                    if thisRatio < fuelRatio set fuelRatio to thisRatio.

                    for pRes in p:resources
                    {
                        if pRes:name = r:name 
                        {
                            set fuelMass to ((pRes:capacity * fuelRatio) * pRes:density).
                            //set stgFuelMass to stgFuelMass + fuelMass.
                            // print pRes:name + " Mass: " + fuelMass.
                            if stgFuelObj:hasKey(r:name)
                            {
                                set stgFuelObj[r:name] to stgFuelObj[r:name] + fuelMass.
                            }
                            else
                            {
                                set stgFuelObj[r:name] to fuelMass.
                            }
                        }
                    }
                }
            }

            fuelsCopy:remove(fuelsCopy:find(r:name)).
            if fuelsCopy:length = 0 break.
        }
    }
    //set stgFuelObj["StgFuelMass"] to stgFuelMass.
    return stgFuelObj.
}

// Returns the current vessel mass if the vessel was on the 
// given stage number (i.e., stg = 4, mass for stages 4 -> -1).
global function ves_mass_at_stage
{
    parameter stg.

    local curMass to 0.
    for p in ship:parts
    {
        if p:stage <= stg 
        {
            set curMass to curMass + p:mass.
        }
    }
    return curMass.
}

// Returns the current vessel mass if the vessel was on the 
// given stage number (i.e., stg = 4, mass for parts decoupledIn stages 4 -> -1).
global function ves_mass_at_stage_next
{
    parameter stg.

    local curMass to 0.
    for p in ship:parts
    {
        if p:decoupledIn <= stg 
        {
            set curMass to curMass + p:mass.
        }
    }
    return curMass.
}

// Returns a mass object for a list of parts
global function ves_mass_for_parts
{
    parameter pList.

    local curMass to 0.
    local dryMass to 0.
    local elFuelMass to 0.
    local fuelMass to 0.
    local fuelRatio to 0.
    local wetMass to 0.

    local resObj  to lex().

    for p in pList
    {
        set curMass to curMass + p:mass.
        set dryMass to dryMass + p:dryMass.
        set wetMass to wetMass + p:wetMass.

        set fuelRatio to 1.

        if p:resources:length > 0
        {
            for r in p:resources 
            {
                if r:amount > 0 
                {
                    local thisRatio to r:amount / r:capacity.
                    if thisRatio < fuelRatio set fuelRatio to thisRatio.

                    set fuelMass to ((r:capacity * fuelRatio) * r:density).
                    set elFuelMass to elFuelMass + fuelMass.
                    if resObj:hasKey(r:name)
                    {
                        
                        set resObj[r:name] to resObj[r:name] + fuelMass.
                    }
                    else
                    {
                        set resObj[r:name] to fuelMass.
                    }
                }
                else
                {
                    if not resObj:hasKey(r:name)
                    {
                        set resObj[r:name] to fuelMass.
                    }
                }
            }
        }
    }

    return lex("Current", curMass, "Dry", dryMass, "Wet", wetMass, "Resources", resObj).
}

// Returns the current and dry mass for a given stage for DV calcs
// Uses stg - 1 because engines are always a stage ahead of part stage
// numbers
global function ves_mass_for_stage 
{
    parameter stg.

    local curMass to 0.
    local dryMass to 0.

    for p in ship:parts
    {
        if p:decoupledIn = stg - 1
        {
            set curMass to curMass + p:mass.
            set dryMass to dryMass + p:dryMass.
        }
        else if p:typename = "decoupler" and p:stage = stg - 1
        {
            set curMass to curMass + p:mass.
            set dryMass to dryMass + p:dryMass.
        }
    }

    return list(curMass, dryMass).
}

// Returns a list of vessel mass at stage, stage mass, stage dry mass
global function ves_stage_mass
{
    parameter stg,
              decoupledIn is -1,
              fuels is list().

    local curMass to 0.
    local dryMass to 0.
    local fuelMass to 0.
    local shipMass to 0.
    local stgFuelMass to 0.
    local wetMass to 0.
    
    local fuelObj to lex().
    local stgFuelObj to lex().
    

    for p in ship:parts
    {
        fuelObj:clear().
        local fuelRatio to 1.

        if p:decoupledIn <= stg 
        {
            set shipMass to shipMass + p:mass.
            // set curMass to curMass + p:mass.
            // set dryMass to dryMass + p:dryMass.
            // set wetMass to wetMass + p:wetMass.
        }
        
        if p:decoupledIn = decoupledIn
        {
            set curMass to curMass + p:mass.
            set dryMass to dryMass + p:dryMass.
            set wetMass to wetMass + p:wetMass.

            if p:resources:length > 0
            {
                for r in p:resources 
                {
                    if fuels:contains(r:name)
                    {
                        local thisRatio to r:amount / r:capacity.
                        // set fuelObj[r:name] to lex(
                        //     "ratio", thisRatio
                        // ).
                        if thisRatio < fuelRatio set fuelRatio to thisRatio.

                        set fuelMass to ((r:capacity * fuelRatio) * r:density).
                        set stgFuelMass to stgFuelMass + fuelMass.
                        if stgFuelObj:hasKey(r:name)
                        {
                            
                            set stgFuelObj[r:name] to stgFuelObj[r:name] + fuelMass.
                        }
                        else
                        {
                            set stgFuelObj[r:name] to fuelMass.
                        }
                    }
                }
            }
        }
    }

    return lex("Current", curMass, "Dry", dryMass, "Wet", wetMass, "Ship", shipMass, "FuelMass", stgFuelMass, "Resources", stgFuelObj).
}
//#endregion

//#region -- Steering
// Checks whether the ship's roll error is marginal
global function ves_roll_settled
{
    return util_check_value(steeringManager:rollError, 0.125).
}

// Checks whether the steering manager has settled on target
global function ves_settled
{
    return util_check_value(steeringManager:angleError, 0.125).
}
//#endregion

//#region -- Staging
// Safe staging
global function ves_safe_stage
{
    parameter mode is "".

    wait 0.5.
    until false 
    {
        until stage:ready 
        {   
            wait 0.01.
        }
        stage.
        break.
    }
    
    // If we are not in booster separation mode, run sep motor and deployable engine check
    if mode = "" 
    {
        // Stage again if currents engines are sep motors
        if ship:availablethrust > 0 
        {
            local onlySep to true.
            for e in ves_stage_engines()
            {
                if not sepList:contains(e:name)
                {
                    set onlySep to false.
                    break.
                }
            }
            
            if onlySep 
            {
                wait 1.
                stage.
            }
        }
        
        for e in ves_stage_engines()
        {
            if e:hasModule("ModuleDeployableEngine") 
            {
                disp_info2("ModuleDeployableEngine found, deploying...").
                wait until e:thrust > 0.
                break.
            }
        }
        //General wait for once staging is complete
        wait 0.5.
    }
    
    disp_info2().
}
//#endregion

//#region -- Translation
// Takes a vector and translates towards it
global function ves_translate
{
    parameter vec is v(0, 0, 0).

    if vec:mag > 1 set vec to vec:normalized. 

    set ship:control:fore       to vDot(vec, ship:facing:forevector).
    set ship:control:starboard  to vDot(vec, ship:facing:starvector).
    set ship:control:top        to vDot(vec, ship:facing:topvector).
}
//#endregion

//#region -- Ship Resources
// Return a given resource type from ship:resources
global function ves_get_resource
{
    parameter resource.

    for r in ship:resources
    {
        if r:name = resource return r.
    }
    return false.
}
//#endregion

//#region -- Part Module Actions / Events

//#region -- Antenna / Comm actions
// Extend / retract antennas in a list
global function ves_activate_antenna
{
    parameter commList is ship:modulesNamed("ModuleRTAntenna"),
              state is true.

    local event to choose "activate" if state else "deactivate".
    
    for m in commList
    {       
        util_do_event(m, event).
    }
}

// Returns the range of a given RTAntenna module
global function ves_antenna_range
{
    parameter m.

    local isDish to false.

    for field in m:allFields
    {
        if field:contains("dish")
        {
            set isDish to true.
        }
    }

    local commRange to choose m:getField("dish range") if isDish else m:getField("omni range").
    local rangeMulti to commRange[commRange:length - 2].
    set commRange to commRange:remove(commRange:length - 2, 2):toNumber.
    if      rangeMulti = "K" set commRange to commRange * 1000.
    else if rangeMulti = "M" set commRange to commRange * 1000000.
    else if rangeMulti = "G" set commRange to commRange * 1000000000.

    return commRange.
}

// Sets up triggers to extend antennas when staged to the part's stage
global function ves_antenna_stage_trigger
{
    parameter commList to ship:modulesNamed("ModuleRTAntenna").

    local stagedCommsObj to lex().

    for m in commList
    {
        if m:part:tag:contains("stageAntenna")
        {
            if not stagedCommsObj:hasKey(m:part:stage) 
            {
                set stagedCommsObj[m:part:stage] to list(m).
            }
            else
            {
                stagedCommsObj[m:part:stage]:add(m).
            }
        }
    }

    for stg in stagedCommsObj:keys
    {
        when stage:number = stg + 1 then
        {
            ves_activate_antenna(stagedCommsObj[stg], true).
        }
    }
}

// Returns the highest gain antenna on the vessel
global function ves_antenna_top_gain
{
    parameter commList.

    local topGain to "".
    local dishIdx to 0.
    
    for m in commList
    {
        if dishIdx = 0 set topGain to m.
        else 
        {
            if ves_antenna_range(m) > ves_antenna_range(topGain) set topGain to m.
        }
        set dishIdx to dishIdx + 1.
    }
    return topGain.
}
//#endregion

//#region -- NeptuneCams
// Take given image type from neptune cameras on board
global function ves_neptune_image
{
    parameter type is "all". // Values: "greyscale", "color", "rgb", "red", "green", "blue", "ir" (infrared), "uv" (ultraviolet), "all"

    local camList is ship:modulesNamed("ModuleNeptuneCamera").
    for cam in camList
    {
        for event in cam:allEvents
        {
            if event:contains("greyscale image") 
            {
                if type = "greyscale" or type = "all" util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")).
            }
            else if event:contains("full colour image")
            {
                if type = "color" or type = "all" util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")). 
            }
            else if event:contains("red image")
            {
                if type = "rgb" or type = "red" or type = "all" util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")). 
            }
            else if event:contains("green image")
            {
                if type = "rgb" or type = "green" or type = "all" util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")). 
            }
            else if event:contains("blue image")
            {
                if type = "rgb" or type = "blue" or type = "all" util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")). 
            }
            else if event:contains("infrared image")
            {
                if type = "ir" or type = "all"  util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")).
            }
            else if event:contains("ultraviolet image")
            {
                if type = "uv" or type = "all"  util_do_event(cam, event:replace("(callable) ", ""):replace(", is KSPEvent", "")).
            }
        }
    }
}
//#endregion

//#region -- Fuel cell actions
// Activate / Deactivate a fuel cell
global function ves_activate_fuel_cell
{
    parameter fuelCell,
              mode is true. // on = true, off = false

    local fcMod to fuelCell:getModule("ModuleResourceConverter").

    if mode
    {
        local onEvent to choose "start turbine" if fuelCell:name:contains("apu-radial") else "start fuel cell".
        util_do_event(fcMod, onEvent).
        
    }
    else if not mode
    {
        local offEvent to choose "stop turbine" if fuelCell:name:contains("apu-radial") else "stop fuel cell".
        util_do_event(fcMod, offEvent).
    }
}
//#endregion

//#region -- Lights actions
global function ves_activate_lights
{
    parameter lightList is ship:modulesNamed("ModuleLight"),
              state is true.

    local event to choose "lights on" if state else "lights off".
    local action to choose "turn light on" if state else "turn light off".

    for m in lightList 
    {
        if not util_do_event(m, event) 
        {
            util_do_action(m, action).
        }
    }
}
//#endregion

//#region --Radiators
// Extend / retract radiators
global function ves_activate_radiator
{
    parameter radList is ship:modulesNamed("ModuleSystemHeatRadiator"),
              state is true.

    if radList:length = 0 set radList to ship:modulesNamed("ModuleDeployableRadiator").
    local event to choose "extend radiator" if state else "retract radiator".

    for m in radList 
    {
        util_do_event(m, event).
    }
}
//#endregion
 
//#region -- Robotics
// Get all robotic modules for a given set of parts
global function ves_get_robotics
{
    parameter pList is ship:parts.

    local roboticMods to list().

    local mHinge to "ModuleRoboticServoHinge".
    local mPiston to "ModuleRoboticServoPiston".
    local mRotate to "ModuleRoboticRotationServo".
    local mRotor  to "ModuleRoboticServoRotor".

    for p in pList
    {    
        if p:hasModule(mHinge)       roboticMods:add(p:getModule(mHinge)).
        else if p:hasModule(mPiston) roboticMods:add(p:getModule(mPiston)).
        else if p:hasModule(mRotate) roboticMods:add(p:getModule(mRotate)).
        else if p:hasModule(mRotor)  roboticMods:add(p:getModule(mRotor)).
    }

    return roboticMods.
}

// Toggle a servo / hinge
global function ves_toggle_robotics
{
    parameter roboticsList.
    
    for m in roboticsList
    {
        if m:getField("locked") 
        {
            util_do_action(m, "toggle locked").
            print "Unlocking " + m:part:name.
        }
        util_do_action(m, "toggle hinge").
    }
    wait 8.
}
//#endregion

//#region -- Solar panels
// Extend / retract solar panels in a list. 
global function ves_activate_solar
{
    parameter solarList is ship:modulesNamed("ModuleDeployableSolarPanel"), 
              state is true.

    local event to choose "extend solar panel" if state else "retract solar panel". 
    
    for m in solarList
    {
        util_do_event(m, event).
    }
}
//#endregion

//#region -- Bays
// Get all bays on a vessel
global function ves_get_us_bays
{
    local bayList to list().
    if ship:modulesNamed("USAnimateGeneric"):length > 0 
    {
        for bay in ship:partsNamedPattern("USCylindricalShroud")
        {
            local b to bay:getModule("USAnimateGeneric").
            bayList:add(b).
        }
    }
    return bayList.
}

// Open bay doors
global function ves_open_bays
{
    parameter bayList is ship:modulesNamed("USAnimateGeneric"),
              door is "all".

    //if door = "all" bays on.
    // Below for US bays
    for bay in bayList 
    {
        if door = "all" or door = "primary"
        {
            util_do_event(bay, "deploy primary bays").
            util_do_event(bay, "open doors").
        }
        if door = "all" or door = "secondary"
        {
            util_do_event(bay, "deploy secondary bays").
        }
    }
}

// Close bay doors
global function ves_close_bays
{
    parameter bayList is ship:modulesnamed("USAnimateGeneric"),
              door is "all".

    bays off.
    // Below for US bays
    for bay in bayList 
    {
        if door = "all" or door = "primary"
        {
            util_do_event(bay, "retract primary bays").
            util_do_event(bay, "close doors").
        }
        if door = "all" or door = "secondary"
        {
            util_do_event(bay, "retract secondary bays").
        }
    }
}

//#region -- Fairings
// Jettison 
global function ves_jettison_fairings
{
    parameter fairingList to list().

    local procEvent     to "jettison fairing".
    local procFairing   to "ProceduralFairingDecoupler".

    local stEvent       to "deploy".
    local safFairing    to "ModuleSimpleAdjustableFairing".
    local stFairing     to "ModuleProceduralFairing".

    if fairingList:length > 0
    {
        for m in fairingList
        {
            if m:name = procFairing util_do_event(m, procEvent).
            else if m:name = safFairing or m:name = stFairing util_do_event(m, stEvent).
        }
    }
}
//#endregion

//#region -- Capacitors
// Automatically controls capacitor charge / recharge.
global function ves_auto_capacitor
{
    local ec           to ves_get_resource("ElectricCharge").
    local storedCharge to ves_get_resource("StoredCharge").

    print "Auto capacitors".
    // Auto-triggers.
    when ec:amount / ec:capacity <= 0.25 and storedCharge:amount > 0 then
    {
        print "Discharging at " + round(missionTime).
        ves_discharge_capacitor().    
        preserve.
    }

    when storedCharge:amount = 0 and ec:amount / ec:capacity >= 0.995 then
    {
        print "Recharging at " + round(missionTime).
        ves_recharge_capacitor().
        when storedCharge:amount / storedCharge:capacity = 1 or ec:amount / ec:capacity < 0.50 then
        {
            print "Disabling recharge at " + round(missionTime).
            ves_recharge_capacitor(ship:modulesNamed("DischargeCapacitor"), false).
        }
    preserve.
    }
}

global function ves_discharge_capacitor
{
    parameter capList to ship:modulesNamed("DischargeCapacitor").

    local ec to ves_get_resource("ElectricCharge").
    
    if ec:amount = ec:capacity return false.
    for m in capList
    {
        if m:getField("Status") = "Ready"
        {
            util_do_event(m, "discharge capacitor").
        }
    }
    return true.
}

global function ves_recharge_capacitor
{
    parameter capList to ship:modulesNamed("DischargeCapacitor"),
              state is true.

    for m in capList 
    {
        if state 
        {
            if m:getField("Status") = "Discharged"
            {
                util_do_event(m, "enable recharge").
            }
        }
        else 
        {
            util_do_event(m, "disable recharge").
        }
    }
    return true.
}
//#endregion

//#region -- Launch Escape System
// Jettison a given LES tower, ensuring the engine starts before decoupling.
global function ves_jettison_les
{
    parameter lesTower.

    lesTower:activate.
    wait 0.05.
    if not lesTower:flameout
    {
        lesTower:getModule("ModuleDecouple"):doEvent("decouple").
        return true.
    }
    else return false. 
}

//#endregion -- Part module actions / events


//#region -- vNext function playground

// checking an external tank (drop tank or booster) for resources. Returns true if the tank has resources, false if not
global function ves_check_ext_tank
{
    parameter extObj,
              extId to -1. // Idx 0 is DCs, 1 is tanks

    local extDC to extObj[0].
    local extTanks to extObj[1].

    if extDC:length > 0
    {
        if extId = -1 set extId to extDC:keys:length - 1.
        local extRes    to choose extTanks[extId]:resources[1] if extTanks[extId]:name:matchesPattern("Size1p5.Tank.05") else extTanks[extId]:resources[0].
        if extRes:amount >= 0.01
        {
            return true.
        }
        else
        {
            return false.
        }
    }
    return false.
}

global function ves_drop_tank
{
    parameter extObj,
              extId to -1.

    local extDC     to extObj[0].
    local extTank   to extObj[1].
    
    if extDC:length > 0 
    {
        if extId = -1 set extId to extDC:length - 1.
        for dc in extDC[extId]
        {
            local dcModule to choose "ModuleAnchoredDecoupler" if dc:hasModule("ModuleAnchoredDecoupler") else "ModuleDecouple".
            if dc:children:length > 0 
            {
                util_do_event(dc:getModule(dcModule), "decouple").
                extDC:remove(extId).
                extTank:remove(extId).
            }
        }
    }
}

global function ves_drop_booster
{
    parameter extObj,
              extId to -1.

    local extDC     to extObj[0].
    local extTank   to extObj[1].

    if extDC:length > 0 
    {
        if extId = -1 set extId to extDC:length - 1.
        for dc in extDC[extId]
        {
            
            if dc:children:length > 0 
            {
                extDC:remove(extId).
                extTank:remove(extId).
            }
        }
        ves_safe_stage("booster").
    }
}
//#endregion