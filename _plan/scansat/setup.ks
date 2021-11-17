set mp to list(
    "launch/boostPhase", list(3000000, 3000000, 86, -1)
    ,"launch/circPhase", list("deploy")
    ,"mission/scansat", list("pro-body")
).
writeJson(mp, "1:/mp.json").