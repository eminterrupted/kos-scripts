@lazyGlobal off.
clearScreen.

parameter params to list().


runOncePath("0:/lib/burnCalc").
runOncePath("0:/lib/disp").
runOncePath("0:/lib/globals").
runOncePath("0:/lib/util").
runOncePath("0:/lib/vessel").
runOncePath("0:/lib/launch").
runOncePath("0:/lib/setup").

// local testFile to Path("0:/test/runFiles/testFile.ks").
// if exists(testFile) deletePath(testFile).
// log "print " + funcToTest + "." to testFile.

// local p0 to "HASH THIS".

// local kMut to { parameter p. return p + 1.}. 
// local vMut to { parameter p. if p:length < 20 { return p:tostring + "-".} else { return "".}}.
// if params:length > 0 
// {
//     set p0 to params[0].
//     if params:length > 1 set p1 to params[1].
//     if params:length > 2 set p2 to params[2].   
// }

set g_line to 0.
local _walkList to list().

print "FUNCTION TEST SCRIPT     v0.000001b" at (0, g_line).
print "======================================" at (0, cr()).
cr().
print "Function: GetPatchesForNode" at (0, cr()).
cr().
print GetPatchesForNode(nextNode) at (0, cr()).
print "*** END OF TEST ***" at (0, cr()).

// GetChildPartTree :: <part>Part, [<string>SearchString], [<int>Stage] -> List<Parts>



// GetPartTree :: <part>Part, List<Parts>, [<int>Stage] -> List<Parts>
// Returns the part tree starting from the provided part with optional stage limiter to stop 
// from walking too far
local function GetPartTree
{
    parameter _parent,
              _treeList,
              _stgLim to -1.
   
    for p in _parent:children
    {
        if p:decoupledIn >= _stgLim
        {
            _treeList:add(p).
            if p:children:length > 0 
            {
                for c in p:children 
                {
                    _treeList:add(GetPartTree(c, _treeList)).
                }
            }
        }
    }
    return _treeList.
}

//DispList(MakeArray(len, startVal, kMut@), tip).

// {
//     local ts to time:seconds.
//     local velo to ship:velocity:surface:mag.
    
//     print resultLine:Format("GFORCE:", CalcGForce(ts, velo)).
// }

// global function CalcGForce
// {
//     parameter lastTS,
//               lastVelo.

//     local dv is ship:velocity:surface:mag - lastVelo.
//     set lastVelo to ship:velocity:surface:mag.
//     local dt to max(time:seconds - lastTS, 0.01).
//     return dv/dt / constant:g0.
// }

// local iterCount to PromptCursorSelect("ITERATION COUNT", list(1, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250), p0).
// cr().
// print "Press Enter to begin" at (0, cr()).
// Pause().
// clr(g_line).
// cr().
// print "Running tests" at (0, g_line).

// print resultLine:format(" ","Total Dur", "Avg Dur") at (0, cr()).
// print resultLine:format("---------------", "----------", "----------") at (0, cr()).

// // Run the old test
// local resultOld to PrintScrOld("                                                            ", cr()).
// print resultLine:format("Old", resultOld:dur, resultOld:avgDur) at (0, g_line).

// // Run the new test
// local resultNew to PrintScrNew("", cr()).
// print resultLine:format("New", resultNew:dur, resultNew:avgDur) at (0, g_line).
// cr().

// local winner to choose "new" if resultNew:dur < resultOld:dur else "old".
// print "Winner: {0}":format(winner:toupper) at (0, cr()).
// print "Delta : {0}":format(abs(resultOld:dur - resultNew:dur)) at (0, cr()).


// // Call the old method of printing
// local function PrintScrOld
// {
//     parameter str, line.

//     local startTime to time:seconds.
//     from { local i to 0.} until i >= iterCount step { set i to i + 1.} do 
//     {
//         print str at (0, line).
//     }
//     local endTime to time:seconds.
    
//     return lex(
//         "iterCount", iterCount
//         ,"startTime", startTime
//         ,"endTime", endTime
//         ,"dur", round(endTime - startTime, 5)
//         ,"avgDur", round((endTime - startTime) / iterCount, 5)
//     ).
// }

// local function PrintScrNew
// {
//     parameter str,
//               line.

//     local testStr to "{0, " + (-terminal:width) + "}".
//     local startTime to time:seconds.
//     from { local i to 0.} until i >= iterCount step { set i to i + 1.} do 
//     {
//         print testStr:format(str) at (0, line).
//     }
//     local endTime to time:seconds.
    
//     return lex(
//         "iterCount", iterCount
//         ,"startTime", startTime
//         ,"endTime", endTime
//         ,"dur", round(endTime - startTime, 5)
//         ,"avgDur", round((endTime - startTime) / iterCount, 5)
//     ).
// }

// print "FUNCTIONAL TEST SCRIPT    v0.000001a".
// print "====================================".
// print " ".
// print "Testing function: PromptTextEntry()".
// local bCores to PromptTextEntry("PromptTest", "TEST PROMPT").

// print "RESULT: [" + bCores + "]". 


//runPath(testFile).

// -- cleanup --//
//deletePath(testFile).

//print CheckPartSet(params:join(""",""")).

// local function GetPartSetCount
// {
//     parameter setTag is "".

//     local pCount to 0.
//     local pList to list().
//     local stepCount to 0.

//     if setTag = ""
//     {
//         set pList to ship:parts.
//     }
//     else
//     {
//         set pList to ship:partsTaggedPattern(setTag + ".*\.{1}\d+").
//     }

//     for p in pList
//     {
//         local parsedTag to p:Tag:Split(".").
//         //local stepIdx to p:tag:LastIndexOf(".").
//         //local step to p:Tag:Substring(stepIdx + 1, p:tag:length - stepIdx - 1).
//         if parsedTag:length > 0 
//         {
//             local step to parsedTag[parsedTag:length - 1]:toNumber(0).
//             set stepCount to max(stepCount, step).
//         }
//         if p:hasModule("ModuleAnimateGeneric") or p:hasModule("USAnimateGeneric") // Generic and bays
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleRTAntenna")   // RT Antennas
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleDeployableSolarPanel")    // Solar panels
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleResourceConverter") // Fuel Cells
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleGenerator") // RTGs
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleDeployablePart")  // Science parts / misc
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleRoboticServoHinge")
//         {
//             set pCount to pCount + 1.
//         }
//         else if p:hasModule("ModuleRoboticServoRotor")
//         {
//             set pCount to pCount + 1.
//         }
//     }

//     return list(pCount, stepCount).
// }