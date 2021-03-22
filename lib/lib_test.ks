@lazyGlobal off.

// Dependencies
//#include "0:/lib/lib_util"

//-- Part testing functions --//

    // Displays engine characteristics during a test
    global function test_engine 
    {
        parameter p, 
                  dur is 15, 
                  ln is 8.

        local engList to list().
        local tVal to 0.50.

        list engines in engList.
        lock throttle to tVal.

        stage.
        until dur <= 0 or (p:thrust <= 0.1 and dur <= 5) or tVal < 0.50
        {
            if dur > 0
            {
                set tVal to min(1, tVal + 0.025).
            }
            else
            {
                set tVal to max(0, tVal - 0.025).
            }

            local durStr to choose "Time Reminaing: " + round(dur, 1) + "s" if dur >= 0 else "Waiting for engine shutdown...".
            print durStr:padRight(terminal:width)                                              at (2, ln).
            
            print "Engine Performance Data"                                                    at (2, ln + 2).
            print "-----------------------"                                                    at (2, ln + 3).
            print ("THROTTLE  : " + round(throttle * 100) + "%"):padRight(terminal:width)      at (2, ln + 4).
            print ("SL THRUST : " + round(p:thrust, 2)):padRight(terminal:width)               at (2, ln + 5).
            print ("SL ISP    : " + round(p:sealevelIsp, 2)):padRight(terminal:width)          at (2, ln + 6).
            print ("VAC THRUST: " + round(p:availableThrustAt(0), 2)):padRight(terminal:width) at (2, ln + 7).
            print ("VAC ISP   : " + round(p:vacuumIsp, 2)):padRight(terminal:width)            at (2, ln + 8).
            print ("FUEL FLOW : " + round(p:fuelFlow, 5)):padRight(terminal:width)             at (2, ln + 9).

            set dur to dur - 0.1.
            wait 0.1.
        }
        for eng in engList
        {
            if eng:ignition 
            {
                eng:shutdown.
            }
        }
        unlock throttle.
        wait 1.
    }


    // Returns a list of parts tagged with test. Can take a list to add 
    // tagged parts to, defaults to a new list
    global function test_tagged_parts
    {
        parameter partList to list().

        for p in ship:partsTaggedPattern("test") 
        {
            partList:add(p).
        }
        return partList.
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


    // Toggles launchpad generator
    global function test_pad_gen
    {
        parameter powerOn.

        for g in ship:modulesNamed("ModuleGenerator")
        {
            if powerOn 
            {
                util_do_event(g, "activate generator").
            }
            else 
            {
                util_do_event(g, "shutdown generator").
            }
        }
    }


    // Check for the presence of a test module and action, else stage
    global function test_part
    {
        parameter p.

        if p:typeName = "engine"
        {
            test_engine(p).
        }
        else if p:hasModule("ModuleTestSubject") 
        {
            local m to p:getModule("ModuleTestSubject").
            if not util_do_event(m, "run test") 
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
        
        print ("Test Part  : " + p:title):padRight(terminal:width) at (2, 5).
        print ("Part NameId: " + p:name):padRight(terminal:width) at (2, 6). 
        
        return 8.
    }