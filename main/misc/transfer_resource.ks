@lazyGlobal off.
clearScreen.

parameter res,
          srcElement,
          tgtElement,
          tgtAmount is 100,
          amountType is "pct".
          
runOncePath("0:/lib/lib_disp").

disp_main(scriptPath(), false).

disp_msg("Creating transfer object for " + res).

if res = "LFO" 
{
    transfer_resource("LiquidFuel", srcElement, tgtElement, tgtAmount, amountType).
    transfer_resource("Oxidizer", srcElement, tgtElement, tgtAmount, amountType).
}
else if res = "LH2O" 
{
    transfer_resource("LqdHydrogen", srcElement, tgtElement, tgtAmount, amountType).
    transfer_resource("Oxidizer", srcElement, tgtElement, tgtAmount, amountType).
}
else if res = "LCH4O"
{
    transfer_resource("LqdMethane", srcElement, tgtElement, tgtAmount, amountType).
    transfer_resource("Oxidizer", srcElement, tgtElement, tgtAmount, amountType).
}
else if res = "MP" or res = "MonoProp" 
{
    transfer_resource("MonoPropellant", srcElement, tgtElement, tgtAmount, amountType).
}
else
{
    transfer_resource(res, srcElement, tgtElement, tgtAmount, amountType).
}

disp_msg("Transfer complete").


// Functions
local function transfer_resource
{
    parameter resName,
              src,
              tgt,
              fillAmt,
              amtType.

    local fillTgt to 0.
    local srcCap to 0.
    local tgtCap to 0.
    local xfrAmt to 0.

    for r in src:resources
    {
        if r:name = resName
        {
            set srcCap to r:capacity.
        }
    }

    for r in tgt:resources 
    {
        if r:name = resName
        {
            if amtType = "pct"
            {
                set fillTgt to r:capacity * fillAmt.
                set xfrAmt  to fillTgt - r:amount.
            }
            else if amtType = "units"
            {
                local maxFill to r:capacity - r:amount.
                if maxFill > fillAmt 
                {
                    set fillTgt to r:amount + fillAmt.
                    set xfrAmt to fillAmt.
                }
                else
                {
                    set fillTgt to r:capacity.
                    set xfrAmt to r:capacity - r:amount.
                }
            }
            else
            {
                return -1.
            }
            set tgtCap to r:capacity.
        }
    }

    local resTransfer to transfer(resName, src, tgt, xfrAmt).
    set resTransfer:active to true.
    
    disp_msg("Transferring resource").
    until resTransfer:status = "Failed" or resTransfer:status = "Finished"
    {
        disp_info("Transfer status: " + resTransfer:status).
        disp_info2(resTransfer:message).
        disp_resource_transfer(resName, src, srcCap, tgt, tgtCap, fillTgt, xfrAmt).
    }
    set resTransfer:active to false.
    return 1.
}

local function disp_resource_transfer
{
    parameter resName, 
              src,
              srcCap,
              tgt,
              tgtCap,
              fillTgt,
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
    print "-----------------" at (0, cr()).
    print "RESOURCE             : " + resName at (0, cr()).
    print "TRANSFER AMOUNT      : " + round(xfrAmt, 2) at (0, cr()).
    print "TRANSFER PROGRESS    : " + round(1 - (xfrAmt / tgtAmt), 2) * 100 + "%   " at (0, cr()).
    cr().
    print "SOURCE ELEMENT       : " + src:name at (0, cr()).
    print "SOURCE AMOUNT / CAP  : " + round(srcAmt, 2) + " / " + round(srcCap) at (0, cr()).
    cr().
    print "TARGET ELEMENT       : " + tgt:name at (0, cr()).
    print "TARGET AMOUNT / CAP  : " + round(tgtAmt, 2) + " / " + round(tgtCap) at (0, cr()).
    cr().
}

local function cr
{
    set line to line + 1.
    return line.
}