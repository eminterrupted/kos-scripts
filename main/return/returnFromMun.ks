@lazyGlobal off.
clearScreen.

parameter orientation is "pro-sun".

runOncePath("0:/lib/disp").
runOncePath("0:/lib/nav").
runOncePath("0:/lib/util").

DispMain(ScriptPath(), false).

// Calculate retrograde velocity parallel to planet velocity

    // Get Moon Velocity Vector and magnitude
    local vMoon to Body:Orbit:Velocity:Orbit:Mag.
    print "vMoon        : " + round(vMoon, 2) at (0, 10).
    // Get velocity of transfer orbit at Moon
    local vTransE to sqrt(body:body:mu * ((2 / GetTransferSma(Body:Body:Radius, Body:Orbit:SemiMajorAxis - (Ship:Orbit:SemiMajorAxis) / 2) - (1 / Body:Orbit:SemiMajorAxis)))).
    print "vTransE      : " + round(vTransE, 2) at (0, cr()).

    // Hyperbolic Escape Velocity
    local vHyp to abs(vTransE - vMoon).
    print "vHyp         : " + round(vHyp, 2) at (0, cr()).

    // Get Sma of hyperbolic escape trajectory
    local aHyp to ((2 / Body:SoiRadius)  - (vHyp^2 / Body:Mu)) ^(-1).
    print "aHyp         : " + round(aHyp) at (0, cr()).

    // Get velocity of our departure periapsis
    local vPe to sqrt(Body:Mu * ((2 / Body:Orbit:SemiMajorAxis) - (1 / aHyp))).
    print "vPe          : " + round(vPe, 2) at (0, cr()).

    // Get the departure angle parallel to the 
    local depAng to ArcCos(1 / (1 + ((Ship:Orbit:SemiMajorAxis * vHyp ^2) / Body:Mu))).
    print "Departure angle: " + round(depAng, 2) at (0, cr()).

    // DeltaV to burn at vPe
    local dv1 to abs((vPe - (sqrt(Body:Mu / Ship:Orbit:SemiMajorAxis) / 2))).
    print "dv1            : " + round(dv1, 2) at (0, cr()).
    cr().
    
    local lanVec to { return solarPrimeVector * angleAxis(-ship:orbit:lan, v(0, 1, 0)). }.
    local argPeVec to { return lanVec() * angleAxis(-ship:orbit:argumentOfPeriapsis, v(0, 1, 0)). }.

    local bodyVelocityTA to mod(360 - vAng(argPeVec(), body:orbit:velocity:orbit), 360).
    print "bodyVelocityTA : " + bodyVelocityTA at (0, cr()).

    local burnTA to mod(360 + bodyVelocityTA + depAng, 360).
    print "burnTA: " + burnTA at (0, cr()).

    //local burnPosVec to vecDraw(
    //    { return body:position.}, 
    //    { return burnVec() * ship:orbit:semiMajorAxis.}, 
    //    rgb(0, 1, 0), 
    //    "Burn Position Vector", 
    //    1.0, 
    //    true, 
    //    0.2
    //).

    local burnUTC to time:seconds + ETAtoTA(ship:orbit, burnTA).
    local mnvNode to node(burnUTC, 0, 0, dv1).
    add mnvNode.
    cr().
    print "Waiting indefinitely" at (0, cr()).
    until false
    {
        wait 1.
    }