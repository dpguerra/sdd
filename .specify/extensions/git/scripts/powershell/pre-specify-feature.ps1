#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$DryRun,
    [string]$ShortName,
    [long]$Number = 0,
    [switch]$Timestamp,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..\..\..')).Path
$markerPath = Join-Path $repoRoot '.specify\extensions\git\feature-branch-context.json'
$createScript = Join-Path $PSScriptRoot 'create-new-feature-branch.ps1'
$featureDirectory = $env:SPECIFY_FEATURE_DIRECTORY

function Get-FeaturePath {
    param([string]$Path)
    if (-not [IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path $repoRoot $Path
    }
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

if ($featureDirectory -and (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
    $marker = Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $marker.feature_directory -or -not $marker.branch_name) {
        throw "Invalid feature branch context in '$markerPath': feature_directory and branch_name are required."
    }

    $pathComparison = if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        [StringComparison]::OrdinalIgnoreCase
    } else {
        [StringComparison]::Ordinal
    }
    $requestedPath = Get-FeaturePath $featureDirectory
    $recordedPath = Get-FeaturePath $marker.feature_directory
    if ([string]::Equals($requestedPath, $recordedPath, $pathComparison)) {
        $actualBranch = (git -C $repoRoot symbolic-ref --quiet --short HEAD)
        if ($LASTEXITCODE -ne 0 -or -not $actualBranch) {
            throw "Feature branch mismatch: expected '$($marker.branch_name)', actual '<detached or unavailable>'."
        }
        if ($actualBranch -cne $marker.branch_name) {
            throw "Feature branch mismatch: expected '$($marker.branch_name)', actual '$actualBranch'."
        }
        if ($env:GIT_BRANCH_NAME -and $env:GIT_BRANCH_NAME -cne $marker.branch_name) {
            throw "Feature branch mismatch: expected '$($marker.branch_name)', requested '$env:GIT_BRANCH_NAME', actual '$actualBranch'."
        }
        if (-not (Test-Path -LiteralPath $requestedPath -PathType Container)) {
            throw "Recorded feature directory does not exist: '$featureDirectory'."
        }
        $segment = ($actualBranch -split '/')[-1]
        $featureNum = if ($segment -match '^(\d{8}-\d{6})-') {
            $Matches[1]
        } elseif ($segment -match '^(\d+)-') {
            $Matches[1]
        } else {
            $actualBranch
        }
        [Console]::Error.WriteLine("[specify] Feature branch precondition already satisfied: $actualBranch")
        if ($Json) {
            [PSCustomObject]@{ BRANCH_NAME = $actualBranch; FEATURE_NUM = $featureNum } | ConvertTo-Json -Compress
        } else {
            Write-Output "BRANCH_NAME: $actualBranch"
            Write-Output "FEATURE_NUM: $featureNum"
        }
        exit 0
    }
    if (Test-Path -LiteralPath $requestedPath) {
        throw "Feature context mismatch: recorded '$($marker.feature_directory)' on branch '$($marker.branch_name)'; requested '$featureDirectory'. Start a new synchronization explicitly before replacing the marker."
    }
}

$arguments = @('-NoProfile', '-File', $createScript, '-Json')
if ($DryRun) { $arguments += '-DryRun' }
if ($ShortName) { $arguments += @('-ShortName', $ShortName) }
if ($PSBoundParameters.ContainsKey('Number')) { $arguments += @('-Number', $Number.ToString()) }
if ($Timestamp) { $arguments += '-Timestamp' }
$arguments += $FeatureDescription
$shell = (Get-Process -Id $PID).Path
$result = & $shell @arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$created = $result | ConvertFrom-Json
if (-not $created.BRANCH_NAME -or -not $created.FEATURE_NUM) {
    throw 'Branch creation returned an invalid result.'
}
if (-not $DryRun -and $featureDirectory) {
    $actualBranch = (git -C $repoRoot symbolic-ref --quiet --short HEAD)
    if ($LASTEXITCODE -ne 0 -or $actualBranch -cne $created.BRANCH_NAME) {
        throw "Cannot record feature context: expected branch '$($created.BRANCH_NAME)', actual '$actualBranch'."
    }
    $marker = [PSCustomObject]@{
        feature_directory = $featureDirectory
        branch_name = $created.BRANCH_NAME
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($markerPath, ($marker | ConvertTo-Json) + "`n", $utf8)
}
if ($Json) {
    $result
} else {
    Write-Output "BRANCH_NAME: $($created.BRANCH_NAME)"
    Write-Output "FEATURE_NUM: $($created.FEATURE_NUM)"
}
