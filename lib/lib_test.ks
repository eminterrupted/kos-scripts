@lazyGlobal off.

//-- Part testing functions --//

    // Displays engine characteristics during a test
    global function test_engine 
    {
        parameter p, 
                  dur is 15, 
                  line is 8.

        local tVal to 0.01.
        lock throttle to tVal.
        until dur <= 0 and p:thrust = 0 and tVal = 0
        {
            set tVal to choose min(1, tVal + 0.025) if dur > 0 else max(0, tVal - 0.05).
            local durStr to choose "Time Reminaing: " + round(dur, 1) + "s" if dur >= 0 else "Waiting for engine shutdown...".
            print durStr:padRight(terminal:width)                                              at (2, line).
            
            print "Engine Performance Data"                                                    at (2, line + 2).
            print "-----------------------"                                                    at (2, line + 3).
            print ("THROTTLE  : " + round(throttle * 100) + "%"):padRight(terminal:width)      at (2, line + 4).
            print ("SL THRUST : " + round(p:thrust, 2)):padRight(terminal:width)               at (2, line + 5).
            print ("SL ISP    : " + round(p:sealevelIsp, 2)):padRight(terminal:width)          at (2, line + 6).
            print ("VAC THRUST: " + round(p:availableThrustAt(0), 2)):padRight(terminal:width) at (2, line + 7).
            print ("VAC ISP   : " + round(p:vacuumIsp, 2)):padRight(terminal:width)            at (2, line + 8).
            print ("FUEL FLOW : " + round(p:fuelFlow, 5)):padRight(terminal:width)             at (2, line + 9).

            set dur to dur - 0.01.
            wait 0.01.
        }
        wait 2.5.
        p:shutdown.
        wait 3.
    }

    // Turns on / off any lights present
    global function test_lights
    {
        parameter state.

        if ship:partsDubbedPattern("cherry"):length > 0
        {
            for p in ship:partsDubbedPattern("cherry")
            {
                local m to p:getModule("ModuleLight").
                if state util_do_event(m, "lights on").
                else     util_do_event(m, "lights off").
            }
        }
    }

    // Check for the presence of a test module and action, else stage
    global function test_part
    {
        parameter p.

        if p:typeName = "engine"
        {
            stage.
            test_engine(p, 15).
        }
        else if p:hasModule("ModuleTestSubject") 
        {
            local m to p:getModule("ModuleTestSubject").
            if m:hasEvent("run test") 
            {
                m:doEvent("run test").
            }
            else
            {
                stage.
            }
        }
        else 
        {
            if stage:number > 0 stage.
        }
    }

    // Takes a module and displays test subject info
    global function test_part_info
    {
        parameter p.

        clearScreen.
        print "Test Controller v0.01b" at (2, 2).
        print "----------------------" at (2, 3).
        
        print ("Test Part    : " + p:title):padRight(terminal:width) at (2, 5).
        print ("Part NameId  : " + p:name):padRight(terminal:width) at (2, 6). 
        
        return 8.
    }

    // Toggles test stand generator
    global function test_stand_gen
    {
        parameter powerOn.

        local genList   to ship:modulesNamed("ModuleGenerator").
        local genOn     to "activate generator".
        local genOff    to "shutdown generator".
        for g in genList
        {
            if powerOn 
            {
                if g:hasEvent(genOn) g:doEvent(genOn).
            }
            else 
            {
                if g:hasEvent(genOff) g:doEvent(genOff). 
            }
        }
    }