@lazyGlobal off.

global function 
parse_contract_param {
    parameter c.

    //local nameFile is "0:/data/name_ref.json".
    //local nameObj to choose readjson("0:/data/name_ref.json") if exists(nameFile) else lex().
    local pname is "".
    local partFlag is false.
    local bodyFlag is false.
    local situFlag is false.

    for param in c:parameters {
        print param:title.
        if param:title:startsWith("Test") {
            set pname to param:title:replace("Test ", "").
            // if nameObj:hasKey(pname) {
            //     set pname to nameObj[pname].
            if ship:partsDubbed(pname):length > 0 set partFlag to true.
            else set partFlag to false.
        }
        else if param:title = ship:body:name set bodyFlag to true.        
        else if param:title = "Landed" or param:title = "Launch Site" or param:title = "PRELAUNCH" set situFlag to true.
    }

    if partFlag = true and bodyFlag = true and situFlag = true {
        return ship:partsDubbed(pname).
    } 
    else return list().
}