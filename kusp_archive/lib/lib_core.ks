//Set vessel configurations
@lazyGlobal off. 

runOncePath("0:/lib/lib_init").

// Common variables for the library
local cacheFile     to "local:/missionCache.json".
local kscCacheFile  to ksc_cache_file_name().

//
//-- Functions --//
//

// Cache functions

    // Retrieves a key/value pair from missionCache is present. 
    // It not present, function will return "null".
    global function from_cache 
    {
        parameter _key.

        local cache to readJson(cacheFile).
        if cache:hasKey(_key) 
        {
            return cache[_key].
        } 
        else 
        {
            return "null".
        }
    }


    // Initiatilizes the cache file, first checking internally. If
    // not present, loads from one of two archive locations based 
    // on ship status
    global function init_mission_cache 
    {
        if not exists(cacheFile) 
        {
            if status = "PRELAUNCH" 
            {
                copyPath("0:/data/missionCacheParam.json", cacheFile).
            } 
            else 
            {
                copyPath(kscCacheFile, cacheFile).
            }
        }

        return readJson(cacheFile).
    }


    // Simple helper to properly format the file name on the archive
    local function ksc_cache_file_name 
    {
        local fileName      to shipName:replace(" ", "_").
        local fileNameLast_ to fileName:findLast("_").
        local folderName    to fileName:remove(fileNameLast_, fileName:length - fileNameLast_).

        return "archive:/logs/" + folderName + "/" + fileName + ".missionCache.json".
    }


    // Function to log the local mission cache to archive for debugging
    local function log_cache_to_archive 
    {
        parameter _cache.

        writeJson(_cache, kscCacheFile).
    }


    // Takes a key/value pair and writes it to the mission cache
    // file at "local:/missionCache.json".
    // Also calls a debugging function to log the cache to archive
    global function to_cache 
    {
        parameter _key, 
                  _val.

        local cache       to lex().
        set   cache       to readJson(cacheFile).
        set   cache[_key] to _val.
        writeJson(cache, cacheFile).

        log_cache_to_archive(cache).
    }


// String formatting
    // Formats a timestamp into a pretty-printed string
    global function format_timestamp 
    {
        parameter _t.

        local hour is floor(_t / 3600).
        local min is floor((_t / 60) - (hour * 60)).
        local sec is round(_t - (hour * 3600 + min * 60)).

        return hour + "h " + min + "m " + sec + "s".
    }


// Terminal
    
    // Waits for keypress with msg on screen
    global function breakpoint 
    {
        print ("*** BREAKPOINT: Press any key ***") at (10, 55).
        terminal:input:getchar().
        print ("                                 ") at (10, 55).
    }