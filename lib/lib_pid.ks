@lazyGlobal off.

global function setup_q_pid {
    parameter pSetpoint,
              kP is 5.0,
              kI is 0.0,
              kD is 0.0,
              maxOutput is 1,
              minOutput is -1.

    local newPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set newPid:setpoint to pSetpoint.

    return newPid.
}

global function setup_acc_pid {
    parameter pSetpoint,
              kP is 0.02,
              kI is 0.00,
              kD is 0.00,
              maxOutput is 0.25,
              minOutput is -0.25.

    local newPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set newPid:setpoint to pSetpoint.

    return newPid.
}

global function setup_alt_pid {
    parameter pSetpoint, 
              kP is 0.05,
              kI is 0.01,
              kD is 0.1,
              maxOutput is 1,
              minOutput is 0.

    local newPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set newPid:setpoint to pSetpoint.

    return newPid.
}

global function setup_vspeed_pid {
    parameter pSetpoint, 
              kP is 0.05,
              kI is 0.02,
              kD is 0.01,
              maxOutput is 1,
              minOutput is 0.

    local newPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set newPid:setpoint to pSetpoint.

    return newPid.
}