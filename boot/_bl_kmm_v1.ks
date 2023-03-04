clearscreen.
Core:DoEvent("Open Terminal").
wait until ship:unpacked and kuniverse:timewarp:issettled.
print "Unpacked".
print "Establishing uplink".
until homeConnection:isconnected
{
    print "Connecting{0,-3}":format(list("",".","..","...")[round(mod(Time:Seconds,3))]) at(0,2).
}
print "Connected".
print "Boot process complete!".
runPath("0:/control/runctrl.ks").
