@lazyGlobal off.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_util.ks").

ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).

from { local x is 5.} until x = 0 step { set x to x - 1.} do {
    print "Test starting in " + x + "..." at (2,2).
    wait 1.
}

for p in ship:parts {
    if p:hasModule("ModuleTestSubject") {
        print "[" + p:title + "] Test in progress...                 " at (2,2).
        test_part(p).
    }
}