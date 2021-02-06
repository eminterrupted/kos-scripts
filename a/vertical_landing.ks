// This script is essentially the same principle as the horizontal landing however it 
declare parameter LandingPosition is latlng(0,0), SpotLanding is FALSE.
// This script can funcion on its own and thus doesn't need the LandingPosition to be displayed
// SpotLanding is used for when using horizontal_landing
clearscreen.

declare function Hysteresis {
	declare parameter input,prev_output, right_hand_limit, left_hand_limit,right_hand_output is true.
	set output to prev_output.
	if prev_output = right_hand_output {
		if input <= left_hand_limit {
			set output to not(right_hand_output).
		}
	} else {
		if input >= right_hand_limit {
			set output to right_hand_output.
		}
	}
	return output.
}

// This sets some landing parameters such as determining what the true altiude is of the base of the rocket.
set ship:control:pilotmainthrottle to 0.
set TouchDownSpeed to 1. // This is set by the user, I set it to 5 since the landing legs break at 6.
set MaxCount to 3. // Used to average the derivative term since it can get pretty eratic
set buffer_alt to 20. // Its not perfect, so a little wiggle room is good to retract the legs.
lock true_alt to altitude - ship:geoposition:terrainheight.// - start_alt. // Again measured from the bottom of the craft.
// This script is meant to be used from a flat surface to launch and return. It can be adapted for landing from any situation.
SAS off.
GEAR ON.
set Throttle_RHL to 60.
set Throttle_LHL to 10.

if ship:body = "Mun" {
	set buffer_terrain to 0.
	}
if ship:body = "Duna" {
	set buffer_terrain to 10.
	}
if ship:body = "Mars" {
	set buffer_terrain to 10.
	}
set buffer_terrain to 10.	
lock V to ship:velocity:orbit.
lock R to ship:body:position.
lock Vper to VDOT(VCRS(R,VCRS(V,R)):direction:vector,V).
lock AccelCent to (Vper^2)/R:mag.
// After it goes up high the rocket will wait to fall back down.
// I manually select the retrograde selection on the SAS. I would do it with the cooked steering but its current
// iteration was not working well with the test ship.
lock MaxThrustAccUp to VDOT(UP:vector,availablethrust/mass*srfretrograde:vector).
// This assumes the ship is pointed exactly retrograde. Meaning this can be used as a gravity turn for landing as well.
lock GravUp to (-1)*(ship:body:mu)/((R:mag)^2).
lock MaxAccUp to MaxThrustAccUp + GravUp + AccelCent. // I opted out of adding drag since its finiky, this adds some safety margin though
lock FPAsurf to 90 - VANG(UP:vector,ship:velocity:surface).

clearscreen.
lock Vmax to sqrt(MAX(0,2*(true_alt - buffer_terrain)*MaxAccUp + TouchDownSpeed^2)).
// The magic of the script. This equation is derived assuming an ascent starting at the touchdown speed and accelerating
// at full throttle. It auto adjusts based on the altitude and the Max Acceleration as it changes with mass loss.
// Basic PD loop. I want essentially no overshoot and very little error at the end. The Kp_v and Kd_v gains are tuned so at the finish
// of the script the error > 0 and absolutely no overshoot. Tune to your liking however (fair warning, you have VERY little margin
// when you are landing. The burn times I have seen are very short. That depends on the ship's TWR however.
lock error_v to Vmax + verticalspeed.
set errorP_v to 0.
set Kp_v to .04.
set errorD_v to 0.
set Kd_v to 0.04.
set ThrustSet to 0.
lock throttle to ThrustSet.
set time0 to time:seconds.
lock time1 to time:seconds - time0.
set count to 1.
set flightmode to 1.
lock steering to srfretrograde.
set Thrust_Hyst_En to false.

until flightmode = 2 AND ship:status = "LANDED" {
	// If you are using this in tandem with Horizontal Landing then this will display where you are landing.
	if SpotLanding {
		set LandingVector to VECDRAW(LandingPosition:position,(altitude-LandingPosition:terrainheight+25)*(LandingPosition:position-R):normalized,GREEN,"Landing Position",1.0,TRUE,.5).
		}
	
	if flightmode = 1 {
		if verticalspeed > 0 AND (AccelCent+GravUp) > 0  {
			set ThrustSet to 1.
			clearscreen.
			print "Burning to Kill Speed, Centrifugal Acceleration too high".
			wait until verticalspeed < 0.
			clearscreen.
			}
		set error1 to error_v.
		set t1 to time1.
		wait .00001.
		set error2 to error_v.
		set t2 to time1.
		set dt to t2-t1.
		// I like to take an average error so its not going crazy due to discrete calculations.
		set errorP_v to .5*(error1+error2).
		set errorD_v_test to (error2-error1)/dt.
		//This next part is used as a running average, the Derivative term was behaving eratically thus this damps out the spikes.
		if count < MaxCount {
			if count < 2 {
				set errorD_v to errorD_v_test.
				}
			if count >= 2 {
				set errorD_v to (errorD_v*(count-1)+errorD_v_test)/count.
				}
			set count to count + 1.		
			}
		if count >= MaxCount {
		
			set errorD_v to (errorD_v*(MaxCount-1)+errorD_v_test)/MaxCount.
			}
		
		set ThrustDemand to 1 - Kp_v*errorP_v - Kd_v*errorD_v.
		if ThrustDemand > 1 { set ThrustDemand to 1. }
		set Thrust_Hyst_En to Hysteresis(ThrustDemand,Thrust_Hyst_En,Throttle_RHL/100,Throttle_LHL/100).
				
		if Thrust_Hyst_En {
			set ThrustSet to ThrustDemand.
			} else {
			set ThrustSet to 0.
			}
		
		if error_v < 0 {
			set ThrustSet to 1. // This is very important. If the error ever drops below 0, it means it might crash since the
								// equation is calculated based on full thrust. 
			}
	
	}
	// Cut off conditions for exiting the vertical landing
	if flightmode = 1 AND true_alt < buffer_alt AND verticalspeed > -1*TouchDownSpeed AND GroundSpeed < 1 {
	    GEAR on.
		lock steering to up.
		lock throttle to .99*mass*-1*GravUp/availablethrust.
		set flightmode to 2.
	}
	if flightmode = 1 AND verticalspeed > -1*TouchDownSpeed AND GroundSpeed < 1 {	
		GEAR on.
		lock steering to up.
		lock throttle to .99*mass*-1*GravUp/availablethrust.
		set flightmode to 2.
		}
	// Some data readouts. Pay attention to the Error term, make sure it doesn't drop below 0.
	
	print "Vmax       = " + round(-1*Vmax,2) + "     "at(0,0).
	print "VertSpeed  = " + round(verticalspeed,2) + "     " at (0,1).
	print "Radar Alt  = " + round(true_alt,2) + "     " at(0,2).
	print "Error Vert = " + round(error_v,2) + "     " at(0,3).
	print "ThrustSet  = " + round(ThrustSet*100,2) + "%       " at(0,4).
	print "GravUp     = " + round(GravUp,2) + "     " at(0,5).
	print "AccelCent  = " + round(AccelCent,2) + "     " at(0,6).
	print "MaxThrustAccUp = " + round(MaxThrustAccUp,2) + "     " at(0,7).
	print "MaxAccUp   = " + round(MaxAccUp,2) + "     " at (0,8).
	print "FlightMode = " + flightmode + "     " at (0,9).
	print "GroundSpeed= " + round(GroundSpeed,2) + "     " at (0,10).
	print "Thrust_Hyst_En = " + Thrust_Hyst_En + "  " at(0,11).
	print "ThrustDemand = " + round(ThrustDemand*100,1) +"%   " at(0,12).
	
	}
	
// Lastly a very crude landing script. The reason for the .99 multiplication is because its not perfect. So the velocity will start to decrease even though there should be no acceleration.
// One could make a simple Proportional controller to assure touchdown speed is met buuut this works fine for low buffer_alt values.
lock throttle to 0.
SAS on.
unlock steering.
wait 10.
clearscreen.
