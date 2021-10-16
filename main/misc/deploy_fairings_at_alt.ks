parameter tgtAlt is 20000.

runOncePath("0:/lib/lib_vessel").
runOncePath("0:/lib/lib_util").

local fairings to list().

for m in ship:modulesNamed("ProceduralFairingDecoupler")
{
    if m:part:tag = "" fairings:add(m).
}

for m in ship:modulesNamed("ModuleProceduralFairing")
{
    if m:part:tag = "" fairings:add(m).
}

for m in ship:modulesNamed("ModuleSimpleAdjustableFairing")
{
    if m:part:tag = "" fairings:add(m).
}

when alt:radar <= tgtAlt then
{
    print "Fairings jettison".
    ves_jettison_fairings(fairings).
}

local parachutes to ship:modulesNamed("RealChuteModule").

if parachutes:length > 0 
{
    if parachutes[0]:name = "RealChuteModule" 
    {
        for c in parachutes 
        {
            print "Chutes armed".
            util_do_event(c, "arm parachute").
        }
    }
    else if parachutes[0]:name = "ModuleParachute"
    {
        when parachutes[0]:getField("safe to deploy?") = "Safe" then 
        {
            for c in parachutes
            {
                util_do_event(c, "deploy chute").
            }
        }
    }
}

until false
{
    wait 0.01.
}