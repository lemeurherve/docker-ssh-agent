Import-Module -DisableNameChecking -Force $PSScriptRoot/test_helpers.psm1

$global:AGENT_IMAGE = Get-EnvOrDefault 'AGENT_IMAGE' ''
$global:BUILD_CONTEXT = Get-EnvOrDefault 'BUILD_CONTEXT' ''
$global:QUIET_TESTS = Get-EnvOrDefault 'QUIET_TESTS' $false

$items = $global:AGENT_IMAGE.Split("-")

# Remove the 'jdk' prefix
$global:JDKMAJORVERSION = $items[2].Remove(0,3)
$global:WINDOWSFLAVOR = $items[0]
$global:WINDOWSVERSION = $items[1]

# TODO: make this name unique for concurency
$global:CONTAINERNAME = 'pester-jenkins-ssh-agent-{0}' -f $global:AGENT_IMAGE

$global:CONTAINERSHELL="powershell.exe"
if($global:WINDOWSFLAVOR -eq 'nanoserver') {
    $global:CONTAINERSHELL = "pwsh.exe"
}

$PUBLIC_SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAvnRN27LdPPQq2OH3GiFFGWX/SH5TCPVePLR21ngMFV8nAthXgYrFkRi/t+Wafe3ByTu2XYUDlXHKGIPIoAKo4gz5dIjUFfoac1ZuCDIbEiqPEjkk4tkfc2qr/BnIZsOYQi4Mbu+Z40VZEsAQU7eBinnZaHE1qGMHjS1xfrRtp2rdeO1EBz92FJ8dfnkUnohTXo3qPVSFGIPbh7UKEoKcyCosRO1P41iWD1rVsH1SLLXYAh2t49L7IPiplg09Dep6H47LyQVbxU9eXY8yMtUrRuwEk9IUX/IqpxNhk5hngHPP3JjsP0hyyrYSPkZlbs3izd9kk3y09Wn/ElHidiEk0Q=="
$PRIVATE_SSH_KEY=@"
-----BEGIN RSA PRIVATE KEY-----
MIIEoQIBAAKCAQEAvnRN27LdPPQq2OH3GiFFGWX/SH5TCPVePLR21ngMFV8nAthX
gYrFkRi/t+Wafe3ByTu2XYUDlXHKGIPIoAKo4gz5dIjUFfoac1ZuCDIbEiqPEjkk
4tkfc2qr/BnIZsOYQi4Mbu+Z40VZEsAQU7eBinnZaHE1qGMHjS1xfrRtp2rdeO1E
Bz92FJ8dfnkUnohTXo3qPVSFGIPbh7UKEoKcyCosRO1P41iWD1rVsH1SLLXYAh2t
49L7IPiplg09Dep6H47LyQVbxU9eXY8yMtUrRuwEk9IUX/IqpxNhk5hngHPP3Jjs
P0hyyrYSPkZlbs3izd9kk3y09Wn/ElHidiEk0QIBJQKCAQEAlUZmiZoHWUnAt9Oz
1jXAiYdLi9ih8kPGZu5PTia9XNvgTlaJxmXZHrKIbYpyK1l8NfCIBBwlZ0tZNc8S
3kdGGPVpkrBu4MryIwxkFELyn4kkB104lh/MiuTnqeqx1AEWeQ9V2mjEuQzXHIiy
2dUEqs40x3tTkdETwa3/AnG9upCsS8DpUmBa50hHvkc8pfmDrCbDAB7QjrgxAv7N
TjZQz1BslDnqULBs0weqD/YG60Vxdbu8ULHcMKYHmlk06a2lxF2A+CbvC+eLyD5B
+YHsD2CnpNhmBxLXfjnKuMhT6ybtop1hZW4zy0jLsyvAgM/kSb/iH9XJ17nfdlMm
NChQcQKBgQDvKs+81jDhoP+fZXi7bnVwlo2UzuTXNkUO1fLCFHWpJXMXu4wY6iMY
klEjXmN68Ijj0n3Enw7yM4/HBcnvRlw78zbDbKxwz5WRVc8w4/Ct4z8TX9Il1srR
Qa9vPhju8KazY1XxNMidMJmcR6cjG7glzKorE9faHc9aIskPP93y1wKBgQDL288f
tk0F/RcikCnfq8Ligm3GkZfP7lyf0T9lXHg0Qe9d3esvVHe02blMGm0vgsKy4Aip
jlyyM8ExI5yF2zUbOqLxDhWWqL6EnlYXEI4s5h/4AJOPrERGdOU/Ix7G312mqcmi
FlRVug8II64O7IgVU6pWyckOSMf6llyH/ItYlwKBgDotAhktLnwSZ7EmhSasKmd+
kSQyU1bxhmtkeVHNoBRjDiheDVIrHUsqgnBjEUdq8N14Y8gLA6KymJgx1yxdOQep
3ONtdg2aRvnWmi58olPPfguhr6hW12NVKqxbNn9PSyS3TEGXN7eIXLdPswiKM7Yq
3Ui/ozUOK4SgrXJpey07AoGAG4xoGQrMI2dj/cB0XH7+qPzeZvEUg+Hw11OgyIIe
FOZQx37al7F39dg7ooAcl7e5ch5GXBooM8HN/7i0SXCmT8mnUQHnPd9zsQ56ViTU
8U+Hx5FgDH8QJTJkKyBr8Vx0cHfPI73UC5WvARmUD9rGSBI5nQaC9BesUkuro6yB
iIMCgYAnlf3vd9/s8izGoHH1K2MJgGQT06Wn4ESjKpqqayqiXHccHGgeXeAiONa1
uiWcmBF4XtMTVXUGcS6DCm/jf/4JDI8B1eJCVQKLbZXZbENWnptDtj098NTt9NdV
TUwLP4n7pK4J2sCIs6fRD5kEYms4BnddXeRuI2fGZHGH70Ci/Q==
-----END RSA PRIVATE KEY-----
"@

Cleanup($global:CONTAINERNAME)

# TODO: uncomment (fixed)
# Describe "[$global:AGENT_IMAGE] image is present" {
#     It 'builds image' {
#         $exitCode, $stdout, $stderr = Run-Program 'docker' "build --tag=${global:AGENT_IMAGE} --file ./windows/${global:WINDOWSFLAVOR}/Dockerfile ${global:BUILD_CONTEXT}"
#         $exitCode | Should -Be 0
#     }
# }

# TODO: uncomment (fixed)
# Describe "[$global:AGENT_IMAGE] image has setup-sshd.ps1 in the correct location" {
#     BeforeAll {
#         docker run --detach --interactive --tty --name "$global:CONTAINERNAME" --publish-all  "$global:AGENT_IMAGE" "$global:CONTAINERSHELL"
#         Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
#     }

#     It 'has setup-sshd.ps1 in C:/ProgramData/Jenkins' {
#         $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"if(Test-Path C:/ProgramData/Jenkins/setup-sshd.ps1) { exit 0 } else { exit 1}`"" $global:TESTS_DEBUG
#         $exitCode | Should -Be 0
#     }

#     AfterAll {
#         Cleanup($global:CONTAINERNAME)
#     }
# }

# TODO: uncomment (fixed)
# Describe "[$global:AGENT_IMAGE] checking image metadata" {
#     It 'has correct volumes' {
#         $exitCode, $stdout, $stderr = Run-Program 'docker' "inspect --format '{{.Config.Volumes}}' $global:AGENT_IMAGE" $global:TESTS_DEBUG
#         $exitCode | Should -Be 0

#         $stdout | Should -Match 'C:/Users/jenkins/AppData/Local/Temp'
#         $stdout | Should -Match 'C:/Users/jenkins/Work'
#     }

#     It 'has the source GitHub URL in docker metadata' {
#         $exitCode, $stdout, $stderr = Run-Program 'docker' "inspect --format=`"{{index .Config.Labels \`"org.opencontainers.image.source\`"}}`" $global:AGENT_IMAGE" $global:TESTS_DEBUG
#         $exitCode | Should -Be 0
#         $stdout.Trim() | Should -Match 'https://github.com/jenkinsci/docker-ssh-agent'
#     }
# }

# TODO: uncomment (fixed)
# Describe "[$global:AGENT_IMAGE] image has correct version of java installed and in the PATH" {
#     BeforeAll {
#         docker run --detach --tty --name="$global:CONTAINERNAME" --publish-all "$global:AGENT_IMAGE" $global:CONTAINERSHELL
#         Is-ContainerRunning $global:CONTAINERNAME
#     }

#     It 'has java installed and in the path' {
#         $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"if(`$null -eq (Get-Command java.exe -ErrorAction SilentlyContinue)) { exit -1 } else { exit 0 }`"" $global:TESTS_DEBUG
#         $exitCode | Should -Be 0

#         $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"`$version = java -version 2>&1 ; Write-Host `$version`"" $global:TESTS_DEBUG
#         $r = [regex] "^openjdk version `"(?<major>\d+)"
#         $m = $r.Match($stdout)
#         $m | Should -Not -Be $null
#         $m.Groups['major'].ToString() | Should -Be "$global:JDKMAJORVERSION"
#     }

#     AfterAll {
#         Cleanup($global:CONTAINERNAME)
#     }
# }

# TODO: fix
# Describe "[$global:AGENT_IMAGE] create agent container with pubkey as argument" {
#     BeforeAll {
#         docker run --detach --tty --interactive --name="$global:CONTAINERNAME" --publish-all "$global:AGENT_IMAGE" "$PUBLIC_SSH_KEY"
#         Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
#     }

#     It 'runs commands via ssh' {
#         $exitCode, $stdout, $stderr = Run-ThruSSH $global:CONTAINERNAME "$PRIVATE_SSH_KEY" "$global:CONTAINERSHELL -NoLogo -C `"Write-Host 'f00'`""
#         $exitCode | Should -Be 0
#         $stdout | Should -Match "f00"
#     }

#     AfterAll {
#         Cleanup($global:CONTAINERNAME)
#     }
# }

Write-Host "=== global:AGENT_IMAGE: $global:AGENT_IMAGE, global:CONTAINERNAME: $global:CONTAINERNAME, PUBLIC_SSH_KEY: $PUBLIC_SSH_KEY, PRIVATE_SSH_KEY: $PRIVATE_SSH_KEY"
# # Adapted from before the JDK factorization
Describe "[$global:AGENT_IMAGE] create agent container with pubkey as argument" {
    BeforeAll {
        $exitCode, $stdout, $stderr = Run-Program 'docker.exe' "run -dit --name $global:CONTAINERNAME -P $global:AGENT_IMAGE $PUBLIC_SSH_KEY"
        Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
    }

    It 'runs commands via ssh' {
        $exitCode, $stdout, $stderr = Run-ThruSSH $global:CONTAINERNAME "$PRIVATE_SSH_KEY" "$global:CONTAINERSHELL -NoLogo -C `"Write-Host 'f00'`""
        $exitCode | Should -Be 0
        $stdout | Should -Match "f00"
    }

    AfterAll {
        Cleanup($global:CONTAINERNAME)
    }
}

# Original from before the JDK factorization
# Describe "[$JDK $FLAVOR] create agent container with pubkey as argument" {
#     BeforeAll {
#         $exitCode, $stdout, $stderr = Run-Program 'docker.exe' "run -dit --name $AGENT_CONTAINER -P $AGENT_IMAGE $PUBLIC_SSH_KEY"
#         Is-ContainerRunning $AGENT_CONTAINER | Should -BeTrue
#     }

#     It 'runs commands via ssh' {
#         $exitCode, $stdout, $stderr = Run-ThruSSH $AGENT_CONTAINER "$PRIVATE_SSH_KEY" "$SHELL -NoLogo -C `"Write-Host 'f00'`""
#         $exitCode | Should -Be 0
#         $stdout | Should -Match "f00"
#     }

#     AfterAll {
#         Cleanup($AGENT_CONTAINER)
#     }
# }

# TODO: fix
# Describe "[$global:AGENT_IMAGE] create agent container with pubkey as envvar" {
#     BeforeAll {
#         docker run --detach --tty --name="$global:CONTAINERNAME" --publish-all --env="JENKINS_AGENT_SSH_PUBKEY=$PUBLIC_SSH_KEY" "$global:AGENT_IMAGE"
#         Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
#     }

#     It 'runs commands via ssh' {
#         $exitCode, $stdout, $stderr = Run-ThruSSH $global:CONTAINERNAME "$PRIVATE_SSH_KEY" "$global:CONTAINERSHELL -NoLogo -C `"Write-Host 'f00'`""
#         $exitCode | Should -Be 0
#         $stdout | Should -Match "f00"
#     }

#     AfterAll {
#         Cleanup($global:CONTAINERNAME)
#     }
# }

# TODO: fix
# $DOCKER_PLUGIN_DEFAULT_ARG="/usr/sbin/sshd -D -p 22"
# Describe "[$global:AGENT_IMAGE] create agent container like docker-plugin with '$DOCKER_PLUGIN_DEFAULT_ARG' as argument" {
#     BeforeAll {
#         [string]::IsNullOrWhiteSpace($DOCKER_PLUGIN_DEFAULT_ARG) | Should -BeFalse
#         docker run --detach --tty --name="$global:CONTAINERNAME" --publish-all --env="JENKINS_AGENT_SSH_PUBKEY=$PUBLIC_SSH_KEY" "$global:AGENT_IMAGE" "$DOCKER_PLUGIN_DEFAULT_ARG"
#         Is-ContainerRunning $global:CONTAINERNAME | Should -BeTrue
#     }

#     It 'runs commands via ssh' {
#         $exitCode, $stdout, $stderr = Run-ThruSSH $global:CONTAINERNAME "$PRIVATE_SSH_KEY" "$global:CONTAINERSHELL -NoLogo -C `"Write-Host 'f00'`""
#         $exitCode | Should -Be 0
#         $stdout | Should -Match "f00"
#     }

#     AfterAll {
#         Cleanup($global:CONTAINERNAME)
#     }
# }

# TODO: uncomment (fixed)
# Describe "[$global:AGENT_IMAGE] build args" {
#     BeforeAll {
#         Push-Location -StackName 'agent' -Path "$PSScriptRoot/.."
#     }

#     It 'uses build args correctly' {
#         $TEST_USER="testuser"
#         $TEST_JAW="C:/hamster"
#         $CUSTOM_IMAGE_NAME = "custom-${AGENT_IMAGE}"

#         $exitCode, $stdout, $stderr = Run-Program 'docker' "build --build-arg `"user=$TEST_USER`" --build-arg `"JENKINS_AGENT_WORK=$TEST_JAW`" --tag=$CUSTOM_IMAGE_NAME --file ./windows/${global:WINDOWSFLAVOR}/Dockerfile ${global:BUILD_CONTEXT}"
#         $exitCode | Should -Be 0

#         $exitCode, $stdout, $stderr = Run-Program 'docker' "run --detach --tty --name=$global:CONTAINERNAME --publish-all $CUSTOM_IMAGE_NAME $global:CONTAINERSHELL"
#         $exitCode | Should -Be 0
#         Is-ContainerRunning "$global:CONTAINERNAME" | Should -BeTrue

#         $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME net user $TEST_USER"
#         $exitCode | Should -Be 0
#         $stdout | Should -Match "User name\s*$TEST_USER"

#         $exitCode, $stdout, $stderr = Run-Program 'docker' "exec $global:CONTAINERNAME $global:CONTAINERSHELL -C `"(Get-ChildItem env:\ | Where-Object { `$_.Name -eq 'JENKINS_AGENT_WORK' }).Value`""
#         $exitCode | Should -Be 0
#         $stdout.Trim() | Should -Match "$TEST_JAW"
#     }

#     AfterAll {
#         Cleanup($global:CONTAINERNAME)
#         Pop-Location -StackName 'agent'
#     }
# }
