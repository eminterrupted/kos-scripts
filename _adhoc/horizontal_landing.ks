// From: TheGreatFez: https://github.com/TheGreatFez/kOS-Scripts/blob/master/horizontal_landing.ks

//WARNING COMPATIBILITY CHECK
//-This script is only ment to work on non-atmosphere bodies, have not tested or run this on atmosphere bodies.
//-Only works if the ship does not have to stage in the middle of the landing burn. Otherwise all calculations might be thrown off
//-Only works if the ship is at near 0 starting inclination and very circular

parameter _tgtGeo is latlng(0, 120).

// Execute Node Function that I use for maneuver nodes
declare function ExecuteNode {
	clearscreen.
	lock throttle to 0.
	SAS off.
	lock DeltaV to nextnode:deltav:mag.
	set BurnTime to .5*DeltaV*mass/availablethrust.
	lock steering to nextnode.
	print "Aligning with Maneuver Node".
	until VANG(ship:facing:vector,nextnode:burnvector) < 1 {
		print "Direction Angle Error = " + round(VANG(ship:facing:vector,nextnode:burnvector),1) + "   "at(0,1).
	}
	clearscreen.
	print "Warping to Node".
	print "Burn Starts at T-minus " + round(BurnTime,2) + "secs   ".
	warpto(time:seconds + nextnode:eta - BurnTime - 10).
	wait until BurnTime >= nextnode:eta.
	
	clearscreen.
	lock throttle to DeltaV*mass/availablethrust.
	print "Executing Node".
	
	until DeltaV <= .1 {
		print "Delta V = " + round(DeltaV,1) + "   " at(0,1).
		print "Throttle = " + MIN(100,round(throttle*100)) + "%   " at(0,2).
	}
	lock throttle to 0.
	unlock all.
	remove nextnode.
	clearscreen.
	print "Node Executed".
}

// Landing position
CLEARVECDRAWS().
SAS OFF.
//lock steering to srfretrograde.
set landing_pos to _tgtGeo.// Where you want to land, currently can only be at 0 lattitude
set g0 to ship:body:mu/(ship:body:radius)^2.
set TWR to availablethrust/(mass*g0).
set Fuel_Factor to 1.25.
set landing_per_buffer to 2000. 	// How high above the landing postion do you want the periapsis of the transfer orbit to be. 
								// NOTE: If this is too low your ship might crash because it starts to drop as it looses horizontal speed.
								// 500m worked very well for my test ship which had a starting Mun TWR of 5.91
if ship:body:name = "Mun" {
	set landing_per_buffer to (50290*(TWR*Fuel_Factor)^(-2.232) + 222.1)*(0.955)^(landing_pos:terrainheight/2500).
	clearscreen.
	print landing_per_buffer.
	wait 1.
	}
if ship:body:name = "Kerbin" {
	set landing_per_buffer to 40000.
	}
if ship:body:name = "Duna" {
	set landing_per_buffer to 20000.
	}
//if ship:body = Mars {
//	set landing_per_buffer to 15000.
//	}
	

lock R_ship to ship:body:position.
lock angle_diff_h to VANG(-R_ship, landing_pos:position - R_ship).
lock dist_diff_h to (angle_diff_h/360)*2*(constant:pi)*R_ship:mag. // Converstion of the difference in angle to a distance
lock Velocity_h_norm to VCRS(VCRS(R_ship,ship:velocity:orbit),R_ship):normalized.
lock Speed_h to VDOT(Velocity_h_norm,ship:velocity:orbit).
lock position_speed_h to landing_pos:altitudevelocity(altitude):orbit:mag.
lock speed_diff_h to Speed_h-position_speed_h. // Converstion of the difference in angular speed to a speed difference
clearscreen.

// Calculte and set the maneuver node. The periapsis will be the preset landing periapsis buffer altitude above the ground at the landing point.
if ship:body:name = "Mun" {
	set R_per_landing to ship:body:radius + max(4500*(ship:body:radius/200000),landing_pos:terrainheight + landing_per_buffer).
	} else {
		set R_per_landing to ship:body:radius + landing_per_buffer.
	}

set SMA_landing to (R_ship:mag + R_per_landing)/2.
set ecc_landing to (R_ship:mag - R_per_landing)/(R_ship:mag + R_per_landing).
set V_apo to sqrt(((1-ecc_landing)*ship:body:MU)/((1+ecc_landing)*SMA_landing)).

set TimePeriod_landing to 2*(constant:pi)*sqrt((SMA_landing^3)/(ship:body:mu)).

set prev_dist_h to dist_diff_h.
wait .1.
set curr_dist_h to dist_diff_h.
set delta_dist_h to curr_dist_h - prev_dist_h. // Check to see if you are infront of behind the desired maneuver node burn point

if delta_dist_h > 0 {
	set eta_node to (TimePeriod_landing/2*position_speed_h)/speed_diff_h + ((constant:pi)*R_ship:mag-dist_diff_h)/speed_diff_h.
	if eta_node < 60 {
		set eta_node to (TimePeriod_landing/2*position_speed_h)/speed_diff_h + ((constant:pi)*R_ship:mag-dist_diff_h+(constant:pi)*R_ship:mag)/speed_diff_h.
		}
} else {
	set eta_node to (TimePeriod_landing/2*position_speed_h)/speed_diff_h + ((constant:pi)*R_ship:mag+dist_diff_h)/speed_diff_h.
	}
	
set deltaV_landing to V_apo - velocityat(ship,time:seconds + eta_node):orbit:mag.

for node in allnodes {remove node.}
set landing_node to NODE(TIME:seconds + eta_node, 0, 0, deltaV_landing).
ADD landing_node.

ExecuteNode().
// I have no idea why I have to retype all the variables I defined earlier but if I don't it gives me some strange errors that the variables aren't defined.
// If anyone would like to help, you can comment from the next line to the "End of the commenting section" and try and run it. I hope you get the same error, and know how to fix it!
lock steering to srfretrograde.
set landing_pos to LATLNG(0,120).

set buffer_speed_h to 0.
set cutoffspeed_h to 25.
//set landing_eta_buffer to 100.
set CutOffThrottle to 0. // In percent
set MaxCount to 5.

lock R_ship to ship:body:position.
lock angle_diff_h to VANG(-R_ship, landing_pos:position - R_ship).
lock dist_diff_h to (angle_diff_h/360)*2*(constant:pi)*R_ship:mag.
lock Velocity_h_norm to VCRS(VCRS(R_ship,ship:velocity:orbit),R_ship):normalized.
lock Speed_h to VDOT(Velocity_h_norm,ship:velocity:orbit).
lock speed_diff_h to Speed_h-landing_pos:altitudevelocity(altitude):orbit:mag.
lock long_diff_dir to VCRS(landing_pos:position,R_ship):normalized.
lock long_diff_h to VDOT(long_diff_dir,ship:velocity:surface).
lock Velocity_diff_direction to (-1*(ship:velocity:orbit - landing_pos:altitudevelocity(altitude):orbit + long_diff_h*long_diff_dir)):direction.
clearscreen.
// End of error commenting section.
// This is the heart of the function. The max horizontal acceleration is calculated as if the rocket is always in surface retrograde. 
// Maintaining surface retrograde maximizes efficiency when landing
// Vmax_h is the maximum speed a ship can be traveling at its current distance to the target such that at full thrust it will reach the target with 0 velocity (aka suicide burn)
// Vmax_h assumes the thrust is constant but updates it to the current max horizontal acceleration and uses a PD loop to deal with the changing TWR
lock MaxThrustAccHor to -1*VDOT(Velocity_h_norm,availablethrust/mass*srfretrograde:vector).
lock truealt to altitude - landing_pos:terrainheight.
lock touchdown_time to (-verticalspeed - sqrt(verticalspeed^2 - 4*(-0.5*g0)*truealt))/(-1*g0).
lock cutoffdist_h to speed_diff_h*touchdown_time.
//set buffer_dist to 93.75.
set buffer_dist to 0.
lock Vmax_h to sqrt(MAX(0,2*(dist_diff_h - buffer_dist)*MaxThrustAccHor)).
// Standard PD loop parameters
lock error_h to Vmax_h - speed_diff_h.
set errorP_h to 0.
set Kp_h to 0.04.
set errorD_h to 0.
set Kd_h to 0.04.
set ThrustSet to 0.
set GravityTurnCorrection to 1.5/100.
lock throttle to ThrustSet.
set time0 to time:seconds.
lock time1 to time:seconds - time0.
set count to 1.
set flightmode to 1.
// Just a nice helping orientation so that your ship is already close to ready to go when it is done warping to the periapsis
set align_vector to -1*landing_pos:altitudevelocity(altitude):orbit.
lock steering to align_vector.
print "Aligning with Surface Retrograde Preemptively".
until VANG(ship:facing:vector,align_vector) < 1 {
	print "Direction Angle Error = " + round(VANG(ship:facing:vector,align_vector),1) + "   "at(0,1).
}
clearscreen.
set landing_eta_buffer to velocityat(ship,time:seconds + eta:periapsis):orbit:mag/(TWR*g0).
print "Warping to " + round(landing_eta_buffer,0) + "sec before Periapsis".
warpto(time:seconds + eta:periapsis - 1.075*landing_eta_buffer).

set follow_mode to 1.
lock steering to srfretrograde.
clearscreen.
until flightmode = 2 {
	if follow_mode = 1 {
		if ship:body:atm:exists {
			if ThrustSet > 0 {
			lock steering to Velocity_diff_direction.
			set follow_mode to 2.
			}
		} else {
			lock steering to Velocity_diff_direction.
			set follow_mode to 2.
			}
	}
	// A visual aid to show where the ship is supposed to land.
	set LandingVector to VECDRAW(landing_pos:position,(altitude-landing_pos:terrainheight+25)*(landing_pos:position-R_ship):normalized,GREEN,"Landing Position",1.0,TRUE,.5).
	set SideslipVector to VECDRAW(V(0,0,0),10*long_diff_h*long_diff_dir,GREEN,"Sideslip Component",1.0,TRUE,.5).
	if flightmode = 1 {
		// Main PD loop for the thrust control
		set error1_h to error_h.
		set dist1 to dist_diff_h.
		set t1 to time1.
		wait .00001.
		set error2_h to error_h.
		set dist2 to dist_diff_h.
		set t2 to time1.
		set dt to t2-t1.
		// I like to take an average error so its not going crazy due to discrete calculations.
		set errorP_h to .5*(error1_h+error2_h).
		set errorD_h_test to (error2_h-error1_h)/dt.
		//This next part is used as a running average, the Derivative term was behaving eratically thus this damps out the spikes.
		if count < MaxCount {
			if count < 2 {
				set errorD_h to errorD_h_test.
				}
			if count >= 2 {
				set errorD_h to (errorD_h*(count-1)+errorD_h_test)/count.
				}
			set count to count + 1.		
			}
		if count >= MaxCount {
		
			set errorD_h to (errorD_h*(MaxCount-1)+errorD_h_test)/MaxCount.
			}
		
		set ThrustSet to 1 - Kp_h*errorP_h - Kd_h*errorD_h + GravityTurnCorrection.
		
		if ThrustSet > 1 {
			set ThrustSet to 1.
			}
		if dist2 > dist1 AND ship:obt:trueanomaly < 90 {
			set ThrustSet to 1.
			}
		// The Cut Off Thrust is used to help maximize efficiency. At 0 it is a nice smooth ramp up but if you make the fuel cut off higher it only turns on when its above this value and thus increases efficiency
		// since the ship will be burning at a higher throttle on average (100% throttle is the most efficient but that requires some more calculations).
		if ThrustSet < CutOffThrottle/100 {
			set ThrustSet to 0.
			}
		if errorP_h < 0 {
			set ThrustSet to 1. // This is very important. If the error ever drops below 0, it means it might crash since the
								// equation is calculated based on full thrust. 
			}
		// Cut off conditions to switch to vertical landing portion of the controller
		if speed_diff_h < 0.1 {
			set ThrustSet to 0.
			set flightmode to 2.
			}
		if (dist_diff_h > (cutoffdist_h)) AND speed_diff_h < cutoffspeed_h {
			set ThrustSet to 0.
			set flightmode to 2.
			}
	}
	
	print "Horizontal Distance to Landing Site = " + round(dist_diff_h,2) + "     "at(0,0).
	print "Speed relative to Landing Site = " + round(speed_diff_h,2) at(0,1).
	print "MaxThrustAccHor = " + round(MaxThrustAccHor,2) at(0,2).
	print "Vmax_h = " + round(Vmax_h,2) at(0,3).
	print "errorP_h = " + round(errorP_h,2) + "      " at(0,4).
	print "errorD_h = " + round(errorD_h,2) + "      " at(0,5).
	print "ThrustSet = " + round(ThrustSet*100,2) + "%     " at(0,7).
	print "Flightmode = " + flightmode at(0,8).
	print "cutoffdist_h = " + round(cutoffdist_h,2) + "      " at(0,9).
	print "Distance to target cutoff = " + round(cutoffdist_h - dist_diff_h,2) + "       " at(0,10).
	print "follow_mode = " + follow_mode at(0,11).
	print "long_diff_h = " + round(long_diff_h,2) + "      " at(0,12).
	}
	run vertical_landing(landing_pos,TRUE).