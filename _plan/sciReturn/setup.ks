set mp to list(
    "launch/boostPhase", list(325000, 325000, 0, -1)
    ,"launch/circPhase", list("deploy")
    ,"mission/collectSci", list("collect", false)
    ,"mission/simpleOrbit", list(252000, "pro-sun")
    ,"return/reentry", list(true, true)
).
writeJson(mp, "1:/mp.json").