@lazyGlobal off.


// Functions
global function sci_deploy
{
    parameter m.

    if not m:hasData
    {
        m:deploy().
        wait until m:hasData.
    }
    else if m:data[0]:scienceValue = 0
    {
        m:reset().
    }
}

global function sci_deploy_list
{
    parameter sciList.

    for m in sciList
    {
        sci_deploy(m).
    }
}

global function sci_modules
{
    local sciList to list().
    for m in ship:modulesNamed("ModuleScienceExperiment")
    {
        sciList:add(m).
    }
    for m in ship:modulesNamed("DMModuleScienceAnimate")
    {
        sciList:add(m).
    }
    return sciList.
}

global function sci_recover
{
    parameter m.

    if m:hasData
    {
        if m:data[0]:transmitValue > 0
        {
            m:transmit().
        }
        else
        {
            m:reset().
        }
        wait until not m:hasData.
    }
}

global function sci_recover_list
{
    parameter sciList.

    for m in sciList
    {
        sci_recover(m).
    }
}

global function sci_stow_experiments
{
    local sciBoxList to ship:modulesNamed("ModuleScienceContainer").
    local sciBox to 0.

    if sciBoxList:length > 0
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