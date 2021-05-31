@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/lib_util").

print "Running repair program".
print "----------------------".
print " ".

local partCount to 0.
local repairCount to 0.
local failCount to 0.

local repairLog to path("0:/data/partRepairLog.log").
if exists(repairLog) deletePath(repairLog).
log "Vessel,Result,UID,Name,Title" to repairLog.

print "Scanning vessel for failures...".
print " ".
for m in ship:modulesNamed("ModuleUPFMEvents")
{
    if m:hasEvent("repair") 
    {
        set partCount to partCount + 1.
        print "Failed part found: " + m:part:title.
        print "Attempting to repair part".
        util_do_event(m, "repair").
        if m:hasEvent("repair") 
        {
            set failCount to failCount + 1.
            print "Repair failed!".
            log ship:name + ",FAILED," + m:part:uid + "," + m:part:name + "," + m:part:title to repairLog.
        }
        else 
        {
            set repairCount to repairCount + 1.
            print "Repair successful!".
            log ship:name + ",SUCCESS," + m:part:uid + "," + m:part:name + "," + m:part:title to repairLog.
        }
        print " ".
    }
}

if partCount > 0 
{
    print "Total repairs attempted  : " + partCount.
    print "Successful repairs       : " + repairCount.
    print "Failed repairs           : " + failCount.
    print " ".
    print "Log: " + repairLog.
}
else
{
    print "No failures detected".
}