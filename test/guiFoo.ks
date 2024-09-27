@LazyGlobal off.
ClearScreen.

parameter _params is list().

RunOncePath("0:/lib/libLoader", list(0)).
RunOncePath("0:/lib/gui").

ClearGuis().
PurgeGUIObj().

// local dataLex to GUI_WidgetDelegates.
InitTestHeader().

print "Parsing core tag".

set g_MissionTag to ParseCoreTag().

global guiHandle to gui(0).
local guiState to False.

print "UP   : Show GUI" at (2, 3).
print "DOWN : Hide GUI" at (2, 4).
print "RIGHT: Initialize GUI" at (2, 5).
print "LEFT : Destroy GUI" at (2, 6).

set guiHandle to InitGUI(0).
set guiHandle:Visible to True.
set guiState to True.

local doneFlag to false.
until doneFlag
{
    GetTermChar().

    if g_TermChar = ""
    {
        print "Gui State: {0}":Format(guiState) at (2, 8).
        if guiState 
        {
            UpdateGUI(guiHandle, "1001").
        }
    }
    else
    {
        if g_TermChar = Terminal:Input:RightCursorOne // Initialize / Reinit
        {
            set guiHandle to InitGUI(0).
            set guiState to True.
        }
        else if g_TermChar = Terminal:Input:UpCursorOne
        {
            if guiState 
            {
                guiHandle:Show().
            }
        }
        else if g_TermChar = Terminal:Input:DownCursorOne
        {
            if guiState 
            {
                guiHandle:Hide().
            }
        }
        else if g_TermChar = Terminal:Input:LeftCursorOne
        {
            PurgeGUIObj(guiHandle).
            set guiState to False.
            set guiHandle to GUI(0).
            ClearGuis().
            guiHandle:Clear().
            g_Gui:Clear().
            set doneFlag to true.

            // GUI_WidgetDelegates:Stack_Pages:Clear().
            // GUI_WidgetDelegates:Active_Stack:Clear().
            // GUI_WidgetDelegates:Active_Button:Clear().
            // set dataLex to GUI_WidgetDelegates.
            clearScreen.
        }
        else if g_TermChar = "g"
        {
            print guiHandle:widgets at (2, 10).
        }
        set g_TermChar to "".
    }

}

local function InitTestHeader
{
    ClearScreen.
    print "** AEA GUI Test Suite v0.01 **".
    print "------------------------------".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
    print " ".
}