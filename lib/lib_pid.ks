@lazyGlobal off.

global function setup_pid {
    parameter pSetpoint,
              kP is 5.0,
              kI is 0.0,
              kD is 0.0,
              maxOutput is 1,
              minOutput is -1.

    global newPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set newPid:setpoint to pSetpoint.

    return newPid.
}