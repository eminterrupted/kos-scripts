parameter clist.

for contract in clist {
    if contract:title:startsWith("Test") {
        set plist to parse_contract_param(contract).
        if plist <> "" {
            print "Contract: [" + contract:title + "]".
            print "Part from contract found on vessel: [" + plist[0] + "]".
            print " ".
        }

        else {
            print "Contract: [" + contract:title + "]".
            print "Part from contract NOT found on vessel".
            print " ".
        }
    }
}

global function parse_contract_param {
    parameter c.

    local nameObj to readjson("0:/data/name_ref.json").
    local pname is "".
    local pflag is false.
    
    for param in c:parameters {
        print param:title.
        if param:title:startsWith("Test") {
            set pname to param:title:replace("Test ", "").
            if nameObj:hasKey(pname) {
                set pname to nameObj[pname].
                if ship:partsNamed(pname):length > 0 set pflag to true.
                else set pflag to false.
            }

            else set pflag to false.
        }
            
        else if param:title = ship:body:name set bflag to true.        
        else if param:title = "Landed" or param:title = "PRELAUNCH" set sflag to true.
    }

    if pflag = true and bflag = true and sflag = true {
        return ship:partsNamed(pname).
    } 
    else return "".
}