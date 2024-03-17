// #include "0:/lib/depLoader.ks"
@LazyGlobal off.


// Note: This lib is more similar to global.ks, but instead of holding a bunch of global variables, this will load various object references
// I split these up like this to keep globals from getting too large, and to someday (TODO willing) selectively load these reference objects based on params. Maybe.

// #endregion