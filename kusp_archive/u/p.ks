@lazyGlobal off.

runOncePath("0:/lib/lib_init").
runOncePath("0:/lib/lib_util").
runOncePath("0:/lib/lib_tag").

until stage:number = 2 
{
    if ship:availableThrust <= 0 and throttle > 0 
    {
        safe_stage().
    }
}