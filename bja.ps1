<#
.SYNOPSIS
    BJA Toolbox v5.0 - Ultimate Performance Edition

.DESCRIPTION
    أداة تويك شاملة بأعلى أداء:
    - 90+ Tweak (Privacy, Performance, Security, UI, Network, Gaming, Maintenance)
    - أيقونات حقيقية للتطبيقات
    - Presets: Standard / Minimal / Advanced / Gaming / Extreme
    - Toggle switches في Customize Preferences
    - Restore Point تلقائي
    - Log كامل

.USAGE
    irm https://raw.githubusercontent.com/gxaff/BJA/main/bja.ps1 | iex
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$script:Version = "5.0.0"
$script:LogPath = "$env:USERPROFILE\Desktop\BJA_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$script:SelectedApps   = New-Object System.Collections.ArrayList
$script:SelectedTweaks = New-Object System.Collections.ArrayList
$script:IconCache = @{}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $script:LogPath -Value $line
    Write-Host $line -ForegroundColor $(switch ($Level) {
        'OK' {'Green'} 'WARN' {'Yellow'} 'ERROR' {'Red'} default {'Gray'}
    })
}

function New-RestorePoint {
    Write-Log "Creating restore point..."
    try {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
            -Name SystemRestorePointCreationFrequency -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "BJA $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
            -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log "Restore point created" 'OK'
    } catch { Write-Log "Restore point skipped" 'WARN' }
}

# ═══════════════════════════════════════════════════════════
#  TWEAKS ENGINE — 90+ Tweaks
# ═══════════════════════════════════════════════════════════

function Invoke-Tweak {
    param([string]$Name)
    Write-Log "Applying: $Name"
    $success = $false
    try {
        switch ($Name) {

            # ══════════ PRIVACY ══════════
            "Disable Telemetry" {
                $p1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
                if (-not (Test-Path $p1)) { New-Item $p1 -Force | Out-Null }
                Set-ItemProperty $p1 -Name AllowTelemetry -Value 0 -Type DWord -Force
                $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                if (-not (Test-Path $p2)) { New-Item $p2 -Force | Out-Null }
                Set-ItemProperty $p2 -Name AllowTelemetry -Value 0 -Type DWord -Force
                Set-ItemProperty $p2 -Name MaxTelemetryAllowed -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Activity History" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name EnableActivityFeed -Value 0 -Type DWord -Force
                Set-ItemProperty $p -Name PublishUserActivities -Value 0 -Type DWord -Force
                Set-ItemProperty $p -Name UploadUserActivities -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Location Tracking" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name Value -Value "Deny" -Type String -Force
                Set-ItemProperty "HKLM:\SYSTEM\Maps" -Name AutoUpdateEnabled -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Advertising ID" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name Enabled -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Consumer Features" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name DisableWindowsConsumerFeatures -Value 1 -Type DWord -Force
                Set-ItemProperty $p -Name DisableSoftLanding -Value 1 -Type DWord -Force
                Set-ItemProperty $p -Name DisableThirdPartySuggestions -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Cortana" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name AllowCortana -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Bing Search" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name BingSearchEnabled -Value 0 -Type DWord -Force
                Set-ItemProperty $p -Name CortanaConsent -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Copilot" {
                $p = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name TurnOffWindowsCopilot -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Recall" {
                try {
                    dism /Online /Disable-Feature /FeatureName:Recall /NoRestart 2>&1 | Out-Null
                    $success = $true
                } catch {}
            }
            "Disable Tailored Experiences" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" `
                    -Name TailoredExperiencesWithDiagnosticDataEnabled -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Speech Privacy" {
                $p = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name HasAccepted -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Input Personalization" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Input\TIPC" -Name Enabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty "HKCU:\Software\Microsoft\InputPersonalization" -Name RestrictImplicitInkCollection -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty "HKCU:\Software\Microsoft\InputPersonalization" -Name RestrictImplicitTextCollection -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Microsoft Store Recommendations" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SilentInstalledAppsEnabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SystemPaneSuggestionsEnabled -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Prevent Device Companion Apps" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name DisableThirdPartySuggestions -Value 1 -Type DWord -Force
                $success = $true
            }

            # ══════════ PERFORMANCE ══════════
            "Disable Delivery Optimization" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name DODownloadMode -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable SysMain" {
                try { Set-Service -Name SysMain -StartupType Disabled -ErrorAction Stop; $success = $true } catch {}
            }
            "Disable Hibernation" {
                try { powercfg /hibernate off; $success = $true } catch {}
            }
            "Enable GPU Scheduling" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
                    -Name HwSchMode -Value 2 -Type DWord -Force
                $success = $true
            }
            "Enable Ultimate Performance" {
                try {
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
                    powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
                    $success = $true
                } catch {}
            }
            "Disable Startup Delay" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name StartupDelayInMSec -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable WPBT" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                    -Name DisableWpbtExecution -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Power Throttling" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name PowerThrottlingOff -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Superfetch" {
                try { Set-Service -Name SysMain -StartupType Disabled -ErrorAction Stop; $success = $true } catch {}
            }
            "Optimize SSD" {
                try { 
                    $sysDrive = $env:SystemDrive
                    Optimize-Volume -DriveLetter $sysDrive.Replace(":","") -ReTrim -ErrorAction Stop
                    $success = $true
                } catch {}
            }
            "Disable Background Apps" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" `
                    -Name GlobalUserDisabled -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Startup Apps Delay" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name StartupDelayInMSec -Value 0 -Type DWord -Force
                $success = $true
            }
            "Adjust Visual Effects for Performance" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Search Indexing" {
                try { Set-Service -Name WSearch -StartupType Disabled -ErrorAction Stop; $success = $true } catch {}
            }
            "Clear Prefetch" {
                try { Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue; $success = $true } catch {}
            }
            "Optimize Memory Management" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                Set-ItemProperty $p -Name LargeSystemCache -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty $p -Name DisablePagingExecutive -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }

            # ══════════ NETWORK ══════════
            "Disable IPv6" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" `
                    -Name DisabledComponents -Value 0xFF -Type DWord -Force
                $success = $true
            }
            "Set IPv6 to Prefer IPv4" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" `
                    -Name DisabledComponents -Value 0x20 -Type DWord -Force
                $success = $true
            }
            "Optimize TCP Settings" {
                try {
                    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
                    netsh int tcp set heuristics disabled 2>&1 | Out-Null
                    netsh int tcp set global rss=enabled 2>&1 | Out-Null
                    $success = $true
                } catch {}
            }
            "Disable NetBIOS over TCP/IP" {
                $ifaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" -ErrorAction SilentlyContinue
                if ($ifaces) {
                    foreach ($iface in $ifaces) {
                        Set-ItemProperty $iface.PSPath -Name NetbiosOptions -Value 2 -ErrorAction SilentlyContinue
                    }
                }
                $success = $true
            }
            "Disable Windows Reserved Bandwidth" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name NonBestEffortLimit -Value 0 -Type DWord -Force
                $success = $true
            }

            # ══════════ SECURITY ══════════
            "Disable Remote Registry" {
                try { Set-Service -Name RemoteRegistry -StartupType Disabled -ErrorAction Stop; $success = $true } catch {}
            }
            "Disable Xbox Services" {
                $any = $false
                foreach ($s in 'XblAuthManager','XblGameSave','XboxNetApiSvc') {
                    try { Set-Service -Name $s -StartupType Disabled -ErrorAction Stop; $any = $true } catch {}
                }
                $success = $any
            }
            "Disable SMBv1" {
                try {
                    dism /Online /Disable-Feature /FeatureName:SMB1Protocol /NoRestart 2>&1 | Out-Null
                    $success = $true
                } catch {}
            }
            "Disable AutoRun" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name NoDriveTypeAutoRun -Value 255 -Type DWord -Force
                Set-ItemProperty $p -Name NoAutorun -Value 1 -Type DWord -Force
                $success = $true
            }
            "Enable Defender PUA Protection" {
                try { Set-MpPreference -PUAProtection 1 -ErrorAction Stop; $success = $true } catch {}
            }

            # ══════════ UI / EXPLORER ══════════
            "Show File Extensions" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name HideFileExt -Value 0 -Type DWord -Force
                $success = $true
            }
            "Show Hidden Files" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name Hidden -Value 1 -Type DWord -Force
                $success = $true
            }
            "Dark Mode" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                    -Name AppsUseLightTheme -Value 0 -Type DWord -Force
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                    -Name SystemUsesLightTheme -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Widgets" {
                try {
                    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                        /v TaskbarDa /t REG_DWORD /d 0 /f 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { $success = $true }
                } catch {}
            }
            "Disable Start Recommendations" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name Start_IrisRecommendations -Value 0 -Type DWord -Force
                $success = $true
            }
            "Enable End Task on Taskbar" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name TaskbarEndTask -Value 1 -Type DWord -Force
                $success = $true
            }
            "Enable Long Paths" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
                    -Name LongPathsEnabled -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Explorer Auto Discovery" {
                $bagsPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags"
                $bagMRU   = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU"
                Remove-Item $bagsPath -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item $bagMRU -Recurse -Force -ErrorAction SilentlyContinue
                $all = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
                if (-not (Test-Path $all)) { New-Item $all -Force | Out-Null }
                New-ItemProperty $all -Name FolderType -Value "NotSpecified" -PropertyType String -Force | Out-Null
                $success = $true
            }
            "Enable Start Menu Previous Layout" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name Start_AccountNotifications -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Taskbar Left Align" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name TaskbarAl -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Lock Screen" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name NoLockScreen -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Transparency Effects" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                    -Name EnableTransparency -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Animations" {
                Set-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" `
                    -Name MinAnimate -Value 0 -Type String -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Sticky Keys Prompt" {
                Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" `
                    -Name Flags -Value "506" -Type String -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Num Lock on Startup" {
                Set-ItemProperty "HKCU:\Control Panel\Keyboard" `
                    -Name InitialKeyboardIndicators -Value "2" -Type String -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Taskbar Search" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
                    -Name SearchboxTaskbarMode -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Hide Task View Button" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name ShowTaskViewButton -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable File Explorer Home" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name ShowHomeTab -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Enable Game Mode" {
                Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" `
                    -Name AutoGameModeEnabled -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Game Bar" {
                Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" `
                    -Name ShowStartupPanel -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }

            # ══════════ MAINTENANCE ══════════
            "Disk Cleanup" {
                try { Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow; $success = $true } catch {}
            }
            "Delete Temp Files" {
                foreach ($p in "$env:TEMP\*","$env:WINDIR\Temp\*","$env:LOCALAPPDATA\Temp\*") {
                    try { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                }
                $success = $true
            }
            "Empty Recycle Bin" {
                try { Clear-RecycleBin -Force -ErrorAction Stop; $success = $true } catch {}
            }
            "Create Restore Point" { New-RestorePoint; $success = $true }
            "Clear DNS Cache" {
                try { ipconfig /flushdns 2>&1 | Out-Null; $success = $true } catch {}
            }
            "Clear Windows Update Cache" {
                try {
                    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
                    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
                    $success = $true
                } catch {}
            }
            "Reset Windows Store Cache" {
                try { Start-Process "wsreset.exe" -Wait -NoNewWindow; $success = $true } catch {}
            }
            "Run System File Check" {
                try { Start-Process "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow; $success = $true } catch {}
            }
            "Run DISM Restore" {
                try { Start-Process "dism" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow; $success = $true } catch {}
            }
            "Disable Reserved Storage" {
                try { dism /Online /Set-ReservedStorageState /State:Disabled /Quiet 2>&1 | Out-Null; $success = $true } catch {}
            }
            "Set Services to Manual" {
                $services = @('DiagTrack','dmwappushservice')
                $any = $false
                foreach ($s in $services) {
                    try { Set-Service -Name $s -StartupType Manual -ErrorAction Stop; $any = $true } catch {}
                }
                $success = $any
            }
        }
        if ($success) { Write-Log "OK: $Name" 'OK' } else { Write-Log "SKIP: $Name" 'WARN' }
    } catch { Write-Log "FAILED: $Name - $($_.Exception.Message)" 'ERROR' }
}

# ═══════════════════════════════════════════════════════════
#  APPS CATALOG
# ═══════════════════════════════════════════════════════════

$script:Apps = @(
    @{Name="Chrome";      Id="Google.Chrome";                Icon="https://www.google.com/chrome/static/images/favicons/favicon-32x32.png";    Cat="Browsers"}
    @{Name="Firefox";     Id="Mozilla.Firefox";              Icon="https://www.mozilla.org/media/img/favicons/firefox/browser/favicon-32x32.1d3d4f70b9b0.png"; Cat="Browsers"}
    @{Name="Brave";       Id="Brave.Brave";                  Icon="https://brave.com/static-assets/images/brave-logo-sans-text.svg";             Cat="Browsers"}
    @{Name="Edge";        Id="Microsoft.Edge";               Icon="https://edgetipscdn.microsoft.com/insider-site/images/favicon.fbd89822.png"; Cat="Browsers"}
    @{Name="Vivaldi";     Id="Vivaldi.Vivaldi";              Icon="https://vivaldi.com/wp-content/uploads/vivaldi_favicon_32.png";                Cat="Browsers"}
    @{Name="Opera";       Id="Opera.Opera";                  Icon="https://www.opera.com/static/opera.ico";                                        Cat="Browsers"}
    @{Name="Discord";     Id="Discord.Discord";              Icon="https://cdn.prod.website-files.com/6257adef93867a3e003fb2c0/6257c7dc0c8b1a41ac66ffb9_favicon.png"; Cat="Communication"}
    @{Name="Telegram";    Id="Telegram.TelegramDesktop";     Icon="https://telegram.org/img/t_logo.png";                                            Cat="Communication"}
    @{Name="WhatsApp";    Id="WhatsApp.WhatsApp";            Icon="https://static.whatsapp.net/rsrc.php/v3/yP/r/rYZqPCBaG70.png";                   Cat="Communication"}
    @{Name="Zoom";        Id="Zoom.Zoom";                    Icon="https://st1.zoom.us/static/6.3.20.0/image/appicon/zoom_icon_dark.png";           Cat="Communication"}
    @{Name="Slack";       Id="SlackTechnologies.Slack";      Icon="https://a.slack-edge.com/80588/marketing/img/meta/favicon-32.png";              Cat="Communication"}
    @{Name="Signal";      Id="OpenWhisperSystems.Signal";    Icon="https://signal.org/assets/images/logo/logo.png";                                 Cat="Communication"}
    @{Name="VS Code";     Id="Microsoft.VisualStudioCode";   Icon="https://code.visualstudio.com/favicon.ico";                                      Cat="Development"}
    @{Name="Cursor";      Id="Anysphere.Cursor";             Icon="https://cursor.com/favicon.ico";                                                 Cat="Development"}
    @{Name="Git";         Id="Git.Git";                      Icon="https://git-scm.com/favicon.ico";                                                Cat="Development"}
    @{Name="Docker";      Id="Docker.DockerDesktop";         Icon="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png";                Cat="Development"}
    @{Name="Node.js LTS"; Id="OpenJS.NodeJS.LTS";            Icon="https://nodejs.org/static/images/favicons/favicon.png";                         Cat="Development"}
    @{Name="Python 3.12"; Id="Python.Python.3.12";           Icon="https://www.python.org/static/favicon.ico";                                      Cat="Development"}
    @{Name="Neovim";      Id="Neovim.Neovim";                Icon="https://neovim.io/favicon.ico";                                                  Cat="Development"}
    @{Name="GitHub CLI";  Id="GitHub.cli";                   Icon="https://github.githubassets.com/favicons/favicon.png";                          Cat="Development"}
    @{Name="VLC";         Id="VideoLAN.VLC";                 Icon="https://www.videolan.org/images/favicon.ico";                                    Cat="Multimedia"}
    @{Name="OBS Studio";  Id="OBSProject.OBSStudio";         Icon="https://obsproject.com/assets/images/new_icon_small-r.png";                     Cat="Multimedia"}
    @{Name="Audacity";    Id="Audacity.Audacity";            Icon="https://audacityteam.org/favicon.ico";                                           Cat="Multimedia"}
    @{Name="GIMP";        Id="GIMP.GIMP.3";                  Icon="https://www.gimp.org/favicon.ico";                                               Cat="Multimedia"}
    @{Name="7-Zip";       Id="7zip.7zip";                    Icon="https://7-zip.org/favicon.ico";                                                  Cat="Utilities"}
    @{Name="Notepad++";   Id="Notepad++.Notepad++";          Icon="https://notepad-plus-plus.org/favicon.ico";                                      Cat="Utilities"}
    @{Name="PowerToys";   Id="Microsoft.PowerToys";          Icon="https://raw.githubusercontent.com/microsoft/PowerToys/main/doc/images/overview/PowerToys.png"; Cat="Utilities"}
    @{Name="Everything";  Id="voidtools.Everything";         Icon="https://www.voidtools.com/favicon.ico";                                          Cat="Utilities"}
    @{Name="WinRAR";      Id="RARLab.WinRAR";                Icon="https://www.win-rar.com/favicon.ico";                                            Cat="Utilities"}
    @{Name="Steam";       Id="Valve.Steam";                  Icon="https://store.steampowered.com/favicon.ico";                                     Cat="Gaming"}
    @{Name="Epic Games";  Id="EpicGames.EpicGamesLauncher";  Icon="https://www.epicgames.com/favicon.ico";                                          Cat="Gaming"}
    @{Name="MSI Afterburner"; Id="Guru3D.Afterburner";       Icon="https://www.msi.com/favicon.ico";                                                Cat="Gaming"}
)

function Get-IconImage {
    param([string]$Url)
    if ($script:IconCache.ContainsKey($Url)) { return $script:IconCache[$Url] }
    try {
        $bytes = (New-Object System.Net.WebClient).DownloadData($Url)
        $stream = New-Object System.IO.MemoryStream(,$bytes)
        $img = New-Object System.Windows.Media.Imaging.BitmapImage
        $img.BeginInit()
        $img.StreamSource = $stream
        $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $img.DecodePixelWidth = 48
        $img.EndInit()
        $img.Freeze()
        $script:IconCache[$Url] = $img
        return $img
    } catch { return $null }
}

function Install-App {
    param([string]$WingetId, [string]$AppName)
    Write-Log "Installing: $AppName"
    try {
        winget install --id $WingetId --silent `
            --accept-package-agreements --accept-source-agreements `
            --disable-interactivity 2>&1 | Out-Null
        Write-Log "Installed: $AppName" 'OK'
    } catch { Write-Log "Failed: $AppName" 'ERROR' }
}

function Set-DNS {
    param([string]$Provider)
    $map = @{
        "Cloudflare" = @("1.1.1.1","1.0.0.1")
        "Google"     = @("8.8.8.8","8.8.4.4")
        "Quad9"      = @("9.9.9.9","149.112.112.112")
        "OpenDNS"    = @("208.67.222.222","208.67.220.220")
        "AdGuard"    = @("94.140.14.14","94.140.15.15")
    }
    if ($Provider -eq "Default") {
        Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses
        }
        return
    }
    if ($map.ContainsKey($Provider)) {
        Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses $map[$Provider]
        }
        Write-Log "DNS: $Provider" 'OK'
    }
}

# ═══════════════════════════════════════════════════════════
#  WPF GUI
# ═══════════════════════════════════════════════════════════

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BJA Toolbox v5.0" Height="850" Width="1400"
        WindowStartupLocation="CenterScreen"
        Background="#0a0a0f" Foreground="#e8e8f0"
        WindowStyle="None" ResizeMode="CanResizeWithGrip">

  <Window.Resources>
    <SolidColorBrush x:Key="BgDark"    Color="#0a0a0f"/>
    <SolidColorBrush x:Key="BgCard"    Color="#1c1c28"/>
    <SolidColorBrush x:Key="BgCardHov" Color="#252536"/>
    <SolidColorBrush x:Key="Accent"    Color="#00e5a0"/>
    <SolidColorBrush x:Key="Accent2"   Color="#7b5cff"/>
    <SolidColorBrush x:Key="TextMain"  Color="#e8e8f0"/>
    <SolidColorBrush x:Key="TextDim"   Color="#7a7a8a"/>
    <SolidColorBrush x:Key="Border"    Color="#26263a"/>

    <Style x:Key="AppCard" TargetType="ToggleButton">
      <Setter Property="Background" Value="{StaticResource BgCard}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Margin" Value="5"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="95"/>
      <Setter Property="Width" Value="170"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Border x:Name="bg" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="{StaticResource BgCardHov}"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent2}"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#0d3328"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Setter TargetName="bg" Property="BorderThickness" Value="2"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Background" Value="{StaticResource Accent}"/>
      <Setter Property="Foreground" Value="#0a0a0f"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Padding" Value="20,12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="8">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#00ffb0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SecondaryBtn" TargetType="Button">
      <Setter Property="Background" Value="{StaticResource BgCard}"/>
      <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
      <Setter Property="Padding" Value="16,10"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="{StaticResource BgCardHov}"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent2}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TweakCard" TargetType="CheckBox">
      <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
      <Setter Property="Padding" Value="12,8"/>
      <Setter Property="Margin" Value="0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="bg" Background="{StaticResource BgCard}"
                    BorderBrush="{StaticResource Border}"
                    BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <StackPanel Orientation="Horizontal">
                <Border x:Name="cb" Width="16" Height="16" CornerRadius="3"
                        Background="Transparent" BorderBrush="{StaticResource Border}"
                        BorderThickness="2" Margin="0,0,10,0">
                  <TextBlock x:Name="check" Text="✓" FontWeight="Bold" FontSize="11"
                             Foreground="#0a0a0f" HorizontalAlignment="Center"
                             VerticalAlignment="Center" Visibility="Collapsed"/>
                </Border>
                <ContentPresenter VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="{StaticResource BgCardHov}"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#0d3328"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Setter TargetName="cb" Property="Background" Value="{StaticResource Accent}"/>
                <Setter TargetName="cb" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Setter TargetName="check" Property="Visibility" Value="Visible"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="45"/>
      <RowDefinition Height="65"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="30"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Background="#08080c">
      <Grid>
        <StackPanel Orientation="Horizontal" Margin="20,0" VerticalAlignment="Center">
          <TextBlock Text="◈" FontSize="22" Foreground="{StaticResource Accent}" VerticalAlignment="Center"/>
          <TextBlock Text="BJA" FontSize="18" FontWeight="Bold" Margin="10,0,0,0" VerticalAlignment="Center"/>
          <TextBlock Text="Toolbox" FontSize="14" Foreground="{StaticResource TextDim}" Margin="6,0,0,0" VerticalAlignment="Center"/>
          <TextBlock Text="v5.0 Ultimate" FontSize="11" Foreground="{StaticResource Accent2}" Margin="10,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,10,0">
          <Button x:Name="BtnMin" Content="—" Width="42" Height="32" Background="Transparent" Foreground="#888" BorderThickness="0" FontSize="16" Cursor="Hand"/>
          <Button x:Name="BtnClose" Content="✕" Width="42" Height="32" Background="Transparent" Foreground="#888" BorderThickness="0" FontSize="14" Cursor="Hand"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Grid.Row="1" Background="#08080c" BorderBrush="{StaticResource Border}" BorderThickness="0,1,0,1">
      <Grid Margin="24,0">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="320"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock x:Name="HeaderText" Text="Applications" FontSize="20" FontWeight="Bold"/>
          <TextBlock x:Name="SubHeaderText" Text="Install apps via winget" FontSize="11" Foreground="{StaticResource TextDim}" Margin="0,2,0,0"/>
        </StackPanel>
        <Border Grid.Column="1" Background="{StaticResource BgCard}" CornerRadius="10" BorderBrush="{StaticResource Border}" BorderThickness="1" VerticalAlignment="Center" Height="40">
          <Grid>
            <TextBlock Text="🔍  Search..." Foreground="{StaticResource TextDim}" VerticalAlignment="Center" Margin="14,0,0,0" x:Name="SearchPlaceholder"/>
            <TextBox x:Name="SearchBox" Background="Transparent" Foreground="{StaticResource TextMain}" BorderThickness="0" Padding="14,0" VerticalContentAlignment="Center" FontSize="12.5" CaretBrush="{StaticResource Accent}"/>
          </Grid>
        </Border>
      </Grid>
    </Border>

    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="220"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <Border Grid.Column="0" Background="#08080c" BorderBrush="{StaticResource Border}" BorderThickness="0,0,1,0">
        <Grid Margin="14">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <StackPanel Grid.Row="0">
            <Button x:Name="NavInstall" Content="📦   Install"    Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <Button x:Name="NavTweaks"  Content="⚙️   Tweaks"     Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <Button x:Name="NavConfig"  Content="🔧   Config"     Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <Button x:Name="NavUpdates" Content="🔄   Updates"    Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
          </StackPanel>

          <TextBlock Grid.Row="1" Text="PRESETS" FontSize="10" Foreground="{StaticResource TextDim}" FontWeight="Bold" Margin="0,18,0,6"/>

          <StackPanel Grid.Row="2">
            <Button x:Name="PresetStandard" Content="⚡  Standard"  Style="{StaticResource SecondaryBtn}" Margin="0,3" Background="#1a3a2a" BorderBrush="#00e5a0"/>
            <Button x:Name="PresetMinimal"  Content="🌿  Minimal"   Style="{StaticResource SecondaryBtn}" Margin="0,3"/>
            <Button x:Name="PresetAdvanced" Content="🔥  Advanced"  Style="{StaticResource SecondaryBtn}" Margin="0,3"/>
            <Button x:Name="PresetGaming"   Content="🎮  Gaming"    Style="{StaticResource SecondaryBtn}" Margin="0,3"/>
            <Button x:Name="PresetExtreme"  Content="💀  Extreme"   Style="{StaticResource SecondaryBtn}" Margin="0,3" Foreground="#ff5566"/>
          </StackPanel>

          <StackPanel Grid.Row="3">
            <Border Height="1" Background="{StaticResource Border}" Margin="0,10"/>
            <Button x:Name="NavRun" Content="▶  RUN SELECTED" Style="{StaticResource PrimaryBtn}" Height="48" Margin="0,4"/>
            <Button x:Name="NavClear" Content="✕  Clear" Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <TextBlock x:Name="StatusCount" Text="0 selected" Foreground="{StaticResource TextDim}" FontSize="11" Margin="0,12,0,0" HorizontalAlignment="Center"/>
          </StackPanel>
        </Grid>
      </Border>

      <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" Padding="20">
        <StackPanel x:Name="ContentArea"/>
      </ScrollViewer>
    </Grid>

    <Border Grid.Row="3" Background="#08080c" BorderBrush="{StaticResource Border}" BorderThickness="0,1,0,0">
      <Grid Margin="24,0">
        <TextBlock x:Name="StatusText" Text="Ready" Foreground="{StaticResource TextDim}" FontSize="11" VerticalAlignment="Center"/>
        <TextBlock Text="BJA Toolbox v5.0" Foreground="{StaticResource TextDim}" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
      </Grid>
    </Border>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$ContentArea = $window.FindName("ContentArea")
$HeaderText  = $window.FindName("HeaderText")
$SubHeaderText = $window.FindName("SubHeaderText")
$StatusText  = $window.FindName("StatusText")
$StatusCount = $window.FindName("StatusCount")
$SearchBox   = $window.FindName("SearchBox")
$SearchPlaceholder = $window.FindName("SearchPlaceholder")

$window.FindName("BtnClose").Add_Click({ $window.Close() })
$window.FindName("BtnMin").Add_Click({ $window.WindowState = 'Minimized' })

$SearchBox.Add_GotFocus({ $SearchPlaceholder.Visibility = 'Collapsed' })
$SearchBox.Add_LostFocus({
    if ([string]::IsNullOrEmpty($SearchBox.Text)) { $SearchPlaceholder.Visibility = 'Visible' }
})

# ═══════════════════════════════════════════════════════════
#  VIEWS
# ═══════════════════════════════════════════════════════════

function Show-InstallView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Applications"
    $SubHeaderText.Text = "Install your favorite apps via winget"

    $categories = $script:Apps | Group-Object Cat | Sort-Object Name
    foreach ($cat in $categories) {
        $catTitle = New-Object System.Windows.Controls.TextBlock
        $catTitle.Text = "▸ $($cat.Name)"
        $catTitle.FontSize = 15; $catTitle.FontWeight = "Bold"
        $catTitle.Foreground = "#7b5cff"; $catTitle.Margin = "6,20,0,10"
        $ContentArea.Children.Add($catTitle) | Out-Null

        $wrap = New-Object System.Windows.Controls.WrapPanel
        foreach ($app in ($cat.Group | Sort-Object Name)) {
            $tile = New-Object System.Windows.Controls.Primitives.ToggleButton
            $tile.Style = $window.FindResource("AppCard")
            $tile.Tag = $app.Id

            $inner = New-Object System.Windows.Controls.StackPanel
            $inner.VerticalAlignment = "Center"; $inner.HorizontalAlignment = "Center"

            $img = Get-IconImage -Url $app.Icon
            if ($img) {
                $imgBox = New-Object System.Windows.Controls.Image
                $imgBox.Source = $img
                $imgBox.Width = 42; $imgBox.Height = 42
                $imgBox.HorizontalAlignment = "Center"
                $inner.Children.Add($imgBox) | Out-Null
            } else {
                $fallback = New-Object System.Windows.Controls.TextBlock
                $fallback.Text = "📦"; $fallback.FontSize = 32
                $fallback.HorizontalAlignment = "Center"
                $inner.Children.Add($fallback) | Out-Null
            }

            $name = New-Object System.Windows.Controls.TextBlock
            $name.Text = $app.Name; $name.FontSize = 12; $name.FontWeight = "SemiBold"
            $name.Foreground = "#e8e8f0"; $name.HorizontalAlignment = "Center"; $name.Margin = "0,6,0,0"
            $inner.Children.Add($name) | Out-Null

            $tile.Content = $inner
            $tile.Add_Checked({
                if (-not $script:SelectedApps.Contains($this.Tag)) {
                    [void]$script:SelectedApps.Add($this.Tag)
                    $StatusCount.Text = "$($script:SelectedApps.Count) selected"
                }
            })
            $tile.Add_Unchecked({
                $script:SelectedApps.Remove($this.Tag) | Out-Null
                $StatusCount.Text = "$($script:SelectedApps.Count) selected"
            })
            $wrap.Children.Add($tile) | Out-Null
        }
        $ContentArea.Children.Add($wrap) | Out-Null
    }
}

function Show-TweaksView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Tweaks"
    $SubHeaderText.Text = "Optimize your system — presets or individual selection"

    $mainGrid = New-Object System.Windows.Controls.Grid
    $colL = New-Object System.Windows.Controls.ColumnDefinition; $colL.Width = "1.3*"
    $colR = New-Object System.Windows.Controls.ColumnDefinition; $colR.Width = "*"
    $mainGrid.ColumnDefinitions.Add($colL); $mainGrid.ColumnDefinitions.Add($colR)

    # LEFT
    $left = New-Object System.Windows.Controls.StackPanel
    $left.Margin = "0,0,10,0"

    function AddTweakSection {
        param($parent, $title, $color, $tweaks)
        $h = New-Object System.Windows.Controls.TextBlock
        $h.Text = $title; $h.FontSize = 14; $h.FontWeight = "Bold"
        $h.Foreground = $color; $h.Margin = "0,14,0,6"
        $parent.Children.Add($h) | Out-Null
        foreach ($t in $tweaks) {
            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Style = $window.FindResource("TweakCard")
            $cb.Content = "   $t"; $cb.Tag = $t
            $cb.Add_Checked({
                if (-not $script:SelectedTweaks.Contains($this.Tag)) {
                    [void]$script:SelectedTweaks.Add($this.Tag)
                    $StatusCount.Text = "$($script:SelectedTweaks.Count) selected"
                }
            })
            $cb.Add_Unchecked({
                $script:SelectedTweaks.Remove($this.Tag) | Out-Null
                $StatusCount.Text = "$($script:SelectedTweaks.Count) selected"
            })
            $parent.Children.Add($cb) | Out-Null
        }
    }

    AddTweakSection -parent $left -title "Essential Tweaks" -color "#7b5cff" -tweaks @(
        "Disable Telemetry","Disable Activity History","Disable Location Tracking",
        "Disable Advertising ID","Disable Consumer Features","Disable Cortana",
        "Disable Bing Search","Disable Copilot","Disable Recall","Disable WPBT",
        "Disable Delivery Optimization","Disable SysMain","Disable Hibernation",
        "Disk Cleanup","Delete Temp Files","Empty Recycle Bin","Create Restore Point",
        "Disable Widgets","Show File Extensions","Show Hidden Files","Dark Mode"
    )

    AddTweakSection -parent $left -title "Performance Tweaks" -color "#00e5a0" -tweaks @(
        "Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay",
        "Disable Power Throttling","Optimize SSD","Disable Background Apps",
        "Adjust Visual Effects for Performance","Optimize Memory Management",
        "Enable Game Mode","Disable Game Bar","Clear Prefetch","Disable Search Indexing"
    )

    AddTweakSection -parent $left -title "Network Tweaks" -color "#66ccff" -tweaks @(
        "Optimize TCP Settings","Disable NetBIOS over TCP/IP","Disable Windows Reserved Bandwidth",
        "Set IPv6 to Prefer IPv4","Disable IPv6","Clear DNS Cache"
    )

    AddTweakSection -parent $left -title "Advanced — CAUTION" -color "#ff9944" -tweaks @(
        "Disable Remote Registry","Disable Xbox Services","Disable SMBv1","Disable AutoRun",
        "Enable Defender PUA Protection","Disable Reserved Storage",
        "Disable Explorer Auto Discovery","Enable Start Menu Previous Layout",
        "Taskbar Left Align","Disable Lock Screen","Disable Transparency Effects",
        "Disable Animations","Disable Sticky Keys Prompt","Num Lock on Startup",
        "Disable Taskbar Search","Hide Task View Button","Disable File Explorer Home",
        "Set Services to Manual","Enable Long Paths","Clear Windows Update Cache",
        "Reset Windows Store Cache"
    )

    [System.Windows.Controls.Grid]::SetColumn($left, 0)
    $mainGrid.Children.Add($left) | Out-Null

    # RIGHT — Preferences
    $right = New-Object System.Windows.Controls.StackPanel
    $ph = New-Object System.Windows.Controls.TextBlock
    $ph.Text = "Customize Preferences"; $ph.FontSize = 14; $ph.FontWeight = "Bold"
    $ph.Foreground = "#00e5a0"; $ph.Margin = "0,0,0,8"
    $right.Children.Add($ph) | Out-Null

    $prefs = @(
        @{Name="BSOD Verbose Mode"; Default=$false}
        @{Name="Dark Theme for Windows"; Default=$true}
        @{Name="Long Paths"; Default=$true}
        @{Name="File Extensions"; Default=$true}
        @{Name="Hidden Files"; Default=$true}
        @{Name="Game Mode"; Default=$true}
        @{Name="Lock Screen Disabled"; Default=$false}
        @{Name="Logon Acrylic Blur"; Default=$true}
        @{Name="Outlook New Version"; Default=$true}
        @{Name="Mouse Acceleration"; Default=$false}
        @{Name="Num Lock on Startup"; Default=$true}
        @{Name="S0 Sleep Network"; Default=$true}
        @{Name="S3 Sleep"; Default=$false}
        @{Name="Scrollbars Always Visible"; Default=$false}
        @{Name="Start Bing Search"; Default=$false}
        @{Name="Start Recommendations"; Default=$false}
        @{Name="Sticky Keys"; Default=$false}
        @{Name="Battery Percentage"; Default=$false}
        @{Name="Centered Taskbar Icons"; Default=$true}
        @{Name="Taskbar Search Icon"; Default=$false}
        @{Name="Taskbar Task View"; Default=$true}
        @{Name="Window Snapping"; Default=$true}
    )

    foreach ($p in $prefs) {
        $rowBorder = New-Object System.Windows.Controls.Border
        $rowBorder.Background = "#1c1c28"
        $rowBorder.BorderBrush = "#26263a"
        $rowBorder.BorderThickness = "1"
        $rowBorder.CornerRadius = "6"
        $rowBorder.Padding = "10,8"
        $rowBorder.Margin = "0,3"

        $rowGrid = New-Object System.Windows.Controls.Grid
        $colLabel = New-Object System.Windows.Controls.ColumnDefinition; $colLabel.Width = "*"
        $colToggle = New-Object System.Windows.Controls.ColumnDefinition; $colToggle.Width = "Auto"
        $rowGrid.ColumnDefinitions.Add($colLabel); $rowGrid.ColumnDefinitions.Add($colToggle)

        $lbl = New-Object System.Windows.Controls.TextBlock
        $lbl.Text = $p.Name; $lbl.FontSize = 11.5
        $lbl.Foreground = "#e8e8f0"; $lbl.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($lbl, 0)
        $rowGrid.Children.Add($lbl) | Out-Null

        $toggle = New-Object System.Windows.Controls.Primitives.ToggleButton
        $toggle.Width = 40; $toggle.Height = 20; $toggle.Cursor = "Hand"
        $toggle.IsChecked = $p.Default; $toggle.Tag = $p.Name
        $toggle.Template = [System.Windows.Markup.XamlReader]::Parse(@"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                 TargetType="ToggleButton">
  <Border x:Name="bg" Background="#3a3a4a" CornerRadius="10" Width="40" Height="20">
    <Border x:Name="knob" Background="#8a8a9a" CornerRadius="8" Width="16" Height="16"
            HorizontalAlignment="Left" Margin="2,0,0,0"/>
  </Border>
  <ControlTemplate.Triggers>
    <Trigger Property="IsChecked" Value="True">
      <Setter TargetName="bg" Property="Background" Value="#00e5a0"/>
      <Setter TargetName="knob" Property="Background" Value="#ffffff"/>
      <Setter TargetName="knob" Property="HorizontalAlignment" Value="Right"/>
      <Setter TargetName="knob" Property="Margin" Value="0,0,2,0"/>
    </Trigger>
  </ControlTemplate.Triggers>
</ControlTemplate>
"@)
        [System.Windows.Controls.Grid]::SetColumn($toggle, 1)
        $rowGrid.Children.Add($toggle) | Out-Null

        $rowBorder.Child = $rowGrid
        $right.Children.Add($rowBorder) | Out-Null
    }

    [System.Windows.Controls.Grid]::SetColumn($right, 1)
    $mainGrid.Children.Add($right) | Out-Null

    $ContentArea.Children.Add($mainGrid) | Out-Null
}

function Show-ConfigView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Configuration"
    $SubHeaderText.Text = "DNS, Fixes, Legacy panels"

    $dnsTitle = New-Object System.Windows.Controls.TextBlock
    $dnsTitle.Text = "▸ DNS Provider"
    $dnsTitle.FontSize = 15; $dnsTitle.FontWeight = "Bold"
    $dnsTitle.Foreground = "#7b5cff"; $dnsTitle.Margin = "6,10,0,10"
    $ContentArea.Children.Add($dnsTitle) | Out-Null

    $dnsWrap = New-Object System.Windows.Controls.WrapPanel
    foreach ($dns in @("Cloudflare","Google","Quad9","OpenDNS","AdGuard","Default")) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("SecondaryBtn")
        $btn.Content = $dns; $btn.Tag = $dns
        $btn.Width = 170; $btn.Height = 45; $btn.Margin = "6"
        $btn.HorizontalContentAlignment = "Center"
        $btn.Add_Click({
            Set-DNS -Provider $this.Tag
            $StatusText.Text = "DNS: $($this.Tag)"
        })
        $dnsWrap.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($dnsWrap) | Out-Null

    $toolsTitle = New-Object System.Windows.Controls.TextBlock
    $toolsTitle.Text = "▸ Fixes & Tools"
    $toolsTitle.FontSize = 15; $toolsTitle.FontWeight = "Bold"
    $toolsTitle.Foreground = "#7b5cff"; $toolsTitle.Margin = "6,30,0,10"
    $ContentArea.Children.Add($toolsTitle) | Out-Null

    $tools = @(
        @{Name="Network Reset";       Action={ Start-Process "netsh" -ArgumentList "int ip reset" -Wait -NoNewWindow }}
        @{Name="System File Check";   Action={ Start-Process "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow }}
        @{Name="DISM Restore";        Action={ Start-Process "dism" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow }}
        @{Name="Restore Point";       Action={ New-RestorePoint }}
        @{Name="Control Panel";       Action={ Start-Process "control" }}
        @{Name="Programs & Features"; Action={ Start-Process "appwiz.cpl" }}
        @{Name="Network Connections"; Action={ Start-Process "ncpa.cpl" }}
        @{Name="System Information";  Action={ Start-Process "msinfo32" }}
        @{Name="Device Manager";      Action={ Start-Process "devmgmt.msc" }}
        @{Name="Services";            Action={ Start-Process "services.msc" }}
    )
    $toolsWrap = New-Object System.Windows.Controls.WrapPanel
    foreach ($t in $tools) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("SecondaryBtn")
        $btn.Content = $t.Name
        $btn.Width = 170; $btn.Height = 45; $btn.Margin = "6"
        $btn.HorizontalContentAlignment = "Center"
        $btn.Add_Click($t.Action)
        $toolsWrap.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($toolsWrap) | Out-Null
}

function Show-UpdatesView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Windows Update Control"
    $SubHeaderText.Text = "Choose how Windows handles updates"

    $profiles = @(
        @{Name="Recommended";      Desc="Defers feature updates 365 days · Defers quality updates 4 days"; Color="#00e5a0"}
        @{Name="Windows Default";  Desc="Restore default Windows Update settings"; Color="#7b5cff"}
        @{Name="Disable Updates";  Desc="Not recommended — stops automatic updates entirely"; Color="#ff5566"}
    )
    foreach ($p in $profiles) {
        $card = New-Object System.Windows.Controls.Border
        $card.Background = "#1c1c28"; $card.BorderBrush = $p.Color; $card.BorderThickness = "2"
        $card.CornerRadius = "12"; $card.Padding = "24"; $card.Margin = "6,6,6,16"
        $card.MaxWidth = 750; $card.HorizontalAlignment = "Left"

        $inner = New-Object System.Windows.Controls.StackPanel
        $title = New-Object System.Windows.Controls.TextBlock
        $title.Text = $p.Name; $title.FontSize = 20; $title.FontWeight = "Bold"; $title.Foreground = $p.Color
        $inner.Children.Add($title) | Out-Null

        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = $p.Desc; $desc.Foreground = "#8a8a9a"; $desc.Margin = "0,8,0,16"; $desc.TextWrapping = "Wrap"
        $inner.Children.Add($desc) | Out-Null

        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "Apply Profile"; $btn.Style = $window.FindResource("PrimaryBtn")
        $btn.HorizontalAlignment = "Left"; $btn.Tag = $p.Name
        $btn.Add_Click({
            $up = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            switch ($this.Tag) {
                "Recommended" {
                    if (-not (Test-Path $up)) { New-Item $up -Force | Out-Null }
                    Set-ItemProperty $up -Name DeferFeatureUpdates -Value 1 -Type DWord -Force
                    Set-ItemProperty $up -Name DeferFeatureUpdatesPeriodInDays -Value 365 -Type DWord -Force
                    Set-ItemProperty $up -Name DeferQualityUpdates -Value 1 -Type DWord -Force
                    Set-ItemProperty $up -Name DeferQualityUpdatesPeriodInDays -Value 4 -Type DWord -Force
                }
                "Windows Default" { Remove-Item $up -Recurse -Force -ErrorAction SilentlyContinue }
                "Disable Updates" {
                    if (-not (Test-Path $up)) { New-Item $up -Force | Out-Null }
                    Set-ItemProperty $up -Name NoAutoUpdate -Value 1 -Type DWord -Force
                }
            }
            $StatusText.Text = "Updates: $($this.Tag)"
        })
        $inner.Children.Add($btn) | Out-Null
        $card.Child = $inner
        $ContentArea.Children.Add($card) | Out-Null
    }
}

# ═══════════════════════════════════════════════════════════
#  PRESETS
# ═══════════════════════════════════════════════════════════

$Presets = @{
    "Standard" = @(
        "Disable Telemetry","Disable Activity History","Disable Location Tracking",
        "Disable Advertising ID","Disable Consumer Features","Disable Delivery Optimization",
        "Disable SysMain","Disk Cleanup","Delete Temp Files","Empty Recycle Bin",
        "Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets",
        "Enable End Task on Taskbar"
    )
    "Minimal" = @(
        "Disable Telemetry","Disable Advertising ID","Disk Cleanup","Empty Recycle Bin"
    )
    "Advanced" = @(
        "Disable Telemetry","Disable Activity History","Disable Location Tracking",
        "Disable Advertising ID","Disable Consumer Features","Disable Cortana",
        "Disable Bing Search","Disable Copilot","Disable Recall","Disable WPBT",
        "Disable Delivery Optimization","Disable SysMain","Disable Hibernation",
        "Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay",
        "Disable Power Throttling","Optimize SSD","Disable Background Apps",
        "Adjust Visual Effects for Performance","Optimize Memory Management",
        "Optimize TCP Settings","Disable NetBIOS over TCP/IP","Disable Windows Reserved Bandwidth",
        "Set IPv6 to Prefer IPv4","Disable Remote Registry","Disable Xbox Services",
        "Disable SMBv1","Disable AutoRun","Enable Defender PUA Protection",
        "Disable Reserved Storage","Disable Explorer Auto Discovery","Enable Long Paths",
        "Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets",
        "Enable End Task on Taskbar","Disable Lock Screen","Disable Transparency Effects",
        "Disable Animations","Disable Sticky Keys Prompt","Num Lock on Startup",
        "Disable Taskbar Search","Hide Task View Button","Disable File Explorer Home",
        "Disk Cleanup","Delete Temp Files","Empty Recycle Bin","Clear DNS Cache",
        "Clear Windows Update Cache","Reset Windows Store Cache"
    )
    "Gaming" = @(
        "Disable Telemetry","Disable Consumer Features","Disable Delivery Optimization",
        "Disable SysMain","Disable Hibernation","Enable GPU Scheduling",
        "Enable Ultimate Performance","Disable Startup Delay","Disable Power Throttling",
        "Disable Background Apps","Adjust Visual Effects for Performance",
        "Optimize Memory Management","Enable Game Mode","Disable Game Bar",
        "Disable Xbox Services","Disable Widgets","Dark Mode",
        "Optimize TCP Settings","Disable NetBIOS over TCP/IP",
        "Disk Cleanup","Delete Temp Files","Empty Recycle Bin","Clear DNS Cache"
    )
    "Extreme" = @(
        "Disable Telemetry","Disable Activity History","Disable Location Tracking",
        "Disable Advertising ID","Disable Consumer Features","Disable Cortana",
        "Disable Bing Search","Disable Copilot","Disable Recall","Disable WPBT",
        "Disable Delivery Optimization","Disable SysMain","Disable Hibernation",
        "Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay",
        "Disable Power Throttling","Optimize SSD","Disable Background Apps",
        "Adjust Visual Effects for Performance","Optimize Memory Management",
        "Disable Search Indexing","Clear Prefetch","Optimize TCP Settings",
        "Disable NetBIOS over TCP/IP","Disable Windows Reserved Bandwidth",
        "Disable IPv6","Disable Remote Registry","Disable Xbox Services",
        "Disable SMBv1","Disable AutoRun","Enable Defender PUA Protection",
        "Disable Reserved Storage","Disable Explorer Auto Discovery","Enable Long Paths",
        "Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets",
        "Disable Start Recommendations","Enable End Task on Taskbar","Disable Lock Screen",
        "Disable Transparency Effects","Disable Animations","Disable Sticky Keys Prompt",
        "Num Lock on Startup","Disable Taskbar Search","Hide Task View Button",
        "Disable File Explorer Home","Disk Cleanup","Delete Temp Files","Empty Recycle Bin",
        "Clear DNS Cache","Clear Windows Update Cache","Reset Windows Store Cache",
        "Run System File Check","Run DISM Restore"
    )
}

function Apply-Preset {
    param([string]$Name)
    $preset = $Presets[$Name]
    $count = 0
    foreach ($child in $ContentArea.Children) {
        if ($child -is [System.Windows.Controls.Grid]) {
            foreach ($gchild in $child.Children) {
                if ($gchild -is [System.Windows.Controls.StackPanel]) {
                    foreach ($sc in $gchild.Children) {
                        if ($sc -is [System.Windows.Controls.CheckBox]) {
                            $sc.IsChecked = $preset -contains $sc.Tag
                            if ($sc.IsChecked) { $count++ }
                        }
                    }
                }
            }
        }
    }
    $StatusText.Text = "Preset: $Name ($count tweaks)"
}

$window.FindName("PresetStandard").Add_Click({ Apply-Preset -Name "Standard" })
$window.FindName("PresetMinimal").Add_Click({  Apply-Preset -Name "Minimal"  })
$window.FindName("PresetAdvanced").Add_Click({ Apply-Preset -Name "Advanced" })
$window.FindName("PresetGaming").Add_Click({   Apply-Preset -Name "Gaming"   })
$window.FindName("PresetExtreme").Add_Click({  Apply-Preset -Name "Extreme"  })

# ═══════════════════════════════════════════════════════════
#  NAVIGATION
# ═══════════════════════════════════════════════════════════

$window.FindName("NavInstall").Add_Click({ Show-InstallView })
$window.FindName("NavTweaks").Add_Click({  Show-TweaksView  })
$window.FindName("NavConfig").Add_Click({  Show-ConfigView  })
$window.FindName("NavUpdates").Add_Click({ Show-UpdatesView })

$window.FindName("NavClear").Add_Click({
    $script:SelectedApps.Clear(); $script:SelectedTweaks.Clear()
    $StatusCount.Text = "0 selected"
    Show-InstallView
})

$window.FindName("NavRun").Add_Click({
    if ($script:SelectedApps.Count -gt 0) {
        New-RestorePoint
        foreach ($id in $script:SelectedApps) {
            $app = $script:Apps | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($app) { Install-App -WingetId $app.Id -AppName $app.Name }
        }
    }
    if ($script:SelectedTweaks.Count -gt 0) {
        New-RestorePoint
        foreach ($t in $script:SelectedTweaks) { Invoke-Tweak -Name $t }
    }
    [System.Windows.MessageBox]::Show("Done! Check log on Desktop", "BJA Toolbox")
    $StatusText.Text = "Complete"
})

# ═══════════════════════════════════════════════════════════
#  START
# ═══════════════════════════════════════════════════════════

Show-InstallView
Write-Log "BJA Toolbox v$($script:Version) started"
$window.ShowDialog() | Out-Null
Write-Log "BJA Toolbox closed"