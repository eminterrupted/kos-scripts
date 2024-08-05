// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// Gui widgets

// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    local GUI_StyleDelegates to lexicon(
        "Align",    { parameter _wStyle, _val. set _wStyle:Align     to _val. return _wStyle:Align     = _val.},
        "Width",    { parameter _wStyle, _val. set _wStyle:Width     to _val. return _wStyle:Width     = _val.},
        "Height",   { parameter _wStyle, _val. set _wStyle:Height    to _val. return _wStyle:Height    = _val.},
        "Font",     { parameter _wStyle, _val. set _wStyle:Font      to _val. return _wStyle:Font      = _val.},
        "FontSize", { parameter _wStyle, _val. set _wStyle:FontSize  to _val. return _wStyle:FontSize  = _val.},
        "WordWrap", { parameter _wStyle, _val. set _wStyle:WordWrap  to _val. return _wStyle:WordWrap  = _val.},
        "Margin",   { parameter _wStyle, _val. set _wStyle:Margin    to _val. return _wStyle:Margin    = _val.},
        "Padding",  { parameter _wStyle, _val. set _wStyle:Padding   to _val. return _wStyle:Padding   = _val.},
        "Border",   { parameter _wStyle, _val. set _wStyle:Border    to _val. return _wStyle:Border    = _val.},
        "Overflow", { parameter _wStyle, _val. set _wStyle:Overflow  to _val. return _wStyle:Overflow  = _val.},
        "HStretch", { parameter _wStyle, _val. set _wStyle:HStretch  to _val. return _wStyle:HStretch  = _val.},
        "VStretch", { parameter _wStyle, _val. set _wStyle:VStretch  to _val. return _wStyle:VStretch  = _val.},
        "TextColor",{ parameter _wStyle, _val. set _wStyle:TextColor to _val. return _wStyle:TextColor = _val.},
        "BG",       { parameter _wStyle, _val. set _wStyle:BG        to _val. return _wStyle:BG        = _val.}
    ).
    
    local GUI_WidgetObj to lexicon(
        "Active_ActionCenter", "NUL"
        ,"Active_Button", lex()
        ,"Active_Stack", lex()
    ).

    local GUI_WidgetDelegates to lexicon(
        "Button", lex(
            "Close", { parameter _param is g_gui. print "Close Pressed {0}":Format(_param:TypeName). if _param:IsType("GUI") { _param:Hide(). set g_GUI_State to false. }}
            ,"CloseAll", { parameter _param is g_gui. print "CloseAll Pressed". ClearGuis(). set g_GUI_State to false. }
            ,"Revert", { parameter _param is "". print "Revert Pressed". return _param. }
            ,"Save", { parameter _param is "". print "Save Pressed". return _param. }
        ),
        "Stack_Pages", lex(
            "Mission Type", {}
            ,"Orbital Parameters", {}
            ,"Staging Parameters", {}
        )
    ).
    // #endregion

    // *- Global
    // #region
    global g_GUI to Gui(0).
    global g_GUI_State to false.
    // #endregion
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Initialization and updates
    // #region

    // InitGUI :: (param)<type> [(optionalParam)<type>] -> (output)<type>
    // Initiates a GUI object and returns the handle to that object
    global function InitGUI
    {
        parameter _type is 0.

        if _type = 0
        {
            return NewMissionParamGUI().
        }
    }

    // PurgeGUI
    global function PurgeGUIObj
    {
        parameter _guiHandle.

        set GUI_WidgetObj to lexicon(
            "Active_ActionCenter", "NUL"
            ,"Active_Button", lex()
            ,"Active_Stack", lex()
        ).
    }

    // UpdateGUI :: parameter _guiHandle<GUI> -> errorCode<int>
    //
    global function UpdateGUI
    {
        parameter _guiHandle,
                  _updateMask is "1111". // Updates all sections for now I guess
                                         // "0001" updates only the action box

        if _updateMask[3] // update the action center
        {
            local wgt to GUI_WidgetObj:Active_ActionCenter.
            if wgt = "NUL"
            {
                return -1. // Uh, that's weird.
            }
            else
            {
                for b in wgt:Widgets
                {
                    if b:HasSuffix("TakePress")
                    {
                        if b:TakePress
                        {
                            if GUI_WidgetDelegates:Button:HasKey(b:Text)
                            {
                                GUI_WidgetDelegates:Button[b:Text]:Call(b:GUI).
                            }
                        }
                    }
                }
            }
        }
    }

    // #endregion

    // *- Constructors
    // #region

    local function NewMissionParamGUI
    {
        local guiWidth to 640.
        local guiHeight to 512.
        
        local newGUI to GUI(guiWidth, guiHeight).
        local ws to newGUI:Style.

        newGui:AddSpacing(2).
        local titleLabel to newGui:AddLabel("AEA Mission Parameter Editor v0.01").
        
        // This is where each page will go
        local mainWindow to newGui:AddHBox().
        
        local editSelect  to mainWindow:AddVBox().
        mainWindow:AddSpacing(4).
        local valuesWindow to mainWindow:AddVBox().
        

        valuesWindow:AddLabel("Values").
        // valuesWindow:AddSpacing(1).
        local stackWindow to valuesWindow:AddVLayout().
        local stackWindowLabel to stackWindow:AddLabel("stackWindow").
        stackWindowLabel:Hide().

        local missionTypePage to stackWindow:AddStack().
        local missionTypePageLabel to missionTypePage:AddLabel("MissionTypePage").
        missionTypePageLabel:Hide().
        local missionTypePageTitle to missionTypePage:AddLabel("This is the Mission Type Page").
        

        local orbitalParameterPage to stackWindow:AddStack().
        local orbitalParameterPageLabel to orbitalParameterPage:AddLabel("OrbitalParameterPage").
        orbitalParameterPageLabel:Hide().
        
        local inclinationSection        to orbitalParameterPage:AddHLayout().
        local inclinationSectionLabel   to inclinationSection:AddLabel("inc").
        inclinationSectionLabel:Hide().

        locaL inclinationValueLabel to inclinationSection:AddLabel("<b>Inclination</b>").
        local inclinationLabelStyleLex to lexicon(
            "Align", "LEFT",
            "Width", 192,
            "Height", 24,
            "Font", "Unispace Bold",
            "FontSize", 16,
            "WordWrap", False
        ).
        StyleWidgetByLex(inclinationValueLabel:Style, inclinationLabelStyleLex).
        
        inclinationSection:AddSpacing(2).
        local incDownButton2 to inclinationSection:AddButton("<<<").
        inclinationSection:AddSpacing(2).
        local incDownButton1 to inclinationSection:AddButton("<<").
        inclinationSection:AddSpacing(2).
        local incDownButton0 to inclinationSection:AddButton("<").
        inclinationSection:AddSpacing(2).
        local incTextBoxReadout to inclinationSection:AddTextField("0").
        inclinationSection:AddSpacing(2).
        local incUpButton0 to inclinationSection:AddButton(">").
        inclinationSection:AddSpacing(2).
        local incUpButton1 to inclinationSection:AddButton(">>").
        inclinationSection:AddSpacing(2).
        local incUpButton2 to inclinationSection:AddButton(">>>").
        inclinationSection:AddSpacing(4).

        local inclinationButtonStyleLex to lexicon(
            "Align", "CENTER",
            "Width", 32,
            "Height", 24,
            "Font", "Unispace Bold",
            "FontSize", 14,
            "WordWrap", False
        ).

        for b in list(incDownButton0, incDownButton1, incDownButton2, incTextBoxReadout, incUpButton0, incUpButton1, incUpButton2)
        {
            StyleWidgetByLex(b:Style, inclinationButtonStyleLex).
        }

        local incTextBoxStyleLex to lexicon(
            "Align", "CENTER",
            "Width", 48,
            "Height", 24,
            "Font", "Unispace Bold",
            "FontSize", 18,
            "WordWrap", False
        ).
        StyleWidgetByLex(incTextBoxReadout:Style, incTextBoxStyleLex).
        
        local stagingParameterPage to stackWindow:AddStack().
        stagingParameterPage:AddLabel("This is the Staging Parameter Page").

        editSelect:AddLabel("Current Selection").
        editSelect:AddSpacing(4).
        local missionTypeRadio  to editSelect:AddRadioButton("Mission Type", False).
        local orbitalParamRadio to editSelect:AddRadioButton("Orbital Parameters", True).
        local stagingParamRadio to editSelect:AddRadioButton("Staging Parameters", False).
        set editSelect:OnRadioChange to ProcessRadioChange@.

        GUI_WidgetObj:Active_Stack:Add("Stack", stackWindow).
        GUI_WidgetObj:Active_Stack:Add("Mission Type", missionTypePage).
        GUI_WidgetObj:Active_Stack:Add("Orbital Parameters", orbitalParameterPage).
        GUI_WidgetObj:Active_Stack:Add("Staging Parameters", stagingParameterPage).
        stackWindow:ShowOnly(orbitalParameterPage).

        mainWindow:AddSpacing(4).

        newGui:AddSpacing(2).

        local actionBox to newGui:AddHLayout().
        local actionBoxLabel to actionBox:AddLabel("actionBox").
        actionBoxLabel:Hide().
        local revertButton to actionBox:AddButton("Revert").
        GUI_WidgetObj:Active_Button:Add("Revert", revertButton).
        local closeButton to actionBox:AddButton("Close").
        GUI_WidgetObj:Active_Button:Add("Close", closeButton).
        local saveButton  to actionBox:AddButton("Save").
        GUI_WidgetObj:Active_Button:Add("Save", saveButton).
        set GUI_WidgetObj:Active_ActionCenter to actionBox.

        
        global guiFoo to newGui.

        return newGui.
    }

    // #endregion

    // *- Widget Helpers
    // #region
    local function ProcessRadioChange
    {
        parameter _selRadio is GUI():addbutton().

        // local selectedGrandparent to _selRadio:Parent:Parent.
        // local grandparentWidgets to selectedGrandparent:Widgets.
        // local stackBox to selectedGrandparent.
        
        // from { local i to grandparentWidgets:Length - 1. } until i < 0 step { set i to i - 1. } do
        // {
        //     if grandparentWidgets[i]:IsType("Box")
        //     {
        //         set stackBox to grandparentWidgets[i].
        //         Break.
        //     }
        // }

        if GUI_WidgetObj:Active_Stack:HasKey("Stack")
        {
            local stackBox to GUI_WidgetObj:Active_Stack:Stack.
            stackBox:ShowOnly(GUI_WidgetObj:Active_Stack[_selRadio:Text]).
        }
    }

    // StyleWidgetByLex
    // Takes in a lexicon of style names and values and applies those to the provided style
    local function StyleWidgetByLex
        {
            parameter _widgetStyle,
                      _styleLex is lex().

            if not _widgetStyle:IsType("Style")
            {
                if _widgetStyle:HasSuffix("Style") 
                {
                    set _widgetStyle to _widgetStyle:Style.
                }
                else
                {
                    return _widgetStyle.
                }
            }
            if _styleLex:Keys:Length = 0
            {
                return -1.
            }
            
            local cnt to 0.
            local len to _styleLex:Keys:Length.

            from { local i to 0.} until i >= len step { set i to i + 1.} do
            {
                local styName to _styleLex:Keys[i].
                if _widgetStyle:HasSuffix(styName)
                {
                    GUI_StyleDelegates[styName]:Call(_widgetStyle, _styleLex:Values[i]).
                    set cnt to cnt + 1.
                }
            }
            
            return len - cnt.
        }
    
    // #endregion

    
// #endregion