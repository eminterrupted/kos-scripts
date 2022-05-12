@lazyGlobal off. 

// Science library

// Dependencies
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").


// Functions 
// Modules
global function GetSciModules
{
    local sciList to list().
    for m in ship:modulesNamed("ModuleScienceExperiment")           sciList:add(m).
    for m in ship:modulesNamed("DMModuleScienceAnimate")            sciList:add(m).
    for m in ship:modulesNamed("DMRoverGooMat")                     sciList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageScience")         sciList:add(m).
    for m in ship:modulesNamed("DMSeismicSensor")                   sciList:add(m).
    for m in ship:modulesNamed("DMSeismicHammer")                   sciList:add(m).
    for m in ship:modulesNamed("DMSoilMoisture")                    sciList:add(m).
    for m in ship:modulesNamed("USSimpleScience")                   sciList:add(m).
    for m in ship:modulesNamed("USAdvancedScience")                 sciList:add(m).
    for m in ship:modulesNamed("DMXrayDiffract")                    sciList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageSoilMoisture")    sciList:add(m).
    for m in ship:modulesNamed("ModuleSpyExperiment")               sciList:add(m).
    return sciList.
}

// Deploy
global function DeploySciList
{
    parameter sciList.

    for m in sciList
    {
        OutInfo().
        OutInfo2().
        if m:name:startsWith("US")
        {
            OutTee("Running US science experiment for: " + m:part:title + " (" + m:name + ")").
            DeployUSSci(m).
        }
        else if m:name:startsWith("DM")
        {
            OutTee("Running DM science experiment for: " + m:part:title + " (" + m:name + ")").
            DeployDMSci(m).
        }
        else if m:name = "ModuleSpyExperiment"
        {
            OutTee("Running Spy Experiment for: " + m:part:title + " (" + m:name + ")").
            DeploySpySci(m).
        }
        else
        {
            OutTee("Running generic science experiment for: " + m:part:title + " (" + m:name + ")").
            DeploySci(m).
        }
    }
}

// Recover
global function RecoverSciList
{
    parameter sciList,
              mode is "ideal".

    for m in sciList
    {
        if m:hasSuffix("HASDATA")
        {
            if m:hasData
            {
                if mode = "transmit"
                {
                    local transmitFlag to false.
                    until transmitFlag
                    {
                        local ecValidation to ValidateECForTransmit(m).
                        if ecValidation[0] = 0
                        {
                            OutMsg("Validating EC for science transmission").
                            OutInfo("EC Required: " + ecValidation[1]).
                            set transmitFlag to true.
                        }
                    }
                    OutTee("Transmitting data from " + m:part:title + " (" + m:name + ")").
                    if TransmitSci(m) 
                    {
                        OutTee("Transmission successful!").
                    }
                    else 
                    {
                        OutTee("Transmission failed!", 0, 2).
                    }
                }
                else if mode = "ideal"
                {
                    if m:data[0]:transmitValue > 0 and m:data[0]:transmitValue = m:data[0]:scienceValue
                    {
                        // local transmitFlag to false.
                        // until transmitFlag
                        // {
                        //     local ecValidation to ValidateECForTransmit(m).
                        //     if ecValidation[0] = 0
                        //     {
                        //         OutMsg("Validating EC for science transmission").
                        //         OutInfo("EC Required: " + ecValidation[1]).
                        //         set transmitFlag to true.
                        //     }
                        // }
                        OutTee("Transmitting data from " + m:part:title + " (" + m:name + ")").
                        if TransmitSci(m)
                        {
                            OutTee("Transmission successful!").
                        }
                        else 
                        {
                            OutTee("Transmission failed!", 0, 2).
                        }
                    }
                    else if m:data[0]:scienceValue > 0
                    {
                        CollectSci().
                        if m:hasEvent("transfer data") 
                        {
                            OutTee("Resetting science module: " + m:name + " (Part: " + m:part:title + ")").
                            ResetSci(m).
                        }
                    }
                    else 
                    {
                        OutTee("Resetting science module: " + m:name + " (Part: " + m:part:title + ")").
                        ResetSci(m).
                    }
                }
                else if mode = "collect"
                {
                    OutTee("Collecting experiment results from module: " + m:name + " (Part: " + m:part:title + ")").
                    CollectSci().
                }
            }
        }
    }
}

// Delete data
global function ClearSciList
{
    parameter sciList. 

    for m in sciList
    {
        m:reset().
        local ts to time:seconds + 5.
        wait until not m:HasData or time:seconds > ts.
    }
}

// Local functions

// Collect
local function CollectSci
{
    local sciBoxList to ship:modulesNamed("ModuleScienceContainer").
    local sciBox to 0.
    local sciBoxPresent to choose true if sciBoxList:length > 0 else false.
    
    if sciBoxPresent
    {
        for m in sciBoxList
        {
            set sciBox to m.
            if sciBox:part = ship:rootPart 
            {
                break.
            }
        }
    }

    if sciBoxPresent
    {
        sciBox:doAction("collect all", true).
        if sciBox:hasEvent("container: transfer data") 
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


// Deploy
local function DeploySci
{
    parameter m.

    if not m:hasData
    {
        if m:HasSuffix("deploy") m:deploy().
        else 
        {
            DoEvent("start laser altimeter measurements").
        }
        local ts to time:seconds + 5.
        wait until m:hasData or time:seconds >= ts.
        if addons:career:available addons:career:closeDialogs.
    }
}

local function DeployDMSci
{
    parameter m.

    if m:HasData
    {
        return false.
    }
    else
    {
        if m:name = "DMSeismicSensor"
        {
            DoAction(m, "Arm Pod").
            if m:Part:HasModule("ModuleAnchoredDecoupler")
            {
                DoEvent(m:Part:GetModule("ModuleAnchoredDecoupler"), "decouple").
            }
        }
        else if m:name = "DMSeismicHammer"
        {
            m:toggle.
            wait 4.
            DoAction(m, "Arm Hammer").
            wait 1.
            DoAction(m, "Collect Seismic Data").
            wait until m:hasData.
        }
        else
        {
            m:deploy.
            local ts to time:seconds + 10.
            until m:hasData
            {
                if time:seconds > ts
                {
                    OutInfo2("WARN: Science Experiment timeout").
                    break.
                }
                else if m:hasData 
                {
                    OutInfo2("Data collected!").
                }
            }
        }
        if addons:career:available addons:career:closeDialogs.
    }
}

local function DeploySpySci
{
    parameter m.

    DoAction(m, "scan target").
    wait 0.1. 
    if addons:available("Career") addons:career:closeDialogs().
}

local function DeployUSSci
{
    parameter m.

    local deployList  to list("log", "observe", "conduct", "open service door", "take a picture").

    for action in m:allActions
    {
        for validAction in deployList
        {
            local trimmedAction to action:replace("(callable) ", ""):replace(", is KSPAction", "").
            if trimmedAction:contains(validAction) 
            {
                m:doAction(trimmedAction, true).
                local ts to time:seconds + 5.
                wait until m:hasData or time:seconds >= ts .
                if addons:career:available addons:career:closeDialogs.
            }

            if trimmedAction = "deploy service door"
            {
                wait 2.
            }
        }
        wait 0.05. 
        if addons:available("Career") addons:career:closeDialogs().
    }
}


// Reset
local function ResetSci
{
    parameter m.
    
    if m:name <> "TSTChemCam" 
    {
        m:reset().
        local ts to time:seconds + 5.
        wait until time:seconds > ts or not m:hasData.
    }
    RetractSci(m).
}

local function RetractSci
{
    parameter m.

    local retractList to list("close", "retract", "stow").

    for action in m:allActions
    {
        for validAction in retractList
        {
            if action:contains(validAction)
            {
                m:doAction(action:replace("(callable) ", ""):replace(", is KSPAction",""), true).
            }
        }
    }
}

// TO-DO 
// Transfer science from a given module to a target container. 
// Defaults to first container in list
// local function TransferSci
// {
//     parameter m,
//               sciBox is ship:modulesNamed("ModuleScienceContainer")[0].

    
// }

// Transmit
local function TransmitSci
{
    parameter m.

    if m:hasData
    {
        m:transmit().
        wait until not m:hasData.
        wait 0.01.
        return true.
    }
    else
    {
        return false.
    }
}

local function ValidateECForTransmit
{
    parameter sciMod.

    local maxPacketCost to 0.
    local maxPacketInt  to 0.
    local maxPacketSize to 0.
    local numUploads    to 0.
    local uploadCost    to 0.
    local uploadTime    to 0.

    local sciMits to sciMod:Data[0]:DataAmount.

    if Ship:ModulesNamed("ModuleRTAntenna"):Length > 0
    {
        for m in ship:ModulesNamed("ModuleRTAntenna")
        {
            if m:GetField("status") = "Connected" 
            {
                set maxPacketCost to max(m:GetField("science packet cost"):toNumber(10), maxPacketCost).
                set maxPacketInt  to max(m:GetField("science packet interval"):toNumber(0.3), maxPacketInt).
                set maxPacketSize to max(m:GetField("science packet size"):toNumber(1), maxPacketSize).
            }
        }

        set numUploads   to sciMits / maxPacketSize.
        set uploadCost   to numUploads * maxPacketCost.
        set uploadTime   to numUploads * maxPacketInt.

        print "Part Module      : " + sciMod:part:name + "         " at (0, 25).
        print "Data Qty (Mits)  : " + sciMits     + "    " at (0, 26).
        print "Packet Cost      : " + maxPacketCost + "   " at (0, 27).
        print "Packet Interval  : " + maxPacketInt  + "   " at (0, 28).
        print "Upload Count     : " + round(numUploads) + "   " at (0, 29).
        print "Upload Cost      : " + round(uploadCost, 1) + "     " at (0, 30).
        print "Upload Time      : " + round(uploadTime, 1) + "     " at (0, 31).

        if uploadCost < Ship:ElectricCharge + 20
        {
            print "EC validation cleared               " at (0, 33).
            return list(0, uploadCost, uploadTime).
        }
        else
        {
            print "EC validation failed                " at (0, 33).
            return list(1, uploadCost, uploadTime).
        }
    }
    print "EC validation: No antennas detected!" at (0, 33).
    return list(2, 0, 0).
}