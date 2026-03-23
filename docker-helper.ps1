function Split-CommandLine([string]$cmdLine) {
    # Split on whitespace, but keep quoted sections together.
    # This also handles mixed-quoted tokens like "C:\path":/container:mode.
    $pattern = '(?:"[^"]*"|[^\s"])+'
    [regex]::Matches($cmdLine, $pattern) | ForEach-Object {
        # Strip all surrounding/embedded quotes from each token
        $_.Value -replace '"', ''
    }
}

function Convert-VolumeSpec([string]$spec) {
    # Match C:\windows\path:/container/path[:mode]
    if ($spec -match '^([A-Za-z]):\\(.+?):(/.+)$') {
        $drive = $Matches[1].ToLower()
        $path  = $Matches[2] -replace '\\', '/'
        $rest  = $Matches[3]
        return "/mnt/$drive/$path`:$rest"
    }
    return $spec
}

$rawCmd = $env:DOCKER_PROXY_ARGS
if (-not $rawCmd) {
    & wsl docker
    exit $LASTEXITCODE
}

$parsed = @(Split-CommandLine $rawCmd)

$convertedArgs = [System.Collections.Generic.List[string]]::new()
$awaitVolume   = $false

foreach ($arg in $parsed) {
    if ($awaitVolume) {
        $convertedArgs.Add((Convert-VolumeSpec $arg))
        $awaitVolume = $false
    } elseif ($arg -eq '-v' -or $arg -eq '--volume') {
        $convertedArgs.Add($arg)
        $awaitVolume = $true
    } elseif ($arg -match '^--volume=(.+)$') {
        $convertedArgs.Add("--volume=$(Convert-VolumeSpec $Matches[1])")
    } else {
        $convertedArgs.Add($arg)
    }
}

if ($env:DOCKER_PROXY_DEBUG) {
    Write-Host "[docker-proxy] raw  : $rawCmd" -ForegroundColor Cyan
    Write-Host "[docker-proxy] args : $($convertedArgs -join ' | ')" -ForegroundColor Cyan
}

& wsl docker @convertedArgs
exit $LASTEXITCODE

