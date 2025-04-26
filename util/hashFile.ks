@LazyGlobal off.


parameter _inputPath,
          _hashType is 0, // 0: Binary Total  Value : Adds up the value of all bytes in a file to get a "total" number that if any byte changes, should end up different
                          // 1: Binary Unique Value: Adds up the value of all unique bytes found in a file.
                          // 2: Binary Diff   Value: Adds up the absolute difference from one value to the next of all bytes found in a file.
                          // 3: Binary Change Value: Adds up the number of times a subsequent byte changes value
                          // 4: Binary Incremental : Compares two adjacent bytes, and adds +1 if the second byte is higher than the first, -1 if lower, and 0 if the same.
                          // 9: Loops through all of the above and displays the resulting outputs in a table
          _showProgress is 0, // 1 enables progress on screen in hash delegates
          _showTimeStats is 1,
          _tempEnableMaxIPU is true. // 1 or true will set max IPU to 2000 until the script is complete then will reset to the existing value.

local cachedIPU to Config:IPU.

if _tempEnableMaxIPU {

    set Config:IPU to 2000.
}

local hashMethods to lexicon(
    0, list("BinaryTotal",          sum_binary_total@       ),
    1, list("BinaryUnique",         sum_binary_unique@      ),
    2, list("BinaryDiff",           sum_binary_diff@        ),
    3, list("BinaryChange",         sum_binary_change@      ),
    4, list("BinaryIncremental",    sum_binary_incremental@ )
).

if _showProgress > 0 ClearScreen.

print "hashFile.ks" at (2, 0).

if Exists(_inputPath) {

    local inputHandle to Open(_inputPath).
    local inputContent to inputHandle:ReadAll.
    local inputBinary to inputContent:Binary.
    
    local selectedMethods to lexicon().

    if _hashType = 9 
    {
        for hsh in hashMethods:Keys {
            print "MultiHash mode" at (2, 2).

            selectedMethods:Add(hsh, hashMethods[hsh]).
        }
    } else {

        selectedMethods:Add(_hashType, hashMethods[_hashType]).
    }
    
    local colAnchor to 15.
    local colIncr   to 15.

    print "Calculating hash(es) for file: {0}":Format(_inputPath) at (0, 4).
    print "Byte count  : " at (0, 10). 
    print "Hash result : " at (0, 12). 

    local _ts to Time:Seconds.

    from { local i to 0.} until i = selectedMethods:Keys:Length step { set i to i + 1.} do {
        
        local hashKey to selectedMethods:Keys[i].
        local activeHash to selectedMethods[hashKey].

        local curCol to colAnchor + (colIncr * i).
        print "{0,13} ":Format(activeHash[0]) at (curCol, 8).
        local _ts1 to Time:Seconds.
        local binaryHash to activeHash[1]:Call(inputBinary, _showProgress).
        local _ts2 to Time:Seconds. 
        if _showTimeStats {
            print "  ( {0,3} s )  ":Format(TimeSpan(Round(_ts2 - _ts1, 2)):seconds) at (curCol, 9).
        }
        print "[{0,9}] ":Format(inputBinary:Length) at (curCol, 10).
        print "[{0,9}] ":Format(binaryHash) at (curCol, 12).

    }
    set _ts to Time:Seconds - _ts.
    print "Total Duration: {0} ":Format(TimeSpan(_ts):Full) at (0, 4).
} else {
    print "Invalid input file, ya doofus" at (2, 2).
}

if _tempEnableMaxIPU {

    set Config:IPU to cachedIPU.
}

print "script complete".





// get_byte_total_hash :: _byteList<list> -> byteValTotal
global function sum_binary_total {
    
    parameter _byteList,
              __showProgress is 0.

    local byteValTotal to 0.

    if __showProgress = 0 {

        for byte in _byteList { 

            if byte:IsType("Scalar") {
                
                if byte < 256 and byte >= 0 {
                    
                    set byteValTotal to byteValTotal + byte. 
                }
            }
        } 
    } else {

        local listLength to _byteList:Length.

        from { local __i to 0.} until __i = listLength step { set __i to __i + 1.} do {

            local pctComplete to choose 0 if __i = 0 else 100 * Round(__i / listLength, 4).
            print "Current Byte Total: {0} ":Format(byteValTotal) at (2, 20).
            print "Processing Char [Current/Total/Pct]:  [ {0,-7} / {1,-7} / {2,5}%] ":Format(__i, listLength, pctComplete) at (2, 22).
            local byte to _byteList[__i].

            set byteValTotal to byteValTotal + byte. 
            print "Adding Current byte [t]: {0} ":Format(byte) at (2, 23).
        } 
    }

    return byteValTotal.
}



// get_byte_unique_hash :: _byteList<list> -> byteValTotal
global function sum_binary_unique
{
    parameter _byteList,
              __showProgress is 0.

    local byteValTotal to 0.
    local byteTracker to UniqueSet().

    if __showProgress = 0 {
    
        for byte in _byteList { 

            if byteTracker:Contains(byte) {

            } else {
                if byte:IsType("Scalar") {
                
                    if byte < 256 and byte >= 0 {
                        
                        set byteValTotal to byteValTotal + byte. 
                    }
                }
                byteTracker:Add(byte).
            }
        } 
    } else {

        local listLength to _byteList:Length.

        from { local __i to 0.} until __i = listLength step { set __i to __i + 1.} do {

            local pctComplete to choose 0 if __i = 0 else 100 * Round(__i / listLength, 4).
            print "Current Unique Byte Total          : [ {0,-7} ]":Format(byteValTotal) at (2, 20).
            print "Processing Char [Current/Total/Pct]: [ {0,-7} / {1,-7} / {2,5}%] ":Format(__i, listLength, pctComplete) at (2, 22).
            local byte to _byteList[__i].

            if byteTracker:Contains(byte) {

                print "Duplicate Byte! [{0}] ":Format(byte) at (2, 23).
            } else {

                print "Unique Byte added: [{0}] ":Format(byte) at (2,23).
                set byteValTotal to byteValTotal + byte. 
                byteTracker:Add(byte).
            }
        }
    }
    return byteValTotal.
}


global function sum_binary_diff {

    parameter _byteList,
              __showProgress is 0. // 0: Disabled. 1: Enabled

    local byteDiffTotal to 0. 
        
    if __showProgress = 0 {

        local lastByteVal to 0.
        for byte in _byteList { 

            set byteDiffTotal to byteDiffTotal + Abs(lastByteVal - byte).
            set lastByteVal to byte.
        }
    } else {
    
        local lastByteVal to 0.
        local listLength to _byteList:Length.

        from { local __i to 0.} until __i = listLength step { set __i to __i + 1.} do {

            local pctComplete to choose 0 if __i = 0 else 100 * Round(__i / listLength, 4).
            print "Current Diff Total: {0} ":Format(byteDiffTotal) at (2, 20).
            print "Processing Char [Current/Total/Pct]:  [ {0,-7} / {1,-7} / {2,5}%] ":Format(__i, listLength, pctComplete) at (2, 22).
            local byte to _byteList[__i].

            local diffResult to Abs(lastByteVal - byte).
            print "Current byte vs last btye [d]: Abs({0} - {1}) = {2}  ":Format(lastByteVal, byte, diffResult) at (2, 23).
            set byteDiffTotal to byteDiffTotal + diffResult.
            set lastByteVal to byte.
        }
    }

    return byteDiffTotal.
}



// Returns a pseudohash value. 
// Formula: Walk every byte in sequence, and add 1 if the byte is different from the last; 0 if the same
global function sum_binary_change {
    parameter _byteList,
              __showProgress is 0. // 0: Disabled. 1: Enabled

    local byteChangeCount to 0. 
        
    if __showProgress = 0 {
        
        local lastByteVal to 0.

        for byte in _byteList { 

            local byteCheckResult to choose 0 if byte = lastByteVal else 1.
            set byteChangeCount to byteChangeCount + byteCheckResult.
            set lastByteVal to byte.
        }
    } else {

        local lastByteVal to 0.
        local listLength to _byteList:Length.

        from { local __i to 0.} until __i = listLength step { set __i to __i + 1.} do {
            
            local pctComplete to choose 0 if __i = 0 else 100 * Round(__i / listLength, 4).
            print "Current Change Count: {0} ":Format(byteChangeCount) at (2, 20).
            print "Processing Char [Current/Total/Pct]:  [ {0,-7} / {1,-7} / {2,5}%] ":Format(__i, listLength, pctComplete) at (2, 22).
            local byte to _byteList[__i].

            local byteCheckResult to choose 0 if byte = lastByteVal else 1.
            local byteResultChar to list("=", "<>")[byteCheckResult].
            print "Current byte vs last byte [i]: {0} {1} {2} ":Format(byte, byteResultChar, lastByteVal) at (2, 23).
            set byteChangeCount to byteChangeCount + byteCheckResult.
            set lastByteVal to byte.
        }

    }
    return byteChangeCount.
}


// Returns a pseudohash value. 
// Formula: Walk every byte in sequence, and compare current byte vs lastByte. > = +1; = = 0; < = -1;
global function sum_binary_incremental {
    
    parameter _byteList,
              __showProgress is 0. // 0: Disabled. 1: Enabled

        local byteIncremental to 0. 
        
    if __showProgress = 0 {

        local lastByteVal to 0.

        for byte in _byteList { 

            local byteResult to choose 1 if byte > lastByteVal else choose -1 if byte < lastByteVal else 0.
            set byteIncremental to byteIncremental + byteResult.
            set lastByteVal to byte.
        }
    } else {

        local lastByteVal to 0.
        local listLength to _byteList:Length.

        from { local __i to 0.} until __i = listLength step { set __i to __i + 1.} do {
            
            local pctComplete to choose 0 if __i = 0 else 100 * Round(__i / listLength, 4).
            print "Current Incremental: {0} ":Format(byteIncremental) at (2, 20).
            print "Processing Char [Current/Total/Pct]:  [ {0,-7} / {1,-7} / {2,5}%] ":Format(__i, listLength, pctComplete) at (2, 22).
            local byte to _byteList[__i].


            local byteResult to choose 1 if byte > lastByteVal else choose -1 if byte < lastByteVal else 0.
            local byteResultChar to list("<","=",">")[byteResult + 1].
            print "Current byte vs last byte [i]: {0} {1} {2} ":Format(byte, byteResultChar, lastByteVal) at (2, 23).
            set byteIncremental to byteIncremental + byteResult.
            set lastByteVal to byte.
        }

        print "Current Incremental Value: {0} ":Format(byteIncremental) at (2, 22).
    }
    return byteIncremental.
}