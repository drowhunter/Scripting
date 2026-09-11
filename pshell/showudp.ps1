param (
    [Parameter(Mandatory=$true)]
    [UInt16]$LOCALPORT
)
$CONNECTIONS = Get-NetUDPEndpoint |Select-Object -Property LocalPort, @{name='ProcessID';expression={(Get-Process -Id $_.OwningProcess). ID}}, @{name='ProcessName';expression={(Get-Process -Id $_.OwningProcess). Path}}
Foreach ($I in $CONNECTIONS)
{
    If ($I.LocalPort -eq $LOCALPORT)
    {
        $I
    }
}