set mp to list(
    "launch/boostPhase", list(250000, 250000, 0, -1)
    ,"launch/circPhase", list("deploy")
    ,"mission/simpleOrbit", list("pro-sun")
).
writeJson(mp, "1:/mp.json").