@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/display/gui/lib_gui.ks").

tag_parts_by_title(ship:parts).

local cache is "0:/data/launchSelectCache.txt".
local cacheObj is lexicon().

local launchScript is "scout_1.ks".
local missionScript is "deploy_sat.ks".
local tApo is "250000".
local tPe is "250000".
local tInc is 0.
local gravTurnAlt is 60000.
local refPitch is 3.

if exists(cache) {
        local cacheObj is readJson(cache).

        if cacheObj:hasKey("launchScript") set launchScript to cacheObj["launchScript"]:toString.
        if cacheObj:hasKey("missionScript") set missionScript to cacheObj["missionScript"]:toString.
        if cacheObj:hasKey("tApo") set tApo to cacheObj["tApo"].
        if cacheObj:hasKey("tPe") set tPe to cacheObj["tPe"].
        if cacheObj:hasKey("tInc") set tInc to cacheObj["tInc"].
        if cacheObj:hasKey("gravTurnAlt") set gravTurnAlt to cacheObj["gravTurnAlt"].
        if cacheObj:hasKey("refPitch") set refPitch to cacheObj["refPitch"].
}

local lScriptList is get_launch_scripts().
local mScriptList is get_mission_scripts().

local gui is gui(500).
local tabWidget is add_tab_widget(gui).

local page is add_tab(tabWidget, "Launch Script Params").
page:addLabel("Select launch parameters").

page:addLabel("Target Apoapsis").
local tfAp is page:addTextField(tApo:toString).
set tfAp:onConfirm to { parameter ap. set tApo to round(ap:toNumber). set cacheObj["tApo"] to tApo. }.

page:addLabel("Target Periapsis").
local tfPe is page:addTextField(tPe:toString).
set tfPe:onConfirm to { parameter pe. set tPe to round(pe:toNumber). set cacheObj["tPe"]to tPe. }.

page:addLabel("Target Inclination").
local inc is tInc.
local incLabel is page:addLabel(round(inc):tostring).
local inc is page:addHSlider(inc, -180, 180).
set inc:onChange to { parameter i. set tInc to round(i). set cacheObj["tInc"] to tInc. set incLabel:text to tInc:tostring. }.

page:addLabel("Gravity Turn End Altitude").
local gta is gravTurnAlt.
local gtaLabel is page:addLabel(round(gta):toString).
local gta is page:addHSlider(gta, 45000, 70000).
set gta:onChange to { parameter a. set gravTurnAlt to round(a). set cacheObj["gravTurnAlt"] to gravTurnAlt. set gtaLabel:text to gravTurnAlt:toString.}.

page:addLabel("refPitch").
local rp is refPitch.
local rpLabel is page:addLabel(round(rp,1):tostring).
local rp is page:addHSlider(rp, 0, 10).
set rp:onChange to { parameter p. set refPitch to round(p, 1). set cacheObj["refPitch"] to refPitch. set rpLabel:text to refPitch:tostring.}.

local page is add_tab(tabWidget, "Launch Script").
page:addLabel("Select launch script").
local lScript is add_popup_menu(page,lScriptList).
set lScript:onchange to { parameter lChoice. set launchScript to lChoice:toString. set cacheObj["launchScript"] to launchScript.}.

local page is add_tab(tabWidget, "Mission Script").
page:addLabel("Select mission script for post-launch").
local mScript is add_popup_menu(page,mScriptList).
set mScript:onchange to { parameter mChoice. set missionScript to mChoice:toString. set cacheObj["missionScript"] to missionScript.}.

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
local tStamp is time:seconds + 30.
local closeGui is false.
until closeGui = true {
        wait(0).

        print "remaining time: " + round(tStamp - time:seconds) + "    " at (2,2).
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
        print "Mission script selected: " + missionScript + "         " at (2,19).

        print "Target Apoapsis:         " + tApo + "      " at (2,21).
        print "Target Periapsis:        " + tPe + "      " at (2,22).
        print "Target Inclination:      " + tInc + "      " at (2,23).
        print "Gravity Turn Altitude:   " + gravTurnAlt + "      " at (2,24).
        print "Gravity Turn End Pitch:  " + refPitch + "      " at (2,25).

        if time:seconds > tStamp set closeGui to true.
        if close:pressed set closeGui to true.
}

gui:hide().

set cacheObj["launchScript"] to launchScript.
set cacheObj["missionScript"] to missionScript.
set cacheObj["tApo"] to tApo.
set cacheObj["tPe"] to tPe.
set cacheObj["tInc"] to tInc.
set cacheObj["gravTurnAlt"] to gravTurnAlt.
set cacheObj["refPitch"] to refPitch.

writeJson(cacheObj,cache).

runPath("0:/_main/mission_controller.ks", launchScript, missionScript, tApo, tPe, tInc, gravTurnAlt, refPitch).