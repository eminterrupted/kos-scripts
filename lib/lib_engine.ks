

global function set_throttle_twr {
    return true.
}

global function setup_t_pid {
    parameter pSetpoint.

    local kP is 0.05.
    local kI is 0.02.
    local kD is 0.01.
    local maxOutput is 1.
    local minOutput is 0.

    local pid is pidLoop(kP, kI, kD, minOutput, maxOutput).
    set pid:setpoint to pSetpoint.
    
    return pid.
}

global function set_throttle_g {
    return true.
}

global function shutdown_eng {
    parameter eng.
    if eng:ignition and eng:allowshutdown eng:shutdown().
}