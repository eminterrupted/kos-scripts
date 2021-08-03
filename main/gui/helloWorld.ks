@lazyGlobal off.

// "Hello World" program for kOS GUI.
//
// Create a GUI window
local gui to gui(200).
// Add widgets to the GUI
local label to gui:addLabel("Hello world!").
set label:style:align to "CENTER".
set label:style:hstretch to true. // Fill horizontally
local ok to gui:addButton("OK").
// Show the GUI.
gui:show().
// Handle GUI widget interactions.
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
set ok:onClick TO myClickChecker@. // This could also be an anonymous function instead.
wait until isDone.

print "OK pressed.  Now closing demo.".
// Hide when done (will also hide if power lost).
gui:hide().