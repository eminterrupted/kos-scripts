clearscreen.
Set Terminal:Width to 70.
Set Terminal:Height to 50.
Core:DoEvent("Open Terminal").
print "Booting".
wait until ship:unpacked and kuniverse:timewarp:issettled.
print "Unpacked".
local _a to list("",".","..","...").
until false
{
    if homeConnection:isconnected break.
    else print "Checking uplink{0,-3}":format(_a[round(mod(Time:Seconds,3))]) at(0,2).
}
print "Uplink complete!  ".
runPath("0:/control/runctrl.ks").