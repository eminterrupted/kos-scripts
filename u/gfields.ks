@lazyGlobal off.

parameter part. 

runOncePath("0:/lib/lib_util").
print "gfields [part]".
print " ".
print "PART(" + part:title + " / " + part:name + "):".

from { local n is 0.} until n = part:modules:length step { set n to n + 1. } do {

    local m is part:getModuleByIndex(n).
    if m:allFieldNames:length > 0 {
        local mObj to get_module_fields(m).
        print "  MODULE(" + m:name + "):".
        for f in mObj:keys {
            print "    " + f + ":  " + mObj[f].
        }
        print " ".
    }
}