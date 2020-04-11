# FLAC Recompress Tool
## Please notice that the script still in developing. All features may changed before the first stable version released.
## What's this?
Thescript can recompress your FLAC audio file to save your disk space with the same quality. After recompression, the size of the file will reduced by up to 50%. (based on your FLAC compression level)

It's useful for some Hi-Res Store like Mora.
## How to use
`flacre.ps1 -l [Log file path] -p [Input file or folder path] -o [Output file or folder path] -t [Threads number]`

For example: `flacre.ps1 -p C:\Users\Admin\Music -o D:\Recompressed`

See notes below for more details.

## Supports Platform
- Windows 7,8,8.1,10 or higher
- macOS 10.12 or higher
- Linux list on https://github.com/PowerShell/PowerShell/releases/

## Requirements
- PowerShell 5.1 (based on .NET Framework)
- PowerShell 7 or higher (based on .NET Core) See more at https://aka.ms/powershell

## Restricted script execution
By default, Microsoft disabled PowerShell script execution on Windows. You can use the command below to enable the script execution.

`Set-ExecutionPolicy -ExecutionPolicy Unrestricted`

And you can use

`Set-ExecutionPolicy -ExecutionPolicy Restricted`

to disable it again.

Binary files from https://xiph.org/flac. 