clearVecDraws().

local bodyPos to vecDraw(ship:position, body:position, cyan, "Body Position", 1, true).
local foreVec to vecDraw(ship:position, ship:obt:velocity:orbit, green, "Velocity", 15, true, 0.002).
local normVec to vecDraw(ship:position, vCrs(body:position, ship:obt:velocity:orbit), magenta, "Norm", 0.02 , true, 5).

set bodyPos:vecupdater to { return body:position. }.
set foreVec:vecupdater to { return ship:obt:velocity:orbit. }.
set normVec:vecupdater to { return vCrs(body:position, ship:obt:velocity:orbit). }.

clearScreen.

terminal:input:clear().

until terminal:input:haschar {
    print "Body Position Vector: " + body:position at (2, 5).
    print "Obt Velocity Vector:  " + ship:obt:velocity:orbit at (2, 6).
    print "Normal Vector:        " + vCrs(body:position, ship:obt:velocity:orbit) at (2, 7).
}

clearVecDraws().
clearScreen.