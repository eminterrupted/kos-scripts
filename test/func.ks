@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_land").

until false
{
    print round(land_time_to_impact(ship:verticalspeed, alt:radar), 3) at (2, 10).
    wait 0.
}