ClearScreen.

parameter _params is list().

set Config:Stat to True.

RunOncePath("0:/lib/depLoader").

local fileTime to GetFileTimeRT().
local profilePath to "0:/test/result/test_ks_{0}.csv":Format(fileTime).

local function FooBear
{
    parameter _prm is "not bound".

    print "Foo Bear is {0}":Format(_prm).
}

local funcDel to FooBear@:Bind("bound").

print funcDel:Call().