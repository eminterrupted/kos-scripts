@lazyGlobal off.
clearScreen.

parameter p0.

runOncePath("0:/lib/lib_disp").
runOncePath("0:/lib/lib_vessel").

clearScreen.
//disp_main(scriptPath()).

print "Inputted timestamp: " + p0.
print "Formatted time (t)        : " at (0, 2). 
print "Formatted time (datetime) : " at (0, 3).

local ts to time:seconds - p0.

until false 
{
    print disp_format_time(ts - time:seconds, "ts") at (28, 2).
    print disp_format_time(ts - time:seconds, "datetime") at (28, 3).
}
print " ".
print "Time format complete".