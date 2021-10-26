@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_disp").

disp_main(scriptPath()).

local cores to ship:modulesnamed("kosProcessor").
local shipCore to "".

set core:volume:name to "local".

for c in cores {
    if c:volume:name:contains("local") 
    {
        set shipCore to c.
        set c:volume:name to "local".
        set c:bootFileName to "/boot/bootLoader.ks".
        copyPath("0:/boot/bootLoader", "local:/boot/bootLoader.ks").
    }
    else if c:volume:name:contains("data") 
    {
        set c:volume:name to "data_0".
    }
}

local ln to 24.
local mpIdx to 0.
local mp to list().

print "Script keys:" at (0, 10).
print "Change Orbit      : NumPad1" at (0, 11).
print "Change Inclination: NumPad2" at (0, 12).
print "Simple Orbit      : NumPad3" at (0, 13).
print "Land on Mun       : NumPad4" at (0, 14).
print "Land Sci          : NumPad5" at (0, 15).
print "Mun Ascent        : NumPad6" at (0, 16).
print "Remove Last Script: Del"     at (0, 18).
print "Finalize Plan     : Enter" at (0, 19).

print "Current Plan" at (0, 22).
print "------------" at (0, 23).
until false
{
    if terminal:input:hasChar
    {
        local input to terminal:input:getChar().
        if input = "1" mp:add("maneuver/change_orbit").
        else if input = "2" mp:add("maneuver/change_inclination").
        else if input = "3" mp:add("mission/simple_orbit").
        else if input = "4" mp:add("land/land_on_mun").
        else if input = "5" mp:add("mission/land_sci").
        else if input = "6" mp:add("launch/mun_ascent").
        else if input = terminal:input:deleteRight
        {
            mp:remove(mp:length - 1).
            print "                                          " at (0, ln).
        }
        else if input = terminal:input:enter break.
    }
    set mpIdx to 0.
    set ln to 24.
    for m in mp
    {
        print mpIdx + ". " + m at (0, ln).
        set mpIdx to mpIdx + 1.
        set ln to ln + 1.
    }
}

local mpQueue to queue().
for m in mp
{
    mpQueue:push(m).
}

writeJson(mpQueue, "data_0:/missionPlan.json").
if core = shipCore 
{
    reboot.
}
else 
{
    shipCore:activate.
}