# Main script
# The part of FLAC Recompress Tool
# Author: Antidotes
# Source: https://github.com/Antidoteseries/FLAC-Recompress-Tool
# Licenced by GPLv3
# Version: 0.7.3 Beta
###########################################################################
[CmdletBinding()]
param (
    [switch]$h,
    [switch]$help,
    [string]$l,
    [string]$log,
    [string]$o,
    [string]$output,
    [string]$p,
    [string]$path,
    [string]$s,
    [string]$suffix,
    [int]$t,
    [int]$thread
)
if ( $l ) { $LogFilePath = $l } else { $LogFilePath = $log }
if ( $o ) { $OutputPath = $o } else { $OutputPath = $output }
if ( $p ) { $InputPath = $p } else { $InputPath = $path }
if ( $t ) { $RunspaceMax = $t } else { $RunspaceMax = $thread }
if ( $s ) { $FileSuffix = $s } else { $FileSuffix = $suffix }

function Write-Uniout {
    param ( 
        $WritePlace, 
        $WriteType,
        $WriteContent,
        $WriteAdditionalParam 
    )
    $WindowWidth = $host.UI.RawUI.WindowSize.Width
    $WindowHeight = $host.UI.RawUI.WindowSize.Height
    $WriteColor = $host.UI.RawUI.ForegroundColor
    switch ( $WriteType ) {
        "Output" { }
        "Verbose" { $WriteContent = "- " + $WriteContent }
        "Info" { $WriteContent = "> " + $WriteContent }
        "Warning" { $WriteContent = "Warning: " + $WriteContent; $WriteColor = "Yellow" }
        "WarningN" { $WriteColor = "Yellow" }
        "Error" { $WriteContent = "Error: " + $WriteContent; $WriteColor = "Red" }
        "ErrorN" { $WriteColor = "Red" }
        "Center" { $WriteContent = " " * (($WindowWidth - $WriteContent.Length) / 2 - 4) + $WriteContent }
        "Divide" { $WriteContent = "-" * ($WindowWidth - 8) }
        "Empty" { $WriteContent = "" }
        "Done" { $WriteColor = "Green" }
        "File" { Write-Host "    - File: $WriteContent.flac " -NoNewline; Write-Host "$WriteAdditionalParam" -ForegroundColor Green; return }
        "Help" {
            Write-Host "    Usage:"
            Write-Host "        flacre " -ForegroundColor White -NoNewline; Write-Host "[options] -path [<inputpath>] -output [<outputpath>/Replace]`n"
            Write-Host "    Options:"
            Write-Host "    -p, -path" -ForegroundColor Yellow -NoNewline; Write-Host " <path>" -ForegroundColor Green
            Write-Host "        Input option. The argument must be existd. Support file and folder. When you input a folder, we will search all FLAC files in the folder and sub-folders."
            Write-Host "    -o, -output" -ForegroundColor Yellow -NoNewline; Write-Host " <path> " -ForegroundColor Green -NoNewline; Write-Host "/" -NoNewline; Write-Host " Replace" -ForegroundColor Green
            Write-Host "        Output option. Support file and folder. When output path is empty or it was same as the input path, we will create a new folder `"Recompressed`" in the path root and saving files. If you want to replace the older file, please use " -NoNewline; Write-Host "-output Replace " -ForegroundColor Yellow -NoNewline; Write-Host "."
            Write-Host "    -t, -thread" -ForegroundColor Yellow -NoNewline; Write-Host " <int>" -ForegroundColor Green
            Write-Host "        Thread option. It decides the number of compress threads at the same time."
            Write-Host "    -s, -suffix" -ForegroundColor Yellow -NoNewline; Write-Host " <string>" -ForegroundColor Green
            Write-Host "        Suffix option. It effects recompressed files' name."
            Write-Host "    -l, -log" -ForegroundColor Yellow -NoNewline; Write-Host " <path>" -ForegroundColor Green
            Write-Host "        Log option. You can export log to the path. By default, log will be generate in TEMP folder."
            Write-Host "    -h, -help" -ForegroundColor Yellow
            Write-Host "        Display the help.`n"
            Write-Host "    Examples:"
            Write-Host "    PS>" -NoNewline; Write-Host " .\flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " C:\Users\Admin\Music" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " D:\Music"
            Write-Host "        Recompress all FLAC files from C:\Users\Admin\Music and save to D:\Music"
            Write-Host "    PS>" -NoNewline; Write-Host " ./flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " /home/Musics" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " /mnt/sdb/MyMusic" -NoNewline; Write-Host " -s" -ForegroundColor DarkGray -NoNewline; Write-Host " `"_cmp.flac`"" -NoNewline; Write-Host " -l" -ForegroundColor DarkGray -NoNewline; Write-Host " /home/flac.log" -NoNewline; Write-Host " -t" -ForegroundColor DarkGray -NoNewline; Write-Host " 8"
            Write-Host "        Recompress all FLAC files from /home/Musics and save to /mnt/sdb/MyMusic. All files will named to *_cmp.flac. Export log to /home/flac.log and set 8 threads."
            Write-Host "    PS>" -NoNewline; Write-Host " .\flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " `"E:\Music\Artist - Title.flac`"" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " E:\Music\New.flac"
            Write-Host "        Recompress E:\Music\Artist - Title.flac to E:\Music\New.flac."
            Write-Host "    PS>" -NoNewline; Write-Host " .\flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " D:\" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " Replace"
            Write-Host "        Recompress all FLAC files from D:\ and replace them."
            return
        }
    }
    if ($WritePlace -match "s") {
        $WriteContent = "    " + $WriteContent
        Write-Host -ForegroundColor $WriteColor $WriteContent
    }
    if ($WritePlace -match "l") {
        Out-File -FilePath $LogFilePath -Encoding utf8 -InputObject $WriteContent -Append
    }
}

# Notify for Windows
function Write-Notify {
    param (
        $NotifyType,
        $NotifyContent
    )
    if ( [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows) ) {  
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        $Notify = New-Object System.Windows.Forms.NotifyIcon
        $PSHostPath = Get-Process -id $pid | Select-Object -ExpandProperty Path
        $PSIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHostPath)
        $Notify.Icon = $PSIcon
        $Notify.BalloonTipTitle = "FLAC Recompress Tool"
        $Notify.BalloonTipIcon = "$NotifyType"
        $Notify.BalloonTipText = "$NotifyContent"
        $Notify.Visible = $true
        $Notify.ShowBalloonTip(5000)
    }
}

function Get-FriendlySpace {
    param ( $FileSpace )
    if ( $FileSpace -ge 1TB ) {
        $FileFriendlySpace = ('{0:n2}' -f ($FileSpace / 1TB)) + "TB"
    }
    elseif ( $FileSpace -ge 1GB ) {
        $FileFriendlySpace = ('{0:n2}' -f ($FileSpace / 1GB)) + "GB"
    }
    elseif ( $FileSpace -ge 1MB ) {
        $FileFriendlySpace = ('{0:n2}' -f ($FileSpace / 1MB)) + "MB"
    }
    elseif ( $FileSpace -ge 1KB ) {
        $FileFriendlySpace = ('{0:n2}' -f ($FileSpace / 1KB)) + "KB"
    }
    elseif ( $FileSpace -gt 0 ) {
        $FileFriendlySpace = ('{0:n2}' -f $FileSpace ) + "B"
    }
    return $FileFriendlySpace
}

# Detect System
$ScriptPath = $MyInvocation.MyCommand.Definition
$ScriptFolder = Split-Path -Parent $ScriptPath
$PSVercode = $PSVersionTable.PSVersion.major
if ( $PSVercode -lt 5 ) {
    Write-Uniout "s" "Error" "PowerShell Version is too low. Please update your PowerShell or install PowerShell Core."
    exit 1
}
Write-Uniout "s" "Info" "Detecting System for Performance"
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
if ( [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform( [System.Runtime.InteropServices.OSPlatform]::Windows )) {
    $FileSeparator = "\"
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
            Write-Uniout "s" "Warning" "Detected ARM64 Devices. FLAC will running in x86-compatible mode."
        }
        "Arm" {
            Write-Uniout "s" "Error" "Detected ARM Devices. Not support your device yet."
            exit 2
        }
    }
    $BinaryFLACVersion = (& $BinaryFLAC -v)
}
else {
    $env:TEMP = "/tmp"
    $FileSeparator = "/"
    $BinaryFLAC = "flac"
    $BinaryMetaFLAC = "metaflac" 
    $BinaryFLACVersion = (& $BinaryFLAC -v)
    if ( $BinaryFLACVersion ) {
        Write-Uniout "s" "Verbose" "Detected Linux or macOS. Use system FLAC binary."
    }
    else {
        Write-Uniout "ls" "Error" "Detected Linux or macOS and missing FLAC binary. You can install FLAC by package manager."
        exit 6
    }
}
if ( -not $LogFilePath ) {
    $LogFilePath = $env:TEMP + "$FileSeparator" + "FLACRecompress_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".log"
}
Write-Uniout "l" "Verbose" "$OSArchitecture"
Write-Uniout "l" "Verbose" "$OSDescription"
if ( -not $RunspaceMax ) {
    $CoreNumber = [System.Environment]::ProcessorCount
    if (( $OSArchitecture -eq "Arm" ) -or ( $OSArchitecture -eq "Arm64" )) {
        $RunspaceMax = '{0:n0}' -f ($CoreNumber / 2) 
    }
    elseif ( $CoreNumber -ge 4 ) {
        $RunspaceMax = $CoreNumber - 2 
    }
    elseif ($CoreNumber -ge 2) {
        $RunspaceMax = $CoreNumber - 1
    }
}
elseif ( $RunspaceMax -le 0 ) {
    Write-Uniout "ls" "Error" "Illegal Thread number"
    exit 5
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

# Help
if ( $h -or $help ) {
    Write-Uniout "s" "Help"
    exit 0
}

# No Paramater start
if ( -not $InputPath ) { 
    Write-Uniout "s" "Info" "No prarmater start. Using -h or -help for help."
    $InputPath = Read-Host "    Input file or folder path  (-p)"
    if ( -not $OutputPath ) {
        $OutputPath = Read-Host "    Output file or folder path (-o)"
    }
}

# Initialize Paramaters
if ( -not $InputPath ) { 
    Write-Uniout "ls" "Warning" "Unspecified Inputpath. Using $ScriptFolder as Inputpath."
    $InputPath = $ScriptFolder 
}
elseif ( -not (Test-Path $InputPath) ) {
    Write-Uniout "ls" "Error" "Inputpath invaild or don't have permissions."
    exit 3
}
if ( $InputPath.StartsWith(".\") -or $InputPath.StartsWith("./") ) {
    $InputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InputPath)
}
if ( $InputPath.EndsWith("\") -or $InputPath.EndsWith("/") ) { 
    $InputPath = $InputPath.Remove($InputPath.Length - 1) 
}

if (( $OutputPath -eq "Replace" ) -or ( $OutputPath -eq "replace" )) {
    $OutputPath = $env:TEMP + "$FileSeparator" + "Recompressed"
    $OutputReplace = $true
    if ( $FileSuffix ) {
        Write-Uniout "ls" "Warning" "File suffix can not using in Replace mode."
        $FileSuffix = ".flac"
    }
}
else {
    $OutputReplace = $false
    if ( -not $OutputPath ) {
        $OutputPath = "$InputPath" + "$FileSeparator" + "Recompressed"
        Write-Uniout "ls" "Warning" "Unspecified Ouputpath. File will output to $OutputPath"
    }
    if ( $OutputPath.StartsWith(".\") -or $OutputPath.StartsWith("./") ) {
        $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    }
    if ( $OutputPath.EndsWith("\") -or $OutputPath.EndsWith("/") ) { 
        $OutputPath = $OutputPath.Remove($OutputPath.Length - 1) 
    }
}

if ( -not $FileSuffix ) {
    $FileSuffix = ".flac"
}
if ( -not ( $FileSuffix -match "\.flac" )) {
    $FileSuffix += ".flac"
}

if ( Test-Path $InputPath -PathType Container ) {
    $FolderMode = $true
    if ( $OutputPath -match "\.flac" ) {
        Write-Uniout "ls" "Error" "Invaild Output folder"
        exit 4
    }
    Write-Uniout "ls" "Info" "Getting Filelist"
    $FileList = Get-ChildItem -Path "$InputPath" -Filter "*.flac" -Recurse | Where-Object { -not ($_.Directory -cmatch "^Recompressed$") } | Select-Object DirectoryName, Name, Length
    if ( -not $FileList ) {
        Write-Uniout "ls" "Warning" "No FLAC file found."
        exit 0
    }
}
else {
    $FolderMode = $false
    $FileList = Get-Item -Path "$InputPath" | Select-Object DirectoryName, Name, Length
}
$FileCount = $FileList.Count
$ErrorCount = 0
$DoneCount = 0
$FileSaveSpaceAll = 0
$TimeCount = Get-Date

Write-Uniout "ls" "Info" "Starting compress, please wait..."
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $RunspaceMax)
$RunspacePool.Open()
try {
    $aryPowerShell = New-Object System.Collections.ArrayList
    $aryIAsyncResult = New-Object System.Collections.ArrayList
    $FileList | ForEach-Object { 
        $FileSource = $_.DirectoryName + $FileSeparator + $_.Name
        $FileLengthOri = $_.Length 
        $FileName = $_.Name -replace "\.flac$"
        if ( $FolderMode ) {
            $FileRelativePath = ($_.DirectoryName).Replace($InputPath, "")
            $FileOutput = "$OutputPath" + "$FileRelativePath" + $FileSeparator + "$FileName" + "$FileSuffix"
            $FileOutputFolder = "$OutputPath" + "$FileRelativePath"
        }
        else {
            if ( $OutputPath -match "\.flac" ) {
                $FileOutput = "$OutputPath"
                $FileOutputFolder = "$OutputPath" -replace "\$FileSeparator[^/\\\?]+\.flac$"
            }
            else {
                $FileOutput = "$OutputPath" + $FileSeparator + "$FileName" + "$FileSuffix"
                $FileOutputFolder = "$OutputPath"
            }
        }
        if ( -not (Test-Path "$FileOutputFolder") ) {
            New-Item -Path "$FileOutputFolder" -ItemType Directory -Force | Out-Null
        }
       
        $PSObject = [PowerShell]::Create()
        $PSObject.RunspacePool = $RunspacePool
        $PSSubScript = {
            [CmdletBinding()]
            param(
                [parameter(mandatory, position = 0)][string]$BinaryFLAC,
                [parameter(mandatory, position = 1)][string]$FileOutput,
                [parameter(mandatory, position = 2)][string]$FileSource,
                [parameter(mandatory, position = 3)][string]$FileName,
                [parameter(mandatory, position = 4)][string]$FileLengthOri,
                [parameter(mandatory, position = 5)][System.Boolean]$OutputReplace
            )
            # For catch error
            $ErrorActionPreference = 'Stop'
            try {
                & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource" *>&1 | Out-Null
                $FileLength = Get-Item $FileOutput | Select-Object -ExpandProperty Length
                $FileSaveSpace = $FileLengthOri - $FileLength
                if ( $OutputReplace ) {
                    Move-Item -Path "$FileOutput" -Destination "$FileSource" -Force
                }
                $PSSubResult = "$FileName" + "|" + "$FileLength" + "|" + "$FileSaveSpace"
            }
            catch {
                $PSSubResult = $Error[0]
            }
            finally {
                [string]$PSSubResult
            }
        }
        $PSObject.AddScript($PSSubScript).AddArgument($BinaryFLAC).AddArgument($FileOutput).AddArgument($FileSource).AddArgument($FileName).AddArgument($FileLengthOri).AddArgument($OutputReplace) | Out-Null
        $IASyncResult = $PSObject.BeginInvoke()
        $aryPowerShell.Add($PSObject) | Out-Null
        $aryIAsyncResult.Add($IASyncResult) | Out-Null
    }
    Start-Sleep 1
    while ( $aryPowerShell.Count -gt 0 ) {
        # Single file needn't progress bar
        if ($FileCount -gt 1) {
            $ProgressPercent = '{0:n0}' -f (($DoneCount / $FileCount) * 100)
            $ProgressFileCount = "File " + '{0:n0}' -f ($DoneCount + 1) + "/" + '{0:n0}' -f $FileCount
            Write-Progress -Activity "Compressing" -Status "$ProgressPercent% Complete:" -PercentComplete $ProgressPercent -CurrentOperation $ProgressFileCount
        }
        for ( $i = 0; $i -lt $aryPowerShell.Count; $i++ ) {
            $PSObject = $aryPowerShell[$i]
            $IASyncResult = $aryIAsyncResult[$i]
            if ( $IASyncResult.IsCompleted -eq $true ) {
                $AsyncResult = [string]($PSObject.EndInvoke($IASyncResult)).TrimEnd("`n")
                if ( $AsyncResult -cmatch "WARNING:" ) {
                    if ( $AsyncResult -cmatch "is not an Ogg FLAC file; treating as a raw file" ) {
                        Write-Uniout "ls" "Error" $AsyncResult.Replace("WARNING: ", "").Replace("is not an Ogg FLAC file; treating as a raw file", "is not a vaild FLAC file")
                        $ErrorCount++
                    }
                    else {
                        Write-Uniout "ls" "Warning" $AsyncResult.Replace("WARNING: ", "")
                    }
                }
                elseif ( $AsyncResult -cmatch "Error:" ) {
                    Write-Uniout "ls" "Error" $AsyncResult.Replace("Error: ", "")
                    $ErrorCount++
                }
                else {
                    $FileName = ($AsyncResult -split "\|")[0]
                    [int]$FileSaveSpace = ($AsyncResult -split "\|")[2]
                    if ($FileSaveSpace -gt 0) {
                        $FileSaveSpaceOutput = "Saved " + (Get-FriendlySpace $FileSaveSpace)
                    }
                    else {
                        $FileSaveSpaceOutput = "No space saved."
                    }
                    $FileSaveSpaceAll += $FileSaveSpace
                    $DoneCount++
                    Write-Uniout "ls" "File" "$FileName" "$FileSaveSpaceOutput"
                }
                $PSObject.Dispose()
                $aryPowerShell.RemoveAt($i)
                $aryIAsyncResult.RemoveAt($i)
            }
        }
        Start-Sleep -Seconds 1
    }
}
catch {
    Write-Uniout "ls" "Error" $Error[0]
    exit 1
}
finally {
    $RunspacePool.Close()
}

Write-Uniout "ls" "Info" "Compress Completed"
if ($ErrorCount -eq 0) {
    $EndMessage = "No error occurred."
    Write-Uniout "ls" "Done" $EndMessage
    Write-Notify "Info" $EndMessage
}
else {
    if ( $ErrorCount -eq 1 ) {
        $EndMessage = "$ErrorCount file has an error."
    }
    else {
        $EndMessage = "$ErrorCount files have errors."
    }
    Write-Uniout "ls" "WarningN" $EndMessage
    Write-Notify "Warning" $EndMessage
}
if ($FileSaveSpaceAll -gt 0) {
    $FileSaveSpaceAllOutput = "Totally saved " + (Get-FriendlySpace $FileSaveSpaceAll)
}
else {
    $FileSaveSpaceAllOutput = "No space saved."
}
Write-Uniout "ls" "Done" "$FileSaveSpaceAllOutput"
$TimeUse = (New-TimeSpan -Start $TimeCount -End (Get-Date)).TotalSeconds