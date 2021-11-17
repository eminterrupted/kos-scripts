set mp to list(
    "launch/boostPhase", list(500000, 500000, 3.1, 254.4)
    ,"launch/circPhase", list()
    ,"mission/csat", list(2971011, 4037456, 3.1, 254.4, 275.5)
).
writeJson(mp, "1:/mp.json").