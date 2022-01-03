// Sample setup file
// Copy / paste into new file named 'setup.ks' under folder matching vessel tag
// If folder matching desired vessel tag does not exist, create one
// Change scripts as needed to execute the mission
set mp to list(
    "util/idElements", list(1)
    ,"launch/boostPhase", list(150000, 150000, 17.0, -1, 0)
    ,"launch/circPhase", list()
    //deploy everything but don't stage b/c we need to burn again later
    ,"util/payloadDeploy", list(false)
    ,"mission/collectSci", list("transmit", false, "pro-sun")
    //DEC 19, YEAR OF OUR LORD TWENTY TWENTY ONE: BATTLE!!! 🔪🗡️ WILL AP BE 
    //MORE THAN 250KM GIVEN JUST A PE OF 150 AND ECC OF .20???????
    //EMILY SAYS: YES!! NO QUESTION ABOUT IT. ITS OBVIOUS.
    //LELANDO SAYS: NOT A CHANCE. I GREW UP IN A HIGH ORBIT AND THIS WILL NOT GET US THERE.
    //STAY TUNED TO FIND OUT
    //IT IS A SAD DAY TODAY. EMILY WAS RIGHT. I AM LELANDS EMO DESPAIR. 😭
    ,"maneuver/changeEccentricity", list("pe", 150000, .2794312962143)
    ,"mission/collectSci", list("transmit", false, "pro-sun")
    ,"mission/simpleOrbit", list(0, "pro-sun")
).
writeJson(mp, "1:/mp.json").