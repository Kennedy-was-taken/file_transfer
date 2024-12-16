#------------------------- Variables ----------------------------#

$global:source = Get-Location
$global:destination = "Enter destinaton Path" # You can change this to your destination path
$global:backup = "Enter backup Path" # You can change this to your backup path
$global:numOfCommits = [int] 100 # You can change it to any number to return a number of commits

#----------------------- End of Variables -------------------------#


#------------------------- Methods ----------------------------#

# Checks to see if git is installed on the system 
function isGitInstalled {

    try{

        (git --version 2>&1)
        return $true;
    }

    catch{

        return $false
    }
}

# checks if the current directory is a git repository
function hasGitRepository($source) {

    if (git -C $source rev-parse --is-inside-work-tree) {
        return $true
    }

    else {
        return $false
    }
          
}

# checks if all the changes have been commited first
function checkStatus($source) {

    $value = git -C $source status 2>&1;

    if ($value -match "Changes not staged for commit") {
        return $false;
    }

    else {
        return $true;
    }
}

function getCommits($source) {
    
    $commits = ( git -C $source rev-list --reverse HEAD -n $global:numOfCommits )
    return $commits;
}

function doesPathExist($path) {

    if (Test-Path $path) {
        return $true;
    }

    else {
        return $false;
    }
}

function backupSource($commits) {

    # $destination = "C:\Users\Kennedy\Documents\test";
    # $source = Get-Location;

    $newCopiedFiles = @();
    $overwrittenFiles = @();

    $today = Get-Date
    $formattedDate = $today.ToString("_dd_MM_yyyy")

    $newPath = "$global:backup\previousChanges$formattedDate"

    Write-Host Beginning backup transfer of original files
    
    foreach ($commit in $commits) {

        # Get the list of files changed in the commit
        $files = git -C $source diff-tree --no-commit-id --name-only -r $commit 2>&1;
        
        # Copy each file to the destination path
        foreach ($file in $files) {

            # Write-host "second loop";

            $sourceFile = Join-Path -Path ($global:destination) -ChildPath $file;
            $destFile = Join-Path -Path ($newPath) -ChildPath $file;

            # Write-Host "$sourceFile"
            # Write-Host "$destFile"

            # Create the destination directory if it doesn't exist
            $destDir = Split-Path -Path $destFile -Parent;
            if (-not (Test-Path -Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force;
            }

            if (Test-Path -Path $sourceFile) {

                # Check if the file already exists in the destination path
                if ( -not (Test-Path -Path $destFile)) {
                    # Checks if the file doesn't already exist in the array
                    if ($newCopiedFiles -notcontains $file) {
                        $newCopiedFiles += $file; # adds the file name to the array
                    }

                }
                
                else {
                    # Checks if the file doesn't already exist in the array
                    if ($overwrittenFiles -notcontains $file) {
                        $overwrittenFiles += $file; # adds the file name to the array
                    }
                }

                # Copy the file
                Copy-Item -Path $sourceFile -Destination $destFile -Force;
            }

        }

    }

    
    Write-Host "Files updated"
    Write-Host "";
    displayResults $newCopiedFiles $overwrittenFiles "2"
}

function copyToDestination($commits) {
    
    # $destination = "C:\Users\Kennedy\Documents\test";
    # $source = Get-Location;

    # Write-Host $commits

    $newCopiedFiles = @();
    $overwrittenFiles = @();

    Write-Host Beginning transfer of files
    
    foreach ($commit in $commits) {

        # Get the list of files changed in the commit
        $files = git -C $global:source diff-tree --no-commit-id --name-only -r $commit 2>&1;
        
        # Copy each file to the destination path
        foreach ($file in $files) {

            # Write-host "second loop";

            $sourceFile = Join-Path -Path ($global:source) -ChildPath $file;
            $destFile = Join-Path -Path ($global:destination) -ChildPath $file;

            # Write-Host "$sourceFile"
            # Write-Host "$destFile"

            # Create the destination directory if it doesn't exist
            $destDir = Split-Path -Path $destFile -Parent;
            if (-not (Test-Path -Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force;
            }

            if (Test-Path -Path $sourceFile) {

                # Check if the file already exists in the destination path
                if ( -not (Test-Path -Path $destFile)) {
                    # Checks if the file doesn't already exist in the array
                    if ($newCopiedFiles -notcontains $file) {
                        $newCopiedFiles += $file; # adds the file name to the array
                    }
    
                }
                    
                else {
                    # Checks if the file doesn't already exist in the array
                    if ($overwrittenFiles -notcontains $file) {
                        $overwrittenFiles += $file; # adds the file name to the array
                    }
                }
    
                # Copy the file
                Copy-Item -Path $sourceFile -Destination $destFile -Force;
            }
        }
            

    }
  
    Write-Host "Files updated"
    Write-Host "";
    displayResults $newCopiedFiles $overwrittenFiles "1"
}

function displayResults($newCopiedFiles, $overwrittenFiles, $value) {

    if($value -eq "1"){
        # Check if the copiedFiles is empty
        if ($newCopiedFiles.Count -gt 0) {

            Write-Warning "The following files were copied to this path : $global:destination"
            $newCopiedFiles | Out-String # Display the array contents
            Write-Host ""
        }

        else {

            Write-Host "No new files were copied to this path : $global:destination"
            Write-Host "";
        }

        # Check if the copiedFiles is empty
        if ($overwrittenFiles.Count -gt 0) {

            Write-Warning "The following files were overwritten at this path : $global:destination"
            $overwrittenFiles | Out-String # Display the array contents
            Write-Host "";
        }

        else {

            Write-Host "No files were overwritten at this path : $global:destination"
            Write-Host "";
        }
    }
    else {
        # Check if the copiedFiles is empty
        if ($newCopiedFiles.Count -gt 0) {

            Write-Warning "The following files were copied to this path : $global:backup"
            $newCopiedFiles | Out-String # Display the array contents
            Write-Host ""
        }

        else {

            Write-Host "No new files were copied to this path : $global:backup"
            Write-Host "";
        }

        # Check if the copiedFiles is empty
        if ($overwrittenFiles.Count -gt 0) {

            Write-Warning "The following files were overwritten at this path : $global:backup"
            $overwrittenFiles | Out-String # Display the array contents
            Write-Host "";
        }

        else {

            Write-Host "No files were overwritten at this path : $global:backup"
            Write-Host "";
        }
    
    }


}

#---------------------- End of Methods --------------------------#



#------------------------- Call Statement ----------------------------#

if(isGitInstalled){
    Write-Host "Git found on the system"

    if (doesPathExist $global:source){
        Write-Host "Source Path exists"
    
        if (doesPathExist $global:destination){
            Write-Host "destination Path exists"
    
            
            if (doesPathExist $global:backup){
                Write-Host "backup Path exists"
    
                if(hasGitRepository($global:source)){
                    # $value = checkStatus;
                    # Write-Host "$value";
                    Write-Host "The project is a git repository";
            
                    if(checkStatus($global:source)){
                        Write-host "No modified files found"
                        Write-host "All code has been commited"
            
                        $commits = getCommits($global:source);
            
                        # Write-Host $commits
            
                        backupSource $commits
            
                        copyToDestination $commits
                    }
                    
                    else{
                        Write-host "Modified files found"
                        Write-host "Commit your changes first before moving any files"
                    }
            
                }
                
                else{
                    Write-host "The project is not a git repository";
                }
    
            }
    
            else{
                Write-Host "backup Path does not exist"
            }
    
        }
        
        else{
            Write-Host "destination Path does not exist"
        }
    }
    
    else{
        Write-Host "Source Path does not exist"
    }

}

else{
    Write-Warning "Git is not installed on your system"
    Write-Warning "Install git first before proceeding"
    Write-Warning Link : "https://git-scm.com/downloads/win"
}


#---------------------- End of Call --------------------------#