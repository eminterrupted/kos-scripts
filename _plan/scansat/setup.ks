set mp to list(
    "launch/boostPhase", list(2250000, 2250000, 88, -1, 0)
    ,"launch/circPhase", list("deploy")
    ,"mission/scansat", list("pro-body")
).
writeJson(mp, "1:/mp.json").