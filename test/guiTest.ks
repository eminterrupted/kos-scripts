// Hello World program for kOS gui
// From: https://ksp-kos.github.io/KOS/structures/gui.html#gui
//

clearScreen.

//Load dependency file
runOncePath("0:/lib/Data/Vessel/thrust.ks").

//Get data to display
local thrustObject is get_thrust_object().

//Create a GUI window
local gui is gui(225,225).

//Add widgets to the GUI
local headerBox is gui:addHBox.
local textBox is gui:addVBox.

//Add some text
local header is headerBox:addLabel("<size=20><b>Thrust Details</b></size>").
set header:style:align to "center".
set header:style:hStretch to true.

local curLabel is textBox:addLabel("<color=orange>Current Thrust</color><color=white>: " + round(thrustObject:current, 2) + "kn </color>").
set curLabel:style:align to "left".
set curLabel:style:hStretch to true.

local maxLabel is textBox:addLabel("<color=red>Max Thrust</color><color=white>:    " + round(thrustObject:max, 2) + "kn </color>").
set maxLabel:style:align to "left".
set maxLabel:style:hStretch to true.               // Fill horizontally

local ok to gui:addButton("OK").

//Show the gui
gui:show().

//Handle GUI widget interactions.
//
// This is the technique known as "callbacks" - instead
// of actively looking again and again to see if a button was
// pressed, the script just tells kOS that it should call a
// delegate function when it notices the button has done
// something, and then the program passively waits for that
// to happen:
local isDone to false.

function myClickChecker {
    set isDone to true.
}

set ok:OnClick to myClickChecker@. //This could also be an anonymous function instead.
wait until isDone.

print "OK, pressed! Now closing demo". 

//Hide when done (or if power lost).
gui:hide().