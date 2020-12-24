@lazyGlobal off.

global function create_simple_orbit {
    parameter _tgtAp, 
              _tgtPe,
              _body is ship:body.

    local ecc to (_tgtAp + _body:radius) - (_tgtPe + _body:radius) / _tgtAp + _tgtPe + (_body:radius * 2).
    local sma to (_tgtAp + _tgtPe) + (_body:radius * 2) / 2. 

    local tgtObt is createOrbit(
    ship:orbit:inclination, 
    ecc,
    sma, 
    ship:orbit:longitudeOfAscendingNode,
    ship:orbit:argumentOfPeriapsis,
    ship:orbit:meanAnomalyAtEpoch,
    ship:orbit:epoch,
    _body).
    
    return tgtObt.
}