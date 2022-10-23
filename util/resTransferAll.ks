clearScreen.

parameter params is list().

runOncePath("0:/lib/loadDep").

local _tgtAmt to 100.
local _amtType to "%".
local _margin to 0.10.

local _resName to params[0].
local _src is params[1].
local _tgtElements is choose list(params[2]) if params:length > 2 else list().

// Parse Params
if params:length > 3
{
  set _tgtAmt to params[3].
  if params:length > 4 set _amtType to params[4].
}
local _srcIdx to {
  from { local i to 0.} until i = _src:resources:length step { set i to i + 1.} do
  {
    if _src:resources[i]:name = _resName return i.
  }
}.
set _srcIdx to _srcIdx:call().

if ship:elements:length = 0 
{
  for el in ship:elements
  {
    if el = _src 
    {
      wait 0.01.
    }
    else
    {
      _tgtElements:add(el).
    }
  }
}

for _tgt in _tgtElements
{
  set _srcRes to _src:resources[_srcIdx].
  local _tgtIdx to {
    from { local idx to 0.} until idx = _tgt:resources:length step { set idx to idx + 1.} do
    {
      if _tgt:resources[idx]:name = _resName return idx.
    }
  }.
  set _tgtIdx to _tgtIdx:call().
  local _tgtRes to _tgt:resources[_tgtIdx].

  local _amt to choose min(_srcRes:amount * (1 - _margin), (_tgtRes:capacity * (1 - (_tgtAmt / 100))) - _tgtRes:amount) if _amtType = "%" else min(_srcRes:amount * (1 - _margin), _tgtAmt).
  
  local xfr to transfer(_srcRes:name, _src, _tgt, _amt).
  OutMsg("Press ENTER to begin transfer").
  local _done to false.
  local _srcBaseline to _srcRes:amount.
  set g_termChar to "begin".
  until _done
  {
      set _done to false.
      set _srcRes to _src:resources[_srcIdx].
      set _tgtRes to _tgt:resources[_tgtIdx].

      if (_srcBaseline - _srcRes:amount) <= 0.1 or xfr:status <> "Transferring"
      {
          OutInfo("Transfer complete!").
          set xfr:active to false.
          set _done to true.
          Breakpoint().
      }
      DispResTransfer2(_src, _srcRes, _tgt, _tgtRes, _amt, _srcBaseline, xfr:status).
      wait 0.01.
      set g_termChar to GetInputChar().
  }
}