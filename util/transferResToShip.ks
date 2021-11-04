@lazyGlobal off.
clearScreen.

runOncePath("0:/lib/disp").
runOncePath("0:/lib/util").

parameter res,
          eSrc,
          amt,
          mode is "pct".

disp_main(scriptPath(), false).

if res = "LFO" 
{
    local lfoAmt to amt.
    local oxAmt to amt * 1.222222222. // Ratio: LF 0.9 <-> 1.1 Ox 
    local remainingLF to choose get_resource_amount_from_pct(eSrc, "LiquidFuel", lfoAmt) if mode = "pct" else lfoAmt.
    local remainingOx to choose get_resource_amount_from_pct(eSrc, "Oxidizer", oxAmt) if mode = "pct" else oxAmt.

    for e in ship:elements
    {
        print "remLF: " + remainingLF at (2, 35).
        print "remOx: " + remainingOx at (2, 36).
        if e:name <> eSrc:name and remainingLF > 0 and remainingOx > 0 
        {
            set remainingLF to remainingLF - transfer_resource_from_source("LiquidFuel", eSrc, e, remainingLF).
            set remainingOx to remainingOx - transfer_resource_from_source("Oxidizer", eSrc, e, remainingOx).
        }
    }
}
else if res = "LH2O" 
{
    local remainingLH to choose get_resource_amount_from_pct(eSrc, "LqdHydrogen", amt) if mode = "pct" else amt.
    local remainingOx to choose get_resource_amount_from_pct(eSrc, "Oxidizer", amt) if mode = "pct" else amt.
    
    for e in ship:elements
    {
        if e:name <> eSrc:name and remainingLH > 0 and remainingOx > 0 
        {
            set remainingLH to remainingLH - transfer_resource_from_source("LqdHydrogen", eSrc, e, remainingLH).
            set remainingOx to remainingOx - transfer_resource_from_source("Oxidizer", eSrc, e, remainingOx).
        }
    }
}
else if res = "LCH4O"
{
    local remainingLCH4 to choose get_resource_amount_from_pct(eSrc, "LqdMethane", amt) if mode = "pct" else amt.
    local remainingOx to choose get_resource_amount_from_pct(eSrc, "Oxidizer", amt) if mode = "pct" else amt.
    
    for e in ship:elements
    {
        if e:name <> eSrc:name and remainingLCH4 > 0 and remainingOx > 0 
        {
            set remainingLCH4 to remainingLCH4 - transfer_resource_from_source("LiquidFuel", eSrc, e, remainingLCH4).
            set remainingOx to remainingOx - transfer_resource_from_source("Oxidizer", eSrc, e, remainingOx).
        }
    }
}
else if res = "MP" or res = "MonoProp" 
{
    local remainingMP to choose get_resource_amount_from_pct(eSrc, "MonoPropellant", amt) if mode = "pct" else amt.
    print "Transferring " + remainingMP + " units" at (2, 25).
    
    for e in ship:elements
    {
        if e:name <> eSrc:name and remainingMP > 0
        {
            set remainingMP to remainingMP - transfer_resource_from_source("MonoPropellant", eSrc, e, remainingMP).
            print "Remaining MP after transfer: " + round(remainingMP, 2) at (2, 26).
        }
    }
}
else
{
    local remainingRes to choose get_resource_amount_from_pct(eSrc, res, amt) if mode = "pct" else amt.
    
    for e in ship:elements
    {
        if e:name <> eSrc:name and remainingRes > 0 
        {
            set remainingRes to remainingRes - transfer_resource_from_source(res, eSrc, e, remainingRes).
        }
    }
}

// Functions
local function get_resource_amount_from_pct
{
    parameter src,
              resName,
              pct.

    for r in src:resources
    {
        if r:name = resName
        {
            return r:amount * (pct / 100).
        }
    }
    return 0.
}


local function transfer_resource_from_source
{
    parameter resName,
              src,
              tgt,
              xfrAmt.

    local srcRes to 0.
    local srcHasRes to false.
    local tgtRes to 0.
    local tgtHasRes to false.
    local tgtStAmt  to 0.

    // Source resource
    for r in src:resources
    {
        if r:name = resName
        {
            set srcRes to r.
            set srcHasRes to true.
        }
    }

    if not srcHasRes 
    {
        disp_msg("No " + resName + " in source element [" + src:name + "]").
        return xfrAmt.
    }
    
    local srcCap to srcRes:capacity.
    local fillTgt to choose xfrAmt if srcRes:amount >= xfrAmt else srcRes:amount.
    local srcAmtTgtResult to srcRes:amount - fillTgt.
    
    // Target resource
    for r in tgt:resources
    {
        if r:name = resName 
        {
            set tgtRes to r.
            set tgtHasRes to true.
        }
    }

    if tgtHasRes 
    {
        local tgtCap to tgtRes:capacity.
        local tgtFreeSpace to tgtRes:capacity - tgtRes:amount.
        set tgtStAmt to tgtRes:amount.

        if tgtFreeSpace < fillTgt
        {
            set fillTgt to tgtFreeSpace.
        }
        
        if tgtFreeSpace > 0.01  and srcRes:amount >= srcAmtTgtResult
        {
            local resTransfer to transfer(resName, src, tgt, fillTgt).
            set resTransfer:active to true.
        
            disp_msg("Transferring resource").
            until resTransfer:status = "Failed" or resTransfer:status = "Finished"
            {
                disp_info("Transfer status: " + resTransfer:status).
                disp_resource_transfer(resName, src, srcCap, tgt, tgtCap, fillTgt).
            }
            disp_info2(resTransfer:message).
            set resTransfer:active to false.

            return tgtRes:amount - tgtStAmt.
        }
        else
        {
            disp_msg().
            disp_msg("No " + resName + " capacity in target element [" + tgt:name + "]           ").
            return 0.
        }
    }
    else
    {
        return 0.
    }
}


local function disp_resource_transfer
{
    parameter resName, 
              src,
              srcCap,
              tgt,
              tgtCap,
              xfrAmt.

    global line to 10.
    local srcAmt to 0.
    local tgtAmt to 0.

    for r in src:resources
    {
        if r:name = resName set srcAmt to r:amount.
    }

    for r in tgt:resources
    {
        if r:name = resName set tgtAmt to r:amount.
    }

    print "RESOURCE TRANSFER" at (0, line).
    print "-----------------" at (0, crs()).
    print "RESOURCE             : " + resName at (0, crs()).
    print "TRANSFER AMOUNT      : " + round(xfrAmt, 2) at (0, crs()).
    print "TRANSFER PROGRESS    : " + round(1 - (xfrAmt / tgtAmt), 2) * 100 + "%   " at (0, crs()).
    crs().
    print "SOURCE ELEMENT       : " + src:name at (0, crs()).
    print "SOURCE AMOUNT / CAP  : " + round(srcAmt, 2) + " / " + round(srcCap) at (0, crs()).
    crs().
    print "TARGET ELEMENT       : " + tgt:name at (0, crs()).
    print "TARGET AMOUNT / CAP  : " + round(tgtAmt, 2) + " / " + round(tgtCap) at (0, crs()).
    crs().
}

local function crs
{
    set line to line + 1.
    return line.
}