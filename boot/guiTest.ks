@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/display/gui/lib_gui.ks").

tag_parts_by_title(ship:parts).

local gui is gui(500).
local tabWidget is add_tab_widget(gui).

local page is add_tab(tabWidget, "Launch Script").
page:addLabel("This is page 1").
page:addLabel("This is where we'll choose the script to use for launch").

local page is add_tab(tabWidget, "Launch Script Params").
page:addLabel("This is page 2").
page:addLabel("Params for launch script will go here").
page:addLabel("tApo").
page:addLabel("tPe").
page:addLabel("Incl").
page:addLabel("gravTurnAlt").
page:addLabel("refPitch").

local page is add_tab(tabWidget, "Orbital Script").
page:addLabel("This is page 3").
page:addLabel("This is where we will choose the script to use in orbit").

local close is gui:addButton("Close").

when True then {
        from { local x is 0.} until x >= tabWidget_alltabs:length step { set x to x+1.} do
        {
                // Earlier, we were careful to hide the panels that were not the current
                // one when they were added, so we can test if the panel is VISIBLE
                // to avoid the more expensive call to SHOWONLY every frame.
                if tabWidget_allTabs[x]:pressed and not (tabWidget_allPanels[x]:VISIBLE) {
                        tabWidget_allPanels[x]:parent:showonly(tabWidget_allPanels[x]).
                }
        }
        PRESERVE.
}

gui:show().
until close:pressed {
        wait(0).
        print "tabWidget_allPanels:length: " + tabWidget_allPanels:length at (2,4).
        print "tabWidget_alltabs:length:   " + tabWidget_allTabs:length at (2,5).

        print "Current tab presses: " at (2,7).
        print " Tab 1:   " + tabWidget_allTabs[0]:pressed + " " at (2,8).
        print " Panel 1: " + tabWidget_allPanels[0]:visible + " "at (2,9).

        print " Tab 2: " + tabWidget_allTabs[1]:pressed + " " at (2,11).
        print " Panel 2: " + tabWidget_allPanels[1]:visible + " " at (2,12).

        print " Tab 3: " + tabWidget_allTabs[2]:pressed + " " at (2,14).
        print " Panel 3: " + tabWidget_allPanels[2]:visible + " " at (2,15).
}

gui:hide().