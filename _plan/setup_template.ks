// Sample setup file
// Copy / paste into new file named 'setup.ks' under folder matching vessel tag
// If folder matching desired vessel tag does not exist, create one
// Change scripts as needed to execute the mission
set mp to list(
    "launch/boostPhase", list(250000, 250000, 0, -1, 0)
    ,"launch/circPhase", list("noDeploy")
    ,"mission/simpleOrbit", list(0, "pro-sun")
).
writeJson(mp, "1:/mp.json").