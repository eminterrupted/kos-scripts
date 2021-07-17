parameter vec1, vec2.

runOncePath("0:/kslib/lib_navball").

until false 
{
    print bearing_between(ship, vec1, vec2).
}