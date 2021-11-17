set mp to list(
    "/launch/boostPhase", list(1250000, 1250000, 86, 0)
    ,"/launch/circPhase", list()
    ,"/mission/scansat", list("radIn")
).
writeJson(mp, "1:/mp.json").