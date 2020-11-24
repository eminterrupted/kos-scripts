@lazyGlobal off.

parameter tgt is "Mun".

clearscreen.

runOncePath("0:/lib/lib_display").
runOncePath("0:/lib/data/nav/lib_deltav").
runOncePath("0:/lib/data/nav/lib_nav").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/data/nav/lib_node").

set target to body(tgt).

local xfrObj is lex("tgt", target, "window", get_mun_xfr_window()).
set xfrObj["burn"] to get_mun_xfr_burn_data(xfrObj["window"]["nodeAt"]).
set xfrObj["window"]["phaseAng"] to get_phase_angle().

if career():canmakenodes add_node(xfrObj["window"]["nodeAt"], xfrObj["burn"]["dv"]).

until false {
    lock steering to ship:prograde.
    set xfrObj["window"]["phaseAng"] to get_phase_angle().

    disp_obt_main().
    disp_obt_data().
    disp_tel().
    disp_eng_perf_data().
    disp_rendezvous_data(xfrObj).
}