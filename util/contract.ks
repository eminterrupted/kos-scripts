@lazyGlobal off.
clearScreen.

local parameter _type is "any",
                _val is "".

local contracts to addons:career:activeContracts.

local delAll        to { parameter _cP. return _cP. }.
local delAny        to { parameter _cP. if _cP:contains(_val) return true. else return false. }.
local delBody       to { parameter _cP. if _cP:matchesPattern("Destination: {0}":format(_val)) return true. else return false. }.
local delCrewed     to { parameter _cP. if _cP:matchesPattern("Destination: .*") return true. else return false. }.

local _typeDel      to delAll@.
if _type = "body" set _typeDel to delBody@.

from { local i to 0.} until i = contracts:length step { set i to i + 1.} do
{
    local c to contracts[i].
    from { local iP to 0.} until iP = c:parameters:length step { set iP to iP + 1.} do
    {
        local cP to c:parameters[iP].
        //print "_cP Title: [{0}]":format(cP:title).
        if _typeDel:call(cP:title)
        {
            print "[{0}] {1} ":format(i, c:title).
            print "    {0} - {1} ":format(iP, cP:title).
            print " ".
        }
    }
}