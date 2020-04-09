# Main script
# The part of FLAC Recompress Tool
# Author: Antidotes
# Source: 
# Licenced by GPLv3
# Version: 0.1.0 Alpha
###########################################################################
[CmdletBinding()]
param (
    [String]$h,
    [String]$Help,
    [String]$l,
    [String]$Log,
    [String]$o,
    [String]$Output,
    [String]$p,
    [String]$Path,
    [String]$t,
    [String]$Thread
)
if ($l) { $Log = $h }
if ($o) { $Output = $o }
if ($p) { $Path = $p }
if ($t) { $Thread = $t }

Write-Output "FLAC Recompress Tool"
Write-Output "Detecting and Optimization enviroument"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PSVersion = $PSVersionTable.PSVersion.major
$BinaryFLAC = "$ScriptPath/bin/flac.exe"
$BinaryMetaFLAC = "$ScriptPath/bin/metaflac.exe"
if (-not $LogFilePath) {
    $LogFilePath = $env:TEMP
}
if (-not $Thread) {
    $SystemCPUInfo = Get-WmiObject -Class Win32_Processor
    $CoreNumber = Select-Object -InputObject $SystemCPUInfo -ExpandProperty NumberOfLogicalProcessors 
    if ($CoreNumber -le 2) {
        $CoreNumber *= @($SystemCPUInfo).Count
    }
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
& $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource"
if (Get-Item $Path | Select-Object -ExpandProperty Mode | Select-String "d") {
    $FileList = Get-ChildItem -Recurse -Include "*.flac" | Select-Object "Name"
}
else {
    
}
Write-Output "Getting Filelist"
$FileList = Get-ChildItem -Path $Scriptpath -Filter "*.flac" -Recurse | Select-Object DirectoryName, Name, Length 
$FileList | ForEach-Object {
    $FileSource = $_.DirectoryName + "\" + $_.Name
    $FileOutput = "C:\Users\Microsoft\Desktop" + "\" + $_.Name
    $JobScriptBlock = [scriptblock]::Create("
    $BinaryFLAC -fsw8 -V -o '$FileOutput' '$FileSource'
    Write-Host '$FileSource'(Get-ChildItem '$FileOutput').Length")
    $JobStart = Start-Job -ScriptBlock $JobScriptBlock
    while ((Get-Job).count -eq 3) {
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
