set mp to list(
    "launch/boostPhase", list(350000, 350000, 22.5, -1, 180)
    ,"launch/circPhase", list("deploy")
    ,"mission/collectSci", list("collect", true, "pro-body")
    ,"mission/simpleOrbit", list(7200, "pro-body")
    ,"return/reentry", list(true, false)
).
writeJson(mp, "1:/mp.json").