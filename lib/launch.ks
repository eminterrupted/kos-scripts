// #include "0:/lib/libLoader.ks"
@lazyGlobal off.

// *~ Dependencies ~* //
// #region
    RunOncePath("0:/lib/kslib/lib_l_az_calc.ks").
    RunOncePath("0:/lib/kslib/lib_navball.ks").
// #endregion


// *~ Variables ~* //
// #region
    // *- Local
    local countdown                 to 5.
    local lc_MinAoA                 to -45.
    // local proSrfObtBlendStartAlt    to 62500.

    local partCAlt to 4776. // 4250. // 6248. // 7268. // 12500
    local proSrfObtBlendStartAlt    to 62500. // 42500. // 30000. // 37500. // 40000. // 47500. // 42500.

    local ascent_Next_Alt_Diff   to (Ship:Bounds:Size:Z * 2).
    local ascent_Next_Alt_Width  to 37500. // 32500. // 22500. // 17500.

    local ascent_Prog_Roll_Alt   to Ship:Altitude + ascent_Next_Alt_Diff.
    local ascent_Prog_Roll_Pitch to 1.725.

    local ascent_Next_Pitch_VSpd to 23.75. //28.75.
    local ascent_Prog_Pitch_Alt_Start to 292. // 327. // 427.
    local ascent_Prog_Pitch_Alt_End   to 112500. // 120000. // 112001. // 100000. // Body:Atm:Height.

    local arcAzDataPath to "0:/data/scratch/azData.json".
    local locAzDataPath to "1:/data/azData.json".

    local crewCapDelegate to { parameter _v. local eCrewCap to _v:CrewCapacity. for p in _v:PartsTaggedPattern("PadCrewCap\|\d+") { set eCrewCap to eCrewCap - p:Tag:Split("|")[1]:ToNumber(0).} return eCrewCap.}.
    local effCrewCap to crewCapDelegate:Call(Ship).
    OutInfo("Effective Crew Capacity: {0} ":Format(effCrewCap)).
    local l_CrewRollVal             to choose 180 if effCrewCap > 0 else 0.

    local phase2Factor              to 0.475.// 0.69230769230775. // 0.725.

    // local l_localGravityDel to choose { return Constant:g0.} if Ship:Body:Name = "Earth" else { return GetLocalGravity(Ship:Body, Ship:Altitude).}.

    local Ascent_Ang_Max to 90.
    local Ascent_Ang_Min to 89.75.
    // local Ascent_Ang_Min to -12.25.
    local Ascent_AoA_Max to 18.
    local Ascent_AoA_Min to 0.0125.

    local Ascent_Blend_Ang_Out to 12.5.

    local PID_AoA_Max    to 4.
    local PID_AoA_Min    to -4.
    local PID_Ang_Max    to 21.
    local PID_Ang_Min    to -12.

    local l_twr_denom to 3.
    local l_pid_twr_ctrl to true.

    local phaseUpdateStr to " {0,-8} | {1,-6} | {2,-8} ".
    global phaseUpdateIdx to 0.

    local l_prog to 0.
    local l_rnmd to 0.

    local l_pid_loop_control_active to False.

    // *- Global
    global g_LaunchParams       to lexicon().
    global g_PresetTurnAlt      to 200.
    global g_la_turnAltStart    to Min(g_PresetTurnAlt, Max(125, Ship:Altitude + Ship:Bounds:Size:Z)). // Altitude at which the vessel will begin a gravity turn
                                                                             // taken from the bounding box of the ship on the launch pad
                                                                             // and is 2x the height of the vessel/launch pad tower
    global g_la_turnAltEnd   to body:Atm:height. //  * 0.72. // 0.64 = 89600m // 70000// 0.925 // Altitude at which the vessel will end a gravity turn

    global g_alt_PID to PidLoop(0.05, 0.01, 0.0325, PID_AoA_Min, PID_AoA_Max).
    global g_apo_pid  to PidLoop(0.005, 0.000125, 0.005, PID_AoA_Min, PID_AoA_Max).
    global g_ascentProfile to lexicon().
    // global g_azData to list().

    global g_PID_Flag       to False.
    global g_PID_Alt_Flag   to False.
    global g_PID_Apo_Flag   to False.
    global g_PID_Enabled    to False.
    global g_PID_Active     to False.

    // Prelaunch params
    global g_LaunchSiteGeo to Ship:GeoPosition.
    global g_PreLaunch_Data to lexicon(
        "LC", lexicon(
            "ALT",  Ship:Altitude
            ,"GEO", g_LaunchSiteGeo
            ,"LAT", g_LaunchSiteGeo:Lat
            ,"LNG", g_LaunchSiteGeo:Lng
        )
    ).

    local MLPModuleLex to lex(
        "Events", list (
            "Rotate Crane"
            ,"Raise Arm"
            ,"Retract Arm"
            ,"Retract Crew Arm"
            ,"Lower Arm"
            ,"Lower Safety Gate"
            ,"Open Upper Clamp"
            ,"Partial Retract Tower Step 1"
            ,"Raise Walkway"
            ,"Elevator down"
            ,"Elevator 1 down"
            ,"Elevator 2 down"
            ,"Lower Gantry Arms"
            ,"Retract Gantry Arms"
        ),
        "Actions", list(
            "Arms", list(
                "Toggle Arm Left"
                ,"Toggle Arm Right"
                ,"Toggle"
            )
        ),
        "Fields", list(
            "Car Height Adjust"
            ,"Arm Length Adjust"
        ),
        "SwingArms", lex(
            "Events", lex(
                "Raise", list(
                    "Raise Arm"
                    ,"Retract Arm"
                    ,"Retract Crew Arm"
                    ,"Retract Gantry Arms"
                ),
                "Lower", list(
                    "LowerArm"
                    ,"Lower Gantry Arms"
                )
            )
        )
    ).

    local countdownPreReqs to lex(
        "PART", lex(
            "AM.MLP.SoyuzLaunchBaseArmLG", 12,
            "AM.MLP.SoyuzLaunchBaseArmSM", 12,
            "AM.MLP.SoyuzLaunchBaseGantry", 24,
            "AM.MLP.SoyuzLaunchBaseElevator", 30
        ),
        "LV", lex(),
        "TAG", lex(),
        "MODULE", lex()        
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

        set g_Program to 1201.

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
            local fShape  to 1.125. // 1.092.
            local minPit  to 0.
            local pitLim  to 40.
            // local fShape  to 1.075.
            // local pitLim  to 33.
            //local pidVals to list(0.25, 0.05, 0.5, 1). // P, I, D, ChangeRate (upper / lower bounds for PID)
            local pidVals to list(0.0075, 0.001, 0.0125, list((-pitLim * 0.5), pitLim)). // P, I, D, ChangeRate (upper / lower bounds for PID)

            if g_MissionTag:Mission:MatchesPattern("DownRange")
            {
                set fShape to 1.
                // set minPit to 1.725.
                // set pitLim to 12.5.
                // set pitBase to "Pro".
                // set fShape to 1.0125.
                set minPit to 0.125.
                set pitLim to 17.25.
                // set pidVals to list(0.0025, 0.00125, 0.00125, 1). // P, I, D, ChangeRate (upper / lower bounds for PID)
                set pidVals to list(0.0375, 0.001, 0.0725, list(-pitLim, pitLim)). // P, I, D, ChangeRate (upper / lower bounds for PID)
                set _delDependency to InitAscentAng_Next(_tgtInc, _tgtAlt, fShape, minPit, pitLim, True, pidVals).
            }
            else if g_MissionTag:Mission:MatchesPattern("SubOrbital")
            {
                set fShape to 0.96.
                set minPit to 1.25.
                set pitLim to 18.
                set pidVals to list(0.01, 0.00125, 0.01125, list(-pitLim, pitLim)). // P, I, D, ChangeRate (upper / lower bounds for PID)
                // set pidVals to list(0.125, 0.00125, 0.725, 1). // P, I, D, ChangeRate (upper / lower bounds for PID)
                set _delDependency to InitAscentAng_Next(_tgtInc, _tgtAlt, fShape, minPit, pitLim, True, pidVals).
            }
            else if Ship:Name:MatchesPattern("^S.OUT.*")
            {
                set fShape to 1.25.
                set minPit to 1.75.
                set pitLim to 24.
                // set pidVals to list(0.25, 0.0125, 0.5, 1). // P, I, D, ChangeRate (upper / lower bounds for PID)
                set pidVals to list(0.004, 0.000125, 0.00325, list(-pitLim, pitLim)). // P, I, D, ChangeRate (upper / lower bounds for PID)
                set _delDependency to InitAscentAng_Next(_tgtInc, _tgtAlt, fShape, minPit, pitLim, True, pidVals).
            }
            else // Orbit
            {
                set minPit to -18.
                set _delDependency to InitAscentAng_Next(_tgtInc, _tgtAlt, fShape, minPit, pitLim, True, pidVals).
                // set _delDependency to InitAscentAng_TreePIDdy(_tgtInc, _tgtAlt, fShape, minPit, pitLim, True, pidVals).
            }
            OutInfo("[TgtInc] {0,-3} | [TgtAlt] {1,-7}":Format(Round(_tgtInc, 2), Round(_tgtAlt)), 1).
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
            // set del to { if Ship:Altitude >= g_PresetTurnAlt { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_PID_FuckingThingSucks(_delDependency), 0). } else { return Heading(compass_for(Ship, Ship:Facing), 90, 0). }}.
            set del to { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), 0).}.
        }
        else if g_MissionTag:Mission:MatchesPattern("^(SubOrbit|Suborbital|PIDSubOrbital)") // Suborbital hop :: [0] Inclination and [1]Target Alt
        {
            set _delDependency["l_az_calc"] to _azData.
            set del to { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), l_CrewRollVal).}.
        }
        else if g_MissionTag:Mission:MatchesPattern("^(Orbit|Orbital|PIDOrbit)$") // Orbital insertion :: [0] Inclination and [1]Target Alt
        {
            set _delDependency["l_az_calc"] to _azData.
            if not _delDependency:HasKey("TRN_ALT_START")
            {
                set _delDependency["TRN_ALT_START"] to ascent_Next_Alt_Diff.
            }
            // set del to { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_TreePIDdy(_delDependency), l_CrewRollVal).}. // GetAscentAng_Next(_delDependency), l_CrewRollVal).}.
            set del to { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), l_CrewRollVal).}. // GetAscentAng_Next(_delDependency), l_CrewRollVal).}.
        }
        else if g_MissionTag:Mission = "Circularize"
        {
            // set _delDependency to InitAscentAng_Next(_tgtAlt, _delDependency:FSHAPE).
            set _delDependency["l_az_calc"] to _azData.
            set del to { return Heading(l_az_calc(_delDependency["l_az_calc"]), GetAscentAng_Next(_delDependency), l_CrewRollVal). }.
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
                           else choose ((srfProPit + obtProPit) / 2) if nrmlzdAlt < 12500
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

        local tgt_TurnEnd       to max(_tgtAp / 2, ascent_Prog_Pitch_Alt_End).

        local blend_Err         to 0.
        local blend_Window      to tgt_TurnEnd - ascent_Prog_Pitch_Alt_Start.
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

            set blend_Err       to (cur_Alt - ascent_Prog_Pitch_Alt_Start) / blend_Window.

            set cur_Pit_Facing  to pitch_for(Ship, Ship:Facing).
            set cur_Pit_Pro_Srf to pitch_for(Ship, Ship:SrfPrograde).
            set cur_Pit_Pro_Obt to pitch_for(Ship, Ship:Prograde).

            set cur_Err_Pro_Srf to cur_Pit_Pro_Srf - cur_Pit_Facing.
            set cur_Err_Pro_Obt to cur_Pit_Pro_Obt - cur_Pit_Facing.

            if cur_Alt < ascent_Prog_Pitch_Alt_Start
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
                  _initPids is false,
                  _pidVals is list(0.0025, 0.0000125, 0.00325, list(-1,1)),
                  _tgtApoETA is 42. // P, I, D, ChangeRate (upper / lower bounds for PID)

        // set g_apo_PID           to PidLoop(1.0, 0.05, 0.001, -45, 90).
        // set g_apo_PID:Setpoint  to _tgtAlt.
        
        // local geo_height          to Ship:GeoPosition:TerrainHeight.
        // local turn_alt_start_track to ascent_Blend_Alt_Start. //  if Ship:Altitude >= (Body:Atm:Height + 25000) else ascent_Blend_Alt_Start.// Round(((Ship:Altitude - geo_height) * 1.0625) + geo_height).
        // local turn_alt_end  to choose 70000 if _tgtAlt <= 200000 else min(125000, max(72000, Round(_tgtAlt / 5))).// 72500 
        // local turn_alt_end        to 175000. // choose 100000 if Body:Atm:Height < 100000 else Body:Atm:Height. //   _tgtAlt <= 200000 else min(325000, max(80000, Round(_tgtAlt / 2.5))).// 72500 
        
        // local turn_alt_blend      to 500. 
        // local turn_alt_blend    to proSrfObtBlendStartAlt.
        local turn_alt_blend    to Min(proSrfObtBlendStartAlt, Max(37500, _tgtAlt / 4)). // 37500. //Max(proSrfObtBlendStartAlt, _tgtAlt / 6).
        // local turn_alt_blend    to proSrfObtBlendStartAlt * 0.925. // 37500. //Max(proSrfObtBlendStartAlt, _tgtAlt / 6).
        // local turn_alt_end      to Min(g_la_turnAltEnd, Max(proSrfObtBlendStartAlt + ascent_Next_Alt_Width, _tgtAlt / 4)).
        local turn_alt_end      to Min(g_la_turnAltEnd, Max(proSrfObtBlendStartAlt + ascent_Next_Alt_Width, _tgtAlt / 3.25)).
        // local turn_alt_blend to proSrfObtBlendStartAlt.
        local turn_alt_blend_window_set to choose list(turn_alt_blend * 0.425, turn_alt_blend * 0.675, turn_alt_blend) if g_MissionTag:Mission:MatchesPattern("DownRange") else list(turn_alt_blend * 0.5, turn_alt_blend * 0.75, turn_alt_blend * 1).
        local turn_apo_tgt        to Round(Max(_tgtAlt * 0.925, turn_alt_blend * 1.125)).
        // local turn_apo_tgt        to Round(Max(_tgtAlt * 0.8725, turn_alt_blend * 1.1125)).

        local ascentAngObj to lexicon(
            "ALT_TGT", ascent_Prog_Roll_Alt
            ,"ALT_TRANS", Ship:Altitude
            ,"APO_ETA_TGT", _tgtApoETA
            ,"APO_TGT", _tgtAlt
            ,"APO_TGT_THRESH", _tgtAlt * 0.9
            ,"APO_TGT_FTT", Max(Body:Atm:Height + 25000, Round(_tgtAlt * 0.725))
            ,"FSHAPE", _fShape
            ,"IN_TRANSITION", false
            ,"INC_TGT", _tgtInc
            ,"PIT_ANG_ERR", 0
            ,"PIT_ANG_LIM_MAX_SET", Queue(90, 63.3, 47, 33, 12.5)
            ,"PIT_ANG_LIM_MAX", Ascent_Ang_Max
            ,"PIT_ANG_LIM_MAX_SPREAD", 2
            ,"PIT_ANG_LIM_MIN", Ascent_Ang_Min
            ,"PIT_ANG_LIM_MIN", Queue()
            ,"PIT_ANG_LIM_NEXT", 89
            ,"PIT_LIM_MAX", _pitLimMax
            ,"PIT_LIM_MIN", _pitLimMin
            ,"PIT_LIM_SET", _pitLimMax
            ,"PIT_MAX", 90
            ,"PIT_UPPER_BOUND",90
            ,"PRO_BLEND_WIDTH", 32500
            ,"PRO_BLEND_END", 0
            ,"PRO_BLEND_START", 0
            ,"TRANS_ALT_ACTUAL", 0
            ,"TRANS_ALT_NEXT", 0
            ,"TRANS_PIT_ACTUAL", 90
            ,"TRANS_PIT_NEXT", 89
            ,"TRANS_ALT_WINDOW", 25000
            ,"TRN_ALT_START", ascent_Prog_Pitch_Alt_Start
            ,"TRN_ALT_START_KIK", ascent_Prog_Roll_Alt
            ,"TRN_ALT_START_TRK", ascent_Prog_Pitch_Alt_Start
            ,"TRN_ALT_END", turn_alt_end
            ,"TRN_ALT_BLEND", turn_alt_blend
            ,"TRN_ALT_BLEND_WINDOW", turn_alt_blend_window_set
            ,"TRN_APO_TGT", turn_apo_tgt
            ,"TRN_DEG_KIK", ascent_Prog_Roll_Pitch
            ,"TRN_SPD_START_KIK", ascent_Next_Pitch_VSpd
            ,"TWR_SMPL", false
            ,"TWR_CUR", 0.000001
            ,"TWR_LAST", 0.000001
            ,"MARK",0
        ).

        if _initPids
        {
            local pidResult to InitAscentAnglePIDs(_pidVals, _tgtAlt).

            ascentAngObj:Add("APO_PID", pidResult["APO_PID"]).
            ascentAngObj:Add("APO_PID_PDEF", _pidVals[0]).
            ascentAngObj:Add("APO_PID_IDEF", _pidVals[1]).
            ascentAngObj:Add("APO_PID_DDEF", _pidVals[2]).
            ascentAngObj:Add("APO_PID_SETPOINT", pidResult["APO_PID_SETPOINT"]).
            ascentAngObj:Add("APO_PID_ANG_MAX", PID_Ang_Max).
            ascentAngObj:Add("APO_PID_ANG_MIN", PID_Ang_Min).
            ascentAngObj:Add("APO_PID_LIM_MAX", PID_AoA_Max).
            ascentAngObj:Add("APO_PID_LIM_MIN", PID_AoA_Min).
            ascentAngObj:Add("APO_PID_RESET", pidResult["APO_PID_RESET"]).
            ascentAngObj:Add("APO_PID_UPDATE_SETPOINT", pidResult["UPDATE_SETPOINT"]).

        }
        
        OutInfo("TurnAlt: {0}":Format(turn_alt_end)).

        set l_prog to 1.
        set l_rnmd to 1.

        return ascentAngObj.
    }

    // Does what it says
    global function InitAscentAng_TreePIDdy
    {
        parameter _tgtInc,
                  _tgtApo,
                  _fShape is 1,
                  _pitAngMin is 89,
                  _pitAoALim is Ascent_Ang_Min,
                  _initPids is True,
                  _pidVals is list(0.00625, 0.0001, 0.0075, list(-2.375,2.375)). // P, I, D, ChangeRate (upper / lower bounds for PID)

        local prog_Alt_Gate_Tower to (Ship:Altitude * 2) + (Ship:Bounds:Size:Z * 2).
        local prog_Alt_Gate_Roll  to prog_Alt_Gate_Tower + 125.
        local prog_Alt_Gate_Pit   to prog_Alt_Gate_Roll + 625.
        local prog_Alt_Gate_Pro   to Min(50000,  Max(prog_Alt_Gate_Pit + 40000,  _tgtApo / 7)). 
        local prog_Alt_Gate_Turn  to Min(80000,  Max(prog_Alt_Gate_Pro + 30000,  _tgtApo / 4.5)). 
        local prog_Alt_Gate_Apo   to Min(110000, Max(prog_Alt_Gate_Turn + 20000, _tgtApo / 2)). 

        local prog_Alt_Gate_Blend_Factor to (prog_Alt_Gate_Pro / prog_Alt_Gate_Apo).
        local prog_Alt_Gate_Blend_Factor_Norm to (1 - ((prog_Alt_Gate_Blend_Factor * 2) + (prog_Alt_Gate_Blend_Factor / 4) - 1)) / _fShape.

        local prog_Apo_Gate_PID_Tgt to _tgtApo * prog_Alt_Gate_Blend_Factor_Norm.
        local prog_Apo_Gate_Tgt     to _tgtApo.

        local prog_Ang_Max_Tower to Ascent_Ang_Max.
        local prog_Ang_Max_Roll  to _pitAngMin.
        local prog_Ang_Max_Pit   to Min(64, (prog_Ang_Max_Roll - 32)). //* prog_Alt_Gate_Blend_Factor). // Max(50, Min(prog_Ang_Max_Roll, 90 * prog_Alt_Gate_Blend_Factor)).
        local prog_Ang_Max_Pro   to Min(32, (prog_Ang_Max_Pit  - 16) * prog_Alt_Gate_Blend_Factor * 0.86).
        local prog_Ang_Max_Turn  to Min(16, (prog_Ang_Max_Pro  - 8)  * prog_Alt_Gate_Blend_Factor * 0.64).
        local prog_Ang_Max_Apo   to Min(PID_Ang_Max, prog_Ang_Max_Turn).

        local prog_Ang_Min_Tower to prog_Ang_Max_Roll.// * prog_Alt_Gate_Blend_Factor_Norm.
        local prog_Ang_Min_Roll  to prog_Ang_Max_Pit.//  * (prog_Alt_Gate_Blend_Factor_Norm * 0.98).
        local prog_Ang_Min_Pit   to prog_Ang_Max_Pro.// * (prog_Alt_Gate_Blend_Factor_Norm * 0.86).
        local prog_Ang_Min_Pro   to prog_Ang_Max_Turn.// * (prog_Alt_Gate_Blend_Factor_Norm * 0.72).
        local prog_Ang_Min_Turn  to prog_Ang_Max_Apo.// * (prog_Alt_Gate_Blend_Factor_Norm * 0.64).
        local prog_Ang_Min_Apo   to Max(PID_Ang_Min, prog_Ang_Min_Turn).

        local prog_AoA_Tower to 0.005.
        local prog_AoA_Roll to 0.125.
        local prog_AoA_Pit  to 15   * (1 - prog_Alt_Gate_Blend_Factor). // Max(-60, Min(-30, -60 * prog_Alt_Gate_Blend_Factor)).
        local prog_AoA_Pro to 37.5 * (1 - prog_Alt_Gate_Blend_Factor). // Max(-60, Min(-30, -60 * prog_Alt_Gate_Blend_Factor)).
        local prog_AoA_Turn  to 60.
        local prog_AoA_Apo  to 17.5.

        local prog_Spd_Gate_Tower to 10.
        local prog_Spd_Gate_Roll  to 17.5.
        local prog_Spd_Gate_Pit   to 27.
        local prog_Spd_Gate_Pro   to 1325.
        local prog_Spd_Gate_Turn  to 1725.
        local prog_Spd_Gate_Apo   to 2000.

        local prog_TWR_Gate_Tower to 1.07.
        local prog_TWR_Gate_Roll  to 1.1.
        local prog_TWR_Gate_Pit   to 1.15.
        local prog_TWR_Gate_Pro   to 3.
        local prog_TWR_Gate_Turn  to 4.25.
        local prog_TWR_Gate_Apo   to 5.

        // local prog_Alt_Queue     to queue(prog_Alt_Gate_Tower,  prog_Alt_Gate_Roll, prog_Alt_Gate_Pit,  prog_Alt_Gate_ProBlend, prog_Alt_Gate_ProObt,   prog_Alt_Gate_Turn  ).
        local prog_Alt_Queue     to queue(prog_Alt_Gate_Tower,  prog_Alt_Gate_Roll, prog_Alt_Gate_Pit,  prog_Alt_Gate_Pro,      prog_Alt_Gate_Turn,     prog_Alt_Gate_Apo   ).
        local prog_Ang_Max_Queue to queue(prog_Ang_Max_Tower,   prog_Ang_Max_Roll,  prog_Ang_Max_Pit,   prog_Ang_Max_Pro,       prog_Ang_Max_Turn,      prog_Ang_Max_Apo    ).
        local prog_Ang_Min_Queue to queue(prog_Ang_Min_Tower,   prog_Ang_Min_Roll,  prog_Ang_Min_Pit,   prog_Ang_Min_Pro,       prog_Ang_Min_Turn,      prog_Ang_Min_Apo    ).
        local prog_AoA_Queue     to queue(prog_AoA_Tower,       prog_AoA_Roll,      prog_AoA_Pit,       prog_AoA_Pro,           prog_AoA_Turn,          prog_AoA_Apo        ).
        local prog_Spd_Queue     to queue(prog_Spd_Gate_Tower,  prog_Spd_Gate_Roll, prog_Spd_Gate_Pit,  prog_Spd_Gate_Pro,      prog_Spd_Gate_Turn,     prog_Spd_Gate_Apo   ).
        local prog_TWR_Queue     to queue(prog_TWR_Gate_Tower,  prog_TWR_Gate_Roll, prog_TWR_Gate_Pit,  prog_TWR_Gate_Pro,      prog_TWR_Gate_Turn,     prog_TWR_Gate_Apo   ).


        local ascentAngObj to lexicon(
            "FSHAPE", _fShape,
            "MARK", 0,
            "TGTINC", _tgtInc,
            "APOTGT", prog_Apo_Gate_Tgt,
            "PIDTGT", prog_Apo_Gate_PID_Tgt,
            "PROG", lexicon(
                "ALT", lexicon(
                    "LAST",  0,
                    "CUR",   prog_Alt_Queue:Pop(),
                    "NEXT",  prog_Alt_Queue:Peek(),
                    "QUEUE", prog_Alt_Queue
                ),
                "ANG", lexicon(
                    "DELTACOMBI", 0,
                    "DELTAS", list(),
                    "MAX", lexicon(
                        "LAST",   Ascent_Ang_Max,
                        "DEF",    Ascent_Ang_Max,
                        "DELTA",   Ascent_Ang_Max - prog_Ang_Max_Queue:Peek(),
                        "CUR",    prog_Ang_Max_Queue:Pop(),
                        "NEXT",   prog_Ang_Max_Queue:Peek(),
                        "QUEUE",  prog_Ang_Max_Queue
                    ),
                    "MIN", lexicon(
                        "LAST",   Ascent_Ang_Min,
                        "DEF",    Ascent_Ang_Min,
                        "DELTA",   Ascent_Ang_Min - prog_Ang_Min_Queue:Peek(),
                        "CUR",    prog_Ang_Min_Queue:Pop(),
                        "NEXT",   prog_Ang_Min_Queue:Peek(),
                        "QUEUE",  prog_Ang_Min_Queue
                    )
                ),
                "AOA", lexicon(
                    "LAST",  prog_AoA_Queue:Peek(),
                    "CUR",   prog_AoA_Queue:Pop(),
                    "DEF",   _pitAoALim,
                    "DELTA", 0,
                    "NEXT",  prog_AoA_Queue:Peek(),
                    "QUEUE", prog_AoA_Queue
                ),
                "SPD", lexicon(
                    "CUR",   0,
                    "DEF",   0,
                    "NEXT",  0,
                    "DELTA", 0,
                    "QUEUE", prog_Spd_Queue
                ),
                "TWR", lexicon(
                    "ACTIVE", 1,
                    "CUR",    1,
                    "DEF",    1,
                    "DELTA", 0,
                    "FACTOR", 1,
                    "LAST",   1,
                    "NEXT",   1,
                    "QUEUE",  prog_TWR_Queue,
                    "SMPL",   true

                )
            )
        ).

        if _initPids
        {
            local pidResult to InitAscentAnglePIDs(_pidVals, _tgtApo).

            ascentAngObj:Add("PID", lexicon()).
            set ascentAngObj:PID to lexicon("APO", lexicon(
                    "PIDREF", pidResult["APO_PID"],
                    "PDEF", _pidVals[0],
                    "IDEF", _pidVals[1],
                    "DDEF", _pidVals[2],
                    "SETPOINT", pidResult["APO_PID_SETPOINT"],
                    "ANG_MAX", prog_AoA_Apo,
                    "ANG_MIN", -prog_AoA_Apo * 0.5,
                    "LIM_MAX", _pidVals[3][1],
                    "LIM_MIN", _pidVals[3][0],
                    "RESET", pidResult["APO_PID_RESET"],
                    "UPDATE_SETPOINT", pidResult["UPDATE_SETPOINT"]
                )
            ).
        }
        
        OutInfo("Next Transition Altitude {0}":Format(ascentAngObj:PROG:ALT:NEXT)).


        set l_prog to 1.
        set l_rnmd to 1.

        return ascentAngObj.
    }

    // InitAscentAnglePIDs :: _pidParams(<List>P, I, D, valLow, valHigh)
    // Initializes PID loops used during ascent and returns a lexicon for inclusion in AscentAngData
    local function InitAscentAnglePIDs
    {
        parameter _pidParams is list(0.0075, 0.001, 0.0125, list(-1, 1)),
                  _tgtAlt is Max(Body:Atm:Height, 25000).

        local pid_P to _pidParams[0].
        local pid_I to _pidParams[1].
        local pid_D to _pidParams[2].
        local pid_MinVal to 0.
        local pid_MaxVal to 0.
        if _pidParams[3]:IsType("List")
        {
            set pid_MinVal to _pidParams[3][0]. 
            set pid_MaxVal to _pidParams[3][1]. 
        }
        else
        {
            if _pidParams:Length > 4
            {
                set pid_MinVal to _pidParams[3].
                set pid_MaxVal to _pidParams[4].
            }
            else
            {
                set pid_MinVal to Min(_pidParams[3], -_pidParams[3]).
                set pid_MaxVal to Max(_pidParams[3], -_pidParams[3]).
            }
        }

        local pid_Apo_ID to "TurnApo".
        set g_PIDS[pid_Apo_ID] to PIDLoop(pid_P, pid_I, pid_D, pid_MinVal, pid_MaxVal).
        set g_PIDS[pid_Apo_ID]:Setpoint to _tgtAlt.

        return Lexicon(
            "APO_PID", pid_Apo_ID,
            "APO_PID_SETPOINT", _tgtAlt,
            "APO_PID_RESET", True,
            "UPDATE_SETPOINT", True
        ).
    }


    // WIP PART FUUUU, jesus fucking chris
    // #TODO: Examine benefit of moving fshape to limits vs eff pitch (* currently in progress)
    global function GetAscentAng_TreePIDdy
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_GatedPID", 0).

        local fShape           to _ascAngObj:FSHAPE.
        local altitude_error   to 0.
        local apo_error        to 0.
        local blend_error      to 0.
        local current_alt      to Ship:Altitude.
        local current_apo      to Ship:Apoapsis.
        local current_pitch    to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).
        local effective_pitch  to 90.
        local error_limit      to 0.
        local err_pit_delta    to 0.
        local output_pitch     to current_pitch.

        local prograde_pitch         to 90.
        local prograde_surface_pitch to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch   to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        local prograde_error_thresh  to 0.625.
        
        local aoa_limit_max to _ascAngObj:PROG:AOA:CUR.
        local aoa_limit_min to 0.

        local ang_limit_max to _ascAngObj:PROG:ANG:MAX:CUR.
        local ang_limit_min to _ascAngObj:PROG:ANG:MIN:CUR.

        local apo_tgt       to _ascAngObj:APOTGT.
        local apo_pid_tgt   to _ascAngObj:PIDTGT.
        
        local trans_alt_current to _ascAngObj:PROG:ALT:CUR.
        local trans_alt_next    to _ascAngObj:PROG:ALT:NEXT.
        
        OutInfo("[P{0,2}:R{1,-3}  ":Format(g_Program, g_RunMode), 2).

        if not g_SpinActive
        {
            if g_RunMode < 0
            {
                RunPath("0:/main/launch/launchAbort").
                return 1 / 0.
            }
            else if g_RunMode > 0
            {
                local trans_ang_factor to Min(1.2, Max(0, trans_alt_current / trans_alt_next)).
                set altitude_error to Min(1, Max(0, (current_alt / trans_alt_current) * trans_ang_factor)).
                set apo_error to current_apo / apo_tgt.

                // local active_twr to choose 0.00001 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR.
                // local twr_factor to choose 1 if _ascAngObj:PROG:TWR:FACTOR = 0 else _ascAngObj:PROG:TWR:FACTOR.
                // local twr_variance to 0.01.

                // if _ascAngObj:PROG:TWR:SMPL
                // {

                //     set _ascAngObj:PROG:TWR:FACTOR to Min(3, Max(0.125, active_twr / _ascAngObj:PROG:TWR:CUR)).
                //     set _ascAngObj:PROG:TWR:LAST   to _ascAngObj:PROG:TWR:ACTIVE.
                //     set _ascAngObj:PROG:TWR:ACTIVE to active_twr.
                //     set _ascAngObj:PROG:TWR:SMPL   to false.
                // }
                // else
                // {
                //     set twr_variance to Abs((active_twr / _ascAngObj:PROG:TWR:ACTIVE) - 1).
                    
                //     if twr_variance > 0.025
                //     {
                //         set _ascAngObj:PROG:TWR:SMPL to true.
                //     }
                // }

                if g_RunMode < 80
                {
                    if apo_error >= apo_pid_tgt
                    {
                        set g_RunMode to 100.
                    }
                    else
                    {

                        if altitude_error > 1 and (Ship:Velocity:Surface:Mag > _ascAngObj:PROG:SPD:CUR) //or twr_factor >= 1.5)
                        {
                            if _ascAngObj:PROG:ANG:MAX:QUEUE:Length > 0
                            {
                                set _ascAngObj:PROG:ANG:MAX:CUR  to Min(current_pitch, _ascAngObj:PROG:ANG:MAX:NEXT).
                                set _ascAngObj:PROG:ANG:MAX:NEXT to _ascAngObj:PROG:ANG:MAX:QUEUE:Pop().
                            }
                            if _ascAngObj:PROG:ANG:MIN:QUEUE:Length > 0
                            {
                                set _ascAngObj:PROG:ANG:MIN:CUR  to _ascAngObj:PROG:ANG:MIN:NEXT.
                                set _ascAngObj:PROG:ANG:MIN:NEXT to _ascAngObj:PROG:ANG:MIN:QUEUE:Pop().
                            }
                            if _ascAngObj:PROG:AOA:QUEUE:Length > 0 
                            {
                                set _ascAngObj:PROG:AOA:CUR  to _ascAngObj:PROG:AOA:NEXT.
                                set _ascAngObj:PROG:AOA:NEXT to _ascAngObj:PROG:AOA:QUEUE:Pop().
                            }
                            if _ascAngObj:PROG:SPD:QUEUE:Length > 0
                            {
                                set _ascAngObj:PROG:SPD:CUR  to _ascAngObj:PROG:SPD:NEXT.
                                set _ascAngObj:PROG:SPD:NEXT to _ascAngObj:PROG:SPD:QUEUE:Pop().
                            }
                            // if _ascAngObj:PROG:TWR:QUEUE:Length > 0
                            // {
                            //     set _ascAngObj:PROG:TWR:CUR  to _ascAngObj:PROG:TWR:NEXT.
                            //     set _ascAngObj:PROG:TWR:NEXT to _ascAngObj:PROG:TWR:QUEUE:Pop().
                            // }
                            local delta to Abs(_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MIN:CUR).
                            local delta_50_pct to (_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MAX:NEXT + _ascAngObj:PROG:ANG:MIN:CUR - _ascAngObj:PROG:ANG:MIN:NEXT) / 2.

                            set _ascAngObj:PROG:ANG:DELTACOMBI to delta.
                            set _ascAngObj:PROG:ANG:DELTAS to list(delta, delta_50_pct, _ascAngObj:PROG:ANG:MAX:NEXT - _ascAngObj:PROG:ANG:MIN:NEXT).

                            set _ascAngObj:MARK to Time:Seconds.

                            if _ascAngObj:PROG:ALT:QUEUE:Length > 0 //  or g_RunMode > 405
                            {
                                set _ascAngObj:PROG:ALT:LAST  to current_alt.
                                set _ascAngObj:PROG:ALT:CUR  to _ascAngObj:PROG:ALT:NEXT.
                                set _ascAngObj:PROG:ALT:NEXT to _ascAngObj:PROG:ALT:QUEUE:Pop().
                            
                                set g_RunMode to g_RunMode + 5.
                            }
                            else
                            {
                                set g_RunMode to 80.
                            }
                        }
                        else
                        {
                            set err_pit_delta to (_ascAngObj:PROG:ANG:DELTACOMBI * altitude_error).// * twr_factor.
                            local wanted_pitch  to ang_limit_max - err_pit_delta.

                            local prograde_delta to prograde_surface_pitch - prograde_orbit_pitch.
                            local prograde_error to (4 / prograde_delta) * fShape.

                            if prograde_error * fShape >= 1
                            {
                                set prograde_pitch to prograde_orbit_pitch.
                            }
                            else if prograde_error <= prograde_error_thresh
                            {
                                set prograde_pitch to prograde_surface_pitch.
                            }
                            else
                            {
                                set prograde_error to (prograde_error - prograde_error_thresh) / (1 - prograde_error_thresh).
                                set prograde_pitch to prograde_surface_pitch * (1 - prograde_error) + (prograde_orbit_pitch * prograde_error). 
                            }

                            // set error_limit   to aoa_limit_min + (aoa_limit_max * twr_factor * (altitude_error * fShape)).
                            set error_limit   to aoa_limit_min + (aoa_limit_max * (altitude_error * fShape)).
                            set output_pitch to Min(prograde_pitch + error_limit, Max(prograde_pitch - error_limit, wanted_pitch)).
                        }
                    }
                }
                else if g_RunMode < 100
                {
                    if apo_error >= apo_pid_tgt
                    {
                        set g_PID_Enabled to True.
                        
                        if _ascAngObj:PROG:ANG:MAX:QUEUE:Length > 0
                        {
                            set _ascAngObj:PROG:ANG:MAX:CUR  to Min(current_pitch, _ascAngObj:PROG:ANG:MAX:NEXT).
                            set _ascAngObj:PROG:ANG:MAX:NEXT to _ascAngObj:PROG:ANG:MAX:QUEUE:Pop().
                        }

                        if _ascAngObj:PROG:ANG:MIN:QUEUE:Length > 0
                        {
                            set _ascAngObj:PROG:ANG:MIN:CUR  to _ascAngObj:PROG:ANG:MIN:NEXT.
                            set _ascAngObj:PROG:ANG:MIN:NEXT to _ascAngObj:PROG:ANG:MIN:QUEUE:Pop().
                        }

                        set _ascAngObj:PROG:ANG:DELTACOMBI to Abs(_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MIN:CUR).

                        if _ascAngObj:PROG:AOA:QUEUE:Length > 0 
                        {
                            set _ascAngObj:PROG:AOA:CUR  to _ascAngObj:PROG:AOA:NEXT.
                            set _ascAngObj:PROG:AOA:NEXT to _ascAngObj:PROG:AOA:QUEUE:Pop().
                        }

                        if _ascAngObj:PROG:SPD:QUEUE:Length > 0
                        {
                            set _ascAngObj:PROG:SPD:CUR  to _ascAngObj:PROG:SPD:NEXT.
                            set _ascAngObj:PROG:SPD:NEXT to _ascAngObj:PROG:SPD:QUEUE:Pop().
                        }

                        // if _ascAngObj:PROG:TWR:QUEUE:Length > 0
                        // {
                        //     set _ascAngObj:PROG:TWR:CUR  to _ascAngObj:PROG:TWR:NEXT.
                        //     set _ascAngObj:PROG:TWR:NEXT to _ascAngObj:PROG:TWR:QUEUE:Pop().
                        // }

                        set _ascAngObj:PROG:ANG:DELTAS to list(_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MIN:CUR, (_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MAX:NEXT + _ascAngObj:PROG:ANG:MIN:CUR - _ascAngObj:PROG:ANG:MIN:NEXT) / 2, _ascAngObj:PROG:ANG:MAX:NEXT - _ascAngObj:PROG:ANG:MIN:NEXT).

                        set _ascAngObj:MARK to Time:Seconds.

                        if _ascAngObj:PROG:ALT:QUEUE:Length = 0 or g_RunMode > 405
                        {
                            set g_RunMode to 80.
                        }
                        else
                        {
                            set _ascAngObj:PROG:ALT:LAST  to current_alt.
                            set _ascAngObj:PROG:ALT:CUR  to _ascAngObj:PROG:ALT:NEXT.
                            set _ascAngObj:PROG:ALT:NEXT to _ascAngObj:PROG:ALT:QUEUE:Pop().
                        
                            set g_RunMode to g_RunMode + 5.
                        }

                        set g_RunMode to 100.
                    }
                    else
                    {
                        set err_pit_delta to _ascAngObj:PROG:ANG:DELTACOMBI * apo_error.
                        local wanted_pitch  to ang_limit_max - err_pit_delta.
                        set error_limit   to aoa_limit_min + (aoa_limit_max * (apo_error * fShape)).
                        set output_pitch to Min(prograde_orbit_pitch + error_limit, Max(prograde_orbit_pitch - error_limit, wanted_pitch)).
                    }
                }
                else
                {
                    local apo_PID to g_PIDS[_ascAngObj:APO_PID].

                    if not g_PID_Active
                    {
                        set g_PID_Active to True.
                        
                        set apo_PID:MaxOutput to ang_limit_max.
                        set apo_PID:MinOutput to ang_limit_min.
                    }
                    // else if l_pid_twr_ctrl
                    // {
                    //     if twr_variance > 0.1
                    //     {
                    //         set apo_PID:kP to Round(_ascAngObj:APO_PID_PDEF / twr_factor, 5).
                    //         set apo_PID:kI to Round(_ascAngObj:APO_PID_IDEF / twr_factor, 5).
                    //         set apo_PID:kD to Round(_ascAngObj:APO_PID_DDEF / twr_factor, 5).

                    //         if g_Debug { OutDebug("TWR PID Adjusment Active ({0} | {1})":Format(Round(twr_variance, 2), Round(twr_factor, 2)), 4).}
                    //     }
                    // }

                    GetTermChar().

                    if g_TermChar:Length > 0
                    {
                        if Unchar(g_TermChar) = 112
                        {
                            set apo_PID:kP to Round(apo_PID:kP * 0.94, 5).
                        }
                        else if Unchar(g_TermChar) = 80
                        {
                            set apo_PID:kP to Round(apo_PID:kP * 1.06, 5).
                        }
                        else if Unchar(g_TermChar) = 105
                        {
                            set apo_PID:kI to Round(apo_PID:kI * 0.94, 5).
                        }
                        else if Unchar(g_TermChar) = 73
                        {
                            set apo_PID:kI to Round(apo_PID:kI * 1.06, 5).
                        }
                        else if Unchar(g_TermChar) = 100
                        {
                            set apo_PID:kD to Round(apo_PID:kD * 0.94, 5).
                        }
                        else if Unchar(g_TermChar) = 68
                        {
                            set apo_PID:kD to Round(apo_PID:kD * 1.06, 5).
                        }
                        else if Unchar(g_TermChar) = 85
                        {
                            set _ascAngObj:APO_PID_RESET to True.
                        }
                        // else if Unchar(g_TermChar) = 84 // T
                        // {
                        //     set l_pid_twr_ctrl to true.
                        // }
                        // else if Unchar(g_TermChar) = 116 // t
                        // {
                        //     set l_pid_twr_ctrl to false.
                        // }
                    }
                    set g_TermChar to "".

                    // PID STUFFS
                    if _ascAngObj:APO_PID_RESET
                    {
                        set apo_PID:kP to _ascAngObj:APO_PID_PDEF.
                        set apo_PID:kI to _ascAngObj:APO_PID_IDEF.
                        set apo_PID:kD to _ascAngObj:APO_PID_DDEF.
                        apo_PID:Reset().

                        set _ascAngObj:APO_PID_UPDATE_SETPOINT to True.
                        set _ascAngObj:APO_PID_RESET to False.
                    }

                    if _ascAngObj:APO_PID_UPDATE_SETPOINT
                    {
                        set apo_PID:Setpoint to apo_tgt.
                        set _ascAngObj:APO_PID_UPDATE_SETPOINT to False.
                    }

                    // local pitGuard to list(-6.25, 6.25).
                    local pitGuard to list(aoa_limit_min, aoa_limit_max).
                    local adjPitGuard to pitGuard[1].
                    if Stage:Number >= g_StageLimit
                    {
                        // set pitGuard  to list(2.5, 2.5).
                        // local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR / l_twr_denom.
                        // set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + ((twrFactor / Ship:Mass)))).
                        set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + ((Ship:Thrust / Ship:Mass)))).
                    }

                    local pid_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis). //(apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                    set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
                    set output_pitch to max(PID_Ang_Min, min(effective_pitch, PID_Ang_Max)).
                    // set g_PIDS[_ascAngObj:APO_PID] to apo_PID.
                }

                if ETA:Apoapsis > ETA:Periapsis
                {
                    set output_pitch to max(PID_Ang_Min, min(PID_Ang_Max, output_pitch)).
                }
            }
            else
            {
                if current_alt > trans_alt_next
                {
                    if _ascAngObj:PROG:ALT:QUEUE:Length > 0
                    {
                        set _ascAngObj:PROG:ALT:CUR  to current_alt.
                        set _ascAngObj:PROG:ALT:NEXT to _ascAngObj:PROG:ALT:QUEUE:Pop().
                    }
                    
                    if _ascAngObj:PROG:ANG:MAX:QUEUE:Length > 0
                    {
                        set _ascAngObj:PROG:ANG:MAX:LAST to _ascAngObj:PROG:ANG:MAX:CUR.
                        set _ascAngObj:PROG:ANG:MAX:CUR  to Max(current_pitch, _ascAngObj:PROG:ANG:MAX:NEXT).
                        set _ascAngObj:PROG:ANG:MAX:NEXT to _ascAngObj:PROG:ANG:MAX:QUEUE:Pop().
                        set _ascAngObj:PROG:ANG:MAX:DELTA     to Round(_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MAX:NEXT, 2). // _ascAngObj:PROG:ANG:MAX.
                    }

                    if _ascAngObj:PROG:ANG:MIN:QUEUE:Length > 0
                    {
                        set _ascAngObj:PROG:ANG:MIN:LAST to _ascAngObj:PROG:ANG:MIN:CUR.
                        set _ascAngObj:PROG:ANG:MIN:CUR  to _ascAngObj:PROG:ANG:MIN:NEXT.
                        set _ascAngObj:PROG:ANG:MIN:NEXT to _ascAngObj:PROG:ANG:MIN:QUEUE:Pop().
                        set _ascAngObj:PROG:ANG:MIN:DELTA to Round(_ascAngObj:PROG:ANG:MIN:CUR - _ascAngObj:PROG:ANG:MIN:NEXT, 2). // _ascAngObj:PROG:ANG:MIN.
                    }

                    if _ascAngObj:PROG:AOA:QUEUE:Length > 0 
                    {
                        set _ascAngObj:PROG:AOA:CUR  to _ascAngObj:PROG:AOA:NEXT.
                        set _ascAngObj:PROG:AOA:NEXT to _ascAngObj:PROG:AOA:QUEUE:Pop().
                    }

                    if _ascAngObj:PROG:SPD:QUEUE:Length > 0
                    {
                        set _ascAngObj:PROG:SPD:CUR  to _ascAngObj:PROG:SPD:NEXT.
                        set _ascAngObj:PROG:SPD:NEXT to _ascAngObj:PROG:SPD:QUEUE:Pop().
                    }

                    if _ascAngObj:PROG:TWR:QUEUE:Length > 0
                    {
                        set _ascAngObj:PROG:TWR:CUR  to _ascAngObj:PROG:TWR:NEXT.
                        set _ascAngObj:PROG:TWR:NEXT to _ascAngObj:PROG:TWR:QUEUE:Pop().
                    }

                    set _ascAngObj:PROG:ANG:DELTAS to list(_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MIN:CUR, (_ascAngObj:PROG:ANG:MAX:CUR - _ascAngObj:PROG:ANG:MAX:NEXT + _ascAngObj:PROG:ANG:MIN:CUR - _ascAngObj:PROG:ANG:MIN:NEXT) / 2, _ascAngObj:PROG:ANG:MAX:NEXT - _ascAngObj:PROG:ANG:MIN:NEXT).
                    
                    set _ascAngObj:MARK to Time:Seconds.

                    set g_RunMode to g_RunMode + 5.
                }
            }
        }

        local progAngDiff to choose 0 if _ascAngObj:PROG:ANG:DELTAS:Length = 0 else _ascAngObj:PROG:ANG:DELTAS[0].
        DispAscentAngleStats(list(
            "ASCENT_ANG_STATS",
            "{0,14}: {1,-8}":Format("CUR ALT",       Round(current_alt)),
            "{0,14}: {1,-8}":Format("NEXT ALT",      Round(trans_alt_next)),
            "{0,14}: {1,-8}":Format("CUR ALT ERR",   Round(altitude_error, 3)),
            "{0,14}: {1,-8}":Format("CUR APO ERR",   Round(apo_error, 3)),
            " ",
            "{0,14}: {1,-8}":Format("CUR PIT",       Round(current_pitch, 2)),
            "{0,14}: {1,-8}":Format("TGT PIT",       Round(output_pitch, 2)),
            "{0,14}: {1,-8}":Format("ANG_LIM_MAX",   Round(ang_limit_max, 2)),
            "{0,14}: {1,-8}":Format("ANG_LIM_MIN",   Round(ang_limit_min, 2)),
            "{0,14}: {1,-8}":Format("ANG DIFF",      Round(progAngDiff, 2)),
            " ",
            "{0,14}: {1,-8}":Format("PRO PIT (SRF)", Round(prograde_surface_pitch, 2)),
            "{0,14}: {1,-8}":Format("PRO PIT (OBT)", Round(prograde_orbit_pitch, 2))
            
            // ,"tgt_AltPitAng", Round(tgt_AltPitAng, 3)
            // ,"tgt_ApoPitAng", Round(tgt_ApoPitAng, 3)
            // ,"tgt_PrsPitAng", Round(tgt_PrsPitAng, 3)
            // ,"eff_PitAng", Round(eff_PitAng, 3)
            )
        ).

        return output_pitch.
    }



    // WIP PART TRES WTF
    // #TODO: Examine benefit of moving fshape to limits vs eff pitch (* currently in progress)
    global function GetAscentAng_Flat
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_Next", 0).

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
        local target_apo_thresh to target_apo * 0.925.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.

        // if g_StagingSoon
        // {

        // }
        // else 
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
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)).
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
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Good
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.4)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            // else if current_apo >= target_apo_thresh and ETA:Apoapsis <= ETA:Periapsis
            // {
            //     // PID STUFFS
            //     if _ascAngObj:APO_PID_RESET
            //     {
            //         g_PIDS[_ascAngObj:APO_PID]:Reset().
            //         set _ascAngObj:UPDATE_SETPOINT to True.
            //         set _ascAngObj:APO_PID_RESET to False.
            //     }

            //     if _ascAngObj:UPDATE_SETPOINT
            //     {
            //         set g_PIDS[_ascAngObj:APO_PID]:Setpoint to target_apo.
            //         set _ascAngObj:UPDATE_SETPOINT to False.
            //     }

            //     local pitGuard to list(1.25, 1.25).
            //     local adjPitGuard to pitGuard[0].
            //     if Stage:Number > g_StageLimit
            //     {
            //         set pitGuard  to list(0.25, 0.5).
            //         local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR.
            //         set adjPitGuard to max(pitGuard[0], min(pitGuard[1], pitGuard[0] + ((twrFactor / Ship:Mass)))).
            //     }

            //     local apo_PID to g_PIDS[_ascAngObj:APO_PID].
            //     local pid_pitch to (apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
            //     set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
            //     set output_pitch to max(PID_AoA_Min, min(effective_pitch, PID_AoA_Max)).
            // }
            else
            {
                set output_pitch        to max(min(current_pitch + 0.325, prograde_surface_pitch - 0.5), 5).
            }

            if ETA:Apoapsis > ETA:Periapsis
            {
                set output_pitch to max(-15, min(45, output_pitch)).
            }
        }

        return output_pitch.
    }

    // WIP PART DEUX, electric OH MY GOD STAHP
    // #TODO: Examine benefit of moving fshape to limits vs eff pitch (* currently in progress)
    global function GetAscentAng_Next
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_Next", 0).

        local fShape            to _ascAngObj:FSHAPE.
        local altitude_error    to 0.
        local apo_error         to 0.
        local apo_turn_error    to 0.
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local current_pitch     to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).
        local effective_error   to 0.
        local effective_limit   to 0.
        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to current_pitch.

        local current_ap_alt    to ((Ship:Altitude * 1.275) + (Ship:Apoapsis * 1.225)) / 2.5.
        // local current_ap_alt    to ((Ship:Altitude * 1.3) + (Ship:Apoapsis * 1.2)) / 2.5.
        // local current_ap_alt    to ((Ship:Altitude * 1.15) + (Ship:Apoapsis * 1.25)) / 2.5.
        
        local prograde_pitch            to 90.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local target_apo_turn   to _ascAngObj:TRN_APO_TGT.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.

        // if g_StagingSoon
        // {

        // }
        // else 
        if g_SpinActive 
        {
            set output_pitch to current_pitch.
            // set pitch_limit_max to max(pitch_limit_min, pitch_limit_max * 0.28).
        }
        else if current_alt > turn_alt_start
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.
            set apo_turn_error      to current_apo / target_apo_turn.            

            // if current_alt < 2000 and Ship:VerticalSpeed > 0
            if current_alt < partCAlt and Ship:VerticalSpeed > 0
            {
                local alt_err_nrm       to altitude_error * (1 - (0.5 * altitude_error)).
                set error_pitch         to 90 * (1 - alt_err_nrm).
                set error_limit         to 0.125 + (pitch_limit_max * altitude_error).
                // set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.005625)).
                set effective_limit     to min(pitch_limit_max, max(error_limit, pitch_limit_min)). // min(pitch_limit_max, max(pitch_limit_min, error_limit)). //  max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max)).
                set prograde_pitch      to prograde_surface_pitch. // (prograde_surface_pitch * min(1, (1.0125 - altitude_error))) + (prograde_orbit_pitch * altitude_error). 
                set effective_pitch     to min(prograde_pitch + effective_limit, max(error_pitch, prograde_pitch - effective_limit)). 

                set output_pitch        to min(90, max(effective_pitch, 0)).

                // OutInfo("pitch_limit_min|max: [{0}|{1}] | error_limit: [{2}]":Format(Round(pitch_limit_min, 5), Round(pitch_limit_max, 5), Round(error_limit, 5)), 2).
                // OutInfo("Part B | Error: Apo:[{0}]|Alt:[{1}] ":Format(Round(apo_error, 3), Round(altitude_error, 3)), 2).
                local ascentAngData to list(
                    "ASCENT ANGLE"
                    ,"Part: B" + "  "
                    ,"Prograde Pitch : " + Round(prograde_pitch, 5) + "  "
                    ,"Error Pitch    : " + Round(error_pitch, 5) + "  "
                    ,"Effective Pitch: " + Round(effective_pitch, 5) + "  "
                    ,"Output Pitch   : " + Round(output_pitch, 5) + "  "
                    ,""
                    ,"Error Limit    : " + Round(error_limit, 2) + "  "
                    ,"Effective Limit: " + Round(effective_limit, 2) + "  "
                    ,""
                    ,"Error (Alt    ): " + Round(altitude_error, 5) + "  "
                    ,"Error (AltNorm): " + Round(altitude_error, 5) + "  "
                ).
                DispAscentAngleStats(ascentAngData).

                set _ascAngObj["PartCPitchLimit"] to current_pitch.
                set _ascAngObj["PartCAltStart"] to current_alt.
            }
            else if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                if not _ascAngObj:HasKey("PartCPitchLimit")
                {
                    set _ascAngObj["PartCPitchLimit"] to current_pitch.
                }
                // OutInfo("pitch_limit_min|max: [{0}|{1}]":Format(Round(pitch_limit_min, 5), Round(pitch_limit_max, 5)), 2).
                // local alt_error_blended to altitude_error * (1 - altitude_error).

                local alt_err_norm      to altitude_error * (1 - (0.625 * altitude_error)).

                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).

                local apo_error_blended to apo_error * blend_apo_error.
                // local comb_err          to alt_error_blended + apo_error_blended.
                local comb_err          to min(1, alt_err_norm + apo_error_blended).

                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to 1.250 + (pitch_limit_max * comb_err).
                // set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.275)). // 1.25)). // 1.03125)).
                set effective_limit     to min(pitch_limit_max, max(error_limit, pitch_limit_min)). // min(pitch_limit_max, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                
                // set prograde_pitch      to min(90, max((prograde_surface_pitch * (1 - altitude_error)) + (prograde_orbit_pitch * altitude_error), -15)). 
                local prograde_error    to min(1, max(0, (current_alt - _ascAngObj["PartCAltStart"]) / ascent_Next_Alt_Width )).
                set prograde_pitch      to (prograde_surface_pitch * (1 - prograde_error)) + (prograde_orbit_pitch * prograde_error).

                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).

                set output_pitch        to min(_ascAngObj["PartCPitchLimit"], max(0, effective_pitch)).
                // OutInfo("Part C | Error: Apo:[{0}]|Alt:[{1}]|Blend:[{2}]|Comb:[{3}] ":Format(Round(apo_error, 3), Round(altitude_error, 3), Round(blend_apo_error, 3), Round(comb_err, 3)), 2).

                local ascentAngData to list(
                    "ASCENT ANGLE"
                    ,"Part         : C    "
                    ,"Tgt [Alt|Apo]: {0} | {1}  ":Format(Round(turn_alt_blend), Round(target_apo))
                    ,"Prograde Pitch : " + Round(prograde_pitch, 5) + "  "
                    ,"Error Pitch    : " + Round(error_pitch, 5) + "  "
                    ,"Effective Pitch: " + Round(effective_pitch, 5) + "  "
                    ,"Output Pitch   : " + Round(output_pitch, 5) + "  "
                    ,""
                    ,"Error Limit    : " + Round(error_limit, 2) + "  "
                    ,"Effective Limit: " + Round(effective_limit, 2) + "  "
                    ,""
                    ,"Error (Alt    ): " + Round(altitude_error, 5) + "  "
                    ,"Error (AltNorm): " + Round(altitude_error, 5) + "  "
                    ,"Error (Apo    ): " + Round(apo_error, 5) + "  "
                    ,"Error (Blend  ): " + Round(blend_apo_error, 5) + "  "
                    ,"Error (ApoBlnd): " + Round(apo_error_blended, 5) + "  "
                    ,"Error (Combine): " + Round(comb_err, 5) + "  "
                ).
                DispAscentAngleStats(ascentAngData).

                set _ascAngObj["PartDPitchLimit"] to current_pitch.
            }
            else if current_ap_alt < turn_alt_end and Ship:VerticalSpeed > 0
            {
                if not _ascAngObj:HasKey("PartDPitchLimit")
                {
                    set _ascAngObj["PartDPitchLimit"] to current_pitch.
                }
                local alt_err_norm to altitude_error * (1 - (0.50 * altitude_error)).
                
                local blend_apo_error   to (current_apo - turn_alt_end) / (target_apo - turn_alt_end).
                // local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to (apo_error * blend_apo_error).
                // local apo_error_blended to (apo_error * blend_apo_error) / 2.
                // local comb_err          to (altitude_error + apo_error_blended).
                local comb_err          to min(1, alt_err_norm + apo_error_blended).

                set error_pitch         to 90 * (1 - comb_err).

                // set error_limit         to 1.25 + (pitch_limit_max * comb_err).
                set error_limit         to 2.5 + pitch_limit_max * min(1, max(0, comb_err)).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.325)). // 1.275)). // 1.0625)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Good
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max)).

                local prograde_error    to min(1, max(0, (current_alt - _ascAngObj["PartCAltStart"]) / ascent_Next_Alt_Width )).
                set prograde_pitch      to (prograde_surface_pitch * (1 - prograde_error)) + (prograde_orbit_pitch * prograde_error).
                // set prograde_pitch      to (prograde_surface_pitch * (1 - comb_err)) + (prograde_orbit_pitch * comb_err). 

                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                // set output_pitch        to min(90, max(-effective_limit, min(effective_pitch, _ascAngObj["PartDPitchLimit"])).
                set output_pitch        to min(_ascAngObj["PartDPitchLimit"], max(effective_pitch, PID_Ang_Min)).

                set _ascAngObj["PartEPitchLimit"] to current_pitch.
                // OutInfo("Part D | Error: Apo:[{0}]|Alt:[{1}]|Blend:[{2}]|Comb:[{3}] ":Format(Round(apo_error, 3), Round(altitude_error, 3), Round(blend_apo_error, 3), Round(comb_err, 3)), 2).

                local ascentAngData to list(
                    "ASCENT ANGLE"
                    ,"Part: D  "
                    ,"Tgt [Alt|Apo]: {0} | {1}  ":Format(Round(turn_alt_end), Round(target_apo))
                    ,"Prograde Pitch : " + Round(prograde_pitch, 5) + "  "
                    ,"Error Pitch    : " + Round(error_pitch, 5) + "  "
                    ,"Effective Pitch: " + Round(effective_pitch, 5) + "  "
                    ,"Output Pitch   : " + Round(output_pitch, 5) + "  "
                    ,""
                    ,"Error Limit    : " + Round(error_limit, 2) + "  "
                    ,"Effective Limit: " + Round(effective_limit, 2) + "  "
                    ,""
                    ,"Error (Alt    ): " + Round(altitude_error, 5) + "  "
                    ,"Error (AltNorm): " + Round(altitude_error, 5) + "  "
                    ,"Error (Apo    ): " + Round(apo_error, 5) + "  "
                    ,"Error (Blend  ): " + Round(blend_apo_error, 5) + "  "
                    ,"Error (ApoBlnd): " + Round(apo_error_blended, 5) + "  "
                    ,"Error (Combine): " + Round(comb_err, 5) + "  "
                ).
                DispAscentAngleStats(ascentAngData).
            }
            else if current_ap_alt < target_apo_turn and Ship:VerticalSpeed > 0
            {
                if not _ascAngObj:HasKey("PartEPitchLimit")
                {
                    set _ascAngObj["PartEPitchLimit"] to current_pitch.
                }
                // local apo_turn_norm to min(1, max(0, apo_turn_error)). //  altitude_error * (1 - (0.50 * altitude_error)).
                
                // local blend_apo_error   to (current_apo - turn_alt_end) / (target_apo - turn_alt_end).
                // local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                // local apo_error_blended to (apo_error * blend_apo_error).
                local apo_error_blended to (apo_turn_error * (1 - apo_turn_error)) + (apo_error * apo_turn_error).
                // local apo_error_blended to (apo_error * blend_apo_error) / 2.
                // local comb_err          to (altitude_error + apo_error_blended).
                local comb_err          to apo_error_blended.
                
                local blend_apo_error   to current_apo / target_apo_turn.
                                
                set error_pitch         to 90 * (1 - comb_err).

                set error_limit         to pitch_limit_max * min(1, max(0, comb_err)).

                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max)).
                
                local prograde_error    to min(1, max(0, (current_alt - _ascAngObj["PartCAltStart"]) / ascent_Next_Alt_Width )).
                set prograde_pitch      to (prograde_surface_pitch * (1 - prograde_error)) + (prograde_orbit_pitch * prograde_error).

                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 

                set output_pitch        to min(_ascAngObj["PartEPitchLimit"], max(effective_pitch, PID_Ang_Min)).

                set _ascAngObj["PartFPitchLimit"] to current_pitch.

                local ascentAngData to list(
                    "ASCENT ANGLE"
                    ,"Part: E  "
                    ,"Tgt [Trn|Apo]: {0} | {1}  ":Format(Round(target_apo_turn), Round(target_apo))
                    ,"Prograde Pitch : " + Round(prograde_pitch, 5) + "  "
                    ,"Error Pitch    : " + Round(error_pitch, 5) + "  "
                    ,"Effective Pitch: " + Round(effective_pitch, 5) + "  "
                    ,"Output Pitch   : " + Round(output_pitch, 5) + "  "
                    ,""
                    ,"Error Limit    : " + Round(error_limit, 2) + "  "
                    ,"Effective Limit: " + Round(effective_limit, 2) + "  "
                    ,""
                    ,"Error (Alt    ): " + Round(altitude_error, 5) + "  "
                    ,"Error (AltNorm): " + Round(altitude_error, 5) + "  "
                    ,"Error (Apo    ): " + Round(apo_error, 5) + "  "
                    ,"Error (Blend  ): " + Round(blend_apo_error, 5) + "  "
                    ,"Error (ApoBlnd): " + Round(apo_error_blended, 5) + "  "
                    ,"Error (Combine): " + Round(comb_err, 5) + "  "
                ).
                DispAscentAngleStats(ascentAngData).
            }
            else
            {
                set error_pitch         to 90 * (1 - apo_error).

                set error_limit         to pitch_limit_max * apo_error.
                set effective_limit     to min(pitch_limit_max, max(error_limit, pitch_limit_min)).

                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). *** Good  // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error) / apo_error)). 

                local prograde_error    to min(1, max(0, (current_alt - _ascAngObj["PartCAltStart"]) / ascent_Next_Alt_Width )).
                set prograde_pitch      to (prograde_surface_pitch * (1 - prograde_error)) + (prograde_orbit_pitch * prograde_error).

                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch      to min(_ascAngObj["PartFPitchLimit"], max(effective_pitch, PID_Ang_Min)).
                // set output_pitch        to min(_ascAngObj["PartEPitchLimit"], max(effective_pitch * fShape, PID_Ang_Min)).
                // OutInfo("Part E | Error: Apo:[{0}] ":Format(Round(apo_error, 3)), 2).
                local ascentAngData to list(
                    "ASCENT ANGLE"
                    ,"Part     : F   "
                    ,"Tgt [Apo]: {0}      ":Format(Round(target_apo))
                    ,"Prograde Pitch : " + Round(prograde_pitch, 5) + "  "
                    ,"Error Pitch    : " + Round(error_pitch, 5) + "  "
                    ,"Effective Pitch: " + Round(effective_pitch, 5) + "  "
                    ,"Output Pitch   : " + Round(output_pitch, 5) + "  "
                    ,""
                    ,"Error Limit    : " + Round(error_limit, 2) + "  "
                    ,"Effective Limit: " + Round(effective_limit, 2) + "  "
                    ,""
                    ,"Error (Apo    ): " + Round(apo_error, 5) + "  "
                    ,""
                    ,""
                    ,""
                    ,""
                    ,""
                ).
                DispAscentAngleStats(ascentAngData).
            }
            
            if ETA:Apoapsis > ETA:Periapsis
            {
                set output_pitch to max(PID_Ang_Min, min(22.5, output_pitch)).
            }
        }
        else
        {
            // OutInfo("Part A", 2).
            local ascentAngData to list(
                "ASCENT ANGLE"
                ,"Part: A" + "  "
                ,"Output Pitch   : " + Round(output_pitch, 5) + "  "
            ).
            DispAscentAngleStats(ascentAngData).
        }

        return output_pitch.
    }

    // WIP PART FUCK IF I KNOW
    // GetAscentAng_ByApoETA
    // Will attempt to return a pitch angle that can maintain a provided ETA to apoapsis
    global function GetAscentAng_ByApoETA
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_ByApoETA", 0).

        local fShape            to _ascAngObj:FSHAPE.
        
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local current_pitch     to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).

        local altitude_error    to 0.
        local apo_error         to 0.
        local effective_error   to 0.
        local effective_limit   to 0.
        local effective_pitch   to 90.
        local error_limit       to 0.
        local error_pitch       to 0.
        local output_pitch      to current_pitch.

        local current_ap_alt    to ((Ship:Altitude * 1.15) + (Ship:Apoapsis * 1.25)) / 2.5.
        
        local prograde_pitch            to 90.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local target_apo_eta    to _ascAngObj:APO_ETA_TGT.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.

        if g_SpinActive 
        {
            set output_pitch to current_pitch.
        }
        else if current_alt > turn_alt_start
        {
            set altitude_error  to current_alt / turn_alt_end.
            set apo_error       to current_apo / target_apo.
            set apo_eta         to ETA:Apoapsis.

            if current_alt < 1750 and Ship:VerticalSpeed > 0
            {
                OutInfo("Part B1", 2).

                

                // local blend_alt_error   to (current_alt - turn_alt_start) / (turn_alt_blend - turn_alt_start).
                // local alt_error_blended to altitude_error * (1 - blend_alt_error).
                // local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                // local apo_error_blended to apo_error * blend_apo_error.
                // local comb_err          to alt_error_blended + apo_error_blended.
                // set effective_error     to comb_err.
                // set error_pitch         to 90 * (1 - comb_err).
                // set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                // // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.05625)). // * 1.125)).// 1.015625)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.05625)).
                // set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                // set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // // * set output_pitch        to max(45, min(effective_pitch * fShape, 90)).
                // set output_pitch        to max(45, min(effective_pitch, 90)).
            }
            else if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                OutInfo("Part C2", 2).
                local blend_alt_error   to current_alt / turn_alt_end.
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.

                set effective_error     to comb_err.
                // set error_pitch         to 90 * (1 - effective_error).
                set error_pitch         to 90 * (1 - effective_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                // set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.275)). // 1.25)). // 1.03125)).
                set effective_limit     to min(pitch_limit_max * 1.075, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.125)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                set output_pitch        to min(90, max(0, effective_pitch)).
                // set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else if current_ap_alt < turn_alt_end and Ship:VerticalSpeed > 0
            {
                OutInfo("Part D3", 2).
                local blend_alt_error   to current_alt  / turn_alt_end.
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.

                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.325)). // 1.275)). // 1.0625)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Good
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else
            {
                OutInfo("Part E4", 2).
                set error_pitch         to 90 * (1 - apo_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). *** Good  // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.1125) / apo_error)). 
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            
            if ETA:Apoapsis > ETA:Periapsis
            {
                set output_pitch to max(-15, min(45, output_pitch)).
            }
        }
        else
        {
            OutInfo("Part A0", 2).
        }

        return output_pitch.
    }

    // WIP PART DEUX, electric OH MY GOD STAHP
    // #TODO: Examine benefit of moving fshape to limits vs eff pitch (* currently in progress)
    global function GetAscentAng_Next_PID
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_Next_PIDdy", 0).

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
        local output_pitch      to current_pitch.

        // local current_ap_alt    to ((Ship:Altitude * 1.0625) + (Ship:Apoapsis * 1.325)) / 2.5.
        
        local prograde_pitch            to 90.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local target_apo_thresh to _ascAngObj:APO_TGT_THRESH.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.

        local pit_ang_max_limit to _ascAngObj:PIT_ANG_LIM_MAX.
        local pit_ang_min_limit to _ascAngObj:PIT_ANG_LIM_MIN.

        local trans_alt_next   to _ascAngObj:TRANS_ALT_NEXT.
        // local trans_alt_actual to _ascAngObj:TRANS_ALT_ACTUAL.
        
        local last_context to g_Context.
        set g_Context to ("1" + g_Context:ToString):ToNumber(g_Context).
        
        OutInfo("[{0}]P{1}:R{2}  ":Format(g_Context, g_Program, g_RunMode), 2).

        if g_SpinActive
        {
            set output_pitch to current_pitch.
        }

        else if g_RunMode > 5
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if g_RunMode = 10
            {
                if current_alt > trans_alt_next and Ship:VerticalSpeed > 0
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    set _ascAngObj:TRANS_ALT_NEXT   to turn_alt_blend.

                    if _ascAngObj:PIT_ANG_LIM_MAX_SET:Length > 1
                    {

                    }
                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(Ascent_AoA_Max, current_pitch).

                    set g_RunMode to 15.
                }
                else
                {
                    local blend_alt_error   to (current_alt - turn_alt_start) / (turn_alt_blend - turn_alt_start).
                    local alt_error_blended to altitude_error * (1 - blend_alt_error).
                    local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                    local apo_error_blended to apo_error * blend_apo_error.
                    local comb_err          to alt_error_blended + apo_error_blended.

                    set effective_error     to comb_err.
                    set error_pitch         to 90 * (1 - comb_err).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                    set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.05625)).
                    set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                    set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).
                }
            }
            else if g_RunMode = 15
            {

                if current_alt > trans_alt_next and Ship:VerticalSpeed > 0
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    set _ascAngObj:TRANS_ALT_NEXT   to current_alt + ascent_Next_Alt_Width.

                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(Ascent_AoA_Max, current_pitch).

                    set g_RunMode to 20.
                }
                else
                {
                    local blend_alt_error   to Min(1, Max(0, current_alt / turn_alt_end)).
                    local alt_error_blended to altitude_error * (1 - blend_alt_error).
                    local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                    local apo_error_blended to apo_error * blend_apo_error.
                    local comb_err          to alt_error_blended + apo_error_blended.

                    set effective_error     to comb_err.
                    set error_pitch         to 90 * (1 - effective_error).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                    set effective_limit     to min(pitch_limit_max * 1.0875, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                    set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                    set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).
                }
            }
            else if g_RunMode = 20
            {
                if current_alt > trans_alt_next and Ship:VerticalSpeed > 0
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    set _ascAngObj:TRANS_ALT_NEXT   to target_apo_thresh.

                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(PID_Ang_Max, current_pitch).

                    set g_RunMode to 25.
                }
                else
                {
                    local blend_error   to Min(1, Max(0, current_alt/ trans_alt_next)).
                    local alt_error_blended to altitude_error * (1 - blend_error).
                    // local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                    local apo_error_blended to apo_error * blend_error.
                    local comb_err          to alt_error_blended + apo_error_blended.

                    set effective_error     to comb_err.
                    set error_pitch         to 90 * (1 - effective_error).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                    set effective_limit     to min(pitch_limit_max * 1.0875, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                    set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                    set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).

                    // local blend_multi to Min(1, (current_alt - trans_alt_actual) / (trans_alt_next - trans_alt_actual)).
                    // local alt_blend_error to altitude_error * blend_multi.
                    // local apo_blend_error to apo_error * (1 - blend_multi).
                    // local comb_err          to alt_blend_error + apo_blend_error.

                    // set effective_error     to comb_err.
                    // set error_pitch         to 90 * (1 - effective_error).
                    // set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                    // set effective_limit     to min(pitch_limit_max * 1.0875, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                    // set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    // set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                    // set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).
                }
                // else
                // {
                //     local blend_alt_error   to Min(1, Max(0, current_alt / turn_alt_end)). // current_alt / turn_alt_end.
                //     local alt_error_blended to altitude_error * (1 - blend_alt_error).
                //     local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                //     local apo_error_blended to apo_error * blend_apo_error.
                //     local comb_err          to alt_error_blended + apo_error_blended.
                //     // local comb_err   to current_apo / target_apo.

                //     set effective_error     to comb_err.
                //     set error_pitch         to 90 * (1 - effective_error).
                //     set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                //     set effective_limit     to min(pitch_limit_max * 1.125, max(pitch_limit_min, error_limit * fShape)).  // )  max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max)).
                //     set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                //     set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                //     set output_pitch        to min(effective_limit, max(effective_pitch, -effective_limit)).
                // }
            }
            else if g_RunMode = 25
            {
                if current_apo > trans_alt_next
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    
                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(PID_Ang_Max, current_pitch).

                    set g_RunMode to 30.
                }
                else
                {
                    set error_pitch         to 90 * (1 - apo_error).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                    set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.125) / apo_error)). 
                    set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                    set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
                }
            }
            else if g_RunMode = 30
            {
                set g_PID_Enabled to True.
                local apo_PID to g_PIDS[_ascAngObj:APO_PID].
                if not g_PID_Active 
                {
                    set g_PID_Active to True.
                    
                    set _ascAngObj:PIT_LIM_MAX to PID_AoA_Max.
                    set pitch_limit_max to PID_AoA_Max.
                    set _ascAngObj:PIT_LIM_MIN to PID_AoA_Min.
                    set pitch_limit_min to PID_AoA_Min.

                    set apo_PID:MaxOutput to _ascAngObj:PIT_ANG_LIM_MAX.
                    set apo_PID:MinOutput to PID_Ang_Min.
                }
                else if l_pid_twr_ctrl
                {
                    local current_twr to choose 0.00001 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR.

                    if _ascAngObj:TWR_SMPL
                    {
                        set _ascAngObj:TWR_LAST to _ascAngObj:TWR_CUR.
                        set _ascAngObj:TWR_CUR  to current_twr.
                        set _ascAngObj:TWR_SMPL to false.
                    }
                    else
                    {
                        local last_twr to _ascAngObj:TWR_LAST.
                        local twr_variance to (current_twr / last_twr) - 1.

                        if Abs(twr_variance) > 0.22
                        {
                            local twrFactor to Min(2.5, Max(0.5, current_twr / l_twr_denom)).
                            local _p to Round(_ascAngObj:APO_PID_PDEF / twrFactor, 5).
                            local _i to Round(_ascAngObj:APO_PID_IDEF / twrFactor, 5).
                            local _d to Round(_ascAngObj:APO_PID_DDEF / twrFactor, 5).

                            set apo_PID:kP to _p.
                            set apo_PID:kI to _i.
                            set apo_PID:kD to _d.

                            if g_Debug { OutDebug("TWR PID Adjusment Active ({0} | {1})":Format(Round(twr_variance, 2), Round(twrFactor, 2)), 4).}

                            set _ascAngObj:TWR_SMPL to true.
                        }
                    }
                }

                GetTermChar().

                if g_TermChar:Length > 0
                {
                    if Unchar(g_TermChar) = 112
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 0.94, 5).
                    }
                    else if Unchar(g_TermChar) = 80
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 1.06, 5).
                    }
                    else if Unchar(g_TermChar) = 105
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 0.94, 5).
                    }
                    else if Unchar(g_TermChar) = 73
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 1.06, 5).
                    }
                    else if Unchar(g_TermChar) = 100
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 0.94, 5).
                    }
                    else if Unchar(g_TermChar) = 68
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 1.06, 5).
                    }
                    else if Unchar(g_TermChar) = 85
                    {
                        set _ascAngObj:APO_PID_RESET to True.
                    }
                    else if Unchar(g_TermChar) = 84 // T
                    {
                        set l_pid_twr_ctrl to true.
                    }
                    else if Unchar(g_TermChar) = 116 // t
                    {
                        set l_pid_twr_ctrl to false.
                    }
                }
                set g_TermChar to "".

                // PID STUFFS
                if _ascAngObj:APO_PID_RESET
                {
                    set apo_PID:kP to _ascAngObj:APO_PID_PDEF.
                    set apo_PID:kI to _ascAngObj:APO_PID_IDEF.
                    set apo_PID:kD to _ascAngObj:APO_PID_DDEF.
                    apo_PID:Reset().

                    set _ascAngObj:APO_PID_UPDATE_SETPOINT to True.
                    set _ascAngObj:APO_PID_RESET to False.
                }

                if _ascAngObj:APO_PID_UPDATE_SETPOINT
                {
                    set apo_PID:Setpoint to target_apo.
                    set _ascAngObj:APO_PID_UPDATE_SETPOINT to False.
                }

                // local pitGuard to list(-6.25, 6.25).
                local pitGuard to list(pitch_limit_min, pitch_limit_max).
                local adjPitGuard to pitGuard[1].
                if Stage:Number >= g_StageLimit
                {
                    // set pitGuard  to list(2.5, 2.5).
                    local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR / l_twr_denom.
                    set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + ((twrFactor / Ship:Mass)))).
                }

                local pid_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis). //(apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
                set output_pitch to max(PID_Ang_Min, min(effective_pitch, PID_Ang_Max)).
                // set g_PIDS[_ascAngObj:APO_PID] to apo_PID.
            }
            
            if ETA:Apoapsis > ETA:Periapsis
            {
                set output_pitch to max(PID_Ang_Min, min(PID_Ang_Max, output_pitch)).
            }
        }
        else
        {
            if current_alt > turn_alt_start
            {
                set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.

                set _ascAngObj:PIT_ANG_LIM_MAX to Max(90, current_pitch).

                set _ascAngObj:TRANS_ALT_NEXT to ascent_Prog_Pitch_Alt_Start.

                set g_RunMode to 10.
            }
        }

        set g_Context to last_context.
        return output_pitch.
    }

    // WIP PART WTFFFFF, electric OH MY GOD STAHP
    // #TODO: Examine benefit of moving fshape to limits vs eff pitch (* currently in progress)
    global function GetAscentAng_Next_PID_2
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_Next_PIDdy2", 0).

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
        local output_pitch      to current_pitch.

        local current_ap_alt    to ((Ship:Altitude * 1.0625) + (Ship:Apoapsis * 1.325)) / 2.5.
        
        local prograde_pitch            to 90.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local target_apo_thresh to _ascAngObj:APO_TGT_THRESH.
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.

        local pit_ang_max_limit to _ascAngObj:PIT_ANG_LIM_MAX.
        local pit_ang_min_limit to _ascAngObj:PIT_ANG_LIM_MIN.

        local trans_alt_next   to _ascAngObj:TRANS_ALT_NEXT.
        local trans_alt_actual to _ascAngObj:TRANS_ALT_ACTUAL.
        local trans_alt_window to _ascAngObj:TRANS_ALT_WINDOW.

        local trans_pit_actual to _ascAngObj:TRANS_PIT_ACTUAL.
        local trans_pit_next   to _ascAngObj:TRANS_PIT_NEXT.
        
        local last_context to g_Context.
        set g_Context to ("1" + g_Context:ToString):ToNumber(g_Context).
        
        OutInfo("[{0}]P{1}:R{2}  ":Format(g_Context, g_Program, g_RunMode), 2).

        if g_SpinActive
        {
            set output_pitch to current_pitch.
        }

        else if g_RunMode > 5
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if g_RunMode = 10
            {
                if current_alt > trans_alt_next and Ship:VerticalSpeed > 0
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.

                    set _ascAngObj:TRANS_ALT_NEXT   to turn_alt_blend.

                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(Ascent_AoA_Max, current_pitch).
                    
                    set g_RunMode to 15.
                }
                else
                {
                    local blend_alt_error   to (current_alt - turn_alt_start) / (turn_alt_blend - turn_alt_start).
                    local alt_error_blended to altitude_error * (1 - blend_alt_error).
                    local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                    local apo_error_blended to apo_error * blend_apo_error.
                    local comb_err          to alt_error_blended + apo_error_blended.

                    set effective_error     to comb_err.
                    set error_pitch         to 90 * (1 - comb_err).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                    set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.05625)).
                    set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                    set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).
                }
            }
            else if g_RunMode = 15
            {

                if current_alt > trans_alt_next and Ship:VerticalSpeed > 0
                {
                    set _ascAngObj:PIT_ANG_LIM_MAX  to Max(Ascent_AoA_Max, current_pitch).
                    set _ascAngObj:PIT_ANG_LIM_MIN  to Ascent_Blend_Ang_Out.
                    
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    set _ascAngObj:TRANS_ALT_NEXT   to current_alt + ascent_Next_Alt_Width.

                    set _ascAngObj:TRANS_ALT_WINDOW to ascent_Next_Alt_Width.
                    
                    set g_RunMode to 20.
                }
                else
                {
                    local blend_alt_error   to Min(1, Max(0, current_alt / trans_alt_next)).
                    local alt_error_blended to altitude_error * (1 - blend_alt_error).
                    local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                    local apo_error_blended to apo_error * blend_apo_error.
                    local comb_err          to alt_error_blended + apo_error_blended.

                    set effective_error     to comb_err.
                    set error_pitch         to 90 * (1 - effective_error).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                    set effective_limit     to min(pitch_limit_max * 1.0875, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                    set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                    set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).
                }
            }
            else if g_RunMode = 20
            {
                if current_alt > trans_alt_next and Ship:VerticalSpeed > 0
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    set _ascAngObj:TRANS_ALT_NEXT   to target_apo_thresh.

                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(PID_Ang_Max, current_pitch).
                    

                    set g_RunMode to 25.
                }
                else
                {
                    local adj_alt_err to (current_alt - trans_alt_actual) / trans_alt_window.

                    set error_pitch   to (trans_pit_actual - trans_pit_next) * (1 - adj_alt_err).
                    set error_limit   to pitch_limit_min + (pitch_limit_max * altitude_error).
                    set effective_limit to Min(pitch_limit_max, Max(pitch_limit_min, error_limit * fShape)).
                    set prograde_pitch  to (prograde_surface_pitch * (1 - adj_alt_err)) + (prograde_orbit_pitch * adj_alt_err).
                    set effective_pitch to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).

                    set output_pitch    to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).

                
                    // local blend_multi to Min(1, (current_alt - trans_alt_actual) / (trans_alt_next - trans_alt_actual)).
                    // local alt_blend_error to altitude_error * blend_multi.
                    // local apo_blend_error to apo_error * (1 - blend_multi).
                    // local comb_err          to alt_blend_error + apo_blend_error.

                    // set effective_error     to comb_err.
                    // set error_pitch         to 90 * (1 - effective_error).
                    // set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                    // set effective_limit     to min(pitch_limit_max * 1.0875, max(pitch_limit_min, error_limit * fShape)).// max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                    // set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                    // set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)).
                    // set output_pitch        to min(pit_ang_max_limit, max(pit_ang_min_limit, effective_pitch)).
                }
                // else
                // {
                //     local blend_alt_error   to Min(1, Max(0, current_alt / turn_alt_end)). // current_alt / turn_alt_end.
                //     local alt_error_blended to altitude_error * (1 - blend_alt_error).
                //     local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                //     local apo_error_blended to apo_error * blend_apo_error.
                //     local comb_err          to alt_error_blended + apo_error_blended.
                //     // local comb_err   to current_apo / target_apo.

                //     set effective_error     to comb_err.
                //     set error_pitch         to 90 * (1 - effective_error).
                //     set error_limit         to pitch_limit_min + (pitch_limit_max * effective_error).
                //     set effective_limit     to min(pitch_limit_max * 1.125, max(pitch_limit_min, error_limit * fShape)).  // )  max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max)).
                //     set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                //     set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                //     set output_pitch        to min(effective_limit, max(effective_pitch, -effective_limit)).
                // }
            }
            else if g_RunMode = 25
            {
                if current_apo > trans_alt_next
                {
                    set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                    set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.
                    
                    set _ascAngObj:PIT_ANG_LIM_MAX to Max(PID_Ang_Max, current_pitch).

                    set g_RunMode to 30.
                }
                else
                {
                    set error_pitch         to 90 * (1 - apo_error).
                    set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                    set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.125) / apo_error)). 
                    set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                    set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
                }
            }
            else if g_RunMode = 30
            {
                set g_PID_Enabled to True.
                local apo_PID to g_PIDS[_ascAngObj:APO_PID].
                if not g_PID_Active 
                {
                    set g_PID_Active to True.
                    
                    set _ascAngObj:PIT_LIM_MAX to PID_AoA_Max.
                    set pitch_limit_max to PID_AoA_Max.
                    set _ascAngObj:PIT_LIM_MIN to PID_AoA_Min.
                    set pitch_limit_min to PID_AoA_Min.

                    set apo_PID:MaxOutput to _ascAngObj:PIT_ANG_LIM_MAX.
                    set apo_PID:MinOutput to PID_Ang_Min.
                }
                else if l_pid_twr_ctrl
                {
                    local current_twr to choose 0.00001 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR.

                    if _ascAngObj:TWR_SMPL
                    {
                        set _ascAngObj:TWR_LAST to _ascAngObj:TWR_CUR.
                        set _ascAngObj:TWR_CUR  to current_twr.
                        set _ascAngObj:TWR_SMPL to false.
                    }
                    else
                    {
                        local last_twr to _ascAngObj:TWR_LAST.
                        local twr_variance to (current_twr / last_twr) - 1.

                        if Abs(twr_variance) > 0.22
                        {
                            local twrFactor to Min(5, Max(1, current_twr / l_twr_denom)).
                            local _p to Round(_ascAngObj:APO_PID_PDEF / twrFactor, 5).
                            local _i to Round(_ascAngObj:APO_PID_IDEF / twrFactor, 5).
                            local _d to Round(_ascAngObj:APO_PID_DDEF / twrFactor, 5).

                            set apo_PID:kP to _p.
                            set apo_PID:kI to _i.
                            set apo_PID:kD to _d.

                            if g_Debug { OutDebug("TWR PID Adjusment Active ({0} | {1})":Format(Round(twr_variance, 2), Round(twrFactor, 2)), 4).}

                            set _ascAngObj:TWR_SMPL to true.
                        }
                    }
                }

                GetTermChar().

                if g_TermChar:Length > 0
                {
                    if Unchar(g_TermChar) = 112
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 0.94, 5).
                    }
                    else if Unchar(g_TermChar) = 80
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 1.06, 5).
                    }
                    else if Unchar(g_TermChar) = 105
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 0.94, 5).
                    }
                    else if Unchar(g_TermChar) = 73
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 1.06, 5).
                    }
                    else if Unchar(g_TermChar) = 100
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 0.94, 5).
                    }
                    else if Unchar(g_TermChar) = 68
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 1.06, 5).
                    }
                    else if Unchar(g_TermChar) = 85
                    {
                        set _ascAngObj:APO_PID_RESET to True.
                    }
                    else if Unchar(g_TermChar) = 84 // T
                    {
                        set l_pid_twr_ctrl to true.
                    }
                    else if Unchar(g_TermChar) = 116 // t
                    {
                        set l_pid_twr_ctrl to false.
                    }
                }
                set g_TermChar to "".

                // PID STUFFS
                if _ascAngObj:APO_PID_RESET
                {
                    set apo_PID:kP to _ascAngObj:APO_PID_PDEF.
                    set apo_PID:kI to _ascAngObj:APO_PID_IDEF.
                    set apo_PID:kD to _ascAngObj:APO_PID_DDEF.
                    apo_PID:Reset().

                    set _ascAngObj:APO_PID_UPDATE_SETPOINT to True.
                    set _ascAngObj:APO_PID_RESET to False.
                }

                if _ascAngObj:APO_PID_UPDATE_SETPOINT
                {
                    set apo_PID:Setpoint to target_apo.
                    set _ascAngObj:APO_PID_UPDATE_SETPOINT to False.
                }

                // local pitGuard to list(-6.25, 6.25).
                local pitGuard to list(pitch_limit_min, pitch_limit_max).
                local adjPitGuard to pitGuard[1].
                if Stage:Number >= g_StageLimit
                {
                    // set pitGuard  to list(2.5, 2.5).
                    local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR / l_twr_denom.
                    set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + ((twrFactor / Ship:Mass)))).
                }

                local pid_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis). //(apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
                set output_pitch to max(PID_Ang_Min, min(effective_pitch, PID_Ang_Max)).
                // set g_PIDS[_ascAngObj:APO_PID] to apo_PID.
            }
            
            if ETA:Apoapsis > ETA:Periapsis
            {
                set output_pitch to max(PID_Ang_Min, min(PID_Ang_Max, output_pitch)).
            }
        }
        else
        {
            if current_alt > turn_alt_start
            {
                set _ascAngObj:TRANS_PIT_ACTUAL to current_pitch.
                set _ascAngObj:TRANS_ALT_ACTUAL to current_alt.

                set _ascAngObj:PIT_ANG_LIM_MAX to Min(90, Max(77, current_pitch)).

                set _ascAngObj:TRANS_ALT_NEXT to ascent_Prog_Pitch_Alt_Start.

                set g_RunMode to 10.
            }
        }

        set g_Context to last_context.
        return output_pitch.
    }


    // Next with PID control
    global function GetAscentAng_PID
    {
        parameter _ascAngObj.

        if g_Debug OutDebug("GetAscentAng_PID", 0).
        
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
        
        set g_PID_Enabled to False.

        local current_ap_alt    to (Ship:Altitude + (1 * (Ship:Apoapsis))) / 2.
        
        local prograde_pitch            to 90.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local target_apo_thresh to _ascAngObj:APO_TGT_THRESH. 
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start    to _ascAngObj:TRN_ALT_START.
                
        local break_PID to False.

        if g_SpinActive 
        {
            if g_Debug OutDebug("g_SpinActive", 1).
            set output_pitch to Max(-5, Min(15, current_pitch)).
            // set pitch_limit_max to max(pitch_limit_min, pitch_limit_max * 0.28).
        }
        else if current_alt > turn_alt_start
        {

            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if g_Debug OutDebug("alt_err: {0} | apo_err {1}":Format(Round(altitude_error, 3), Round(apo_error, 3)), 2).

            if current_alt < turn_alt_start and Ship:VerticalSpeed > 0
            {
                if g_Debug OutDebug("Prog 616_0", 3).
                local blend_alt_error   to (current_alt - turn_alt_start) / (2500 - turn_alt_start).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.125)).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.05625)). // * 1.125)).// 1.015625)).
                // ** set effective_limit     to max(pitch_limit_min, min(error_limit  * fShape, pitch_limit_max * 1.05625)).
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(45, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(45, min(effective_pitch, 90)).
            }
            else if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                if g_Debug OutDebug("Prog 616_1", 3).
                set error_pitch         to 90 * (1 - altitude_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.225)).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.275)). // 1.25)). // 1.03125)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Best
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
                // * set output_pitch        to min(90, effective_pitch * fShape).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else if current_ap_alt < turn_alt_end and Ship:VerticalSpeed > 0 
            {
                if g_Debug OutDebug("Prog 616_2", 3).
                local blend_alt_error   to (current_alt - turn_alt_blend) / (turn_alt_end - turn_alt_blend).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_apo_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to 90 * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max)).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.25)). // 1.275)). // 1.0625)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Good
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.4)). *** Best
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else if (current_apo >= target_apo_thresh and ETA:Apoapsis <= ETA:Periapsis and not break_PID) or (g_PID_Active and current_alt >= Ship:Body:ATM:Height)
            {
                if not g_PID_Active 
                {
                    set g_PID_Active to True.
                    
                    set _ascAngObj:PIT_LIM_MAX to _ascAngObj:PIT_LIM_MAX * 0.5.
                    set pitch_limit_max to _ascAngObj:PIT_LIM_MAX.

                    set _ascAngObj:PIT_LIM_MIN to _ascAngObj:PIT_LIM_MIN * 0.5.
                    set pitch_limit_min to _ascAngObj:PIT_LIM_MIN.
                }
                local apo_PID to g_PIDS[_ascAngObj:APO_PID].

                GetTermChar().

                if g_TermChar:Length > 0
                {
                    if Unchar(g_TermChar) = 112
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 0.91, 5).
                    }
                    else if Unchar(g_TermChar) = 80
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 1.1, 5).
                    }
                    else if Unchar(g_TermChar) = 105
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 0.91, 5).
                    }
                    else if Unchar(g_TermChar) = 73
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 1.1, 5).
                    }
                    else if Unchar(g_TermChar) = 100
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 0.91, 5).
                    }
                    else if Unchar(g_TermChar) = 68
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 1.1, 5).
                    }
                    else if Unchar(g_TermChar) = 85
                    {
                        set _ascAngObj:APO_PID_RESET to True.
                    }
                }
                set g_TermChar to "".

                if g_Debug OutDebug("Prog 616_3", 3).
                // PID STUFFS
                set g_PID_Enabled to True.
                if _ascAngObj:APO_PID_RESET
                {
                    apo_PID:Reset().
                    set _ascAngObj:UPDATE_SETPOINT to True.
                    set _ascAngObj:APO_PID_RESET to False.
                }

                if _ascAngObj:UPDATE_SETPOINT
                {
                    set apo_PID:Setpoint to target_apo.
                    set _ascAngObj:UPDATE_SETPOINT to False.
                }

                local pitGuard to list(-3, 3).
                // local pitGuard to list(pitch_limit_min, pitch_limit_max).
                local adjPitGuard to pitGuard[1].
                if Stage:Number >= g_StageLimit
                {
                    // set pitGuard  to list(2.5, 2.5).
                    local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR / 10.
                    set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + ((twrFactor / Ship:Mass)))).
                }

                local pid_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis). //(apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
                set output_pitch to max(PID_AoA_Min, min(effective_pitch, PID_AoA_Max)).
                // set g_PIDS[_ascAngObj:APO_PID] to apo_PID.
            }
            else
            {
                if g_Debug OutDebug("Prog 616_4", 3).
                set error_pitch         to 90 * (1 - apo_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error) / apo_error)).
                // * set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). *** Good  // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.1125) / apo_error)).  ** Best
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }

            if ETA:Apoapsis > ETA:Periapsis
            {
                if g_Debug OutDebug("Prog Reversi", 4).
                set output_pitch to max(2.5, min(45, -output_pitch)).
            }
        }

        return Min(90, Max(-90, output_pitch * fShape)).
    }

    // Next with PID control
    global function GetAscentAng_PID_NextPlease
    {
        parameter _ascAngObj.

        // set g_Debug to true.
        if g_Debug OutDebug("GetAscentAng_PID", 0).
        
        local fShape            to _ascAngObj:FSHAPE.
        local degree_error      to 0.
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
        
        set g_PID_Enabled to False.

        local current_ap_alt    to (Ship:Altitude + (1 * (Ship:Apoapsis))) / 2.
        
        local prograde_pitch            to 90.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        
        local pitch_limit_max   to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min   to _ascAngObj:PIT_LIM_MIN.
        local target_apo        to _ascAngObj:APO_TGT.
        local target_apo_thresh to _ascAngObj:APO_TGT_THRESH. 
        local turn_alt_blend    to _ascAngObj:TRN_ALT_BLEND.
        local turn_alt_end      to _ascAngObj:TRN_ALT_END.
        local turn_alt_start_kickover to _ascAngObj:TRN_ALT_START_KIK.
        local turn_alt_start_track    to _ascAngObj:TRN_ALT_START_TRK.
        local turn_deg_kick           to _ascAngObj:TRN_DEG_KIK.
        local turn_ang_kick           to 90 - turn_deg_kick.
        local turn_spd_start_kickover to _ascAngObj:TRN_SPD_START_KIK.
        
        local break_PID to False.

        if g_SpinActive 
        {
            if g_Debug OutDebug("g_SpinActive", 1).
            set output_pitch to Max(-5, Min(15, current_pitch)).
            // set pitch_limit_max to max(pitch_limit_min, pitch_limit_max * 0.28).
        }
        else 
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if g_Debug OutDebug("alt_err: {0} | apo_err {1}":Format(Round(altitude_error, 3), Round(apo_error, 3)), 4).

            if current_alt < turn_alt_start_kickover and Ship:VerticalSpeed < turn_spd_start_kickover
            {
                if g_Debug OutDebug("Prog 616_-1", 2).
            }
            else if current_alt < turn_alt_start_track and Ship:VerticalSpeed > 0
            {
                if g_Debug OutDebug("Prog 616_0", 2).
                set altitude_error      to Min(1, Max(0, (current_alt - turn_alt_start_kickover) / (turn_alt_start_track - turn_alt_start_kickover))).
                local angle_error       to turn_deg_kick * altitude_error.

                set error_pitch         to Max(turn_ang_kick, Min(90, 90 - angle_error)).

                set effective_limit     to 1.
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)). 

                set output_pitch        to max(turn_ang_kick, min(effective_pitch, 90)).

                set degree_error to Abs(current_pitch - prograde_surface_pitch).
            }
            else if current_alt < turn_alt_blend and Ship:VerticalSpeed > 0
            {
                if g_Debug OutDebug("Prog 616_1", 2).
                set altitude_error      to Min(1, Max(0, (current_alt - turn_alt_start_kickover) / (turn_alt_blend - turn_alt_start_kickover))).
                set error_pitch         to turn_deg_kick * (1 - altitude_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * altitude_error).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max)).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.2)). // 1.25)). // 1.03125)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.275)). // *** Good
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Best
                set effective_pitch     to max(prograde_surface_pitch - effective_limit, min(error_pitch, prograde_surface_pitch + effective_limit)).
                // * set output_pitch        to min(90, effective_pitch * fShape).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            else if current_ap_alt < target_apo_thresh and Ship:VerticalSpeed > 0 
            {
                if g_Debug OutDebug("Prog 616_2", 2).
                set altitude_error      to Min(1, Max(0, (current_alt - turn_alt_start_kickover) / (turn_alt_end - turn_alt_start_kickover))).
                local blend_alt_error   to (current_alt - turn_alt_blend) / (turn_alt_end - turn_alt_blend).
                local alt_error_blended to altitude_error * (1 - blend_alt_error).
                // local blend_apo_error   to (current_apo - turn_alt_blend) / (target_apo - turn_alt_blend).
                local apo_error_blended to apo_error * blend_alt_error.
                local comb_err          to alt_error_blended + apo_error_blended.
                set effective_error     to comb_err.
                set error_pitch         to turn_deg_kick * (1 - comb_err).
                set error_limit         to pitch_limit_min + (pitch_limit_max * comb_err).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max)).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_max * 1.225)). // 1.275)). // 1.0625)).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.325)). *** Good
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_max * 1.4)). *** Best
                set prograde_pitch      to (prograde_surface_pitch * (1 - effective_error)) + (prograde_orbit_pitch * effective_error). 
                set effective_pitch     to max(prograde_pitch - effective_limit, min(error_pitch, prograde_pitch + effective_limit)). 
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
                
                // PID STUFFS, start it up
                if g_Debug OutDebug("Prog 616_2 PID TRAIN", 2).
                set g_PID_Enabled to False.
                local apo_PID to g_PIDS[_ascAngObj:APO_PID].

                if _ascAngObj:APO_PID_RESET
                {
                    apo_PID:Reset().
                    set _ascAngObj:UPDATE_SETPOINT to True.
                    set _ascAngObj:APO_PID_RESET to False.
                }

                if _ascAngObj:UPDATE_SETPOINT
                {
                    set apo_PID:Setpoint to target_apo.
                    set _ascAngObj:UPDATE_SETPOINT to False.
                }

                local pitGuard to list(-1.5, 1.5).
                // local pitGuard to list(pitch_limit_min, pitch_limit_max).
                local adjPitGuard to pitGuard[1].
                if Stage:Number >= g_StageLimit
                {
                    // set pitGuard  to list(2.5, 2.5).
                    local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR / 10.
                    set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + Min(1.25, twrFactor / Ship:Mass))).
                }

                local pid_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis). //(apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                // set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
                // set output_pitch to max(PID_AoA_Min, min(effective_pitch, PID_AoA_Max)).
                // set g_PIDS[_ascAngObj:APO_PID] to apo_PID.
            }
            else if (current_apo >= target_apo_thresh and ETA:Apoapsis <= ETA:Periapsis and not break_PID) or (g_PID_Active and current_alt >= Ship:Body:ATM:Height)
            {
                if not g_PID_Active 
                {
                    set g_PID_Active to True.
                    
                    set _ascAngObj:PIT_LIM_MAX to _ascAngObj:PIT_LIM_MAX * 0.25.
                    set pitch_limit_max to _ascAngObj:PIT_LIM_MAX.

                    set _ascAngObj:PIT_LIM_MIN to _ascAngObj:PIT_LIM_MIN * 0.25.
                    set pitch_limit_min to _ascAngObj:PIT_LIM_MIN.
                }
                local apo_PID to g_PIDS[_ascAngObj:APO_PID].

                GetTermChar().

                if g_TermChar:Length > 0
                {
                    if Unchar(g_TermChar) = 112
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 0.91, 5).
                    }
                    else if Unchar(g_TermChar) = 80
                    {
                        set apo_PID:kP to Round(apo_PID:kP * 1.1, 5).
                    }
                    else if Unchar(g_TermChar) = 105
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 0.91, 5).
                    }
                    else if Unchar(g_TermChar) = 73
                    {
                        set apo_PID:kI to Round(apo_PID:kI * 1.1, 5).
                    }
                    else if Unchar(g_TermChar) = 100
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 0.91, 5).
                    }
                    else if Unchar(g_TermChar) = 68
                    {
                        set apo_PID:kD to Round(apo_PID:kD * 1.1, 5).
                    }
                    else if Unchar(g_TermChar) = 85
                    {
                        set _ascAngObj:APO_PID_RESET to True.
                    }
                }
                set g_TermChar to "".

                if g_Debug OutDebug("Prog 616_3", 2).
                // PID STUFFS
                set g_PID_Enabled to True.
                if _ascAngObj:APO_PID_RESET
                {
                    apo_PID:Reset().
                    set _ascAngObj:UPDATE_SETPOINT to True.
                    set _ascAngObj:APO_PID_RESET to False.
                }

                if _ascAngObj:UPDATE_SETPOINT
                {
                    set apo_PID:Setpoint to target_apo.
                    set _ascAngObj:UPDATE_SETPOINT to False.
                }

                local pitGuard to list(-1, 1).
                // local pitGuard to list(pitch_limit_min, pitch_limit_max).
                local adjPitGuard to pitGuard[1].
                if Stage:Number >= g_StageLimit
                {
                    // set pitGuard  to list(2.5, 2.5).
                    local twrFactor to choose 1 if g_ActiveEngines_Data:TWR = 0 else g_ActiveEngines_Data:TWR / 10.
                    set adjPitGuard to min(pitGuard[1], max(pitGuard[0], pitGuard[1] + ((twrFactor / Ship:Mass)))).
                }

                local pid_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis). //(apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                set effective_pitch to max(current_pitch - adjPitGuard, min(pid_pitch, current_pitch + adjPitGuard)).
                set output_pitch to max(PID_AoA_Min, min(effective_pitch, PID_AoA_Max)).
                // set g_PIDS[_ascAngObj:APO_PID] to apo_PID.
            }
            else
            {
                if g_Debug OutDebug("Prog 616_4", 2).
                set error_pitch         to 90 * (1 - apo_error).
                set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error) / apo_error)).
                set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.25) / apo_error)). // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.375) / apo_error)). *** Good  // 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
                // set effective_limit     to max(pitch_limit_min, min(error_limit * fShape, pitch_limit_min + (pitch_limit_max / apo_error * 1.1125) / apo_error)).  ** Best
                set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
                // * set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
                set output_pitch        to max(-effective_limit, min(effective_pitch, 90)).
            }
            
            if ETA:Apoapsis > ETA:Periapsis
            {
                if g_Debug OutDebug("Prog Reversi", 3).
                set output_pitch to max(2.5, min(45, -output_pitch + 5) * fShape).
            }
            else
            {
                set output_pitch to output_pitch * fShape.
            }
        }
        if g_Debug OutDebug("err_pit: {0} | eff_lim {1} | eff_pit: {2} ":Format(Round(error_pitch, 3), Round(effective_limit, 3), Round(effective_pitch, 3), Round(output_pitch, 3), Round(current_pitch, 3)), 5).
        if g_Debug OutDebug("out_pit: {0} | cur_pit: {1}":Format(Round(output_pitch, 3), Round(current_pitch, 3)), 6).

        // set g_Debug to false.

        return Min(90, Max(-90, output_pitch)).
    }


    // Next with PID control
    global function GetAscentAng_PID_FuckingThingSucks
    {
        parameter _ascAngObj.

        // set g_Debug to true.
        // OutDebug("GetAscentAng_PID_FuckingThingSucks", -8).
        // set g_DbgLine to g_DbgAnchorLine.

        set g_DbgLine to g_DbgAnchorLine.
        
        local fShape       to _ascAngObj:FSHAPE.
        local trans_alt_err      to 0.
        local apo_err      to 0.
        local comb_err     to 0.
        local current_alt  to Ship:Altitude.
        local current_apo  to Ship:Apoapsis.


        local pitch_limit_effective   to 0.
        // local target_pitch       to 0.
        
        set g_PID_Enabled to False.

        local current_ap_alt            to (Ship:Altitude + (1 * Ship:Apoapsis)) / 2.
        
        local current_pitch             to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).
        local output_pitch              to current_pitch.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, Ship:SrfPrograde:Vector).
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, Ship:Prograde:Vector).
        local prograde_output_pitch     to 0.
        local target_correction_pitch   to 0.
        local target_pitch              to current_pitch.
        
        local turn_alt_blend_window     to _ascAngObj:TRN_ALT_BLEND_WINDOW.
        local turn_alt_end              to _ascAngObj:TRN_ALT_END.
        local turn_alt_end_err          to Min(1, current_alt / turn_alt_end).
        local turn_alt_start_track      to _ascAngObj:TRN_ALT_START_TRK.
        local turn_alt_start_kick       to _ascAngObj:TRN_ALT_START_KIK.
        local turn_deg_kick             to _ascAngObj:TRN_DEG_KIK.
        local turn_ang_kick             to 90 - turn_deg_kick.
        local turn_spd_start_kickover   to _ascAngObj:TRN_SPD_START_KIK.
        
        local pro_blend_start           to _ascAngObj:PRO_BLEND_START.
        local pro_blend_width           to _ascAngObj:PRO_BLEND_WIDTH.
        
        local pitch_ang_max             to _ascAngObj:PIT_MAX.
        local pitch_limit_max           to _ascAngObj:PIT_LIM_MAX.
        local pitch_limit_min           to _ascAngObj:PIT_LIM_MIN.
        local pitch_limit_set           to _ascAngObj:PIT_LIM_SET.
        local pitch_upper_bound         to _ascAngObj:PIT_UPPER_BOUND.
        local target_alt                to _ascAngObj:ALT_TGT.
        local transition_alt            to _ascAngObj:ALT_TRANS.
        local target_apo                to _ascAngObj:APO_TGT.
        local target_apo_thresh         to _ascAngObj:APO_TGT_THRESH. 
        
        local blend_err to 0.
        local blend_err_sani to 0.
        
        local break_PID to False.

        if g_SpinActive 
        {
            if g_Debug OutDebug("g_SpinActive", -8).
            set output_pitch to Max(-5, Min(15, current_pitch)).
        }
        else 
        {
            if g_Debug OutDebug("              ", -8).

            set trans_alt_err to (current_alt - transition_alt) / (target_alt - transition_alt).
            set turn_alt_end_err to Min(1, current_alt / turn_alt_end).
            set apo_err to current_apo / target_apo.
            set comb_err to 0.
            
            
            if l_prog = 1
            {
                set prograde_output_pitch to prograde_surface_pitch.
                if g_Debug OutDebug(phaseUpdateStr:Format("Liftoff*", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -2).
                
                set l_prog to 5.
            }
            else if l_prog = 5
            {
                if g_Debug OutDebug(phaseUpdateStr:Format("VertAsc*", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -2).

                set l_prog to 10.
                set l_rnmd to 1.
            }
            else if l_prog = 10 // Altitude-only calculations
            {
                set prograde_output_pitch to prograde_surface_pitch.
                if l_rnmd = 5 // Initial "Kick over" Turn & Roll Program
                {
                    if current_alt > target_alt and Ship:VerticalSpeed > 0
                    {
                        if g_Debug OutDebug(phaseUpdateStr:Format("BlendAlt", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -2).
                        set _ascAngObj:ALT_TGT     to turn_alt_blend_window[0].
                        set _ascAngObj:ALT_TRANS   to current_alt.
                        set _ascAngObj:PIT_MAX     to current_pitch.
                        set _ascAngObj:PIT_LIM_MAX to pitch_limit_set * 0.22.
                        // set _ascAngObj:PIT_LIM_MAX to 3.25.
                        // set _ascAngObj:PIT_LIM_MAX to current_pitch - 1.25. 
                        // set _ascAngObj:PIT_LIM_MAX to Min(current_pitch, pitch_limit_set * 0.525).
                        set l_rnmd to 11.
                    }
                    else
                    {
                        // set comb_err to Min(1, Max(0, ((alt_err * 9) + apo_err) / 10)).
                        // set comb_err to (trans_alt_err * (1 - trans_alt_err)) + (apo_err * trans_alt_err).
                        // set pitch_limit_effective to Min(0.75, Max(-0.75, (pitch_limit_min + (pitch_limit_max * trans_alt_err)))).

                        set comb_err to ((trans_alt_err * (1 - (trans_alt_err)) * 0.225) + ((turn_alt_end_err * (1 - turn_alt_end_err)) * 0.775)) + (apo_err * trans_alt_err).
                        set pitch_limit_effective to Min(pitch_limit_max, Max(-pitch_limit_max, pitch_limit_min + (pitch_limit_max * comb_err))).
                    }
                }
                else if l_rnmd = 11 // Burn to desired Blend Altitude
                {
                    if current_alt >= target_alt and Ship:VerticalSpeed > 0
                    {
                        if g_Debug OutDebug(phaseUpdateStr:Format("BurnApo*", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -2).
                        
                        set _ascAngObj:ALT_TGT     to turn_alt_blend_window[1].
                        set _ascAngObj:ALT_TRANS   to current_alt.
                        set _ascAngObj:PIT_MAX     to current_pitch.
                        set _ascAngObj:PIT_LIM_MAX to pitch_limit_set * 0.325.
                        // set _ascAngObj:PIT_LIM_MAX to Min(current_pitch, pitch_limit_set * 0.525). //  - 1.25. // Min(current_pitch, pitch_limit_set * 0.6725).// Abs(pitch_limit_max - (15 * fShape)).
                        
                        local blend_headroom to _ascAngObj:ALT_TGT - current_alt.
                        local blend_width_sani to Min(25000, Max(12500, blend_headroom)). // , Round(Ship:VerticalSpeed * 27.5))).

                        set _ascAngObj:PRO_BLEND_START to current_alt.
                        set _ascAngObj:PRO_BLEND_WIDTH to blend_width_sani. // if blend_headroom < blend_width_sani else Round(blend_headroom).
                        
                        set l_rnmd to 15.
                    }
                    else
                    {
                        // set comb_err to ((alt_err * 6.725) + (apo_err * 3.275)) / 10. // to ((alt_err * 7) + (apo_err * 9)) / 16.
                        // set comb_err to (trans_alt_err * (1 - trans_alt_err)) + (apo_err * trans_alt_err).
                        // set pitch_limit_effective to pitch_limit_min + (pitch_limit_max * comb_err).

                        set comb_err to ((trans_alt_err * (1 - (trans_alt_err)) * 0.25) + ((turn_alt_end_err * (1 - turn_alt_end_err)) * 0.75)) + (apo_err * turn_alt_end_err).
                        set pitch_limit_effective to Min(pitch_limit_max, Max(-pitch_limit_max, pitch_limit_min + (pitch_limit_max * comb_err))).
                    }
                }
                else if l_rnmd = 15 // Burn to desired Apoapsis
                {
                    set blend_err to (current_alt - _ascAngObj:PRO_BLEND_START) / _ascAngObj:PRO_BLEND_WIDTH.
                    set blend_err_sani to Min(1, blend_err).
                    set prograde_output_pitch to ((prograde_surface_pitch * (1 - blend_err_sani)) + (prograde_orbit_pitch * blend_err_sani)).

                    if current_alt >= target_alt and Ship:VerticalSpeed > 0 and blend_err >= 1
                    {
                        if g_Debug OutDebug(phaseUpdateStr:Format("BLApoAlt", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -2).
                        set _ascAngObj:ALT_TGT     to turn_alt_blend_window[2].
                        set _ascAngObj:ALT_TRANS   to current_alt.
                        set _ascAngObj:PIT_MAX     to current_pitch.
                        set _ascAngObj:PIT_LIM_MAX to pitch_limit_set * 0.5.
                        // set _ascAngObj:PIT_LIM_MAX to Min(current_pitch, pitch_limit_set * 0.575). // Abs(pitch_limit_max - (15 * fShape)).

                        local blend_headroom to _ascAngObj:ALT_TGT - current_alt.

                        set _ascAngObj:PRO_BLEND_START to current_alt.
                        set _ascAngObj:PRO_BLEND_WIDTH to Round(blend_headroom).

                        set l_rnmd to 17.
                        set l_prog to 20.
                    }
                    else
                    {
                        // set comb_err to Min(1, Max(0, ((alt_err * 1.25) + (apo_err * 8.75) / 10))).
                        // set comb_err to (trans_alt_err * (1 - trans_alt_err)) + (apo_err * trans_alt_err).
                        // set pitch_limit_effective to pitch_limit_min + (pitch_limit_max * comb_err).

                        set comb_err to (trans_alt_err * (1 - (trans_alt_err)) * 0.25) + ((turn_alt_end_err * (1 - turn_alt_end_err)) * 0.75) + (apo_err * turn_alt_end_err).
                        set pitch_limit_effective to Min(pitch_limit_max, Max(-pitch_limit_max, pitch_limit_min + (pitch_limit_max * comb_err))).
                    }
                }
                else // Liftoff
                {
                    if current_alt >= turn_alt_start_kick or Ship:VerticalSpeed >= turn_spd_start_kickover
                    {
                        if g_Debug OutDebug(phaseUpdateStr:Format("KickOver", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -2).
                        set _ascAngObj:ALT_TGT     to turn_alt_start_track.
                        set _ascAngObj:ALT_TRANS   to current_alt.
                        set _ascAngObj:PIT_MAX     to current_pitch.
                        set _ascAngObj:PIT_LIM_MAX to 0.75.

                        // set _ascAngObj:PIT_LIM_MAX to current_pitch. //Min(current_pitch, (pitch_limit_set * 0.775)).
                        // set _ascAngObj:APO_PID_LIM_MAX to _ascAngObj:PIT_LIM_MAX.
                        // set _ascAngObj:APO_PID_LIM_MIN to Max(-3.25, Min(PID_AoA_Min, -_ascAngObj:PIT_LIM_MAX)).
                        // set _ascAngObj:APO_PID_LIM_MIN to PID_AoA_Min * Min(1, Max(0.125, (1 - trans_alt_err))).


                        set l_rnmd to 5.
                    }
                    else if Ship:VerticalSpeed >= 2.5
                    {
                        set pitch_limit_effective to 0.0125.
                    }
                    else
                    {
                        set comb_err to ((trans_alt_err * (1 - (trans_alt_err)) * 0.125) + ((turn_alt_end_err * (1 - turn_alt_end_err)) * 0.875)) + (apo_err * turn_alt_end_err).
                        if g_Debug OutDebug(phaseUpdateStr:Format("PHASE", "MET", "ALT"), -12).
                    }
                }
                // set target_pitch to pitch_upper_bound * (1 - comb_err).
                set target_pitch to pitch_ang_max * (1 - comb_err).
                set output_pitch to Min(prograde_output_pitch + pitch_limit_effective, Max(prograde_output_pitch - pitch_limit_effective, target_pitch)).
                // set output_pitch to Min(prograde_output_pitch + pitch_limit_max, Max(prograde_output_pitch - pitch_limit_max, target_pitch)).
            }
            else if l_prog = 20 // Combined Alt and Apo target blending, initializing the PID loop
            {
                set trans_alt_err to Min(1, (current_alt - transition_alt) / (target_alt - transition_alt)).
                set apo_err to current_apo / target_apo.
                set pitch_upper_bound to _ascAngObj:PIT_MAX.
                // set comb_err to ((trans_alt_err * (1 - (trans_alt_err)) * 0.75) + ((turn_alt_end_err * (1 - turn_alt_end_err)) * 0.925)) + (apo_err * turn_alt_end_err).
                
                if l_rnmd = 17 // Blend Alt into Apo
                {
                    if current_alt >= target_alt
                    {
                        if g_Debug OutDebug(phaseUpdateStr:Format("SetupPID", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -12).

                        // set _ascAngObj:ALT_TGT     to turn_alt_end.
                        set _ascAngObj:ALT_TGT     to _ascAngObj:APO_TGT_FTT.
                        set _ascAngObj:ALT_TRANS   to current_alt.
                        set _ascAngObj:PIT_MAX     to current_pitch.
                        set _ascAngObj:PIT_LIM_MAX to pitch_limit_set * 0.675.
                        // set _ascAngObj:PIT_LIM_MAX to current_pitch.
                        // set _ascAngObj:PIT_LIM_MAX to Max(current_pitch, Ascent_AoA_Max * fShape).
                        // set _ascAngObj:PIT_LIM_MAX to Min(current_pitch, pitch_limit_set * 0.775). // Min(current_pitch, pitch_limit_set * 0.725).// Abs(pitch_limit_max - (15 * fShape)).

                        set _ascAngObj:APO_PID_LIM_MAX to _ascAngObj:PIT_MAX.
                        set _ascAngObj:APO_PID_LIM_MIN to PID_AoA_Min * fShape.

                        local blend_headroom to Min(50000, Max(12500, _ascAngObj:APO_TGT_FTT - current_alt)).

                        set _ascAngObj:PID_BLEND_START to current_alt.
                        set _ascAngObj:PID_BLEND_WIDTH to Round(blend_headroom).
                        // set _ascAngObj:APO_PID_LIM_MIN to PID_AoA_Min * Min(1, Max(0.125, (1 - trans_alt_err))).
                        
                        set l_prog to 27.
                        set l_rnmd to 21.
                    }
                    else
                    {
                        set blend_err to (current_alt - _ascAngObj:PRO_BLEND_START) / _ascAngObj:PRO_BLEND_WIDTH.

                        if blend_err > 1
                        {
                            set blend_err_sani to 1.
                            set prograde_output_pitch to prograde_orbit_pitch.
                        }
                        else
                        {
                            set blend_err_sani to Min(1, blend_err).
                            set prograde_output_pitch to ((prograde_surface_pitch * (1 - blend_err_sani)) + (prograde_orbit_pitch * blend_err_sani)).
                        }

                        set comb_err to (trans_alt_err * (1 - (trans_alt_err)) * 0.125) + ((turn_alt_end_err * (1 - turn_alt_end_err)) * 0.075) + ((apo_err * turn_alt_end_err) * 0.8).
                        set pitch_limit_effective to pitch_limit_min + (pitch_limit_max * comb_err).

                        // OutInfo("2: BlendStart: {0} | Cur: {1} | BlendWidth: {2} ":Format(_ascAngObj:PRO_BLEND_START, Round(pro_alt_diff), _ascAngObj:PRO_BLEND_WIDTH), 2).
                        OutInfo("2: BlendStart: {0} | BlendWidth: {1} | BlendError: {2} ":Format(_ascAngObj:PRO_BLEND_START, _ascAngObj:PRO_BLEND_WIDTH, Round(blend_err)), 2).
                    }
                }

                set target_pitch  to pitch_ang_max * (1 - comb_err).
                set output_pitch to Min(prograde_output_pitch + pitch_limit_effective, Max(prograde_output_pitch - pitch_limit_effective, target_pitch)).
                // set output_pitch to Min(prograde_output_pitch + pitch_limit_max, Max(prograde_output_pitch - pitch_limit_max, target_pitch)).
            }
            else if l_prog = 27 // Closed Loop to ApoThresh
            {
                set apo_err to current_apo / target_apo.
                set prograde_output_pitch to prograde_orbit_pitch.
                if l_rnmd = 21 // Burn to apo thresh (prior to PID kick in)
                {
                    if current_ap_alt >= target_alt
                    {
                        if g_Debug OutDebug(phaseUpdateStr:Format("PIDLoop*", Round(MissionTime, 3):ToString(), Round(Ship:Altitude, 1)), -12).
                        set _ascAngObj:ALT_TGT     to target_apo_thresh.
                        set _ascAngObj:ALT_TRANS   to current_alt.
                        set _ascAngObj:PIT_MAX     to Max(PID_Ang_Max, current_pitch).
                        set _ascAngObj:PIT_LIM_MAX to pitch_limit_set * 0.825.
                        // set _ascAngObj:APO_PID_LIM_MAX to _ascAngObj:PIT_LIM_MAX.
                        
                        set _ascAngObj:APO_PID_LIM_MAX to Max(current_pitch, PID_Ang_Max).
                        set _ascAngObj:APO_PID_LIM_MIN to PID_Ang_Min * fShape.
                        
                        set g_PIDS[_ascAngObj:APO_PID]:MaxOutput to _ascAngObj:APO_PID_LIM_MAX.
                        set g_PIDS[_ascAngObj:APO_PID]:MinOutput to _ascAngObj:APO_PID_LIM_MIN.

                        local blend_headroom to Min(37500, Max(7500, _ascAngObj:ALT_TGT - current_alt)).

                        set _ascAngObj:PID_BLEND_START to current_alt.
                        set _ascAngObj:PID_BLEND_WIDTH to Round(blend_headroom).

                        set g_PID_Active to True.

                        set l_prog to 33.
                        set l_rnmd to 24.
                    }
                    else
                    {
                        set pitch_limit_effective to pitch_limit_min + (pitch_limit_max * apo_err).
                    }
                }
                // set pitch_limit_max to 0.125.
                // set target_pitch  to pitch_ang_max - (pitch_limit_effective * apo_err).
                set target_pitch to pitch_ang_max * (1 - apo_err).
                set output_pitch to Min(prograde_output_pitch + pitch_limit_effective, Max(prograde_output_pitch - pitch_limit_effective, target_pitch)).
            }
            else if l_prog = 33 // Pid Control
            {
                if l_rnmd = 20
                {
                    // set _ascAngObj:PIT_LIM_MIN to PID_AoA_Min * fShape.
                    set g_PID_Active to False.
                    set _ascAngObj:PIT_LIM_MIN to 5.
                    set _ascAngObj:PIT_LIM_MAX to PID_AoA_Max * fShape.

                    set l_prog to 20.
                    set l_rnmd to 17.

                    return current_pitch.
                }
                else if l_rnmd = 22
                {

                    set g_PID_Active to True.
                        
                    set _ascAngObj:PIT_LIM_MIN to 5 * fShape.
                    set _ascAngObj:PIT_LIM_MAX to 22.5 * fShape.
                    
                    set l_rnmd to 26.
                    return current_pitch.
                }
                // else if l_rnmd = 24
                // {
                //     if not g_PID_Active
                //     {
                //         set g_PID_Active to True.
                        
                //         set _ascAngObj:PIT_LIM_MAX to Max(current_pitch, PID_AoA_Max).
                //         set _ascAngObj:PIT_LIM_MIN to -27.5.
                //     }
                //     set l_rnmd to 26.
                //     return current_pitch.
                // }
                else if l_rnmd = 23
                {
                    // set _ascAngObj:PIT_LIM_MAX to 3.75. //current_pitch.
                    // set _ascAngObj:PIT_LIM_MIN to 0.
                    // set _ascAngObj:PIT_LIM_MIN to PID_AoA_Min * fShape.
                    // set _ascAngObj:PIT_LIM_MAX to Max(current_pitch, 22.5 * fShape).
                    // set _ascAngObj:PIT_MAX to current_pitch.

                    // set _ascAngObj:APO_PID_LIM_MAX to Max(current_alt, PID_AoA_Max * fShape).
                    // set _ascAngObj:APO_PID_LIM_MIN to PID_AoA_Min * (1 - apo_err).

                    set l_rnmd to 24.
                }
                else if l_rnmd = 24
                {
                    // if (current_apo >= target_apo_thresh and ETA:Apoapsis <= ETA:Periapsis and not break_PID) or (g_PID_Active and current_alt >= Ship:Body:ATM:Height)
                    local apo_PID to g_PIDS[_ascAngObj:APO_PID].
                    set g_PID_Active to True.
                    if break_PID
                    {
                        set l_rnmd to 20.
                        return current_pitch.
                    }
                    else if current_apo >= target_apo // target_apo_thresh or apo_PID:MaxOutput <= PID_AoA_Max
                    {
                        set _ascAngObj:PIT_LIM_MAX to pitch_limit_set.
                        // set _ascAngObj:PIT_LIM_MAX to 12.5.
                        // set _ascAngObj:PIT_LIM_MIN to 1.25.
                        // set _ascAngObj:PIT_MAX to current_pitch.

                        // set _ascAngObj:APO_PID_LIM_MAX to pitch_limit_set.
                        // set _ascAngObj:APO_PID_LIM_MIN to PID_AoA_Min.

                        // set apo_PID:MinOutput to _ascAngObj:APO_PID_LIM_MIN.
                        // set apo_PID:MaxOutput to _ascAngObj:APO_PID_LIM_MAX.
                        
                        set l_rnmd to 25.
                    }
                    else
                    {                        

                        GetTermChar().

                        if g_TermChar:Length > 0
                        {
                            if Unchar(g_TermChar) = 112
                            {
                                set apo_PID:kP to Round(apo_PID:kP * 0.91, 5).
                            }
                            else if Unchar(g_TermChar) = 80
                            {
                                set apo_PID:kP to Round(apo_PID:kP * 1.1, 5).
                            }
                            else if Unchar(g_TermChar) = 105
                            {
                                set apo_PID:kI to Round(apo_PID:kI * 0.91, 5).
                            }
                            else if Unchar(g_TermChar) = 73
                            {
                                set apo_PID:kI to Round(apo_PID:kI * 1.1, 5).
                            }
                            else if Unchar(g_TermChar) = 100
                            {
                                set apo_PID:kD to Round(apo_PID:kD * 0.91, 5).
                            }
                            else if Unchar(g_TermChar) = 68
                            {
                                set apo_PID:kD to Round(apo_PID:kD * 1.1, 5).
                            }
                            else if Unchar(g_TermChar) = 85
                            {
                                set _ascAngObj:APO_PID_RESET to True.
                            }
                        }
                        set g_TermChar to "".

                        
                        // PID STUFFS
                        set g_PID_Enabled to True.
                        if _ascAngObj:APO_PID_RESET
                        {
                            apo_PID:Reset().
                            set _ascAngObj:UPDATE_SETPOINT to True.
                            set _ascAngObj:APO_PID_RESET to False.
                        }

                        if _ascAngObj:UPDATE_SETPOINT
                        {
                            set apo_PID:Setpoint to target_apo.
                            set _ascAngObj:UPDATE_SETPOINT to False.
                        }

                        // local pitGuard to list(PID_AoA_Min, PID_AoA_Max).
                        // local pitGuard to list(-4.25, 4.25).
                        
                        // if g_ActiveEngines:Length > 0
                        // {
                        //     local twrFactor to choose 1 if g_ActiveEngines_Data:TWR < 1 else g_ActiveEngines_Data:TWR / g_ActiveEngines:Length.
                        //     set pitGuard to list(pitGuard[0] * (twrFactor / (Ship:Mass * 0.1)), pitGuard[1] * (twrFactor / (Ship:Mass * 0.1))).
                        // }
                        // else
                        // {
                        //     set pitGuard to list(pitGuard[0] * (1 - apo_err), pitGuard[1] * (1 - apo_err)).
                        // }

                        set target_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis).
                        set apo_err to current_apo / target_apo.
                        
                        local blend_alt_diff to current_alt - _ascAngObj:PID_BLEND_START.
                        set blend_err to blend_alt_diff / _ascAngObj:PID_BLEND_WIDTH.
                        set blend_err_sani to Min(1, Max(-1, blend_err)).

                        set pitch_limit_effective to pitch_limit_min + Min(pitch_limit_max, Max(0, (pitch_limit_max * apo_err) * Abs(1 - blend_err_sani))).

                        // set apo_PID:MaxOutput to Max(pitch_ang_max, apo_PID:MaxOutput - (0.25 * blend_err_sani)).

                        // set prograde_output_pitch to ((prograde_surface_pitch * (1 - blend_err_sani)) + (prograde_orbit_pitch * blend_err_sani)).
                        
                        // set pitch_limit_effective to pitch_limit_min + (pitch_limit_max * Min(1, Max(0, blend_apo_err_sani))).
                        
                        // set pitch_limit_effective to 3.25 + ((PID_AoA_Max - 3.25) * apo_err).
                        // set pitch_limit_effective to current_pitch + pitGuard[1].
                        // set output_pitch to Min(pitch_ang_max, Max(pitch_limit_min, Min(prograde_orbit_pitch + pitch_limit_effective, Max(prograde_orbit_pitch - pitch_limit_effective, needed_pitch)))).
                        // set output_pitch to Min(pitch_ang_max, Max(pitch_limit_min, needed_pitch)).
                        set output_pitch to Min(current_pitch + pitch_limit_effective, Max(current_pitch - pitch_limit_effective, target_pitch)).
                    }
                }
                else if l_rnmd = 25
                {
                    // if (current_apo >= target_apo_thresh and ETA:Apoapsis <= ETA:Periapsis and not break_PID) or (g_PID_Active and current_alt >= Ship:Body:ATM:Height)
                    // {

                    // }

                    if break_PID
                    {
                        set l_rnmd to 20.
                        return current_pitch.
                    }
                    else
                    {                        
                        local apo_PID to g_PIDS[_ascAngObj:APO_PID].

                        GetTermChar().

                        if g_TermChar:Length > 0
                        {
                            if Unchar(g_TermChar) = 112
                            {
                                set apo_PID:kP to Round(apo_PID:kP * 0.91, 5).
                            }
                            else if Unchar(g_TermChar) = 80
                            {
                                set apo_PID:kP to Round(apo_PID:kP * 1.1, 5).
                            }
                            else if Unchar(g_TermChar) = 105
                            {
                                set apo_PID:kI to Round(apo_PID:kI * 0.91, 5).
                            }
                            else if Unchar(g_TermChar) = 73
                            {
                                set apo_PID:kI to Round(apo_PID:kI * 1.1, 5).
                            }
                            else if Unchar(g_TermChar) = 100
                            {
                                set apo_PID:kD to Round(apo_PID:kD * 0.91, 5).
                            }
                            else if Unchar(g_TermChar) = 68
                            {
                                set apo_PID:kD to Round(apo_PID:kD * 1.1, 5).
                            }
                            else if Unchar(g_TermChar) = 85
                            {
                                set _ascAngObj:APO_PID_RESET to True.
                            }
                        }
                        set g_TermChar to "".

                        
                        // PID STUFFS
                        // set g_PID_Enabled to True.
                        if _ascAngObj:APO_PID_RESET
                        {
                            apo_PID:Reset().
                            set _ascAngObj:UPDATE_SETPOINT to True.
                            set _ascAngObj:APO_PID_RESET to False.
                        }

                        if _ascAngObj:UPDATE_SETPOINT
                        {
                            set apo_PID:Setpoint to target_apo.
                            set _ascAngObj:UPDATE_SETPOINT to False.
                        }

                        // local pitGuard to list(PID_AoA_Min, PID_AoA_Max).
                        // local pitGuard to list(-4.25, 4.25).
                        
                        // if g_ActiveEngines:Length > 0
                        // {
                        //     local twrFactor to choose 1 if g_ActiveEngines_Data:TWR < 1 else g_ActiveEngines_Data:TWR / g_ActiveEngines:Length.
                        //     set pitGuard to list(pitGuard[0] * (twrFactor / (Ship:Mass * 0.1)), pitGuard[1] * (twrFactor / (Ship:Mass * 0.1))).
                        // }
                        // else
                        // {
                        //     set pitGuard to list(pitGuard[0] * (1 - apo_err), pitGuard[1] * (1 - apo_err)).
                        // }

                        // set target_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis).
                        // set apo_err to current_apo / target_apo.

                        // set pitch_limit_effective to pitch_limit_min + ((pitch_limit_max / 8) * Min(1, Max(0, apo_err))).


                        set apo_err to current_apo / target_apo.
                        
                        // local blend_alt_diff to current_alt - _ascAngObj:PRO_BLEND_START.
                        // set blend_err to blend_alt_diff / _ascAngObj:PRO_BLEND_WIDTH.
                        // set blend_err_sani to Min(1, blend_err).
                        local apo_err_sani to Min(1, Max(-1, apo_err)).

                        // set apo_PID:MaxOutput to Max(pitch_limit_max, apo_PID:MaxOutput - (apo_PID:MaxOutput * apo_err_sani)).

                        set target_pitch to apo_PID:Update(Time:Seconds, Ship:Apoapsis).

                        // set prograde_output_pitch to ((prograde_surface_pitch * (1 - blend_err_sani)) + (prograde_orbit_pitch * blend_err_sani)).
                        
                        set pitch_limit_effective to pitch_limit_min + (3.25 * (1 - apo_err_sani)).
                        
                        // set pitch_limit_effective to 3.25 + ((PID_AoA_Max - 3.25) * apo_err).
                        // set pitch_limit_effective to current_pitch + pitGuard[1].
                        // set output_pitch to Min(pitch_ang_max, Max(pitch_limit_min, Min(prograde_orbit_pitch + pitch_limit_effective, Max(prograde_orbit_pitch - pitch_limit_effective, needed_pitch)))).
                        set output_pitch to Min(pitch_ang_max, Max(pitch_limit_min, target_pitch)).
                        // set output_pitch to Min(current_pitch + pitch_limit_effective, Max(target_pitch, current_pitch - pitch_limit_effective)).
                        // set pitch_limit_effective to pitch_limit_min + Min(pitch_limit_max, Max(0, (pitch_limit_max * apo_err) * Abs(1 - blend_err_sani))).
                    }
                }
            }
            else
            {
                set l_prog to 10.
            }
            
            if ETA:Apoapsis > ETA:Periapsis
            {
                if g_Debug OutDebug("Prog Reversi", -3).
                set output_pitch to Min(18, Max(output_pitch, -18)).
            }
            else
            {
                if g_Debug OutDebug("            ", -3).
            }
        }

        
        // if g_Debug 
        // {
        //     local idx to -2.
        //     local GetNextIdx to { parameter _i to 0. set idx to _i + 1. return _i + 1.}.
            
        //     local prograde_output_pitch_sani to choose 0.00001 if prograde_output_pitch = 0 else prograde_output_pitch.
        //     local pitch_limit_effective_sani to choose 0.00001 if pitch_limit_effective = 0 else pitch_limit_effective.
        //     local pitch_limit_max_sani to choose 0.00001 if pitch_limit_max = 0 else pitch_limit_max.

        //     OutDebug("Prog: {0} | Rnmd: {1}":Format(l_prog, l_rnmd), GetNextIdx(idx)).

        //     OutDebug(" err_alt: {0,-7} | lim_min: {1,-6} |  srf_pro: {2,-6} ":Format(Round(trans_alt_err, 3), Round(pitch_limit_min, 3), Round(prograde_surface_pitch, 3)),      GetNextIdx(idx),2).
        //     OutDebug(" err_apo: {0,-7} | lim_max: {1,-6} |  obt_pro: {2,-6} ":Format(Round(apo_err, 3), Round(pitch_limit_max, 3), Round(prograde_orbit_pitch, 3)),              GetNextIdx(idx)).
        //     OutDebug("comb_err: {0,-7} | eff_lim: {1,-6} |  pro_out: {2,-6} ":Format(Round(comb_err, 3), Round(pitch_limit_effective_sani, 3), Round(prograde_output_pitch, 3)), GetNextIdx(idx)).
        //     OutDebug(" cur_alt: {0,-7} | tgt_alt: {1,-10} ":Format(Round(current_alt), target_alt), crDbg(GetNextIdx(idx), 2)).
            
        //     OutDebug(" cur_pit: {0,-7} | pro_out: {1,-6} |  pro_err: {2,-6} ":Format(Round(current_pitch, 3), Round(prograde_output_pitch_sani, 3), Round(blend_err, 3)), GetNextIdx(idx), 2).
        //     OutDebug(" tgt_pit: {0,-7} | crc_amt: {1,-6} |  lim_err: {2,-6} ":Format(Round(target_pitch, 3),  Round(target_correction_pitch, 3), Round(pitch_limit_effective_sani / pitch_limit_max_sani, 3)), GetNextIdx(idx)).
        //     OutDebug(" out_pit: {0,-7} | tgt_dif: {1,-6} |  {2,10} ":Format(Round(output_pitch, 3),  Round(target_pitch - output_pitch, 3), " "), GetNextIdx(idx)).
        // }

        // set g_Debug to false.

        return output_pitch.
    }


    // With Experimental PID Control too I guess because I'm dumb
    global function GetAscentAng_PIDyParty 
    {
        parameter _ascAngObj.

        local fShape            to choose _ascAngObj:FSHAPE if _ascAngObj:HasKey("FSHAPE") else 1.
        local altitude_error    to 0.
        local apo_error         to 0.
        local current_alt       to Ship:Altitude.
        local current_apo       to Ship:Apoapsis.
        local current_pit       to 90 - VAng(Ship:Up:Vector, Ship:Facing:Vector).
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
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.
        
        if current_alt > turn_alt_start
        {
            set altitude_error      to current_alt / turn_alt_end.
            set apo_error           to current_apo / target_apo.

            if l_pid_loop_control_active
            {
                if _ascAngObj:APO_PID_RESET
                {
                    g_PIDS[_ascAngObj:APO_PID]:Reset().
                    set _ascAngObj:UPDATE_SETPOINT to True.
                    set _ascAngObj:APO_PID_RESET to False.
                }

                if _ascAngObj:UPDATE_SETPOINT
                {
                    set g_PIDS[_ascAngObj:APO_PID]:Setpoint to target_apo.
                    set _ascAngObj:UPDATE_SETPOINT to False.
                }

                local apo_PID to g_PIDS[_ascAngObj:APO_PID].
                local pid_pitch to (apo_PID:Update(Time:Seconds, Ship:Apoapsis)) * PID_AoA_Max.
                set output_pitch to max(PID_AoA_Min, min(pid_pitch, PID_AoA_Max)).
            }
            else
            {
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
                    OutInfo("Switching to PID Control").
                    set l_pid_loop_control_active to True.
                    set output_pitch to current_pit.
                }
                // else if g_MissionTag:Mission:StartsWith("PID")
            }
            // else
            // {
            //     set error_pitch         to 90 * (1 - apo_error).
            //     set error_limit         to pitch_limit_min + (pitch_limit_max * apo_error).
            //     set effective_limit     to max(pitch_limit_min, min(error_limit, pitch_limit_min + (pitch_limit_max / apo_error * 1.325) / apo_error)). // 1.125) / apo_error))). // ((pitch_limit * 1.25) / min(1.00000001, apo_error))).
            //     set effective_pitch     to max(prograde_orbit_pitch - effective_limit, min(error_pitch, prograde_orbit_pitch + effective_limit)).
            //     set output_pitch        to max(-effective_limit, min(effective_pitch * fShape, 90)).
            // }
        }

        if ETA:Apoapsis > ETA:Periapsis
        {
            set output_pitch to max(-17.5, min(45, -output_pitch)).
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
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.
        
        
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
        local turn_alt_start    to _ascAngObj:TRN_ALT_START_TRK.

        // Vector to pitch degree conversions
        local prograde_surface          to Ship:SrfPrograde:Vector.
        local prograde_surface_pitch    to 90 - VAng(Ship:Up:Vector, prograde_surface).
        local prograde_orbit            to Ship:Prograde:Vector.
        local prograde_orbit_pitch      to 90 - VAng(Ship:Up:Vector, prograde_orbit).
        local prograde_effective_pitch   to prograde_orbit_pitch.

        // Check our flags for any pre-update actions
        if _ascAngObj:HasKey("APO_PID_RESET")
        {
            if _ascAngObj:APO_PID_RESET
            {
                PID_Alt:Reset().
                PID_Apo:Reset().
                // if g_Debug OutDebug("APO_PID_RESET triggered at ({0})":Format(Round(MissionTime, 2))).
            }
            set _ascAngObj:APO_PID_RESET to false.
        }
        if _ascAngObj:HasKey("UPDATE_SETPOINT")
        {
            if _ascAngObj:UPDATE_SETPOINT
            {
                set PID_Alt:Setpoint to _ascAngObj:ALT_PID_SETPOINT.
                set PID_Apo:Setpoint to _ascAngObj:APO_PID_SETPOINT.
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
        
        if _ascAngObj:APO_PID_RESET
        {
            PID_Apo:Reset().
            set _ascAngObj:APO_PID_RESET to False. 
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

    // - Launchpads 
    // #region
    // ConfigureLaunchPad
    //
    global function ConfigureLaunchPlatform
    {
        set g_Program to 6.

        local lpClamps to Ship:ModulesNamed("LaunchClamp").
        local lpLights to choose lpClamps[0]:Part:PartsDubbedPattern("Light") if lpClamps:Length > 0 else list().


        if lpLights:Length > 0
        {
            for p in lpLights 
            { 
                if p:HasModule("ModuleLight") 
                {
                    local m to p:GetModule("ModuleLight"). 

                    if Ship:Sensors:Light > 1 // CurrentTimeSpan:HOUR > 11 and CurrentTimeSpan:HOUR <= 23
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
        // Swing Arm Defaults to Retract Arm LeftW

        local MLPList to Ship:PartsNamedPattern("^AM.MLP.*").
        local moduleLex to Lexicon().
        // set g_Debug to True.
        OutInfo("Configuring Launchpad").
        from { local i to MLPList:Length - 1.} until i < 0 step { set i to i - 1.} do
        {
            local p to MLPList[i].
            
            if not (p:Name:MatchesPattern("(Hold|Clamp|TSM|SwingArm|AtlasUmb|Atlas2Umb)") and p:HasModule("ModuleAnimateGenericExtra"))
            {
                from { local _i to 0. local doneFlag to False.} until _i >= p:Modules:Length or doneFlag step { set _i to _i + 1.} do
                {
                    local m to p:GetModuleByIndex(_i).
                    if m:Name = ("ModuleAnimateGenericExtra")
                    {
                    //    if g_Debug  OutDebug("{0}: {1}":Format(p:Name, m:Name), 1).
                        for modItemType in MLPModuleLex:Keys
                        {
                            // if modItemType = "Fields"
                            // {
                            //     for fieldName in MLPModuleLex[modItemType]
                            //     {
                            //         if m:HasField(fieldName)
                            //         {
                            //             local result to GetField(m, fieldName).
                            //             moduleLex:Add(p:name + "_{0}":Format(_i), list(m, "Fields", fieldName)).
                            //             OutDebug("Result: {0}":Format(result)).
                            //             // set doneFlag to True.
                            //         }
                            //     }
                            // }
                            // else if modItemType = "Events"
                            if modItemType = "Events"
                            {
                                for eventName in MLPModuleLex[modItemType]
                                {
                                    if m:HasEvent(eventName)
                                    {
                                        local result to DoEvent(m, eventName).
                                        moduleLex:Add(p:name + "_{0}":Format(_i), list(m, "Events", eventName)).
                                        // if g_Debug OutDebug("Result: {0}":Format(result), 2).
                                        // set doneFlag to True.
                                    }
                                }
                            }
                        }
                        if m:HasField("Status")
                        {   
                            local stat to m:GetField("Status").
                            OutInfo("Status: {0}":Format(stat), 2).
                            if stat = "Locked" 
                            {
                                OutInfo("", 1).
                                OutInfo("", 2).
                            }
                        }
                    }
                }
            }
            else if p:Name:MatchesPattern("^AM.MLP.*SwingArm.*")
            {
                if p:Tag:MatchesPattern("(Retract\|)?(L(eft)?|R(ight)?)+(\|OnLoad)+")
                {
                    if p:Tag:Length > 0 and not p:Tag:StartsWith("Retract") 
                    {
                        set p:Tag to "Retract|{0}":Format(p:Tag).
                    }
                    local tagSplit to p:Tag:Replace("Retract|",""):Split("|").
                    local armActionType to tagSplit[0].
                    local armRetractDir to "Right".
                    if tagSplit:Length > 1 
                    {
                        set armRetractDir to choose "Left" if tagSplit[1]:MatchesPattern("L(eft)?") else "Right".
                    }
                
                    from { local _i to 0. local doneFlag to False.} until _i = p:Modules:Length or doneFlag step { set _i to _i + 1.} do
                    {
                        local m to p:GetModulesByIndex(_i).
                        if m:HasEvent("{0} Arm {1}":Format(armActionType, armRetractDir))
                        {
                            local eventName to m:GetModuleByIndex(_i).
                            OutInfo("Part: {0} | Event: {1}":Format(p:Name, eventName), 1).
                            moduleLex:Add(p:name + "_{0}":Format(_i), list(m, "Events", eventName)).
                            set doneFlag to True.
                        }
                    }
                }
            }
            
        }

        from { local i to 0.} until i <= moduleLex:Keys:Length step { set i to i + 1.} do
        {
            local _doneFlag to False.
            local partName to moduleLex:Keys[i].

            local m       to moduleLex:Values[i][0].
            local typeStr to choose moduleLex:Values[i][1] if moduleLex:Values[i]:Length > 1 else "NUL".
            local nameStr to choose moduleLex:Values[i][2] if moduleLex:Values[i]:Length > 2 else "NUL".
            local value   to choose moduleLex:Values[i][3] if moduleLex:Values[i]:Length > 3 else "NUL".



            OutInfo("Part: {0} | {1}: {2}":Format(partName, typeStr, nameStr), 1).
            if DoEvent(m, typeStr) > 0
            {
                set g_TS to Time:Seconds + 5.
            }
            else if DoAction(m, nameStr, True) 
            {
                set g_TS to Time:Seconds + 5.
            }
            else if SetField(m, nameStr, value)
            {
                set g_TS to Time:Seconds + 5.
            }

            until _doneFlag
            {
                if m:HasField("Status")
                {   
                    local stat to GetField(m, "Status", 0).
                    OutInfo("Status: {0}":Format(stat), 2).
                    if stat = 1
                    {
                        set _doneFlag to True.
                        OutInfo("", 1).
                        OutInfo("", 2).
                    }
                    else
                    {
                        OutInfo("Time Remaining: {0}":Format(g_TS - Time:Seconds), 2).
                    }
                }
                else
                {
                    if Time:Seconds > g_TS
                    {
                        set _doneFlag to True.
                        OutInfo("", 1).
                        OutInfo("", 2).
                    }
                    else
                    {
                        OutInfo("Time Remaining: {0}":Format(g_TS - Time:Seconds), 2).
                    }
                }
            }
        }
        
    }

    // Resets the launch platform to pre-launch state
    global function ResetLaunchPlatform
    {
        set g_Program to 5.
        local lpClamps to Ship:ModulesNamed("LaunchClamp").
        local lpLights to choose lpClamps[0]:Part:PartsDubbedPattern("Light") if lpClamps:Length > 0 else list().

        if lpLights:Length > 0
        {
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
                if m:Part:Name:MatchesPattern("^AM.MLP.*SwingArm.*") and m:Part:Tag:MatchesPattern("Retract\|(Left|Right)\|OnLoad")
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

    // - Launch Parameters
    
    // GetLaunchParameters
    //
    global function GetLaunchParameters
    {
        set g_MissionTag to ParseCoreTag(core:tag).
        
        local _azObj    to g_azData.
        local _mission  to g_MissionTag:Values[0].
        local _tgtInc   to 199.
        local _tgtAp    to 100000.
        local _tgtPe    to 100000. 
        local _tgtEcc   to -1. 

        if g_MissionTag:Params:Length > 0 set _tgtInc to g_MissionTag:Params[0].
        if g_MissionTag:Params:Length > 1 set _tgtAp  to g_MissionTag:Params[1].
        if g_MissionTag:Params:Length > 2
        {
            if g_MissionTag:Params[2] <= 1
            {
                set _tgtPe  to g_MissionTag:Params[2].
                set _tgtEcc to GetEccFromApPe(_tgtAp, _tgtPe).
            }
            else
            {
                set _tgtPe to GetPeFromApEcc(_tgtAp, g_MissionTag:Params[2]).
            }
        }
        else
        {
            set _tgtPe to _tgtAp.
            set _tgtEcc to 0. 
        }

        set g_azData to l_az_calc_init(_tgtAp, _tgtInc).
        set _azObj to g_azData.

        return Lexicon(
            "MSNTYPE",  _mission,
            "TGTINC",   _tgtInc,
            "TGTAP",    _tgtAp,
            "TGTPE",    _tgtPe,
            "TGTECC",   _tgtEcc,
            "AZ",       _azObj,
            "PRD",      g_PreLaunch_Data
        ). 
    }

    // ModifyLaunchParameters
    //
    global function ModifyLaunchParameters
    {
        local modifyCommit to False.
        local cancelCommit to False.

        DispLaunchConfigData(g_LaunchParams).

        local tempStr to "Modify Launch Parameters? (y / n)".
        set   tempStr to tempStr:PadLeft(Round(Terminal:Width - tempStr:Length) / 2):PadRight(Round(Terminal:Width - tempStr:Length) / 2).

        print tempStr at (Round((Terminal:Width - tempStr:Length) / 2), Terminal:Height - 5).
        print " ":PadRight(Terminal:Width - 1) at (0, Terminal:Height - 4).

        until modifyCommit or cancelCommit
        {
            GetTermChar().

            if g_TermChar = "y"
            {
                set modifyCommit to True.
            }
            else if g_TermChar = "n"
            {
                set cancelCommit to True.
            }
            set g_TermChar to "".
        }

        if cancelCommit
        {
            print " ":PadRight(Terminal:Width - 1) at (0, Terminal:Height - 5).
            set tempStr to "cancelling...".
            print tempStr at (Round((Terminal:Width - tempStr:Length) / 2), Terminal:Height - 5).
            wait 0.25. 

            print " ":PadRight(Terminal:Width - 1) at (0, Terminal:Height - 5).

            return g_LaunchParams.
        }
        else if modifyCommit
        {
            local confirmChangesFlag to false.
            local cancelChangesFlag  to false.

            // // #TODO ModifyCommit section
            // until confirmChangesFlag or cancelChangesFlag
            // {
            // }
        }
    }
// #endregion

// *- Launch Countdown
// #region

    // PreLaunchInit :: Launch event setup
    global function PreLaunchInit
    {
        parameter _tgtAp,
                  _tgtInc,
                  _azObj is list().

        // If this is a re-init, clear the existing variables
        set g_Program to 4.
        
        local launchObj to lex(
            "_tgtAp", 0
            ,"_tgtInc", 0
            ,"_azObj", list()
            ,"boosterObj", list()
        ).

        if g_TermChar = Terminal:Input:HomeCursor
        {
            if g_LoopDelegates:Events:Keys:Length > 0
            {
                g_LoopDelegates:Events:Clear.
                g_LoopDelegates:Program:Clear.
                if g_LoopDelegates:HasKey("Staging") 
                {
                    g_LoopDelegates:Remove("Staging").  
                }
            }

            set _azObj to list().
            set g_AzData to list().
        }

        ConfigureLaunchPlatform().

        // Set the steering delegate
        if _azObj:Length = 0 and g_GuidedAscentMissions:Contains(g_MissionTag:Mission)
        {
            
            
            set _azObj to l_az_calc_init(_tgtAp, _tgtInc).
            set g_AzData to _azObj.
        }
        else
        {
            set g_AzData to _azObj.
        }
        WriteJson(g_azData, arcAzDataPath).
        CopyPath(arcAzDataPath, locAzDataPath).

        set g_SteeringDelegate to GetAscentSteeringDelegate(_tgtAp, _tgtInc, g_AzData).

        local rcsModules to Ship:ModulesNamed("ModuleRCSFX").
        if rcsModules:Length > 0
        {
            local rcsArmStage to 0.
            for m in rcsModules
            {
                set rcsArmStage to Max(rcsArmStage, m:Part:Stage + 1).
            }
            local rcsCheckDel to { parameter _params to list(). if _params:length = 0 { set _params to list(Stage:Number, 0.002, 5).} if Stage:Number <= _params[0] { return Ship:Body:ATM:AltitudePressure(Ship:Altitude) <= _params[1] or g_ActiveEngines_Data:BurnTimeRemaining <= _params[2].} else { return false.}}.
            local rcsActionDel to { parameter _params is list(). RCS on. set g_RCSArmed to False. return False.}.
            local rcsEventData to CreateLoopEvent("RCSEnable", "RCS", list(rcsArmStage, 0.00325, 6), rcsCheckDel@, rcsActionDel@).
            set g_RCSArmed to RegisterLoopEvent(rcsEventData).
        }

        set g_FairingsArmed     to ArmFairingJettison("ascent").
        set g_LESArmed          to ArmLESTower().
        set g_SpinArmed         to SetupSpinStabilizationEventHandler().
        
        if Ship:PartsTaggedPattern("((Ascent\|Booster)|(ASC\|BSTR))\|"):Length > 0
        {
            set launchObj["boosterResult"] to ArmBoosterStaging("Ascent").
        }
        else
        {
            set launchObj["BoosterResult"] to list(false, { return true.}, { return false.}).
        }
        set g_HotStagingArmed   to ArmHotStaging().
        local osp to Ship:PartsTaggedPattern("^OnStage").
        set launchObj["onStageParts"] to osp.
        if osp:Length > 0
        {
            set g_OnStageEventArmed to SetupOnStageEventHandler(osp).
        }

        // Check if we have any special MECO engines to handle
        // local ascentEventParts to Ship:PartsTaggedPattern("(^Ascent\|)(?<!STGDLY)!)").
        local ascentEventParts to Ship:PartsTaggedPattern("^Ascent\|(?!STGDLY\|)").
        if ascentEventParts:Length > 0 
        {
            set launchObj["ASCENT"] to lexicon(
                "PARTS", ascentEventParts,
                "COUNT", ArmAscentEvents(ascentEventParts)
            ).
        }

        DispStateFlags().
        DispLaunchConfigData(launchObj).

        return launchObj.
    }

    // GetTerminalCountdown
    global function GetTerminalCountdown
    {
        parameter _minCountdown is 0.

        local termCount to Max(_minCountdown, countdown).
        
        for pName in countdownPreReqs:PART:Keys
        {
            if Ship:PartsNamedPattern(pName):Length > 0
            {
                set termCount to Max(termCount, countdownPreReqs:PART[pName]).
            }
        }
        for tagStr in countdownPreReqs:TAG:Keys
        {
            if Ship:PartsNamedPattern(tagStr):Length > 0
            {
                set termCount to Max(termCount, countdownPreReqs:TAG[tagStr]).
            }
        }

        return termCount.
    }

    // LaunchCountdown :: [<scalar>IgnitionSequenceStartSec] -> none
    // Performs the countdown
    global function LaunchCountdown
    {
        parameter t_engStart to -2.75.

        local launchStage to 99.
        
        local launchClamps to Ship:ModulesNamed("LaunchClamp").
        if launchClamps:Length > 0
        {
            for m in launchClamps
            {
                set launchStage to min(launchStage, m:part:stage).
            }
        }

        // OutDebug("launchStage: " + launchStage, 0).
        wait 0.5.

        local moduleNames to list("ModuleAnimateGenericExtra").
        local eventStrings to lexicon(
            "SwingArm", list(
                "retract arm"
                ,"retract arm left"
                ,"retract arm right"
            )
        ).

        local swingArms to lexicon("PARTS", lexicon(), "MODULES", lexicon(), "EVENTS", lexicon(), "KEYTIMES", lexicon()).

        for p in Ship:PartsNamedPattern("AM.MLP..*SwingArm.*")
        {
            local stopFlag to False.
            from { local i to 0.} until i >= p:AllModules:Length or stopFlag step { set i to i + 1.} do
            {
                local m to p:GetModuleByIndex(i).
                if moduleNames:Contains(m:Name)
                {
                    for evStr in m:AllEvents
                    {
                        local evStrSani to evStr:Replace("(callable) ", ""):Replace(", is KSPEvent", "").
                        if eventStrings:SwingArm:Contains(evStrSani)
                        {
                            local evStrSpl to evStrSani:Split(" ").

                            if evStrSpl:Length > 2
                            {
                                if p:Tag:Length > 0
                                {
                                    if p:Tag:Contains(evStrSpl[2])
                                    {
                                        swingArms:PARTS:Add(p:UID, p).
                                        swingArms:MODULES:Add(p:UID, m).
                                        swingArms:EVENTS:Add(p:UID, evStrSani).
                                        set stopFlag to True.
                                    }
                                }
                                else
                                {
                                    swingArms:PARTS:Add(p:UID, p).
                                    swingArms:MODULES:Add(p:UID, m).
                                    swingArms:EVENTS:Add(p:UID, evStrSani).
                                    set stopFlag to True.
                                }
                            }
                            else
                            {
                                swingArms:PARTS:Add(p:UID, p).
                                swingArms:MODULES:Add(p:UID, m).
                                swingArms:EVENTS:Add(p:UID, evStrSani).
                                set stopFlag to True.
                            }
                        }
                    }
                }
            }
        }

        local ignitionSequenceActivated   to true.
        local engSpoolLex to Lexicon().
        local nextEngStg to 99.
        local totalSpoolTime to 0.
        local maxSpoolTime to 0.
        // from { local i to Stage:Number - 1.} until i < launchStage step { set i to i - 1.} do 
        from { local i to Stage:Number.} until i < launchStage step { set i to i - 1.} do 
        {
            local stgEngs to GetEnginesForStage(i).

            if stgEngs:Length > 0
            {
                local stgMaxSpool to 0.
                local stgEngSpecs to GetEnginesSpecs(stgEngs).
                // print stgEngSpecs at(0, 50).
                // Breakpoint().
                for eng in stgEngSpecs:Engines:Values
                {
                    set stgMaxSpool  to max(stgMaxSpool, eng:SpoolTime).
                    set maxSpoolTime to max(maxSpoolTime, eng:SpoolTime).
                }
                set totalSpoolTime to totalSpoolTime + stgMaxSpool.
                set engSpoolLex[i] to stgMaxSpool.
                set nextEngStg to min(nextEngStg, i).
            }
        }
        set countdown            to maxSpoolTime + 5.
        local t_launch           to Time:Seconds + countdown.
        local launchCommitGo     to false.
        // local hasSpool           to engSpoolLex[Stage:Number - 1][0].
        // print engSpoolLex at (5, 10).
        // Breakpoint().
        // local spoolTime          to engSpoolLex[Stage:Number - 1].
        set t_engStart           to t_launch - maxSpoolTime.
        
        OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_launch, 2))).

        local l_TS to 0.

        until Time:Seconds >= t_launch and launchCommitGo
        {
            if Time:Seconds >= t_engStart 
            {
                if ignitionSequenceActivated
                {
                    if Time:Seconds > l_TS
                    {
                        // OutDebug("Doing the engine thing", 0).
                        EngineIgnitionSequence().
                        set l_TS to Time:Seconds + (engSpoolLex[Stage:Number] * 1.11).
                        // set ignitionSequenceActivated to true.
                    }

                    set ignitionSequenceActivated to Stage:Number > launchStage + 1.
                }
                else
                {
                    set launchCommitGo to LaunchCommitValidation_Next(t_launch, maxSpoolTime).
                    if launchCommitGo
                    {
                        // for p in Ship:PartsDubbedPattern("AM\.MLP.*swing.*arm.*")
                        // {
                        //     RetractSwingArms(p).
                        // }
                        for pUID in swingArms:Parts:Keys
                        {
                            if not DoEvent(swingArms:Modules[pUID], swingArms:Events[pUID])
                            {
                                RetractSwingArms(p).
                            }
                        }

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

    // WaitForLaunchCommit
    global function WaitForLaunchCommit
    {
        parameter _cd is Max(countdown, 5).

        OutMsg("[T-{0}] *** LAUNCH HOLD *** ":Format(_cd)).
        OutInfo("Waiting for launch command ").
        
        set g_TS to Time:Seconds.

        local launchTS to 0.

        local launchStrUpper to "Press [ENTER] to hopefully go to space today".
        local launchStrLower to "...or [INSERT] to change launch params".
        local launchCharsUpper to list(
            ""
            ,"*"
            ,"**"
            ,"***"
        ).
        local launchCharsLower to list(
            ""
            ,"*"
            ,"**"
            ,"***"
        ).

        local launchCommit to False.
        // local reInitLaunchConfig to False.
        until launchCommit
        {
            local idx to Mod(Round(Time:Seconds - g_TS), launchCharsUpper:Length).

            local tempStrUpper to "{0,3} {1} {0,-3}":Format(launchCharsUpper[idx], launchStrUpper).
            local tempStrLower to "{0,3} {1} {0,-3}":Format(launchCharsLower[idx], launchStrLower). 
            
            print tempStrUpper at (Round((Terminal:Width - tempStrUpper:Length) / 2), Terminal:Height - 5).
            print tempStrLower at (Round((Terminal:Width - tempStrUpper:Length) / 2), Terminal:Height - 4).

            GetTermChar().
            if not g_Debug
            {
                CheckKerbaliKode().
            }

            if g_TermChar = Terminal:Input:Enter
            {
                set launchCommit to True.
                set launchTS to Time:Seconds + _cd.
            }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                set g_TS to Time:Seconds + 3.

                OutInfo().
                until Time:Seconds > g_TS
                {
                    OutMsg("Rebooting in {0,-4}...":Format(Round(g_TS - Time:Seconds, 2))).
                    wait 0.01.
                }
                reboot.
            }
            // TODO: Modify Launch Params
            // else if g_TermChar = Terminal:Input:Backspace
            // {
            //     set g_launchParams to ModifyLaunchParameters().
            // }
            // else if g_TermChar = Terminal:Input:HomeCursor or reInitLaunchConfig
            // {
            //     OutMsg("Reinitializing launch configuration").
            //     print " ":PadRight(Terminal:Width) at (0, Terminal:Height - 5).

            //     PreLaunchInit().
            //     set reInitLaunchConfig to False.
            //     wait 0.25.
            //     OutInfo().
            //     OutMsg("Waiting for launch command").
            // }
            else if g_TermChar = Terminal:Input:DeleteRight
            {
                ResetLaunchPlatform().
                set g_TS2 to Time:Seconds + 5.
                set g_TermChar to "".
                print " ":PadRight(Terminal:Width) at (0, Terminal:Height - 5).

                local doneFlag to False.
                until doneFlag
                {
                    GetTermChar().
                    if g_TermChar = Terminal:Input:DeleteRight or g_TermChar = Terminal:Input:EndCursor
                    {
                        set doneFlag to True.
                    }
                    else if g_TS2 - Time:Seconds < 0
                    {
                        set doneFlag to True.
                    }
                    else
                    {
                        OutMsg("[{0,-4}s] Resetting launch pad configuration...":Format(Round(g_TS2 - Time:Seconds, 2))).
                    }
                    OutInfo().
                    set g_TermChar to "".
                }
                unset doneFlag.
                
                OutMsg("Waiting for launch command").
            }
            else if g_TermChar = "="
            {
                set _cd to _cd + 1.
            }
            else if g_TermChar = "-"
            {
                set _cd to _cd - 1.
            }
            set g_TermChar to "".
        }

        return launchTS.
    }



    local function LaunchCommitValidation
    {
        parameter t_liftoff to Time:Seconds + 3,
                  t_spoolTime to 0.1,
                  launchThrustThreshold to 0.982.

        // local abortFlag         to false.
        // local launchCommit      to false.
        local engPerfAbort          to t_liftoff + 5.
        local lastTS                to 0.
        local sustainedThrust       to 0.
        local sustainedThrustMet    to false.
        local sustainedThrustSet    to 0.25.
        local targetTS              to 0.
        local thrustPerf            to 0.
        
        set t_spoolTime             to max(0.09, t_spoolTime * 1.0625).

        OutInfo("Validating engine performance...").
        set g_activeEngines to GetActiveEngines(Ship).
        set t_val to 1.
        
        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            // OutDebug("Status: {0}":Format(ship:status), -5).
            until Time:Seconds > engPerfAbort
            {
                // OutDebug("TTA: {0}":Format(engPerfAbort - Time:Seconds), -4).
                wait 0.01.
                if t_spoolTime > 0.01
                {
                    set g_ActiveEngines to GetActiveEngines(Ship, "NoSRB").
                    set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines, g_ActiveEngines_Data).
                    set thrustPerf to g_ActiveEngines_Data["ThrustPct"].
                    // OutDebug("Thrust: {0}":Format(Round(thrustPerf, 3)), -3).

                    if Time:Seconds > t_liftoff
                    {
                        //OutInfo("EngStatus: {0}":Format(_engMod:GetField("Status")), 1).
                        OutInfo("[Ignition Status]: {0}":Format(g_ActiveEngines_Data["Ignition"]), 1).
                        // if g_ActiveEngines["ENGSTATUS"]["Status"] = "Failed"
                        // {
                        //     set t_val to 0.
                        //     return false.
                        // }

                        // OutDebug("Thrust: {0}":Format(thrustPerf), -3).
                        if thrustPerf >= launchThrustThreshold
                        {
                            // if sustainedThrustMet
                            // {
                                return true.
                            // }
                            // else
                            // {
                            //     set lastTS to Time:Seconds.
                            //     if sustainedThrust > 0
                            //     {
                            //         set sustainedThrust to sustainedThrust + (Time:Seconds - lastTS).
                            //         set sustainedThrustMet to sustainedThrust >= sustainedThrustSet.
                            //     }
                            //     else
                            //     {
                            //         set targetTS to Time:Seconds + sustainedThrustSet.
                            //         set sustainedThrust to targetTS - lastTS.
                            //     }
                            // }
                        }
                        else
                        {
                            set sustainedThrust to 0.
                            set sustainedThrustMet to false.
                        }
                    }
                    DispEngineTelemetry().
                }
                else if Time:Seconds >= t_liftoff
                {
                    // OutDebug("T-0: {0}":Format(True), -3).
                    return true.
                }
                OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_liftoff, 1))).
            }
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
            return true.
        }
        
        // Performance not validated by abort time, so return false.
        // OutInfo("Line 305", 1).
        return false.
    }

    
    // Next
    local function LaunchCommitValidation_Next
    {
        parameter t_liftoff to Time:Seconds,
                  t_spoolTime to 0.1,
                  _tgtThrPct to 0.99.

        // local abortFlag         to false.
        // local launchCommit      to false.
        local engPerfAbort to t_liftoff + 5.
        local thrPct to 0.
        
        set t_spoolTime             to max(0.09, t_spoolTime * 1.0625).

        OutInfo("Validating engine performance...").
        set g_activeEngines to GetActiveEngines(Ship).
        set t_val to 1.
        
        if ship:status = "PRELAUNCH" or ship:status = "LANDED"
        {
            until Time:Seconds > engPerfAbort
            {
                // set g_ActiveEngines to GetActiveEngines(Ship, "NoSRB").
                set g_ActiveEngines to GetActiveEngines(Ship).
                set g_ActiveEngines_Data to GetEnginesPerformanceData(g_ActiveEngines, g_ActiveEngines_Data).
                wait 0.01.
                set thrPct to g_ActiveEngines_Data["ThrustPct"].
                
                if t_spoolTime > 0.01
                {    
                    if Time:Seconds > t_liftoff
                    {
                        if thrPct >= _tgtThrPct
                        {
                            OutInfo("Performance validation complete", 1).
                            OutInfo("", 2).
                            wait 0.1.
                            return true.
                        }
                    }
                    OutInfo("Ignition Status [Eng Count]: {0} [{1}] ":Format(g_ActiveEngines_Data["Ignition"], g_ActiveEngines:Length), 1).
                    OutInfo("[Thrust]: {0}kn | {1}kn | {2}% ":Format(Round(Ship:Thrust,1), Round(g_ActiveEngines_Data["ThrustAvailPres"],1), Round(thrPct * 100,2)), 2).
                    DispEngineTelemetry().
                }
                else if Time:Seconds >= t_liftoff
                {
                    return true.
                }
                OutMsg("LAUNCH: T{0}s":format(round(Time:Seconds - t_liftoff, 1))).
            }
        }
        else
        {
            OutMsg("ERROR: Tried to validate launch, but already airborne!").
            return true.
        }
        
        // Performance not validated by abort time, so return false.
        // OutInfo("Line 305", 1).
        return false.
    }


    local function EngineIgnitionSequence
    {
        set t_Val to 1.
        stage.
        wait 0.01.
        set g_ActiveEngines to GetActiveEngines(Ship).
    }

// #endregion


// *- Part Module Manipulation
// #region

    // Retract Crew Arm
    global function RetractCrewArm
    {
        parameter _parts is list().

        local crewArms to choose _parts if _parts:Length > 0 else Ship:PartsNamedPattern("AM.MLP.*Crew.*Arm").
        local stopFlag to false.

        for _part in crewArms
        {
            from { local i to 0.} until i = _part:modules:length or stopFlag step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if m:Name = "ModuleAnimateGenericExtra"
                {
                    if DoEvent(m, "retract arm")
                    {
                        set stopFlag to True.
                    }
                }
            }
        }
    }   

    // Retract Swing Arms
    global function RetractSwingArms
    {
        parameter _part.

        local stopFlag to False.

        if _part:Tag:MatchesPattern("(L(eft)?$)")
        {
            from { local i to 0.} until i = _part:modules:length or stopFlag step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if m:Name = "ModuleAnimateGenericExtra"
                {
                    if DoEvent(m, "retract arm")
                    {
                        set stopFlag to True.
                    }
                    else if DoEvent(m, "retract arm left")
                    {
                        set stopFlag to True.
                    }
                    else if DoAction(m, "retract arm left", true)
                    {
                        set stopFlag to True.
                    }
                }
            }
        }
        else
        {
            from { local i to 0.} until i = _part:modules:length or stopFlag step { set i to i + 1.} do
            {
                local m to _part:GetModuleByIndex(i).
                if m:Name = "ModuleAnimateGenericExtra"
                {
                    if DoEvent(m, "retract arm")
                    {
                        set stopFlag to True.
                    }
                    else if DoEvent(m, "retract arm right")
                    {
                        set stopFlag to True.
                    }
                    else if DoAction(m, "retract arm right", true)
                    {
                        set stopFlag to True.
                    }
                }
            }
        }
    }
// #endregion

// #endregion