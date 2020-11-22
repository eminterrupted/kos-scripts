@lazyGlobal off.

global function jettison_heatshield {
    parameter hs.

    local m is "ModuleDecouple".
    if hs:hasModule(m) {
        set m to hs:getModule(m).
        m:doEvent("jettison heat shield").
        return true.
    }
    else return false.
}