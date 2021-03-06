@lazyGlobal off.

//-- Dependencies --//

//-- Variables --//

//-- Functions --//

// Converts longitude into degrees
global function lng_to_degrees
{
    parameter lng.
    return mod(lng + 360, 360).
}

// Gets the phase angle between the current vessel and a target orbitable
global function phase_angle
{
    parameter tgt.

    return mod(lng_to_degrees(tgt:longitude) - lng_to_degrees(ship:longitude) + 360, 360).
}