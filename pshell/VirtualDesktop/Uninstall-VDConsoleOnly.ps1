#Requires -RunAsAdministrator
# Reverts Install-VDConsoleOnly.ps1: removes the task and guard script, restores automatic service startup.

Unregister-ScheduledTask -TaskName 'VD Console Only' -Confirm:$false -ErrorAction SilentlyContinue
Set-Service -Name 'VirtualDesktop.Service.exe' -StartupType Automatic
Start-Service -Name 'VirtualDesktop.Service.exe' -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:ProgramData 'VDConsoleOnly') -Recurse -Force -ErrorAction SilentlyContinue
"Uninstalled. Service startup: $((Get-Service 'VirtualDesktop.Service.exe').StartType)"
