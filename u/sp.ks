parameter dv, 
          stg to stage:number.

runOncePath("0:/lib/data/nav/lib_deltav.ks").

local dvObj to get_stages_for_dv(dv, stg).
print dvObj.
print " ".
print " ".

if dvObj:hasKey("deficit") print "Deficit detected, break".

else {
    for k in dvObj:keys {
        print "Burn Dur: " + get_burn_dur_by_stg(k, dvObj[k]).
    }
}


global function get_burn_dur_by_stg {
    parameter pStg,
              pDv.
    
    local eList to get_engs_for_stg(pStg).
    local engPerfObj to get_eng_perf_obj(eList).
    local exhVel to get_engs_exh_vel(eList, ship:apoapsis).
    local vMass to get_vmass_at_stg(pStg).

    local stageThrust to 0.
    for e in engPerfObj:keys {
        set stageThrust to stageThrust + engPerfObj[e]["thr"]["poss"].
    }
    
    return ((vMass * exhVel) / stageThrust) * ( 1 - (constant:e ^ (-1 * (pDv / exhVel)))).
}