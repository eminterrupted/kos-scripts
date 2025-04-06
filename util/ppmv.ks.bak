@LazyGlobal off.
ClearScreen.

parameter _module is "".

// Dependencies
RunOncePath("0:/lib/depLoader").

DispMain(ScriptPath()).

// Declare Variables
local moduleToPrint to core.

// Parse Params
if _module:length > 0 
{
  set moduleToPrint to _module.
}

local moduleData to lexicon("FIELD", lexicon(), "ACTION", lexicon(), "EVENT", lexicon()).

local moduleStringCleaner to lexicon(
    "FIELD", lexicon(
        "PRE", list(
            "(settable) ",
            "(callable) "
        ),
        "POST", list(
            ", is Single",
            ", is Boolean",
            ", is Boolean"
        )
    ),
    "ACTION", lexicon(
        "PRE", list(
            "(callable) "
        ),
        "POST", list(
            ", is KSPAction"
        )
    ),
    "EVENT", lexicon(
        "PRE", list(
            "(callable) "
        ),
        "POST", list(
            ", is KSPEvent"
        )
    )

).

OutMsg("Processing Fields").

for __f in _module:AllFields
{
    local doneFlag to false.
    local __charCount to __f:Length.
    from { local i to 0.} until i = moduleStringCleaner:FIELD:PRE:Length or doneflag step { set i to i + 1.} do
    {
        if moduleStringCleaner:FIELD:PRE:Length > i.
         local challengeStrSetPre to list(moduleStringCleaner:FIELD:PRE[i]).

        set __f to __f:replace(challengeStrsPre,"").
        
        
    }
    moduleData:GetField[__f:Replace()].
}