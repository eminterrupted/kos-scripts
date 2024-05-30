@LazyGlobal off.
ClearScreen. 

RunOncePath("0:/lib/depLoader.ks").
RunOncePath("0:/lib/deploy.ks").

local rtUID to Ship:RootPart:UID.

print "Waiting for deployment...".
until false
{
    if Ship:RootPart:UID = rtUID
    {
        wait 5.
    }
    else
    {
        break.
    }
}
ClearScreen.

local onPayloadParts to Ship:PartsTaggedPattern("OnPayload\|\d*").

if Ship:PartsTaggedPattern("OnPayload\|\d*"):Length > 0
{
    print "Running OnPayload Routine".
    from { local i to 0.} until i >= 9 step { set i to i + 1.} do
    {
        print "Index: " + i.
        local partsToDeploy to Ship:PartsTaggedPattern("OnPayload\|{0}":Format(i)).
        RunDeployRoutine(partsToDeploy).
    }
}
else if Ship:PartsTaggedPattern("OnDeploy\|\d*"):Length > 0
{
    print "Running OnDeploy Routine".
    from { local i to 0.} until i >= 9 step { set i to i + 1.} do
    {
        print "Index: " + i.
        local partsToDeploy to Ship:PartsTaggedPattern("OnDeploy\|{0}":Format(i)).
        RunDeployRoutine(partsToDeploy).
    }
}
else 
{
    print "Deploying Panels".
    for m in Ship:ModulesNamed("ModuleROSolar")
    {
        if m:HasEvent("Extend Solar Panel") m:DoEvent("Extend Solar Panel").
    }
    wait 2.5.
    print "Deploying Antenna".
    for m in Ship:ModulesNamed("ModuleDeployableAntenna")
    {
        if m:HasEvent("Extend Antenna") m:DoEvent("Extend Antenna").
    }
}
print "Deployment Complete".
print "Enabling RCS".

for m in Ship:ModulesNamed("ModuleRCSFX")
{
    SetField(m, "RCS", True).
}

print "Checking Connection...".
wait until HomeConnection:IsConnected().
print "Connection established".
copyPath("0:/boot/bn_ExecNodes.ks", "/boot/bl.ks").
wait 1.
reboot.