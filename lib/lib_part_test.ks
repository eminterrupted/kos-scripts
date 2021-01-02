global function test_part {
    parameter p.

    local tMod is "ModuleTestSubject".

    if p:hasModule(tMod) {
        local m is p:getModule(tMod).

        if m:hasEvent("run test") {
            m:doEvent("run test").
        }

        else {
            if p:stage = stage:number - 1 stage.
            else if p:stage = stage:number - 2 {
                stage. 
                stage.
            }

            else if p:stage = stage:number - 3 {
                stage.
                stage.
                stage.
            }
        }
    }
}
