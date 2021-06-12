@lazyGlobal off.

// Variables

// Global functions

// Time to impact
global function land_time_to_impact 
{
    parameter currentVelocity,
              distance.

    local v to -currentVelocity.
    local d to distance.
    local g to ((ship:body:mu * (ship:mass * 1000)) / (ship:body:radius + ship:altitude)^2) /  (ship:mass * 1000). // Current gravity
    //local g to ship:body:mu / ship:body:radius^2. // Surface gravity
    return (sqrt(v^2 + 2 * (g * d)) - v) / g.
}

// return srfRetrograde if verticalSpeed < 0, else up
global function land_srfretro_or_up
{
    if ship:verticalSpeed < 0 
    {
        return srfRetrograde.
    }
    else
    {
        return up.
    }
}