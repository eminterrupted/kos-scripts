@LazyGlobal off.
ClearScreen.

parameter _params is list().

// Dependencies
RunOncePath("0:/lib/depLoader").

// Declare Variables
local bootFile to Path("0:/boot/bn_payloadDeploy.ks").
local coreList to Ship:ModulesNamed("kOSProcessor").
local exemptVolumeNames to list(Ship:RootPart:Tag).
local includeRoot to False.
local overrideNamedVolumes to False.

// Parse Params
if _params:length > 0 
{
    set bootFile to _params[0].
    if _params:Length > 1 set coreList to _params[1].
    if _params:Length > 2 set overrideNamedVolumes to _params[2].
    if _params:Length > 3 set includeRoot to _params[3].
    if _params:Length > 4 set exemptVolumeNames to _params[4].
}

OutMsg("Uploading payload boot file [{0}]":Format(bootFile)).
cr().
from { local i to 0. local processFlag to False. } until i >= coreList:Length step { set i to i + 1. set processFlag to False. } do {
	local curCore     to coreList[i].
    local curVol      to curCore:Volume.

    OutInfo("Current Core: {0} (TAG=[{1}],UID=[{1}])":Format(curCore:Part:Name, curCore:Tag, curCore:Part:UID)).

    if curVol:Name = ""
    {
        set processFlag to True.
    }
    else if includeRoot
    {
        if curCore:Part:UID = Ship:RootPart:UID
        {
            set processFlag to True.
        }
    }
    else if exemptVolumeNames:Contains(curVol:Name)
    {
        set processFlag to False.
    }
    else if curCore:Part:UID <> Ship:RootPart:UID
    {
        set processFlag to overrideNamedVolumes.
    }

    if processFlag
    {
        OutInfo("Uploading boot file...").
        local vName to "payload_" + i.
		set curCore:Tag to vName.
		set curVol:Name to vName.
		copyPath(bootFile, vName + ":/boot/bl.ks").
        OutInfo("Setting BootFileName").
		set curCore:BootFileName to "/boot/bl.ks".
        if exists(Path("/boot/bl.ks")) and curCore:BootFileName = "/boot/bl.ks"
        {
            OutInfo("Upload successful").
        }
        else
        {
            OutInfo("Uh oh, something is borked").
        }
	}
    else
    {
        OutInfo("Core skipped!").
    }
    cr().
}
