set mp to list(
    "launch/boostPhase", list(250000, 250000, 0, -1, 0)
    ,"launch/circPhase", list()
    ,"mission/simpleOrbit", list()
).
writeJson(mp, "1:/mp.json").