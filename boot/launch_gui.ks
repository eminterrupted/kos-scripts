@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/display/gui/lib_gui.ks").



local cache to "0:/data/launchSelectCache.json".
local localCache to "local:/launchSelectCache.json".
local cacheObj to lexicon().

local launchScript to "scout_1.ks".
local missionScript to "deploy_sat.ks".
local tApo to "250000".
local tPe to "250000".
local tInc to 0.
local gtAlt to 60000.
local gtPitch to 3.

if exists(cache) {
        set cacheObj to readJson(cache).

        if cacheObj:hasKey("launchScript") set launchScript to cacheObj["launchScript"]:toString.
        if cacheObj:hasKey("missionScript") set missionScript to cacheObj["missionScript"]:toString.
        if cacheObj:hasKey("tApo") set tApo to cacheObj["tApo"].
        if cacheObj:hasKey("tPe") set tPe to cacheObj["tPe"].
        if cacheObj:hasKey("tInc") set tInc to cacheObj["tInc"].
        if cacheObj:hasKey("gtAlt") set gtAlt to cacheObj["gtAlt"].
        if cacheObj:hasKey("gtPitch") set gtPitch to cacheObj["gtPitch"].
}

local lScriptList to get_launch_scripts().
local mScriptList to get_mission_scripts().

local gui to gui(500).
local tabWidget to add_tab_widget(gui).

local page to add_tab(tabWidget, "Launch Script Params").
page:addLabel("Select launch parameters").

page:addLabel("Target Apoapsis").
local tfAp to page:addTextField(tApo:toString).
set tfAp:onConfirm to { parameter ap. set tApo to round(ap:toNumber). set cacheObj["tApo"] to tApo. }.

page:addLabel("Target Periapsis").
local tfPe to page:addTextField(tPe:toString).
set tfPe:onConfirm to { parameter pe. set tPe to round(pe:toNumber). set cacheObj["tPe"]to tPe. }.

page:addLabel("Target Inclination").
local inc to tInc.
local incLabel to page:addLabel(round(inc):tostring).
set inc to page:addHSlider(inc, -180, 180).
set inc:onChange to { parameter i. set tInc to round(i). set cacheObj["tInc"] to tInc. set incLabel:text to tInc:tostring. }.

page:addLabel("Gravity Turn End Altitude").
local gta to gtAlt.
local gtaLabel to page:addLabel(round(gta):toString).
set gta to page:addHSlider(gta, 45000, 70000).
set gta:onChange to { parameter a. set gtAlt to round(a). set cacheObj["gtAlt"] to gtAlt. set gtaLabel:text to gtAlt:toString.}.

page:addLabel("gtPitch").
local rp to gtPitch.
local rpLabel to page:addLabel(round(rp,1):tostring).
set rp to page:addHSlider(rp, 0, 10).
set rp:onChange to { parameter p. set gtPitch to round(p, 1). set cacheObj["gtPitch"] to gtPitch. set rpLabel:text to gtPitch:tostring.}.

set page to add_tab(tabWidget, "Launch Script").
page:addLabel("Select launch script").
page:addLabel("Currently selected launch script: " + launchScript).
local lScript to add_popup_menu(page,lScriptList).
set lScript:onchange to { parameter lChoice. set launchScript to lChoice:toString. set cacheObj["launchScript"] to launchScript.}.

set page to add_tab(tabWidget, "Mission Script").
page:addLabel("Select mission script for post-launch").
page:addLabel("Currently selected mission script: " + missionScript).
local mScript to add_popup_menu(page,mScriptList).
set mScript:onchange to { parameter mChoice. set missionScript to mChoice:toString. set cacheObj["missionScript"] to missionScript.}.

local close to gui:addButton("Close").

when True then {
        from { local x to 0.} until x >= tabWidget_alltabs:length step { set x to x+1.} do
        {
                // Earlier, we were careful to hide the panels that were not the current
                // one when they were added, so we can test if the panel to VISIBLE
                // to avoid the more expensive call to SHOWONLY every frame.
                if tabWidget_allTabs[x]:pressed and not (tabWidget_allPanels[x]:VISIBLE) {
                        tabWidget_allPanels[x]:parent:showonly(tabWidget_allPanels[x]).
                }
        }
        PRESERVE.
}

gui:show().
local tStamp to time:seconds + 30.
local closeGui to false.
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
        print "Gravity Turn Altitude:   " + gtAlt + "      " at (2,24).
        print "Gravity Turn End Pitch:  " + gtPitch + "      " at (2,25).

        if time:seconds > tStamp set closeGui to true.
        if close:pressed set closeGui to true.
}

gui:hide().

set cacheObj["launchScript"] to launchScript.
set cacheObj["missionScript"] to missionScript.
set cacheObj["tApo"] to tApo.
set cacheObj["tPe"] to tPe.
set cacheObj["tInc"] to tInc.
set cacheObj["gtAlt"] to gtAlt.
set cacheObj["gtPitch"] to gtPitch.

writeJson(cacheObj, cache).
copyPath(cache, localCache).

local mc to "0:/_main/mission_controller.ks".
local localMC to ship:rootpart.
set localMC to localMC:getModule("kOSProcessor").
set localMC to localMC:volume:name + ":/mission_controller.ks".
copyPath(mc, localMC).

runPath(localMC, launchScript, missionScript, tApo, tPe, tInc, gtAlt, gtPitch).