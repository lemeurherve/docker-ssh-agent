[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/{0}/OpenSSH-Win64.zip' -f $env:OPENSSH_VERSION
Write-Host "Retrieving $url..."
Invoke-WebRequest -Uri $url -OutFile C:/openssh.zip -UseBasicParsing
Expand-Archive c:/openssh.zip 'C:/Program Files'
Remove-Item C:/openssh.zip
$env:PATH = '{0};{1}' -f $env:PATH,'C:\Program Files\OpenSSH-Win64'

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Current User: $CurrentUser"
$CurrentGroup = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Translate([System.Security.Principal.NTAccount]).Value
Write-Host "Current Group: $CurrentGroup"



if(!(Test-Path 'C:\ProgramData\ssh')) { New-Item -Type Directory -Path 'C:\ProgramData\ssh' | Out-Null }

(Get-Acl 'C:\ProgramData\ssh').Access | Format-Table -AutoSize
$before = (Get-Acl 'C:\ProgramData\ssh').Access
Write-Host "===== before: $before"


# Define the path to the folder
$FolderPath = 'C:\ProgramData\ssh'

# Get the current ACL of the folder
$FolderAcl = Get-Acl -Path $FolderPath

# Define the identity of the ACL entry you want to remove (e.g., user or group)
$IdentityToRemove = 'CREATOR OWNER'

# Find and remove the specific ACL entry from the ACL
$UpdatedAcl = $FolderAcl | Where-Object { $_.IdentityReference -ne $IdentityToRemove }

# Set the modified ACL back to the folder
Set-Acl -Path $FolderPath -AclObject $UpdatedAcl


(Get-Acl 'C:\ProgramData\ssh').Access | Format-Table -AutoSize
$after = (Get-Acl 'C:\ProgramData\ssh').Access
Write-Host "===== after: $after"


& 'C:/Program Files/OpenSSH-Win64/Install-SSHd.ps1'



Copy-Item 'C:\Program Files\OpenSSH-Win64\sshd_config_default' 'C:\ProgramData\ssh\sshd_config'
$content = Get-Content -Path "C:\ProgramData\ssh\sshd_config"
$content | ForEach-Object { $_ -replace '#PermitRootLogin.*','PermitRootLogin no'
                    -replace '#PasswordAuthentication.*','PasswordAuthentication no'
                    -replace '#PermitEmptyPasswords.*','PermitEmptyPasswords no'
                    -replace '#PubkeyAuthentication.*','PubkeyAuthentication yes'
                    -replace '#SyslogFacility.*','SyslogFacility LOCAL0'
                    -replace '#LogLevel.*','LogLevel INFO'
                    -replace 'Match Group administrators',''
                    -replace '(\s*)AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys',''
            } |
Set-Content -Path "C:\ProgramData\ssh\sshd_config"
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'ChallengeResponseAuthentication no'
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'HostKeyAgent \\.\pipe\openssh-ssh-agent'
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value ('Match User {0}' -f $env:JENKINS_AGENT_USER)
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value ('       AuthorizedKeysFile C:/Users/{0}/.ssh/authorized_keys' -f $env:JENKINS_AGENT_USER)
New-Item -Path HKLM:\SOFTWARE -Name OpenSSH -Force | Out-Null
New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value 'C:\Program Files\Powershell\pwsh.exe' -PropertyType string -Force | Out-Null