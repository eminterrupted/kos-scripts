set mp to list(
    "launch/boostPhase", list(350000, 350000, 22.5, -1, 180)
    ,"launch/circPhase", list("")
    ,"mission/collectSci", list("collect", false, "pro-body")
    ,"mission/simpleOrbit", list(252000, "pro-body")
    ,"return/reentry", list(true, false)
).
writeJson(mp, "1:/mp.json").