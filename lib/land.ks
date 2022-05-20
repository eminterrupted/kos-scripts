@LazyGlobal off.

// Globals


// Functions

// Time to impact
global function TimeToImpact
{
    parameter currentVelocity,
              distance.

    local curVelocity  to -currentVelocity.
    local distToImpact to distance.
    local localGravity to ((ship:body:mu * (ship:mass * 1000)) / (ship:body:radius + ship:altitude)^2) /  (ship:mass * 1000). // Current gravity
    //local g to ship:body:mu / ship:body:radius^2. // Surface gravity
    return (sqrt(curVelocity^2 + 2 * (localGravity * distToImpact)) - curVelocity) / localGravity.
}