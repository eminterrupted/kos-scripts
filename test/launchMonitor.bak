//Launch monitoring script using info from https://www.youtube.com/watch?v=QBZUiuhJKZc&list=PLEpK8nolWr1rghS5cOEOL-JQ33h4CgPAP&index=2&t=0s
//Thia program will attach to a vessel launch and stage once to activate a launch. 
//Then it will will run the rest of the program like it was controlling the launch without actually controlling the vessel. 
//Useful for debugging. 

//Parameters to pass in - countdown timer, targetApo, targetPer
parameter countdown is 10, 
          targetApoapsis is 100000, 
          targetPeriapsis is 100000, 
          targetInclination is 0.0, 
          turnEndAltitude is 50000.

set config:stat to true.

clearScreen.
set terminal:width to 60.
//set terminal:height to 40.

//Variables
    //gravity turn parameters
    set gravityTurnAlt to turnEndAltitude / 20.     // Max altitude for gravity turn to begin
    set gravityTurnVel to 100.      // Max velocity for gravity turn to begin

    //vessel variables
    set tVal to 0.
    set launchCommit to 0.
    set twr to 0.
    set runmode to 5.
    set targetPitch to 0.

    //launch body variables
    set atmAlt to body:atm:height.
    set srfGravity to (constant:g * body:mass) / ( body:radius ^ 2 ).


    //Time / counters
    set cooldown to 10.
    set counter0 to 0.
    set counter1 to 0. 
    set preLaunchTimer to 3.
    set cooldown to round(random() * 3).
    set typeTime to 0.05.
    
//functions

//Sets ship to a known config prior to launch, and safes the runmode to "Vertical Ascent"
global function knownConfig {
    //Set ship to known configuration
    SAS off. 
    RCS off.
    lights off. 
    gear off.
    set targetPitch to 0.
}

//Fun loading screen :) 
global function loadingScreen {
    
    declare parameter loopNum is 1.

    until loopNum <= 0 {
        
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

        print "Loading " at(1,1).
        wait typeTime.

        print "Loading t" at(1,1).
        wait typeTime.

        print "Loading te" at(1,1).
        wait typeTime.

        print "Loading tes" at(1,1).
        wait typeTime.

        print "Loading test" at(1,1).
        wait typeTime.

        print "Loading test " at(1,1).
        wait typeTime.

        print "Loading test p" at(1,1).
        wait typeTime.

        print "Loading test pr" at(1,1).
        wait typeTime.

        print "Loading test pro" at(1,1).
        wait typeTime.

        print "Loading test prog" at(1,1).
        wait typeTime.

        print "Loading test progr" at(1,1).
        wait typeTime.

        print "Loading test progra" at(1,1).
        wait typeTime.

        print "Loading test program" at(1,1).
        wait typeTime.

        print "Loading test program." at(1,1).
        wait typeTime.

        print "Loading test program.." at(1,1).
        wait typeTime.

        print "Loading test program..." at(1,1).
        wait 1.25.

        print "                       " at(1,1).
        wait 1.
        
        set loopNum to ( loopNum - 1 ).

    }
}.

global function preFlightCheck {
    
    until preLaunchTimer = 0 { 

        //Pre-launch check screen
        print "Kerbal's First Launch Monitoring Program          v0.1b" at (0,1).
        print "=======================================================" at (0,2).
               
        print "VESSEL:  " + shipName at (1,5).
        print "--------------------------------------------------" at (1,6).
        
        print "COUNTDOWN:           " + countdown + "   " at (2,8).
        print "TARGET APOAPSIS:     " + round(targetApoapsis) + "    " at (2,9).
        print "TARGET PERIAPSIS:    " + round(targetPeriapsis) + "    " at (2,10).
        print "TARGET INCLINATION:  " + round(targetInclination) + "    " at (2,11).
        print "GRAVITY TURN ALT:    " + round(targetApoapsis) + "    " at (2,12).
        print "GRAVITY TURN VEL:    " + round(targetPeriapsis) + "    " at (2,13).

        if preLaunchTimer >= 1 {
            print "Press Ctrl-C within " + preLaunchTimer + "s to abort " at (2,20).
            set preLaunchTimer to (preLaunchTimer - 1).
            wait 1.
            print "                                                    " at (2,20).
        }

        else {
            print "                                                    " at (2,20).
        }
    }
}.

global function getTwr {
    
    local curThrust is 0. 
    local curTwr is 0.
    local pStage is ship:parts. 

    list engines in pStage.

    for e in pStage {

        if e:stage = stage:number {
            set curThrust to curThrust + e:thrust.
        }
    }
    
    set curTwr to ( curThrust / ( ship:wetmass * srfGravity )).

    print "CURRENTTWR:         " + curTwr at (2,33).
    print "CURRENTTHRUST:      " + curThrust at (2,34). 

    return curTwr. 
}.

global function updateDisplay {

    //Clear screen every 30 times to avoid junk hanging around on screen if the spaces at the end of each line don't cover them.
    if counter0 >= 30 { 
        clearScreen. 
        set counter0 to 0.
        set counter1 to counter1 + 1. 
    } 
    
    else {
        set counter0 to counter0 + 1. 
        set counter1 to counter1 + 1. 
    }

    //update Mission Elapsed Time
    local metHour is floor(missionTime / 3600).
    local metMin is floor((missiontime - (metHour * 3600) / 60)).
    local metSec is round(missionTime - (metHour * 3600) - (metMin * 60)).

    //updateDisplay
    print "Kerbal's First Launch Monitoring Program          v0.1b" at (0,1).
    print "=======================================================" at (0,2).
    
    print "VESSEL:      " + shipName at (1,5).
    print "--------------------------------------------------" at (1,6).
    print "MET:         " + metHour + "h " + metMin + "m " + metSec + "s     " at (1,7).
    print "STATUS:      " + status + "        " at (1,8).
    print "RUNMODE:     " + runmode + " - " + msg + "                       " at (1,9).
        

    print "ALTITUDE:    " + round(ship:altitude) + "    " at (2,12).
    print "APOAPSIS:    " + round(ship:apoapsis) + "    " at (2,13).
    print "PERIAPSIS:   " + round(ship:periapsis) + "    " at (2,14).
    
    print "TARGETAPO:   " + round(targetApoapsis) + "    " at (26,12).
    print "TARGETPER:   " + round(targetPeriapsis) + "    " at (26,13).
    print "TARGETINCL:  " + round(targetInclination) + "    " at (26,14).


    print "DYNPRESSURE: " + round(ship:q, 5) + "    " at (2,16).
    print "VEL:         " + round(ship:airspeed) + "      " at (2,17).
    print "VERTSPEED:   " + round(ship:verticalSpeed) + "      " at (2,18).
    print "GRNDSPEED:   " + round(ship:groundspeed) + "      " at (2,19).
    
    print "TVAL:        " + round((tVal * 100),1) + "%  " at (26,16).
    print "AVLTHSTPRES: " + round(ship:availablethrustat(ship:q), 0.1) + "    " at (26,17).
    print "TWR:         " + round( getTwr() ) + "    " at (26,18).
    print "MASS:        " + round(ship:mass, 2) + "    " at (26,19).


    print "HEADING:     " + round(ship:facing:forevector:x) + "      " at (2,21).
    print "ROLLVAL:     " + round(ship:facing:forevector:z) + "     " at (2,22).
    print "ROLLERROR:   " + round(steeringManager:rollerror, 3) + "       " at (2,23).
    print "TARGETPITCH: " + round(targetPitch, 1) + "   " at (2,24).
    print "PITCHERROR:  " + round(steeringManager:pitcherror, 3) + "       " at (2,25).

}.


//Begin program

    //loading screen
    loadingScreen(cooldown).

    // updateDisplay on screen describing desired orbital parameters
    clearScreen.
    print "Loading preFlightCheck.sys                        " at (0,2).
    wait 0.5.
    print "                                                  " at (0,2).
    preFlightCheck(). 

    //Puts the ship into a known config prior to launch.
    clearScreen.
    print "Loading knownConfig.sys                           " at (0,2).
    wait 0.5.
    print "                                                  " at (0,2).
    knownConfig().   

    //Safe to vertical ascent program in case it's launched mid flight
    set runmode to 5. 

    //Check if ready to launch
    if (alt:radar < 25) and (twr <= 0) { //Guess if we are waiting for takeoff 
        set runmode to 1. 
        } 
    
    until runmode = 0 { //Main launch loop - step through each runmode until program reaches runmode 0 (which signals program termination)

        if runmode = 1 {
            if countdown >= 1 {
                set msg to "xLaunch countdown (T - " + countdown + "s)".
                updateDisplay().
                wait 1.
                set countdown to (countdown - 1).
            } 
            else {
                set msg to "xxxLaunch countdown (T - " + countdown + "s)".
                updateDisplay().
                set runmode to 2.                           //initiate launch routine
            }

        }

        //Launch sequence - stages the rocket, initiating launch, before handing off to next runmode
        if runmode = 2 {

            set msg to "Launch sequence".
            updateDisplay().
            set tVal to 1.                                              //Throttle up to 100% 
            set twr to getTwr().
            print"twr: " + twr at (2,30).

            stage. 

            //If current TWR is greater than 1.0, launch the ship
            if twr > 1.0 {
                set launchCommit to 1.                                  //Triggers the "go for launch" flag
                set runmode to 3.                                       //Vehicle is released, go to next runmode
                print "runmode set to 3  " at (2,31).
            }

            // else, abort
            else {
                set launchCommit to 0.                                  //Forces the no-go for launch flag to safe further staging.
                set runmode to 99.                                      //Triggers runmode that powers abort sequence
            }
        }

        //Launch verify - if alt is between 0-75m, TWR is greater than 1, and mission time is greater than / equal 2, signal clock is running, else abort
        if runmode = 3 {
            
            set twr to getTwr().

            if alt:radar < 75 and missionTime >= 2 and twr > 1.0 {                //Until we clear the tower
                set msg to "Clock is running".
                //lock steering to heading (90,90,270).                 // Keep current steering
                set defRTF to steeringManager:rolltorquefactor.       // Dumps existing default roll torque factor to restore after roll program is complete
                //set steeringManager:rolltorquefactor to .50.          // Sets the RTF to 50% to ensure a nice gradual roll program.
            } 
            
            else if alt:radar >= 75 {                               //Once tower is cleared, move on to runmode 4
                set runmode to 4.
                print "runmode set to 4 " at (2,31).
            }
        }

        if runmode = 4 {                                       //Initiate the roll program
            set msg to "Roll program".

            set tVal TO 1.                                            //Throttle stays at 100% throughout liftoff and roll program

            if ship:altitude < 500 {
                //set lock steering to heading(90,90,0).                // Initiates roll program
            }

            else {
                //set steeringManager:rolltorquefactor to defRTF.       // restore RTF
                set runmode to 5.
            }
        }

        if runmode = 5 {                       //Continue vertical ascent
            set msg to "Vertical ascent".
            //lock steering to heading(90,90,0).                      //Steering control

            if ship:altitude > gravityTurnAlt {                     //When ship reaches 3500m in altitude 
                set runmode to 6.                                   //initiate next runmode
            }
            else if ship:airspeed >= gravityTurnVel {               //Else, if ship is travelling at faster than 125m/s 
                set runmode to 6.                                   //initiate next runmode
            }
        }

        if runmode = 6 {   //Gravity turn
            set msg to "Gravity turn". 
            set targetPitch to max( 3, 90 * (1 - alt:radar / 50000 )).                          //Pitch over gradually until levelling out to 3 degrees above 50 km. 
                                                                                                //Value of pitch is current altitude divided by horizontal altitude, substracted from 1 to make a decreasing number, multiplied by 90 to get degrees)
            //lock steering to heading( 90, targetPitch, 0)                                       //heading 90' due E, then target pitch, then roll to 0'
            set tVal to 1.                                                                //Keep throttle at 100%

            if ship:apoapsis >= targetApoapsis {                                                //when ship reaches apoapsis
                set runmode to 7.                                                               //set to next runmode
            }
        }

        if runmode = 7 {   //Coast to Apo
            set msg to "Coasting to apoapsis".

            //check to see if ship needs correction burn first
            if (ship:apoapsis <= (targetApoapsis * 0.999)) {
                set runMode to 8.
            }

            //else if ship is in atmosphere and Apo meets requirement, turn off engine
            else if (ship:altitude <= atmAlt ) and (ship:apoapsis >= targetApoapsis) {
                set targetPitch to ship:prograde:pitch.                                         //While in the atmosphere and coasting, set the pitch to prograde to minimize drag
                //lock steering to heading( 90, targetPitch, 0).                                  //Keeps the ship pointed forward
                set tVal to 0.0.                                                                //Keep throttle at 0%
            }

            else if (ship:altitude > atmAlt ) and (ship:apoapsis >= targetApoapsis) {
                set targetPitch to ship:prograde:pitch. 
                //lock steering to heading(90, targetPitch, 0).
                set tVal to 0.0.
                set runMode to 9.                                                               //next runmode is 
            }

            //if ship is in atmosphere and Apo is below requirement, initiate a correction burn
        if runmode = 8 {
            if (ship:altitude <=70000) and (ship:apoapsis < (targetApoapsis * 0.999)) {
            
            set msg to "Correction burn".

            set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).              //Pitch over gradually until levelling out to 0 degrees above target altitude 
            //lock steering to heading( 90, targetPitch, 0) " at (2,30).                    //Keeps the ship pointed forward
            set tVal to 0.05.                                                               //Keep throttle at 5%
            }

            else if ship:apoapsis >= (targetApoapsis * 1.005) {
            set msg to "Correction burn complete".
            set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).  //Pitch over gradually until levelling out to 0 degrees above target altitude 
            //lock steering to heading( 90, targetPitch, 0). //Keeps the ship pointed forward
            set tVal to 0.0.                //Turns off the throttle
            set runmode to 7.               //De-escalates the runmode
            }
        }


        //If ship is out of atmosphere and on target, create manuever node for circularization burn
        if runmode = 9 { 
            
            if warp = 0 {                                                           //if we are not already time warping
            set msg to "Calculating circularization burn".
            
            set stageParts to parts:stage.
            set eng to { list engines in stageParts.}.
            //set circPro to ().     //Calculates the dV required for a circularization burn at Apo
            //set circNode to node((time:seconds + eta:apoapsis), 0, 0, circPro).           //Creates the manuever node for the circularization burn
            
            set runmode to 10.
            }

            else if warp > 0 {
                set warp to 0.
            }
        }
        
        //Warp initiate
        if runmode = 10 {
            if eta:apoapsis > 120 {
                wait 1.                                                                  //wait to make sure ship is stable
                set msg to "Initiating time warp".
                //set warp to 2.                                                          //Warp setting 2 - be careful when warping
                }

            //If less than 60s away from the manuever node, stop warp
            else if eta:apoapsis <= 120 {                              
                set msg to "Throttling back warp". 
                //set warp to 0.                                                          //warp to 0
                set runmode to 11.                                                       //initiate next runmode
            }
        }

        //Circulization burn
        if runmode = 11 {
            if (eta:apoapsis < 60) or (verticalSpeed < 0) {                             //If we're less than 10s from Apo or losing altitude
                set msg to "Circularization burn".
                set targetPitch to (90 * ( 0 - ship:altitude / targetPeriapsis )).      //Pitch over gradually until levelling out to 0 degrees above target altitude
                //lock steering to heading( 90, targetPitch, 0).                          //heading 90' due E, then target pitch, then roll to 0'
                set tVal to 1.                                                          //Set throttle to 100%
            }
            
            if (ship:periapsis > targetPeriapsis) or (ship:periapsis > targetPeriapsis * 0.999) { //If periapsis is high enough or getting close to the apoapsis
                print "Circularization burn complete!". 
                set tVal to 0.                              //End the burn
                set runmode to 12.                           //Advance to runmode 9, which is the countdown to final runmode.
            }    
        }

        if runmode = 12 {   //Initiates a 10s timer post-circularization burn before deploying panels and antenna, and returning control to player
            set msg to "Cooldown timer - " + cooldown + "              ".

            set tVal to 0.                                              //Keep throttle off during countdown
            set cooldown to (cooldown - 1).                             //Increments the timer
            if cooldown < 1 {                                           //Increment runmode when timer complete
                set runmode to 13.
            }
        }

        if runmode = 13 {  //Final runmode, preps ship for space
            set msg to "Ship stable, prepping for user".
            set tVal to 0.                                  //Shutdown engine

            //Deploy all solar panels
            for p in ship:partstaggedpattern("lv-solar*") {

                set pMod to p:modules.
                
                for idx in range(0, pMod:length) {

                    local m is p:getmodulesbyindex(idx).

                    if m:name = "ModuleDeployableSolarPanel" {
                        set msg to "Extending solar panels".
                        updateDisplay().
                        m:doaction("extend solar panel",true).
                    }
                }
            }

            //Deploy all antenna
            for p in ship:partstaggedpattern("lv-comm-*") {
                    
                set pModules to p:MODULES.

                for idx in range(0, pModules:length) {
                    
                    local m is p:getmodulesbyindex(idx).

                    IF m:name = "ModuleRTAntenna" {
                        set msg to "Extending antenna".
                        updateDisplay().
                        m:doaction("toggle",TRUE).
                    }
                }
            }

            //lights on.                                      //Turn on ship lights
            //unlock steering.                                //Returns steering control to player

            set msg to "Ship stabilized".

            set runmode to 0.                               //Terminate program
        }

        //Abort
        if runmode = 99 {
            set msg to "ABORT!".
            set tVal to 0.0.                                //Kill throttle on abort
            set runmode to 0.
            updateDisplay().
        }
        
        //Run every loop//
        //lock throttle to tVal.                              //Keep throttle locked to tVal

        //Staging
        //Ensure doesn't auto stage during countdown
        if launchCommit = 1 {
            if stage:Liquidfuel < 1 {                           //Stage if current stage is out of fuel
            
            set msg to "Staging...".

            updateDisplay().
            //lock throttle to 0.                             //Throttle to 0
            wait 0.5.                                         //Wait for coast
            //stage.
            wait 1.5.                                         //Wait for stage to clear
            //lock throttle to tVal.                          //Return throttle to tVal to resume launch
            }
        }

        //Generate the updateDisplay
        updateDisplay().

    }
}

//log profileResult() to "0:/launchMonitor_HungLoop_full.csv".