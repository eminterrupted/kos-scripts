set mp to list(
    "launch/boostPhase", list(150000, 150000, 0, -1, 180)
    ,"launch/suborbitalHop", list(180)
    ,"mission/collectSci", list("collect", false, "pro-body")
    ,"return/reentry", list(true, false, 125000, 2)
).
writeJson(mp, "1:/mp.json").