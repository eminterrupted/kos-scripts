param (
    [string]$InputFile = "C:\Users\emilyha\Desktop\HeaderStrings.csv",

    [string]$MaskFile = "C:\Users\emilyha\Desktop\CharUnicodeByteMask.csv",

    [string]$OutputFile = "_packed.csv",

    [int]$OutputWriteMode = 1  # 0 = WriteIfNew, 1 = VersionedSave, 2 = Overwrite, 3 = NoAction
);

if (!(Test-Path -Path $InputFile)) {

    Write-Host -Object ("Invalid input file! | [$($InputFile)]") 
    exit
} 
else {
    Write-Host -Object ("Using input file: | [$($InputFile)]") 
}

if (!(Test-Path -Path $MaskFile)) {
    
    Write-Host -Object ("Invalid mask file! | [$($MaskFile)]") 
    exit
} 
else {
    
    Write-Host -Object ("Using mask file: | [$($MaskFile)]")

    $InputPath = Get-Item $InputFile
    $MaskPath  = Get-Item $MaskFile


    if ($OutputFile -eq "_packed.csv") {
        $OutputFile = $InputPath.FullName.Replace($InputPath.Extension, $OutputFile)
    }
    
    $OutputDir  = $OutputFile.Substring(0, $OutputFile.LastIndexOf('\'))
    $OutputExt  = $OutputFile.Substring($OutputFile.LastIndexOf('.'), 4)

    $FStr = "{0,-92}"

    if (Test-Path -Path $OutputFile) {

        Write-Host -Object ("Provided output file already exists! | [$($OutputFile)]")
        Write-Host -Object (" ")
        Write-Host -Object ($FStr -f "Press Enter to create a versioned save, Delete to overwrite, Escape to abort")
        
        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {

            "Enter" {

                Write-Host -Object ($FStr -f "Create a versioned save by appending a numeric sequence id to the filename") -NoNewline
                Start-Sleep -Seconds 1
                
                # Creates a versioned save file name
                $VersionedFileExt = "_v{0,2:d2}.{1}" -f (Get-ChildItem -Path $OutputDir -Filter "$($OutputFile.Substring($OutputFile.LastIndexOf('\') + 1, ($OutputFile.Length - $OutputFile.LastIndexOf('\') - 1)) )*$($OutputExt)").Count,$OutputExt.Substring(1, $OutputExt.Length - 1)
                $OutputWriteMode = 1
                $OutputFile      = $OutputFile.Replace($OutputExt, $VersionedFileExt)
            }
            "Delete" {
                Write-Host -Object ($FStr -f "Enable overwriting of the existing output file") -NoNewline 
                Start-Sleep -Seconds 1

                $OutputWriteMode = 2
            }
            "Escape" {
                Write-Host -Object ($FStr -f "Operation aborted.") -NoNewline 
                Start-Sleep -Seconds 1

                $OutputWriteMode = 3
                exit
            }
            Default {
                Write-Host -Object ($FStr -f "Invalid selection. Please try again.") -NoNewline 
                Start-Sleep -Milliseconds 500
                Write-Host -Object ($FStr -f "Press Enter to create a versioned save, Delete to overwrite, Escape to abort") -NoNewline 
            }
        }
        Write-Host -Object ($FStr -F "  ") -NoNewline 

        Write-Host -Object ("  Current Setting: [{0,-13}]   " -f @("TakeNoAction", "WriteIfNew", "VersionedSave", "Overwrite")[$OutputWriteMode + 1]) 
    } 
    else {
        $OutputWriteMode = 2
    }

    if ($OutputWriteMode -eq 3) {
        Write-Host -Object ("Terminating hexPacker, goodbye") 
        Write-Host -Object (" ") 
    }
    else {

        $InputContent = Get-Content -Path $InputPath
        $MaskTable    = (Get-Content -Path $MaskPath).ReplaceLineEndings() | ConvertFrom-Csv -Header "HexId", "Code", "Char"
        
        $OutputContent = @()

        foreach ($Line in $InputContent) {
        
            $LineArray = $Line.ToCharArray()
            $OutputArray = @()

            $CharPos   = 0
            $ConsecuCounter = 0
            
            [Char]$TestChar

            while ($CharPos -le $LineArray.Count) {
                
                $CurrentChar = $LineArray[$CharPos]

                if ($CharPos -eq 0) {

                    $MaskRow      = $MaskTable[$MaskTable.Char.IndexOf($CurrentChar.ToString([cultureinfo]::CurrentCulture))]
                    $OutputArray += '"' + $($MaskRow.HexId) + '"'
                    
                    $TestChar     = $CurrentChar
                    $ConsecuCounter += 1
                }
                elseif ($CharPos -ge $LineArray.Count(0)) {

                    $ConsecuCounter += 1
                    $OutputArray += ", $($ConsecuCounter) )"

                }
                elseif ($CurrentChar -eq $TestChar) {

                    $ConsecuCounter += 1
                } 
                else {
                    # Log character count
                    $OutputArray += $ConsecuCounter
                    try {
                        
                        $MaskRowIdx = $MaskTable.Char.IndexOf($CurrentChar.ToString())
                        $MaskRow    = $MaskTable[$MaskRowIdx]
                    }
                    catch {
                        Start-Sleep .5
                    }
                    $OutputArray += '"' + $($MaskRow.HexId) + '"'

                    $TestChar = $CurrentChar
                    $ConsecuCounter = 1
                }
                $CharPos += 1
            }

            $OutputLine = "list( "
            $OutputArray | ForEach-Object { $OutputLine += "$($_), " }
            # $OutputLine += "1 )"
            $OutputLine = $OutputLine -match "(^.*)(,\s*\)\s*$)" ? "$($Matches.1) )" : $OutputLine
            
            $OutputContent += $OutputLine
        }

        Set-Content -Value $OutputContent -Path $OutputFile
    }

    Write-Host -Object ("Alllll done") 
}
