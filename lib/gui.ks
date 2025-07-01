@LazyGlobal off.

// *~ Dependencies ~* //
// #region

// #endregion

// *~ Variables ~* //
// #region
    // *- Global (Used outside of library)
    // #region
    
    // #endregion

    // *- Local (Global within library)
    // #region
    local TabWidget_alltabs is List().
    local TabWidget_allpanels is List().

    local __styleDelegates is lexicon(
        "offset", lex(
            // Combo
            "LRTB",  { parameter _inRectOffset, _lrtbList. return SetRectOffset(_inRectOffset, _lrtbList). }, // Number of pixels on all four sides
            "HV",    { parameter _inRectOffset, _lrtbList. return SetRectOffset(_inRectOffset, _lrtbList). }, // Number of pixels in H(orizontal) and V(ertical) dimensions
            // Single-value
            "LEFT",  lex("val", 0, "del", { parameter _inRectOffset, _newVal. set _inRectOffset:LEFT   to _newVal. return _inRectOffset. }), // Number of pixels on the left.
            "RIGHT", lex("val", 0, "del", { parameter _inRectOffset, _newVal. set _inRectOffset:RIGHT  to _newVal. return _inRectOffset. }), // Number of pixels on the right.
            "TOP",   lex("val", 0, "del", { parameter _inRectOffset, _newVal. set _inRectOffset:TOP    to _newVal. return _inRectOffset. }), // Number of pixels on the top.
            "BOTTOM",lex("val", 0, "del", { parameter _inRectOffset, _newVal. set _inRectOffset:BOTTOM to _newVal. return _inRectOffset. }), // Number of pixels on the bottom.
            "H",     lex("val", 0, "del", { parameter _inRectOffset, _newVal. set _inRectOffset:H      to _newVal. return _inRectOffset. }), // Sets the number of pixels on both the left and right. Reading returns LEFT.
            "V",     lex("val", 0, "del", { parameter _inRectOffset, _newVal. set _inRectOffset:V      to _newVal. return _inRectOffset. })
        )
    ).

    local __styleObjects is lexicon(
        "rect", lex(
            "offset", lex(
                "ALIGN",    "CENTER", // "LEFT|CENTER|RIGHT"
                "BG",       "",                // Name of a “9-slice” image file. 
                "FONT",     "",
                "FONTSIZE", 12,
                "HEIGHT",   0,
                "WIDTH",    0,
                "LEFT",     0,
                "RIGHT",    0,
                "TOP",      0,
                "BOTTOM",   0,
                "HSTRETCH", True,
                "VSTRETCH", True,
                "RICHTEXT", True,
                "WORDWRAP", False,
                "TEXTCOLOR",RGBA(1, 1, 1, 1),  // RGBA Text Color for this state
                "BORDER",   lex(),
                "MARGIN",   lex(),
                "OVERFLOW", lex(),
                "PADDING",  lex()
                  // Sets the number of pixels on both the top and bottom. Reading returns TOP.
            ),
            "INIT",     { parameter _styleObj. }
        ),
        "tab", lex(
            "offset", lex(
                "TYPE", "HV",
                "VALS",   list(64, 24)
            )
        ),
        "stylestate", lex(
            "ALIGN",    "CENTER", // "LEFT|CENTER|RIGHT"
            "BG",       "",                // Name of a “9-slice” image file. 
            "FONT",     "",
            "FONTSIZE", 12,
            "HEIGHT",   0,
            "WIDTH",    0,
            "HSTRETCH", True,
            "VSTRETCH", True,
            "RICHTEXT", True,
            "WORDWRAP", False,
            "TEXTCOLOR",RGBA(1, 1, 1, 1),  // RGBA Text Color for this state
            "BORDER",   lex(),
            "MARGIN",   lex(),
            "OVERFLOW", lex(),
            "PADDING",  lex()
        ),
        "validstates", list(
            "NORMAL",
            "ON",
            "HOVER",
            "HOVER_ON",
            "ACTIVE",
            "ACTIVE_ON",
            "FOCUSED",
            "FOCUSED_ON"
        )
    ).

    // Style reference: https://ksp-kos.github.io/KOS/structures/gui_widgets/style.html#structure:STYLE
    global __guiStyles is lexicon(
        "base", lex(
            "TAB", lex(
                "TYPE",     "tab",
                "STYLE",    "tab_off",
                "STATE", lex(
                    "ON", lex( 
                        "STYLE", "tab_on"
                    ),
                    "HOVER", lex(
                        "BG", ""
                    ),
                    "HOVER_ON", lex(
                        "BG", ""
                    )
                )
            ),
            "PANEL", lex(
                "BG", "assets/gui/def/Panel",
                "TEXTCOLOR", RGBA(0.7,0.75,0.7,1)
                
            )
        ),
        "APL", lex(
            "PANELBASE", lex(
                "BG",       "assets/gui/cm_panel_base_v3.png",
                "TEXTCOLOR",RGBA(0.7,0.75,0.7,1),
                // "POS",      list(),  // Width, Height
                "STRETCH",  list(true, true),  // H, V
                "MARGIN", list(16),
                "BORDER", list(64, 64),
                "PADDING", list(16, 16)
            ),
            "PANEL0", lex(
                "BG",       "assets/gui/cmp_base_128.png",
                "TEXTCOLOR",RGBA(0.7,0.75,0.7,1),
                // "POS",      list(),  // Width, Height
                "STRETCH",  list(true, true),  // H, V
                "MARGIN", list(32),
                "BORDER", list(48, 48),
                "PADDING", list(8, 8)
            ),
           "PANEL1", lex(
                "BG",       "assets/gui/cmpanel_bg_0-80.png",
                "TEXTCOLOR",RGBA(0.7,0.75,0.7,1),
                // "POS",      list(),  // Width, Height
                "STRETCH",  list(true, true),  // H, V
                "MARGIN", list(32),
                "BORDER", list(16, 16)
            ),
            "PANEL2", lex(
                "BG", "assets/gui/cmpanel_bg_2.png",
                "TEXTCOLOR", RGBA(0.7,0.75,0.7,1),
                "MARGIN", list(8, 8),
                "PADDING", list(32),
                "BORDER", list(48, 48)
            )
        )
    ).
    // #endregion
// #endregion

// *- Types 
// #region

// #endregion

// *- Delegates
// #region

// #endregion


// *** Library Setup Code *** //
// This should rarely be used! //
// #region

// #endregion

// *~ Functions ~* //
// #region

    // *- Object init
    // #region
    global function AddBoxWidget 
    {
        parameter _box,
                  _styleLex is __guiStyles:BASE.


    }

    // *- Tutorial Functions (From: https://ksp-kos.github.io/KOS/tutorials/gui.html)
    // #region

    // AddTabWidget :: <box> -> vBox<Box>
    // This function takes any box as a parameter (eg. the top level GUI, or one created by GUI:ADDVLAYOUT, GUI:ADDSCROLLBOX, etc.
    global function AddTabWidget
    {
            // Any box is allowed
            parameter _box,
                      _styleLex is __guiStyles:BASE.

            // See if styles for the TabWidget components (tabs and panels) has
            // already been defined elsewhere. If not, define each one

            if not _box:GUI:SKIN:HAS("TabWidgetTab") {

                // The style for tabs is like a button, but it should smoothly connect
                // to the panel below it, especially if it is the current selected tab.

                local style is _box:GUI:SKIN:ADD("TabWidgetTab",_box:GUI:SKIN:BUTTON).

                // Images are stored alongside the code.
                local tabStyle to _styleLex:TAB.

                set style to SetStyle(style, tabStyle).

                // for keyID in tabStyle:Keys {
                //     if keyID = "STATE" {
                //         for stateKeyID in tabStyle[keyID]:Keys {
                //             local stateStyle to _styleLex[stateKeyID].
                //             for stateStyleKeyID in stateStyle:Keys {
                //                 set style:(stateKeyID):(stateStyleKeyID) to stateStyle[stateStyleKeyID].
                //             }
                //         }
                //     }
                //     else {
                //         set style:(keyID) to tabStyle[keyID].
                //     }
                // }

                // set style:BG    to _styleLex:TAB:BG.
                // set style:ON:BG to _styleLex:TAB:STATE:ON:BG.
                // // Tweak the style.
                // set style:TEXTCOLOR to _styleLex:TAB:TEXTCOLOR.
                // set style:HOVER:BG to _styleLex:TAB:STATE:HOVER:BG.
                // set style:HOVER_ON:BG to _styleLex:TAB:STATE:HOVER_ON:BG.
                // set style:MARGIN:H to _styleLex:TAB:MARGIN:H.
                // set style:MARGIN:BOTTOM to _styleLex:TAB:MARGIN:BOTTOM.
            }
            if not _box:GUI:SKIN:HAS("TabWidgetPanel") {
                local style is _box:GUI:SKIN:ADD("TabWidgetPanel",_box:GUI:SKIN:WINDOW).
                local panelStyle to _styleLex:PANEL.
                set style to SetStyle(style, panelStyle).
                // set style:BG to panelStyle:BG.
                // set style:PADDING:TOP to panelStyle:PADDING:TOP.
            }

            // Add a vlayout (in case the box is a HBOX, for example),
            // then add a hlayout for the tabs and a stack to hols all the panels.
            local vbox is _box:ADDVLAYOUT.
            local tabs is vbox:ADDHLAYOUT.
            local panels is vbox:ADDSTACK.

            // any other customization of tabs and panels goes here

            // Return the empty TabWidget.
            return vbox.
    }

    // AddTab :: tabwidget<vbox>, tabname<string> -> panel<vbox>
    // This function takes a TabWidget created by the previous function and adds another tab to the end with a given name. 
    // returns a VBOX into which widgets for that page of the TabWidget can be added.
    declare function AddTab
    {
            declare parameter tabwidget. // (the vbox)
            declare parameter tabname. // title for the tab

            // Get back the two widgets we created in AddTabWidget
            local hboxes is tabwidget:WIDGETS.
            local tabs is hboxes[0]. // the HLAYOUT
            local panels is hboxes[1]. // the STACK

            // Add another panel, style it correctly
            local panel is panels:ADDVBOX.
            set panel:STYLE to panel:GUI:SKIN:GET("TabWidgetPanel").

            // Add another tab, style it correctly
            local tab is tabs:ADDBUTTON(tabname).
            set tab:STYLE to tab:GUI:SKIN:GET("TabWidgetTab").

            // Set the tab button to be exclusive - when
            // one tab goes up, the others go down.
            set tab:TOGGLE to true.
            set tab:EXCLUSIVE to true.

            // If this is the first tab, make it start already shown (make the tab presssed)
            // Otherwise, we hide it (even though the STACK will only show the first anyway,
            // but by keeping everything "correct", we can be a little more efficient later.
            if panels:WIDGETS:LENGTH = 1 {
                    set tab:PRESSED to true.
                    panels:SHOWONLY(panel).
            } else {
                    panel:HIDE().
            }

            // Add the tab and its corresponding panel to global variables,
            // in order to handle interaction later.
            TabWidget_alltabs:ADD(tab).
            TabWidget_allpanels:ADD(panel).

            return panel.
    }
    // #endregion

    // *- Widget actions
    // #region

    // ChooseTab :: tabwidget<Tab>, tabnum<Scalar> -> (none)
    // Will set the given tabwidget to the given tab index
    declare function ChooseTab
    {
        declare parameter tabwidget. // The tab
        declare parameter tabnum. // Which tab to choose (0 is first)
        // Find the tabs hlayout - is is the first of the two we added
        local hboxes is tabwidget:WIDGETS.
        local tabs is hboxes[0].
        // Find the tab, and set it to be pressed
        set tabs:WIDGETS[tabnum]:PRESSED to true.
    }

    // SetupTabTrigger ::
    // Rather than ask the user to repeatedly call a function to run the TabWidget, we instead use a “trick” to watch 
    //   the tab buttons to see if they get pressed, and raise the corresponding tab if they are
    global function SetupTabTrigger 
    {
        parameter TabWidget.
        
        when True then {
            from { local x is 0.} until x >= TabWidget_alltabs:LENGTH step { set x to x+1.} DO {
                    // Earlier, we were careful to hide the panels that were not the current
                    // one when they were added, so we can test if the panel is VisIBLE
                    // to avoid the more expensive call to SHOWONLY every frame.
                    if TabWidget_alltabs[x]:PRESSED AND not TabWidget_allpanels[x]:VisIBLE {
                            TabWidget_allpanels[x]:parent:showonly(TabWidget_allpanels[x]).
                    }
            }
            PRESERVE.
        }
    }
    // #endregion
// #endregion


    // *- Style
    // #region

    // SetRectOffsetStyle
    // 
    local function SetRectOffset
    {
        parameter _rectOffset,
                  _rectVals.

        if _rectOffset:IsType("StyleRectOffset") {
            if _rectVals:IsType("Lexicon") {
                for keyID in _rectVals:Keys {
                    if      keyID = "LEFT"   { set _rectOffset:Left   to _rectVals[keyID]. }.
                    else if keyID = "RIGHT"  { set _rectOffset:Right  to _rectVals[keyID]. }.
                    else if keyID = "TOP"    { set _rectOffset:Top    to _rectVals[keyID]. }.
                    else if keyID = "BOTTOM" { set _rectOffset:Bottom to _rectVals[keyID]. }.
                    else if keyID = "H"      { set _rectOffset:H      to _rectVals[keyID]. }.
                    else if keyID = "V"      { set _rectOffset:V      to _rectVals[keyID]. }.
                }
            } else if _rectVals:IsType("List") {
                if _rectVals:Length = 1 {
                    set _rectOffset:H to _rectVals[0].
                    set _rectOffset:V to _rectVals[0].
                } else if _rectVals:Length = 2 {
                    set _rectOffset:H to _rectVals[0].
                    set _rectOffset:V to _rectVals[1].
                } else if _rectVals:Length = 4 {
                    set _rectOffset:LEFT   to _rectVals[0].
                    set _rectOffset:RIGHT  to _rectVals[1].
                    set _rectOffset:TOP    to _rectVals[2].
                    set _rectOffset:BOTTOM to _rectVals[3].
                }   
            }
        }
        return _rectOffset.
    }

    // SetStyle
    global function SetStyle 
    {
        parameter _style,
                  _styleLex.

        if (_style:IsType("Style") or _style:IsType("StyleState")) and _styleLex:IsType("Lexicon") {
            for keyID in _styleLex:Keys {
                if keyID = "ALIGN"          { set _style:Align     to _styleLex[keyID].}.
                else if keyID = "BG"        { set _style:BG        to _styleLex[keyID].}.
                else if keyID = "FONT"      { set _style:Font      to _styleLex[keyID].}.
                else if keyID = "FONTSIZE"  { set _style:FontSize  to _styleLex[keyID].}.
                else if keyID = "RICHTEXT"  { set _style:RichText  to _styleLex[keyID].}.
                else if keyID = "TEXTCOLOR" { set _style:TextColor to _styleLex[keyID].}.
                else if keyID = "WORDWRAP"  { set _style:WordWrap  to _styleLex[keyID].}.
                else if keyID = "WIDTH"     { set _style:Width     to _styleLex[KeyID].}.
                else if keyID = "HEIGHT"    { set _style:Height    to _styleLex[KeyID].}.
                else if keyID = "HSTRETCH"  { set _style:HStretch  to _styleLex[keyID].}.
                else if keyID = "VSTRETCH"  { set _style:VStretch  to _styleLex[keyID].}.

                else if keyID = "MARGIN"    { SetRectOffset(_style:Margin, _styleLex[KeyID]).  }.
                else if keyID = "PADDING"   { SetRectOffset(_style:Padding, _styleLex[KeyID]). }.
                else if keyID = "BORDER"    { SetRectOffset(_style:Border, _styleLex[KeyID]).  }.
                else if keyID = "OVERFLOW"  { SetRectOffset(_style:Overflow, _styleLex[KeyID]).}.

                else if keyID = "NORMAL"     { set _style:Normal     to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "NORMAL_ON"  { set _style:Normal_On  to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "HOVER"      { set _style:Hover      to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "HOVER_ON"   { set _style:Hover_On   to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "ACTIVE"     { set _style:Active     to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "ACTIVE_ON"  { set _style:Active_On  to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "FOCUSED"    { set _style:Focused    to SetStyle(_style, _styleLex[keyID]).}
                else if keyID = "FOCUSED_ON" { set _style:Focused_On to SetStyle(_style, _styleLex[keyID]).}

            }
        }
        return _style.
    }
    // #endregion

// #endregion