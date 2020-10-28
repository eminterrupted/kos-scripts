

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

    global tPid is pidLoop(kP, kI, kD, minOutput, maxOutput).
}

global function set_throttle_g {
    return true.
}
