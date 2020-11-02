@lazyGlobal off.

if defined tabWidget_allTabs unset tabWidget_allTabs.
if defined tabWidget_allPanels unset tabWidget_allPanels.

global tabWidget_allTabs is list().
global tabWidget_allPanels is list().


global function add_popup_menu {

    parameter pTabPanel,
              pOptions.

    local popup is pTabPanel:addPopupMenu().
    set popup:options to pOptions.

    return popup.
}

global function add_scrollbox {

    parameter pTabWidget. // tab title

    // Get back the two widgets we created in add_tab_widget
    local hBoxes is pTabWidget:widgets.
    local gTabs is hBoxes[0].    // hlayout
    local gPanels is hBoxes[1].  // stack

    // Add a scrollbox
    local panel is gPanels:addscrollbox().
    set panel:style to panel:gui:skin:get("TabWidgetPanel").
    set panel:style:width to 400.
    set panel:style:height to 400.

    return panel.
}


global function add_h_slider {

    parameter pTabPanel,
              pMin,
              pMax,
              pInit.

    return true.
}

global function add_tab {

    parameter pTabWidget,   // (the vbox)
              pTabName.     // tab title

    // Get back the two widgets we created in add_tab_widget
    local hBoxes is pTabWidget:widgets.
    local gTabs is hBoxes[0].    // hlayout
    local gPanels is hBoxes[1].  // stack

    // Add another panel and style correctly
    local panel is gPanels:addVBox.
    set panel:style to panel:gui:skin:get("TabWidgetPanel").

    // Add another tab, style it correctly. 
    local tab is gTabs:addButton(pTabName).
    set tab:style to tab:gui:skin:get("TabWidgetTab").

    //Set the tab button to be exclusive - 
    // When one tab goes up, all others go down
    set tab:toggle to true.
    set tab:exclusive to true.

    //If this is the first tab, make it start already pressed. 
    //Otherwise, hide it (even though STACK will only show the first anyway, 
    //By keeping things "correct" we can be more efficient later)
    if gPanels:widgets:length = 1 {
        set tab:pressed to true.
        gPanels:showOnly(panel).
    } else {
        panel:hide().
    }

    //Add the tab and its corresponding panel to global variables to handle interaction later
    tabWidget_allTabs:add(tab).
    tabWidget_allPanels:add(panel).

    return panel.
}


global function add_tab_widget {
    parameter pBox.

    // See if styles for the TabWidget components (tabs and panels) has
    // already been defined elsewhere. If not, define each one

    if not pBox:gui:skin:has("TabWidgetTab") {

        // The style for tabs is like a button, but it should smoothly connect
        // to the panel below it, especially if it is the current selected tab.
        local style is pBox:gui:skin:add("TabWidgetTab", pBox:gui:skin:button).

        set style:bg to "lib/display/gui/assets/back".
        set style:on:bg to "lib/display/gui/assets/front".
        
        //Tweaking the style
        set style:textColor to rgba(0.7, 0.75, 0.7, 1).
        set style:hover:bg to "".
        set style:hover_on:bg to "".
        set style:margin:h to 0.
        set style:margin:bottom to 0.
    }

    if not pBox:gui:skin:has("TabWidgetPanel") { 
        local style is pBox:gui:skin:add("TabWidgetPanel", pBox:gui:skin:window).
        set style:bg to "lib/display/gui/assets/panel".
        set style:padding:top to 0.
    }

    // Add a vlayout (in case the box is a HBOX, for example),
    // then add a hlayout for the tabs and a stack to hols all the panels.
    local vBox is pBox:addVLayout.
    local tabs is vBox:addHLayout.
    local panels is vBox:addStack.

    
    // any other customization of tabs and panels goes here

    // Return the empty TabWidget.
    return vBox.
}


global function choose_tab {
    parameter pTabWidget,   //the tab
              pNum.         //tab to choose (0-indexed)

    //Finc the tabs hlayout, which we know is the first one we added
    local hBoxes is pTabWidget:widgets.
    local tabs is hBoxes[0].

    set tabs:widgets[pNum]:pressed to true. 
}


global function get_launch_scripts {
        local fList is list().
        local scrList is list().

        switch to 0.
        cd("_main/launch").
        list files in fList.
        for f in fList scrList:add(f).

        return scrList.
}


global function get_mission_scripts {
        local fList is list().
        local scrList is list().

        switch to 0.
        cd("_main/mission").
        list files in fList.
        for f in fList scrList:add(f).

        return scrList.
}