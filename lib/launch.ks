// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
    RunOncePath("0:/kslib/lib_l_az_calc.ks").
    RunOncePath("0:/kslib/lib_navball.ks").
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local countdown                 to 5.
    local lc_MinAoA                 to -45.
    local proSrfObtBlendStartAlt    to 100000.
    local atmBlendDiv               to Body:ATM:Height - proSrfObtBlendStartAlt.

    local ascent_Blend_Start        to proSrfObtBlendStartAlt.
    local ascent_Blend_End          to Body:Atm:Height.
    local ascent_Blend_Window       to ascent_Blend_End - ascent_Blend_Start.

    local Ascent_AoA_Max            to 45.
    local Ascent_AoA_Min            to 7.5.
    local PID_AoA_Max               to 15.
    local PID_AoA_Min               to -15.
    local l_HotStageAOALimitVal     to 0.

    // *- Global
    global g_la_turnAltStart to Ship:Altitude + (Ship:Bounds:Size:Z * 2).    // Altitude at which the vessel will begin a gravity turn
                                                                             // taken from the bounding box of the ship on the launch pad
                                                                             // and is 2x the height of the vessel/launch pad tower
    global g_la_turnAltEnd   to body:Atm:height * 0.90. // 0.925 // Altitude at which the vessel will end a gravity turn
    global g_sounderStartTurn to 125.

    global g_alt_PID to PidLoop(1.0, 0.05, 0.001, -1, 1).
    global g_apo_pid  to PidLoop(1.0, 0.05, 0.001, -1, 1).
    global g_ascentProfile to lexicon().
    // global g_azData to list().

    global g_PID_Flag       to false.
    global g_PID_Alt_Flag   to false.
    global g_PID_Apo_Flag   to false.

    // Prelaunch params
    global g_PreLaunch_Data to lexicon(
        "LC", lexicon(
            "ALT",  Ship:Altitude
            ,"GEO", Ship:GeoPosition
            ,"LAT", Ship:GeoPosition:Lat
            ,"LNG", Ship:GeoPosition:Lng
        )
    ).

// #endregion


// *~--- Functions ---~* //
// #region

// *- Guidance
// #region

    // GetAscentSteeringDelegate :: 
    // Returns the steering delegate appropriate for the mission
    global function GetAscentSteeringDelegate
    {
        // parameter _delDependency is lexicon().
        parameter _tgtAlt,
                  _tgtInc,
                  _azData is g_azData.

        if not g_MissionTag:HasKey("Mission")
        {
            set g_MissionTag to ParseCoreTag(Core:Tag).
        }

        local del to { return Ship:Facing. }.
        local _delDependency to g_AngDependency.
        
        if _tgtAlt < 0
        {
            if g_MissionTag:Params:Length > 0
            {
                set _tgtAlt to choose ParseStringScalar(g_MissionTag:Params[1]) if g_MissionTag:Params:Length > 1 else 250000.
            }
            else
            {
                set _tgtInc to 0.
                set _tgtAlt to 250000.
            }
        }

        if _azData:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
        {
            set _azData to l_az_calc_init(_tgtAlt, _tgtInc).
            set g_azData to _azData.
        }
        else
        {
            set g_azData to _azData. 
        }


        if g_AngDependency:Keys:Length = 0// and g_azData:Length > 0
        {
            // set _delDependency to InitAscentAng_Next(_tgtAlt, 0.9875, 7.5, 30).
            local fShape to 1.25.
            local minPit to 5.
            local pitLim to 32.5.
            if g_MissionTag:Mission:MatchesPattern("DownRange")
            {
                set fShape to 1.3250.
                set minPit to 3.
                set pitLim to 50.
            }
            OutInfo("[TgtInc] {0,-3} | [TgtAlt] {1,-7}":Format(Round(_tgtInc, 2), Round(_tgtAlt)), 1).
            set _delDependency to InitAscentAng_Next(_tgtInc, _tgtAlt, fShape, minPit, pitLim).
        }
        set g_AngDependency to _delDependency.

        // local rollAngle to choose { return 180.} if Ship:CrewCapacity > 0
        // else choose { return vAng(VXCL(Ship:SrfPrograde:Vector, Sun:Position)).} if Ship:ModulesNamed("ModuleROSolar"):Length > 0
        // else { return 0.}.

        // Mission types and ascent angle profiles
        if g_MissionTag:Mission = "Sounder"
        {
            set del to { return Ship:Facing:Vector.}.
        }
        else if g_MissionTag:Mission = "SSO" // Sounder - Suborbital (Unguided ascent, guided reentry) :: No Params
        {
            set del to { return Ship:Facing:Vector.}.
        }
        else if g_MissionTag:Mission = "MaxAlt" // Sounding Rocket Main :: [0]Heading and [1]Ascent Angle
        {
            set del to { return Heading(g_MissionTag:Params[0], g_MissionTag:Params[1], 0).}.
        }
        else if g_MissionTag:Mission:MatchesPattern("DownRange") // DownRange with no reentry :: [0]Inclination and [1]Target Alt
        {
            set _delDependency["l_az_calc"] to _azData.
            set del to { if Ship:Altitude >= g_sounderStartTurn { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), 0). } else { return Heading(compass_for(Ship, Ship:Facing), 90, 0). }}.
        }
        else if g_MissionTag:Mission:MatchesPattern("^(Suborbital|PIDSubOrbital)") // Suborbital hop :: [0] Inclination and [1]Target Alt
        {
            set _delDependency["l_az_calc"] to _azData.
            set del to { if Ship:Altitude >= _delDependency:TRN_ALT_START { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), 0). } else { return Heading(g_MissionTag:Params[0], 90, 0 ). }}.
        }
        else if g_MissionTag:Mission:MatchesPattern("^(Orbit|PIDOrbit)$") // Orbital insertion :: [0] Inclination and [1]Target Alt
        {
            set _delDependency["l_az_calc"] to _azData.
            if not _delDependency:HasKey("TRN_ALT_START")
            {
                set _delDependency["TRN_ALT_START"] to Ship:Altitude + 125.
            }
            set del to { if Ship:Altitude >= _delDependency:TRN_ALT_START { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), 0). } else { return Heading(g_MissionTag:Params[0], 90, 0 ). }}.
        }
        else if g_MissionTag:Mission = "Circularize"
        {
            // set _delDependency to InitAscentAng_Next(_tgtAlt, _delDependency:FSHAPE).
            set _delDependency["l_az_calc"] to _azData.
            set del to { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), 0). }.
        }
        return del@.
    }

    // GetAscentAngle :: <scalar>tAlt (Target Altitude), [<scalar>shapeFactor] -> <scalar>AscentAngle (-10.0 - 90.0)
    // Returns a valid launch angle for the current vessel during an ascent 
    // based on current altitude and target altitude. Used to provide continuous 
    // guidance as the vessel ascends. 
    global function GetAscentAngle
    {
        parameter _tgtAp is Body:ATM:Height,
                  _tgtAlt is Body:ATM:Height * 0.86,
                  _fShape is 0.750. // 'shape' factor to provide a way to control the steepness of the trajectory. Values < 1 = flatter, > 1 = steeper

        local eff_PitAng to 45.
        // local tgt_effAP  to tgt_ap. // max(body:Atm:Height, tgt_ap / 2).
        if Ship:Altitude < g_la_turnAltStart
        {
        }
        else // if g_ConsumedResources:HasKey("TimeRemaining")
        {
            // if g_ConsumedResources["TimeRemaining"] < 5
            // {
            //     local pitFacing to pitch_for(Ship, Ship:Facing).
            //     local pitPro    to pitch_for(Ship, Ship:SrfPrograde).
            //     set tgt_EffAng to pitFacing + ((pitFacing - pitPro) * Body:Atm:AltitudePressure(cur_alt)).
            // }
            // else
            // {
            local cur_alt    to Ship:Altitude.
            local cur_EffAlt to 0.1 + cur_Alt - g_la_turnAltStart.
            local nrmlzdAlt  to cur_Alt - proSrfObtBlendStartAlt.

            local cur_Pres   to Body:ATM:AltitudePressure(cur_Alt).

            local obtProPit to pitch_for(Ship, Ship:Prograde).
            local srfProPit to pitch_for(Ship, Ship:SrfPrograde).
            
            // local pitDiff   to VAng(Ship:SrfPrograde:Vector, Ship:Prograde:Vector).
            
            // local cur_pitAng to choose srfProPit if cur_alt < 100000 else 
            //     choose ((srfProPit + obtProPit) / 2) if cur_alt < body:Atm:Height else 
            //     obtProPit.
            local isAboveBlendLine to cur_Alt > proSrfObtBlendStartAlt.
            print isAboveBlendLine at (2, 45).
            local cur_PitAng to choose srfProPit if nrmlzdAlt < 0
                           else choose ((srfProPit + obtProPit) / 2) if nrmlzdAlt < 25000
                           else obtProPit. 
                           
            local tgt_EffAlt to _tgtAlt - g_la_turnAltStart.
            local tgt_EffApo to _tgtAp - g_la_turnAltStart.
            local cur_AltErr to cur_EffAlt / tgt_EffAlt.
            local cur_ApoErr to cur_EffAlt / tgt_EffApo.
            local cur_PrsErr to min(1, ((1 - cur_Pres) / 2)).
            // local tgt_pitAng to max(-5, 90 * (1 - cur_altErr)).// * abs(f_shape - 1).
            local tgt_AltPitAng to 90 * (1 - cur_AltErr).  // cur_PitAng * cur_AltErr.
            local tgt_ApoPitAng to 90 * (1 - cur_ApoErr).  // cur_PitAng * (1 - cur_ApoErr).
            local tgt_PrsPitAng to 90 * cur_Pres.  // cur_PitAng * cur_Pres.

            // local cur_pitRatio to Round(cur_alt / (Body:Atm:Height + 25000), 4).
            // local tgt_pitRatio to Round(Ship:Apoapsis / tgt_effAP, 4).
            //local eff_pitRatio to choose cur_pitRatio if cur_alt < Body:Atm:Height * 0.625 else tgt_pitRatio.
            // local eff_pitRatio to choose apo_PitAng if cur_alt >= g_la_turnAltEnd else (1 - Body:Atm:AltitudePressure(cur_alt)).
            set eff_PitAng to choose tgt_AltPitAng if cur_Alt < proSrfObtBlendStartAlt 
                else choose (tgt_ApoPitAng + tgt_AltPitAng) / 2 if cur_Alt < Body:ATM:Height
                else tgt_ApoPitAng.
            // set   eff_pitRatio to eff_PitRatio * _fShape.
            set eff_PitAng to max(cur_PitAng - 3.5, min(90, cur_PitAng + 3.5)) * _fShape.
            //local tgt_angErr to min(10, max(lc_MaxAoA * eff_pitRatio, 10 * min(1, eff_pitRatio * lc_MinAoA))) * f_shape.
            // local tgt_angErr to min((30 * eff_pitRatio) , max(-30, (90 * eff_pitRatio))).
            // local res_PitAng to min(15, max(-15, eff_PitAng)).
            // if cur_alt > Body:Atm:Height 
            // {
            //     set tgt_angErr to tgt_angErr / (1 + g_ActiveEnginesLex:CURTWR).
            // }
            // set tgt_effAng to choose max(tgt_ApoPitAng, cur_pitAng - tgt_angErr) if cur_alt > ((_tgtAlt * _fShape) 25000). // min(90, max(cur_pitAng - tgt_angErr, min(cur_pitAng + tgt_angErr, tgt_pitAng)) * f_shape).
            if eff_PitAng < 0 
            {
                set eff_PitAng to eff_PitAng / 0.975.
            }
            // }
            DispAscentAngleStats(lexicon(
                "ASCENT ANGLE"
                ,"srfProPit", Round(srfProPit, 3)
                ,"obtProPit", Round(obtProPit, 3)
                ,"cur_Alt", Round(cur_Alt)
                ,"proSrfObtBlendStartAlt", proSrfObtBlendStartAlt
                ,"nrmlzdAlt", Round(nrmlzdAlt)
                ,"cur_PitAng", Round(cur_PitAng, 3)
                ,"cur_AltErr", Round(cur_AltErr, 3)
                ,"cur_ApoErr", Round(cur_ApoErr, 3)
                ,"cur_PrsErr", Round(cur_PrsErr, 3)
                ,"tgt_AltPitAng", Round(tgt_AltPitAng, 3)
                ,"tgt_ApoPitAng", Round(tgt_ApoPitAng, 3)
                ,"tgt_PrsPitAng", Round(tgt_PrsPitAng, 3)
                ,"eff_PitAng", Round(eff_PitAng, 3)
                )
            ).
        }
        OutInfo("Current Pitch Angle: {0}":Format(Round(eff_PitAng, 2)), 1).

        return eff_PitAng.
    }

    global function GetAscentAng2
    {
        parameter _tgtAp is Body:Atm:Height + 100000,
                  _fShape is 1.0125.  // < 1 is flatter, > 1 is steeper

        local tgt_TurnEnd       to max(_tgtAp / 2, ascent_Blend_End).

        local blend_Err         to 0.
        local blend_Window      to tgt_TurnEnd - ascent_Blend_Start.
        local cur_Alt           to Ship:Altitude.
        local cur_Alt_Err       to 0.
        local cur_Apo           to 0.
        local cur_Apo_Err       to 0.
        local cur_Err_Pro_Srf   to 0.
        local cur_Err_Pro_Obt   to 0.

        local cur_Pit           to 0.
        local cur_Pit_Err       to 0.
        local cur_Pit_Facing    to 0.
        local cur_Pit_Pro_Srf   to 0.
        local cur_Pit_Pro_Obt   to 0.

        local eff_Alt           to 0.
        local eff_Alt_Tgt       to 0.
        local eff_Apo_Tgt       to 0.
        local eff_H_Err         to 0.
        local eff_Pit           to 0.

        local out_Pit           to 90.


        if cur_alt > g_la_turnAltStart
        {
            set eff_Alt         to 0.001 + cur_Alt - g_la_turnAltStart.
            set eff_Alt_Tgt     to tgt_TurnEnd - g_la_turnAltStart.
            set cur_Alt_Err     to eff_Alt / eff_Alt_Tgt.

            set cur_Apo         to 0.001 + Ship:Apoapsis - g_la_turnAltStart.
            set eff_Apo_Tgt     to _tgtAp - g_la_turnAltStart.
            set cur_Apo_Err     to cur_Apo / eff_Apo_Tgt.

            set blend_Err       to (cur_Alt - ascent_Blend_Start) / blend_Window.

            set cur_Pit_Facing  to pitch_for(Ship, Ship:Facing).
            set cur_Pit_Pro_Srf to pitch_for(Ship, Ship:SrfPrograde).
            set cur_Pit_Pro_Obt to pitch_for(Ship, Ship:Prograde).

            set cur_Err_Pro_Srf to cur_Pit_Pro_Srf - cur_Pit_Facing.
            set cur_Err_Pro_Obt to cur_Pit_Pro_Obt - cur_Pit_Facing.

            if cur_Alt < ascent_Blend_Start
            {
                set cur_Pit_Err  to cur_Err_Pro_Srf.
                set cur_Pit      to cur_Pit_Pro_Srf.
                set eff_H_Err    to cur_Alt_Err.
                set eff_Pit      to 90 * (1 - (eff_H_Err * _fShape)).
            }
            else if cur_Alt < tgt_TurnEnd
            {
                set cur_Pit_Err  to ((cur_Err_Pro_Srf * (1 - cur_Alt_Err)) + (cur_Err_Pro_Obt * (1 - cur_Apo_Err))) / 2.
                set eff_H_Err    to ((cur_Alt_Err     * (1 - blend_Err  )) + (cur_Apo_Err     * blend_Err        )) / 2.
                set cur_Pit      to 90 * (1 - (((cur_Pit_Err + eff_H_Err) / 2) * _fShape)). // 90 * ((1 - (cur_Alt_Err * (blend_Window / (tgt_TurnEnd - cur_Alt))) + (1 - cur_Apo_Err)) / 2).
            }
            else
            {
                set cur_Pit_Err to cur_Err_Pro_Obt.
                set eff_H_Err   to cur_Apo_Err.
                set cur_Pit     to 90 * (((cur_Pit_Err + eff_H_Err) / 2) * _fShape).
            }
            set eff_Pit  to cur_Pit - (Ascent_AoA_Max * eff_H_Err).
            set out_Pit  to min(90, max(-15, eff_Pit * _fShape)).
        }

        DispAscentAngleStats(lexicon(
            "Cur Pitch (SRF)",  Round(cur_Pit_Pro_Srf, 3)
            ,"Cur Pitch (OBT)", Round(cur_Pit_Pro_Obt, 3)
            ,"Cur Pitch (EFF)", Round(cur_Pit, 3)
            ,"Cur Alt (IAM)",   Round(cur_Alt)
            ,"Cur Alt (EFF)",   Round(eff_Alt)
            ,"Cur Err (ALT)",   Round(cur_Alt_Err, 3)
            ,"Cur Err (APO)",   Round(cur_Apo_Err, 3)
            ,"Cur Err (EFF)",   Round(eff_H_Err, 3)
            ,"Pitch (EFF)",     Round(eff_Pit, 3)
            ,"Pitch (OUT)",     Round(out_Pit, 3)
            )
        ).
        return out_Pit.
    }

    global function InitAscentAng_Next
    {
        parameter _tgtInc,
                  _tgtAlt,
                  _fShape is 1,
                  _pitLimMin is Ascent_AoA_Min,
                  _pitLimMax is Ascent_AoA_Max,
                  _fStop is 90,
                  _pidChangeRate is Ascent_AoA_Max.

        // set g_apo_PID           to PidLoop(1.0, 0.05, 0.001, -45, 90).
        // set g_apo_PID:Setpoint  to _tgtAlt.

        if abs(_tgtInc) + 5 > _fStop
        {
            set _fStop to choose _tgtInc + 5 if _tgtInc > 0 else abs(_tgtInc - 5).
        }

        local turn_alt_start      to g_la_turnAltStart.
        local turn_alt_end        to choose 70000 if _tgtAlt <= 200000 else min(1000000, max(100000, Round(_tgtAlt / 2.75))).// 72500 
        local turn_alt_blend      to 500. 

        local pid_Apo_ID to "TurnApo".
        // set g_PIDS[pid_Apo_ID]       to PIDLoop(0.05, 0.0075, 0.000825, -_pidChangeRate, _pidChangeRate).
        //set g_PIDS[pid_Apo_ID]       to PIDLoop(_pidChangeRate * 0.5, _pidChangeRate * 0.25, _pidChangeRate * 0.125, -_pidChangeRate, _pidChangeRate). 
        set g_PIDS[pid_Apo_ID]       to PIDLoop(_pidChangeRate * 1, _pidChangeRate * 0.625, _pidChangeRate * 0.250, -_pidChangeRate, _pidChangeRate). 
        set g_PIDS[pid_Apo_ID]:Setpoint to _tgtAlt.
        
        local pid_Alt_ID to "TurnAlt".
        set g_PIDS[pid_Alt_ID]   to PIDLoop(1.0, 0.05, 0.001, -_pidChangeRate, _pidChangeRate).
        set g_PIDS[pid_Alt_ID]:Setpoint to turn_alt_end.
        // set g_alt_PID           to PidLoop(1.0, 0.05, 0.001, -45, 90).
        // set g_alt_PID:Setpoint  to trn_alt_end.
        
        OutInfo("TurnAlt: {0}":Format(turn_alt_end)).

        return lexicon
        (
            "ALT_PID", pid_Alt_ID
            ,"ALT_SETPOINT", turn_alt_end
            ,"APO_PID", pid_Apo_ID
            ,"APO_SETPOINT", _tgtAlt
            ,"APO_TGT", _tgtAlt
            ,"FSHAPE", _fShape
            ,"PIT_LIM_MAX", _pitLimMax
            ,"PIT_LIM_MIN", _pitLimMin
            ,"RESET_PIDS", True
            ,"TRN_ALT_START", turn_alt_start
            ,"TRN_ALT_END", turn_alt_end
            ,"TRN_ALT_BLEND", turn_alt_blend
            ,"TRN_APO_TGT", Round(_tgtAlt * 0.825)
            ,"UPDATE_SETPOINT", True
        ).
    }

    // WIP PART DEUX, electric OH MY GOD STAHP
    // #TODO: Examine benefit of moving fshape to limits vs eff pitch (* currently in progress)
    global function GetAscentAng_Next
    {
        parameter _ascAngObj.

        local fShape            to _ascAngObj:FSHAPE.
        local altitude_error    to 0.
        local apo_error         to 0.
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local current_pitch     to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).
        local effective_error   to 0.
        local effective_limit   to 0.
        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to 90.

        local current_ap_alt    to (Ship:Altitude + (1 * (Ship:Apoapsis))) / 2.
        
        local prograde_pitch            to 90.
        local prograde_surface          to Ship:SrfPrograde:Vector. // Ship:Velocity:Surface.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograde_orbit            to Ship:Prograde:Vector. // Ship:Velocity:Orbit.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START.

        if g_SpinActive 
        {
            set output_pitch to current_pitch.
            // set pitch_limit_max to max(pitch_limit_min, pitch_limit_max * 0.28).
        }
        else if current_alt > turn_alt_start
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if current_alt < 1000 and Ship:VerticalSpeed > 0
            {
                local blend_alt_error   to (current_alt - turn_alt_start) / (2500 - turn_alt_start).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.05625)). // * 1.125)).// 1.015625)).
                set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.05625)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(45, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(45, min(effective_pitch, 90)).
            }

            if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                set error_pitch         to 90 * (1 - altitude_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.275)). // 1.25)). // 1.03125)).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
                // * set output_pitch        to min(90, effective_pitch * fShape).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else if current_ap_alt < turn_alt_end and Ship:VerticalSpeed > 0
            {
                local blend_alt_error   to (current_alt - turn_alt_blend) / (turn_alt_end - turn_alt_blend).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.325)). // 1.275)). // 1.0625)).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else
            {
                set error_pitch         to 90 * (1 - apo_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }

            if ETA:Apoapsis > ETA:Periapsis
            {
                set output_pitch to max(-12.5, min(12.5, output_pitch)).
            }
        }

        return output_pitch.
    }

    // With PID Control too I guess because I'm dumb
    global function GetAscentAng_PIDyParty
    {
        parameter _ascAngObj.

        local fShape            to _ascAngObj:FSHAPE.
        local altitude_error    to 0.
        local apo_error         to 0.
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local effective_error   to 0.
        local effective_limit   to 0.
        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to 90.

        local current_ap_alt    to (Ship:Altitude + (1 * (Ship:Apoapsis))) / 2.
        
        local prograde_pitch            to 90.
        local prograde_surface          to Ship:SrfPrograde:Vector. // Ship:Velocity:Surface.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograde_orbit            to Ship:Prograde:Vector. // Ship:Velocity:Orbit.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START.
        
        if current_alt > turn_alt_start
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if current_alt < 2500 and Ship:VerticalSpeed > 0
            {
                local blend_alt_error   to (current_alt - turn_alt_start) / (2500 - turn_alt_start).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max)). // * 1.125)).// 1.015625)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                set output_pitch        to max(45, min(effective_pitch * fShape, 90)).
            }

            if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                set error_pitch         to 90 * (1 - altitude_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.25)). // 1.03125)).
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
                set output_pitch        to min(90, effective_pitch * fShape).
            }
            else if current_ap_alt < turn_alt_end and Ship:VerticalSpeed > 0
            {
                local blend_alt_error   to (current_alt - turn_alt_blend) / (turn_alt_end - turn_alt_blend).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.275)).// 1.0625)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
            }
            else if g_MissionTag:Mission:StartsWith("PID")
            {
                // OutDebug("In PIDLoop!").
                if _ascAngObj:RESET_PIDS
                {
                    g_PIDS[_ascAngObj:APO_PID]:Reset().
                    set _ascAngObj:UPDATE_SETPOINT to True.
                    set _ascAngObj:RESET_PIDS to False.
                }

                if _ascAngObj:UPDATE_SETPOINT
                {
                    set g_PIDS[_ascAngObj:APO_PID]:Setpoint to target_apo.
                    set _ascAngObj:UPDATE_SETPOINT to False.
                }

                local apo_PID to g_PIDS[_ascAngObj:APO_PID].
                set error_pitch to 90 * (1 - apo_error).
                set output_pitch to max(PID_AoA_Min, min(apo_PID:Update(Time:Seconds, Ship:Apoapsis), PID_AoA_Max)).
            }
            else
            {
                set error_pitch         to 90 * (1 - apo_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
            }
        }
        if ETA:Apoapsis > ETA:Periapsis
        {
            //set output_pitch to max(5, min(-5, -output_pitch)).
            set output_pitch to -output_pitch.
        }

        return output_pitch.
    }

    // WIP PART TRES, WTF THIS BETTER BE GOOD YOU DUMMY
    global function GetAscentAng_NextNext
    {
        parameter _ascAngObj,
                  _clampAOA is 0.

        local fShape            to _ascAngObj:FSHAPE.
        local altitude_error    to 0.
        local apo_error         to 0.
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local effective_error   to 0.
        local effective_limit   to 0.
        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to 90.

        local current_ap_alt    to (Ship:Altitude + (1 * (Ship:Apoapsis))) / 2.
        
        local prograde_pitch            to 90.
        local prograde_surface          to Ship:SrfPrograde:Vector. // Ship:Velocity:Surface.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograde_orbit            to Ship:Prograde:Vector. // Ship:Velocity:Orbit.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        
        local pitch_limit_max   to choose _clampAOA if _clampAOA > 0 else _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to choose 0.0125 if _clampAOA > 0 else _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START.
        
        
        if current_alt > turn_alt_start
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if current_alt < 2500 and Ship:VerticalSpeed > 0
            {
                local blend_alt_error   to (current_alt - turn_alt_start) / (2500 - turn_alt_start).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max)). // * 1.125)).// 1.015625)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                set output_pitch        to max(45, min(effective_pitch * fShape, 90)).
            }

            if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                set error_pitch         to 90 * (1 - altitude_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.25)). // 1.03125)).
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
                set output_pitch        to min(90, effective_pitch * fShape).
            }
            else if current_ap_alt < turn_alt_end and Ship:VerticalSpeed > 0
            {
                local blend_alt_error   to (current_alt - turn_alt_blend) / (turn_alt_end - turn_alt_blend).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.275)).// 1.0625)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
            }
            else
            {
                set error_pitch         to 90 * (1 - apo_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
            }
        }
        if ETA:Apoapsis > ETA:Periapsis
        {
            set output_pitch to max(5, min(-5, -output_pitch)).
        }

        return output_pitch.
    }

    global function GetPIDAscentAngle
    {
        parameter _ascAngObj,
                  _reset to False.

        local output_pitch      to 90.

        local PID_Apo           to g_PIDS[_ascAngObj:APO_PID].

        if _reset 
        {
            PID_Apo:Reset().
        }


        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.

        // Vector to pitch degree conversions
        local prograde_surface          to Ship:SrfPrograde:Vector.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograde_orbit            to Ship:Prograde:Vector.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        local prograde_effective_pitch  to choose prograde_orbit_pitch if Ship:Velocity:Orbit:Mag > 1500 else prograde_surface_pitch.

        local desired_change_apo to PID_Apo:Update(Time:Seconds, Ship:Apoapsis).
        set output_pitch to Max(pitch_limit_min, Min(prograde_effective_pitch + desired_change_apo, pitch_limit_max)).

        return output_pitch.
    }

    // WIP AGAIN CAUSE WHY NOT YOU IDIOT
    global function GetPIDAscentAngle_Old
    {
        parameter _ascAngObj.

        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.

        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to 90.       

        local PID_Alt           to g_PIDS[_ascAngObj:ALT_PID].
        local PID_Alt_Output    to 0.
        local PID_Apo           to g_PIDS[_ascAngObj:APO_PID].
        local PID_Apo_Output    to 0.
        local PID_Avg_Error     to 0.
        local PID_Avg_Output    to 0.
        local PID_Inv_Error     to 0.
        local PID_Inv_Output    to 0.
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local turn_blend_alt    to _ascAngObj:TRN_ALT_BLEND.
        local turn_end_alt      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START.

        // Vector to pitch degree conversions
        local prograde_surface          to Ship:SrfPrograde:Vector.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograde_orbit            to Ship:Prograde:Vector.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        local prograde_effective_pitch   to prograde_orbit_pitch.

        // Check our flags for any pre-update actions
        if _ascAngObj:HasKey("RESET_PIDS")
        {
            if _ascAngObj:RESET_PIDS
            {
                PID_Alt:Reset().
                PID_Apo:Reset().
                // if g_Debug OutDebug("RESET_PIDS triggered at ({0})":Format(Round(MissionTime, 2))).
            }
            set _ascAngObj:RESET_PIDS to false.
        }
        if _ascAngObj:HasKey("UPDATE_SETPOINT")
        {
            if _ascAngObj:UPDATE_SETPOINT
            {
                set PID_Alt:Setpoint to _ascAngObj:ALT_SETPOINT.
                set PID_Apo:Setpoint to _ascAngObj:APO_SETPOINT.
                // if g_Debug OutDebug("UPDATE_SETPOINT triggered at ({0})":Format(Round(MissionTime, 2))).
            }
            set _ascAngObj:UPDATE_SETPOINT to false.
        }
    
        // Update the PID loops
        set PID_Alt_Output to PID_Alt:Update(Time:Seconds, current_alt).
        set PID_Apo_Output to PID_Apo:Update(Time:Seconds, current_apo).
        set PID_Avg_Output to (PID_Alt_Output + PID_Apo_Output) / 2.

        // Create an average value from both pid error rates
        set PID_Avg_Error  to (PID_Alt:Error + PID_Apo:Error) / 2.
        set PID_Inv_Error  to 1 - PID_Avg_Error.


        // Now do... something I guess
        if current_alt < turn_alt_start
        {
            set prograde_effective_pitch to prograde_surface_pitch.
            set error_limit    to Min(pitch_limit_max, Max(pitch_limit_min, pitch_limit_max * PID_Avg_Output)).
            set error_pitch to PID_Alt_Output.
        }
        else if current_alt < turn_end_alt and current_apo <= target_apo
        {
            local blend_window to turn_end_alt - turn_alt_start.
            local blend_error to (Ship:Altitude - turn_alt_start) / blend_window.
            set prograde_effective_pitch to (prograde_surface_pitch * (1 - blend_error)) + (prograde_orbit_pitch * blend_error).
            // set error_limit    to Min(pitch_limit_max, Max(pitch_limit_min, (pitch_limit_min * (1 - blend_error)) + (pitch_limit_max * blend_error))).
            set error_limit    to Min(pitch_limit_max, Max(pitch_limit_min, pitch_limit_max * PID_Avg_Output)).
            set error_pitch to (PID_Alt_Output * (1 - blend_error)) + (PID_Apo_Output * blend_error).
        }
        else 
        {
            set prograde_effective_pitch to prograde_orbit_pitch.
            set error_limit    to Min(pitch_limit_max, Max(pitch_limit_min, pitch_limit_max * PID_Avg_Output)).
            set error_pitch to PID_Apo_Output.
        }

        set effective_pitch     to max(prograde_effective_pitch - error_limit, min(error_pitch, prograde_effective_pitch + error_limit)).
        set output_pitch        to max(-45, min(90, effective_pitch)).

        return output_pitch.
    }

    global function GetPIDPitchAngle
    {
        parameter _ascAngObj.

        local output_pitch      to 0.

        local PID_Apo           to g_PIDS[_ascAngObj:APO_PID].
        
        if _ascAngObj:RESET_PIDS
        {
            PID_Apo:Reset().
            set _ascAngObj:RESET_PIDS to False. 
        }
        if _ascAngObj:UPDATE_SETPOINT
        {
            set PID_Apo:Setpoint to _ascAngObj:APO_TGT.
            set _ascAngObj:UPDATE_SETPOINT to False.
        }

        local pitch_limit_max  to 15. // _ascAngObj:PIT_LIM_MAX.

        // Vector to pitch degree conversions
        local existing_vector  to SteeringManager:Target:Vector.
        local existing_pitch   to 90 - VAng(Ship:Up:Vector, existing_vector).
        // local prograde_surface          to Ship:SrfPrograde:Vector.
        // local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        // local prograde_orbit            to Ship:Prograde:Vector.
        // local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        // local effective_pitch  to existing_pitch. // choose prograde_orbit_pitch if Ship:Velocity:Orbit:Mag > 1500 else prograde_surface_pitch.

        local desired_change_apo to (PID_Apo:Update(Time:Seconds, Ship:Apoapsis)).
        set output_pitch to Max(-pitch_limit_max, Min(existing_pitch + desired_change_apo, pitch_limit_max)).

        if g_Debug { OutDebug("Existing_Pitch [{0}] | Desired_Change_Apo [{1}] | output_pitch [{2}]":Format(Round(existing_pitch, 2), Round(desired_change_apo, 2), Round(output_pitch, 2)), 1).}

        return output_pitch.
    }



    global function LaunchAngForAlt
    {
        parameter turnAlt,
                  startAlt is g_la_turnAltStart,
                  endPitch is -15,
                  pitchLim is 5,
                  _fShape is 1.
        
        // Calculates needed pitch angle to track towards desired pitch at the desired turn altitude
        local pitch     to max(endPitch, 90 * (1 - ((ship:altitude - startAlt) / (turnAlt - startAlt)))). 
        // local pg to ship:srfprograde:vector.

        local pg        to ship:srfPrograde:vector.// local pg to choose ship:SrfPrograde:Vector if ship:body:atm:altitudepressure(ship:altitude) * constant:atmtokpa > 0.001 else ship:prograde:vector.
        local pgPitch   to 90 - vang(ship:up:vector, pg).
        //set pitchLim    to choose pitchLim if ship:body:atm:altitudePressure(ship:altitude) * constant:atmtokpa > 0.0040 else pitchLim * 5.
        // Calculate the effective pitch with a 5 degree limiter
        local effPitch  to max(pgPitch - pitchLim, min(pitch, pgPitch + pitchLim)) * _fShape.
        return effPitch.
    }.

    // WIP, AltitudePressure based version of Ascent Angle vs. purely height
    // global function GetAscentAng2
    // {
    //     parameter tgt_alt is body:Atm:height,
    //               tgt_ap is body:Atm:height * 2,
    //               f_shape is 1.0375. // 'shape' factor to provide a way to control the steepness of the trajectory. Values < 1 = steeper, > 1 = flatter

    //     local tgt_effAng to 90.
    //     local tgt_effAP  to max(body:Atm:Height, tgt_ap / 2).
    //     if cur_alt < g_la_turnAltStart
    //     {
    //     }
    //     else if g_ConsumedResources:HasKey("TimeRemaining")
    //     {
    //         if g_ConsumedResources["TimeRemaining"] < 5
    //         {
    //             set tgt_EffAng to pitch_for(ship, ship:srfPrograde).
    //         }
    //         else
    //         {
    //             local cur_pitAng to choose pitch_for(ship, ship:srfprograde) if cur_alt < 75000 else 
    //                 choose ((pitch_for(ship, ship:SrfPrograde) + pitch_for(ship, ship:Prograde)) / 2) if cur_alt < body:Atm:Height else 
    //                 pitch_for(ship, ship:Prograde).
    //             local tgt_effAlt to tgt_alt - g_la_turnAltStart.
    //             local cur_effAlt to 0.1 + cur_alt - g_la_turnAltStart.
    //             local cur_altErr to cur_effAlt / (tgt_effAlt / 2).
    //             local tgt_pitAng to max(-5, 90 * (1 - cur_altErr)).// * abs(f_shape - 1).
    //             local cur_pitRatio to Round(cur_alt / (Body:Atm:Height + 25000), 4).
    //             local tgt_pitRatio to Round(Ship:Apoapsis / tgt_effAP, 4).
    //             local eff_pitRatio to choose cur_pitRatio if cur_alt < Body:Atm:Height * 0.625 else tgt_pitRatio.
    //             //local tgt_angErr to min(10, max(lc_MaxAoA * eff_pitRatio, 10 * min(1, eff_pitRatio * lc_MinAoA))) * f_shape.
    //             local tgt_angErr to min(12.5, max(-12.5, ((100 * eff_pitRatio) / 2))) * f_shape.
    //             set   tgt_effAng to max(tgt_pitAng, cur_pitAng - tgt_angErr). // min(90, max(cur_pitAng - tgt_angErr, min(cur_pitAng + tgt_angErr, tgt_pitAng)) * f_shape).
    //         }
    //     }
    //     return tgt_effAng.
    // }

    // Local helper function
    
// #endregion

// *- Pre-Launch Configuration
// #region

    // ConfigureLaunchPad
    //
    global function ConfigureLaunchPlatform
    {
        local CurrentTimeSpan to TimeSpan(TIME:SECONDS).
        local lpClamps to Ship:ModulesNamed("LaunchClamp").
        local lpLights to choose lpClamps[0]:Part:PartsDubbedPattern("Light") if lpClamps:Length > 0 else list().

        if lpLights:Length > 0
        {
            local lpLightModules to list().
            for p in lpLights 
            { 
                if p:HasModule("ModuleLight") 
                {
                    local m to p:GetModule("ModuleLight"). 

                    if CurrentTimeSpan:HOUR > 11 and CurrentTimeSpan:HOUR <= 23
                    {
                        DoAction(m, "Turn Light Off", true).
                    }
                    else
                    {
                        DoAction(m, "Turn Light On", true).
                    }
                }
            }
        }

        local lpEventList to list(
            "Raise Walkway"
            ,"Lower Safety Gate"
            ,"Open Upper Clamp"
            ,"Partial Retract Tower Step 1"
        ).
        for m in Ship:ModulesNamed("ModuleAnimateGenericExtra")
        {
            if m:Part:Name:MatchesPattern("^AM.MLP.*")
            {
                for lpEvent in lpEventList
                {
                    if DoEvent(m, lpEvent) = 1
                    {
                        wait 0.01.
                        if m:HasField("Status")
                        {
                            wait until m:GetField("Status") = "Locked".
                        }
                        else 
                        {
                            wait 1.
                        }
                    }
                }
                if m:HasField("Car Height Adjust")
                {
                    m:SetField("Car Height Adjust", 0).
                }
                if m:Part:Name:MatchesPattern("^AM.MLP.*SwingArm.*") and m:Part:Tag:MatchesPattern("Retract\|(Left|Right)\|OnLoad") <> 0
                {
                    local tagSplit to m:Part:Tag:Split("|").
                    if m:HasEvent("{0} Arm {1}":Format(tagSplit[0], tagSplit[1]))
                    {
                        if DoEvent(m, "{0} Arm {1}":Format(tagSplit[0], tagSplit[1]))
                        {
                            wait until m:GetField("Status") = "Locked".
                        }
                    }
                }
            }
        }
    }

    // Resets the launch platform to pre-launch state
    global function ResetLaunchPlatform
    {
        local lpClamps to Ship:ModulesNamed("LaunchClamp").
        local lpLights to choose lpClamps[0]:Part:PartsDubbedPattern("Light") if lpClamps:Length > 0 else list().

        if lpLights:Length > 0
        {
            local lpLightModules to list().
            for p in lpLights 
            { 
                if p:HasModule("ModuleLight") 
                {
                    local m to p:GetModule("ModuleLight"). 
                    DoAction(m, "Turn Light Off", true).
                }
            }
        }

        local lpEventList to list(
            "Lower Walkway"
            ,"Raise Safety Gate"
            ,"Close Upper Clamp"
            ,"Raise Tower"
        ).
        for m in Ship:ModulesNamed("ModuleAnimateGenericExtra")
        {
            if m:Part:Name:MatchesPattern("^AM.MLP.*")
            {
                for lpEvent in lpEventList
                {
                    if DoEvent(m, lpEvent) = 1
                    {
                        wait 0.01.
                        if m:HasField("Status")
                        {
                            wait until m:GetField("Status") = "Locked".
                        }
                        else 
                        {
                            wait 1.
                        }
                    }
                }
                if m:HasField("Car Height Adjust")
                {
                    m:SetField("Car Height Adjust", 0).
                }
                if m:Part:Name:MatchesPattern("^AM.MLP.*SwingArm.*") and m:Part:Tag:MatchesPattern("Retract\|(Left|Right)\|OnLoad") <> 0
                {
                    local tagSplit to m:Part:Tag:Split("|").
                    if m:HasEvent("{0} Arm {1}":Format(tagSplit[0], tagSplit[1]))
                    {
                        if DoEvent(m, "{0} Arm {1}":Format(tagSplit[0], tagSplit[1]))
                        {
                            wait until m:GetField("Status") = "Locked".
                        }
                    }
                }
            }
        }
    }

// #endregion

// *- Launch Countdown
// #region

    // LaunchCountdown :: [<scalar>IgnitionSequenceStartSec] -> none
    // Performs the countdown
    global function LaunchCountdown
    {
        parameter t_engStart to -2.75.

        local launchStage to 99.
        // for p in Ship:PartsDubbedPattern("Clamp|AM\.MLP")
        // {
        //     set launchStage to min(launchStage, p:stage).
        // }
        for m in ship:ModulesNamed("LaunchClamp")
        {
            set launchStage to min(launchStage, m:part:stage).
        }

        local arm_engStartFlag   to true.
        local engSpoolLex to Lexicon().
        local totalSpoolTime to 0.
        local maxSpoolTime to 0.
        from { local i to Stage:Number - 1.} until i < launchStage step { set i to i - 1.} do 
        {
            local stgMaxSpool to 0.
            local stgEngSpecs to GetEnginesSpecs(GetEnginesForStage(i)).
            for eng in stgEngSpecs:Values
            {
                if eng:IsType("Lexicon")
                {
                    set stgMaxSpool  to max(stgMaxSpool, eng:SpoolTime).
                    set maxSpoolTime to max(eng:SpoolTime, maxSpoolTime).
                }
            }
            set totalSpoolTime to totalSpoolTime + stgMaxSpool.
            set engSpoolLex[i] to stgMaxSpool.
        }
        set countdown            to maxSpoolTime + 3.
        local t_launch           to Time:Seconds + countdown.
        local launchCommit       to false.
        //local hasSpool           to engSpoolLex[Stage:Number - 1][0].
        // print engSpoolLex at (5, 10).
        // Breakpoint().
        //local spoolTime          to engSpoolLex[Stage:Number - 1].
        set t_engStart           to t_launch - (maxSpoolTime * 1.025).
        
        OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).

        local l_TS to 0.

        until Time:Seconds >= t_launch or launchCommit
        {
            if Time:Seconds >= t_engStart 
            {
                if arm_engStartFlag
                {
                    if Time:Seconds > l_TS
                    {
                        EngineIgnitionSequence().
                        set l_TS to Time:Seconds + (engSpoolLex[Stage:Number] / 1.50).
                    }

                    if Stage:Number = launchStage + 1
                    {
                        set arm_engStartFlag to false.
                    }
                }
                else
                {
                    if LaunchCommitValidation(t_launch, maxSpoolTime)
                    {
                        // for p in Ship:PartsDubbedPattern("AM\.MLP.*swing.*arm.*")
                        // {
                        //     RetractSwingArms(p).
                        // }
                        until Stage:Number = launchStage 
                        { 
                            wait until Stage:READY. 
                            stage.
                        }
                        MsgInfoString("MSG", "Liftoff!").
                        OutInfo().
                    }
                    else
                    {
                        OutMsg("*** ABORT ***").
                        set t_Val to 0.
                        for eng in g_ActiveEngines
                        {
                            eng:Shutdown.
                        }
                        OutInfo().
                        Breakpoint().
                        wait 10.
                        return false.
                    }
                }
                wait 0.01.
            }

            OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).
        }
        return true.
    }



    local function LaunchCommitValidation
    {
        parameter t_liftoff to Time:Seconds,
                  t_spoolTime to 0.1,
                  launchThrustThreshold to 0.985.

        // local abortFlag         to false.
        // local launchCommit      to false.
        local engPerfAbort    to t_liftoff + 5.
        local thrustPerf        to 0.
        set t_spoolTime         to max(0.09, t_spoolTime).

        OutInfo("Validating engine performance...").
        wait 0.01.
        set g_activeEngines to GetActiveEngines().
        set t_val to 1.
        wait 0.01.

        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            until Time:Seconds > engPerfAbort
            {  
                wait 0.01.
                if t_spoolTime > 0.1
                {
                    set g_ActiveEngines to GetActiveEngines().
                    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines).
                    set thrustPerf to max(0.0001, g_ActiveEngines_Data["ThrustPct"]).

                    if Time:Seconds > t_liftoff
                    {
                        //OutInfo("EngStatus: {0}":Format(_engMod:GetField("Status")), 1).
                        OutInfo("[Ignition Status]: {0}":Format(g_ActiveEngines_Data["Ignition"]), 1).
                        // if g_ActiveEngines["ENGSTATUS"]["Status"] = "Failed"
                        // {
                        //     set t_val to 0.
                        //     return false.
                        // }
                        if thrustPerf > launchThrustThreshold
                        {
                            return true.
                        }
                    }
                    DispEngineTelemetry().
                }
                else if Time:Seconds > t_liftoff
                {
                    return true.
                }
                OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_liftoff, 1))).
            }
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
            OutInfo("Line 300", 1).
            return false.
        }
        
        // Performance not validated by abort time, so return false.
        OutInfo("Line 305", 1).
        return false.
    }


    local function EngineIgnitionSequence
    {
        set t_Val to 1.
        stage.
        wait 0.01.
        set g_ActiveEngines to GetActiveEngines().
    }

// #endregion


// *- Part Module Manipulation
// #region

    // Retract Swing Arms
    global function RetractSwingArms
    {
        parameter _part.

        if _part:Tag:MatchesPattern("left")
        {
            from { local i to 0.} until i = _part:modules:length step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if DoEvent(m, "retract arm left")
                {
                    break.
                }
                else if DoAction(m, "retract arm left", true)
                {
                    break.
                }
            }
        }
        else
        {
            from { local i to 0.} until i = _part:modules:length step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if DoEvent(m, "retract arm right")
                {
                    break.
                }
                else if DoAction(m, "retract arm right", true)
                {
                    break.
                }
            }
        }
    }
// #endregion

// #endregion