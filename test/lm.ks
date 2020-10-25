//Launch monitoring script using info from https://www.youtube.com/watch?v=QBZUiuhJKZc&list=PLEpK8nolWr1rghS5cOEOL-JQ33h4CgPAP&index=2&t=0s
//Thia program will attach to a vessel launch and stage once to activate a launch. 
//Then it will will run the rest of the program like it was controlling the launch without actually controlling the vessel. 
//Useful for debugging. 


//
//--- Parameters ---//
//
parameter countdown is 10, 
          targetApoapsis is 130000, 
          targetPeriapsis is 130000, 
          targetInclination is 0.0, 
          turnEndAltitude is 50000.

//Enable runtime analysis
set config:stat to true.

clearScreen.
set terminal:width to 55.
set terminal:height to 40.


//
//--- Variables ---///
//

//gravity turn parameters
set gravityTurnAlt to turnEndAltitude / 20.     // Max altitude for gravity turn to begin
set gravityTurnVel to 100.      // Max velocity for gravity turn to begin

//vessel variables
set tVal to 0.
set tqVal to 0.
set launchCommit to 0.
set myTwr to 0.
set runmode to 5.
set targetPitch to 0.
set dynPressLimit to 0.135.
set startingAlt to round(alt:radar).
set sVal to heading(90,90,270).

//launch body variables
set atmosphereAltitude to body:atm:height.
set srfGravity to (constant:g * body:mass) / ( body:radius ^ 2 ).


//Time / counters
set cooldown to 10.
set counter0 to 0.
set counter1 to 0. 
set pidFlag to 0.
set preLaunchTimer to 5.
set lsCount to round(random() * 1).
set typeTime to 0.05.
set warpTs to 30. // How  many seconds before a manuever warp will stop.

//Other variables
set msg to "Script initialize".
    


//
//--- Functions ---///
//

global function check_heading {

    parameter refHdg is 90.
    declare local retHdg is 90.

    //Validate heading provided is within bounds
    if refHdg <= 360 and refHdg >= 0 {   
        set retHdg to refHdg.
    }

    //If hdg exceeds upper bounds, try to find the intended heading.
    else if refHdg > 360 { 
        from { local x is refHdg.} until x < 360 step { set x to x - 360.} do {
            set retHdg to x. 
            wait 0.001.
        }
    }
    
    else if refHdg < 0 {
        from { local x is refHdg.} until x > 0 step { set x to x + 360. } do {
            set retHdg to x.
            wait 0.001.
        }
    }

    return retHdg.
}.


//Get current heading


global function get_heading {    

    set retHdg to abs(ship:bearing).
    
    return retHdg.
}.


//Returns average isp for stage with optional thrust mode / stage select
global function get_isp {

    parameter mode is "current".
    parameter stageNum is stage:number.
    
    local curPres is ship:sensors:pres.
    local relThrust is 0.
    local shipParts is ship:parts.
    local stageThrust is get_thrust(mode).
    local thisIsp is 0.
    local thisThrust is 0.
    
    list engines in shipParts.

    for e in shipParts {

        if e:stage = stageNum {

            if mode = "available" or mode = "avail" or mode = "a" {
                set thisThrust to e:availableThrustAt(curPres).
                set thisIsp to e:ispAt(curPres).
            }
            
            else if mode = "current" or mode = "cur" or mode = "c" or mode = " " { 
                set thisThrust to e:thrust. 
                set thisIsp to e:isp.
            }

            else if mode = "max" or mode = "m" {
                set thisThrust to e:maxThrustAt(curPres).
                set thisIsp to e:ispAt(curPres).
            }

            else if mode = "possible" or mode = "pos" or mode = "p" {
                set thisThrust to e:possibleThrustAt(curPres).
                set thisIsp to e:ispAt(curPres).
            }   

            else if mode = "sealevel" or mode = "sea" or mode = "s" {
                set thisThrust to e:possibleThrustAt(body:atmostphere:seaLevelPressure).
                set thisIsp to e:seaLevelIsp.
            }

            else if mode = "vacuum" or mode = "vac" or mode = "v" {
                set thisThrust to e:possibleThrustAt(0.0).
                set thisIsp to e:vacuumIsp. 
            }

        set relThrust to relThrust + (thisThrust / thisIsp).
        }
    }

    return stageThrust / relThrust.
}.


//Returns mass of ship at a given stage
global function get_mass_at_stage {

    parameter stageNum is stage:number.

    local sumMass is 0.
    local shipParts is ship:parts.

    for p in shipParts {
        if p:stage <= stageNum {
            set sumMass to sumMass + p:mass. 
        }
    }

    return sumMass.
}.


//Set pitch by deviation from a reference pitch to ensure more gradual gravity turns and course corrections
global function get_pitch_for_altitude {

    parameter refPitch.
    parameter tgtAlt.
    
    declare local tgtPitch is 0.
    
    if refPitch < 0 {
        set tgtPitch to min( -( 90 * ( 1 - ship:altitude / tgtAlt)),  refPitch).
    }

    else if refPitch >= 0 {
        set tgtPitch to max( ( 90 * ( 1 - ship:altitude / tgtAlt)) , refPitch) .
    }
    
    return tgtPitch.
}.


//Set throttle with function to control by maxQ
global function get_throttle_by_q {

    if pidFlag = 0 {

        set thrPid to pidLoop( 1.0, 0, 0, 0.00, 0.40).
        set thrPid:setpoint to dynPressLimit. 
        
        set pidFlag to 1.
    } 
    
    return 1 + thrPid:update(time:seconds, ship:q). 
}.


//Returns thrust for stage, given optional mode and stage number
global function get_thrust {

    parameter mode is "current".
    parameter stageNum is stage:number.
    
    local curPres is ship:sensors:pres.
    local sumThrust is 0.
    local shipParts is ship:parts.
    list engines in shipParts.

    for e in shipParts {
        
        if e:stage = stageNum {
            
            if mode = "available" or mode = "avail" {
                set sumThrust to sumThrust + e:availableThrustAt(curPres).
            }

            else if mode = "current" or mode = "cur" { 
                set sumThrust to sumThrust + e:thrust.
            }

            else if mode = "max" {
                set sumThrust to sumThrust + e:maxThrust.
            }   

            else if mode = "possible" or mode = "pos" {
                set sumThrust to sumThrust + e:possibleThrustAt(curPres).
            }

            else if mode = "sealevel" or mode = "sea" {
                set sumThrust to sumThrust + e:possibleThrustAt(body:atm:seaLevelPressure). 
            }

            else if mode = "vacuum" or mode = "vac" {
                set sumThrust to sumThrust + e:maxThrustAt(0.0).
            }
        }
    }

    return sumThrust.
}.


//Returns Thrust / Weight Ratio for a given mode
global function get_twr {
    
    parameter mode is "current".
    parameter stageNum is stage:number.
    
    local stageThrust is get_thrust(mode).
    local shipMass is get_mass_at_stage(stageNum).
    
    return ( stageThrust / ( shipMass * srfGravity )).
}.


//Fun loading screen :) 
global function loading_screen {
    
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
    
    print "Loading complete!" at(1,1).
    wait 0.25.
}.


//Pre-flight check and confirmation screen.
global function pre_flight_check {
    
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
        print "GRAVITY TURN ALT:    " + round(gravityTurnAlt) + "    " at (2,12).
        print "GRAVITY TURN VEL:    " + round(gravityTurnVel) + "    " at (2,13).

        if preLaunchTimer >=1 {
            print "Press any key within " + preLaunchTimer + "s to abort " at (2,20).
            set preLaunchTimer to (preLaunchTimer - 1).

            wait 1.
            print "                                                    " at (2,20).
        }

        else {
            print "                                                    " at (2,20).
        }
    }
}.


//Sets ship to a known config prior to launch, and safes the runmode to "Vertical Ascent"
global function set_known_config {
    SAS off. 
    RCS off.
    lights off. 
    gear off.
}.


global function update_display {

    parameter string is "0".

    //update Mission Elapsed Time
    local metHour is floor(missionTime / 3600).
    local metMin is floor((missiontime / 60) - (metHour * 60)).
    local metSec is round(missionTime - (metHour * 3600 + metMin * 60)).

    //Clear screen every 60 times to avoid junk hanging around on screen if the spaces at the end of each line don't cover them.
    if counter0 >= 60 { 
        clearScreen. 
        set counter0 to 0.
        set counter1 to counter1 + 1. 
    } 
    
    else {
        set counter0 to counter0 + 1. 
        set counter1 to counter1 + 1. 
    }

    //update_display
    print "Kerbal's First Launch Monitoring Program          v0.1b" at (0,1).
    print "=======================================================" at (0,2).
    
    print "VESSEL:      " + shipName at (2,6).
    print "--------------------------------------------------" at (2,7).
    print "MET:         " + metHour + "h " + metMin + "m " + metSec + "s     " at (2,8).
    print "STATUS:      " + status + "        " at (2,9).
    print "RUNMODE:     " + runmode + " - " + msg + "                       " at (2,10).
        

    print "ALTITUDE:    " + round( ship:altitude) + "    " at (2,13).
    print "APOAPSIS:    " + round( ship:apoapsis) + "    " at (2,14).
    print "PERIAPSIS:   " + round( ship:periapsis) + "    " at (2,15).
    
    print "TARGETAPO:   " + round( targetApoapsis) + "    " at (26,13).
    print "TARGETPER:   " + round( targetPeriapsis) + "    " at (26,14).
    print "TARGETINCL:  " + round( targetInclination) + "    " at (26,15).


    print "DYNPRESSURE: " + round( ship:q, 5) + "    " at (2,17).
    print "VEL:         " + round( ship:airspeed) + "      " at (2,18).
    print "VERTSPEED:   " + round( ship:verticalSpeed) + "      " at (2,19).
    print "GRNDSPEED:   " + round( ship:groundspeed) + "      " at (2,20).
    
    print "TVAL:        " + round( ( tVal * 100), 1) + "%  " at (26,17).
    PRINT "TQVAL:       " + round( ( tqVal * 100), 1) + "%  " at (26,18).
    print "THRUST:      " + round( get_thrust(), 2) + "    " at (26,19).
    print "TWR:         " + round( get_twr(), 2) + "    " at (26,20).
    print "MASS:        " + round( ship:mass, 2) + "    " at (26,21).


    print "HEADING:     " + round( get_heading(), 1) + "      " at (2,22).
    print "ROLL:        " + round( ship:facing:roll, 1) + "     " at (2,23).
    print "PITCH:       " + round( ship:facing:pitch, 1) + "     " at (2,24).

    print "TARGETPITCH: " + round( targetPitch, 1) + "    " at (26,23).
    print "PITCHERROR:  " + round( steeringManager:pitcherror, 3) + "       " at (26,24).

    //Add custom log string if present
    if string <> "0" {
        print "LOG: " + string + "                      " at (2,30).
    }
}.



//
//---Begin program---///
//

    //loading screen
    loading_screen(lsCount).


    // update_display on screen describing desired orbital parameters
    clearScreen.
    print "Loading pre_flight_check.sys                        " at (0,2).
    wait 0.5.
    print "                                                  " at (0,2).
    pre_flight_check(). 


    //Puts the ship into a known config prior to launch.
    clearScreen.
    print "Loading set_known_config.sys                           " at (0,2).
    wait 0.5.
    print "                                                  " at (0,2).
    set_known_config().   


    print "Loading launchControl.sys                         " at (0,2).
    //Safe to vertical ascent program in case it's launched mid flight
    wait 1.
    set runmode to 5.
    
    //Check if ready to launch
    if round(alt:radar - startingAlt) <= 1 and (myTwr <= 0) {
        lock steering to sVal.
        set runmode to 1. 
    } 
    

//
//--- Main launch loop ---//
//

    //Step through each runmode until program reaches runmode 0 (which signals program termination)
    until runmode = 0 { 


        //Launch countdown
        if runmode = 1 {
            if countdown >= 1 {
                set msg to "Launch countdown (T - " + countdown + "s)".
                update_display().
                wait 1.
                set countdown to (countdown - 1).
            }

            else {
                set msg to "Launch countdown (T - " + countdown + "s)".
                update_display().
                set runmode to 2. 
            }
        }


        //Launch sequence
        else if runmode = 2 {
            set msg to "Launch sequence".
            set tVal to 1.0.                                      
            stage.
            wait 0.001.
            set runmode to 3.
        }
            

        //Launch verify
        else if runmode = 3 {
            set myTwr to get_twr().

            //if vehicle is lifting off
            if round(alt:radar - startingAlt) <= 5 and myTwr > 1.0 {
                set msg to "Liftoff!".
                set launchCommit to 1.
            }
            
            //else if the vehicle has cleared the tower
            else if round(alt:radar - startingAlt) >= 75 and myTwr > 1.0 and launchCommit = 1 {
                set msg to "Tower Cleared".                         
                set runmode to 4.                                 
            }

            //else if ship has not built enough thrust to lift off after 2s
            else if (alt:radar - startingAlt) < 75 and myTwr <= 1.0 and missionTime > 2 {
                set tVal to 0.0.                                        
                set msg to "ABORT!".                                    
                set launchCommit to 0.                                  
                set runmode to 99.                                      
            }
        }


        //Roll program
        else if runmode = 4 {                                       
            set msg to "Roll program".

            set sVal to heading(90,90,0).
            set tVal to 1.0.
            
            set runmode to 5.                                   
        }


        //Vertical ascent - straight up until either gravityTurn parameter is met
        else if runmode = 5 {                                  
            set msg to "Vertical ascent".

            set tVal to get_throttle_by_q().
            lock throttle to tVal.

            if ship:altitude >= gravityTurnAlt or ship:airspeed >= gravityTurnVel {                    
                set runmode to 6.   
            }
        }


        //Gravity turn
        else if runmode = 6 {   
            set msg to "Gravity turn". 

            //Update steering
            set targetPitch to get_pitch_for_altitude(5, turnEndAltitude).
            
            set sVal to heading(90, targetPitch, 0).        

            //Set throttle by dynamic pressure
            set tVal to get_throttle_by_q().
            lock throttle to tVal.

            //Target is met
            if ship:apoapsis >= targetApoapsis {                                
                set runmode to 7.
            }
        }


        //Coast to Apo
        else if runmode = 7 {   
            set msg to "Coasting to apoapsis".

            //If apo is low and correction needed
            if (ship:apoapsis <= (targetApoapsis * 0.999)) {            
                set targetPitch to get_pitch_for_altitude(0, targetApoapsis). 
                set sVal to heading(get_heading(), targetPitch, 0).
                wait 3.

                set runMode to 8.                               
            }

            //else if ship is in atmosphere and Apo meets requirement set to prograde to minimize drag
            else if (ship:altitude <= atmosphereAltitude ) and (ship:apoapsis >= targetApoapsis) {
                set sVal to prograde.
                set tVal to 0.0.                                       
            }

            //else if ship is out of the atmosphere and does not need correction
            else if (ship:altitude > atmosphereAltitude ) and (ship:apoapsis >= targetApoapsis) {
                set runMode to 9.                                      
            }  
        }


        //if ship is in atmosphere and Apo is below requirement, initiate a correction burn
        else if runmode = 8 {

            //Correction burn execute
            //If in atm and below target
            if (ship:altitude <=70000) and (ship:apoapsis < (targetApoapsis * 0.9995)) {     
                set msg to "Correction burn".
                
                set targetPitch to get_pitch_for_altitude(0, targetApoapsis). 
                set sVal to heading(get_heading(), targetPitch, 0).
                wait 3.

                set tVal to 0.05.                                                              //Keep throttle at 5%
            }

            else if ship:apoapsis >= (targetApoapsis * 1.0005) {                             //if target + buffer reached
                set msg to "Correction burn complete".

                set sVal to heading(get_heading(), targetPitch, 0).
                set tVal to 0.0.
                set runmode to 7.                                                               //De-escalates the runmode
            }
        }


        //If ship is out of atmosphere and on target, create manuever node for circularization burn and calculate how long the engines need to burn
        else if runmode = 9 { 
            
            set msg to "Calculating circularization burn".
            
            set targetPitch to get_pitch_for_altitude(0, targetPeriapsis).
            set sVal to heading(get_heading(), targetPitch, 0).
            set tVal to 0.0.

            //Calculate variables
            //set cbThrust to get_thrust("available").
            set cbIsp to get_isp("vacuum").
            //set cbTwr to get_twr("vacuum").
            set cbStartMass to get_mass_at_stage().
            set exhaustVelocity to (constant:g0 * cbIsp ). 
            set obtVelocity to sqrt(body:mu / (body:radius + targetPeriapsis )).
            update_display("CALCULATED ORBITAL VELOCITY:  " + obtVelocity + "  ").

            //calculate deltaV
            //From: https://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design
            set dV to ((sqrt(body:mu / (targetPeriapsis + body:radius))) * (1 - sqrt((2 * (ship:periapsis + body:radius)) / (ship:periapsis + targetPeriapsis + (2 * (body:radius)))))).
            
            //Calculate vessel end mass
            set cbEndMass to (1 / ((cbStartMass * constant:e) ^ (dV / exhaustVelocity))).  

            //Calculate time parameters for the burn
            set cbDuration to exhaustVelocity * ln(cbStartMass) - exhaustVelocity * ln(cbEndMass).
            set cbMarkApo to time:seconds + eta:apoapsis.
            set cbStartBurn to cbMarkApo - (cbDuration / 2).

            //create the manuever node
            set cbNode to node(cbMarkApo, 0, 0, dV).

            //Add to flight path
            add cbNode. 

            set runmode to 10.
        }


        //Warp initiate
        else if runmode = 10 {
            
            set tVal to 0.0. 

            //If more than burn start + 2x warpTs, warp
            if cbNode:eta > ( 2 * (warpTs) - (cbDuration / 2))  {
                wait 3.                                                                 
                
                set msg to "Initiating time warp".
                update_display().

                kuniverse:Timewarp:warpto(cbStartBurn - warpTs).
            }

            //If less than 50% + the warpTs value  away from the manuever node, stop warp
            else if cbNode:eta < (warpTs + (cbDuration / 2)) {                              
                set msg to "Throttling back warp". 
                set kuniverse:timewarp:warp to 0.
                update_display().

                set sVal to heading(get_heading(), targetPitch, 0).

                set runmode to 11.
            }
        }


        //Circularization burn
        else if runmode = 11 {

            //Start burn
            if (cbNode:eta < cbStartBurn) or (verticalSpeed < 0) {
                set msg to "Circularization burn".
                set targetPitch to get_pitch_for_altitude(0, targetPeriapsis).
                set sVal to heading(get_heading(), targetPitch, 0).
                set tVal to 1.0.                                                
            }
            
            //Complete burn
            if (ship:periapsis > targetPeriapsis) or (ship:periapsis > targetPeriapsis * 0.999) { 
                print "Circularization burn complete!". 
                set tVal to 0.0.                                         
                set runmode to 12.                                       
            }
        }


        else if runmode = 12 {   //Initiates a 10s timer post-circularization burn before deploying panels and antenna, and returning control to player
            set msg to "Stabilizing ship in " + cooldown + "s".
            update_display().

            set tVal to 0.0.                                            //Keep throttle off during countdown
            set cooldown to (cooldown - 1).                             //Increments the timer
            
            if cooldown < 1 {                                           //Increment runmode when timer complete
                set runmode to 13.
            }
        }


        else if runmode = 13 {  //Final runmode, preps ship for space
            set msg to "Ship stabilized".
            set runmode to 0.                               //Terminate program
        }


        //Abort
        if runmode = 99 {
            set msg to "ABORT!".
            set tVal to 0.0.                                //Kill throttle on abort
            set runmode to 0.
            update_display().
        }
        

        //Run every loop//

        //steering
        lock steering to sVal.

        //throttle
        //update thrPid every cycle as it's own variable to give the pidLoop more data points
        set tqVal to get_throttle_by_q(). 
        lock throttle to tVal.


        //Staging
        //Ensure doesn't auto stage during countdown
        if launchCommit = 1 and stage:Liquidfuel < 1 {                            //Stage if current stage is out of fuel
             set msg to "Staging...".

             update_display().
             lock throttle to 0.                             //Throttle to 0
             wait 0.5.                                         //Wait for coast
             stage.
             wait 1.5.                                         //Wait for stage to clear
             lock throttle to tVal.                          //Return throttle to tVal to resume launch
        }

        update_display().
    }