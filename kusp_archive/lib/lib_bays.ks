@lazyGlobal off.

runOncePath("0:/lib/lib_util").

local usMod to "USAnimateGeneric".

// Opens doors for a provided part. 
// Inputs are a part, and an optional param to define 
// which door to open: 0: both, 1: primary, 2: secondary
global function deploy_bay_doors 
{
    parameter p,
              mode is 0.

    if p:hasModule(usMod) 
    {
        local m to p:getModule(usMod).
        if mode = 0
        {
            do_event(m, "deploy primary bays").
            do_event(m, "deploy secondary bays").
        }
        else if mode = 1
        {
            do_event(m, "deploy primary bays").
        }
        else if mode = 2
        {
            do_event(m, "deploy secondary bays").
        }
        wait 5. // wait for bay door to open
    }
}

// Closes doors for a part
// Inputs are a part, and an optional param to define 
// which door to open: 0: both, 1: primary, 2: secondary
global function close_bay_doors 
{
    parameter p,
              mode is 0.

    if p:hasModule(usMod) 
    {
        local m to p:getModule(usMod).
        if mode = 0
        {
            do_event(m, "retract primary bays").
            do_event(m, "retract secondary bays").
        }
        else if mode = 1
        {
            do_event(m, "retract primary bays").
        }
        else if mode = 2
        {
            do_event(m, "retract secondary bays").
        }
        wait 5. // wait for bay door to open
    }
}