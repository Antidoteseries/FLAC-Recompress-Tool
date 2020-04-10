# Main script
# The part of FLAC Recompress Tool
# Author: Antidotes
# Source: https://github.com/Antidoteseries/FLAC-Recompress-Tool
# Licenced by GPLv3
# Version: 0.2.0 Alpha
###########################################################################
[CmdletBinding()]
param (
    [string]$h,
    [string]$Help,
    [string]$l,
    [string]$Log,
    [string]$o,
    [string]$Output,
    [string]$p,
    [string]$Path,
    [string]$t,
    [string]$Thread
)
if ($l) { $Log = $h }
if ($o) { $Output = $o }
if ($p) { $Path = $p }
if ($t) { $Thread = $t }

Write-Output "FLAC Recompress Tool"
Write-Output "Detecting and Optimization enviroument"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PSVersion = $PSVersionTable.PSVersion.major
if ($PSVersion -lt 5) {
    Write-Output "Error: PowerShell Version is too low. Please update your PowerShell or install PowerShell Core."
    exit 1
}

# Detect OS and Architecture
if ($PSVersionTable.PSEdition -eq "Core") {
    $OSArchitecture = [string][System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    $OSDescription = [string][System.Runtime.InteropServices.RuntimeInformation]::OSDescription
}
else {
    if ([System.Environment]::Is64BitOperatingSystem) {
        $OSArchitecture = "X64"
    }
    # For Windows on ARM devices, Windows PowerShell always running on x86-compatible mode.
    elseif (Test-Path "C:\Windows\SysArm32\cmd.exe") {
        if (Test-Path "C:\Windows\SysWow64\cmd.exe") { 
            $OSArchitecture = "Arm64"
        }
        else { 
            $OSArchitecture = "Arm" 
        }
    }
    else {
        $OSArchitecture = "X86"
    }
    $OSDescription = [System.Environment]::OSVersion.VersionString
}
$OSArchitecture
if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
    switch ($OSArchitecture) {
        "X64" {
            $BinaryFLAC = "$ScriptPath\bin\x64\flac.exe"
            $BinaryMetaFLAC = "$ScriptPath\bin\x64\metaflac.exe" 
        }
        "X86" {
            $BinaryFLAC = "$ScriptPath\bin\x86\flac.exe"
            $BinaryMetaFLAC = "$ScriptPath\bin\x86\metaflac.exe" 
        }
        "Arm64" {
            $BinaryFLAC = "$ScriptPath\bin\x86\flac.exe"
            $BinaryMetaFLAC = "$ScriptPath\bin\x86\metaflac.exe" 
            Write-Output "Detected ARM64 Devices. FLAC will running in x86-compatible mode."
        }
        "Arm" {
            Write-Output "Detected ARM Devices. Not support your device yet."
            exit 2
        }
    }
}
else {
    $BinaryFLAC = "flac"
    $BinaryMetaFLAC = "metaflac" 
    Write-Output "Detected Linux or macOS. Using your system FLAC binary."
}

if (-not $LogFilePath) {
    $LogFilePath = $env:TEMP
}
if (-not $Thread) {
    $CoreNumber = [System.Environment]::ProcessorCount
    if ($CoreNumber -le 2) {
        $Thread = 1
    }
    else {
        $Thread = $CoreNumber - 1
    }
}
if (-not $Path) {
    $Path = $ScriptPath
}
if (-not $Output) {
    $FileSuffix = "_Recompressed.flac"
    $Output = $Path
}
else {
    $FileSuffix = ".flac"
}

if (-not (Test-Path $Path)) {
    Write-Output "Error: Target File or Folder isn't existed."
    exit 3
}
if (Get-Item $Path | Select-Object -ExpandProperty Mode | Select-String "d") {
    # Folder Mode
    if ($Output -match ".flac") {
        Write-Output "Error: Invaild Output folder"
        exit 4
    }
    Write-Output "Getting Filelist"
    $FileList = Get-ChildItem -Path $Scriptpath -Filter "*.flac" -Recurse | Select-Object DirectoryName, Name, Length 
    $FileList | ForEach-Object {
        $FileSource = $_.DirectoryName + "\" + $_.Name
        $FileRelativePath = ($_.DirectoryName).Replace($Path, "")
        $FileName = ($_.Name).Replace(".flac", "")
        $FileOutput = "$Output" + "$FileRelativePath" + "\" + "$FileName" + "$FileSuffix"
        $FileOutputFolder = "$Output" + "$FileRelativePath"
        if (-not (Test-Path $FileOutputFolder)) {
            New-Item -Path $FileOutputFolder -ItemType Directory -Force >null
        }
        $JobScriptBlock = [scriptblock]::Create("
        $BinaryFLAC -fsw8 -V -o '$FileOutput' '$FileSource'
        Write-Host '$FileSource'(Get-ChildItem '$FileOutput').Length")
        Start-Job -ScriptBlock $JobScriptBlock >null
        while ((Get-Job).count -eq $Thread) {
            Start-Sleep 1
            foreach ($Job in Get-Job) {
                if ($Job.State -eq "Completed") {
                    Receive-Job $Job
                    Remove-Job $Job
                }
            }
        }   
    }
    while ((Get-Job).count -gt 0) {
        Start-Sleep 1
        foreach ($Job in Get-Job) {
            if ($Job.State -eq "Completed") {
                Receive-Job $Job
                Remove-Job $Job
            }
        }
    }   
}
else {
    # Single File Mode
    $FileSource = $Path
    $FileOutput = $Output
    & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource"
}

