# --- Variable Declarations ---
# Define target directory and repository URL
$destinationDirectory = "D:/destination_dir"
$repositoryUrl = "git@github.com:DavydMelnik/belhard-devops.git"

# --- Function Definitions ---
#Ensures directory exists or creates it
function Ensure-Dir {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirPath
    )
    Set-Location /
    if (Test-Path $DirPath) {
        Write-Host "The folder '$DirPath' already exists and will be overwritten"
        Read-Host "Press Enter to continue..."
        Remove-Item $DirPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $DirPath -ItemType Directory -Force > $null
}

#Clones a Git repository with error handling
function Invoke-GitRepositoryClone {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RepositoryUrl,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetDirectory
    )
    try {
        $output = git clone $RepositoryUrl $TargetDirectory 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Cloning ERROR: $output"
        } else {
            Write-Host "Repository successfully cloned to $TargetDirectory"
        }
    } catch {
        Write-Error "ERROR: $_"
    }
}

#Processes Git tags and increments version if needed
function Update-TagPatch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepositoryPath
    )
    Set-Location $RepositoryPath
    $tagInfo = git describe --tags --long 2>$null
    if (-not $tagInfo) {
        Write-Host "No Tags. Exit"
        exit 1
    }
    if ($tagInfo -match '^(.+)-(\d+)-g[0-9a-f]+$') {
        $lastTag = $matches[1]
        $commitsAfterTag = [int]$matches[2]
        
        if ($commitsAfterTag -gt 0) {
            Write-Host "There are new commits after the tag $lastTag ($commitsAfterTag commits)"
                
            if ($lastTag -match '^v?(\d+)\.(\d+)\.(\d+)$') {
                $newTag = "v$($matches[1]).$($matches[2]).$([int]$matches[3] + 1)"
                git tag -a $newTag -m "chore(release): auto-increment patch version to $newTag"
                try {
                    $output = git push origin $newTag 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Pushing new tag ERROR: $output"
                    } else {
                        Write-Host "Tag created: $newTag"
                    }
                } catch {
                    Write-Error "ERROR: $_"
                    }
            } else {
                Write-Error "Invalid tag format: $lastTag"
            }

        } else {
            Write-Host "No changes"
        }

    } else {
        Write-Host "No changes"
    }

}

#Deleting local directory
function Remove-LocalDirectory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RepositoryPath
    )
    Set-Location /
    Remove-Item $RepositoryPath -Recurse -Force -ErrorAction SilentlyContinue
} 

# --- Main execution ---
Ensure-Dir -DirPath $destinationDirectory
Invoke-GitRepositoryClone -RepositoryUrl $repositoryUrl -TargetDirectory $destinationDirectory
Update-TagPatch -RepositoryPath $destinationDirectory
Remove-LocalDirectory -RepositoryPath $destinationDirectory