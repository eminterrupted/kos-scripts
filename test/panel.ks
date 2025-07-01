@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/gui.ks").

local panelGui is gui(500).

local guiStyle to panelGui:Style.
SetStyle(guiStyle, __guiStyles:APL:PANELBASE).

local pnlHLO to panelGui:AddHLayout().
// pnlHLO:AddSpacing(0).

local pnlVLO to pnlHLO:AddVLayout().
// pnlVLO:AddSpacing(10).

local panelVBox_0 is pnlVLO:AddVBox().

local pgStyle to panelVBox_0:Style. 

// print pgStyle:Suffixnames.
// wait 10.
SetStyle(pgStyle, __guiStyles:APL:PANEL0).

set pgStyle:Width to 768.
set pgStyle:Height to 320.

// page:ADDLABEL("This is page 1").
// page:ADDLABEL("Put stuff here!").

// LOCAL page2 IS AddTab(tabwidget,"Two").
// page2:ADDLABEL("This is page 2").
// page2:ADDLABEL("Put more stuff here!").

// LOCAL page3 IS AddTab(tabwidget,"Three").
// page3:ADDLABEL("This is page 3").
// page3:ADDLABEL("Put even stuff here!").

// ChooseTab(tabwidget,0).

local close is panelVBox_0:ADDBUTTON("Close").
// SetupTabTrigger(tabwidget).

panelGui:SHOW().
UNTIL close:PRESSED {
    // Handle processing of all the widgets on all the tabs.
    WAIT(0).
}
panelGui:HIDE().