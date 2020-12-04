@lazyGlobal off.

runOncePath("0:/lib/lib_core").

//Payload
global function deploy_payload {
    wait 1. 
    until stage:number < 1 safe_stage().
}