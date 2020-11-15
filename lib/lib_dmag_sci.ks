//Library for science
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_sci.ks").

local sciMod is "DMModuleScienceAnimate".

//Gets all science modules on the vessel
global function get_dmag_mod {
    return ship:modulesNamed(sciMod).
}


//Takes a list of parts, and returns all science modules
global function get_dmag_mod_for_list {
    parameter pList.

    local retlist is list().
    for p in pList {
        if p:hasModule(sciMod) {
            retList:add(p:getModule(sciMod)).
        }
    }

    return retList.
}


global function log_dmag_sci {
    parameter m.

    if not m:inoperable {
        if not m:deployed {
            m:toggle(). 
            wait until m:deployed.
            m:deploy().
            wait until m:hasdata.
        }
        addons:career:closedialogs().
    }

    return m:data.
}


global function reset_dmag_sci {
    parameter m.

    if m:hasdata m:reset().
    if m:deployed {
        m:toggle().
    }
}