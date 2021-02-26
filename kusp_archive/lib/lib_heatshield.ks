@lazyGlobal off.

global function jettison_heatshield 
{
    parameter hs.

    local m is "ModuleDecouple".
    if hs:hasModule(m) 
    {
        return do_event(hs:getModule(m), "jettison heat shield").
    }
    else return false.
}