@lazyGlobal off.
clearScreen.

parameter ascentAlt is 40000, 
          ascentInc is 0,
          stageOnAscent is false.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_launch").
runOncePath("0:/lib/lib_vessel").
runOncePath("0:/kslib/lib_l_az_calc").

// Variables
local dataDisk to choose "1:/" if not (defined dataDisk) else dataDisk.
local launchPlanCache to dataDisk + "launchPlan.json".
local engList to list().

list engines in engList.
for e in engList 
{
    if e:stage = stage:number e:activate.
}

local groundComms to list().
for m in ship:modulesNamed("ModuleRTAntenna")
{
    if m:part:tag:contains("groundAntenna")
    {
        groundComms:add(m).
    }
}

ves_activate_solar(ship:modulesNamed("ModuleDeployableSolarPanel"), false).
ves_activate_antenna(groundComms, false).

local ascentPath to path("0:/main/launch/multiStage_noAtmosphere").
local circPath   to choose path("0:/main/launch/circ_burn_node") if career():canMakeNodes else path("0:/main/launch/circ_burn_simple").

download(circPath).

local launchPlan to lex(
    "tgtAp",  ascentAlt,
    "tgtPe",  ascentAlt,
    "tgtInc", ascentInc,
    "tgtRoll",0,
    "lazObj", l_az_calc_init(ascentAlt, ascentInc),
    "queue", queue(ascentPath:name, circPath:name)
).
writeJson(launchPlan, launchPlanCache).

ship:deltaV:forcecalc.
disp_hud("Forcing dV recalc for stage: " + stage:number).
wait 1.
if stageOnAscent
{
    when alt:radar > 50 then
    {
        stage.
    }
}

// Main
runPath("0:/main/controller/launchController").
if circPath:volume:name <> "Archive" 
{
    deletePath(circPath).
}

ves_activate_solar(ship:modulesNamed("ModuleDeployableSolarPanel"), true).

local flyComms to list().
for m in ship:modulesNamed("ModuleRTAntenna") 
{
    if not m:part:tag:contains("groundAntenna")
    {
        flyComms:add(m).
    }
}

ves_activate_antenna(flyComms, true).