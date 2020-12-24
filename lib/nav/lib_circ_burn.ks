@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_calc_mnv").

global function do_circ_burn {
    parameter circObj.

    print "MSG: Executing setup_circ_burn()             " at (2, 7).
    local burnObj to setup_circ_burn(circObj).

    set circObj["burnNode"] to burnObj["burnNode"].
    set circObj["burnObj"] to burnObj["burnObj"].

    print "MSG: Executing warp_to_circ_burn()           " at (2, 7).
    warp_to_circ_burn(circObj).
    
    print "MSG: Executing exec_circ_burn()              " at (2, 7).
    exec_circ_burn(circObj).
}


local function setup_circ_burn {
    parameter cObj.
    
    set_rm(18).
    logStr("Setting up circularization burn object").
    
    local sVal to lookdirup(ship:prograde:vector, sun:position).
    lock steering to sVal.

    local tVal to 0. 
    lock throttle to tVal.

    //Add the circ node
    local burnNode to add_simple_circ_node("ap", cObj["tPe"]).
    local burnObj to get_burn_obj_from_node(burnNode).

    logStr("Burn object created").

    return lex("burnNode", burnNode, "burnObj", burnObj).
}


local function warp_to_circ_burn {
    parameter cObj.
    
    local burnEta is cObj["burnObj"]:burnEta.

    set_rm(22).
    lock steering to choose lookdirup(nextnode:burnvector, sun:position) if hasNode else lookdirup(ship:prograde:vector, sun:position).
    warp_to_timestamp(burnEta).
}


local function exec_circ_burn {
    parameter cObj.
    
    set_rm(24).

    logStr("Executing circularization burn").

    until time:seconds >= cObj["burnObj"]:burnEta {
        update_display().
    }

    exec_node(cObj["burnNode"]).

    disp_clear_block("burn_data").

    local tVal to 0.
    lock throttle to tVal.
}