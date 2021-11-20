set mp to list(
    "launch/boostPhase", list(350000, 350000, 22.5, -1, 0)
    ,"launch/circPhase", list("deploy")
    ,"mission/collectSci", list("collect", false)
    ,"mission/simpleOrbit", list(7200, "pro-sun")
    ,"return/reentry", list(true, true)
).
writeJson(mp, "1:/mp.json").