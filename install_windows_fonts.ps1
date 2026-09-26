# Register Powerline fonts for the current Windows user (Windows Terminal on WSL).
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SourceDir
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$FontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$RegPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -Path $RegPath -Force | Out-Null
New-Item -ItemType Directory -Path $FontDir -Force | Out-Null

if (-not (Test-Path -LiteralPath $SourceDir)) {
    Write-Error "Font source not found: $SourceDir"
}

Get-ChildItem -LiteralPath $SourceDir -Filter '*.ttf' | ForEach-Object {
    $src = $_.FullName
    $dest = Join-Path $FontDir $_.Name
    Copy-Item -LiteralPath $src -Destination $dest -Force

    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    $pfc.AddFontFile($dest)
    $family = $pfc.Families[0].Name

    $regName = ($_.BaseName + ' (TrueType)')
    New-ItemProperty -Path $RegPath -Name $regName -Value $_.Name -PropertyType String -Force | Out-Null
    Write-Output "Registered: $regName -> $($_.Name) [$family]"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FontNative {
  [DllImport("gdi32.dll", EntryPoint="AddFontResourceW", CharSet=CharSet.Unicode)]
  public static extern int AddFontResource(string lpFileName);
}
"@ | Out-Null

Get-ChildItem -LiteralPath $FontDir -Filter 'Roboto*.ttf' | ForEach-Object {
    $rc = [FontNative]::AddFontResource($_.FullName)
    Write-Output "AddFontResource $($_.Name): $rc"
}

Write-Output 'Font registration complete. Fully quit and reopen Windows Terminal.'
Write-Output 'If apps still complain, sign out of Windows once, or double-click Roboto Mono for Powerline.ttf and choose Install.'
