@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init.ks").
runOncePath("0:/lib/display/gui/lib_gui.ks").



local cache to "0:/data/launchSelectCache.json".
local localCache to "local:/launchSelectCache.json".
local cacheObj to lexicon().

local launchS1 to "scout_1.ks".
local missionS1 to "deploy_sat.ks".
//local missionS2 to "no_reentry.ks".
local tApo to "250000".
local tPe to "250000".
local tInc to "0".
local gtAlt to "60000".
local gtPitch to 3.
local rVal to 0.

if exists(cache) {
        set cacheObj to readJson(cache).

        if cacheObj:hasKey("launchS1") set launchS1 to cacheObj["launchS1"]:toString.
        if cacheObj:hasKey("missionS1") set missionS1 to cacheObj["missionS1"]:toString.
        //if cacheObj:hasKey("missionS2") set missionS2 to cacheObj["missionS2"]:toString.
        if cacheObj:hasKey("tApo") set tApo to cacheObj["tApo"].
        if cacheObj:hasKey("tPe") set tPe to cacheObj["tPe"].
        if cacheObj:hasKey("tInc") set tInc to cacheObj["tInc"].
        if cacheObj:hasKey("gtAlt") set gtAlt to cacheObj["gtAlt"].
        if cacheObj:hasKey("gtPitch") set gtPitch to cacheObj["gtPitch"].
        if cacheObj:hasKey("rVal") set rVal to cacheObj["rVal"].
}

local lScriptList to get_launch_scripts().
local mScriptList to get_mission_scripts().

local gui to gui(750).
local tabWidget to add_tab_widget(gui).

local page to add_tab(tabWidget, "Launch Script Params").

page:addspacing(10).

local lbox to page:addvbox().
lbox:addLabel("Select launch parameters").

lbox:addspacing(20).

local obox to lbox:addhlayout().
local leftbox to obox:addvlayout().
leftbox:addLabel("Target Apoapsis").
local tfAp to leftbox:addTextField(tApo:toString).
set tfAp:onConfirm to { parameter ap. set tApo to round(ap:toNumber). set cacheObj["tApo"] to tApo. }.

leftbox:addspacing(20).

leftbox:addLabel("Target Periapsis").
local tfPe to leftbox:addTextField(tPe:toString).
set tfPe:onConfirm to { parameter pe. set tPe to round(pe:toNumber). set cacheObj["tPe"]to tPe. }.

leftbox:addspacing(20).

leftbox:addLabel("Gravity Turn End Altitude").
local gta to leftbox:addTextField(round(gtAlt):toString).
set gta:onConfirm to { parameter a. set gtAlt to round(a:toNumber). set cacheObj["gtAlt"] to gtAlt.}.

local rightbox to obox:addvlayout().

local inc to tInc.
local incText to "Target Inclination: ".
local incLabel to rightbox:addLabel(incText + round(inc):tostring).
set inc to rightbox:addHSlider(inc, -90, 90).
set inc:onChange to { parameter i. set tInc to round(i). set cacheObj["tInc"] to tInc. set incLabel:text to incText + tInc.}.

rightbox:addspacing(20).

rightbox:addLabel("Roll Angle").
local rbox to rightbox:addhlayout().
local rb0 to rbox:addRadioButton("0", true).
rbox:addspacing(75).
local rb90 to rbox:addRadioButton("90", false).
rbox:addspacing(75).
local rb180 to rbox:addRadioButton("180", false).
rbox:addspacing(75).
local rb270 to rbox:addRadioButton("270", false).
set rbox:onRadioChange to { parameter r. if r = "0" set rVal to r:text:toNumber. else set rVal to r:text:toNumber.}.

rightbox:addspacing(4).

//rightbox:addLabel("Gravity Turn Final Pitch").
local rp to gtPitch.
local rpText to "Gravity Turn Final Pitch: ".
local rpLabel to rightbox:addLabel(rpText + round(rp,1):tostring).
set rp to rightbox:addHSlider(rp, 0, 5).
set rp:onChange to { parameter p. set gtPitch to round(p, 1). set cacheObj["gtPitch"] to gtPitch. set rpLabel:text to rpText + gtPitch:tostring.}.

page:addspacing(10).


set page to add_tab(tabWidget, "Script Select").
page:addspacing(10).

local scrbox to page:addvlayout().
scrbox:addlabel("Select launch and mission scripts").
scrbox:addspacing(5).

local hbox to scrbox:addhlayout().
hbox:addspacing(5).

local lsbox to hbox:addvbox().
lsbox:addspacing(5).
lsbox:addLabel("Launch / Ascent").
lsbox:addspacing(10).
local ls1 to add_popup_menu(lsbox, lScriptList).
set ls1:onchange to { parameter lChoice. set launchS1 to lChoice:toString:replace(".ks", ""). set cacheObj["launchS1"] to launchS1.}.

local s1box to hbox:addvbox().
s1box:addspacing(5).
s1box:addLabel("Mission Stage 1").
s1box:addspacing(10).
local s1 to add_popup_menu(s1box, mScriptList).
set s1:onchange to { parameter mChoice. set missionS1 to mChoice:toString:replace(".ks",""). set cacheObj["missionS1"] to missionS1.}.

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
local rProc to ship:rootpart:getModule("kOSProcessor").
rProc:doAction("open terminal",true).

until closeGui = true {
        wait(0).

        print "remaining time: " + round(tStamp - time:seconds) + "    " at (2,2).
        print "Launch script selected:  " + launchS1 + "         " at (2,4).
        print "Stage 1 script selected: " + missionS1 + "         " at (2,5).
        //print "Stage 2 script selected: " + missionS2 + "         " at (2,6).

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

set cacheObj["launchS1"] to launchS1.
set cacheObj["missionS1"] to missionS1.
//set cacheObj["missionS2"] to missionS2.
set cacheObj["tApo"] to tApo.
set cacheObj["tPe"] to tPe.
set cacheObj["tInc"] to tInc.
set cacheObj["gtAlt"] to gtAlt.
set cacheObj["gtPitch"] to gtPitch.
set cacheObj["rVal"] to rVal.

writeJson(cacheObj, cache).
copyPath(cache, localCache).

local mc to "0:/_main/mc_vnext".
local localMC to rProc:volume:name + ":/boot/mc".
//copyPath(mc, localMC).
compile(mc) to localMC.
set rProc:bootfilename to localMC:replace("local:","").
//if exists("local:/boot/gui_stage") deletePath("local:/boot/gui_stage").

runPath(localMC).