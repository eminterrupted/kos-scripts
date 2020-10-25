//PID Testing script from https://ksp-kos.github.io/KOS/tutorials/pidloops.html?highlight=pid
//Use with vessel PID Trainer 1
//For early tests this script will point the ship straight up and then 

declare parameter mode is "both", gSetpoint is 1.25, qSetpoint is 0.1.

clearScreen. 
set terminal:width to 50.
set terminal:height to 40.
set runmode to 1. 

//Check the mode and configure pid loop accordingly
if mode = "both" {
    set qWeight to 2.
    set gWeight to 2.
}

else if mode = "g" {
    set qWeight to 0.
    set gWeight to 2.
}

else if mode = "q" {
    set qWeight to 2.
    set gWeight to 0.
}

//Set pre-launch throttle / steering values
set minThr to 0.60.
set tVal to 1.
lock throttle to tVal.
set myCourse to heading(90,90,270).
lock steering to myCourse.

until runmode = 0 {

    //Create 2 pid loops and averages their outputs for throttle control prior to launch
    if runmode = 1 {
        
        //Setup the gForce pid loop
        set g to ship:body:mu / ship:body:radius ^ 2.
        lock accVec to ship:sensors:acc - ship:sensors:grav.
        lock gForce to accVec:mag / g.
        
        lock gP to gSetpoint - gForce. 
        set gI to 0.
        set gD to 0.

        set gP0 to gP. 

        //Deadband - flucuations smaller than this will not be recorded
        lock gDeadband to abs(gP) < 0.01.

        set gKp to 0.02.
        set gKi to 0.005.
        set gKd to 0.0025.

        lock gOutput to gKp * gP + gKi * gI + gKd * gD.


        //Setup dynPress loop - can reuse common variables from gforce loop 
        lock qP to qSetpoint - ship:q.
        set qI to 0.
        set qD to 0.

        set qP0 to qP.

        //Deadband
        lock qDeadband to abs(qP) < 0.001.

        set qKp to 2.6.
        set qKi to 0.02.
        
        set qKd to 0.04.

        lock qOutput to qKp * qP + qKi * qI + qKd * qD.
        
        //Average the two loops together with extra weighting towards the q loop for output
        lock dtVal to min( 0.05, max(-0.05, ( ( gWeight * gOutput) + ( qWeight * qOutput) / ( gWeight + qWeight)))).

        set t0 to time:seconds.

        set runmode to 2.   
    }
    
    //Launch
    else if runmode = 2 {
        stage.
        set runmode to 3.
    }


    //don't do anything until ship has reached above ground.
    else if runmode = 3 {
        if ship:altitude > 500 {
            set runmode to 4.
        }
    }

    //Now iterate over the pid loop for throttle control
    else if runmode = 4 {

        if ship:altitude <= 50000 {
            set dt to time:seconds - t0.

            if dt > 0 {

                if not gDeadband {
                        
                    //update gravity loop
                    set gI to gI + gP * dt.
                    set gD to ( gP - gP0) / dt.

                    //I-windup safeguard. If non-zero, limit Ki * I to [-1,1].
                    if gKi <> 0 {
                        set gI to min( 1.0 / gKi, max( -1.0 / gKi, gI)).
                    }
                }

                if not qDeadband {
                    
                    //update q loop
                    set qI to qI + qP * dt.                
                    set qD to ( qP - qP0) / dt. 

                    //I-windup safeguard
                    if qKi <> 0 {
                        set qI to min( 1.0 / qKi, max( -1.0 / qKi, qI)).
                    }
                }

                //update the throttle to the averaged value dtVal, with upper / lower throttle limits enforced.              
                set tVal to max( minThr, min( 1.0, tVal + dtVal)).

                //Storing used vals
                set gP0 to gP.
                set qP0 to qP.
                set t0 to time:seconds. 
            }
        } else {

            set tVal to 0.
            set runmode to 0.
        }

        print "GFORCE PID LOOP" at (2,18). 
        print "---------------" at (2,19).
        if gWeight > 0 {
            print "ACTIVE" at (2,20).
        }
        print "SETPOINT:  " + gSetpoint + "    " at (2,21).
        print "INPUT:     " + round(gforce, 4) + "    " at (2,22).
        print "OUTPUT:    " + round(gOutput, 4) + "    " at (2,23).
        
        print "P:         " + round(gP, 4) + "    " at (2,25).
        print "I:         " + round(gI, 4) + "    " at (2,26).
        print "D:         " + round(gD, 4) + "    " at (2,27).

        print "DYN-Q PID LOOP" at (25,18). 
        print "--------------" at (25,19).
        if qWeight > 0 {
            print "ACTIVE" at (25,20).
        }
        print "SETPOINT:  " + qSetpoint + "    " at (25,21).
        print "INPUT:     " + round(ship:q, 4) + "    " at (25,22).
        print "OUTPUT:    " + round(qOutput, 4) + "    " at (25,23).
        
        print "P:         " + round(qP, 4) + "    " at (25,25).
        print "I:         " + round(qI, 4) + "    " at (25,26).
        print "D:         " + round(qD, 4) + "    " at (25,27).
    }

    lock steering to myCourse.
    lock throttle to tVal.

    print "SHIP" at (2,2).
    print "----" at (2,3).
    print "NAME:      " + ship:name + "     "at (2,5).
    print "STAGENUM:  " + stage:number + "    " at (2,6).
    print "MODE:      " + mode + "      " at (2,7).
    print "WEIGHT:    " +  qWeight + "(q) / " + gWeight + "(g)    " at (2,8).
    print "ALTITUDE:  " + round(ship:altitude) + "     " at (2,9).

    print "THROTTLE" at (2,11).
    print "--------" at (2,12).
    print "TVAL:      " + round(tVal * 100, 2) + "     " at (2,14).
    print "DTVAL:     " + round(dtVal * 100, 3) + "      " at (2,15).

    wait 0.001.

}