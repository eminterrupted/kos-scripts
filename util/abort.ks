for m in Ship:ModulesNamed("ModuleRangeSafety")
{
    m:DoEvent("Range Safety").
    print " Range Safety Triggered! ".
    Terminal:Input:GetChar.
    break.
}