@lazyGlobal off.
runOncePath("0:/lib/lib_test").

test_pad_gen(true).

if core:part = ship:rootPart runPath("0:/test/partTest").
else runPath("0:/test/airborneTest").