set mp to list(
    "launch/boostPhase", list(175000, 175000, 45, -1, 0)
    ,"launch/circPhase", list("deploy")
).
writeJson(mp, "1:/mp.json").