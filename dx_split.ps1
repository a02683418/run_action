param(
    [string]$OutputDir = "split_output"
)

$ErrorActionPreference = "Stop"

if ($OutputDir -eq "." -or $OutputDir -eq ".\") {
    Write-Host "错误: 输出目录不能是当前目录(.)，否则会覆盖输入文件。"
    exit 1
}

$outputPath = Join-Path -Path (Get-Location) -ChildPath $OutputDir
if (-not (Test-Path -LiteralPath $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$inputFileCount = 0
$totalReadLines = 0
$writtenLines = 0
$fileLineCounter = @{}

Write-Host "开始处理，输出目录: $outputPath"

$oldFiles = Get-ChildItem -LiteralPath $outputPath -File -Filter "*.csv" -ErrorAction SilentlyContinue
if ($oldFiles) {
    $oldCount = @($oldFiles).Count
    $oldFiles | Remove-Item -Force
    Write-Host "已清理旧输出文件: $oldCount 个"
}

$inputFiles = Get-ChildItem -LiteralPath (Get-Location) -File -Filter "*.csv"
foreach ($csvFile in $inputFiles) {
    $inputFileCount++
    Write-Host "读取文件: $($csvFile.FullName)"

    foreach ($line in Get-Content -LiteralPath $csvFile.FullName) {
        $totalReadLines++

        if ([string]::IsNullOrEmpty($line)) {
            continue
        }

        if (-not $line.Contains(",")) {
            continue
        }

        $parts = $line -split ",", 2
        $rawName = $parts[0].TrimEnd("`r")
        $rawContent = $parts[1].TrimEnd("`r")

        if ([string]::IsNullOrEmpty($rawName)) {
            continue
        }

        # Windows 非法文件名字符替换
        $safeName = $rawName -replace '[<>:"/\\|?*]', "_"
        $outFile = Join-Path -Path $outputPath -ChildPath ($safeName + ".csv")

        Add-Content -LiteralPath $outFile -Value $rawContent -Encoding UTF8
        $writtenLines++

        if ($fileLineCounter.ContainsKey($safeName)) {
            $fileLineCounter[$safeName]++
        } else {
            $fileLineCounter[$safeName] = 1
        }
    }
}

Write-Host ""
Write-Host "每个输出文件对应行数："
foreach ($k in ($fileLineCounter.Keys | Sort-Object)) {
    Write-Host ("{0}.csv: {1}" -f $k, $fileLineCounter[$k])
}

$outputFileCount = @((Get-ChildItem -LiteralPath $outputPath -File -Filter "*.csv" -ErrorAction SilentlyContinue)).Count

Write-Host ""
Write-Host "处理完成："
Write-Host "输入文件数: $inputFileCount"
Write-Host "读取总行数: $totalReadLines"
Write-Host "成功写入行数: $writtenLines"
Write-Host "输出文件数: $outputFileCount"
