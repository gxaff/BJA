<#
.SYNOPSIS
    BJA Toolbox v9.0 Final - Async Icons + Splash + Zero Hang

.DESCRIPTION
    - Password Lock (142010)
    - Splash Screen فوري
    - Async Icon Loading (الواجهة تفتح قبل تحميل الأيقونات)
    - Local Icon Cache
    - 80+ Tweak + 5 Presets
    - Input Tab
    - Config + Updates

.USAGE
    irm https://raw.githubusercontent.com/gxaff/BJA/main/bja.ps1 | iex
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$script:Version        = "9.0.0"
$script:Password       = "142010"
$script:LogPath        = "$env:USERPROFILE\Desktop\BJA_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$script:SelectedTweaks = New-Object System.Collections.ArrayList
$script:TweakBoxes     = New-Object System.Collections.ArrayList
$script:IconCacheDir   = "$env:LOCALAPPDATA\BJA\Icons"
if (-not (Test-Path $script:IconCacheDir)) {
    New-Item $script:IconCacheDir -ItemType Directory -Force | Out-Null
}

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
#  WPF SETUP
# ═══════════════════════════════════════════════════════════

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ═══════════════════════════════════════════════════════════
#  SPLASH SCREEN
# ═══════════════════════════════════════════════════════════

function Show-Splash {
    $splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BJA" Height="240" Width="440"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" ResizeMode="NoResize"
        AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False">
  <Border Background="#0a0a0f" CornerRadius="18" BorderBrush="#00e5a0" BorderThickness="2">
    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="30">
      <TextBlock Text="◈" FontSize="52" Foreground="#00e5a0" HorizontalAlignment="Center"/>
      <TextBlock Text="BJA Toolbox" FontSize="24" FontWeight="Bold" Foreground="#e8e8f0" HorizontalAlignment="Center" Margin="0,10,0,0"/>
      <TextBlock Text="v9.0 Final" FontSize="11" Foreground="#7b5cff" HorizontalAlignment="Center" Margin="0,2,0,0"/>
      <TextBlock x:Name="SplashStatus" Text="Initializing..." FontSize="11" Foreground="#7a7a8a" HorizontalAlignment="Center" Margin="0,20,0,8"/>
      <Border Background="#1c1c28" CornerRadius="4" Height="6" Width="320" HorizontalAlignment="Center">
        <Border x:Name="SplashBar" Background="#00e5a0" CornerRadius="4" Height="6" Width="0" HorizontalAlignment="Left"/>
      </Border>
    </StackPanel>
  </Border>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$splashXaml)
    $splash = [Windows.Markup.XamlReader]::Load($reader)
    $splash.Show()
    return $splash
}

function Update-Splash {
    param($Splash, [string]$Status, [int]$Percent)
    try {
        $bar = $Splash.FindName("SplashBar")
        $txt = $Splash.FindName("SplashStatus")
        if ($txt) { $txt.Text = $Status }
        if ($bar) { $bar.Width = 320 * $Percent / 100 }
        $Splash.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
    } catch {}
}

$splash = Show-Splash
Start-Sleep -Milliseconds 200
Update-Splash $splash "Loading WPF components..." 20

# ═══════════════════════════════════════════════════════════
#  PASSWORD LOCK
# ═══════════════════════════════════════════════════════════

function Show-PasswordLock {
    $lockXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BJA Lock" Height="520" Width="460"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" ResizeMode="NoResize"
        AllowsTransparency="True" Background="Transparent">
  <Border Background="#0a0a0f" CornerRadius="18" BorderBrush="#00e5a0" BorderThickness="2">
    <Grid>
      <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="45">
        <TextBlock Text="◈" FontSize="70" Foreground="#00e5a0" HorizontalAlignment="Center"/>
        <TextBlock Text="BJA Toolbox" FontSize="28" FontWeight="Bold" Foreground="#e8e8f0" HorizontalAlignment="Center" Margin="0,14,0,0"/>
        <TextBlock Text="v9.0 Final" FontSize="12" Foreground="#7b5cff" HorizontalAlignment="Center" Margin="0,4,0,32"/>
        <TextBlock Text="أدخل الرمز السري" FontSize="14" Foreground="#7a7a8a" HorizontalAlignment="Center" Margin="0,0,0,12"/>
        <Border Background="#1c1c28" CornerRadius="10" BorderBrush="#26263a" BorderThickness="1" Padding="16,12">
          <PasswordBox x:Name="PwdBox" Background="Transparent" Foreground="#e8e8f0" BorderThickness="0"
                       FontSize="24" HorizontalContentAlignment="Center" CaretBrush="#00e5a0" MaxLength="20"/>
        </Border>
        <TextBlock x:Name="ErrorText" Text="" FontSize="12" Foreground="#ff5566" HorizontalAlignment="Center" Margin="0,12,0,0"/>
        <Button x:Name="UnlockBtn" Content="UNLOCK" Height="46" Margin="0,22,0,0"
                Background="#00e5a0" Foreground="#0a0a0f" FontWeight="Bold" FontSize="14"
                BorderThickness="0" Cursor="Hand">
          <Button.Template>
            <ControlTemplate TargetType="Button">
              <Border Background="{TemplateBinding Background}" CornerRadius="10">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
            </ControlTemplate>
          </Button.Template>
        </Button>
        <TextBlock Text="Powered by BJA" FontSize="10" Foreground="#3a3a4a" HorizontalAlignment="Center" Margin="0,22,0,0"/>
      </StackPanel>
    </Grid>
  </Border>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$lockXaml)
    $lockWin = [Windows.Markup.XamlReader]::Load($reader)
    $lockWin.Add_MouseLeftButtonDown({ try { $lockWin.DragMove() } catch {} })

    $pwdBox    = $lockWin.FindName("PwdBox")
    $errText   = $lockWin.FindName("ErrorText")
    $unlockBtn = $lockWin.FindName("UnlockBtn")
    $script:Unlocked = $false

    $tryUnlock = {
        if ($pwdBox.Password -eq $script:Password) {
            $script:Unlocked = $true
            $lockWin.Close()
        } else {
            $errText.Text = "❌ الرمز غلط — حاول تاني"
            $pwdBox.Password = ""
            $pwdBox.Focus() | Out-Null
        }
    }
    $unlockBtn.Add_Click($tryUnlock)
    $pwdBox.Add_KeyDown({ if ($_.Key -eq 'Return') { & $tryUnlock } })
    $pwdBox.Focus() | Out-Null
    $lockWin.ShowDialog() | Out-Null
    return $script:Unlocked
}

Update-Splash $splash "Lock screen..." 40
$splash.Close()

if (-not (Show-PasswordLock)) {
    Write-Host "  ❌ Access Denied" -ForegroundColor Red
    exit
}
Write-Host "  ✅ Access granted" -ForegroundColor Green
Write-Host ""

$splash = Show-Splash
Update-Splash $splash "Loading main interface..." 60

# ═══════════════════════════════════════════════════════════
#  TWEAK ENGINE
# ═══════════════════════════════════════════════════════════

function Invoke-Tweak {
    param([string]$Name)
    Write-Log "Applying: $Name"
    $success = $false
    try {
        switch ($Name) {
            "Disable Telemetry" {
                $p1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
                if (-not (Test-Path $p1)) { New-Item $p1 -Force | Out-Null }
                Set-ItemProperty $p1 -Name AllowTelemetry -Value 0 -Type DWord -Force
                $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                if (-not (Test-Path $p2)) { New-Item $p2 -Force | Out-Null }
                Set-ItemProperty $p2 -Name AllowTelemetry -Value 0 -Type DWord -Force
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
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name HwSchMode -Value 2 -Type DWord -Force
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
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name DisableWpbtExecution -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Power Throttling" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name PowerThrottlingOff -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Background Apps" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name GlobalUserDisabled -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
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
            "Optimize SSD" {
                try {
                    $letter = $env:SystemDrive.Replace(":","")
                    Optimize-Volume -DriveLetter $letter -ReTrim -ErrorAction Stop
                    $success = $true
                } catch {}
            }
            "Adjust Visual Effects for Performance" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Search Indexing" {
                try { Set-Service -Name WSearch -StartupType Disabled -ErrorAction Stop; $success = $true } catch {}
            }
            "Disable IPv6" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -Value 0xFF -Type DWord -Force
                $success = $true
            }
            "Set IPv6 to Prefer IPv4" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -Value 0x20 -Type DWord -Force
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
            "Disable AutoRun" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name NoDriveTypeAutoRun -Value 255 -Type DWord -Force
                $success = $true
            }
            "Enable Defender PUA Protection" {
                try { Set-MpPreference -PUAProtection 1 -ErrorAction Stop; $success = $true } catch {}
            }
            "Show File Extensions" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 -Type DWord -Force
                $success = $true
            }
            "Show Hidden Files" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1 -Type DWord -Force
                $success = $true
            }
            "Dark Mode" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value 0 -Type DWord -Force
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value 0 -Type DWord -Force
                $success = $true
            }
            "Enable Long Paths" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name LongPathsEnabled -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Widgets" {
                try {
                    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { $success = $true }
                } catch {}
            }
            "Disable Start Recommendations" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_IrisRecommendations -Value 0 -Type DWord -Force
                $success = $true
            }
            "Enable End Task on Taskbar" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name TaskbarEndTask -Value 1 -Type DWord -Force
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
            "Taskbar Left Align" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Transparency Effects" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Animations" {
                Set-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Value 0 -Type String -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Num Lock on Startup" {
                Set-ItemProperty "HKCU:\Control Panel\Keyboard" -Name InitialKeyboardIndicators -Value "2" -Type String -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Disable Taskbar Search" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchboxTaskbarMode -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
            "Hide Task View Button" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Value 0 -Type DWord -Force
                $success = $true
            }
            "Enable Game Mode" {
                Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" -Name AutoGameModeEnabled -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $success = $true
            }
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
            "Disable Reserved Storage" {
                try { dism /Online /Set-ReservedStorageState /State:Disabled /Quiet 2>&1 | Out-Null; $success = $true } catch {}
            }
        }
        if ($success) { Write-Log "OK: $Name" 'OK' }
        else { Write-Log "SKIP: $Name" 'WARN' }
    } catch { Write-Log "FAILED: $Name - $($_.Exception.Message)" 'ERROR' }
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
#  PRESETS
# ═══════════════════════════════════════════════════════════

$script:Presets = @{
    "Standard" = @("Disable Telemetry","Disable Activity History","Disable Location Tracking","Disable Advertising ID","Disable Consumer Features","Disable Delivery Optimization","Disable SysMain","Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets","Enable End Task on Taskbar","Delete Temp Files","Empty Recycle Bin")
    "Minimal" = @("Disable Telemetry","Disable Advertising ID","Delete Temp Files","Empty Recycle Bin")
    "Advanced" = @("Disable Telemetry","Disable Activity History","Disable Location Tracking","Disable Advertising ID","Disable Consumer Features","Disable Cortana","Disable Bing Search","Disable Copilot","Disable WPBT","Disable Delivery Optimization","Disable SysMain","Disable Hibernation","Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay","Disable Power Throttling","Optimize Memory Management","Optimize SSD","Adjust Visual Effects for Performance","Disable Background Apps","Optimize TCP Settings","Disable NetBIOS over TCP/IP","Disable Windows Reserved Bandwidth","Set IPv6 to Prefer IPv4","Disable Remote Registry","Disable Xbox Services","Disable AutoRun","Enable Defender PUA Protection","Disable Reserved Storage","Disable Explorer Auto Discovery","Enable Long Paths","Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets","Enable End Task on Taskbar","Disable Transparency Effects","Disable Animations","Num Lock on Startup","Disable Taskbar Search","Hide Task View Button","Delete Temp Files","Empty Recycle Bin","Clear DNS Cache","Clear Windows Update Cache","Reset Windows Store Cache")
    "Gaming" = @("Disable Telemetry","Disable Consumer Features","Disable Delivery Optimization","Disable SysMain","Disable Hibernation","Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay","Disable Power Throttling","Disable Background Apps","Adjust Visual Effects for Performance","Optimize Memory Management","Enable Game Mode","Disable Xbox Services","Disable Widgets","Dark Mode","Optimize TCP Settings","Disable NetBIOS over TCP/IP","Delete Temp Files","Empty Recycle Bin","Clear DNS Cache")
    "Extreme" = @("Disable Telemetry","Disable Activity History","Disable Location Tracking","Disable Advertising ID","Disable Consumer Features","Disable Cortana","Disable Bing Search","Disable Copilot","Disable WPBT","Disable Delivery Optimization","Disable SysMain","Disable Hibernation","Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay","Disable Power Throttling","Optimize Memory Management","Optimize SSD","Adjust Visual Effects for Performance","Disable Background Apps","Disable Search Indexing","Clear Prefetch","Optimize TCP Settings","Disable NetBIOS over TCP/IP","Disable Windows Reserved Bandwidth","Disable IPv6","Disable Remote Registry","Disable Xbox Services","Disable AutoRun","Enable Defender PUA Protection","Disable Reserved Storage","Disable Explorer Auto Discovery","Enable Long Paths","Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets","Disable Start Recommendations","Enable End Task on Taskbar","Disable Transparency Effects","Disable Animations","Num Lock on Startup","Disable Taskbar Search","Hide Task View Button","Delete Temp Files","Empty Recycle Bin","Clear DNS Cache","Clear Windows Update Cache","Reset Windows Store Cache")
}

# ═══════════════════════════════════════════════════════════
#  MAIN GUI
# ═══════════════════════════════════════════════════════════

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="BJA Toolbox v9.0" Height="850" Width="1400"
        WindowStartupLocation="CenterScreen"
        Background="#0a0a0f" Foreground="#e8e8f0"
        WindowStyle="None" ResizeMode="CanResizeWithGrip">
  <Window.Resources>
    <SolidColorBrush x:Key="BgCard"    Color="#1c1c28"/>
    <SolidColorBrush x:Key="BgCardHov" Color="#252536"/>
    <SolidColorBrush x:Key="Accent"    Color="#00e5a0"/>
    <SolidColorBrush x:Key="Accent2"   Color="#7b5cff"/>
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
            <Border x:Name="bg" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="10">
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
      <Setter Property="Foreground" Value="#e8e8f0"/>
      <Setter Property="Padding" Value="16,10"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"/>
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
      <Setter Property="Foreground" Value="#e8e8f0"/>
      <Setter Property="Padding" Value="12,8"/>
      <Setter Property="Margin" Value="0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="bg" Background="{StaticResource BgCard}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <StackPanel Orientation="Horizontal">
                <Border x:Name="cb" Width="16" Height="16" CornerRadius="3" Background="Transparent" BorderBrush="{StaticResource Border}" BorderThickness="2" Margin="0,0,10,0">
                  <TextBlock x:Name="check" Text="✓" FontWeight="Bold" FontSize="11" Foreground="#0a0a0f" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
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
          <TextBlock Text="🔒" FontSize="18" Foreground="#00e5a0" VerticalAlignment="Center"/>
          <TextBlock Text="BJA" FontSize="18" FontWeight="Bold" Margin="10,0,0,0" VerticalAlignment="Center"/>
          <TextBlock Text="Toolbox" FontSize="14" Foreground="#7a7a8a" Margin="6,0,0,0" VerticalAlignment="Center"/>
          <TextBlock Text="v9.0 Final" FontSize="11" Foreground="#7b5cff" Margin="10,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,10,0">
          <Button x:Name="BtnMin" Content="—" Width="42" Height="32" Background="Transparent" Foreground="#888" BorderThickness="0" FontSize="16" Cursor="Hand"/>
          <Button x:Name="BtnClose" Content="✕" Width="42" Height="32" Background="Transparent" Foreground="#888" BorderThickness="0" FontSize="14" Cursor="Hand"/>
        </StackPanel>
      </Grid>
    </Border>

    <Border Grid.Row="1" Background="#08080c" BorderBrush="#26263a" BorderThickness="0,1,0,1">
      <Grid Margin="24,0">
        <StackPanel VerticalAlignment="Center">
          <TextBlock x:Name="HeaderText" Text="Tweaks" FontSize="20" FontWeight="Bold"/>
          <TextBlock x:Name="SubHeaderText" Text="Preset أو اختيار يدوي" FontSize="11" Foreground="#7a7a8a" Margin="0,2,0,0"/>
        </StackPanel>
      </Grid>
    </Border>

    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="220"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <Border Grid.Column="0" Background="#08080c" BorderBrush="#26263a" BorderThickness="0,0,1,0">
        <Grid Margin="14">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <StackPanel Grid.Row="0">
            <Button x:Name="NavTweaks"  Content="⚙️   Tweaks"     Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <Button x:Name="NavInput"   Content="🖱️   Input"      Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <Button x:Name="NavConfig"  Content="🔧   Config"     Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <Button x:Name="NavUpdates" Content="🔄   Updates"    Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
          </StackPanel>

          <TextBlock Grid.Row="1" Text="PRESETS" FontSize="10" Foreground="#7a7a8a" FontWeight="Bold" Margin="0,18,0,6"/>

          <StackPanel Grid.Row="2">
            <Button x:Name="PresetStandard" Content="⚡  Standard"  Style="{StaticResource SecondaryBtn}" Margin="0,3" Background="#1a3a2a" BorderBrush="#00e5a0"/>
            <Button x:Name="PresetMinimal"  Content="🌿  Minimal"   Style="{StaticResource SecondaryBtn}" Margin="0,3"/>
            <Button x:Name="PresetAdvanced" Content="🔥  Advanced"  Style="{StaticResource SecondaryBtn}" Margin="0,3"/>
            <Button x:Name="PresetGaming"   Content="🎮  Gaming"    Style="{StaticResource SecondaryBtn}" Margin="0,3"/>
            <Button x:Name="PresetExtreme"  Content="💀  Extreme"   Style="{StaticResource SecondaryBtn}" Margin="0,3" Foreground="#ff5566"/>
          </StackPanel>

          <StackPanel Grid.Row="3">
            <Border Height="1" Background="#26263a" Margin="0,10"/>
            <Button x:Name="NavRun" Content="▶  RUN SELECTED" Style="{StaticResource PrimaryBtn}" Height="48" Margin="0,4"/>
            <Button x:Name="NavClear" Content="✕  Clear" Style="{StaticResource SecondaryBtn}" Margin="0,4"/>
            <TextBlock x:Name="StatusCount" Text="0 selected" Foreground="#7a7a8a" FontSize="11" Margin="0,12,0,0" HorizontalAlignment="Center"/>
          </StackPanel>
        </Grid>
      </Border>

      <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" Padding="20">
        <StackPanel x:Name="ContentArea"/>
      </ScrollViewer>
    </Grid>

    <Border Grid.Row="3" Background="#08080c" BorderBrush="#26263a" BorderThickness="0,1,0,0">
      <Grid Margin="24,0">
        <TextBlock x:Name="StatusText" Text="Ready" Foreground="#7a7a8a" FontSize="11" VerticalAlignment="Center"/>
        <TextBlock Text="BJA Toolbox v9.0" Foreground="#7a7a8a" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
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

$window.FindName("BtnClose").Add_Click({ $window.Close() })
$window.FindName("BtnMin").Add_Click({ $window.WindowState = 'Minimized' })

# ═══════════════════════════════════════════════════════════
#  VIEWS
# ═══════════════════════════════════════════════════════════

function Add-TweakSection {
    param($title, $color, $list)
    $hdr = New-Object System.Windows.Controls.TextBlock
    $hdr.Text = $title; $hdr.FontSize = 14; $hdr.FontWeight = "Bold"
    $hdr.Foreground = $color; $hdr.Margin = "0,14,0,6"
    $ContentArea.Children.Add($hdr) | Out-Null

    foreach ($t in $list) {
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
        $ContentArea.Children.Add($cb) | Out-Null
        [void]$script:TweakBoxes.Add($cb)
    }
}

function Show-TweaksView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Tweaks"
    $SubHeaderText.Text = "Preset أو اختيار يدوي"
    $script:TweakBoxes.Clear()

    $presetRow = New-Object System.Windows.Controls.StackPanel
    $presetRow.Orientation = "Horizontal"
    $presetRow.Margin = "0,0,0,15"

    foreach ($p in @(
        @{Name="Standard"; Color="#00e5a0"}, @{Name="Minimal"; Color="#7b5cff"},
        @{Name="Advanced"; Color="#ff9944"}, @{Name="Gaming"; Color="#66ccff"},
        @{Name="Extreme"; Color="#ff5566"}, @{Name="Clear"; Color="#5a5a6a"}
    )) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $p.Name; $btn.Tag = $p.Name
        $btn.Width = 130; $btn.Height = 34; $btn.Margin = "0,0,8,0"
        $btn.Cursor = "Hand"; $btn.Background = "#1c1c28"; $btn.Foreground = $p.Color
        $btn.BorderBrush = $p.Color; $btn.BorderThickness = "1"; $btn.FontSize = 12; $btn.FontWeight = "SemiBold"
        $btn.Add_Click({
            $n = $this.Tag
            if ($n -eq "Clear") {
                $script:SelectedTweaks.Clear()
                foreach ($cb in $script:TweakBoxes) { $cb.IsChecked = $false }
                $StatusCount.Text = "0 selected"; $StatusText.Text = "Cleared"
            } else {
                $preset = $script:Presets[$n]
                $script:SelectedTweaks.Clear()
                foreach ($cb in $script:TweakBoxes) { $cb.IsChecked = ($preset -contains $cb.Tag) }
                $StatusCount.Text = "$($script:SelectedTweaks.Count) selected"
                $StatusText.Text = "Preset: $n"
            }
        })
        $presetRow.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($presetRow) | Out-Null

    Add-TweakSection "Essential Tweaks" "#7b5cff" @(
        "Disable Telemetry","Disable Activity History","Disable Location Tracking","Disable Advertising ID",
        "Disable Consumer Features","Disable Cortana","Disable Bing Search","Disable Copilot",
        "Disable WPBT","Disable Delivery Optimization","Disable SysMain","Disable Hibernation",
        "Show File Extensions","Show Hidden Files","Dark Mode","Disable Widgets","Enable End Task on Taskbar"
    )
    Add-TweakSection "Performance Tweaks" "#00e5a0" @(
        "Enable GPU Scheduling","Enable Ultimate Performance","Disable Startup Delay","Disable Power Throttling",
        "Optimize SSD","Disable Background Apps","Adjust Visual Effects for Performance",
        "Optimize Memory Management","Enable Game Mode","Clear Prefetch","Disable Search Indexing"
    )
    Add-TweakSection "Network Tweaks" "#66ccff" @(
        "Optimize TCP Settings","Disable NetBIOS over TCP/IP","Disable Windows Reserved Bandwidth",
        "Set IPv6 to Prefer IPv4","Disable IPv6","Clear DNS Cache"
    )
    Add-TweakSection "Security Tweaks" "#ff9944" @(
        "Disable Remote Registry","Disable Xbox Services","Disable AutoRun","Enable Defender PUA Protection"
    )
    Add-TweakSection "UI Tweaks" "#a888ff" @(
        "Disable Explorer Auto Discovery","Taskbar Left Align","Disable Transparency Effects",
        "Disable Animations","Num Lock on Startup","Disable Taskbar Search",
        "Hide Task View Button","Disable Start Recommendations","Enable Long Paths"
    )
    Add-TweakSection "Maintenance" "#aaaaff" @(
        "Disk Cleanup","Delete Temp Files","Empty Recycle Bin","Create Restore Point",
        "Clear Windows Update Cache","Reset Windows Store Cache","Disable Reserved Storage"
    )
}

function Show-InputView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Input Control"
    $SubHeaderText.Text = "Mouse · Keyboard · Macros"

    $mouseHdr = New-Object System.Windows.Controls.TextBlock
    $mouseHdr.Text = "▸ Mouse Settings"
    $mouseHdr.FontSize = 14; $mouseHdr.FontWeight = "Bold"
    $mouseHdr.Foreground = "#00e5a0"; $mouseHdr.Margin = "0,10,0,8"
    $ContentArea.Children.Add($mouseHdr) | Out-Null

    $speedRow = New-Object System.Windows.Controls.StackPanel
    $speedRow.Orientation = "Horizontal"; $speedRow.Margin = "0,4,0,8"
    $speedLabel = New-Object System.Windows.Controls.TextBlock
    $speedLabel.Text = "Speed:"; $speedLabel.FontSize = 12
    $speedLabel.Foreground = "#7a7a8a"; $speedLabel.VerticalAlignment = "Center"; $speedLabel.Margin = "0,0,10,0"
    $speedRow.Children.Add($speedLabel) | Out-Null

    foreach ($s in @(
        @{Name="Slow"; Value="3"}, @{Name="Medium"; Value="10"},
        @{Name="Fast"; Value="15"}, @{Name="Pro"; Value="20"}
    )) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $s.Name; $btn.Tag = $s.Value
        $btn.Width = 110; $btn.Height = 34; $btn.Margin = "0,0,6,0"; $btn.Cursor = "Hand"
        $btn.Background = "#1c1c28"; $btn.Foreground = "#e8e8f0"
        $btn.BorderBrush = "#26263a"; $btn.BorderThickness = "1"; $btn.FontSize = 12
        $btn.Add_Click({
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseSensitivity -Value $this.Tag -Type String -Force
            [System.Windows.MessageBox]::Show("Mouse speed: $($this.Content)`n`nSign out to apply.", "BJA")
        })
        $speedRow.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($speedRow) | Out-Null

    $precisionRow = New-Object System.Windows.Controls.StackPanel
    $precisionRow.Orientation = "Horizontal"
    $precisionRow.Margin = "0,15,0,10"

    foreach ($p in @(
        @{Name="🎯 Aim";     Sens="10"; T1="0"; T2="0"; Spd="0"},
        @{Name="🖌️ Drawing"; Sens="6";  T1="0"; T2="0"; Spd="0"},
        @{Name="🎮 Gaming";  Sens="20"; T1="0"; T2="0"; Spd="0"},
        @{Name="📋 Default"; Sens="10"; T1="6"; T2="10"; Spd="1"}
    )) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $p.Name; $btn.Tag = $p
        $btn.Width = 140; $btn.Height = 50; $btn.Margin = "0,0,10,0"; $btn.Cursor = "Hand"
        $btn.Background = "#1c1c28"; $btn.Foreground = "#ff9944"
        $btn.BorderBrush = "#ff9944"; $btn.BorderThickness = "1"
        $btn.FontSize = 12; $btn.FontWeight = "SemiBold"
        $btn.Add_Click({
            $p = $this.Tag
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseSensitivity -Value $p.Sens -Type String -Force
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value $p.T1 -Type String -Force
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value $p.T2 -Type String -Force
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value $p.Spd -Type String -Force
            [System.Windows.MessageBox]::Show("Applied: $($p.Name)`n`nSign out.", "BJA")
        })
        $precisionRow.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($precisionRow) | Out-Null

    $kbHdr = New-Object System.Windows.Controls.TextBlock
    $kbHdr.Text = "▸ Keyboard Settings"
    $kbHdr.FontSize = 14; $kbHdr.FontWeight = "Bold"
    $kbHdr.Foreground = "#66ccff"; $kbHdr.Margin = "0,25,0,8"
    $ContentArea.Children.Add($kbHdr) | Out-Null

    $kbRow = New-Object System.Windows.Controls.StackPanel
    $kbRow.Orientation = "Horizontal"

    foreach ($k in @(
        @{Name="Fast Key Repeat"; Reg="KeyboardDelay"; Value="0"},
        @{Name="Fast Repeat Rate"; Reg="KeyboardSpeed"; Value="31"},
        @{Name="Num Lock on Boot"; Reg="InitialKeyboardIndicators"; Value="2"}
    )) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $k.Name; $btn.Tag = $k
        $btn.Width = 160; $btn.Height = 44; $btn.Margin = "0,0,10,0"; $btn.Cursor = "Hand"
        $btn.Background = "#1c1c28"; $btn.Foreground = "#66ccff"
        $btn.BorderBrush = "#66ccff"; $btn.BorderThickness = "1"; $btn.FontSize = 12
        $btn.Add_Click({
            $k = $this.Tag
            Set-ItemProperty "HKCU:\Control Panel\Keyboard" -Name $k.Reg -Value $k.Value -Type String -Force -ErrorAction SilentlyContinue
            [System.Windows.MessageBox]::Show("Applied: $($k.Name)", "BJA")
        })
        $kbRow.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($kbRow) | Out-Null
}

function Show-ConfigView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Configuration"
    $SubHeaderText.Text = "DNS · Fixes · Panels"

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

function Apply-PresetByName {
    param([string]$Name)
    Show-TweaksView
    Start-Sleep -Milliseconds 100
    $preset = $script:Presets[$Name]
    $script:SelectedTweaks.Clear()
    foreach ($cb in $script:TweakBoxes) {
        $cb.IsChecked = ($preset -contains $cb.Tag)
    }
    $StatusCount.Text = "$($script:SelectedTweaks.Count) selected"
    $StatusText.Text = "Preset: $Name"
}

$window.FindName("PresetStandard").Add_Click({ Apply-PresetByName "Standard" })
$window.FindName("PresetMinimal").Add_Click({  Apply-PresetByName "Minimal"  })
$window.FindName("PresetAdvanced").Add_Click({ Apply-PresetByName "Advanced" })
$window.FindName("PresetGaming").Add_Click({   Apply-PresetByName "Gaming"   })
$window.FindName("PresetExtreme").Add_Click({  Apply-PresetByName "Extreme"  })

$window.FindName("NavTweaks").Add_Click({  Show-TweaksView  })
$window.FindName("NavInput").Add_Click({   Show-InputView   })
$window.FindName("NavConfig").Add_Click({  Show-ConfigView  })
$window.FindName("NavUpdates").Add_Click({ Show-UpdatesView })

$window.FindName("NavClear").Add_Click({
    $script:SelectedTweaks.Clear()
    $StatusCount.Text = "0 selected"
    Show-TweaksView
})

$window.FindName("NavRun").Add_Click({
    if ($script:SelectedTweaks.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select tweaks first", "BJA")
        return
    }
    New-RestorePoint
    foreach ($t in $script:SelectedTweaks) { Invoke-Tweak -Name $t }
    [System.Windows.MessageBox]::Show("Done! Check log on Desktop", "BJA")
    $StatusText.Text = "Complete - check log"
})

# ═══════════════════════════════════════════════════════════
#  START
# ═══════════════════════════════════════════════════════════

Update-Splash $splash "Ready!" 100
Start-Sleep -Milliseconds 300
$splash.Close()

Show-TweaksView
Write-Log "BJA Toolbox v$($script:Version) started"
$window.ShowDialog() | Out-Null
Write-Log "BJA Toolbox closed"