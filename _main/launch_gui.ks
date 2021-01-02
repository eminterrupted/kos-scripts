@lazyGlobal off.

clearscreen. 

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/display/gui/lib_gui").

local kscCache to "0:/data/missionCacheParam.json".
local shipCache to "local:/missionCache.json".
local cache to lexicon().

local launchS1  to "multistage_base".   // Launch script
local missionS1 to "simple_orbit".      // First stage mission script
local missionS2 to "simple_reentry".    // Second stage mission script
local lAp       to "250000".            // Desired launch ap
local lPe       to "250000".            // Desired launch pe
local lInc      to "0".                 // Desired launch inclination
local lTAlt     to "60000".             // Altitude that the script will use for launch angle calcs
local rVal      to 0.                   // Orientation of the craft for the duration of the mission
                                        // Typically 0 for probes, 180 for manned vessels cuz windows :) 

// Load the above from the cache
if exists(kscCache) {
        set cache to readJson(kscCache).

        if cache:hasKey("launchS1")     set launchS1    to cache["launchS1"]:toString.
        if cache:hasKey("missionS1")    set missionS1   to cache["missionS1"]:toString.
        if cache:hasKey("missionS2")    set missionS2   to cache["missionS2"]:toString.
        if cache:hasKey("lAp")          set lAp         to cache["lAp"].
        if cache:hasKey("lPe")          set lPe         to cache["lPe"].
        if cache:hasKey("lInc")         set lInc        to cache["lInc"].
        if cache:hasKey("lTAlt")        set lTAlt       to cache["lTAlt"].
        if cache:hasKey("rVal")         set rVal        to cache["rVal"].
}

// Load the available scripts for later selection
local lScriptList to get_launch_scripts().
local mScriptList to get_mission_scripts().

// Initiate the gui box
local gui to gui(750).
local tabWidget to add_tab_widget(gui).

// Create a launch script parameters widget
local page to add_tab(tabWidget, "Launch Script Params").

page:addspacing(10).

local lbox to page:addvbox().
lbox:addLabel("Select launch parameters").

lbox:addspacing(20).

local obox to lbox:addhlayout().
local leftbox to obox:addvlayout().
leftbox:addLabel("Target Apoapsis").
local tfAp to leftbox:addTextField(lAp:toString).
set tfAp:onConfirm to { parameter ap. set lAp to round(ap:toNumber). set cache["lAp"] to lAp. }.

leftbox:addspacing(20).

leftbox:addLabel("Target Periapsis").
local tfPe to leftbox:addTextField(lPe:toString).
set tfPe:onConfirm to { parameter pe. set lPe to round(pe:toNumber). set cache["lPe"]to lPe. }.

leftbox:addspacing(20).

leftbox:addLabel("Gravity Turn End Altitude").
local gta to leftbox:addTextField(round(lTAlt):toString).
set gta:onConfirm to { parameter a. set lTAlt to round(a:toNumber). set cache["lTAlt"] to lTAlt.}.

local rightbox to obox:addvlayout().

local inc to lInc.
local incText to "Target Inclination: ".
local incLabel to rightbox:addLabel(incText + round(inc):tostring).
set inc to rightbox:addHSlider(inc, -90, 90).
set inc:onChange to { parameter i. set lInc to round(i). set cache["lInc"] to lInc. set incLabel:text to incText + lInc.}.

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
set ls1:onchange to { parameter lChoice. set launchS1 to lChoice:toString:replace(".ks", ""). set cache["launchS1"] to launchS1.}.

local s1box to hbox:addvbox().
s1box:addspacing(5).
s1box:addLabel("Mission Stage 1").
s1box:addspacing(10).
local s1 to add_popup_menu(s1box, mScriptList).
set s1:onchange to { parameter mChoice. set missionS1 to mChoice:toString:replace(".ks",""). set cache["missionS1"] to missionS1.}.

local s2box to hbox:addvbox().
s2box:addspacing(5).
s2box:addLabel("Mission Stage 2").
s2box:addspacing(10).
local s2 to add_popup_menu(s2box, mScriptList).
set s2:onchange to { parameter mChoice. set missionS2 to mChoice:toString:replace(".ks",""). set cache["missionS2"] to missionS2.}.

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
core:doAction("open terminal",true).

until closeGui = true {
        wait(0).

        print "remaining time: " + round(tStamp - time:seconds) + "    " at (2,2).
        print "Launch script selected:  " + launchS1    + "      " at (2,4).
        print "Stage 1 script selected: " + missionS1   + "      " at (2,5).
        print "Stage 2 script selected: " + missionS2   + "      " at (2,6).

        print "Launch Apoapsis:          " + lAp        + "      " at (2,7).
        print "Launch Periapsis:         " + lPe        + "      " at (2,8).
        print "Launch Inclination:       " + lInc       + "      " at (2,9).
        print "Launch Turn Altitude:     " + lTAlt      + "      " at (2,10).
        print "Roll Program Orientation: " + rVal       + "      " at (2,12).

        if time:seconds > tStamp set closeGui to true.
        if close:pressed set closeGui to true.
}

gui:hide().

set cache["launchS1"] to launchS1.
set cache["missionS1"] to missionS1.
set cache["missionS2"] to missionS2.
set cache["lAp"] to lAp.
set cache["lPe"] to lPe.
set cache["lInc"] to lInc.
set cache["lTAlt"] to lTAlt.
set cache["rVal"] to rVal.

writeJson(cache, kscCache).
copyPath(kscCache, shipCache).

local mc to "0:/_main/mc".
local localMC to core:volume:name + ":/boot/mc".
compile(mc) to localMC.

runPath(localMC).