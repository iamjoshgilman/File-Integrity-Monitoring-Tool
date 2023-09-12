Function CalculateFileHash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function EraseBaselineIfAlreadyExists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        #Delete it
        Remove-Item -Path .\baseline.txt
    }
}

Write-Host " "
Write-Host "What would you like to do?"
Write-Host "A. Collect new Baseline?"
Write-Host "B. Begin monitoring files with saved Basline?"
Write-Host " "

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host " "

if ($response -eq "A".ToUpper()) {
     # Calcualte Hash from the target files and store in baseline.txt
     Write-Host "Calculating Hahes and making new baseline.txt" -ForegroundColor Cyan
    
    #Delete baseline.txt if already exists
    EraseBaselineIfAlreadyExists
    
    #Collect files in target folder
    $files = Get-ChildItem -Path .\Files

    #Calcuate Hash for each file in folder
    foreach ($f in $files) {
        $hash = CalculateFileHash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append 
    }
}
elseif ($response -eq "B".ToUpper()) {

    $FileHashDictionary = @{}

    # Load file|hash from baseline.txt and store them in a dictionary
    $filePathesAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathesAndHashes) {
        $FileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    # Begin monitoring files with saved Baseline
    Write-Host "Monitoring File Integrity..." -ForegroundColor Cyan
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\Files

        # For each file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {
            $hash = CalculateFileHash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append

            # Notify if a new file has been created
            if ($null -eq $fileHashDictionary[$hash.Path]) {
                # A new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            else {

                # Notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # The file has not changed
                }
                else {
                    # File file has been compromised!, notify the user
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
                }
            }
        }

        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                # One of the baseline files must have been deleted, notify the user
                Write-Host "$($key) has been deleted!" -ForegroundColor Magenta
            }
        }
    }
}