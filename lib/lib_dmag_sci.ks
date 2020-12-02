//Library for science
@lazyGlobal off.

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_sci.ks").

local dmagMod is "DMModuleScienceAnimate".

//Deploy without running the experiment - useful for experiments that can't run until deployed
// global function deploy_dmag_list {
//     parameter mList.

//     for m in mList {
//         deploy_dmag_sci_mod(m).
//     }
// }


// global function deploy_dmag_sci_mod {
//     parameter m.
    
//     if m:part:hasModule(dmagMod) {
//         for a in m:allActions {
//             if a:contains("deploy") m:doAction(a:replace("(callable) ",""):replace(", is KSPAction",""), true).
//         }
//     }
// }


//Gets all science modules on the vessel
global function get_dmag_mod {
    return ship:modulesNamed(dmagMod).
}


//Takes a list of parts, and returns all science modules
global function get_dmag_mod_for_list {
    parameter pList.

    local retlist is list().
    for p in pList {
        if p:hasModule(dmagMod) {
            retList:add(p:getModule(dmagMod)).
        }
    }

    return retList.
}


global function log_dmag_sci {
    parameter m.
    
    m:deploy().
    local tstamp to time:seconds + 5. 
    wait until m:hasdata or time:seconds > tstamp.
    addons:career:closedialogs().
}


global function log_dmag_list {
    parameter mlist.
    for m in mlist {
        log_dmag_sci(m).
    }
}


global function reset_dmag_sci {
    parameter m.

    if m:hasdata m:reset().
    if m:deployed {
        m:toggle().
    }
}