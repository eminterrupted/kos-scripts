clearScreen.

wait until ship:loaded.
wait until ship:unpacked.

print "KMD Bootup Sequence Initiated...".

local ts to time:seconds + 5.
until time:seconds >= ts
{
    print "KMD Bootup Sequence Initiated" at (0, 0).
    wait 0.25.
    print "KMD Bootup Sequence Initiated."  at (0, 0).
    wait 0.25.
    print "KMD Bootup Sequence Initiated.." at (0, 0).
    wait 0.25.
    print "KMD Bootup Sequence Initiated..." at (0, 0).
    wait 0.5.
}


if exists("1:/bootManifest.json") 
{
    print "Found manifest.json".
    local manifest to readJson("1:/bootManifest.json").
    
    if manifest["robotics"]:length > 0 
    {
        local event to "activate".
        for a in manifest["robotics"] 
        {
            local mod to a:getModule("ModuleRTAntenna").
            if mod:hasEvent(event) mod:doEvent(event).
        }
    }

    if manifest["bays"]:length > 0 
    {
        local event to "activate".
        for a in manifest["bays"] 
        {
            local mod to a:getModule("ModuleRTAntenna").
            if mod:hasEvent(event) mod:doEvent(event).
        }
    }

    if manifest["panels"]:length > 0 
    {
        local event to "activate".
        for a in manifest["panels"] 
        {
            local mod to a:getModule("ModuleRTAntenna").
            if mod:hasEvent(event) mod:doEvent(event).
        }
    }

    if manifest["antennas"]:length > 0 
    {
        local event to "activate".
        for a in manifest["antennas"] 
        {
            local mod to a:getModule("ModuleRTAntenna").
            if mod:hasEvent(event) mod:doEvent(event).
        }
    }

    copyPath("0:/boot/bootLoader.ks", "/boot/bootLoader.ks").
    set core:bootFileName to "/boot/bootLoader.ks".
    reboot.
}
else
{
    print "Boot manifest not found!".
    print " ".
    print "1:/>".
}