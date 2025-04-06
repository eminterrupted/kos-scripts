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
        "Border",   { parameter _wStyle, _val. return ApplyStyleRectOffsetValues(_wStyle:Border,  _val).},
        "Margin",   { parameter _wStyle, _val. return ApplyStyleRectOffsetValues(_wStyle:Margin,  _val).},
        "Overflow", { parameter _wStyle, _val. return ApplyStyleRectOffsetValues(_wStyle:Overflow,_val).},
        "Padding",  { parameter _wStyle, _val. return ApplyStyleRectOffsetValues(_wStyle:Padding, _val).},
        "HStretch", { parameter _wStyle, _val. set _wStyle:HStretch  to _val. return _wStyle:HStretch  = _val.},
        "VStretch", { parameter _wStyle, _val. set _wStyle:VStretch  to _val. return _wStyle:VStretch  = _val.},
        "TextColor",{ parameter _wStyle, _val. set _wStyle:TextColor to _val. return _wStyle:TextColor = _val.},
        "BG",       { parameter _wStyle, _val. set _wStyle:BG        to _val. return _wStyle:BG        = _val.},
        "StyleStates", lexicon(
            "Normal",       { parameter _wStyle. if _wStyle:HasSuffix("Normal")     return _wStyle:Normal.    },
            "On",           { parameter _wStyle. if _wStyle:HasSuffix("On")         return _wStyle:On.        },
            "Hover",        { parameter _wStyle. if _wStyle:HasSuffix("Hover")      return _wStyle:Hover.     },
            "Hover_On",     { parameter _wStyle. if _wStyle:HasSuffix("Hover_On")   return _wStyle:Hover_On.  },
            "Active",       { parameter _wStyle. if _wStyle:HasSuffix("Active")     return _wStyle:Active.    },
            "Active_On",    { parameter _wStyle. if _wStyle:HasSuffix("Active_On")  return _wStyle:Active_On. },
            "Focused",      { parameter _wStyle. if _wStyle:HasSuffix("Focused")    return _wStyle:Focused.   },
            "Focused_On",   { parameter _wStyle. if _wStyle:HasSuffix("Focused_On") return _wStyle:Focused_On.}
        )
    ).

    local GUI_Styles to lexicon().
    
    local GUI_WidgetObj to lexicon(
        "Active_ActionCenter", "NUL"
        ,"Active_Button", lex()
        ,"Active_Stack", lex()
        ,"Active_TipBox", "NUL"
    ).

    local GUI_WidgetDelegates to lexicon(
        "Confirm", lex(
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
        ,"Templates", lex(
            "Button", lex(
                "---", { parameter _btn, _prm. local upPrm to _prm - 10. return upPrm. }
            )
        )
    ).
    // #endregion

    // *- Global
    // #region
    global g_GUI to Gui(0).
    global g_GUI_State to false.
    // #endregion

    // Objects that need to be hydrated after above variables
    local GUI_WidgetPreFabs to lexicon(
        "BTN", lexicon(
            "---", { parameter _host, _prm is "NUL". local b to _host:AddButton("---"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. },
            "--",  { parameter _host, _prm is "NUL". local b to _host:AddButton("--"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. },
            "-",   { parameter _host, _prm is "NUL". local b to _host:AddButton("-"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. },
            "-0-", { parameter _host, _prm is "NUL". local b to _host:AddButton("-"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. },
            "+++", { parameter _host, _prm is "NUL". local b to _host:AddButton("+++"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. },
            "++",  { parameter _host, _prm is "NUL". local b to _host:AddButton("++"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. },
            "+",   { parameter _host, _prm is "NUL". local b to _host:AddButton("+"). StyleWidgetByLex(b:Style, GUI_Styles["obtParamButton"]). return b. }
        ),
        "TXF", lexicon(
            "STR", { parameter _host, _prm. if not _prm:IsType("String") { set _prm to _prm:ToString.} else if _prm:IsType("String") { set _prm to TimeSpan(_prm:ToNumber(-99999999)):Full. } else if _prm:IsType("TimeSpan") { set _prm to _prm:Full.} local b to _host:AddTextField(_prm:Full). StyleWidgetByLex(b:Style, GUI_Styles["obtParamTextBox"]). return b. },
            "TSF", { parameter _host, _prm. if not _prm:IsType("String") { if _prm:IsType("Scalar") { set _prm to TimeSpan(_prm):Full:ToString.} else if _prm:IsType("TimeSpan") { set _prm to _prm:Full:ToString.}} local b to _host:AddTextField(_prm). StyleWidgetByLex(b:Style, GUI_Styles["obtParamTextBox"]). return b. }
        ),
        "Stack", lexicon(
            "MiType", lexicon(),
            "ObtPrm", lexicon(
                "TgtInc", lexicon(
                    "Label", list("Inclination", "obtParamLabel"),
                    "Columns", list(
                        list("BTN:---","SP:2","BTN:-","SP:4","TXF:STR","SP:4","BTN:+","SP:2","BTN:+++")
                    )
                )
            ),
            "StgPrm", lexicon()
        )
    ).
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
        parameter _guiHandle is "all".

        if _guiHandle:IsType("String") 
        {
            if _guiHandle = "All"
            {
                set GUI_WidgetObj to lexicon(
                    "Active_ActionCenter", "NUL"
                    ,"Active_Button", lex()
                    ,"Active_Stack", lex()
                ).
            }
        }
    }

    // UpdateGUI :: parameter _guiHandle<GUI> -> errorCode<int>
    //
    global function UpdateGUI
    {
        parameter _guiHandle,
                  _updateMask is "1111". // Updates all sections for now I guess
                                         // "1000" updates only the 
                                         // "0001" updates only the action box

        

        if _updateMask[3] // update the Confirm center
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
                            if GUI_WidgetDelegates:Confirm:HasKey(b:Text)
                            {
                                GUI_WidgetDelegates:Confirm[b:Text]:Call(b:GUI).
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
    
    // Mission Parameter GUI (for editing start params)
    local function NewMissionParamGUI
    {
        local guiWidth to 1280.
        local guiHeight to 0.
        
        
        PurgeGUIObj().

        local guiRoot   to GUI(guiWidth, guiHeight).
        // local guiRootID to guiRoot:AddLabel("guiRoot_NewMissionParam").
        // set guiRootID:Visible to False.
        
        local rootStyle to guiRoot:Style.
        set rootStyle:Padding:H to 4.
        set rootStyle:Padding:V to 4.
        set rootStyle:Width     to guiWidth + 8.

        local rootWindowTitleBox to guiRoot:AddHLayout().
        local rootWindowTitleBar to rootWindowTitleBox:AddLabel("AEA Mission Parameter Editor v0.01").
        local rootTitleBarStyleLex to lex(
            "Align", "Left"
            ,"Width", guiWidth
            ,"Height", 22
            ,"Font", "Aero Matics Italic"//"Digital-7 (mono italic)",//"Unispace Bold"
            ,"FontSize", 28
            ,"TextColor", g_Colors:Orange// Magenta
            ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Margin",   list(12,12,6,6)
        ).
        StyleWidgetByLex(rootWindowTitleBar:Style, rootTitleBarStyleLex).
        
        local mainDisplayArea to guiRoot:AddVLayout().
        local mainDisplayAreaStyleLex to lexicon(
            "Width", guiWidth
            ,"Height", 512
            ,"HStretch", True
            ,"VStretch", True
            ,"Padding", list(8,8,4,4)
        ).
        StyleWidgetByLex(mainDisplayArea:Style, mainDisplayAreaStyleLex).
        
        local mainWindow to mainDisplayArea:AddHLayout().
        local mainWindowStyleLex to lexicon(
            "Width",  guiWidth - 16
            ,"Height", 504
            ,"HStretch", False
            ,"VStretch", True
            ,"Padding", list(8,8,4,4)
            ,"Margin", list(4,4,4,4)
        ).
        StyleWidgetByLex(mainWindow:Style, mainWindowStyleLex).

        local mainWindowLabelStyleLex to lexicon(
            "Align", "Left"
            ,"Font", "Aero Matics Bold"//"Arial Bold"
            ,"FontSize", 16
            ,"TextColor", g_Colors:OldGreen// Magenta
            ,"WordWrap", False
            ,"HStretch", True
            ,"VStretch", False
            ,"Padding",  list(4,4,2,2)
            ,"Margin",   list(4,4,0,4)
        ).

        local editSelectWindow  to mainWindow:AddVBox().
        local editSelectStyleLex to lexicon(
            "Width",  256
            ,"Height", 496
            ,"HStretch", False
            ,"VStretch", False
            ,"Padding", list(8,8,4,4)
            ,"Margin",  list(4,4,4,4)
        ).
        StyleWidgetByLex(editSelectWindow:Style, editSelectStyleLex).
        local mainWindowID to mainWindow:AddLabel("displayArea").
        mainWindowID:Hide().


        local editSelectWindowLabel to editSelectWindow:AddLabel("Current Selection").
        StyleWidgetByLex(editSelectWindowLabel:Style, mainWindowLabelStyleLex).
        
        local editWindowRadioButtonStyleLex to lexicon(
            "Align",    "Left"
            ,"Font",     "Aero Matics Regular" //"Arial",
            ,"FontSize", 16
            ,"TextColor",White// Magenta,
            ,"WordWrap", False
            ,"HStretch", True
            ,"VStretch", False
            ,"Height",   24
            ,"Width",    192
            ,"Margin",   list(4,4,4,4)
            ,"Padding",  list(32,4,0,6)
        ).
        editSelectWindow:AddSpacing(8).
        local missionTypeRadio  to editSelectWindow:AddRadioButton("Mission Type", False).
        editSelectWindow:AddSpacing(2).
        local orbitalParamRadio to editSelectWindow:AddRadioButton("Orbital Parameters", True).
        editSelectWindow:AddSpacing(2).
        local stagingParamRadio to editSelectWindow:AddRadioButton("Staging Parameters", False).
        editSelectWindow:AddSpacing(2).

        for rb in list(missionTypeRadio, orbitalParamRadio, stagingParamRadio)
        {
            StyleWidgetByLex(rb:Style, editWindowRadioButtonStyleLex).
        }

        set editSelectWindow:OnRadioChange to ProcessRadioChange@.

        mainWindow:AddSpacing(8).

        local widthRemaining to mainWindowStyleLex:Width - editSelectStyleLex:Width.
        local stackBaseWindow      to mainWindow:AddVBox().
        local stackBaseWindowStyleLex to lexicon(
            "Width",  mainWindowStyleLex:Width - editSelectStyleLex:Width - 16
            ,"Height", 496
            ,"HStretch", True
            ,"VStretch", True
            ,"Padding", list(8,8,4,4)
            ,"Margin",  list(4,4,4,4)
        ).
        StyleWidgetByLex(stackBaseWindow:Style, stackBaseWindowStyleLex).
        
        local stackBaseWindowLabel to stackBaseWindow:AddLabel("Values").
        StyleWidgetByLex(stackBaseWindowLabel, mainWindowLabelStyleLex).
        // local stackBaseWindowLabelStyleLex to lexicon(
        //     "Width",  564
        //     ,"Height", 20
        //     ,"HStretch", False
        //     ,"VStretch", False
        //     ,"Font", "Cascadia Code"
        //     ,"FontSize", 12
        // ).

        local stackWindow       to stackBaseWindow:AddVLayout().
        local stackWindowStyleLex to lexicon(
            "Width",  widthRemaining - 16
            ,"Height", stackWindow:Parent:Style:Height
            ,"HStretch", True
            ,"VStretch", True
            ,"Padding", list(8,8,4,4)
            ,"Margin",  list(4,4,4,4)
        ).
        // stackWindow:AddSpacing(2).
        
        local stackWindowID     to stackWindow:AddLabel("stackWindow").
        stackWindowID:Hide().
        local missionTypePage       to stackWindow:AddStack().
        local orbitalParameterPage  to stackWindow:AddStack().
        local stagingParameterPage  to stackWindow:AddStack().
        for s in list(missionTypePage, orbitalParameterPage, stagingParameterPage)
        {
            StyleWidgetByLex(s, stackWindowStyleLex).   
        }
        
        GUI_WidgetObj:Active_Stack:Add("MITYPE", Lexicon("Handle", missionTypePage,  "TXF", lex(), "BTN", lex())).
        BuildMissionTypePage(missionTypePage).

        GUI_WidgetObj:Active_Stack:Add("OBTPRM", Lexicon("Handle", orbitalParameterPage, "TXF", lex(), "BTN", lex())).
        BuildOrbitalParamPageNext(orbitalParameterPage).
        
        GUI_WidgetObj:Active_Stack:Add("STGPRM", Lexicon("Handle", stagingParameterPage, "TXF", lex(), "BTN", lex())).
        BuildStagingParamPage(stagingParameterPage).



        GUI_WidgetObj:Active_Stack:Add("Stack", stackWindow).
        GUI_WidgetObj:Active_Stack:Add("Mission Type", missionTypePage).
        GUI_WidgetObj:Active_Stack:Add("Orbital Parameters", orbitalParameterPage).
        GUI_WidgetObj:Active_Stack:Add("Staging Parameters", stagingParameterPage).
        stackWindow:ShowOnly(orbitalParameterPage).
        
        // mainWindow:AddSpacing(4).

        // guiRoot:AddSpacing(2).

        local confirmBox to guiRoot:AddHLayout().
        local confirmBoxStyleLex to rootTitleBarStyleLex:Copy().
        confirmBoxStyleLex:Remove("Align").
        set confirmBoxStyleLex["Align"]  to "RIGHT".
        set confirmBoxStyleLex["Height"] to 42.
        set confirmBoxStyleLex["Width"]  to guiWidth.
        StyleWidgetByLex(confirmBox:Style, confirmBoxStyleLex).

        local confirmBoxID to confirmBox:AddLabel("actionBox").
        confirmBoxID:Hide().

        local toolTipWindow to confirmBox:AddHBox().
        local toolTipWindowStyleLex to lexicon(
            "Align",    "Left"
            ,"Font",     "Arial"
            ,"FontSize", 18
            ,"TextColor",White// Magenta,
            ,"WordWrap", True
            ,"HStretch", False
            ,"VStretch", False
            ,"Height",   42
            ,"Width",    396
            ,"Margin",   list(8,8,4,4)
            ,"Padding",  list(8,8,8,8)
        ).
        StyleWidgetByLex(toolTipWindow, toolTipWindowStyleLex).

        local toolTipBox to confirmBox:AddHBox().
        local toolTipBoxStyleLex to lexicon(
            "Align",    "Left"
            ,"Font",     "Arial"
            ,"FontSize", 18
            ,"TextColor",White// Magenta,
            ,"WordWrap", True
            ,"HStretch", False
            ,"VStretch", False
            ,"Height",   42
            ,"Width",    396
            ,"Margin",   list(4,4,4,4)
            ,"Padding",  list(4,4,4,4)
        ).
        StyleWidgetByLex(toolTipBox, toolTipBoxStyleLex).
        local toolTip to toolTipBox:AddTipDisplay.
        set GUI_WidgetObj:Active_TipBox to toolTip.

        confirmBox:AddSpacing(guiWidth - 4).

        local revertButton to confirmBox:AddButton("Revert").
        local closeButton to confirmBox:AddButton("Close").
        local saveButton  to confirmBox:AddButton("Save").
        local confirmButtonStyleLex to lexicon(
            "Align",    "Center"
            ,"Font",     "Aero Matics Regular" //"Arial",
            ,"FontSize", 24
            ,"TextColor",White// Magenta,
            ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Height",   32
            ,"Width",    128
            ,"Margin",   list(4,4,-2,2)
            ,"Padding",  list(4,4,8,8)
        ).
        for cb in list(revertButton, closeButton, saveButton)
        {
            StyleWidgetByLex(cb:Style, confirmButtonStyleLex).
        }
        
        return guiRoot.
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


    // ApplyStyleRectOffsetValues :: _wsroObj <styleRectOffset>, _vals list(<scalar>), 
    local function ApplyStyleRectOffsetValues
    {
        parameter _wsroObj, 
                  _vals.

        if _wsroObj:IsType("StyleRectOffset")
        {
            if _vals:IsType("Scalar")
            {
                set _wsroObj:H to _vals.
                set _wsroObj:V to _vals.
                return _wsroObj:H + _wsroObj:V = _vals * 2.
            }
            else if _vals:IsType("List")
            {
                if _vals:Length = 1
                {
                    set _wsroObj:H to _vals[0].
                    set _wsroObj:V to _vals[0].
                    return _wsroObj:H + _wsroObj:V = _vals[0] * 2.
                }
                else if _vals:Length = 2
                {
                    set _wsroObj:H to _vals[0].
                    set _wsroObj:V to _vals[1].
                    return _wsroObj:H + _wsroObj:V = _vals[0] + _vals[1].
                }
                else if _vals:Length = 4
                {
                    set _wsroObj:Left   to _vals[0].
                    set _wsroObj:Right  to _vals[1].
                    set _wsroObj:Top    to _vals[2].
                    set _wsroObj:Bottom to _vals[3].

                    return _wsroObj:Left + _wsroObj:Right + _wsroObj:Top + _wsroObj:Bottom = _vals[0] + _vals[1] + _vals[2] + _vals[3].
                }
            }
        }

        return false.
    }


    // local function NewOrbitalParamStack
    // {
    //     parameter _pageObj.

    //     if not _pageObj:HasSuffix("AddStack")
    //     {
    //         return -1.
    //     }
    //     else
    //     {
    //         local stackPage to _pageObj:AddStack().

    //         local orbitalParameterPageID to stackPage:AddLabel("OrbitalParameterPage").
    //         orbitalParameterPageID:Hide().

    //         stackPage:AddSpacing(2).
    //         local tgtIncSection     to stackPage:AddVBox().
    //         local tgtIncSectionID   to tgtIncSection:AddLabel("tgtInc").
    //         tgtIncSectionID:Hide().
            
    //         locaL inclinationValueLabel to tgtIncSection:AddLabel("<b>Inclination</b>").
    //         local inclinationLabelStyleLex to lexicon(
    //             "Align", "LEFT",
    //             "Width", 128,
    //             "Height", 32,
    //             "Font", "Unispace Bold",
    //             "FontSize", 14,
    //             "WordWrap", False
    //         ).
    //         StyleWidgetByLex(inclinationValueLabel:Style, inclinationLabelStyleLex).
            
    //         tgtIncSection:AddSpacing(2).
    //         local incDownButton1 to tgtIncSection:AddButton("---").
    //         tgtIncSection:AddSpacing(2).
    //         local incDownButton0 to tgtIncSection:AddButton("-").
    //         tgtIncSection:AddSpacing(2).
    //         local incTextBoxReadout to tgtIncSection:AddTextField("0").
    //         tgtIncSection:AddSpacing(2).
    //         local incUpButton0 to tgtIncSection:AddButton("+").
    //         tgtIncSection:AddSpacing(2).
    //         local incUpButton1 to tgtIncSection:AddButton("+++").
    //         tgtIncSection:AddSpacing(4).

    //         local inclinationButtonStyleLex to lexicon(
    //             "Align", "CENTER",
    //             "Width", 32,
    //             "Height", 28,
    //             "Font", "Unispace Bold",
    //             "FontSize", 10,
    //             "WordWrap", False
    //         ).

    //         for b in list(incDownButton0, incDownButton1, incTextBoxReadout, incUpButton0, incUpButton1)
    //         {
    //             StyleWidgetByLex(b:Style, inclinationButtonStyleLex).
    //         }

    //         local incTextBoxStyleLex to lexicon(
    //             "Align", "CENTER",
    //             "Width", 72,
    //             "Height", 28,
    //             "Font", "Unispace Bold",
    //             "FontSize", 14,
    //             "WordWrap", False
    //         ).
    //         StyleWidgetByLex(incTextBoxReadout:Style, incTextBoxStyleLex).

    //         // _pageObj:AddSpacing(2).
    //         // local tgtApSection to _pageObj:AddHBox().
    //         // local tgtApSectionLabel to tgtApSection:AddLabel("tgtAp").
    //         // tgtApSectionLabel:Hide().

    //         // _pageObj:AddSpacing(2).
    //         // local tgtPeSection to _pageObj:AddHBox().
    //         // local tgtPeSectionLabel to tgtPeSection:AddLabel("tgtPe").
    //         // tgtPeSectionLabel:Hide().

    //         // _pageObj:AddSpacing(2).
    //         // local tgtEccSection to _pageObj:AddHBox().
    //         // local tgtEccSectionLabel to tgtEccSection:AddLabel("tgtEcc").
    //         // tgtEccSectionLabel:Hide().

    //         // _pageObj:AddSpacing(2).
    //         // local tgtPeriodSection to _pageObj:AddHBox().
    //         // local tgtPeriodSectionLabel to tgtPeriodSection:AddLabel("tgtPeriod").
    //         // tgtPeriodSectionLabel:Hide().
            
    //         local orbitalParamSectionStyleLex to lexicon(
    //             "Height", 36
    //         ).
    //         for wdg in stackPage:Widgets
    //         {
    //             if wdg:IsType("Box") StyleWidgetByLex(wdg:Style, orbitalParamSectionStyleLex).
    //         }
    //         stackPage:AddSpacing(2).

    //         return stackPage.
    //     }
    // }

    // BuildMissionTypePage :: (param)<type> [(optionalParam)<type>] -> (output)<type>
    // Function Description
    local function BuildMissionTypePage
    {
        parameter _pageObj.

        // local missionTypePageID to _pageObj:AddLabel("MissionTypePage").
        // missionTypePageID:Hide().

        local missionTypePageLabel to _pageObj:AddLabel("Mission Types").

        return _pageObj.
    }

    // BuildOrbitalParamPage :: _pageObj<guibox> -> _pageObj<guibox>
    local function BuildOrbitalParamPageNext
    {
        parameter _pageObj.

        local pageBox to _pageObj:AddVLayout().
        set pageBox:Style:Width to pageBox:Style:Width.
        set pageBox:Style:Height to pageBox:Style:Height.

        local widthRemaining    to choose _pageObj:Style:Width - (_pageObj:Style:Padding:Left * 12) if _pageObj:Style:Width <> 0 else 896. // 1024 - 256.
        local actionCenterWidth to Round(widthRemaining * 0.96).// 444.
        local paramTextBoxWidth to Round(widthRemaining * 0.30). // 192.
        local buttonWidth       to 36.
        local labelWidth        to Round(widthRemaining * 0.54). // 288.
        local rowHeight         to 42.
        
        local tgtInc     to choose g_MissionTag:Params[0] if g_MissionTag:Params:Length > 0 else 0.
        local tgtApo     to choose g_MissionTag:Params[1] if g_MissionTag:Params:Length > 1 else 175000.
        
        local tgtEcc     to -1. 
        local tgtCircAlt to -1.
        
        if g_MissionTag:Params:Length > 2
        {
            local _p2 to g_MissionTag:Params[2].
            if _p2 = 0
            {
                set tgtCircAlt to tgtApo.
                set tgtEcc to 0.
            }
            else if _p2 > 1
            {
                set tgtCircAlt to _p2.
                set tgtEcc to Round(GetEccFromApPe(Max(tgtApo, tgtCircAlt), Min(tgtApo, tgtCircAlt), Body), 5).
            }
            else if _p2 > 0
            {
                set tgtCircAlt to Round(GetApFromPeEcc(tgtApo, _p2)).
                set tgtEcc to _p2.
            }
            else if _p2 > -1
            {
                set tgtCircAlt to Round(Max(Body:Atm:Height + 10000, GetPeFromApEcc(tgtApo, Abs(_p2)))).
                set tgtEcc to _p2.
            }
        }
        local tgtPeriod  to GetPeriodFromSMA(GetSMAFromApPe(tgtApo, tgtCircAlt)).
        
        local orbitalParameterPageID to pageBox:AddLabel("OrbitalParamPage").
        orbitalParameterPageID:Hide().

        local obtParamRowStyleLex to lexicon(
            "Align", "LEFT"
            ,"Width", widthRemaining + (paramTextBoxWidth * 0.27)
            ,"Height", rowHeight
            ,"HStretch", False
            ,"VStretch", False
            ,"Padding", list(8,8,4,4)
            ,"Margin",  list(4,4,4,4)
        ).
        GUI_Styles:Add("obtParamRow", obtParamRowStyleLex).
        local obtParamButtonStyleLex to lexicon(
            "Align", "CENTER"
            ,"Width", buttonWidth //42
            ,"Height", 28
            ,"Font", "Arial Bold"
            ,"FontSize", 18
            ,"WordWrap", False
            ,"Padding", list(4,4,4,4)
            ,"Margin",  list(4,4,2,6)
        ).
        GUI_Styles:Add("obtParamButton", obtParamButtonStyleLex).
        local obtParamLabelStyleLex to lexicon(
            "Align", "LEFT"
            ,"Width", labelWidth
            ,"Height", 32
            ,"Font", "Cascadia Mono"
            ,"FontSize", 16
            ,"TextColor", White
            ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Margin", list(4,4,0,0)
            ,"Padding", list(4,4,0,0)
        ).
        GUI_Styles:Add("obtParamLabel", obtParamLabelStyleLex).
        local obtParamActionCenterStyleLex to lexicon(
            "Align", "RIGHT"
            ,"Width", actionCenterWidth
            ,"Height", 32
            ,"HStretch", True
            ,"VStretch", True
            ,"Margin", list(4,4,0,0)
            ,"Padding", list(4,4,0,0)
        ).
        GUI_Styles:Add("obtParamActionCenter", obtParamActionCenterStyleLex).
        local obtParamTextBoxStyleLex to lexicon(
            "Align", "CENTER"
            ,"Width", paramTextBoxWidth
            ,"Height", 30
            ,"Font", "digital-7 (italic)"
            ,"FontSize", 28
            ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Margin", list(8,8,4,4)
            ,"Padding", list(4,4,2,10)
        ).
        GUI_Styles:Add("obtParamTextBox", obtParamTextBoxStyleLex).


        local function NewObtParamRow
        {
            parameter _hostWidget,
                      _rowId,
                      _rowType,
                      _rowObjData is lex().

            local rowDat to choose GUI_WidgetPreFabs:Stack[_rowType][_rowId] if GUI_WidgetPreFabs:Stack[_rowType]:HasKey(_rowId) else _rowObjData.

            local newRow to _hostWidget:AddHBox().
            StyleWidgetByLex(newRow:Style, obtParamRowStyleLex).
            local newLabel  to newRow:AddHLayout().
            StyleWidgetByLex(newLabel:Style, obtParamLabelStyleLex).
            local newActionPane to newRow:AddHLayout().
            StyleWidgetByLex(newActionPane:Style, obtParamActionCenterStyleLex).

            local rowSectionID to newRow:AddLabel(_rowId).
            rowSectionID:Hide().

            local valueLabelSection to newLabel:AddHLayout().
            local valueLabel to valueLabelSection:AddLabel(GUI_WidgetPreFabs:Stack:ObtPrm[_rowId]:Label[0]).
            StyleWidgetByLex(valueLabel:Style, obtParamLabelStyleLex).
            
            for _c in rowDat:Columns
            {
                local itemSection     to newActionPane:AddHLayout().
                StyleWidgetByLex(itemSection:Style, obtParamActionCenterStyleLex).
                itemSection:AddSpacing(4).
                for _o in _c
                {
                    local obj to _o:Split(":").

                    local newObj to GUI_WidgetPreFabs[obj[0]][obj[1]].
                    itemSection:AddSpacing(2).
                    local incDownButton0 to itemSection:AddButton("-").
                    itemSection:AddSpacing(2).
                    local incTextBox to itemSection:AddTextField(tgtInc:ToString).
                    itemSection:AddSpacing(2).
                    local incUpButton0 to itemSection:AddButton("+").
                    itemSection:AddSpacing(2).
                    local incUpButton1 to itemSection:AddButton("+++").
                    
                    for b in list(incDownButton0, incDownButton1, incUpButton0, incUpButton1)
                    {
                        StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
                        GUI_WidgetObj:Active_Button.
                    }
                    StyleWidgetByLex(incTextBox:Style, obtParamTextBoxStyleLex).
                    set incTextBox:ToolTip to "Inc: {0}":Format(tgtInc).
                    GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("TgtInc", incTextBox).
                }
                itemSection:AddSpacing(4).
            }
        }

        local rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        local labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        local actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Inclination
        local inclinationValueLabelSection to labelPane:AddHLayout().
        local inclinationValueLabel to inclinationValueLabelSection:AddLabel("Inclination").
        StyleWidgetByLex(inclinationValueLabel:Style, obtParamLabelStyleLex).
        local tgtIncSection     to actionPane:AddHLayout().
        local tgtIncSectionID to tgtIncSection:AddLabel("tgtInc").
        tgtIncSectionID:Hide().
        local tgtIncActionSection to tgtIncSection:AddHLayout().
        StyleWidgetByLex(tgtIncActionSection:Style, obtParamActionCenterStyleLex).
        tgtIncActionSection:AddSpacing(8).
        local incDownButton1 to tgtIncActionSection:AddButton("---").
        tgtIncActionSection:AddSpacing(2).
        local incDownButton0 to tgtIncActionSection:AddButton("-").
        tgtIncActionSection:AddSpacing(2).
        local incTextBox to tgtIncActionSection:AddTextField(tgtInc:ToString).
        tgtIncActionSection:AddSpacing(2).
        local incUpButton0 to tgtIncActionSection:AddButton("+").
        tgtIncActionSection:AddSpacing(2).
        local incUpButton1 to tgtIncActionSection:AddButton("+++").
        tgtIncActionSection:AddSpacing(4).
        for b in list(incDownButton0, incDownButton1, incUpButton0, incUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
            GUI_WidgetObj:Active_Button.
        }
        StyleWidgetByLex(incTextBox:Style, obtParamTextBoxStyleLex).
        set incTextBox:ToolTip to "Inc: {0}":Format(tgtInc).
        GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("TgtInc", incTextBox).

        pageBox:AddSpacing(4).

        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Apoapsis
        local tgtApoSection     to actionPane:AddHLayout().
        local tgtApoSectionID to tgtApoSection:AddLabel("tgtApo").
        tgtApoSectionID:Hide().
        
        local tgtApoLabelSection to labelPane:AddHLayout().
        local tgtApoValueLabel to tgtApoLabelSection:AddLabel("Initial Target Apoapsis").
        StyleWidgetByLex(tgtApoValueLabel:Style, obtParamLabelStyleLex).
        local tgtApoActionSection to tgtApoSection:AddHLayout().
        StyleWidgetByLex(tgtApoActionSection:Style, obtParamActionCenterStyleLex).
        tgtApoActionSection:AddSpacing(8).
        local tgtApoDownButton1 to tgtApoActionSection:AddButton("---").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoDownButton0 to tgtApoActionSection:AddButton("-").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoTextBox to tgtApoActionSection:AddTextField(tgtApo:ToString).
        tgtApoActionSection:AddSpacing(2).
        local tgtApoUpButton0 to tgtApoActionSection:AddButton("+").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoUpButton1 to tgtApoActionSection:AddButton("+++").
        tgtApoActionSection:AddSpacing(4).
        for b in list(tgtApoDownButton0, tgtApoDownButton1, tgtApoUpButton0, tgtApoUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(tgtApoTextBox:Style, obtParamTextBoxStyleLex).
        set tgtApoTextBox:ToolTip to "Apo: {0}":Format(tgtApo).
        GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("TgtApo", tgtApoTextBox).

        pageBox:AddSpacing(4).

        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Circularization Altitude
        local tgtCircAltSection     to actionPane:AddHLayout().
        local tgtCircAltSectionID to tgtCircAltSection:AddLabel("tgtCircAlt").
        tgtCircAltSectionID:Hide().
        local tgtCircAltLabelSection to labelPane:AddHLayout().
        local tgtCircAltValueLabel to tgtCircAltLabelSection:AddLabel("Target Circularization Altitude").
        StyleWidgetByLex(tgtCircAltValueLabel:Style, obtParamLabelStyleLex).
        
        local tgtCircAltActionSection to tgtCircAltSection:AddHLayout().
        StyleWidgetByLex(tgtCircAltActionSection:Style, obtParamActionCenterStyleLex).
        tgtCircAltActionSection:AddSpacing(8).
        local tgtCircAltDownButton1 to tgtCircAltActionSection:AddButton("---").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltDownButton0 to tgtCircAltActionSection:AddButton("-").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltTextBox to tgtCircAltActionSection:AddTextField(tgtCircAlt:ToString).
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltUpButton0 to tgtCircAltActionSection:AddButton("+").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltUpButton1 to tgtCircAltActionSection:AddButton("+++").
        tgtCircAltActionSection:AddSpacing(4).
        for b in list(tgtCircAltDownButton0, tgtCircAltDownButton1, tgtCircAltUpButton0, tgtCircAltUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(tgtCircAltTextBox:Style, obtParamTextBoxStyleLex).
        set tgtCircAltTextBox:ToolTip to "CircAlt: {0}":Format(tgtCircAlt).
        GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("TgtCircAlt", tgtCircAltTextBox).


        pageBox:AddSpacing(4).


        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Eccentricity
        local tgtEccSection     to actionPane:AddHLayout().
        local tgtEccSectionID to tgtEccSection:AddLabel("tgtEcc").
        tgtEccSectionID:Hide().
        local tgtEccLabelSection     to labelPane:AddHLayout().
        local tgtEccValueLabel to tgtEccLabelSection:AddLabel("Initial Eccentricty").
        StyleWidgetByLex(tgtEccValueLabel:Style, obtParamLabelStyleLex).
        local tgtEccActionSection to tgtEccSection:AddHLayout().
        StyleWidgetByLex(tgtEccActionSection:Style, obtParamActionCenterStyleLex).
        tgtEccActionSection:AddSpacing(8).
        local tgtEccDownButton1 to tgtEccActionSection:AddButton("---").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccDownButton0 to tgtEccActionSection:AddButton("-").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccTextBox to tgtEccActionSection:AddTextField(tgtEcc:ToString).
        tgtEccActionSection:AddSpacing(2).
        local tgtEccUpButton0 to tgtEccActionSection:AddButton("+").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccUpButton1 to tgtEccActionSection:AddButton("+++").
        tgtEccActionSection:AddSpacing(4).
        for b in list(tgtEccDownButton0, tgtEccDownButton1, tgtEccUpButton0, tgtEccUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(tgtEccTextBox:Style, obtParamTextBoxStyleLex).
        set tgtEccTextBox:ToolTip to "Ecc: {0}":Format(tgtEcc).
        GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("TgtEcc", tgtEccTextBox).


        pageBox:AddSpacing(4).


        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).
        
        // Target post-circ orbital period
        local obtPerSection     to actionPane:AddHLayout().
        local obtPerSectionId to obtPerSection:AddLabel("obtPer").
        obtPerSectionId:Hide().
        local obtPerLabelSection     to labelPane:AddHLayout().
        local obtPerValueLabel to obtPerLabelSection:AddLabel("Post-Burn Orbital Period").
        StyleWidgetByLex(obtPerValueLabel:Style, obtParamLabelStyleLex).

        local obtPerActionSection to obtPerSection:AddHLayout().
        StyleWidgetByLex(obtPerActionSection:Style, obtParamActionCenterStyleLex).
        obtPerActionSection:AddSpacing(8).
        local obtPerDownButton1 to obtPerActionSection:AddButton("---").
        obtPerActionSection:AddSpacing(2).
        local obtPerDownButton0 to obtPerActionSection:AddButton("-").
        obtPerActionSection:AddSpacing(2).
        local obtPerTextBox to obtPerActionSection:AddTextField(tgtPeriod:ToString).
        obtPerActionSection:AddSpacing(2).
        local obtPerUpButton0 to obtPerActionSection:AddButton("+").
        obtPerActionSection:AddSpacing(2).
        local obtPerUpButton1 to obtPerActionSection:AddButton("+++").
        obtPerActionSection:AddSpacing(4).
        for b in list(obtPerDownButton0, obtPerDownButton1, obtPerUpButton0, obtPerUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(obtPerTextBox:Style, obtParamTextBoxStyleLex).
        set obtPerTextBox:ToolTip to "Period: {0} ":Format(TimeSpan(tgtCircAlt):Full).
        GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("ObtPer", obtPerTextBox).


        pageBox:AddSpacing(4).

        pageBox:AddSpacing(2).

        return _pageObj.
    }

    // BuildOrbitalParamLine
    local function BuildOrbitalParamLine
    {
        parameter _hostGuiObj,
                  _paramRef,
                  _paramID,
                  _lineData is list("NUL"),
                  _styleSet is GUI_Styles.

        local rowPane to _hostGuiObj:AddHBox().
        local sectionID to rowPane:AddLabel(_paramID).
        SectionID:Hide().
        StyleWidgetByLex(rowPane:Style, _styleSet["obtParamRow"]).
        local labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, _styleSet["obtParamLabel"]).
        local actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, _styleSet["obtParamActionCenter"]).

        // Label Section
        local labelSection to labelPane:AddHLayout().
        local labelValue to labelSection:AddLabel(_lineData[0]).
        StyleWidgetByLex(labelValue:Style, _styleSet["obtParamLabel"]).

        // Action Section
        local actionSection to actionPane:AddHLayout().
        StyleWidgetByLex(actionSection:Style, _styleSet["obtParamActionCenter"]).
        actionSection:AddSpacing(8).

        set _lineData to list("BTN:---","BTN:-","TXF:STR", "BTN:+","BTN:+++").

        for datStr in _lineData
        {
            local dat to datStr:Split(":").
            local newObj to "".
            
            if GUI_WidgetPreFabs:HasKey(dat[0])
            {
                if GUI_WidgetPreFabs[dat[0]]:HasKey(dat[1])
                {
                    set newObj to GUI_WidgetPreFabs[dat[0]][dat[1]]:Call(actionSection, _paramRef).

                }
            }

            if dat[0] = "BTN"
            {
                GUI_WidgetObj:Active_Stack["OBTPRM"]:BTN:Add(dat[1], GUI_WidgetDelegates("---")).
            }

        }

        StyleWidgetByLex(incTextBox:Style, obtParamTextBoxStyleLex).
        set incTextBox:ToolTip to "Inc: {0}":Format(tgtInc).
        GUI_WidgetObj:Active_Stack["OBTPRM"]:TXF:Add("TgtInc", incTextBox).

        return 0.
    }

    // BuildOrbitalParamPage :: _pageObj<guibox> -> _pageObj<guibox>
    local function BuildOrbitalParamPage
    {
        parameter _pageObj.

        local pageBox to _pageObj:AddVLayout().
        set pageBox:Style:Width to pageBox:Style:Width.
        set pageBox:Style:Height to pageBox:Style:Height.


        local widthRemaining    to choose _pageObj:Style:Width - (_pageObj:Style:Padding:Left * 4) if _pageObj:Style:Width <> 0 else 896. // 1024 - 256.
        local actionCenterWidth to Round(widthRemaining * 0.76).// 444.
        local paramTextBoxWidth to Round(widthRemaining * 0.22). // 192.
        local buttonWidth       to 32.
        local labelWidth        to Round(widthRemaining * 0.42). // 288.
        local valueWidth        to 320.
        local paneHeight        to 496.
        local rowHeight         to 36.
        local rowWidth          to 874.

        local orbitalParameterPageID to pageBox:AddLabel("OrbitalParamPage").
        orbitalParameterPageID:Hide().

        local obtParamRowStyleLex to lexicon(
            "Align", "LEFT"
            ,"Width", widthRemaining - 8 //42
            ,"Height", rowHeight
            // ,"Font", "Arial Bold"
            // ,"FontSize", 18
            // ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Margin", list(2,2,2,2)
            ,"Padding", list(2,2,2,2)
        ).
        local obtParamButtonStyleLex to lexicon(
            "Align", "CENTER"
            ,"Width", buttonWidth //42
            ,"Height", 28
            ,"Font", "Arial Bold"
            ,"FontSize", 18
            ,"WordWrap", False
            ,"Margin", list(2,2,2,2)
            ,"Padding", list(4,4,4,4)
        ).
        local obtParamSectionStyleLex to lexicon(
            "Align", "LEFT"
            ,"Width", widthRemaining
            ,"Height", 32
            ,"Font", "Cascadia Mono"
            ,"FontSize", 16
            ,"TextColor", White
            ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Margin", list(4,2,2,2)
            ,"Padding", list(4,4,2,2)
        ).
        local obtParamLabelStyleLex to lexicon(
            "Align", "LEFT"
            ,"Width", labelWidth
            ,"Height", 32
            ,"Font", "Cascadia Mono"
            ,"FontSize", 16
            ,"TextColor", White
            ,"WordWrap", False
            ,"HStretch", False
            ,"VStretch", False
            ,"Margin", list(4,4,0,0)
            ,"Padding", list(4,4,0,0)
        ).
        local obtParamActionCenterStyleLex to lexicon(
            "Align", "RIGHT"
            ,"Width", actionCenterWidth
            ,"Height", 32
            ,"HStretch", True
            ,"VStretch", True
            ,"Margin", list(4,4,2,2)
            ,"Padding", list(4,4,2,2)
        ).
        local obtParamTextBoxStyleLex to lexicon(
            "Align", "CENTER"
            ,"Width", paramTextBoxWidth
            ,"Height", 24
            ,"Font", "digital-7 (italic)"
            ,"FontSize", 24
            ,"WordWrap", False
            ,"HStretch", True
            ,"VStretch", False
            ,"Margin", list(2,2,2,2)
            ,"Padding", list(4,4,0,0)
        ).
        local obtParamValueStyleLex to lexicon(
            "Align", "CENTER"
            ,"Width", valueWidth
            ,"Height", paneHeight
            ,"Font", "digital-7 (italic)"
            ,"FontSize", 24
            ,"TextColor", White
            ,"WordWrap", False
            ,"HStretch", True
            ,"VStretch", False
            ,"Margin", list(4,2,2,2)
            ,"Padding", list(4,4,2,2)
        ).

        local rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        local labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        local actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).
        
        // local valuePane  to pageBox:AddVLayout().
        // local valuePaneStyleLex to obtParamSectionStyleLex:Copy().
        // set valuePaneStyleLex:Width to valueWidth.
        // set valuePaneStyleLex:Height to paneHeight.
        // set valuePaneStyleLex:Font to "digital-7 (italic)".
        // StyleWidgetByLex(valuePane:Style, valuePaneStyleLex).

        // Target Inclination
        local inclinationValueLabelSection to labelPane:AddHLayout().
        local inclinationValueLabel to inclinationValueLabelSection:AddLabel("Inclination").
        StyleWidgetByLex(inclinationValueLabel:Style, obtParamLabelStyleLex).
        local tgtIncSection     to actionPane:AddHLayout().
        local tgtIncSectionID to tgtIncSection:AddLabel("tgtInc").
        tgtIncSectionID:Hide().
        local tgtIncActionSection to tgtIncSection:AddHLayout().
        StyleWidgetByLex(tgtIncActionSection:Style, obtParamActionCenterStyleLex).
        tgtIncActionSection:AddSpacing(8).
        local incDownButton1 to tgtIncActionSection:AddButton("---").
        tgtIncActionSection:AddSpacing(2).
        local incDownButton0 to tgtIncActionSection:AddButton("-").
        tgtIncActionSection:AddSpacing(2).
        local incTextBoxReadout to tgtIncActionSection:AddTextField(widthRemaining:ToString).
        tgtIncActionSection:AddSpacing(2).
        local incUpButton0 to tgtIncActionSection:AddButton("+").
        tgtIncActionSection:AddSpacing(2).
        local incUpButton1 to tgtIncActionSection:AddButton("+++").
        tgtIncActionSection:AddSpacing(4).
        for b in list(incDownButton0, incDownButton1, incUpButton0, incUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(incTextBoxReadout:Style, obtParamTextBoxStyleLex).

        pageBox:AddSpacing(4).

        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Apoapsis
        local tgtApoSection     to actionPane:AddHBox().
        local tgtApoSectionID to tgtApoSection:AddLabel("tgtApo").
        tgtApoSectionID:Hide().
        
        local tgtApoLabelSection to labelPane:AddHLayout().
        local tgtApoValueLabel to tgtApoLabelSection:AddLabel("Initial Target Apoapsis").
        StyleWidgetByLex(tgtApoValueLabel:Style, obtParamLabelStyleLex).
        local tgtApoActionSection to tgtApoSection:AddHLayout().
        StyleWidgetByLex(tgtApoActionSection:Style, obtParamActionCenterStyleLex).
        tgtApoActionSection:AddSpacing(8).
        local tgtApoDownButton1 to tgtApoActionSection:AddButton("---").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoDownButton0 to tgtApoActionSection:AddButton("-").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoTextBoxReadout to tgtApoActionSection:AddTextField("0").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoUpButton0 to tgtApoActionSection:AddButton("+").
        tgtApoActionSection:AddSpacing(2).
        local tgtApoUpButton1 to tgtApoActionSection:AddButton("+++").
        tgtApoActionSection:AddSpacing(4).
        for b in list(tgtApoDownButton0, tgtApoDownButton1, tgtApoUpButton0, tgtApoUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(tgtApoTextBoxReadout:Style, obtParamTextBoxStyleLex).

        pageBox:AddSpacing(4).

        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Circularization Altitude
        local tgtCircAltSection     to actionPane:AddHLayout().
        local tgtCircAltSectionID to tgtCircAltSection:AddLabel("tgtCircAlt").
        tgtCircAltSectionID:Hide().
        local tgtCircAltLabelSection to labelPane:AddHLayout().
        local tgtCircAltValueLabel to tgtCircAltLabelSection:AddLabel("Target Circularization Altitude").
        StyleWidgetByLex(tgtCircAltValueLabel:Style, obtParamLabelStyleLex).
        local tgtCircAltActionSection to tgtCircAltSection:AddHLayout().
        StyleWidgetByLex(tgtCircAltActionSection:Style, obtParamActionCenterStyleLex).
        tgtCircAltActionSection:AddSpacing(8).
        local tgtCircAltDownButton1 to tgtCircAltActionSection:AddButton("---").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltDownButton0 to tgtCircAltActionSection:AddButton("-").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltTextBoxReadout to tgtCircAltActionSection:AddTextField("0").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltUpButton0 to tgtCircAltActionSection:AddButton("+").
        tgtCircAltActionSection:AddSpacing(2).
        local tgtCircAltUpButton1 to tgtCircAltActionSection:AddButton("+++").
        tgtCircAltActionSection:AddSpacing(4).
        for b in list(tgtCircAltDownButton0, tgtCircAltDownButton1, tgtCircAltUpButton0, tgtCircAltUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(tgtCircAltTextBoxReadout:Style, obtParamTextBoxStyleLex).

        pageBox:AddSpacing(4).

        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target Eccentricity
        local tgtEccSection     to actionPane:AddHLayout().
        local tgtEccSectionID to tgtEccSection:AddLabel("tgtEcc").
        tgtEccSectionID:Hide().
        local tgtEccLabelSection     to labelPane:AddHLayout().
        local tgtEccValueLabel to tgtEccLabelSection:AddLabel("Initial Eccentricty").
        StyleWidgetByLex(tgtEccValueLabel:Style, obtParamLabelStyleLex).
        local tgtEccActionSection to tgtEccSection:AddHLayout().
        StyleWidgetByLex(tgtEccActionSection:Style, obtParamActionCenterStyleLex).
        tgtEccActionSection:AddSpacing(8).
        local tgtEccDownButton1 to tgtEccActionSection:AddButton("---").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccDownButton0 to tgtEccActionSection:AddButton("-").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccTextBoxReadout to tgtEccActionSection:AddTextField("0").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccUpButton0 to tgtEccActionSection:AddButton("+").
        tgtEccActionSection:AddSpacing(2).
        local tgtEccUpButton1 to tgtEccActionSection:AddButton("+++").
        tgtEccActionSection:AddSpacing(4).
        for b in list(tgtEccDownButton0, tgtEccDownButton1, tgtEccUpButton0, tgtEccUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(tgtEccTextBoxReadout:Style, obtParamTextBoxStyleLex).

        pageBox:AddSpacing(4).

        set rowPane to pageBox:AddHBox().
        StyleWidgetByLex(rowPane:Style, obtParamRowStyleLex).
        set labelPane  to rowPane:AddHLayout().
        StyleWidgetByLex(labelPane:Style, obtParamLabelStyleLex).
        set actionPane to rowPane:AddHLayout().
        StyleWidgetByLex(actionPane:Style, obtParamActionCenterStyleLex).

        // Target post-circ orbital period
        local obtPerSection     to actionPane:AddHLayout().
        local obtPerSectionId to obtPerSection:AddLabel("obtPer").
        obtPerSectionId:Hide().
        local obtPerLabelSection     to labelPane:AddHlayout().
        local obtPerValueLabel to obtPerLabelSection:AddLabel("Post-Burn Orbital Period").
        StyleWidgetByLex(obtPerValueLabel:Style, obtParamLabelStyleLex).

        local obtPerActionSection to obtPerSection:AddHLayout().
        StyleWidgetByLex(obtPerActionSection:Style, obtParamActionCenterStyleLex).
        obtPerActionSection:AddSpacing(8).
        local obtPerDownButton1 to obtPerActionSection:AddButton("---").
        obtPerActionSection:AddSpacing(2).
        local obtPerDownButton0 to obtPerActionSection:AddButton("-").
        obtPerActionSection:AddSpacing(2).
        local obtPerTextBoxReadout to obtPerActionSection:AddTextField(TimeSpan(Orbit:Period):Full).
        obtPerActionSection:AddSpacing(2).
        local obtPerUpButton0 to obtPerActionSection:AddButton("+").
        obtPerActionSection:AddSpacing(2).
        local obtPerUpButton1 to obtPerActionSection:AddButton("+++").
        obtPerActionSection:AddSpacing(4).
        for b in list(obtPerDownButton0, obtPerDownButton1, obtPerUpButton0, obtPerUpButton1)
        {
            StyleWidgetByLex(b:Style, obtParamButtonStyleLex).
        }
        StyleWidgetByLex(obtPerTextBoxReadout:Style, obtParamTextBoxStyleLex).
        pageBox:AddSpacing(4).
        
        // local orbitalParamSectionStyleLex to lexicon(
        //     "Height", 36
        // ).
        // for wdg in pageBox:Widgets
        // {
        //     if wdg:IsType("Box") StyleWidgetByLex(wdg:Style, orbitalParamSectionStyleLex).
        // }
        pageBox:AddSpacing(2).

        return _pageObj.
    }

    // BuildStagingParam
    local function BuildStagingParamPage
    {
        parameter _pageObj.

        _pageObj:AddLabel("This is the Staging Parameter Page").
        _pageObj:AddSpacing(4).

        return _pageObj.
    }

    // StyleWidgetByLex
    // Takes in a lexicon of style names and values and applies those to the provided style
    local function StyleWidgetByLex
    {
        parameter _widgetStyle,
                  _styleLex is lex(),
                  _styleState is 0.

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
            else
            {
                OutInfo("styName / _widgetType: {0} / {1} ":Format(styName, _widgetStyle), 2).
            }
        }
        
        return len - cnt.
    }
    
    // #endregion

    
// #endregion