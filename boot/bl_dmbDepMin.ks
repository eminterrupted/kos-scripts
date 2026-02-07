clearScreen.
wait until missionTime > 1.
set sId to { return Ship:Name+"-"+Ship:RootPart:Uid.}.
set msId to sId().
set ts to Time:Seconds.
until sId() <> msId
{
    print "["+Round(Time:Seconds - ts, 3)+"|"+msId+"] Awt trg".
    wait 0.02.
}
print "["+Round(Time:Seconds - ts, 3)+"|"+sId()+"] Rtn strt".
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
ship:control:neutralize.
rcs off.
unlock steering.
print "["+Round(Time:Seconds - ts, 3)+"|"+sId()+"] Rtn cmplt".