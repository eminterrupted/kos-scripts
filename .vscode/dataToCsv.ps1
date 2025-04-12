
# description="Convert a specified delimited text file to a CSV file with optional custom delimiter."
[CmdletBinding()]
param (
    [Parameter(Position = 0, HelpMessage = 'Path to the input text file')]
    [ValidateScript({Test-Path $_})]
    [string]$SourcePath = 'E:\source\KSP\KSP-KOS\RP1-V2-PPE\data\ref\unicodeCharacters.txt',

    [Parameter(Position = 1, HelpMessage = 'Path for the output CSV file')]
    [ValidateScript({Test-Path $_.Substring(0, $_.LastIndexOf('\'))})]
    [string]$OutputPath = 'E:\source\KSP\KSP-KOS\RP1-V2-PPE\data\ref\charCodes.csv',

    [Parameter(Position = 2, HelpMessage = 'Delimiter to use between fields in the input file')]
    [string]$SourceDelimiter = "\s",

    [Parameter(Position = 3, HelpMessage = 'Set $True to treat consecutive delimiters as one.')]
    [bool]$IgnoreConsecutive = $True,

    [Parameter(Position = 4, HelpMessage = 'Delimiter to use between fields in the output CSV')]
    [string]$OutputDelimiter = ","
);

cls

if ($IgnoreConsecutive) {
    if ($SourceDelimiter -notlike ("*+")) {
        $SourceDelimiter += "+"
    }
}

# $SourceFile = Get-Item -Path $SourcePath
$SourceData = Get-Content -Path $SourcePath -ErrorAction SilentlyContinue -Force

$regex = "^\s+(\d*)\s*(\S+).*$"

$ErrorData  = @();
$OutputData = @{"Code"=@();"Char"=@()};

Write-Output "Parsing   : [$($SourcePath)]          "
Write-Output "Delimiter : [$($SourceDelimiter)]     "
Write-Output " "
$LoopStr = ""
foreach ($Line in $SourceData) {
    
    $LoopStr = ""
    $LoopStr = "`r Parsed: $($OutputData.Count)       "
    $LoopStr += "`r Errors: $($ErrorData.Count)       "
    $LoopStr += "`r "
    $LoopStr += "`r Parsing Line: $($Line)          "

    Write-Host $LoopStr -NoNewline
    $LoopStr = ""

    if ($Line -match $regex) {
        try {
            $OutputData.Code += $Matches.1 
            $OutputData.Char += "$($Matches.2)"
            # if (($Matches.2).Count -eq 0) {
            #     $OutputData += "$($Matches.1),' '"
            # } else {
            # }
        }
        catch {
            $LoopStr += "`r ERROR: $($Line)" 
        } 
    } else {
        $ErrorData += $Matches.0
    }
    
    Write-Host $LoopStr -NoNewline
}

$LoopStr += "`r Parsed: $($OutputData.Count)       "
$LoopStr += "`r Errors: $($ErrorData.Count)       "
$LoopStr += "`r "
Write-Host $LoopStr 

$LoopStr = ""
$LoopStr += "`r Converting to CSV with Delimiter: [$($OutputDelimiter)] "
Write-Host $LoopStr -NoNewline

$OutputCsv = @("Code,Char");

foreach ($i in (0..$OutputData.Code.Count)) {
    $OutputCsv += "$($OutputData.Code[$i])$($OutputDelimiter)$($OutputData.Char[$i])"
}

$LoopStr = ""
$LoopStr += "`r Writing to path: [$($OutputPath)] "
Write-Host $LoopStr -NoNewline

Out-File -FilePath $OutputPath -InputObject $OutputCsv -Force

$LoopStr = ""
$LoopStr += "`r Writing to path: [$($OutputPath)] "
if (Test-Path -Path $OutputPath) {
    $LoopStr += "`r Status: $($True)"
} else {
    $LoopStr += "`r Status: $($False)"
}
$LoopStr += "`r "
Write-Host $LoopStr