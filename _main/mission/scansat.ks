parameter tgtPe1 is 350000,
          tgtAp1 is 350000,
          tgtInc is 84,
          tgtLan is "current".

runpath("0:/u/rrm", 0).

if (ship:periapsis < tgtPe1 * 0.975 or ship:periapsis > tgtPe1 * 1.025) or (ship:apoapsis < tgtAp1 * 0.975 or ship:apoapsis > tgtAp1 * 1.025) {
    runPath("0:/_main/adhoc/orbit_change", tgtAp1, tgtPe1).
}

if tgtLan = "current" set tgtLan to ship:orbit:longitudeofascendingnode.

if ship:orbit:inclination < tgtInc -1 or ship:orbit:inclination > tgtInc + 1 {
    runPath("0:/_main/adhoc/simple_inclination_change", tgtInc, tgtLan).
}

runpath("0:/_main/component/deploy_scansat").