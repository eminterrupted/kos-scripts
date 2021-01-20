@lazyGlobal off.

parameter tgtAlt0,
          tgtAlt1,
          flipPhase is false,
          runmodeReset is false.

clearscreen.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_warp").
runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_deltav").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_mnv").

set stateObj to init_state_obj("ADHOC").
local runmode to stateObj:runmode.
if runmode = 99 set runmode to 0.
if runmodeReset set runmode to 0.

disp_main().

local sVal is lookDirUp(ship:facing:forevector, sun:position).
lock steering to sVal.

local tVal is 0.
lock throttle to tVal.

// Staging trigger
when ship:availableThrust < 0.1 and tVal > 0 then {
    safe_stage().
    preserve.
}


// Main
local nodeAt to 0.

// Executes the intial hohmann burn node 
// at the desired point
set nodeAt to choose "ap" if flipPhase else "pe".
exec_circ_burn(nodeAt, tgtAlt0).

// Executes the second hohman burn.
set nodeAt to choose "pe" if flipPhase else "ap".
exec_circ_burn(nodeAt, tgtAlt1).

// Preps the vessel for long-term orbit
unlock steering.
unlock throttle.
logStr("Orbital change completed").
