# Main script
# The part of FLAC Recompress Tool
# Author: Antidotes
# Source: https://github.com/Antidoteseries/FLAC-Recompress-Tool
# Licenced by GPLv3
# Version: 0.3.0 Alpha
###########################################################################
[CmdletBinding()]
param (
    [string]$h,
    [string]$help,
    [string]$l,
    [string]$log,
    [string]$o,
    [string]$output,
    [string]$p,
    [string]$path,
    [string]$t,
    [string]$thread
)
if ( $l ) { $LogFilePath = $l } else { $LogFilePath = $Log }
if ( $o ) { $Output = $o } else { $Output = $output }
if ( $p ) { $InputPath = $p } else { $InputPath = $path }
if ( $t ) { $ThreadNumber = $t } else { $ThreadNumber = $thread }

# Initialize Paramaters
$ScriptPath = $MyInvocation.MyCommand.Definition
$ScriptFolder = Split-Path -Parent $ScriptPath
$PSVercode = $PSVersionTable.PSVersion.major
if ( $PSVercode -lt 5 ) {
    Write-Uniout "ls" "Info" "Error: PowerShell Version is too low. Please update your PowerShell or install PowerShell Core."
    exit 1
}
if ( -not $LogFilePath ) {
    $LogFilePath = $env:TEMP + "\FLACRecompress_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".log"
}
if ( -not $ThreadNumber ) {
    $CoreNumber = [System.Environment]::ProcessorCount
    if ( $CoreNumber -ge 2 ) {
        $ThreadNumber = $CoreNumber - 1 
    }
}
elseif ( $ThreadNumber -le 0 ) {
    Write-Uniout "ls" "Info" "Error: Illegal Thread number"
    exit 5
}
if ( -not $InputPath ) { 
    $InputPath = $ScriptFolder 
}
elseif ( -not (Test-Path $InputPath) ) {
    Write-Uniout "ls" "Info" "Error: Target File or Folder isn't existed."
    exit 3
}
elseif ( $InputPath.EndsWith("\") ) { 
    $InputPath = $InputPath.Remove($InputPath.Length - 1) 
}
if ( -not $Output ) {
    $FileSuffix = "_Recompressed.flac"
    $Output = $InputPath
}
else {
    $FileSuffix = ".flac"
}

function Write-Uniout ( $WritePlace, $WriteType, $WriteContent ) {
    $WindowWidth = $host.UI.RawUI.WindowSize.Width
    $WindowHeight = $host.UI.RawUI.WindowSize.Height
    $WriteColor = $host.UI.RawUI.ForegroundColor
    switch ( $WriteType ) {
        "Verbose" { $WriteContent = "- " + $WriteContent }
        "Info" { $WriteContent = "> " + $WriteContent }
        "Warning" { $WriteContent = "Warning: " + $WriteContent; $WriteColor = "Yellow" }
        "Error" { $WriteContent = "Error:   "; $WriteColor = "Red" }
        "Center" { $WriteContent = " " * (($WindowWidth - $WriteContent.Length) / 2 - 4) + $WriteContent }
        "Divide" { $WriteContent = "-" * ($WindowWidth - 8) }
        "Empty" { $WriteContent = "" }
    }
    if ($WritePlace -match "s") {
        $WriteContent = "    " + $WriteContent
        Write-Host -ForegroundColor $WriteColor $WriteContent
    }
    if ($WritePlace -match "l") {
        Out-File -FilePath $LogFilePath -Encoding utf8 -InputObject $WriteContent -Append
    }

}

Clear-Host
$ScriptInfo = Get-content -Path $ScriptPath -TotalCount 6
$host.UI.RawUI.WindowTitle = "FLAC Recompress Tool"
Write-Uniout "s" "Empty"
Write-Uniout "ls" "Center" ("FLAC Recompress Tool" + $ScriptInfo[5].Replace("# Version:", ""))
Write-Uniout "ls" "Center" $ScriptInfo[2].Replace("# ", "")
Write-Uniout "ls" "Center" $ScriptInfo[4].Replace("# ", "")
Write-Uniout "ls" "Center" $ScriptInfo[3].Replace("# Source: ", "")
Write-Uniout "ls" "Divide"
Write-Uniout "ls" "Info" "Detecting and Optimization enviroument"

# Detect OS and Architecture
if ( $PSVersionTable.PSEdition -eq "Core" ) {
    $OSArchitecture = [string][System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    $OSDescription = [string][System.Runtime.InteropServices.RuntimeInformation]::OSDescription
}
else {
    if ( [System.Environment]::Is64BitOperatingSystem ) {
        $OSArchitecture = "X64"
    }
    # For Windows on ARM devices, Windows PowerShell always running on x86-compatible mode.
    elseif ( Test-Path "C:\Windows\SysArm32\cmd.exe" ) {
        if ( Test-Path "C:\Windows\SysWow64\cmd.exe" ) { 
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
if ( [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows) ) {
    switch ( $OSArchitecture ) {
        "X64" {
            $BinaryFLAC = "$ScriptFolder\bin\x64\flac.exe"
            $BinaryMetaFLAC = "$ScriptFolder\bin\x64\metaflac.exe" 
        }
        "X86" {
            $BinaryFLAC = "$ScriptFolder\bin\x86\flac.exe"
            $BinaryMetaFLAC = "$ScriptFolder\bin\x86\metaflac.exe" 
        }
        "Arm64" {
            $BinaryFLAC = "$ScriptFolder\bin\x86\flac.exe"
            $BinaryMetaFLAC = "$ScriptFolder\bin\x86\metaflac.exe" 
            Write-Uniout "ls" "Warning" "Detected ARM64 Devices. FLAC will running in x86-compatible mode."
        }
        "Arm" {
            Write-Uniout "ls" "Error" "Detected ARM Devices. Not support your device yet."
            exit 2
        }
    }
}
else {
    $BinaryFLAC = "flac"
    $BinaryMetaFLAC = "metaflac" 
    Write-Uniout "ls" "Verbose" "Detected Linux or macOS. Using your system FLAC binary."
}

if ( Get-Item $InputPath | Select-Object -ExpandProperty Mode | Select-String "d" ) {
    # Folder Mode
    if ( $Output -match "\.flac" ) {
        Write-Uniout "ls" "Error" "Invaild Output folder"
        exit 4
    }
    Write-Uniout "ls" "Info" "Getting Filelist"
    $FileList = Get-ChildItem -Path $ScriptFolder -Filter "*.flac" -Recurse | Select-Object DirectoryName, Name, Length 
    if (-not $FileList) {
        Write-Uniout "ls" "Warning" "No FLAC file found."
        exit 0
    }
    $FileList | ForEach-Object {
        $FileSource = $_.DirectoryName + "\" + $_.Name
        $FileRelativePath = ($_.DirectoryName).Replace($InputPath, "")
        $FileName = ($_.Name).Replace(".flac", "")
        $FileOutput = "$Output" + "$FileRelativePath" + "\" + "$FileName" + "$FileSuffix"
        $FileOutputFolder = "$Output" + "$FileRelativePath"
        if ( -not (Test-Path $FileOutputFolder) ) {
            New-Item -Path $FileOutputFolder -ItemType Directory -Force >null
        }
        if ( $ThreadNumber -eq 1 ) {
            & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource"
            Write-Host "$FileSource"(Get-ChildItem "$FileOutput").Length
        }
        else {
            $JobScriptBlock = [scriptblock]::Create("
                $BinaryFLAC -fsw8 -V -o '$FileOutput' '$FileSource'
                Write-Host '$FileSource'(Get-ChildItem '$FileOutput').Length")
            Start-Job -ScriptBlock $JobScriptBlock >null
            while ( (Get-Job).count -eq $ThreadNumber ) {
                Start-Sleep 1
                foreach ( $Job in Get-Job ) {
                    if ( $Job.State -eq "Completed" ) {
                        Receive-Job $Job
                        Remove-Job $Job
                    }
                }
            }
        }   
    }
    while ( (Get-Job).count -gt 0 ) {
        Start-Sleep 1
        foreach ( $Job in Get-Job ) {
            if ( $Job.State -eq "Completed" ) {
                Receive-Job $Job
                Remove-Job $Job
            }
        }
    }   
}
else {
    # Single File Mode
    $FileSource = $InputPath
    if ( $Output -match "\.flac" ) {
        $FileOutput = "$Output"
    }
    else {
        if ( $PSVercode -le 5 ) {
            $FileName = (Split-Path -Path $FileSource -Leaf).Replace("\.[^.]+$", "")
        }
        else {
            $FileName = Split-Path -Path $FileSource -LeafBase
        }
        $FileOutput = "$Output" + "\" + "$FileName" + "$FileSuffix"
    }
   
    & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource"
}
Write-Uniout "ls" "Info" "Completed"
