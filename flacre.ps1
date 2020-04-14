# Main script
# The part of FLAC Recompress Tool
# Author: Antidotes
# Source: https://github.com/Antidoteseries/FLAC-Recompress-Tool
# Licenced by GPLv3
# Version: 0.9.5 Beta
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
    [int]$thread,
    [switch]$id3convert
)
if ( $l ) { $LogFilePath = $l } else { $LogFilePath = $log }
if ( $o ) { $OutputPath = $o } else { $OutputPath = $output }
if ( $p ) { $InputPath = $p } else { $InputPath = $path }
if ( $t ) { $RunspaceMax = $t } else { $RunspaceMax = $thread }
if ( $s ) { $FileSuffix = $s } else { $FileSuffix = $suffix }
if ( $id3convert ) {
    $ConvertID3Tag = $true
}
else {
    $ConvertID3Tag = $false
}

$WindowWidth = [System.Console]::BufferWidth 
$WindowHeight = [System.Console]::BufferHeight
function Write-Uniout {
    param ( 
        $WritePlace, 
        $WriteType,
        $WriteContent
    )
    $WriteColor = "White" # $host.UI.RawUI.ForegroundColor invaild in Linux
    switch ( $WriteType ) {
        "Output" { }
        "Verbose" { $WriteContent = "- " + $WriteContent }
        "Info" { $WriteContent = "> " + $WriteContent }
        "Warning" { $WriteContent = "Warning: " + $WriteContent; $WriteColor = "Yellow" }
        "WarningN" { $WriteColor = "Yellow" }
        "Error" { $WriteContent = "Error: " + $WriteContent; $WriteColor = "Red" }
        "ErrorN" { $WriteColor = "Red" }
        "Center" { [System.Console]::SetCursorPosition(( [System.Console]::CursorLeft + [int](( $WindowWidth - $WriteContent.Length ) / 2 - 4 )), [System.Console]::CursorTop ) }
        "Divide" { $WriteContent = "-" * ( $WindowWidth - 8 ) }
        "Done" { $WriteColor = "Green" }
        "Help" {
            Write-Host ""
            Write-Host "    Usage:"
            Write-Host "        flacre " -ForegroundColor White -NoNewline; Write-Host "[options] -path [<inputpath>] -output [<outputpath>/Replace]`n" -ForegroundColor Gray
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
            Write-Host "    -id3convert" -ForegroundColor Yellow -NoNewline; Write-Host " (Experiment Feature)" -ForegroundColor White
            Write-Host "        Enable convert id3 tag to standard FLAC tag. If not enable, FLAC with id3 tag will occurate an error."
            Write-Host "        ID3 tag is not supported by Xiph.org officially, converting may lost metadata like title, artist and so on."
            Write-Host "    -h, -help" -ForegroundColor Yellow
            Write-Host "        Display the help.`n"
            Write-Host "    Examples:"
            Write-Host "    PS>" -NoNewline; Write-Host " flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " C:\Users\Admin\Music" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " D:\Music"
            Write-Host "        Recompress all FLAC files from C:\Users\Admin\Music and save to D:\Music"
            Write-Host "    PS>" -NoNewline; Write-Host " flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " /home/Musics" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " /mnt/sdb/MyMusic" -NoNewline; Write-Host " -s" -ForegroundColor DarkGray -NoNewline; Write-Host " `"_cmp.flac`"" -NoNewline; Write-Host " -l" -ForegroundColor DarkGray -NoNewline; Write-Host " /home/flac.log" -NoNewline; Write-Host " -t" -ForegroundColor DarkGray -NoNewline; Write-Host " 8"
            Write-Host "        Recompress all FLAC files from /home/Musics and save to /mnt/sdb/MyMusic. All files will named to *_cmp.flac. Export log to /home/flac.log and set 8 threads."
            Write-Host "    PS>" -NoNewline; Write-Host " flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " `"E:\Music\Artist - Title.flac`"" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " E:\Music\New.flac"
            Write-Host "        Recompress E:\Music\Artist - Title.flac to E:\Music\New.flac."
            Write-Host "    PS>" -NoNewline; Write-Host " flacre" -ForegroundColor Yellow -NoNewline; Write-Host " -p" -ForegroundColor DarkGray -NoNewline; Write-Host " D:\" -NoNewline; Write-Host " -o" -ForegroundColor DarkGray -NoNewline; Write-Host " Replace"
            Write-Host "        Recompress all FLAC files from D:\ and replace them."
            return
        }
    }
    if ( $WritePlace -match "s" ) {
        Write-Host $WriteContent  -ForegroundColor $WriteColor 
        [System.Console]::SetCursorPosition(( [System.Console]::CursorLeft + 4 ), [System.Console]::CursorTop)
    }
    if (( $WritePlace -match "l" ) -and $LogEnabled ) {
        Out-File -FilePath $LogFilePath -Encoding utf8 -InputObject (( Get-Date -Format "[yyyy-MM-dd HH:mm:ss] ") + $WriteContent ) -Append
    }
}

$ProgressLine = $WindowHeight - 5
function Write-Progress2 {
    param (
        [int]$PercentCompleted,
        [string]$CurrentOperation
    )
    $ProgressLineStart = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition(4, $ProgressLine - 1)
    Write-Host ( [string]$PercentCompleted + "% Completed:" ) -ForegroundColor White; [System.Console]::SetCursorPosition(4, [System.Console]::CursorTop)
    $ProgressStringCount = [int](( $WindowWidth - 10 ) * ( $PercentCompleted / 100 ))
    $ProgressString = "[" + "o" * $ProgressStringCount + " " * ( $WindowWidth - 10 - $ProgressStringCount ) + "]"
    Write-Host $ProgressString ; [System.Console]::SetCursorPosition(4, [System.Console]::CursorTop)
    Write-Host $CurrentOperation; [System.Console]::SetCursorPosition(4, [System.Console]::CursorTop)
    [System.Console]::SetCursorPosition(4, $ProgressLineStart)
}

# Notify for Windows
function Write-Notify {
    param (
        $NotifyType,
        $NotifyContent
    )
    if ( $PSHostWindows ) {  
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        $Notify = New-Object System.Windows.Forms.NotifyIcon
        $PSHostPath = Get-Process -id $pid | Select-Object -ExpandProperty Path
        $PSIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHostPath)
        $Notify.Icon = $PSIcon
        $Notify.BalloonTipTitle = $ScriptTitle
        $Notify.BalloonTipIcon = $NotifyType
        $Notify.BalloonTipText = $NotifyContent
        $Notify.Visible = $true
        $Notify.ShowBalloonTip(5000)
    }
}

function Get-FriendlySize {
    param ( $FileSpace )
    if ( $FileSpace -ge 1TB ) {
        $FileFriendlySpace = ( '{0:n2}' -f ( $FileSpace / 1TB )) + "TB"
    }
    elseif ( $FileSpace -ge 1GB ) {
        $FileFriendlySpace = ( '{0:n2}' -f ( $FileSpace / 1GB )) + "GB"
    }
    elseif ( $FileSpace -ge 1MB ) {
        $FileFriendlySpace = ( '{0:n2}' -f ( $FileSpace / 1MB )) + "MB"
    }
    elseif ( $FileSpace -ge 1KB ) {
        $FileFriendlySpace = ( '{0:n2}' -f ( $FileSpace / 1KB )) + "KB"
    }
    elseif ( $FileSpace -gt 0 ) {
        $FileFriendlySpace = ( '{0:n2}' -f $FileSpace ) + "B"
    }
    return $FileFriendlySpace
}

# Getting script infomation
$ScriptPath = $MyInvocation.MyCommand.Definition # is Literal Path
$ScriptFolder = Split-Path -Parent $ScriptPath
$PSVercode = $PSVersionTable.PSVersion.major
if ( $PSVercode -lt 5 ) {
    Write-Uniout "s" "Error" "PowerShell Version is too low. Please update your PowerShell or install PowerShell Core."
    exit 1
}

# Title
Clear-Host
$LogEnabled = $true
$ScriptTitle = "FLAC Recompress Tool"
$ScriptInfo = Get-content -LiteralPath $ScriptPath -TotalCount 6 
$host.UI.RawUI.WindowTitle = $ScriptTitle
[System.Console]::SetCursorPosition(4, 1)
Write-Uniout "s" "Center" ( $ScriptTitle + $ScriptInfo[5].Replace("# Version:", "") )
Write-Uniout "s" "Center" $ScriptInfo[2].Replace("# ", "")
Write-Uniout "s" "Center" $ScriptInfo[4].Replace("# ", "")
Write-Uniout "s" "Center" $ScriptInfo[3].Replace("# Source: ", "")
Write-Uniout "s" "Divide"

# Help
if ( $h -or $help ) {
    Write-Uniout "s" "Help"
    exit 0
}

# Detect System
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
    $PSHostWindows = $true
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
    $BinaryFLACVersion = ( & $BinaryFLAC -v )
}
else {
    $PSHostWindows = $false
    $env:TEMP = "/tmp"
    $FileSeparator = "/"
    $BinaryFLAC = "flac"
    $BinaryMetaFLAC = "metaflac" 
    $BinaryFLACVersion = ( & $BinaryFLAC -v )
    if ( $BinaryFLACVersion ) {
        Write-Uniout "s" "Verbose" "Detected Linux or macOS. Use system FLAC binary."
    }
    else {
        Write-Uniout "s" "Error" "Detected Linux or macOS and missing FLAC binary. Please install FLAC in package manager first."
        exit 6
    }
}
if ( -not $LogFilePath ) {
    $LogFilePath = $env:TEMP + $FileSeparator + "FLACRecompress_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".log"
}

Write-Uniout "l" "Verbose" "Started"
Write-Uniout "l" "Verbose" "Architecture: $OSArchitecture"
Write-Uniout "l" "Verbose" "OS: $OSDescription"
Write-Uniout "l" "Verbose" "FLAC Version: $BinaryFLACVersion"
if ( -not $RunspaceMax ) {
    $CoreNumber = [System.Environment]::ProcessorCount
    if (( $OSArchitecture -eq "Arm" ) -or ( $OSArchitecture -eq "Arm64" )) {
        $RunspaceMax = '{0:n0}' -f ( $CoreNumber / 2 ) 
    }
    elseif ( $CoreNumber -ge 4 ) {
        $RunspaceMax = $CoreNumber - 2 
    }
    elseif ( $CoreNumber -ge 2 ) {
        $RunspaceMax = $CoreNumber - 1
    }
}
elseif ( $RunspaceMax -le 0 ) {
    Write-Uniout "ls" "Error" "Illegal Thread number"
    exit 5
}

# No Paramater start
if ( -not $InputPath ) { 
    Write-Uniout "s" "Info" "No prarmater start. Using -h or -help for help."
    $InputPath = Read-Host "Input file or folder path  (-p)"
    [System.Console]::SetCursorPosition(4, [System.Console]::CursorTop)
    if ( -not $OutputPath ) {
        $OutputPath = Read-Host "Output file or folder path (-o)"
        [System.Console]::SetCursorPosition(4, [System.Console]::CursorTop)
    }
}

# Initialize Paramaters
if ( -not $InputPath ) { 
    Write-Uniout "ls" "Warning" "Unspecified Inputpath. Using $ScriptFolder as Inputpath."
    $InputPath = $ScriptFolder 
}
elseif (( -not ( Test-Path -Path $InputPath )) -or ( $InputPath -match '''''''' ) -or ( $InputPath -match '``' )) {
    Write-Uniout "ls" "Error" "Inputpath invaild or don't have permissions."
    exit 3
}
if ( $InputPath.StartsWith(".\") -or $InputPath.StartsWith("./") ) {
    $InputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InputPath)
}
if ( $InputPath.EndsWith("\") -or $InputPath.EndsWith("/") ) { 
    $InputPath = $InputPath.Remove($InputPath.Length - 1) 
}
$InputPathLiteral = ( $InputPath -replace '`\[', '[' -replace '`\]', ']' -replace '''''', '''' )

if (( $OutputPath -eq "Replace" ) -or ( $OutputPath -eq "replace" )) {
    $OutputPath = $env:TEMP + $FileSeparator + "Recompressed"
    $OutputReplace = $true
    if ( $FileSuffix ) {
        Write-Uniout "ls" "Warning" "File suffix can not using in Replace mode."
        $FileSuffix = ".flac"
    }
}
else {
    $OutputReplace = $false
    if ( -not $OutputPath ) {
        if ( $InputPath -match "\.flac") {
            $OutputPath = ( $InputPathLiteral -replace "\$FileSeparator[^/\\\?]+\.flac$" ) + $FileSeparator + "Recompressed"
        }
        else {
            $OutputPath = $InputPathLiteral + $FileSeparator + "Recompressed"  
        }
        Write-Uniout "ls" "Warning" "Unspecified Ouputpath. File will output to $OutputPath"
    }
    if ( $OutputPath.StartsWith(".\") -or $OutputPath.StartsWith("./") ) {
        $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    }
    if ( $OutputPath.EndsWith("\") -or $OutputPath.EndsWith("/") ) { 
        $OutputPath = $OutputPath.Remove( $OutputPath.Length - 1 ) 
    }
}
$OutputPathLiteral = ( $OutputPath -replace '`\[', '[' -replace '`\]', ']' -replace '''''', '''' )

if ( -not $FileSuffix ) {
    $FileSuffix = ".flac"
}
if ( -not ( $FileSuffix -match "\.flac" )) {
    $FileSuffix += ".flac"
}

if ( $ConvertID3Tag ) {
    Write-Uniout "ls" "Info" "ID3 Tag Convert is enabled. ID3 tag is not supported by Xiph.org officially, converting may lost metadata."
}

if ( Test-Path -LiteralPath $InputPathLiteral -PathType Container ) {
    $FolderMode = $true
    if ( "$OutputPath" -match "\.flac$" ) {
        Write-Uniout "ls" "Error" "Invaild Output path. You must set a folder if the input path is a folder。"
        exit 4
    }
    Write-Uniout "ls" "Info" "Getting Filelist"
    $FileList = Get-ChildItem -LiteralPath $InputPathLiteral -Filter "*.flac" -Recurse | Where-Object { -not ( $_.Directory -cmatch "Recompressed" ) }
    if ( -not $FileList ) {
        Write-Uniout "ls" "Warning" "No FLAC file found."
        exit 0
    }
    $FileCount = $FileList.Count
    Write-Uniout "s" "Verbose" "Find $FileCount files."
}
else {
    $FolderMode = $false
    $FileList = Get-Item -LiteralPath $InputPathLiteral
    $FileCount = $FileList.Count
}
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
  
    Write-Uniout "l" "Info" "File list:-----------------------------------------"
    foreach ( $FileEach in $FileList ) {
        $FileSource = $FileEach.DirectoryName + $FileSeparator + $FileEach.Name
        $FileLengthOri = $FileEach.Length
        $FileName = $FileEach.Name -replace "\.flac$"
        if ( $FolderMode ) {
            $FileRelativePath = $FileEach.DirectoryName -replace [Regex]::Escape($InputPathLiteral), "" 
            $FileOutput = $OutputPathLiteral + $FileRelativePath + $FileSeparator + $FileName + $FileSuffix
            $FileOutputFolder = $OutputPathLiteral + $FileRelativePath
        }
        else {
            if ( $OutputPath -match "\.flac" ) {
                $FileOutput = $OutputPath
                $FileOutputFolder = $OutputPathLiteral -replace "\$FileSeparator[^/\\\?]+\.flac$"
            }
            else {
                $FileOutput = $OutputPathLiteral + $FileSeparator + $FileName + $FileSuffix
                $FileOutputFolder = $OutputPathLiteral
            }
        }
       
        if ( -not ( Test-Path -LiteralPath $FileOutputFolder )) {
            New-Item -Path $FileOutputFolder -ItemType Directory -Force | Out-Null
        }
        Write-Uniout "l" "Verbose" "File Source:$FileSource After:$FileOutput"
        $PSObject = [PowerShell]::Create()
        $PSObject.RunspacePool = $RunspacePool
        $PSSubScript = {
            [CmdletBinding()]
            param(
                [parameter(mandatory, position = 0)][string]$BinaryFLAC,
                [parameter(mandatory, position = 1)][string]$BinaryMetaFLAC,
                [parameter(mandatory, position = 2)][string]$FileOutput,
                [parameter(mandatory, position = 3)][string]$FileSource,
                [parameter(mandatory, position = 4)][string]$FileName,
                [parameter(mandatory, position = 5)][string]$FileLengthOri,
                [parameter(mandatory, position = 6)][switch]$OutputReplace,
                [parameter(mandatory, position = 7)][switch]$ConvertID3Tag
            )
            # For catch error
            $ErrorActionPreference = 'Stop'
            try {
                & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileSource" *>&1 | Out-Null
                $FileLength = Get-Item -LiteralPath $FileOutput | Select-Object -ExpandProperty Length
                if ( $OutputReplace ) {
                    Move-Item -LiteralPath $FileOutput -Destination $FileSource -Force
                }
                $PSSubResult = "$FileName|$FileLength|$FileLengthori"
            }
            catch {
                $ErrorMessage = ( $Error[0].Exception.Message -replace "^.*:\s" )
                if (( $ConvertID3Tag ) -and ( $ErrorMessage -match "has an ID3" )) {
                    $ErrorActionPreference = 'SilentlyContinue'
                    & $BinaryMetaFLAC --export-tags-to="$FileOutput.tag" "$FileSource"
                    & $BinaryMetaFLAC --export-picture-to="$FileOutput.tag_picture" "$FileSource"
                    & $BinaryFLAC -d -o "$FileOutput.wav" "$FileSource"
                    & $BinaryFLAC -fsw8 -V -o "$FileOutput" "$FileOutput.wav"
                    Remove-Item -LiteralPath "$FileOutput.wav" -Force
                    & $BinaryMetaFLAC --import-tags-from="$FileOutput.tag" "$FileOutput"
                    Remove-Item -LiteralPath "$FileOutput.tag" -Force
                    if ( Test-Path -LiteralPath "$FileOutput.tag_picture" ) {
                        & $BinaryMetaFLAC --import-picture-from="$FileOutput.tag_picture" "$FileOutput"
                        Remove-Item -LiteralPath "$FileOutput.tag_picture" -Force
                    }
                    $FileLength = Get-Item -LiteralPath $FileOutput | Select-Object -ExpandProperty Length
                    if ( $OutputReplace ) {
                        Move-Item -LiteralPath $FileOutput -Destination $FileSource -Force
                    }
                    $PSSubResult = "$FileName|$FileLength|$FileLengthori"
                }
                else {
                    if ( Test-Path -LiteralPath $FileOutput ) {
                        Remove-Item -LiteralPath $FileOutput -Force
                    }
                    if ( $ErrorMessage -match "has an ID3" ) {
                        $ErrorMessage = "has ID3 tag that not support non-standard metadata"
                    }
                    elseif (( $ErrorMessage -cmatch "is not an Ogg FLAC file; treating as a raw file" ) -or ( $ErrorMessage -cmatch "for encoding a raw file you must specify a value" )) {
                        $ErrorMessage = "not a vaild FLAC file"
                    }
                    $PSSubResult = "- File: $FileName.flac Error: " + $ErrorMessage
                }
            }
            finally {
                $PSSubResult
            }
        }
        $PSObject.AddScript($PSSubScript).AddArgument($BinaryFLAC).AddArgument($BinaryMetaFLAC).AddArgument($FileOutput).AddArgument($FileSource).AddArgument($FileName).AddArgument($FileLengthOri).AddArgument($OutputReplace).AddArgument($ConvertID3Tag) | Out-Null
        $IASyncResult = $PSObject.BeginInvoke()
        $aryPowerShell.Add($PSObject) | Out-Null
        $aryIAsyncResult.Add($IASyncResult) | Out-Null
    }
  
    Write-Uniout "l" "Info" "Action Result:-------------------------------------"
    while ( $aryPowerShell.Count -gt 0 ) {
        $ProgressPercent = '{0:n0}' -f ((( $DoneCount + $ErrorCount ) / $FileCount ) * 100)
        $ProgressFileCount = "File " + '{0:n0}' -f ( $DoneCount + $ErrorCount + 1 ) + "/" + '{0:n0}' -f $FileCount
        Write-Progress2 -PercentComplete $ProgressPercent -CurrentOperation $ProgressFileCount
        $host.UI.RawUI.WindowTitle = "$ScriptTitle - $ProgressPercent%"
        for ( $i = 0; $i -lt $aryPowerShell.Count; $i++ ) {
            $PSObject = $aryPowerShell[$i]
            $IASyncResult = $aryIAsyncResult[$i]
            if ( $IASyncResult.IsCompleted -eq $true ) {
                $AsyncResult = [string]( $PSObject.EndInvoke($IASyncResult) ).TrimEnd("`n")
                # Clear output area
                if ( [System.Console]::CursorTop -ge ( $ProgressLine - 2 )) {
                    [System.Console]::SetCursorPosition(0, 6)
                    for ($i1 = 6; $i1 -lt ( $ProgressLine - 1 ); ++$i1 ) {
                        Write-Host ( " " * $WindowWidth )
                    }
                    [System.Console]::SetCursorPosition(4, 6)
                }
                if ( $AsyncResult -cmatch "Error:" ) {
                    Write-Uniout "ls" "ErrorN" $AsyncResult
                    $ErrorCount++
                }
                else {
                    $FileName = ( $AsyncResult -split "\|" )[0]
                    [int]$FileLength = ( $AsyncResult -split "\|" )[1]
                    [int]$FileLengthOri = ( $AsyncResult -split "\|" )[2]
                    $FileSaveSpace = $FileLengthOri - $FileLength
                    if ( $FileSaveSpace -gt 0 ) {
                        $FileSaveSpaceOutput = "Saved " + ( Get-FriendlySize $FileSaveSpace )
                    }
                    else {
                        $FileSaveSpaceOutput = "Already been compressed"
                    }
                    $FileSaveSpaceAll += $FileSaveSpace
                    $DoneCount++
                    # No need to pass too many parameters to Write-Uniout, output here directly
                    Write-Host ( "- File: $FileName.flac " ) -NoNewline; Write-Host (( Get-FriendlySize $FileLengthOri ) + "->" ) -NoNewline; Write-Host (( Get-FriendlySize $FileLength ) + " " ) -ForegroundColor White -NoNewline; Write-Host "$FileSaveSpaceOutput" -ForegroundColor Green
                    # For log
                    Write-Uniout "l" "Verbose" ( "File: $FileName.flac Original Size: " + ( Get-FriendlySize $FileLengthOri ) + " Recompressed Size: " + ( Get-FriendlySize $FileLength ))
                    [System.Console]::SetCursorPosition(4, [System.Console]::CursorTop)
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
    Write-Uniout "l" "Verbose" $Error[0].InvocationInfo.PositionMessage
    $ErrorReasonGet = $true
    exit 1
}
finally {
    if (( $DoneCount + $ErrorCount ) -ne $FileCount ) {
        if ( -not $ErrorReasonGet ) {
            Write-Uniout "ls" "Error" "Exit abnormally."
        }
        $host.UI.RawUI.WindowTitle = "$ScriptTitle - Stopped"
        [System.Console]::SetCursorPosition(0, $ProgressLine - 1)
        Write-Host ( " " * ( $WindowWidth - 6 ))
        [System.Console]::SetCursorPosition(4, $ProgressLine - 1)
        Write-Host "Stopped" -ForegroundColor Red
        [System.Console]::SetCursorPosition(0, $ProgressLine + 3)
    }
    $RunspacePool.Close()
}
Write-Uniout "ls" "Info" "Compress Completed"
$host.UI.RawUI.WindowTitle = "$ScriptTitle - 100%"
Write-Progress2 -PercentComplete 100
[System.Console]::SetCursorPosition(4, $ProgressLine + 1)
Write-Host ( " " * ( $WindowWidth - 6 ))
[System.Console]::SetCursorPosition(4, $ProgressLine + 1)

if ( $ErrorCount -eq 0 ) {
    $ErrorMessage = "$ErrorCount error occurred."
    Write-Uniout "ls" "Done" $ErrorMessage
   
}
elseif ( $ErrorCount -eq 1 ) {
    $ErrorMessage = "$ErrorCount error occurred."
    Write-Uniout "ls" "WarningN" $ErrorMessage
}
else {
    $ErrorMessage = "$ErrorCount errors occurred."
    Write-Uniout "ls" "WarningN" $ErrorMessage
}
if ( $FileSaveSpaceAll -gt 0 ) {
    $FileSaveSpaceAllOutput = "Compressed $DoneCount files. Totally saved " + ( Get-FriendlySize $FileSaveSpaceAll )
}
else {
    $FileSaveSpaceAllOutput = "Compressed $DoneCount files. All of files have been compressed."
}
Write-Uniout "ls" "Done" $FileSaveSpaceAllOutput
if ( $ErrorCount -eq 0 ) {
    Write-Notify "Info" $FileSaveSpaceAllOutput
}
else {
    Write-Notify "Warning" $ErrorMessage
}
$TimeUse = '{0:n2}' -f ( New-TimeSpan -Start $TimeCount -End (Get-Date) ).TotalSeconds
Write-Uniout "l" "Info" "Time use: $TimeUse s"