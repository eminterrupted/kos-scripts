set mp to list(
    "launch/boostPhase", list(700000, 700000, 84, -1)
    ,"launch/circPhase", list("deploy")
    ,"mission/collectSci", list("ideal")
).
writeJson(mp, "1:/mp.json").