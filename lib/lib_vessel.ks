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
        //local dvStg to mnv_stage_dv(stg).
        local dvStg to ship:stageDeltaV(stg):current.
        set dvStgObj[stg] to dvStg.
        set availDv to availDv + dvStg.
        print "Stage " + stg + " dV: " + dvStg.
    }

    print " ".
    print "Total available dV: " + availDv.

    //print dvStgObj at (2, 15).

    return dvStgObj.
}

// Returns available deltaV on the vessel
global function ves_available_dv_next
{
    local availDv to 0.
    local dvStgObj to lex().

    // Iterate over stages until dv is covered
    from { local stg to stage:number.} until stg <= -1 step { set stg to stg - 1.} do
    {
        local dvStg to mnv_stage_dv(stg).
        //local dvStg to ship:stageDeltaV(stg):current.
        set dvStgObj[stg] to dvStg.
        set availDv to availDv + dvStg.
        print "Stage " + stg + " dV: " + dvStg.
    }

    print " ".
    print "Total available dV: " + availDv.

    //print dvStgObj at (2, 15).

    return dvStgObj.
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
    parameter engList.
    
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

// Returns the aggregate exhaust velocity for a given stage
global function ves_stage_exh_vel
{
    parameter stg.

    local stgIsp to ves_stage_isp(stg).
    return constant:g0 * stgIsp.
}

// Returns isp for a given stage
global function ves_stage_isp
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
// ToDo: Return fuel mass for a given stage
global function ves_stage_fuel_mass
{
    parameter stg.

    local stgFuelObj to lex().

    for p in ship:parts
    {
        if p:decoupledIn = stg - 1
        {
            if p:resources:length > 0
            {
                for r in p:resources
                {
                    if stgFuelObj:hasKey(r:name) 
                    {
                        set stgFuelObj[r:name] to stgFuelObj[r:name] + (r:amount * r:density).
                    }
                    else
                    {
                        set stgFuelObj[r:name] to r:amount * r:density.
                    }
                }
            }
        }
    }
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
// Open bay doors
global function ves_open_bays
{
    parameter bayList,
              door is "all".

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
    parameter bayList,
              door is "all".

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
    local procEvent     to "jettison fairing".
    local procFairing   to "ProceduralFairingDecoupler".

    local stEvent       to "deploy".
    local safFairing    to "ModuleSimpleAdjustableFairing".
    local stFairing     to "ModuleProceduralFairing".

    if ship:modulesNamed(procFairing):length > 0
    {
        for m in ship:modulesNamed(procFairing)
        {
            if m:part:tag = "" util_do_event(m, procEvent).
        }
    }
    if ship:modulesNamed(stFairing):length > 0
    {
        for m in ship:modulesNamed(stFairing)
        {
            if m:part:tag = "" util_do_event(m, stEvent).
        }
    }
    if ship:modulesNamed(safFairing):length > 0
    {
        for m in ship:modulesNamed(safFairing)
        {
            if m:part:tag = "" util_do_event(m, stEvent).
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