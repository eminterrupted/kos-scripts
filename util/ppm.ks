@lazyGlobal off.

parameter _part is "".

clearScreen. 

if _part = ""
{
    print "ERROR: No valid part provided!".
    print "Must provide param value with typename: 'Part'".
}
else
{
    print "MODULES FOR PART: " + _part:name.
    print "COUNT           : {0}":Format(_part:modules:length).
    print "----------------------------------------------------".
    print " ".

    local line is 5.

    from { local n is 0.} until n = _part:modules:Length step { set n to n + 1.} do 
    {
        local m is _part:getModuleByIndex(n).

        if line < terminal:height - 35 
        {
            set line to line + 1.
            print "[{0}] MODULE({1})":Format(n, m:name).

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