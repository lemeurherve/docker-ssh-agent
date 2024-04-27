[CmdletBinding()]
Param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string] $Cmd
)

Write-Host '=== dump network information'
ipconfig
netstat -a

Write-Host '=== call OpenSSH-Win64 install-sshd.ps1'
& 'C:/Program Files/OpenSSH-Win64/install-sshd.ps1'

Write-Host '=== call setup-sshd.ps1'
& C:/ProgramData/Jenkins/setup-sshd.ps1 $Cmd
