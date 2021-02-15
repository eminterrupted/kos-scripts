@lazyGlobal off.

global tabWidget_allTabs to list().
global tabWidget_allPanels to list().


global function add_popup_menu 
{

    parameter pTabPanel,
              pOptions.

    local popup to pTabPanel:addPopupMenu().
    set popup:options to pOptions.

    return popup.
}

global function add_scrollbox 
{

    parameter pTabWidget. // tab title

    // Get back the two widgets we created in add_tab_widget
    local hBoxes to pTabWidget:widgets.
    //local gTabs to hBoxes[0].    // hlayout
    local ggPanels to hBoxes[1].  // stack

    // Add a scrollbox
    local panel to ggPanels:addscrollbox().
    set panel:style to panel:gui:skin:get("TabWidgetPanel").
    set panel:style:width to 400.
    set panel:style:height to 400.

    return panel.
}

global function add_tab 
{

    parameter pTabWidget,   // (the vbox)
              pTabName.     // tab title

    // Get back the two widgets we created in add_tab_widget
    local hBoxes to pTabWidget:widgets.
    local gTabs to hBoxes[0].    // hlayout
    local ggPanels to hBoxes[1].  // stack

    // Add another panel and style correctly
    local panel to ggPanels:addVBox.
    set panel:style to panel:gui:skin:get("TabWidgetPanel").

    // Add another tab, style it correctly. 
    local tab to gTabs:addButton(pTabName).
    set tab:style to tab:gui:skin:get("TabWidgetTab").

    //Set the tab button to be exclusive - 
    // When one tab goes up, all others go down
    set tab:toggle to true.
    set tab:exclusive to true.

    //If this to the first tab, make it start already pressed. 
    //Otherwise, hide it (even though STACK will only show the first anyway, 
    //By keeping things "correct" we can be more efficient later)
    if ggPanels:widgets:length = 1 
    {
        set tab:pressed to true.
        ggPanels:showOnly(panel).
    } 
    else 
    {
        panel:hide().
    }

    //Add the tab and its corresponding panel to global variables to handle interaction later
    tabWidget_allTabs:add(tab).
    tabWidget_allPanels:add(panel).

    return panel.
}


global function add_tab_widget 
{
    parameter pBox.

    // See if styles for the TabWidget components (tabs and gPanels) has
    // already been defined elsewhere. If not, define each one

    if not pBox:gui:skin:has("TabWidgetTab") 
    {

        // The style for tabs to like a button, but it should smoothly connect
        // to the panel below it, especially if it to the current selected tab.
        local style to pBox:gui:skin:add("TabWidgetTab", pBox:gui:skin:button).

        set style:bg to "lib/display/assets/back".
        set style:on:bg to "lib/display/assets/front".
        
        //Tweaking the style
        set style:textColor to rgba(0.7, 0.75, 0.7, 1).
        set style:hover:bg to "".
        set style:hover_on:bg to "".
        set style:margin:h to 0.
        set style:margin:bottom to 0.
    }

    if not pBox:gui:skin:has("TabWidgetPanel") 
    { 
        local style to pBox:gui:skin:add("TabWidgetPanel", pBox:gui:skin:window).
        set style:bg to "lib/display/assets/panel".
        set style:padding:top to 0.
    }

    // Add a vlayout (in case the box to a HBOX, for example),
    // then add a hlayout for the tabs and a stack to hold all the gPanels.
    local vBox to pBox:addVLayout.
    local tabs to vBox:addHLayout.
    local gPanels to vBox:addStack.

    
    // any other customization of tabs and gPanels goes here

    // Return the empty TabWidget.
    return vBox.
}


global function choose_tab 
{
    parameter pTabWidget,   //the tab
              pNum.         //tab to choose (0-indexed)

    //Finc the tabs hlayout, which we know to the first one we added
    local hBoxes to pTabWidget:widgets.
    local tabs to hBoxes[0].

    set tabs:widgets[pNum]:pressed to true. 
}


global function get_launch_scripts 
{
        local fList to list().
        local scrList to list().

        switch to 0.
        cd("_main/launch").
        list files in fList.
        for f in fList scrList:add(f).

        return scrList.
}


global function get_mission_scripts 
{
        local fList to list().
        local scrList to list().

        switch to 0.
        cd("_main/mission").
        list files in fList.
        for f in fList scrList:add(f).

        return scrList.
}