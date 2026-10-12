# Voice Flow installer for Windows - installs the dictation app, then brands it
# with the person's own name, logo and words.
# Built on Handy (MIT licence, github.com/cjpais/Handy) - see LICENSE-Handy.txt
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic
$Payload = $PSScriptRoot
Get-ChildItem -Path (Split-Path $Payload) -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

function Say($msg, $icon = 'Information') {
  [void][System.Windows.Forms.MessageBox]::Show($msg, 'Voice Flow setup', 'OK', $icon)
}
function Fail($msg) { Say $msg 'Warning'; exit 1 }

# --- 1. Questions (or a preset, for pre-branded kits) ---
$PresetFile = Join-Path $Payload 'preset.json'
if (Test-Path $PresetFile) {
  $Preset = Get-Content $PresetFile -Raw | ConvertFrom-Json
  $Name = $Preset.name
  $Logo = if ($Preset.logo) { Join-Path $Payload $Preset.logo } else { '' }
  $Words = @($Preset.words)
} else {
  $Name = [Microsoft.VisualBasic.Interaction]::InputBox(
    "What should your voice app be called?`n`nTip: your business name + Flow, e.g. Smith Plumbing Flow",
    'Voice Flow setup', 'My Flow')
  $Logo = ''
  $ans = [System.Windows.Forms.MessageBox]::Show(
    "Add your logo? It becomes the app icon and the little icon by your clock.`n`nA square logo works best (PNG or JPG).",
    'Voice Flow setup', 'YesNo', 'Question')
  if ($ans -eq 'Yes') {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Pick your logo'
    $dlg.Filter = 'Images|*.png;*.jpg;*.jpeg;*.bmp;*.gif'
    if ($dlg.ShowDialog() -eq 'OK') { $Logo = $dlg.FileName }
  }
  $w = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Any words it should always spell right? Your business name, team names, products, suburbs.`n`nSeparate with commas, or leave blank.",
    'Voice Flow setup', '')
  $Words = @($w -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
$Name = ($Name -replace '[\\/:*?"<>|]', '').Trim()
if (-not $Name) { $Name = 'My Flow' }

# --- 2. Install the engine silently (official signed installer, per-user, no admin) ---
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { 'arm64' } else { 'x64' }
$Setup = Join-Path $Payload "Handy_$arch-setup.exe"
Get-Process -Name handy -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "Installing $Name... (this can take a minute)"
$p = Start-Process -FilePath $Setup -ArgumentList '/S', '/NS' -Wait -PassThru
$Dir = Join-Path $env:LOCALAPPDATA 'Handy'
$Exe = Join-Path $Dir 'handy.exe'
if (-not (Test-Path $Exe)) { Fail "Install did not finish (code $($p.ExitCode)). Ask whoever sent you this." }
Get-Process -Name handy -ErrorAction SilentlyContinue | Stop-Process -Force

# --- 3. Brand it ---
function Square-Image($path, $size) {
  $src = [System.Drawing.Image]::FromFile($path)
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'HighQuality'; $g.PixelOffsetMode = 'HighQuality'
  $g.Clear([System.Drawing.Color]::Transparent)
  $scale = [Math]::Min($size / $src.Width, $size / $src.Height)
  $w = [int]($src.Width * $scale); $h = [int]($src.Height * $scale)
  $g.DrawImage($src, [int](($size - $w) / 2), [int](($size - $h) / 2), $w, $h)
  $g.Dispose(); $src.Dispose()
  return $bmp
}
function Png-Bytes($bmp) {
  $ms = New-Object System.IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  return ,$ms.ToArray()
}

$Ico = Join-Path $Dir 'brand.ico'
if ($Logo -and (Test-Path $Logo)) {
  try {
    # Menu-bar (tray) icons
    $tray = Square-Image $Logo 64
    $trayBytes = Png-Bytes $tray; $tray.Dispose()
    foreach ($f in 'handy','handy_warning','tray_idle','tray_idle_dark','tray_idle_warning','tray_idle_warning_dark',
                   'tray_recording','tray_recording_dark','tray_transcribing','tray_transcribing_dark') {
      [System.IO.File]::WriteAllBytes((Join-Path $Dir "resources\$f.png"), $trayBytes)
    }
    # App icon (.ico holding PNG images)
    $sizes = 256, 48, 32, 16
    $imgs = foreach ($s in $sizes) { $b = Square-Image $Logo $s; ,(Png-Bytes $b); $b.Dispose() }
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter $ms
    $bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
      $s = $sizes[$i]; $d = $imgs[$i]
      $bw.Write([byte]($s % 256)); $bw.Write([byte]($s % 256)); $bw.Write([byte]0); $bw.Write([byte]0)
      $bw.Write([UInt16]1); $bw.Write([UInt16]32); $bw.Write([UInt32]$d.Length); $bw.Write([UInt32]$offset)
      $offset += $d.Length
    }
    foreach ($d in $imgs) { $bw.Write($d) }
    $bw.Flush(); [System.IO.File]::WriteAllBytes($Ico, $ms.ToArray()); $bw.Dispose()
  } catch { Say "That logo could not be used, so the standard icon was kept.`n`n$($_.Exception.Message)" 'Warning'; $Ico = $null }
} else { $Ico = $null }
$IconLoc = if ($Ico) { "$Ico,0" } else { "$Exe,0" }

# Shortcuts with the person's name + icon (old ones from a previous name are removed)
$Shell = New-Object -ComObject WScript.Shell
$StartDir = [Environment]::GetFolderPath('Programs')
$Desktop = [Environment]::GetFolderPath('Desktop')
$Marker = Join-Path $Dir 'brand-name.txt'
if (Test-Path $Marker) {
  $old = Get-Content $Marker -Raw
  foreach ($d in $StartDir, $Desktop) { Remove-Item (Join-Path $d "$($old.Trim()).lnk") -ErrorAction SilentlyContinue }
}
foreach ($d in $StartDir, $Desktop) {
  Remove-Item (Join-Path $d 'Handy.lnk') -ErrorAction SilentlyContinue
  $lnk = $Shell.CreateShortcut((Join-Path $d "$Name.lnk"))
  $lnk.TargetPath = $Exe; $lnk.WorkingDirectory = $Dir; $lnk.IconLocation = $IconLoc; $lnk.Description = "$Name - hold the key and talk"
  $lnk.Save()
}
Set-Content -Path $Marker -Value $Name -NoNewline

# Name + icon in Settings > Installed apps
$Uninst = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Handy'
if (Test-Path $Uninst) {
  Set-ItemProperty $Uninst -Name DisplayName -Value $Name
  if ($Ico) { Set-ItemProperty $Uninst -Name DisplayIcon -Value $Ico }
}

# --- 4. Starter settings (first install only; never overwrites someone's own settings) ---
$Sup = Join-Path $env:APPDATA 'com.pais.handy'
$SettingsFile = Join-Path $Sup 'settings_store.json'
if (-not (Test-Path $SettingsFile)) {
  New-Item -ItemType Directory -Force -Path $Sup | Out-Null
  $json = Get-Content (Join-Path $Payload 'settings_store.json') -Raw | ConvertFrom-Json
  $json.settings.custom_words = @($Words)
  [System.IO.File]::WriteAllText($SettingsFile, ($json | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding $false))
}

# --- 5. Start it ---
Start-Process -FilePath $Exe -WorkingDirectory $Dir
Say "$Name is installed.`n`n1.  In the $Name window, follow the steps. If it asks which voice model to use, choose Parakeet V3. It downloads once (about a minute).`n`n2.  Click into any text box, hold  Ctrl + Space , talk, and let go. If Windows asks to use the microphone, click Yes.`n`nYou'll find $Name in your Start menu and on your desktop."
