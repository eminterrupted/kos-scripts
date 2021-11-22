set mp to list(
    "launch/boostPhase", list(525000, 525000, target:orbit:inclination, target:orbit:lan, 180)
    ,"launch/circPhase", list("")
).
writeJson(mp, "1:/mp.json").