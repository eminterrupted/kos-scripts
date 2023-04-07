// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
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
    local ascent_MaxAoA             to 7.5.

    // *- Global
    global g_la_turnAltStart to Ship:Altitude + (Ship:Bounds:Size:Z * 2).    // Altitude at which the vessel will begin a gravity turn
                                                                             // taken from the bounding box of the ship on the launch pad
                                                                             // and is 2x the height of the vessel/launch pad tower
    global g_la_turnAltEnd   to body:Atm:height * 0.925. // Altitude at which the vessel will end a gravity turn
    
    global g_turn_pid to PidLoop(1.0, 0.05, 0.001, -1, 1).
    global g_apo_pid  to PidLoop(1.0, 0.05, 0.001, -1, 1).
    global g_ascentProfile to lexicon().

// #endregion


// *~--- Functions ---~* //
// #region

// *- Guidance
// #region

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
                set eff_PitAng to eff_PitAng / -4.
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
                set cur_Pit      to 90 * (1 - (eff_H_Err * _fShape)). // 90 * ((1 - (cur_Alt_Err * (blend_Window / (tgt_TurnEnd - cur_Alt))) + (1 - cur_Apo_Err)) / 2).
            }
            else
            {
                set cur_Pit_Err to cur_Err_Pro_Obt.
                set eff_H_Err   to cur_Apo_Err.
                set cur_Pit     to 90 * (eff_H_Err * _fShape).
            }
            set eff_Pit  to cur_Pit - (ascent_MaxAoA * eff_H_Err).
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
        parameter _tgtAlt.

        set g_apo_PID           to PidLoop(1.0, 0.05, 0.001, -1, 1).
        set g_apo_PID:Setpoint  to _tgtAlt.

        local trn_alt_start      to g_la_turnAltStart.
        local trn_alt_end        to 75000.// max(Body:ATM:Height + 10000, min(Body:ATM:Height + 110000, (Body:ATM:Height + _tgtAlt) / 2)).
        local trn_alt_blend      to 10000.// max(Body:Atm:Height - 50000, min(Body:ATM:Height + 50000, trn_alt_end - 100000)).
        
        set g_turn_PID           to PidLoop(1.0, 0.05, 0.001, -1, 1).
        set g_turn_PID:Setpoint  to trn_alt_end.
        
        return lexicon
        (
            "APO_PID", g_apo_PID
            ,"APO_SETPOINT", _tgtAlt
            ,"APO_TGT", _tgtAlt
            ,"PIT_LIM", 25
            ,"TRN_PID", g_turn_PID
            ,"TRN_SETPOINT", trn_alt_end
            ,"TRN_ALT_START", trn_alt_start
            ,"TRN_ALT_END", trn_alt_end
            ,"TRN_ALT_BLEND", trn_alt_blend
            ,"TRN_APO_TGT", Round(_tgtAlt * 0.875)
        ).
    }

    // WIP PART DEUX, electric OH MY GOD STAHP
    global function GetAscentAng_Next
    {
        parameter _ascAngObj,
                  _fShape is 0.99825. // Veeeerrrrry sensitive


        local pitch_limit_low   to 5.
        local altitude_error    to 0.
        local apo_error         to 0.
        local ascent_mode       to 0.
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local effective_error   to 0.
        local effective_limit   to 0.
        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to 90.
        local pid_pitch         to 0.
        local pid_value         to 1.
        
        local facing_pitch              to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).
        local prograde_pitch            to 90.
        local prograde_surface          to Ship:SrfPrograde:Vector. // Ship:Velocity:Surface.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograge_orbit            to Ship:Prograde:Vector. // Ship:Velocity:Orbit.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograge_orbit).
        local angle_of_attack_pitch     to facing_pitch - prograde_surface_pitch.
        
        local pitch_limit   to _ascAngObj:PIT_LIM.
        local target_apo    to _ascAngObj:APO_TGT.
        local target_apo_turn to _ascAngObj:TRN_APO_TGT.
        local turn_alt_blend to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end  to _ascAngObj:TRN_ALT_END.
        local turn_alt_start to _ascAngObj:TRN_ALT_START.
        
        
        if current_alt > turn_alt_start
        {
            // if current_alt < turn_alt_start
            // {
            //     set altitude_error      to current_alt / turn_alt_end.
            //     set error_pitch         to 90 * (1 - altitude_error).
            //     set error_limit         to pitch_limit_low + (pitch_limit * altitude_error).
            //     set effective_limit     to max(pitch_limit_low, min(error_limit, pitch_limit)).
            //     set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
            //     set output_pitch        to max(-5, min(effective_pitch * _fShape, 90)).
            // }
            if current_alt < turn_alt_blend
            {
                set altitude_error      to current_alt / turn_alt_end.
                set error_pitch         to 90 * (1 - altitude_error).
                set error_limit         to pitch_limit_low + (pitch_limit * altitude_error).
                set effective_limit     to max(pitch_limit_low, min(error_limit, pitch_limit)).
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
                set output_pitch        to min(90, effective_pitch * _fShape).
            }
            else if current_alt < turn_alt_end
            {
                set ascent_mode to 1.
                set altitude_error      to current_alt / turn_alt_end.
                set apo_error           to current_apo / target_apo.     
                local blend_alt_error   to (current_alt - turn_alt_blend) / (turn_alt_end - turn_alt_blend).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local apo_error_blended to apo_error * blend_alt_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                // print "alt_error_blended: {0} ":Format(round(alt_error_blended, 3)) at (2, 25).
                // print "apo_error_blended: {0} ":Format(round(apo_error_blended, 3)) at (2, 26).
                // print "comb_error: {0} ":Format(round(comb_err, 3)) at (2, 27).
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_low + (pitch_limit * altitude_error).
                set effective_limit     to max(pitch_limit_low, min(error_limit, pitch_limit * 1.5)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                //set prograde_pitch      to prograde_surface_pitch.
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                set output_pitch        to max(-10, min(effective_pitch * _fShape, 90)).
            }
            // else if current_apo < target_apo_turn
            // {
            //     set ascent_mode         to 2.
            //     set altitude_error      to current_alt / target_apo_turn.
            //     set apo_error           to current_apo / target_apo.     
            //     local blend_alt_error   to target_apo_turn - turn_alt_end.
            //     local apo_error_blended to apo_error * blend_alt_error.
            //     local comb_err          to alt_error_blended + apo_error_blended.
            //     print "alt_error_blended: {0} ":Format(round(alt_error_blended, 3)) at (2, 25).
            //     print "apo_error_blended: {0} ":Format(round(apo_error_blended, 3)) at (2, 26).
            //     print "comb_error: {0} ":Format(round(comb_err, 3)) at (2, 27).
            //     set effective_error     to comb_err.
            //     set error_pitch         to 90 * (1 - comb_err).
            //     set error_limit         to pitch_limit_low + (pitch_limit * altitude_error).
            //     set effective_limit     to max(pitch_limit_low, min(error_limit, pitch_limit * 1.5)).
            //     set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
            //     //set prograde_pitch      to prograde_surface_pitch.
            //     set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
            //     set output_pitch        to max(-15, min(effective_pitch * _fShape, 90)).

            // }
            // else if current_apo < target_apo * 0.825
            // {
            //     set ascent_mode to 3.
            //     set apo_error           to current_apo / target_apo.
            //     set error_pitch         to 90 * (1 - apo_error).
            //     set effective_limit     to max(pitch_limit_low, min(pitch_limit_low + (pitch_limit * apo_error), pitch_limit * 1.5)).
            //     set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
            //     set output_pitch        to max(-10, min(effective_pitch * _fShape, 90)).
            // }
            else
            {
                set ascent_mode to 3.
                set apo_error           to current_apo / target_apo.
                set error_pitch         to 90 * (1 - apo_error).
                set effective_limit     to max(pitch_limit_low, pitch_limit_low + (pitch_limit / min(1, apo_error))).
                // set effective_limit     to max(pitch_limit_low, min(pitch_limit_low + (pitch_limit * apo_error), pitch_limit * 3)).
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                // set effective_pitch     to max(0 - effective_limit, min(error_pitch, 0 + effective_limit)).
                set output_pitch        to max(-5, min(effective_pitch * _fShape, 90)).
            }
        }
        if output_pitch < 0 set output_pitch to output_pitch * 1.5.
        // OutInfo("out_pit (Mode): {0} ({1}) ":Format(round(output_pitch, 3), ascent_mode), 1).
        // OutInfo("aoa_pit (DLim): {0} ({1}) ":Format(round(angle_of_attack_pitch, 3), round(effective_limit, 3)), 2).
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

// *- Countdown
// #region

    // Countdown :: [<scalar>IgnitionSequenceStartSec] -> none
    // Performs the countdown
    global function LaunchCountdown
    {
        parameter t_engStart to -2.75.

        local launchStage to 99.
        for p in Ship:PartsDubbedPattern("Clamp|AM\.MLP")
        {
            set launchStage to min(launchStage, p:stage).
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
                        OutMsg("Liftoff!").
                        OutInfo().
                    }
                    else
                    {
                        OutMsg("*** ABORT ***").
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
                  launchThrustThreshold to 0.975.

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
        wait 0.025.
        set g_ActiveEngines to GetActiveEngines().
    }

// #endregion


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