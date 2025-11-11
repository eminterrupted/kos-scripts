@LazyGlobal off.
ClearScreen.

until false
{
    if Ship:Altitude >= Ship:Body:Atm:Height
    {
        runPath("0:/main/action/deployResSat").
        break.
    }
    wait 5.
}