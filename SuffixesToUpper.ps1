param (
    [string]$FileMask = '*.tst',
    
    [switch]$Recurse
)

if ($Recurse) 
{
    $filesToProcess = Get-ChildItem $FileMask -Recurse
}
else
{
    $filesToProcess = Get-ChildItem $FileMask
}

foreach ($sf in $filesToProcess) 
{ 
    $hitCount = 1
    while ($hitCount -gt 0)
    {
        $hitCount = 0
        $sfContent = Get-Content $sf
        Out-File -FilePath $sf.FullName -Force
        foreach ($line in $sfContent) 
        { 
            if ($line -cmatch '(^.*)(:[a-z])(.*$)') 
            {
                $hitCount++
                $ogLine = $Matches[0]
                $line = "$($Matches[1])$($Matches[2].ToUpper())$($Matches[3])"
                Write-Output -inputObject "$($sf.Name) regex hit   : $($ogLine)"
                Write-Output -inputObject "$($sf.Name) replacement: $($line)"
                Write-Output -inputObject " "
            }
            Add-Content -LiteralPath $sf.FullName -Value $line
        }
    }

    # try 
    # { 
    #     Write-Output "$($sf.Name) written successfully"
    #     Write-Output -inputObject " "
    # } 
    # catch 
    # {
    #     Write-Output "$($sf.Name) Error when writing!"
    #     Write-Output -inputObject " "
    # }
}