@lazyGlobal off.
clearScreen.

parameter res,
          srcElement,
          tgtElement,
          tgtFillPct is 100.

runOncePath("0:/lib/lib_disp").

disp_main(scriptPath(), false).

if tgtFillPct > 1 set tgtFillPct to tgtFillPct / 100.

disp_msg("Creating transfer object for " + res).

print "Resource: " + res at (2, 15).

print "Source Element: " + srcElement at (2, 17).

print "Target Element: " + tgtElement at (2, 20).


if res = "LFO" 
{
    transfer_resource("LiquidFuel", srcElement, tgtElement, tgtFillPct).
    transfer_resource("Oxidizer", srcElement, tgtElement, tgtFillPct).
}
else if res = "LH2O" 
{
    transfer_resource("LqdHydrogen", srcElement, tgtElement, tgtFillPct).
    transfer_resource("Oxidizer", srcElement, tgtElement, tgtFillPct).
}
else if res = "LCH4O"
{
    transfer_resource("LqdMethane", srcElement, tgtElement, tgtFillPct).
    transfer_resource("Oxidizer", srcElement, tgtElement, tgtFillPct).
}
else if res = "MP" or res = "MonoProp" 
{
    transfer_resource("MonoPropellant", srcElement, tgtElement, tgtFillPct).
}
else
{
    transfer_resource(res, srcElement, tgtElement, tgtFillPct).
}

disp_msg("All transfers complete").


// Functions
local function transfer_resource 
{
    parameter resName,
              src,
              tgt,
              pct.

    local fillTgt to -1.

    for r in src:resources
    {
        if r:name = resName
        {
            lock srcAmt to r:amount.
            print "Source Units: " + round(srcAmt, 2) at (2, 18).
        }
    }

    for r in tgt:resources 
    {
        if r:name = resName
        {
            set fillTgt to r:capacity * pct.
            lock tgtAmt to r:amount.
            print "Target Units: " + round(r:amount, 2) at (2, 21).
            print "Target Fill: " + round(fillTgt, 2) at (2, 22).
        }
    }

    if fillTgt = -1 return -1.
    else 
    {
        local resTransfer to transfer(resName, src, tgt, fillTgt).
        set resTransfer:active to true.
        print "Transfer Status: " + resTransfer:status at (2, 25).
        wait 2.
        until tgtAmt >= fillTgt or srcAmt <= 0.1
        {
            disp_info("Transferring " + round(fillTgt - tgtAmt, 2) + " units of " + resName).
            wait 2.
        }
        set resTransfer:active to false.
        disp_info("Transfer complete!").
        return 1.
    }
}