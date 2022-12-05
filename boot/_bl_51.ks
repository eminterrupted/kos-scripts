lock throttle to 1.
print "Press any key to launch".
wait until Terminal:Input:HasChar.
print "Launch sequence start".
until VerticalSpeed > 1 {stage. wait 1.}
until false {
  if ship:availableThrust < 0.1 {
    wait until stage:ready.
	stage.
	wait 2.
  }
  else { print "THRUST: " + round(ship:availableThrust,2) at (2,5).}
  wait 0.1.
}