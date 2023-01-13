@lazyGlobal off.

parameter part is "".

clearScreen. 

if part = ""
{
    print "ERROR: No valid part provided!".
    print "Must provide param value with typename: 'Part'".
}
else
{
    print "MODULES FOR PART: " + part:name.
    print "----------------------------------------------------".
    print " ".

    local line is 5.

    from { local n is 0.} until n = part:modules:Length step { set n to n + 1.} do 
    {
        local m is part:getModuleByIndex(n).

        if line < terminal:height - 35 
        {
            set line to line + 1.
            print "MODULE(" + m:name + "):".

            set line to line + 1 + m:Allactions:Length + m:Allevents:Length + m:Allfields:Length.
            print m.

            set line to line + 1.
            print " ".
        }
        else 
        {
            print "** [press any key] **" at ( terminal:width - 30, terminal:height - 5).
            terminal:input:getChar().
            clearScreen.
            set line to 0.
        }
    }
}