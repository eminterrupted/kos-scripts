set mp to list(
    "launch/boostPhase", list(1250000, 1250000, 45, -1, 0)
    ,"launch/circPhase", list("deploy")
    ,"mission/collectSci", list("ideal", "pro-body")
).
writeJson(mp, "1:/mp.json").