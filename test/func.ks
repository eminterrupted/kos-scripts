@lazyGlobal off.
clearScreen.

parameter p.

runOncePath("0:/lib/lib_vessel").

lock ecPct to ship:resources[0]:amount / ship:resources[0]:capacity.

until false {
    ves_auto_activate_fuel_cell(p).
    
    if p:getModule("ModuleResourceConverter"):getField("fuel cell") = "Inactive" print "Fuel Cell Off" at (2, 5).
    else print "Fuel Cell On " at (2, 5).
    print "Ship EC: " + round(ship:electricCharge, 2) + "    " at(2, 6).
    print "Ship EC%: " + round(ecPct, 2) + "       " at(2, 7).
    print "Ship Light Sensor Reading: " + round(ship:sensors:light, 2) + "   " at (2, 8).
}