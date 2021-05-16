@lazyGlobal off.

//-- Dependencies
runOncePath("0:/lib/lib_util").

//-- Functions

// Takes a list and deploys each
global function sci_deploy_list
{
    parameter sciList.

    for m in sciList
    {
        if m:name:startsWith("US")
        {
            sci_deploy_us(m).
        }
        else
        {
            sci_deploy(m).
        }
    }
}

// Returns all science modules on the vessel
global function sci_modules
{
    local sciList to list().
    for m in ship:modulesNamed("ModuleScienceExperiment")   sciList:add(m).
    for m in ship:modulesNamed("DMModuleScienceAnimate")    sciList:add(m).
    for m in ship:modulesNamed("USSimpleScience")           sciList:add(m).
    for m in ship:modulesNamed("USAdvancedScience")         sciList:add(m).
    return sciList.
}

// Takes a list of modules and runs recovers each based on desired mode
global function sci_recover_list
{
    parameter sciList,
              mode is "ideal".

    for m in sciList
    {
        if m:hasData
        {
            if mode = "transmit"
            {
                sci_transmit(m).
            }
            else if mode = "ideal"
            {
                if m:data[0]:transmitValue > 0 and m:data[0]:transmitValue = m:data[0]:scienceValue
                {
                    sci_transmit(m).
                }
                else if m:data[0]:scienceValue > 0
                {
                    sci_collect_experiments().
                }
                else 
                {
                    sci_reset(m).
                }
            }
            else if mode = "collect"
            {
                sci_collect_experiments().
            }
        }
    }
}

//-- Local functions --//

// Collects experiments in a science container
local function sci_collect_experiments
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

// Deploy stock or DMagic experiments
local function sci_deploy
{
    parameter m.

    if not m:hasData
    {
        m:deploy().
        wait until m:hasData.
        if addons:career:available addons:career:closeDialogs.
    }
}

// Deploy USScience experiments
local function sci_deploy_us
{
    parameter m.

    local deployList  to list("log", "observe", "conduct").

    for action in m:allActions
    {
        for validAction in deployList
        {
            if action:contains(validAction) 
            {
                m:doAction(action:replace("(callable) ", ""):replace(", is KSPAction", ""), true).
                wait until m:hasData.
                if addons:career:available addons:career:closeDialogs.
            }
        }
    }
}

// Function for resetting an experiment
local function sci_reset
{
    parameter m.
    
    m:reset().
    wait until not m:hasData.
    sci_retract(m).
}

// Retract the experiment if possible
local function sci_retract
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

// Function for transmitting data
local function sci_transmit
{
    parameter m.

    m:transmit().
    wait until not m:hasData.
}
