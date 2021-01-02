local guiPath to "0:/_main/launch_gui".
local mcPath to "local:/boot/mc".

if ship:status = "PRELAUNCH" {
    runPath(guiPath).
} else {
    print "Going through bootloader for local mc" at (2, 55). 
    wait 3.
    runPath(mcPath).
}