# https://david-homer.blogspot.com/2022/10/powershell-get-acl-displays-unknown.html
# Corrects the NTFS file system rights standardizing GENERIC_* permissions.
Function Get-FileSystemRights
{

    [CmdletBinding()]
    param(
        [Parameter()]
        [int] $RightsValue
    )

    $GENERIC_ALL = [int]268435456;
    $GENERIC_READ = [int]-2147483648;
    $GENERIC_WRITE = [int]1073741824;
    $GENERIC_EXECUTE =[int]536870912;

    if (($RightsValue -band $GENERIC_ALL) -eq $GENERIC_ALL) { return [System.Security.AccessControl.FileSystemRights]::FullControl; }

    if (($RightsValue -band $GENERIC_READ) -eq $GENERIC_READ)
    {

        $RightsValue = $RightsValue -= $GENERIC_READ;

        $RightsValue = $RightsValue += [int][System.Security.AccessControl.FileSystemRights]::Read;

        $RightsValue = $RightsValue += [int][System.Security.AccessControl.FileSystemRights]::Synchronize;

    }

    if (($RightsValue -band $GENERIC_WRITE) -eq $GENERIC_WRITE)
    {
        $RightsValue = $RightsValue -= $GENERIC_WRITE;
        $RightsValue = $RightsValue += [int][System.Security.AccessControl.FileSystemRights]::Write;
        $RightsValue = $RightsValue += [int][System.Security.AccessControl.FileSystemRights]::Synchronize;
    }

    if (($RightsValue -band $GENERIC_EXECUTE) -eq $GENERIC_EXECUTE)
    {
        $RightsValue = $RightsValue -= $GENERIC_EXECUTE;
        $RightsValue = $RightsValue += [int][System.Security.AccessControl.FileSystemRights]::Traverse;
        $RightsValue = $RightsValue += [int][System.Security.AccessControl.FileSystemRights]::Synchronize;
    }

    return [System.Security.AccessControl.FileSystemRights] $RightsValue;

} 

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

# (Get-Acl 'C:\ProgramData\ssh').Access | Format-Table -AutoSize
# $before = (Get-Acl 'C:\ProgramData\ssh').Access
# Write-Host "===== before: $before"


# # Define the path to the folder
# $FolderPath = 'C:\ProgramData\ssh'

# # Define the identity of the ACL entry you want to remove (e.g., user or group)
# $IdentityToRemove = 'CREATOR OWNER'
# $AccessRightsToRemove = "Write"  # Specify the access rights to remove

# # # Get the current ACL of the folder
# # $FolderAcl = Get-Acl -Path $FolderPath

# # # Find and remove the specific access rule from the ACL
# # $AccessRuleToRemove = $FolderAcl.Access | Where-Object { $_.FileSystemRights -eq $AccessRightsToRemove }

# # if ($AccessRuleToRemove -ne $null) {
# #     $FolderAcl.RemoveAccessRule($AccessRuleToRemove)
    
# #     # Apply the modified ACL back to the folder
# #     Set-Acl -Path $FolderPath -AclObject $FolderAcl
# #     Write-Host "Access rule removed successfully."
# # } else {
# #     Write-Host "Access rule not found."
# # }

# $acl = (Get-Acl $FolderPath).Access;
# foreach ($ace in $acl)
# {
#     Write-Host $ace.IdentityReference $ace.FileSystemRights (Get-FileSystemRights -RightsValue $ace.FileSystemRights);

# }


# # # Find and remove the specific ACL entry from the ACL
# # $UpdatedAcl = $FolderAcl | Where-Object { $_.IdentityReference -ne $IdentityToRemove }

# # # Set the modified ACL back to the folder
# # Set-Acl -Path $FolderPath -AclObject $UpdatedAcl

& icacls 'C:\ProgramData\ssh' /remove "CREATOR OWNER" /T /C



Write-Host "===== after:"
(Get-Acl 'C:\ProgramData\ssh').Access | Format-Table -AutoSize

icacls 'C:\ProgramData\ssh' /inheritance:d;
icacls 'C:\ProgramData\ssh' /remove "CREATOR OWNER";

Write-Host "===== after2:"
(Get-Acl 'C:\ProgramData\ssh').Access | Format-Table -AutoSize


& 'C:/Program Files/OpenSSH-Win64/Install-SSHd.ps1'



Copy-Item 'C:\Program Files\OpenSSH-Win64\sshd_config_default' 'C:\ProgramData\ssh\sshd_config'
$content = Get-Content -Path "C:\ProgramData\ssh\sshd_config"
$content | ForEach-Object { $_ -replace '#PermitRootLogin.*','PermitRootLogin no' `
                    -replace '#PasswordAuthentication.*','PasswordAuthentication no' `
                    -replace '#PermitEmptyPasswords.*','PermitEmptyPasswords no' `
                    -replace '#PubkeyAuthentication.*','PubkeyAuthentication yes' `
                    -replace '#SyslogFacility.*','SyslogFacility LOCAL0' `
                    -replace '#LogLevel.*','LogLevel INFO' `
                    -replace 'Match Group administrators','' `
                    -replace '(\s*)AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys',''
            } |
Set-Content -Path "C:\ProgramData\ssh\sshd_config"
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'ChallengeResponseAuthentication no'
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value 'HostKeyAgent \\.\pipe\openssh-ssh-agent'
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value ('Match User {0}' -f $env:JENKINS_AGENT_USER)
Add-Content -Path "C:\ProgramData\ssh\sshd_config" -Value ('       AuthorizedKeysFile C:/Users/{0}/.ssh/authorized_keys' -f $env:JENKINS_AGENT_USER)
New-Item -Path HKLM:\SOFTWARE -Name OpenSSH -Force | Out-Null
New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value 'C:\Program Files\Powershell\pwsh.exe' -PropertyType string -Force | Out-Null