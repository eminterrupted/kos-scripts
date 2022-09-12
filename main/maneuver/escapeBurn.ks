@LazyGlobal off.
ClearScreen.

parameter params is list().

// Dependencies
RunOncePath("0:/lib/loadDep").
RunOncePath("0:/lib/burnCalc").
RunOncePath("0:/lib/mnv").

DispMain(ScriptPath():name).

// Declare Variables


// Parse Params
// if params:length > 0 
// {
//   set foo to params[0].
// }

// Calculate retrograde velocity parallel to planet velocity

    // Get Body Velocity Vector and magnitude
    local vBody to Body:Orbit:Velocity:Orbit:Mag.
    print "vBody        : " + round(vBody, 2) at (0, 10).

    // Get velocity of transfer orbit at Body
    local vTransE to sqrt(body:body:mu * ((2 / GetTransferSma(Body:Orbit:SemiMajorAxis - 5000000000, Body:Orbit:SemiMajorAxis - (Ship:Orbit:SemiMajorAxis) / 2) - (1 / Body:Orbit:SemiMajorAxis)))).
    print "vTransE      : " + round(vTransE, 2) at (0, cr()).

    // Hyperbolic Escape Velocity
    local vHyp to abs(vTransE - vBody).
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
    //local dv1 to abs((vPe - (sqrt(Body:Mu / Ship:Orbit:SemiMajorAxis) / 2))).
    local dv1 to round(abs(vTransE - vBody)).
    print "dv1            : " + round(dv1, 2) at (0, cr()).
    cr().
    
    local lanVec to v(0, 0, 0).
    local argPeVec to v(0, 0, 0).
    local bodyVelocityTA to 0.

    if ship:orbit:inclination > 90 
    {
        set lanVec to { return solarPrimeVector * angleAxis(-ship:orbit:lan, v(0, 1, 0)). }.
        set argPeVec to { return lanVec() * angleAxis(-ship:orbit:argumentOfPeriapsis, v(0, 1, 0)). }.
        set bodyVelocityTA to mod(540 - vAng(argPeVec(), body:orbit:velocity:orbit), 360).
    }
    else
    {
        set lanVec to { return solarPrimeVector * angleAxis(-ship:orbit:lan, v(0, 1, 0)). }.
        set argPeVec to { return lanVec() * angleAxis(-ship:orbit:argumentOfPeriapsis, v(0, 1, 0)). }.
        set bodyVelocityTA to mod(360 - vAng(argPeVec(), body:orbit:velocity:orbit), 360).
    }

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
    wait 1.
    if not mnvNode:orbit:hasnextpatch 
    {
        set mnvNode to IterateMnvNode(mnvNode, "parentSoi", list(list(0, 0, 0, 1))).
        add mnvNode.
    }

    cr().
    print "Press Enter to begin node execution routine" at (0, cr()).
    print "Press End to terminate script" at (0, cr()).
    Terminal:Input:Clear.
    local _char to "".
    local doneFlag to false.
    until doneFlag
    {
        if Terminal:Input:HasChar
        {
            set _char to Terminal:Input:GetChar.
            if _char = Terminal:Input:Enter
            {
                ExecNodeBurn(mnvNode).
                set doneFlag to true.
            }
            else if _char = Terminal:Input:EndCursor
            {
                set doneFlag to true.
            }
            else
            {
                set _char to "".
            }
        }
    }

    print ScriptPath() + "complete!" at (0, cr()).

    local function IterateMnvNode
    {
        parameter mnv,
                  desiredResult,
                  iterationParams. // Nested list of maneuver node step values (i.e., list(list(0, 0, 0, 1), list(0, 0, 0, -1)))

        // Node needs to be on the flight plan for us to determine the results
        if not hasNode add mnv.

        // We want to escape the current body's SOI
        if desiredResult = "escSoi"
        {
            // If we are already escaping, just return true.
            if mnv:Orbit:HasNextPatch
            {
                return mnv.
            }
            else
            {
                // Loop through the iteration parameters
                until false
                {
                    for i in iterationParams
                    {
                        remove mnv. // Remove the mnv node to work with it
                        set mnv to node(mnv:Time + i[0], mnv:RadialOut + i[1], mnv:Normal + i[2], mnv:Prograde + i[3]). // Add the paramers to the node values
                        add mnv. // Add it again so we can see the results.
                        if mnv:Orbit:HasNextPatch 
                        {
                            remove mnv.
                            return mnv. // Return true if we've accomplished our mission.
                        }
                    }
                }
                // Return false if we've exhausted all iteration parameters and the loop bailed for some reason
                return false.
            }
        }
        else if desiredResult = "parentSoi"
        {
            // If we have a patch that already is in the sun's SOI, return true.
            local interPatch to GetInterceptPatchIndex(Ship:Body:Body). 
            if interPatch > -1 
            {
                return nextNode.
            }
            else
            {
                until false
                {
                    for i in iterationParams
                    {
                        remove mnv. // Remove the mnv node to work with it
                        set mnv to node(mnv:Time + i[0], mnv:RadialOut + i[1], mnv:Normal + i[2], mnv:Prograde + i[3]). // Add the paramers to the node values
                        add mnv. // Add it again so we can see the results.
                        DispMnvPatchList(mnv, 22).
                        set interPatch to GetInterceptPatchIndex(Ship:Body:Body, mnv:orbit).
                        if interPatch > -1
                        {
                            remove mnv.
                            return mnv.
                        }
                    }
                }
            }
        }
    }