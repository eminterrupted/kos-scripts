set vec_shipPos to ship:position - body:position.
set vec_tgtPos to target:position - body:position.

print "Sign check test".
print "---------------".
print "Target             : " + target.

set phaseAng to vAng(vec_shipPos, vec_tgtPos).
print "phaseAng pre check : " + round(phaseAng, 1).
set signCheck to vDot(vCrs(vec_tgtPos, vec_shipPos), vCrs(ship:velocity:orbit, vec_shipPos)).
print "signCheck          : " + signCheck.
if signCheck > 0 
{
    set phaseAng to 360 - phaseAng. 
}
print "phaseAng post-check: " + round(phaseAng, 1).