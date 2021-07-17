local wp is "".

for w in allWaypoints() 
{ 
    if w:isSelected set wp to w.
}

vecDraw(ship:position, wp:position, RGB(0, 0, 1), "Waypoint Position", 1.0, true, 0.5, true).
