@lazyGlobal off.

global function setup_tpid {
    parameter pSetpoint,
              kP is 5.0,
              kI is 0.0,
              kD is 0.0,
              maxOutput is 1,
              minOutput is -1.

    global tPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set tPid:setpoint to pSetpoint.
}

global function update_tpid {
    parameter pInput.

    return tPid:update(pInput).
}