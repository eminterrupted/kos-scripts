print "Waiting for HomeConnection".
until HomeConnection:IsConnected
{

}
runPath("0:/main/exec/mpExec51.ks").
copyPath("0:/boot/bx_TermGlobals.ks", "/boot/bl_51.ks").
reboot.


wait 1.
local aniList to list("     ", ".", "..", "...", "...-X", " ", "  ", "   ", "...->>").
local idx to 0.
ClearScreen.
print "okay".
until false {
  print "in da loop [{0}]":Format(idx).
  if HomeConnection:IsConnected 
  {
    print "Waiting for HomeConnection{0}":Format(aniList[aniList:Length - 1]) at (2, 12).
    wait 1.
    break.
  }
  else
  {
    print "Waiting for HomeConnection{0}":Format(aniList[idx]) at (2, 12).
  }
  set idx to choose 0 if idx = aniList:Length - 2 else idx + 1.
  wait 0.75.
}
print "Connection successful          " at (2, 12).
