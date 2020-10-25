//Launch script using info from https://www.youtube.com/watch?v=QBZUiuhJKZc&list=PLEpK8nolWr1rghS5cOEOL-JQ33h4CgPAP&index=2&t=0s
//Thia program will launch a ship into orbit

//Parameters to pass in - countdown timer, targetApo, targetPer
declare parameter countdown is 10, targetApoapsis is 100000, targetPeriapsis is 100000, targetInclination is 0.0.

//clearscreen
clearScreen.

set cd to (random() * 3).
set typeTime to 0.07.

until round(cd) <= 0 {
        
        print "L" at (1,1).
        wait typeTime.

        print "Lo" at(1,1).
        wait typeTime.

        print "Loa" at(1,1).
        wait typeTime.

        print "Load" at(1,1).
        wait typeTime.

        print "Loadi" at(1,1).
        wait typeTime.

        print "Loadin" at(1,1).
        wait typeTime.

        print "Loading" at(1,1).
        wait typeTime.

        print "Loading." at(1,1).
        wait typeTime.

        print "Loading.." at(1,1).
        wait typeTime.

        print "Loading..." at(1,1).
        wait 1.25.

        print "          " at(1,1).
        wait 1.
        
        set cd to ( cd - 1 ).

        }


//gravity turn parameters
set gravityTurnAlt to 2500.     // Max altitude for gravity turn to begin
set gravityTurnVel to 100.      // Max velocity for gravity turn to begin

//Other variables
set cooldown to 10.

//Important concepts
    //runmode - this will be used for flow control as well as displaying what block of code the system is processing
    //  0: Terminate runmode
    // 11: Launch countdown routine
    //  1: Launch routine 
    //  2: Launched, roll program
    //  3: Vertical ascent
    //  4: Intitial gravity turn
    //  5: Coast to Apoapsis
    //  6: Circularization burn
    //  9: Cooldown timer
    // 10: Deploy panels and antenna, return control to player


//Begin program

//Set ship to known configuration
SAS off. 
RCS off.
lights on. 
gear off.
set tVal to 0.
set launchCommit to 0.

set runmode to 2. //Safety in cas we start mid flight
if (alt:radar < 25) and (ship:verticalspeed < 1.0) { //Guess if we are waiting for takeoff 
    set runmode to 1. 
    }

until runmode = 0 { //Run until we end the program

    if runmode = 1 {
        if countdown >= 1 {
            print "Launch countdown (T - " + countdown + "s)  " at (18,8).
            wait 1.
            set countdown to (countdown - 1).
        } 
        else if countdown < 1 {
            print "Launch countdown (T - 0s)               " at (18,8).
            set runmode to 2.                           //initiate launch routine
        }
    }

    if runmode = 2{                            //Ship is on the launch pad
        print "Liftoff!                         " at (18,8).
        lock steering to heading (90,90,270).                   //Point the rocket straight up
        set tVal to 1.                                          //Throttle up to 100%
        stage.                                                  //Pressing space bar
        set launchCommit to 1.                                  //Triggers the "go for launch" flag
        set runmode to 3.                                       //Vehicle is off the pad, go to next runmode)
    }

    else if runmode = 3 {                       //Initiate the roll program

        set tVal TO 1.                                          //Throttle stays at 100% throughout liftoff and roll program

        if alt:radar < 75 {
            lock steering to heading (90,90,270).               // Keep current steering
            set defRTF to steeringManager:rolltorquefactor.     // Dumps existing default roll torque factor to restore after roll program is complete
            set steeringManager:rolltorquefactor to .50.        // Sets the RTF to 50% to ensure a nice gradual roll program.
            print "Liftoff!                         " at (18,8).
        }

        else if runmode = 3 and ship:altitude < 250 {
            lock steering to heading(90,90,0).                  // Initiates roll program
            print "Roll program                     " at (18,8).
        }

        else if runmode = 3 and (steeringManager:rollerror > 5.0 or steeringManager:rollerror < -5.0) {
            print "Roll program                     " at (18,8).
        }

        else if runmode = 3 and (steeringManager:rollerror < 5.0 or steeringManager:rollerror > -5.0 ) {
            set steeringManager:rolltorquefactor to defRTF.     // restore RTF
            print "Roll program complete            " at (18,8).
            set runmode to 4.
        }
    }

    else if runmode = 4 {                       //Continue vertical ascent
        print "Vertical ascent                  " at (18,8).
        lock steering to heading(90,90,0). 

        if ship:altitude > gravityTurnAlt {                     //When ship reaches 3500m in altitude 
            set runmode to 5.                                   //initiate next runmode
        }
        else if ship:airspeed >= gravityTurnVel {               //Else, if ship is travelling at faster than 125m/s 
            set runmode to 5.                                   //initiate next runmode
        }
    }

    else if runmode = 5 {   //Gravity turn
        print "Gravity turn                     " at (18,8). 
        set targetPitch to max( 3, 90 * (1 - alt:radar / 50000 )).  //Pitch over gradually until levelling out to 3 degrees above 50 km. 
                                                                    //Value of pitch is current altitude divided by horizontal altitude, substracted from 1 to make a decreasing number, multiplied by 90 to get degrees)
        lock steering to heading( 90, targetPitch, 0).              //heading 90' due E, then target pitch, then roll to 0'
        set tVal to 1.                                              //Keep throttle at 100%

        if ship:apoapsis >= targetApoapsis {                        //when ship reaches apoapsis
            set runmode to 6.                                       //set to next runmode
        }
    
    }

    else if (runmode = 6) or (runmode = 55) {   //Coast to Apo
        print "Coasting to apoapsis             " at (18,8).
        lock steering to ship:prograde.  
        
        //if ship is in atmosphere and Apo meets requirement, turn off engine
        if (runmode = 6) and (ship:altitude <=70000) and (ship:apoapsis >= targetApoapsis) {
            set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).      //Pitch over gradually until levelling out to 0 degrees above target altitude 
            lock steering to heading( 90, targetPitch, 0).                          //Keeps the ship pointed forward
            set tVal to 0.0.                                                        //Keep throttle at 0%
        }
        
        //if ship is in atmosphere and Apo is below requirement, initiate a correction burn
        if (runmode = 6) and (ship:altitude <=70000) and (ship:apoapsis < (targetApoapsis * 0.995)) {
            print "Correction burn                  " at (18,8).
            set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).      //Pitch over gradually until levelling out to 0 degrees above target altitude 
            lock steering to heading( 90, targetPitch, 0).                          //Keeps the ship pointed forward
            set tVal to 0.05.                                                       //Keep throttle at 5%
            set runmode to 7.                                                      //runmode for coasting burns
            }

        //If ship is out of atmosphere and on target, create manuever node for circularization burn, then initiate warp
        if (runmode = 6) and (ship:altitude > 70000) and (ship:apoapsis >= (targetApoapsis * 0.995)) and (eta:apoapsis > 120) and (verticalSpeed > 0) { //warp requirements - in space, apoapsis is met, more than 60s away from Apo and stable
            if warp = 0 {                                                           //if we are not already time warping
            
            print "Calculating circularization burn " at (18,8).
            
            //set stageParts to parts:stage.
            //set eng to { list engines in stageParts.}.
            //set circPro to ().                                                        //Calculates the dV required for a circularization burn at Apo
            //set circNode to node((time:seconds + eta:apoapsis), 0, 0, circPro).     //Creates the manuever node for the circularization burn
            
            print "Initiating time warp             " AT (18,8). 
            wait 3.                                                                 //wait to make sure ship is stable
            set warp to 2.                                                          //Warp setting 2 - be careful when warping
            }
        }

        //If less than 60s away from the manuever node, stop warp
        else if (runmode = 6) and eta:apoapsis < 60 {                              
            print "Throttling back warp             " AT (18,8). 
            set warp to 0.                                                          //warp to 0
            set runmode to 8.                                                       //initiate next runmode
        }
    }

            //If the ship is performing a correction burn and above targetApoapsis + 2.5%
    else if (runmode = 7) and (ship:apoapsis >= (targetApoapsis * 1.005)) {
        print "Correction burn complete         " at (18,8).
        set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).  //Pitch over gradually until levelling out to 0 degrees above target altitude 
        lock steering to heading( 90, targetPitch, 0). //Keeps the ship pointed forward
        set tVal to 0.0.                //Turns off the throttle
        set runmode to 6.               //De-escalates the runmode
    }

    else if runmode = 8 {   //Circulization burn
        print "Circularization burn             " at (18,8).                    //Print current status to display
        if (eta:apoapsis < 60) or (verticalSpeed < 0) {                         //If we're less than 10s from Apo or losing altitude
            set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).  //Pitch over gradually until levelling out to 0 degrees above target altitude
            lock steering to heading( 90, targetPitch, 0).                     //heading 90' due E, then target pitch, then roll to 0'
            set tVal to 1.                                                      //Set throttle to 100%
        }
        if (ship:periapsis > targetPeriapsis) or (ship:periapsis > targetPeriapsis * 0.999) { //If periapsis is high enough or getting close to the apoapsis
            print "Circularization burn complete!   " AT (18,8). //Clear status from screen
            set tVal to 0.                              //End the burn
            set runmode to 9.                           //Advance to runmode 9, which is the countdown to final runmode.
        }    
    }

    else if runmode = 9 {   //Initiates a 10s timer post-circularization burn before deploying panels and antenna, and returning control to player
        print "Cooldown timer - " + cooldown + "              " AT (18,8).
        set tVal to 0.                                              //Keep throttle off during countdown
        set cooldown to (cooldown - 1).                             //Increments the timer
        if cooldown < 1 {                                           //Increment runmode when timer complete
            set runmode to 10.
        }
    }

    else if runmode = 10 {  //Final runmode, preps ship for space
        print "Ship stable, prepping for user  "  at (18,8).
        set tVal to 0.                                  //Shutdown engine

        //Deploy bays
        for p in ship:partsdubbedpattern("bayDoor*") {

            set pModules to p:MODULES.
            for idx in range(0, pModules:length) {
                
                local m is p:getmodulesbyindex(idx).

                if m:name = "USAnimateGeneric" {
                    PRINT "Opening bay doors                " at (18,8).
                    m:DOACTION("deploy primary bays", true).
                }
            }
        }

        //Deploy all solar panels
        FOR p IN ship:partstaggedpattern("solar*") {

            SET pModules to p:MODULES.
            
            FOR idx IN RANGE(0, pModules:length) {

                LOCAL m IS p:GETMODULEBYINDEX(idx).

                IF m:name = "ModuleDeployableSolarPanel" {
                    PRINT ("Extending solar panels           ") at (18,8).
                    m:DOACTION("extend solar panel",TRUE).
                }
            }
        }

        //Deploy all antenna
        for p in ship:partstaggedpattern("omni-*") {
                
            set pModules to p:MODULES.

            for idx in range(0, pModules:length) {
                
                local m is p:getmodulesbyindex(idx).

                IF m:name = "ModuleRTAntenna" {
                    PRINT ("Extending antenna                ") at (18,8).
                    m:DOACTION("toggle",TRUE).
                }
            }
        }

        print "Ship stable, returning control   "  at (18,8).

        lights on.                                      //Turn on ship lights
        unlock steering.                                //Returns steering control to player
        print "Ship should now be in space!     " at (18,8).
        set runmode to 0.                               //Terminate program
    }
    
    //Run every loop//
    lock throttle to tVal.                              //Keep throttle locked to tVal

    //Staging
    //Ensure doesn't auto stage during countdown
    if launchCommit = 1 {
        if stage:Liquidfuel < 1 {                           //Stage if current stage is out of fuel
        print "Staging...                       " at (18,8).
        lock throttle to 0.                             //Throttle to 0
        wait 1.                                         //Wait 1s for coast
        stage.
        wait 2.                                         //Wait 2s for stage to clear
        lock throttle to tVal.                          //Return throttle to tVal to resume launch
        }
    }

    //Printout
    print "Kerbal's First Launch Program           v0.1b" at (0,2).
    print "=============================================" at (0,3).
    
    print "VESSEL:      " + shipName at (1,5).
    print "-------------------------------------------" at (1,6).
    print "STATUS:      " + status + "        " at (1,7).
    print "RUNMODE:     " + runmode + " -" at (1,8).
        
    print "ALTITUDE:    " + round(ship:altitude) + "    " at (2,12).
    print "APOAPSIS:    " + round(ship:apoapsis) + "    " at (2,13).
    print "PERIAPSIS:   " + round(ship:periapsis) + "    " at (2,14).
    
    print "TARGETAPO:   " + round(targetApoapsis) + "    " at (2,12).
    print "TARGETPER:   " + round(targetPeriapsis) + "    " at (2,13).
    print "TARGETINCL:  " + round(targetInclination) + "    " at (2,14).

    print "VELOCITY:    " + round(ship:airspeed) + "      " at (2,16).
    print "VERTSPEED:   " + round(ship:verticalSpeed) + "      " at (2,17).
    print "GRNDSPEED:   " + round(ship:groundspeed) + "      " at (2,18).

    print "HEADING:     " + round(ship:heading, 1) + "      " at (26,16).
    print "ROLLERROR:   " + round(steeringManager:rollerror, 3) + "       " at (26,17).
    print "PITCHERROR:  " + round(steeringManager:pitcherror, 3) + "       " at (26,18).

    print "DYNPRESSURE: " + round(ship:q, 5) + "    " at (2,21).
    print "AVLTHSTPRES: " + round(ship:availablethrustat(ship:q), 0.1) + "    " at (2,22).
    print "MASS:        " + round(ship:mass, 2) + "    " at (2,23).

}