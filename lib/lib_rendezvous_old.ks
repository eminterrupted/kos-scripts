// Returns the expected altitude for an orbit at a given true anomaly
global function orbit_altitude_at_ta 
{
    parameter _obtIn,   // Orbit to check
              _ta.      // True anomaly in degrees

    local sma is _obtIn:semiMajorAxis.
    local ecc is _obtIn:eccentricity.
    local r is sma * (1 - ecc^2) / (1 + ecc * cos(_ta)).

    return r - _obtIn:body:radius.
}

// Get the true anomaly of _obt0 where it crosses _obt1's altitude
// using a warmer / cooler algorithm. Specify the intended min/max
// epsilon of accuracy, as this is expensive. Returns -1 as flag to 
// indicate no crossing point.
global function orbit_cross_ta 
{
    parameter _obt0,        // Current orbit
              _obt1,        // Orbit to find intersect with
              _maxEpsilon,  // how coarse to search at first
              _minEpsilon.  // how fine to search before accepting answer

    local pe_ta_off is ta_offset( _obt0, _obt1).

    local incr is _maxEpsilon.
    local prev_diff is 0.
    local start_ta is _obt0:trueanomaly. // Start the search where the ship is
    local ta is start_ta.

    until ta > start_ta + 360 or abs(incr) < _minEpsilon 
    {
        local diff is orbit_altitude_at_ta(_obt0, ta) - orbit_altitude_at_ta(_obt1, pe_ta_off + ta).

        // if pos / neg signs of diff and prev_diff differ and neither are zero:
        if diff * prev_diff < 0 
        {
            // Then this is a hit, so we reverse direction and go slower
            set incr to - incr / 10.
        }

        set prev_diff to diff.

        set ta to ta + incr.
    }

    if ta > start_ta + 360 
    {
        return -1.  // We've checked the entire orbit with no hits
    } 
    else 
    {
        return mod(ta, 360).
    }
}


// How far ahead is _obt0's true anomaly measured from _obt1's in degrees?
global function ta_offset 
{
    parameter _obt0,
              _obt1.

    // _obt0 Pe longitude (relative to solar system)
    local pe_lng_0 is _obt0:argumentOfPeriapsis + _obt0:lan.

    // _obt1 Pe longitude (relative to solar system)
    local pe_lng_1 is _obt1:argumentOfPeriapsis + _obt1:lan.

    // how far ahead is obt0's TA measured from obt1's in degrees?
    return pe_lng_0 - pe_lng_1.
}


//Formats a target string as an orbitable object
global function orbitable 
{
    parameter _tgt.

    local vList to list().
    list targets in vList.

    for vs in vList 
    {
        if vs:name = _tgt 
        {
            return vessel(_tgt).
        }
    }
    
    return body(_tgt).
}


// How many degrees difference between ship and a target
global function target_angle 
{
    parameter _tgt.

    return mod(
        lng_to_degrees(orbitable(_tgt):longitude)
        - lng_to_degrees(ship:longitude) + 360,
        360
    ).
}