#Requires -RunAsAdministrator
# Runs Virtual Desktop's service only while someone is at the physical console.
# During an active RDP session the service is stopped and any Streamer in the RDP session is closed,
# so VirtualDesktop.Setup.exe never gets launched there and never raises a UAC prompt.
#
# Undo:  Unregister-ScheduledTask -TaskName 'VD Console Only' -Confirm:$false
#        Set-Service 'VirtualDesktop.Service.exe' -StartupType Automatic
#        Remove-Item "$env:ProgramData\VDConsoleOnly" -Recurse

$ErrorActionPreference = 'Stop'
$svcName = 'VirtualDesktop.Service.exe'
$dir = Join-Path $env:ProgramData 'VDConsoleOnly'
$guard = Join-Path $dir 'guard.ps1'

New-Item -ItemType Directory -Force -Path $dir | Out-Null

@"
`$svc = '$svcName'
`$sessions = qwinsta 2>`$null
`$rdp = `$sessions | Where-Object { `$_ -match 'rdp-tcp#\d+\s+\S+\s+(\d+)\s+Active' }
`$console = `$sessions | Where-Object { `$_ -match 'console\s+\S+\s+\d+\s+Active' }

if (`$rdp) {
    Stop-Service `$svc -Force -ErrorAction SilentlyContinue
    foreach (`$line in `$rdp) {
        if (`$line -match 'rdp-tcp#\d+\s+\S+\s+(\d+)\s+Active') {
            `$id = [int]`$Matches[1]
            Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Setup' -ErrorAction SilentlyContinue |
                Where-Object SessionId -eq `$id | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }
}
elseif (`$console) {
    Start-Service `$svc -ErrorAction SilentlyContinue
}
"@ | Set-Content -Path $guard -Encoding UTF8

# Manual so it no longer starts at boot; the task starts it on console logon/connect.
Set-Service -Name $svcName -StartupType Manual

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Runs Virtual Desktop only for console sessions, never during RDP.</Description></RegistrationInfo>
  <Triggers>
    <BootTrigger />
    <LogonTrigger />
    <SessionStateChangeTrigger><StateChange>ConsoleConnect</StateChange></SessionStateChangeTrigger>
    <SessionStateChangeTrigger><StateChange>RemoteConnect</StateChange></SessionStateChangeTrigger>
    <SessionStateChangeTrigger><StateChange>SessionUnlock</StateChange></SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author"><UserId>S-1-5-18</UserId><RunLevel>HighestAvailable</RunLevel></Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT2M</ExecutionTimeLimit>
    <Priority>4</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "$guard"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Register-ScheduledTask -TaskName 'VD Console Only' -Xml $xml -Force | Out-Null
Start-ScheduledTask -TaskName 'VD Console Only'
"Installed. Service startup: $((Get-Service $svcName).StartType); status: $((Get-Service $svcName).Status)"
