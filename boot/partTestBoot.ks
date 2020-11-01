@lazyGlobal off.

clearScreen.
runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/lib_util.ks").

for p in ship:parts {
    if p:hasModule("ModuleTestSubject") {
        test_part(p).
    }
}