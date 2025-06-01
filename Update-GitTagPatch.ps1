
$destination_dir = "D:/destination_dir"
$url = "git@github.com:DavydMelnik/belhard-devops.git"


function Ensure-Dir {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirPath
    )
    
    if (Test-Path $DirPath) {
        Write-Host "The folder '$DirPath' already exists and will be overwritten"
        Read-Host "Press Enter to continue..."
        Remove-Item $DirPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $DirPath -ItemType Directory -Force > $null
}




Set-Location /
Ensure-Dir -DirPath $destination_dir
Set-Location -Path $destination_dir
try {
    $output = git clone $url $destination_dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cloning ERROR: $output"
    } else {
        Write-Host "Repository successfully cloned to $destination_dir"
    }
} catch {
    Write-Error "ERROR: $_"
}

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

Set-Location /
Remove-Item $destination_dir -Recurse -Force -ErrorAction SilentlyContinue