set mp to list(
    "launch/boostPhase", list(1000000, 1000000, 22.5, -1, 0)
    ,"launch/circPhase", list("deploy")
    ,"mission/collectSci", list("collect", false)
    ,"mission/simpleOrbit", list(252000, "pro-sun")
    ,"return/reentry", list(true, true)
).
writeJson(mp, "1:/mp.json").