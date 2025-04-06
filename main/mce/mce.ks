// #TODO:Parse the plan

// #TODO: Execute the plan

if core:tag:MatchesPattern("(Sounder|Sounding)")
{
    runPath("0:/main/launch/sounderLaunch.ks").
} 
else if core:tag:MatchesPattern("(DownRange(r)?|DR)")
{
    runPath("0:/main/launch/downrangerLaunch.ks").
}