@lazyGlobal off.


// Functions
global function sci_deploy
{
    parameter m.

    if not m:hasData
    {
        m:deploy().
    }
    else
    {
        sci_recover(m).
    }
}

global function sci_recover
{
    parameter m.

    if m:hasData
    {
        if m:data[0]:transmitValue > 0
        {
            m:transmit().
        }
        else
        {
            m:reset().
        }
    }
}