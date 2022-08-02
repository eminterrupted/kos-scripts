@lazyGlobal off. 

// Science library

// Dependencies
runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

// Globals
global SciExpSituMap to lex(

    // ExperimentId         (SituMask, BiomeMask, RequiresAtmosphere)
    
    // Stock
    "crewReport",           list(63, 23, 0)
    ,"evaReport",           list(59, 3, 0)
    ,"mysteryGoo",          list(63, 3, 0)
    ,"surfaceSample",       list(3,  3, 0)
    ,"mobileMaterialsLab",  list(63, 3, 0)
    ,"temperatureScan",     list(63, 7, 0)
    ,"barometerScan",       list(31, 3, 0)
    ,"seismicScan",         list(1,  1, 0)
    ,"gravityScan",         list(51, 51, 0)
    ,"atmosphereAnalysis",  list(13, 13, 1)
    ,"asteroidSample",      list(63, 7, 0)
    ,"cometSample_short",   list(63, 7, 0)
    ,"cometSample_intermediate", list(63, 7, 0)
    ,"cometSample_long",    list(63, 7, 0)
    ,"cometSample_interstellar", list(63, 7, 0)
    ,"infraredTelescope",   list(32, 0, 0)
    ,"magentometer",        list(51, 1, 0)
    ,"evaScience",          list(63, 0, 0)
    
    // DMagic
    ,"AnomalyScan",         list(0, 0, 0)
    ,"dmAsteroidScan",      list(0, 0, 0)
    ,"dmbiodrillscan",      list(1, 1, 1)
    ,"dmImagingPlatform",   list(48, 16, 0)
    ,"dmlaserblastscan",    list(3, 3, 0)
    ,"dmNAlbedoScan",       list(1, 1, 0)
    ,"dmReconScan",         list(16, 0, 0)
    ,"dmRadiometerScan",    list(32, 0, -1)
    ,"dmseismicHammer",     list(1, 1, 0)
    ,"dmSIGINT",            list(16, 0, 0)
    ,"dmSoilMoisture",      list(16, 0, 0)
    ,"dmSolarParticles",    list(48, 0, -1)
    ,"dmXRayDiffract",      list(1, 1, 0)
    ,"rpwsScan",            list(48, 0, 0)
    ,"scopeScan",           list(48, 16, 0)

    // KURS
    ,"TargetScanning",      list(63, 31, 0)
    
    // Kiwi Kerbalism
    // ,"kiwi_gasAnalyzer",    list(63, 3)
    // ,"kiwi_hydrometer",     list(63, 7)
    // ,"kiwi_photometry",     list(63, 7)
    // ,"kiwi_photopolarimeter",list(63, 7)
    // ,"kiwi_gammaRay",       list(48, 1)
    // ,"kiwi_cosmicRay",      list(48, 1)
    // ,"kiwi_IRspec",         list(48, 1)
    // ,"kiwi_ionElec",        list(24, 1)
    // ,"kiwi_UVspec",         list(48, 1)
    // ,"kiwi_solarWind",      list(32, 1)
    // ,"kiwi_soilScoop",      list(3, 3)

    // Scansat
    ,"SCANsatAltimetryLoRes",   list(0, 0, 0)
    ,"SCANsatAltimetryHiRes",   list(0, 0, 0)
    ,"SCANsatBiomeAnomaly",   list(0, 0, 0)
    ,"SCANsatResources",    list(0, 0, 0)
    ,"SCANsatVisual",       list(0, 0, 0)

    // SSPX
    ,"sspxFishStudy",       list(51, 0, 0)
    ,"sspxPlantGrowth",     list(51, 0, 0)
    ,"sspxVisualObservation", list(51, 7, 0)
    ,"sspxTelescopeObservation", list(51, 7, 0)


    // Tantares
    // ,"insectStorage",       list(56, 0, 0)
    ,"tantares_laser_reflector", list(63, 7, 0)
    ,"tantares_visible_light_camera", list(63, 7, 0)
    ,"tantares_visible_light_camera_0", list(63, 7, 0)
    ,"tantares_visible_light_camera_2", list(63, 7, 0)
    ,"tantares_ultraviolet_light_camera", list(63, 7, 0)
    ,"tantares_ultraviolet_light_camera_0", list(63, 7, 0)
    ,"tantares_ultraviolet_light_camera_2", list(63, 7, 0)
    ,"tantares_infrared_light_camera", list(63, 7, 0)
    ,"tantares_infrared_light_camera_0", list(63, 7, 0)
    ,"tantares_infrared_light_camera_2", list(63, 7, 0)
    ,"tantares_sp_ion_trap", list(63, 7, 0)
    ,"tantares_sp_photometer", list(63, 7, 0)
    ,"tantares_sp_laser_reflector", list(63, 7, 0)
    ,"tantares_sp_cosmic_ray_detector", list(63, 7, 0)
    ,"tantares_sp_xray_spectrometer", list(63, 7, 0)
    ,"tantares_sp_gamma_ray_spectrometer", list(63, 7, 0)

    // TST
    ,"TarsierSpaceTech.SpaceTelescope", list(48, 7, 0)
    ,"TarsierSpaceTech.ChemCam", list(1, 1, 0)

    // US2 Science
    ,"USmapCam",            list(16, 7, 0)
    ,"USlaserAltimeter",    list(16, 7, 0)
    ,"USCameraPicture",     list(48, 16, 0)

    // Misc
    ,"kdex",                list(63, 21, 0)
    ,"telemetryReport",     list(63, 15, 0)
).

global SciParReqMap to lex(
    "dmUS2GoreSat", 8
    ,"dmUS2Scope", 8
).

global SciExpIdMap to lex(
    // experimentId, action String
    "Crew Report",                          "crewReport"
    ,"EVA Report",                          "evaReport"
    ,"Observe Mystery Goo",                 "mysteryGoo"
    ,"Take Surface Sample",                 "surfaceSample"
    ,"Conduct Materials Study",             "mobileMaterialsLab"
    ,"Log Temperature",                     "temperatureScan"
    ,"Log Pressure Data",                   "barometerScan"
    ,"Log Seismic Data",                    "seismicScan"
    ,"Log Gravity Data",                    "gravityScan"
    ,"Run Atmosphere Analysis",             "atmosphereAnalysis"
    ,"Log Observation Data",                "infraredTelescope"
    ,"Run Magnetometer Report",             "magentometer"
    ,"Perform EVA Science",                 "evaScience"

    // DMagic           
    ,"Collect Anomalous Data",              "AnomalyScan"
    ,"Collect Core Sample",                 "dmbiodrillscan"
    ,"Log Imaging Data",                    "dmImagingPlatform"
    ,"Collect Laser Data",                  "dmlaserblastscan"
    ,"Collect Hydrogen Data",               "dmNAlbedoScan"
    ,"Collect Stereo Recon Data",           "dmReconScan"
    ,"Log Irradiance Scan",                 "dmRadiometerScan"
    ,"Collect Seismic Data",                "dmseismicHammer"
    ,"Collect Radio Data",                  "dmSIGINT"
    ,"Collect Soil Moisture Data",          "dmSoilMoisture"
    ,"Collect Solar Particles",             "dmSolarParticles"
    ,"Collect X-Ray Data",                  "dmXRayDiffract"
    ,"Log Radio Plasma Wave Data",          "rpwsScan"
    ,"Log Visual Observations",             "scopeScan"

    // KURS         
    ,"Scan Target",                         "TargetScanning"

    // SSPX         
    ,"Observe Species",                     "sspxFishStudy"
    ,"Observe Plant Growth",                "sspxPlantGrowth"
    ,"Visual Scan",                         "sspxVisualObservation"
    ,"Observe Local Space",                 "sspxTelescopeObservation"


    // Tantares
    // ,"insectStorage",       list(56, 0)
    ,"Log Laser Reflector Data",            "tantares_laser_reflector"
    ,"Log Visible Light Data",              "tantares_visible_light_camera"
    ,"Log Ultraviolet Light Data",          "tantares_ultraviolet_light_camera"
    ,"Log Infrared Light Data",             "tantares_infrared_light_camera"
    ,"Log Charged Particles Data",          "tantares_sp_ion_trap"
    ,"Log Light Data",                      "tantares_sp_photometer"
    ,"Log Measurements Data",               "tantares_sp_laser_reflector"
    ,"Log Cosmic Ray Data",                 "tantares_sp_cosmic_ray_detector"
    ,"Log X-Ray Data",                      "tantares_sp_xray_spectrometer"
    ,"Log Gamma Ray Data",                  "tantares_sp_gamma_ray_spectrometer"

    // US2 Science
    ,"Take a picture",                      "USmapCam"
    ,"Start Laser Altimeter Measurements",  "USlaserAltimeter"
    ,"Take a picture",                      "USCameraPicture"

    // Misc             
    ,"Run Dust Analysis",                   "kdex"
    ,"Telemetry Report",                    "telemetryReport"
).

// Functions 

// Modules
global function GetSciModules
{
    local sciList to list().
    for m in ship:modulesNamed("ModuleScienceExperiment")           sciList:add(m).
    for m in ship:modulesNamed("DMModuleScienceAnimate")            sciList:add(m).
    for m in ship:modulesNamed("DMSoilMoisture")                    sciList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageScience")         sciList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageSoilMoisture")    sciList:add(m).
    for m in ship:modulesNamed("DMSoilMoisture")                    sciList:add(m).
    for m in ship:modulesNamed("DMRoverGooMat")                     sciList:add(m).
    for m in ship:modulesNamed("USSimpleScience")                   sciList:add(m).
//    for m in ship:modulesNamed("DMSeismicSensor")                   sciList:add(m).
    for m in ship:modulesNamed("DMXrayDiffract")                    sciList:add(m).
    for m in ship:modulesNamed("USAdvancedScience")                 sciList:add(m).
    for m in ship:modulesNamed("ModuleSpyExperiment")               sciList:add(m).
    for m in ship:modulesNamed("DMSeismicHammer")                   sciList:add(m).
    return sciList.
}

// GetSciModulesForSituation
global function GetSciModulesForCurrentSituation
{
    local sciList to list().
    local stepList to list().

    for m in ship:modulesNamed("ModuleScienceExperiment")           stepList:add(m).   
    for m in ship:modulesNamed("DMModuleScienceAnimate")            stepList:add(m).
    for m in ship:modulesNamed("DMSoilMoisture")                    stepList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageScience")         stepList:add(m).
    for m in ship:modulesNamed("DMUniversalStorageSoilMoisture")    stepList:add(m).
    for m in ship:modulesNamed("DMSoilMoisture")                    stepList:add(m).
    for m in ship:modulesNamed("DMRoverGooMat")                     stepList:add(m).
    for m in ship:modulesNamed("USSimpleScience")                   stepList:add(m).
    for m in ship:modulesNamed("DMXrayDiffract")                    stepList:add(m).
    for m in ship:modulesNamed("USAdvancedScience")                 stepList:add(m).
    for m in ship:modulesNamed("ModuleSpyExperiment")               stepList:add(m).
    for m in ship:modulesNamed("DMSeismicHammer")                   stepList:add(m).

    local trackedIds to uniqueSet().

    for m in stepList
    {
        for a in m:allActions
        {
            local aSani to a:Substring(11, a:length - 11 - 14).
            if SciExpIdMap:Keys:Contains(aSani)
            {
                local expId to SciExpIdMap[aSani].
                if not trackedIds:contains(expId)
                {
                    local expSitu to SciExpSituMap[expId].
                    if CheckCurrentSituationDetailed(expSitu) > 0
                    {
                        sciList:add(m).
                        trackedIds:add(expId).
                    }
                }
            }
            else
            {
                OutInfo2("aSani miss: " + aSani).
                wait 0.25.
            }
        }
    }

    return sciList.
}

// Deploy
global function DeploySciList
{
    parameter sciList.

    for m in sciList
    {
        OutInfo().
        OutInfo2().
        if m:name:startsWith("US")
        {
            OutTee("Running US science experiment for: " + m:part:title + " (" + m:name + ")").
            DeployUSSci(m).
        }
        else if m:name:startsWith("DM")
        {
            OutTee("Running DM science experiment for: " + m:part:title + " (" + m:name + ")").
            DeployDMSci(m).
        }
        else if m:name = "ModuleSpyExperiment"
        {
            OutTee("Running Spy Experiment for: " + m:part:title + " (" + m:name + ")").
            DeploySpySci(m).
        }
        else
        {
            OutTee("Running generic science experiment for: " + m:part:title + " (" + m:name + ")").
            DeploySci(m).
        }
    }
}

// Recover
global function RecoverSciList
{
    parameter sciList,
              mode is "ideal".

    for m in sciList
    {
        RecoverSciMod(m, mode).
    }
    OutInfo().
    OutMsg("SciList Recovery Completed").
}

global function RecoverSciList2
{
    parameter sciList,
              mode is "ideal".

    local allowedVals to list("ideal", "collect", "transmit", "tx", "txAll", "txForce").
    for m in sciList
    {
        local mTag to m:part:tag:split(".").
        if mTag[0] = "science"
        {
            if allowedVals:contains(mTag[1]) 
            {
                set mode to mTag[1].
            }
        }
        
        RecoverSciMod(m, mode).
    }
    OutInfo().
    OutMsg("SciList Recovery Completed").
}

global function RecoverSciMod
{
    parameter sciMod,
              mode is "ideal".

    if sciMod:hasSuffix("HASDATA")
    {
        if sciMod:hasData
        {
            if mode = "transmit" or mode = "tx"
            {
                local transmitFlag to false.
                until transmitFlag
                {
                    local ecValidation to list(0, 0, 0).//ValidateECForTransmit(m).
                    if ecValidation[0] = 0
                    {
                        OutMsg("Validating EC for science transmission").
                        OutInfo("EC Required: " + ecValidation[1]).
                        set transmitFlag to true.
                    }
                }
                OutTee("Transmitting data from " + sciMod:part:title + " (" + sciMod:name + ")").
                if TransmitSci(sciMod) 
                {
                    OutTee("Transmission successful!").
                }
                else 
                {
                    OutTee("Transmission failed!", 0, 2).
                }
            }
            else if mode = "ideal"
            {
                if sciMod:data[0]:transmitValue > 0 and sciMod:data[0]:transmitValue = sciMod:data[0]:scienceValue
                {
                    // local transmitFlag to false.
                    // until transmitFlag
                    // {
                    //     local ecValidation to ValidateECForTransmit(m).
                    //     if ecValidation[0] = 0
                    //     {
                    //         OutMsg("Validating EC for science transmission").
                    //         OutInfo("EC Required: " + ecValidation[1]).
                    //         set transmitFlag to true.
                    //     }
                    // }
                    OutTee("Transmitting data from " + sciMod:part:title + " (" + sciMod:name + ")").
                    if TransmitSci(sciMod)
                    {
                        OutTee("Transmission successful!").
                    }
                    else 
                    {
                        OutTee("Transmission failed!", 0, 2).
                    }
                }
                else if sciMod:data[0]:scienceValue > 0
                {
                    CollectSci().
                    if sciMod:hasEvent("transfer data") 
                    {
                        OutTee("Resetting science module: " + sciMod:name + " (Part: " + sciMod:part:title + ")").
                        ResetSci(sciMod).
                    }
                }
                else 
                {
                    OutTee("Resetting science module: " + sciMod:name + " (Part: " + sciMod:part:title + ")").
                    ResetSci(sciMod).
                }
            }
            else if mode = "collect"
            {
                OutTee("Collecting experiment results from module: " + sciMod:name + " (Part: " + sciMod:part:title + ")").
                CollectSci().
            }
        }
    }
}

// Delete data
global function ClearSciList
{
    parameter sciList. 

    for m in sciList
    {
        m:reset().
        local ts to time:seconds + 5.
        wait until not m:HasData or time:seconds > ts.
    }
}

// Local functions

// Collect
local function CollectSci
{
    local sciBoxList to ship:modulesNamed("ModuleScienceContainer").
    local sciBox to 0.
    local sciBoxPresent to choose true if sciBoxList:length > 0 else false.
    
    if sciBoxPresent
    {
        for m in sciBoxList
        {
            set sciBox to m.
            if sciBox:part = ship:rootPart 
            {
                break.
            }
        }
    }

    if sciBoxPresent
    {
        sciBox:doAction("collect all", true).
        if sciBox:hasEvent("container: transfer data") 
        {
            return true.
        }
        else 
        {
            return false.
        }
    }
    return false.
}


// Deploy
local function DeploySci
{
    parameter m.

    if not m:hasData
    {
        if m:HasSuffix("deploy") and not m:inoperable
        {
            m:deploy().
        }
        else if m:hasEvent("start laser altimeter measurements")
        {
            DoEvent("start laser altimeter measurements").
        }
        local ts to time:seconds + 5.
        wait until m:hasData or time:seconds >= ts.
        if addons:career:available addons:career:closeDialogs.
    }
}

local function DeployDMHammer
{
    parameter m.

    local podList to ship:modulesNamed("DMSeismicSensor").
    for pod in podList
    {
        DoAction(pod, "Arm Pod").
        if pod:Part:HasModule("ModuleAnchoredDecoupler")
        {
            DoEvent(pod:Part:GetModule("ModuleAnchoredDecoupler"), "decouple").
        }
    }

    wait 5.
    
    m:toggle.
    wait 4.
    DoAction(m, "Arm Hammer").
    wait 1.
    DoAction(m, "Collect Seismic Data").
    wait until m:hasData.
}

local function DeployDMSci
{
    parameter m.

    if m:HasData
    {
        return false.
    }
    else
    {
        if m:name = "DMSeismicHammer"
        {
            OutTee ("Running DM Seismic Hammer Experiment").
            DeployDMHammer(m).
        }
        else if m:name <> "DMSeismicPod"
        {
            m:deploy.
            local ts to time:seconds + 10.
            until m:hasData
            {
                if time:seconds > ts
                {
                    OutInfo2("WARN: Science Experiment timeout").
                    break.
                }
                else if m:hasData 
                {
                    OutInfo2("Data collected!").
                }
            }
        }
        if addons:career:available addons:career:closeDialogs.
    }
}

local function DeploySpySci
{
    parameter m.

    DoAction(m, "scan target").
    wait 0.1. 
    if addons:available("Career") addons:career:closeDialogs().
}

local function DeployUSSci
{
    parameter m.

    local deployList  to list("log", "observe", "conduct", "open service door", "take a picture").

    for action in m:allActions
    {
        for validAction in deployList
        {
            local trimmedAction to action:replace("(callable) ", ""):replace(", is KSPAction", "").
            if trimmedAction:contains(validAction) 
            {
                m:doAction(trimmedAction, true).
                local ts to time:seconds + 5.
                wait until m:hasData or time:seconds >= ts .
                if addons:career:available addons:career:closeDialogs.
            }

            if trimmedAction = "deploy service door"
            {
                wait 2.
            }
        }
        wait 0.05. 
        if addons:available("Career") addons:career:closeDialogs().
    }
}


// Reset
local function ResetSci
{
    parameter m.
    
    if m:name <> "TSTChemCam" 
    {
        m:reset().
        local ts to time:seconds + 5.
        wait until time:seconds > ts or not m:hasData.
    }
    RetractSci(m).
}

local function RetractSci
{
    parameter m.

    local retractList to list("close", "retract", "stow").

    for action in m:allActions
    {
        for validAction in retractList
        {
            if action:contains(validAction)
            {
                m:doAction(action:replace("(callable) ", ""):replace(", is KSPAction",""), true).
            }
        }
    }
}

// TO-DO 
// Transfer science from a given module to a target container. 
// Defaults to first container in list
// local function TransferSci
// {
//     parameter m,
//               sciBox is ship:modulesNamed("ModuleScienceContainer")[0].

    
// }

// Transmit
local function TransmitSci
{
    parameter m.

    if m:hasData
    {
        m:transmit().
        wait until not m:hasData.
        wait 0.01.
        return true.
    }
    else
    {
        return false.
    }
}

local function ValidateECForTransmit
{
    parameter sciMod.

    local maxPacketCost to 0.
    local maxPacketInt  to 0.
    local maxPacketSize to 0.
    local numUploads    to 0.
    local uploadCost    to 0.
    local uploadTime    to 0.

    local sciMits to sciMod:Data[0]:DataAmount.

    if Ship:ModulesNamed("ModuleRTAntenna"):Length > 0
    {
        for m in ship:ModulesNamed("ModuleRTAntenna")
        {
            if m:GetField("status") = "Connected" 
            {
                set maxPacketCost to max(m:GetField("science packet cost"):toNumber(10), maxPacketCost).
                set maxPacketInt  to max(m:GetField("science packet interval"):toNumber(0.3), maxPacketInt).
                set maxPacketSize to max(m:GetField("science packet size"):toNumber(1), maxPacketSize).
            }
        }

        set numUploads   to sciMits / maxPacketSize.
        set uploadCost   to numUploads * maxPacketCost.
        set uploadTime   to numUploads * maxPacketInt.

        print "Part Module      : " + sciMod:part:name + "         " at (0, 25).
        print "Data Qty (Mits)  : " + sciMits     + "    " at (0, 26).
        print "Packet Cost      : " + maxPacketCost + "   " at (0, 27).
        print "Packet Interval  : " + maxPacketInt  + "   " at (0, 28).
        print "Upload Count     : " + round(numUploads) + "   " at (0, 29).
        print "Upload Cost      : " + round(uploadCost, 1) + "     " at (0, 30).
        print "Upload Time      : " + round(uploadTime, 1) + "     " at (0, 31).

        if uploadCost < Ship:ElectricCharge + 20
        {
            print "EC validation cleared               " at (0, 33).
            return list(0, uploadCost, uploadTime).
        }
        else
        {
            print "EC validation failed                " at (0, 33).
            return list(1, uploadCost, uploadTime).
        }
    }
    print "EC validation: No antennas detected!" at (0, 33).
    return list(2, 0, 0).
}