@lazyGlobal off.
clearScreen.

parameter param is "Read".

local blConnect to choose processor("PCX0"):connection if core:part:tag <> "PCX0" else processor("PCX1").
local msgReady to false.
local msgQueue to core:messages.

local waitStr to "Waiting for message".
local xmtStr to "Transmitting message".
local waitChars to list("-", "\", "|", "/").

print "Message system test".
print "Core: " + core:part:tag.
print "Mode: " + param.
print " ".

if param = "Read"
{
    until false
    {
        local ts to time:seconds.
        print waitStr at (0, 5).
        until msgQueue:length > 0 
        {
            if time:seconds < ts + 0.1 print "[" + waitChars[0] + "]" at (waitStr:length + 1, 5).
            else if time:seconds < ts + 0.2 print "[" + waitChars[1] + "]" at (waitStr:length + 1, 5).
            else if time:seconds < ts + 0.3 print "[" + waitChars[2] + "]" at (waitStr:length + 1, 5).
            else if time:seconds < ts + 0.4 print "[" + waitChars[3] + "]" at (waitStr:length + 1, 5).
            else set ts to time:seconds.
        }
    }
}