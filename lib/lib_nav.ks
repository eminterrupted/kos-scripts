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

// Gets the phase angle to a target orbitable around a parent body
global function phase_angle
{
    parameter tgt.

    return mod(lng_to_degrees(tgt:longitude) - lng_to_degrees(ship:longitude) + 360, 360).
}

//#region -- Eccentricity
// Calculates the eccentricity of given ap, pe, and planet
global function util_ecc_calc
{
    parameter ap,
              pe,
              tgtBody is ship:body.

    return ((ap + tgtBody:radius) - (pe + tgtBody:radius)) / (ap + pe + (tgtBody:radius * 2)).
}

// Returns the desired apoapsis given a known periapsis and eccentricity
global function util_ap_for_pe_ecc 
{
    parameter pe,
              ecc,
              tgtBody is ship:body.

    return (((pe + tgtBody:radius) / (1 - ecc)) * (1 + ecc)) - tgtBody:radius.
}

// Returns the desired periapsis given a known apoapsis and eccentricity
global function util_pe_for_ap_ecc 
{
    parameter ap,
              ecc,
              tgtBody is ship:body.

    return (((ap + tgtBody:radius) / (1 + ecc)) * (1 - ecc)) - tgtBody:radius.
}
//#endregion