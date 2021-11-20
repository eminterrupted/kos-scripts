set mp to list(
    "launch/boostPhase", list(135000, 135000, -45, -1, 180)
    ,"launch/suborbitalHop", list("pro-body")
    ,"mission/collectSci", list("collect", false, "pro-body")
    ,"return/reentry", list(true, false, 125000, 2)
).
writeJson(mp, "1:/mp.json").