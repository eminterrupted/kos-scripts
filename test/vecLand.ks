parameter wp.

LOCAL surfGrav IS BODY:MU / BODY:RADIUS^2.  //surface gravity for current body
LOCAL throt IS 0.
LOCK THROTTLE TO throt.
LOCAL vecTar IS SHIP:FACING:VECTOR.  //initializing the target vector with the current facing vector of the ship
LOCK STEERING TO vecTar.
UNTIL FALSE {
    LOCAL faceVec IS SHIP:FACING:VECTOR.    // the direction the ship is facing

    LOCAL velVec IS SHIP:VELOCITY:SURFACE.  // velocity vector
    SET vdVelVec TO VECDRAW(v(0,0,0),velVec,RGB(1,1,0),"Velocity Vector",1,TRUE,0.1,TRUE).

    LOCAL tarVec IS wp:POSITION.        // vector to target
    SET vdTarVec TO VECDRAW(v(0,0,0),tarVec,RGB(1,0,0),"Target Vector",1,TRUE,0.1,TRUE).

    LOCAL accel IS (SHIP:AVAILABLETHRUST / SHIP:MASS - surfGrav) * 0.5 .// 1/2 ship's available acceleration minus gravity.
    LOCAL wantVelVec IS tarVec:NORMALIZED * SQRT(2 * tarVec:MAG * accel). // converting the distance to desired velocity using kinematic equation
      // normalizing a vector keeps it's direction but sets the length (magnitude) to 1
      // multiplying a vector by a number multiples it's magnitude by that number
    SET vdWantVelVec TO VECDRAW(v(0,0,0),wantVelVec,RGB(0,1,0),"Wanted Velocity Vector",1,TRUE,0.2,TRUE).

    LOCAL errorVec IS wantVelVec - velVec. // the difference between the wanted velocity and the current velocity
    SET vdErrorVec TO VECDRAW(velVec,errorVec,RGB(0,0,1),"Error Vector",1,TRUE,0.1,TRUE).

    IF VDOT(errorVec,velVec) < 0 { // a vector dot product (VDOT) is some what complicated
        SET vecTar TO errorVec.    // but in this if the result is negative then the 2 vectors are more than 90 degrees away from each other
    } ELSE {                       // which means that the desired velocity is less than the current velocity and as such can be used for steering input
        SET vecTar TO -errorVec.   // if the result is still positive then the desired velocity is larger than the current velocity so we will use the inverse for steering
    }
    SET throt TO VDOT(faceVec,errorVec) / accel.
                                        // in this case because the results of SHIP:FACING:VECTOR will always be have a magnitude of 1
                                        // the result of the VDOT will be how long the errorVec is along the faceVec axis
                                        // think of it as like measuring the vertical height of a tilted thing
                                        // but where the vector with a magnitude of 1 defines the "up" direction
                                        // The division by accel is because that represents what the throttle can do given an error
    WAIT 0.
}