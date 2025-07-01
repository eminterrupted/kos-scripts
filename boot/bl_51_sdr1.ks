if Core:HasEvent("Open Terminal") Core:DoEvent("Open Terminal").
print "Unpacking and establishing uplink...".
wait until ship:unpacked and homeConnection:IsConnected().
RunPath("0:/t/sdr1").