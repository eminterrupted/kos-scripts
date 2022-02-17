// Science library

// Functions 
// Modules
global function GetSciModules
{
    local sciList to list().
    for m in ship:modulesNamed("ModuleScienceExperiment")           sciList:add(m).
    for m in ship:modulesNamed("DMModuleScienceAnimate")            sciList:add(m).
    for m in ship:modulesNamed("DMRoverGooMat")                     sciList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageScience")         sciList:add(m).
    for m in ship:modulesNamed("USSimpleScience")                   sciList:add(m).
    for m in ship:modulesNamed("USAdvancedScience")                 sciList:add(m).
    for m in ship:modulesNamed("DMXrayDiffract")                    sciList:add(m).
    return sciList.
}

// Deploy
global function DeploySciList
{
    parameter sciList.

    for m in sciList
    {
        if m:name:startsWith("US")
        {
            DeployUSSci(m).
        }
        else
        {
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
                    TransmitSci(m).
                }
                else if mode = "ideal"
                {
                    if m:data[0]:transmitValue > 0 and m:data[0]:transmitValue = m:data[0]:scienceValue
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
                        TransmitSci(m).
                    }
                    else if m:data[0]:scienceValue > 0
                    {
                        CollectSci().
                        if m:hasEvent("transfer data") ResetSci(m).
                    }
                    else 
                    {
                        ResetSci(m).
                    }
                }
                else if mode = "collect"
                {
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
    }
}


// Reset
local function ResetSci
{
    parameter m.
    
    if m:name <> "TSTChemCam" 
    {
        m:reset().
        wait until not m:hasData.
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

// Transmit
local function TransmitSci
{
    parameter m.

    m:transmit().
    wait until not m:hasData.
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