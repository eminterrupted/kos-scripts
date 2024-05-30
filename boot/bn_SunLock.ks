ClearScreen.
print "SL+".
local sd to { parameter _p. return Sun:Position + r(0,_p,0).}.
local p to 0.
set sv to sd:call(p).
lock steering to sv.
until false
{
    local t to Terminal:Input.
    if t:HasChar
    {
        local c to t:GetChar.
        if c = t:UpCursorOne set p to p + 11.25.
        else if c = t:DownCursorOne set p to p - 11.25.
        else if c = t:DeleteRight set p to 0.
        else break.
    }
    set sv to sd:call(p).
}
unlock steering.
print "SL-".