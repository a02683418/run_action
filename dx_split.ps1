param(
    [string]$OutputDir = "split_output"
)

$ErrorActionPreference = "Stop"

function Get-SafeFileName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $safe = $Name
    foreach ($ch in [System.IO.Path]::GetInvalidFileNameChars()) {
        $safe = $safe.Replace([string]$ch, "_")
    }
    return $safe
}

if (($OutputDir -eq '.') -or ($OutputDir -eq '.\')) {
    Write-Host "Error: output directory cannot be current directory (.)."
    exit 1
}

$cwd = (Get-Location).Path
$outputPath = Join-Path -Path $cwd -ChildPath $OutputDir

if (-not (Test-Path -LiteralPath $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$inputFileCount = 0
$totalReadLines = 0
$writtenLines = 0
$fileLineCounter = @{}

Write-Host "Start processing. Output directory: $outputPath"

$oldFiles = Get-ChildItem -LiteralPath $outputPath -File -Filter "*.csv" -ErrorAction SilentlyContinue
if ($null -ne $oldFiles -and @($oldFiles).Count -gt 0) {
    $oldCount = @($oldFiles).Count
    $oldFiles | Remove-Item -Force
    Write-Host "Cleaned old output files: $oldCount"
}

$inputFiles = Get-ChildItem -LiteralPath $cwd -File -Filter "*.csv"
foreach ($csvFile in $inputFiles) {
    $inputFileCount++
    Write-Host "Reading file: $($csvFile.FullName)"

    foreach ($line in Get-Content -LiteralPath $csvFile.FullName) {
        $totalReadLines++

        if ([string]::IsNullOrEmpty($line)) {
            continue
        }

        $commaIndex = $line.IndexOf(",")
        if ($commaIndex -lt 0) {
            continue
        }

        $rawName = $line.Substring(0, $commaIndex).TrimEnd("`r")
        $rawContent = $line.Substring($commaIndex + 1).TrimEnd("`r")

        if ([string]::IsNullOrEmpty($rawName)) {
            continue
        }

        $safeName = Get-SafeFileName -Name $rawName
        $outFile = Join-Path -Path $outputPath -ChildPath ($safeName + ".csv")

        Add-Content -LiteralPath $outFile -Value $rawContent -Encoding UTF8
        $writtenLines++

        if ($fileLineCounter.ContainsKey($safeName)) {
            $fileLineCounter[$safeName]++
        }
        else {
            $fileLineCounter[$safeName] = 1
        }
    }
}

Write-Host ""
Write-Host "Per output file line count:"
foreach ($k in ($fileLineCounter.Keys | Sort-Object)) {
    Write-Host ("{0}.csv: {1}" -f $k, $fileLineCounter[$k])
}

$outputFileCount = @(
    Get-ChildItem -LiteralPath $outputPath -File -Filter "*.csv" -ErrorAction SilentlyContinue
).Count

Write-Host ""
Write-Host "Done:"
Write-Host "Input file count: $inputFileCount"
Write-Host "Total lines read: $totalReadLines"
Write-Host "Total lines written: $writtenLines"
Write-Host "Output file count: $outputFileCount"
