clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

local _tgtAmt to 100.
local _amtType to "%".

local _xfrList to list().

local _srcElement is params[0].
local _tgtElement is params[1].
local _resList to params[2].

// Parse Params
if params:length > 3
{
  set _tgtAmt to params[3].
  if params:length > 4 set _amtType to params[4].
}

//local _srcResObj to GetResources(_srcElement, _tgtElement, _resList).
//runPath("0:/main/util/transferResource", list(_srcElement, _tgtElement, _resList, _tgtAmt)).

local _srcResLex to lex().
local _tgtResLex to lex().
local elements to ship:elements.

elements:remove(ship:elements:indexOf(_srcElement:name)).

for _el in elements
{
    local _elIdx to ship:elements:indexOf(_el).
    set _srcResLex to GetElementResources(_srcElement, _resList).
    set _tgtResLex[_elIdx:toString()] to lex("Resources", GetElementResources(_el, _resList), "Transfers", lex()).
}






// Functions

local function GetElementResources
{
    parameter _el,
              _resFetchList.

    local resLex to lex().

    for res in _el:resources
    {
        if _resFetchList:contains(res:name) set resLex[res:name] to res.
    }    
    return resLex.
}


local function GetResources
{
  parameter _src,
            _tgt,
            _resList.
  
  local resObj to lexicon().
  local safe to 0.1.
  local srcResEnough to false.
  local tSpace to 0.

  for _res in _resList:split(";")
  {
    for _tRes in _tgt:resources
    {
      if _tRes:name = _res
      {
        set tSpace to floor(_tRes:capacity - _tRes:amount).
        set resObj["tgt"][_res] to list(tRes, tSpace, srcResEnough).
      }
    }

    for _sRes in _src:resources 
    {
      if _sRes:name = _res 
      {
        set srcResEnough to (_sRes:capacity - _sRes:amount) >= tSpace.
        local sResSafeAmt to _sRes:capacity * safeLimits[_res].
        if resObj:hasKey("src") set resObj["src"][_res] to list (_sRes, _sRes:amount, sResSafeAmt).
      }
    } 
  }
  return resObj.
}

local function GetTransfer 
{
  parameter _srcRes,
            _tgtRes,
            _resObj.

  local safe to 0.1.

}