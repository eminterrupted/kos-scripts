    local axisNum to draws[draws:length - 1]:length - 1.
    until axisNum < 0 {
        local thisOne to draws[draws:length - 1][axisNum].
        set thisOne:show to false.
        draws[draws:length - 1]:remove(axisNum).
        set axisNum to axisNum -1.
    }

    draws:remove(draws:length - 1).