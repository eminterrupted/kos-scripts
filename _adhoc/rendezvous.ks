@lazyGlobal off.

parameter other. // The target 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_core").
runOncePath("0:/lib/display/lib_display").
runOncePath("0:/lib/lib_sci").
runOncePath("0:/lib/lib_warp").

runOncePath("0:/lib/nav/lib_calc_mnv").
runOncePath("0:/lib/nav/lib_mnv").
runOncePath("0:/lib/nav/lib_nav").
runOncePath("0:/lib/nav/lib_node").
runOncePath("0:/lib/nav/lib_rendezvous").

runOncePath("0:/lib/lib_mass_data").
runOncePath("0:/lib/lib_engine_data").


clearScreen.

local sVal to lookDirUp(ship:prograde:vector, sun:position).
lock steering to sVal.

local tVal to 0.
lock throttle to tVal.

update_display().

local intersect_ta to orbit_cross_ta(ship:obt, other:obt, 10, 0.01).

// If the orbits do not yet intersect
if intersect_ta < 0 {
    print "MSG: No intersect point in orbits yet         " at (2, 45).

    wait 1.

    until eta:periapsis < 10 * warp^2 {
        update_display().
    }

    set warp to 0.

    if ship:obt:semiMajorAxis < other:obt:semiMajorAxis {
        set sVal to lookDirUp(ship:prograde:vector, sun:position).
        print "MSG: Will enlarge orbit at periapsis      " at (2, 45).
    } else {
        set sVal to lookDirUp(ship:retrograde:vector, sun:position).
        print "MSG: Will reduce orbit at periapsis       " at (2, 45).
    }

    wait until ship:obt:trueanomaly >= 0 and ship:obt:trueanomaly < 90.

    print "MSG: Burning until exists crossing point      " at (2, 45).
    set tVal to 1.
    until intersect_ta >= 0 {
        update_display().
        // Use larger check for fast approximation
        set intersect_ta to orbit_cross_ta(ship:obt, other:obt, 10, 2).
    }

    //Now use the more precise check once we know it will work
    set intersect_ta to orbit_cross_ta(ship:obt, other:obt, 10, 0.01).
}

local intersect_eta to eta_to_ta(ship:obt, intersect_ta).
local intersect_first_utime to time:seconds + intersect_eta.

local ta_offset_from_other to ta_offset(ship:obt, other:obt).
local other_intersect_ta to intersect_ta - ta_offset_from_other. 
local other_intersect_eta to eta_to_ta(other:obt, other_intersect_ta).

print "MSG: intersect_ta : " + round(intersect_ta, 1) + " deg     " at (2, 48).
print "MSG:     other_ta : " + round(other_intersect_ta, 1) + " deg     " at (2, 49).
print "MSG: intersect_eta: " + round(intersect_eta, 1) + " s     " at (2, 51).
print "MSG:     other_eta: " + round(other_intersect_eta, 1) + " s     " at (2, 52).

//Obtain a list of the next 5 utimes the target will cross the intersect point
local rendezvous_utimes to list().
from { local i to 0.} until i = 4 step { set i to i + 1.} do {
    rendezvous_utimes:add(time:seconds + other_intersect_eta + other:obt:period * i).
}

print "MSG: Waiting until intersect point                " at (2, 45).
local wait_left to intersect_first_utime - time:seconds.
until wait_left <= 0 {
    set wait_left to intersect_first_utime - time:seconds.
    print "Time remaining: " + round(wait_left) + "s     " at (2, 46).
    if wait_left < 20 {
        set warp to 0.
    }

    set sVal to lookDirUp(ship:prograde:vector, sun:position). 

    update_display().
}

local clr to "                                                           ".

print "MSG: Enlarging orbit until matching a rendezvous time       " at (2, 45).
print clr at (2, 46).
print clr at (2, 47).
print clr at (2, 48).
print clr at (2, 49).
print clr at (2, 50).
print clr at (2, 51).
print clr at (2, 52).

local rendezvous_tolerance_1 to 50. // seconds
local rendezvous_tolerance_2 to 5. // seconds
local rendezvous_tolerance_3 to 1. // seconds
local found to false.
local my_rendezvous_utime to 0. // will calc later in loop
local num_orbits to 0. // How many orbits until a hit
local burn_start_time to time:seconds.
set tVal to 1.
until found {
    wait 0.1.
    local i to 0.
    until found or i = 4 {
        set my_rendezvous_utime to burn_start_time + ship:obt:period + i.
        print "[" + i + "]. mine = " + round(my_rendezvous_utime, 1) + "s     " at (2, 47 + i).
        local j is 0.
        until found or j = 4 {
            local other_rendezvous_utime to rendezvous_utimes[j].
            local time_diff to my_rendezvous_utime - other_rendezvous_utime.
            print "other = " + round(other_rendezvous_utime, 1) + "s     " at (25, 47 + j).
            if abs(time_diff) < rendezvous_tolerance_1 {
                set tVal to 0.1.
            }
            if abs(time_diff) < rendezvous_tolerance_2 {
                set tVal to 0.01.
            }
            if abs(time_diff) < rendezvous_tolerance_3 {
                set tVal to 0.
                set found to true.
                set num_orbits to i.
            }

            set j to j + 1.
        }

        set i to i + 1.
    }
}
