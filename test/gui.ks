@LazyGlobal off.
ClearScreen.

RunOncePath("0:/lib/gui.ks").

LOCAL my_gui IS GUI(500).
LOCAL tabwidget IS AddTabWidget(my_gui).

LOCAL page IS AddTab(tabwidget,"One").
page:ADDLABEL("This is page 1").
page:ADDLABEL("Put stuff here!").

LOCAL page2 IS AddTab(tabwidget,"Two").
page2:ADDLABEL("This is page 2").
page2:ADDLABEL("Put more stuff here!").

LOCAL page3 IS AddTab(tabwidget,"Three").
page3:ADDLABEL("This is page 3").
page3:ADDLABEL("Put even stuff here!").

ChooseTab(tabwidget,1).

LOCAL close IS my_gui:ADDBUTTON("Close").
SetupTabTrigger(tabwidget).

my_gui:SHOW().
UNTIL close:PRESSED {
    // Handle processing of all the widgets on all the tabs.
    WAIT(0).
}
my_gui:HIDE().