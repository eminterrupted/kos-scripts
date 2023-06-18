// #include "0:/lib/libLoader.ks"
@lazyGlobal off.
// *~ Dependencies ~* //
// Required libraries not loaded by libLoader by default go here
// #region
// #include "0:/lib/globals"

// #endregion


// *~ Variables ~* //
// Local and global variables used in this library
// #region
    // *- Local
    // #region
    // #endregion

    // *- Global
    // #region
    // #endregion
// #endregion


// *~ Library Setup Functions ~* //
// Functions that run on library load to help setup stuff
// #region
SetKOSConfig().
// #endregion


// *~ Functions ~* //
// #region
  
    // *- Config
    // #region
    local function SetKOSConfig
    {
        parameter _ipu is 500
                 ,_ucp is False
                 ,_stat is False
                 ,_clobber is False
                 ,_verbose is True
                 ,_safeMode is True.

        set Config:IPU      to _ipu.
        set Config:UCP      to _ucp.
        set Config:Stat     to _stat.
        set Config:Clobber  to _clobber.
        set Config:Verbose  to _verbose.
        set Config:Safe     to _safeMode.
    }
    // #endregion

    // *- Tag Functions
    // #region

    // ParseCoreTag :: (_tag)<string> -> (_tagList)List<string>
    // Parses a tag for the following: Mission name, Stop Stage
    global function ParseCoreTag
    {
        parameter _tag is Core:Tag.

        local tagSplit to list().

        set tagSplit to _tag:Split("|").
        if tagSplit:Length > 0
        {
            set g_Mission to tagSplit[0].
            if tagSplit:Length > 1 set g_StageLimit to tagSplit[1]:ToNumber(0).
        }

        return list(
            g_Mission
            ,g_StageLimit
        ).
    }
    
    // #endregion

    // *- Module Helpers
    // #region

    // DoEvent :: (_m)<PartModule>, (_event)<String> -> (_result)<Bool>
    // Attempts to perform the provided event on the provided part module. 
    // Returns True if event found and performed, false if not
    global function DoEvent
    {
        parameter _m,
                  _event.

        if _m:HasEvent(_event)
        {
            _m:DoEvent(_event).
            return True.
        }
        else
        {
            return False.
        }
    }
    // #endregion
// #endregion