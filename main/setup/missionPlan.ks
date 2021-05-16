@lazyGlobal off.

// Launch params
local launchAp     to 2500000.
local launchPe     to 150000.
local launchInc    to 45.
local launchRoll   to choose 180 if ship:crewcapacity > 0 else 0.

// Mission plan
// Lex format - scr: script, prm: paramList (optional)
local missionPlan  to list(
    // Mission scripts (all missions in order)
        lex("scr", "mission/simple_orbit"),
        //lex("scr", "mission/auto_sci_biome"),
        //lex("scr", "maneuver/transfer_to_mun",        "prm", list()),
        //lex("scr", "maneuver/wait_for_soi_change"),
        //lex("scr", "maneuver/capture_burn"),           "prm", list()),
        //lex("scr", "maneuver/change_inclination",     "prm", list()),
        //lex("scr", "maneuver/change_orbit",           "prm", list()),
        //lex("scr", "mission/orbital_science"),
        //lex("scr", "return/return_from_mun",          "prm", list()),
        //lex("scr", "mission/sun_science",             "prm", list()),
        //lex("scr", "mission/relay_orbit"),
        //lex("scr", "mission/scansat"),
        //lex("scr", "mission/suborbital_hop",          "prm", list()),
    
    // Return scripts
        lex("scr", "return/no_return")
        //lex("scr", "return/ksc_reentry")
).

local launchParam to list(
    launchPe,
    launchAp,
    launchInc,
    launchRoll
).

local missionCache to lex(
    "missionPlan", missionPlan,
    "launchParam", launchParam
).

writeJson(missionCache, "0:/data/cache/missionPlan.json").