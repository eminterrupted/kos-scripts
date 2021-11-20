@lazyGlobal off.
clearScreen.

parameter param is "Read".

runOncePath("0:/lib/util").

local blConnect to choose processor("PCX0"):connection if core:part:tag <> "PCX0" else processor("PCX1").
local msgs to list().
local msgQueue to core:messages.

local waitStr to "Waiting for message".
local xmtStr to "Transmitting message".
local waitChars to list("-", "\", "|", "/").

if param = "Read"
{
    until false
    {
        print "Message system test".
        print "Core: " + core:part:tag.
        print "Mode: " + param.
        print " ".
        print waitStr at (0, 5).

        local ts to time:seconds.
        until msgs:length > 0
        {
            set msgs to CheckMsgQueue().
            if time:seconds < ts + 0.1 print "[" + waitChars[0] + "]" at (waitStr:length + 1, 5).
            else if time:seconds < ts + 0.2 print "[" + waitChars[1] + "]" at (waitStr:length + 1, 5).
            else if time:seconds < ts + 0.3 print "[" + waitChars[2] + "]" at (waitStr:length + 1, 5).
            else if time:seconds < ts + 0.4 print "[" + waitChars[3] + "]" at (waitStr:length + 1, 5).
            else set ts to time:seconds.
        }

        print "Message received!            " at (0, 5).
        print "Sent from: " + msgs[1] at (0, 6).
        print "Received : " + msgs[0] at (0, 8).
        print "-----------------------" at (0, 9).
        print msgs[2] at (0, 10).
        
        Breakpoint().
        msgs:clear().
        clearScreen.
    }
}