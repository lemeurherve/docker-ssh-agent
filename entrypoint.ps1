[CmdletBinding()]
Param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string] $Cmd
)

& 'C:/Program Files/OpenSSH-Win64/install-sshd.ps1'
& C:/ProgramData/Jenkins/setup-sshd.ps1 $Cmd
