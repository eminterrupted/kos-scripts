wait until ship:unpacked.

if addons:rt:haskscconnection(ship)
{
    copyPath("0:/main/mission/station_orbit", "1:/station_orbit.ks").
}

runPath("1:/station_orbit.ks").