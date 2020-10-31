@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/display/gui/lib_gui.ks").

tag_parts_by_title(ship:parts).

local launchScript is "scout_1.ks".
local obtScript is "deploy_relsat.ks".
local tApo is "250000".
local tPe is "250000".
local tInc is "0".
local gravTurnAlt is "60000".
local refPitch is "3".

local lScriptList is get_launch_scripts().
local oScriptList is get_orbital_scripts().

local gui is gui(500).
local tabWidget is add_tab_widget(gui).

local page is add_tab(tabWidget, "Launch Script Params").
page:addLabel("Select launch parameters").

page:addLabel("Target Apoapsis").
local tfAp is page:addTextField(tApo).
set tfAp:onConfirm to { parameter ap. set tApo to ap.}.

page:addLabel("Target Periapsis").
local tfPe is page:addTextField(tPe).
set tfPe:onConfirm to { parameter pe. set tPe to pe.}.

page:addLabel("Target Inclination").
local inc is page:addTextField(tInc).
set inc:onConfirm to { parameter i. set tInc to i.}.

page:addLabel("Gravity Turn End Altitude").
local gta is page:addTextField(gravTurnAlt).
set gta:onConfirm to { parameter gt. set gravTurnAlt to gt.}.

page:addLabel("refPitch").
local rPitch is page:addTextField("3").
set rPitch:onConfirm to { parameter rp. set refPitch to rp.}.

local page is add_tab(tabWidget, "Launch Script").
page:addLabel("Select launch script").
local lScript is add_popup_menu(page,lScriptList).
set lScript:onchange to { parameter lChoice. set launchScript to lChoice:toString.}.

local page is add_tab(tabWidget, "Orbital Script").
page:addLabel("Select mission script for orbit").
local oScript is add_popup_menu(page,oScriptList).
set oScript:onchange to { parameter oChoice. set obtScript to oChoice:toString.}.

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
        
        print "Launch script selected:  " + launchScript + "         " at (2,18).
        print "Orbital script selected: " + obtScript + "         " at (2,19).

        print "Target Apoapsis:         " + tApo + "      " at (2,21).
        print "Target Periapsis:        " + tPe + "      " at (2,22).
        print "Target Inclination:      " + tInc + "      " at (2,23).
        print "Gravity Turn Altitude:   " + gravTurnAlt + "      " at (2,24).
        print "Gravity Turn End Pitch:  " + refPitch + "      " at (2,25).
}

gui:hide().

runPath("0:/launch.ks", launchScript, obtScript, tApo, tPe, tInc, gravTurnAlt, refPitch).