@lazyGlobal off.

global function parse_contract_param {
    parameter c.

    //local nameFile is "0:/data/name_ref.json".
    //local nameObj to choose readjson("0:/data/name_ref.json") if exists(nameFile) else lex().
    local pname is "".
    local pflag is false.
    local bflag is false.
    local sflag is false.

    for param in c:parameters {
        print param:title.
        if param:title:startsWith("Test") {
            set pname to param:title:replace("Test ", "").
            // if nameObj:hasKey(pname) {
            //     set pname to nameObj[pname].
            if ship:partsDubbed(pname):length > 0 set pflag to true.
            else set pflag to false.
        }
            
        else if param:title = ship:body:name set bflag to true.        
        else if param:title = "Landed" or param:title = "PRELAUNCH" set sflag to true.
    }

    if pflag = true and bflag = true and sflag = true {
        return ship:partsDubbed(pname).
    } 
    else return list().
}