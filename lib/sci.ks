// Science library

// Functions 
// Modules
global function GetSciModules
{
    local sciList to list().
    for m in ship:modulesNamed("ModuleScienceExperiment")           sciList:add(m).
    for m in ship:modulesNamed("DMModuleScienceAnimate")            sciList:add(m).
    for m in ship:modulesNamed("DMRoverGooMat")                     sciList:add(m).
    for m in ship:modulesNamed("DMSoilMoisture")                    sciList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageScience")         sciList:add(m).
    for m in ship:modulesNamed("USSimpleScience")                   sciList:add(m).
    for m in ship:modulesNamed("USAdvancedScience")                 sciList:add(m).
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
                    TransmitSci(m).
                }
                else if mode = "ideal"
                {
                    if m:data[0]:transmitValue > 0 and m:data[0]:transmitValue = m:data[0]:scienceValue
                    {
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
        local ts to time:seconds + 10.
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