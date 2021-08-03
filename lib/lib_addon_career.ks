@lazyGlobal off.
// Functions related to the Career addon from here: https://github.com/JonnyOThan/kOS-Career
// Uses the namespace of the function type vs. the library name as in other places

// Parses contracts for test parts, and if available on the vessel, 
// returns those in a list. Can take an input list to add to, defaults
// to a new list. Returns empty list if contract addon not available
global function test_contract_parts
{
    parameter partList is list().

    if addons:career:available 
    {
        local contracts to addons:career:activeContracts.
        
        // Iterate over the ship's parts then the contracts to see if 
        // any parts are in test contracts
        for p in ship:parts 
        {
            for c in contracts 
            {
                if c:title:contains("test") or c:title:contains("haul") 
                {
                    if c:title:contains(p:title) 
                    {
                        if not partList:contains(p) 
                        {
                            partList:add(p).
                        }
                    }
                }
            }
        }
    }   
    else 
    {
        return partList().
    }
}