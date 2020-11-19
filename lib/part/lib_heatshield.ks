@lazyGlobal off.

global function jettison_heatshield {
    parameter p.

    local m is "ModuleDecouple".
    if p:hasModule(m) {
        set m to p:getModule(m).
        m:doEvent("jettison heat shield").
        return true.
    }
    else return false.
}