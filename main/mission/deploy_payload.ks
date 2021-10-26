@lazyGlobal off.
clearScreen.

parameter payloads is ship:partsTaggedPattern("payload.").

// Dependencies
local libs to list(
    "0:/lib/lib_disp.ks"               //#include "0:/lib/lib_disp"
    ,"0:/lib/lib_util.ks"              //#include "0:/lib/lib_util"
    ,"0:/lib/lib_vessel.ks"            //#include "0:/lib/lib_vessel"
).

for lib in libs 
{
    local locLib to copyLocal(lib).
    runOnceLocal(locLib).
}

// Variables
local bootPath to "".
local idx to 0.
local manifest to lex().
local ts to 0.

// Main
if payloads:length > 0
{
    for p in payloads
    {
     if p:hasModule("kOSProcessor")
        {
            local cpu to p:getModule("kOSProcessor").
            set bootPath to cpu:volume:root + ":/bootManifest.json".

            manifest:clear().
            set manifest["antennas"] to ship:partsTaggedPattern("payloadAntenna." + idx).
            set manifest["panels"]   to ship:partsTaggedPattern("payloadPanel."+ idx).
            set manifest["bays"]     to ship:partsTaggedPattern("payloadBays." + idx).
            set manifest["robotics"] to ship:partsTaggedPattern("payloadRobotic." + idx). 

            
            writeJson(manifest, bootPath).

            if exists(bootPath)
            {
                bootCycle(cpu).
            }
                stagePayload(cpu).
                set idx to idx + 1.
            }
            else
            {
                except("Could not write manifest to location (" + bootPath + ")", 2).
            }
        }
    }
else
{
    except("No payload on vessel", 2).
}

// Functions

// function for copying libs to data disk
local function copyLocal
{
    parameter srcFile.

    local destFile to changeRoot(srcFile, "data_0").
   
    if addons:rt:hasKscConnection(ship) 
    {
        if exists(srcFile) copyPath(srcFile, destFile).
    }
    return destFile.
}

// function for running libs off data disk. If not found, or if a KSC connection is available, run from archive
local function runOnceLocal
{
    parameter fileToRun.

    if not exists(fileToRun) and addons:rt:hasKscConnection(ship)
    {
        set fileToRun to changeRoot(fileToRun, "0").
    }
    runOncePath(fileToRun).
}

// Change the root of a path
local function changeRoot
{
    parameter srcFile,
              destRoot.

    if srcFile:typename = "string" set srcFile to path(srcFile).
    
    local   destFile to destRoot + ":".
    local   srcSeg   to srcFile:segments.

    from { local i to 0.} until i >= srcSeg:length step {set i to i + 1.} do {
        set destFile to destFile + "/" + srcSeg[i].
    }
    return path(destFile).
}

// Reboot a cpu
local function bootCycle
{
    parameter cpu.

    if cpu:part:uid = core:part:uid
    {
        reboot.
    }
    else
    {
        disp_msg("Booting Payload (" + cpu:part:tag:split(".")[1] + ")").
        set ts to time:seconds + 2.5.
        cpu:deactivate.
        until time:seconds >= ts
        {
            disp_info("Bootup Timer: " + round(ts - time:seconds, 2)).
        }
        cpu:activate.
        disp_info().
    }
}

// Stage a payload, assuming proper stage order
local function stagePayload
{
    parameter cpu.

    disp_msg("Staging Payload (" + cpu:part:tag:split(".")[1] + ")").
    set ts to time:seconds + 5.
    until time:seconds >= ts
    {
        disp_info("Staging: " + round(ts - time:seconds, 2)).
    }
    ves_safe_stage().
    disp_info().
}