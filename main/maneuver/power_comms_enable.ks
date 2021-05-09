local event to "extend solar panel".

for m in ship:modulesNamed("ModuleDeployableSolarPanel")
{
    if m:part:tag = ""
    {
        if m:hasEvent(event) m:doEvent(event).
    }
}
   
for m in ship:modulesNamed("ModuleRTAntenna")
{       
    if m:part:tag = "" 
    {
        if m:hasEvent("activate") m:doEvent("activate"). 
    }
}