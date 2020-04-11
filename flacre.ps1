# Main script
# The part of FLAC Recompress Tool
# Author: Antidotes
# Source: https://github.com/Antidoteseries/FLAC-Recompress-Tool
# Licenced by GPLv3
# Version: 0.4.0 Alpha
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
if ( $l ) { $LogFilePath = $l } else { $LogFilePath = $log }
if ( $o ) { $OutputPath = $o } else { $OutputPath = $output }
if ( $p ) { $InputPath = $p } else { $InputPath = $path }
if ( $t ) { $RunspaceMax = $t } else { $RunspaceMax = $thread }
function Write-Uniout ( $WritePlace, $WriteType, $WriteContent ) {
    $WindowWidth = $host.UI.RawUI.WindowSize.Width
    $WindowHeight = $host.UI.RawUI.WindowSize.Height
    $WriteColor = $host.UI.RawUI.ForegroundColor
    switch ( $WriteType ) {
        "Verbose" { $WriteContent = "- " + $WriteContent }
        "Info" { $WriteContent = "> " + $WriteContent }
        "Warning" { $WriteContent = "Warning: " + $WriteContent; $WriteColor = "Yellow" }
        "Error" { $WriteContent = "Error: " + $WriteContent; $WriteColor = "Red" }
        "Center" { $WriteContent = " " * (($WindowWidth - $WriteContent.Length) / 2 - 4) + $WriteContent }
        "Divide" { $WriteContent = "-" * ($WindowWidth - 8) }
        "Empty" { $WriteContent = "" }
        "Done" { $WriteColor = "Green" }
    }
    if ($WritePlace -match "s") {
        $WriteContent = "    " + $WriteContent
        Write-Host -ForegroundColor $WriteColor $WriteContent
    }
    if ($WritePlace -match "l") {
        Out-File -FilePath $LogFilePath -Encoding utf8 -InputObject $WriteContent -Append
    }
}

$ScriptPath = $MyInvocation.MyCommand.Definition
$ScriptFolder = Split-Path -Parent $ScriptPath
$PSVercode = $PSVersionTable.PSVersion.major
if ( $PSVercode -lt 5 ) {
    Write-Uniout "ls" "Error" "PowerShell Version is too low. Please update your PowerShell or install PowerShell Core."
    exit 1
}
if ( -not $LogFilePath ) {
    $LogFilePath = $env:TEMP + "\FLACRecompress_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".log"
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
# No Paramater start
if ( -not $InputPath ) { 
    $InputPath = Read-Host "     Input file or folder path (-p)"
    $OutputPath = Read-Host "    Output file or folder path (-o)"
}
# Initialize Paramaters
if ( -not $InputPath ) { 
    Write-Uniout "ls" "Warning" "Unspecified Inputpath. Using $ScriptFolder as Inputpath."
    $InputPath = $ScriptFolder 
}
elseif ( -not (Test-Path $InputPath) ) {
    Write-Uniout "ls" "Error" "Target File or Folder isn't existed."
    exit 3
}
elseif ( $InputPath.EndsWith("\") ) { 
    $InputPath = $InputPath.Remove($InputPath.Length - 1) 
}
if ( -not $OutputPath ) {
    Write-Uniout "ls" "Warning" "Unspecified Ouputpath. All recompressed file will output to the same folder and named as *_Recompress.flac"
    $FileSuffix = "_Recompressed.flac"
    $OutputPath = $InputPath
}
else {
    $FileSuffix = ".flac"
}
if ( -not $RunspaceMax ) {
    $CoreNumber = [System.Environment]::ProcessorCount
    if ( $CoreNumber -ge 2 ) {
        $RunspaceMax = [int]( $CoreNumber / 2 )
    }
}
elseif ( $RunspaceMax -le 0 ) {
    Write-Uniout "ls" "Error" "Illegal Thread number"
    exit 5
}

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
Write-Uniout "l" "Verbose" "$OSArchitecture"
Write-Uniout "l" "Verbose" "$OSDescription"

if ( Get-Item $InputPath | Select-Object -ExpandProperty Mode | Select-String "d" ) {
    # Folder Mode
    if ( $OutputPath -match "\.flac" ) {
        Write-Uniout "ls" "Error" "Invaild Output folder"
        exit 4
    }
    Write-Uniout "ls" "Info" "Getting Filelist"
    $FileList = Get-ChildItem -Path $InputPath -Filter "*.flac" -Recurse -Exclude "*_Recompressed.flac" | Select-Object DirectoryName, Name, Length
    if (-not $FileList) {
        Write-Uniout "ls" "Warning" "No FLAC file found."
        exit 0
    }
    Write-Uniout "ls" "Info" "Starting compress"
    $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $RunspaceMax)
    $RunspacePool.Open()
    $aryPowerShell = New-Object System.Collections.ArrayList
    $aryIAsyncResult = New-Object System.Collections.ArrayList
    try {
        $FileList | ForEach-Object {
            $FileSource = $_.DirectoryName + "\" + $_.Name
            $FileLengthOri = $_.Length
            $FileRelativePath = ($_.DirectoryName).Replace($InputPath, "")
            $FileName = ($_.Name).Replace(".flac", "")
            $FileOutput = "$OutputPath" + "$FileRelativePath" + "\" + "$FileName" + "$FileSuffix"
            $FileOutputFolder = "$OutputPath" + "$FileRelativePath"
            if ( -not (Test-Path $FileOutputFolder) ) {
                New-Item -Path $FileOutputFolder -ItemType Directory -Force | Out-Null
            }
            $PSObject = [PowerShell]::Create()
            $PSObject.RunspacePool = $RunspacePool
            $PSSubScript = {
                [CmdletBinding()]
                param(
                    [parameter(mandatory, position = 0)][string]$BinaryFLAC,
                    [parameter(mandatory, position = 1)][string]$FileOutput,
                    [parameter(mandatory, position = 2)][string]$FileSource
                )
                & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource"
            }
            $PSObject.AddScript($PSSubScript).AddArgument($BinaryFLAC).AddArgument($FileOutput).AddArgument($FileSource).AddCommand("Out-String") | Out-Null
            $IASyncResult = $PSObject.BeginInvoke()
            $aryPowerShell.Add($PSObject) | Out-Null
            $aryIAsyncResult.Add($IASyncResult) | Out-Null
        }
        while ($aryPowerShell.Count -gt 0) {
            for ($i = 0; $i -lt $aryPowerShell.Count; $i++) {
                $PSObject = $aryPowerShell[$i]
                $IASyncResult = $aryIAsyncResult[$i]
                if ($IASyncResult.IsCompleted -eq $true) {
                    $AsyncResult = $PSObject.EndInvoke($IASyncResult)
                    $PSObject.Dispose()
                    $aryPowerShell.RemoveAt($i)
                    $aryIAsyncResult.RemoveAt($i)
                }
            }
            Start-Sleep -Seconds 1
        }
    }
    finally {
        $RunspacePool.Close()
    }
}
else {
    # Single File Mode
    $FileSource = $InputPath
    if ( $OutputPath -match "\.flac" ) {
        $FileOutput = "$OutputPath"
    }
    else {
        if ( $PSVercode -le 5 ) {
            $FileName = (Split-Path -Path $FileSource -Leaf).Replace("\.[^.]+$", "")
        }
        else {
            $FileName = Split-Path -Path $FileSource -LeafBase
        }
        $FileOutput = "$OutputPath" + "\" + "$FileName" + "$FileSuffix"
    }
    & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource"
}
Write-Uniout "ls" "Done" "Completed"
# Notify for Windows
if ( [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows) ) {  
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    $Notify = New-Object System.Windows.Forms.NotifyIcon
    $PSHostPath = Get-Process -id $pid | Select-Object -ExpandProperty Path
    $PSIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHostPath)
    $Notify.Icon = $PSIcon
    $Notify.BalloonTipTitle = "FLAC Recompress Tool"
    $Notify.BalloonTipIcon = "Info"
    $Notify.BalloonTipText = "Completed"
    $Notify.Visible = $true
    $Notify.ShowBalloonTip(5000)
}