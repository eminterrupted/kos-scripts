@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/display/gui/lib_gui.ks").



local cache to "0:/data/launchSelectCache.json".
local localCache to "local:/launchSelectCache.json".
local cacheObj to lexicon().

local launchScript to "scout_1.ks".
local missionScript to "deploy_sat.ks".
local reentryScript to "no_reentry.ks".
local tApo to "250000".
local tPe to "250000".
local tInc to "0".
local gtAlt to "60000".
local gtPitch to 3.
local rVal to 0.

if exists(cache) {
        set cacheObj to readJson(cache).

        if cacheObj:hasKey("launchScript") set launchScript to cacheObj["launchScript"]:toString.
        if cacheObj:hasKey("missionScript") set missionScript to cacheObj["missionScript"]:toString.
        if cacheObj:hasKey("reentryScript") set reentryScript to cacheObj["reentryScript"]:toString.
        if cacheObj:hasKey("tApo") set tApo to cacheObj["tApo"].
        if cacheObj:hasKey("tPe") set tPe to cacheObj["tPe"].
        if cacheObj:hasKey("tInc") set tInc to cacheObj["tInc"].
        if cacheObj:hasKey("gtAlt") set gtAlt to cacheObj["gtAlt"].
        if cacheObj:hasKey("gtPitch") set gtPitch to cacheObj["gtPitch"].
        if cacheObj:hasKey("rVal") set rVal to cacheObj["rVal"].
}

local lScriptList to get_launch_scripts().
local mScriptList to get_mission_scripts().
local rScriptList to get_reentry_scripts().

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
local inc to page:addTextField(round(tInc):tostring).
set inc:onConfirm to { parameter i. set tInc to round(i:toNumber). set cacheObj["tInc"] to tInc. }.

page:addLabel("Gravity Turn End Altitude").
local gta to page:addTextField(round(gtAlt):toString).
set gta:onConfirm to { parameter a. set gtAlt to round(a:toNumber). set cacheObj["gtAlt"] to gtAlt.}.

page:addLabel("Gravity Turn Reference Pitch").
local rp to gtPitch.
local rpLabel to page:addLabel(round(rp,1):tostring).
set rp to page:addHSlider(rp, 0, 10).
set rp:onChange to { parameter p. set gtPitch to round(p, 1). set cacheObj["gtPitch"] to gtPitch. set rpLabel:text to gtPitch:tostring.}.

page:addLabel("Final Roll Angle").
local rb0 to page:addRadioButton("0", true).
local rb90 to page:addRadioButton("90", false).
local rb180 to page:addRadioButton("180", false).
local rb270 to page:addRadioButton("270", false).
set page:onRadioChange to { parameter r. if r = "0" set rVal to r:text:toNumber. else set rVal to r:text:toNumber.}.

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

set page to add_tab(tabWidget, "Reentry Script").
page:addLabel("Select a script for reentry").
page:addLabel("Currently selected reentry script: " + reentryScript).
local rScript to add_popup_menu(page,rScriptList).
set rScript:onchange to { parameter rChoice. set reentryScript to rChoice:toString. set cacheObj["reentryScript"] to reentryScript.}.

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
local tStamp to time:seconds + 60.
local closeGui to false.
ship:rootpart:getModule("kOSProcessor"):doAction("open terminal",true).

until closeGui = true {
        wait(0).

        print "remaining time: " + round(tStamp - time:seconds) + "    " at (2,2).
        
        print "Launch script selected:  " + launchScript + "         " at (2,4).
        print "Mission script selected: " + missionScript + "         " at (2,5).
        print "Reentry script selected: " + reentryScript + "         " at (2,6).

        print "Target Apoapsis:         " + tApo + "      " at (2,7).
        print "Target Periapsis:        " + tPe + "      " at (2,8).
        print "Target Inclination:      " + tInc + "      " at (2,9).
        print "Gravity Turn Altitude:   " + gtAlt + "      " at (2,10).
        print "Gravity Turn End Pitch:  " + gtPitch + "      " at (2,11).
        print "Roll Program Value:      " + rVal + "  " at (2,12).

        if time:seconds > tStamp set closeGui to true.
        if close:pressed set closeGui to true.
}

gui:hide().

set cacheObj["launchScript"] to launchScript.
set cacheObj["missionScript"] to missionScript.
set cacheObj["reentryScript"] to reentryScript.
set cacheObj["tApo"] to tApo.
set cacheObj["tPe"] to tPe.
set cacheObj["tInc"] to tInc.
set cacheObj["gtAlt"] to gtAlt.
set cacheObj["gtPitch"] to gtPitch.
set cacheObj["rVal"] to rVal.

writeJson(cacheObj, cache).
copyPath(cache, localCache).

local mc to "0:/_main/mc.ks".
local localMC to ship:rootpart.
set localMC to localMC:getModule("kOSProcessor").
set localMC to localMC:volume:name + ":/mc.ks".
copyPath(mc, localMC).

runPath(localMC, launchScript, missionScript, reentryScript, tApo, tPe, tInc, gtAlt, gtPitch, rVal).