@lazyGlobal off.

runOncePath("0:/lib/lib_util").

//Payload
global function deploy_payload {
    wait 1. 
    until stage:number < 1 safe_stage().
}