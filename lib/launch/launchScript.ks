//tutorial launch script with roll program

//first, clear the terminal screen
clearScreen.

set myThrottle to 0.

lock throttle to myThrottle.

//this is the countdown loop. at(col, line) puts the text in a specific location on screen
print "Counting down: " at (0,12).
from {local countdown is 15.} until countdown = -1 step {set countdown to countdown -1.} do {          
                
                //waits 1s to make sure this is a 1s timer
                wait 1.

                //prints countdown marker at 1s intervals
                if countdown > 10 {
                
                        print "T-" + countdown + " " at(16,12).
                
                } else if countdown = 10 {
                        
                        print "T-" + countdown + " "  at(16,12).
                        
                        set myThrottle to 0.01.

                } else if countdown < 10 and countdown > 8 {
                
                        print "T-" + countdown + " "  at(16,12).

                //fire ROFIs
                } else if countdown = 8 {
                        
                        print "T-" + countdown + " "  at(16,12).

                        print "ROFI engage" at(0,14).

                        stage.

                } else if countdown < 8 and countdown > 5 {
                
                        print "T-" + countdown + " "  at(16,12).

                
                //at 5s begin ignition sequence
                } else if countdown = 5 {
                        
                        print "T-" + countdown + " "  at(16,12).

                        print "Ignition sequence start" at(0,14).

                        stage.

                } else if countdown = 4 {
                        
                        print "T-" + countdown + " "  at(16,12).

                        print "Ignition sequence start" at(0,14).

                        stage.

                } else if countdown > 1 and countdown < 4 {
                
                        print "T-" + countdown + " "  at(16,12).

                //at 1s fire the sequence timers
                } else if countdown = 1  {
                        
                        SET myThrottle to 0.50.

                         print "T-" + countdown + " "  at(16,12).

                        stage.

                //at 0s, set throttle to 100% and release clamps
                } else if countdown = 0 {
                        
                        //Set throttle to 100% and release clamps
                        set myThrottle to 1.0.

                        print "T-" + countdown + " "  at(16,12).

                        stage.
                }
                
}.

//if vessel begins climbing, announce liftoff
if ship:verticalspeed > 0 {
            
            clearScreen.

            print "Liftoff!            " at (0,12).

}. 


//this trigger checks for thrust to be 0, then executes the code in brackets
when ship:maxthrust = 0 and ship:altitude > 0 then {
                
                clearScreen. 

                print "Heading: " + round(ship:heading)  at(0,4).
                print "Altitude: " + round(ship:altitude) at(0,5).
                print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                print "Air speed: " + round(ship:airspeed) at (0,9).

                print "Staging" at(0,12).

                wait 1.

                stage.
                
                //the preserve keyword keeps the trigger active after it has already been triggered
                preserve. 
}.


//heading(dir, pitch, roll) is the command for ship navigational control
set mySteer to heading(0,90,0).  

//locks steering to mySteer, which means we can just update the value
lock steering to mySteer.

//this is the loop for the gravity turn. execute loop until the ship reaches 100km
until ship:apoapsis > 100000 {
             

                //initiate roll program at 50m/s
                if ship:velocity:surface:mag >= 50 and ship:velocity:surface:mag < 125 {    
                        
                        set mySteer to heading(90,90,0).

                        //prints the apoapis, velocity, and altitude on screen, round(value, places) to avoid dec (except velocity)
                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                        print "Initiating roll program" at(0,12).
                        
                
                //once we pass 125m/s pitch down to 85 degrees
                } else if ship:velocity:surface:mag >= 125 and ship:velocity:surface:mag < 200 {  
                

                        set mySteer to heading(90,85,0).

                        print "Pitching to 85 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).
                
                //200 m/s, pitch to 80
                } else if ship:velocity:surface:mag >= 200 and ship:velocity:surface:mag < 275 {

                        set mySteer to heading(90,80,0).

                        print "Pitching to 80 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //275m/s, pitch to 75
                } else if ship:velocity:surface:mag >= 275 and ship:velocity:surface:mag < 350 {
                        
                        set mySteer to heading(90,75,0).

                        print "Pitching to 75 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //350m/s, pitch to 70
                } else if ship:velocity:surface:mag >= 350 and ship:velocity:surface:mag < 425 {

                        set mySteer to heading(90,70,0).

                        print "Pitching to 70 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).
                
                //425m/s, pitch to 65
                } else if ship:velocity:surface:mag >= 425 and ship:velocity:surface:mag < 500 {

                        set mySteer to heading(90,65,0).

                        print "Pitching to 65 degrees" at(0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //500m/s, pitch to 60
                } else if ship:velocity:surface:mag >= 500 and ship:velocity:surface:mag < 575 {

                        set mySteer to heading(90,60,0).

                        print "Pitching to 60 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //575m/s, pitch to 55
                } else if ship:velocity:surface:mag >= 575 and ship:velocity:surface:mag < 675 {

                        set mySteer to heading(90,55,0).

                        print "Pitching to 55 degrees" at (0,15).
                        
                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //675m/s, pitch to 45
                } else if ship:velocity:surface:mag >= 675 and ship:velocity:surface:mag < 800 {

                        set mySteer to heading(90,45,0).
                                               
                        print "Pitching to 50 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //800m/s, pitch to 35
                } else if ship:velocity:surface:mag >= 800 and ship:velocity:surface:mag < 925 {

                        set mySteer to heading(90,35,0).
    
                        print "Pitching to 50 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //925,/s, pitch to 25
                } else if ship:velocity:surface:mag >= 925 and ship:velocity:surface:mag < 1050 {

                        set mySteer to heading(90,25,0).
     
                        print "Pitching to 40 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).

                //1050,/s, pitch to 40
                } else if ship:velocity:surface:mag >= 1050 {

                        set mySteer to heading(90,15,0).
                        
                        print "Pitching to 40 degrees" at (0,15).

                        print "Heading: " + round(ship:heading)  at(0,4).
                        print "Altitude: " + round(ship:altitude) at(0,5).
                        print "Apoapsis: " + round(ship:apoapsis) at(0,6).
                        print "Vertical Speed: " + round(ship:verticalspeed) at(0,7).
                        print "Ground Speed: " + round(ship:groundspeed) at(0,8).
                        print "Air speed: " + round(ship:airspeed) at (0,9).
                
                }.

}.

wait until ship:altitude > 100000.

clearScreen.

print "Launch sequence complete!" AT(0,12).

//hands user control
unlock all.