function Initialize-Git {
[CmdletBinding()]
Param(
	[switch]
	$SkipSSHSetup = $false
)
<#
.SYNOPSIS
	Sets up the GitHub Git Shell Environment
.DESCRIPTION
	Sets up the proper PATH and ENV to use GitHub for Window's shell environment
#>
	if ($env:github_shell -eq $null) 
	{
		Write-Verbose "Running GitHub\shell.ps1"

		if (Test-Path -Type Container "$env:LocalAppData\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c")
		{
			$env:github_git = Resolve-Path "$env:LocalAppData\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c"
		}
		else
		{
			return
		}

		# Initialize Environment variables needed by MinGW, SSH, and Git commands:
		$env:PLINK_PROTOCOL = "ssh"
		$env:TERM = "msys"
		$env:HOME = $HOME
		$env:OPENSSL_CONF = "$env:GITHUB_GIT\ssl\openssl.cnf"

		# Setup PATH with the Git, GitHub, and msBuild tools
		$pGitPath = $env:github_git
		$env:Path = "$env:Path;$pGitPath\cmd;$pGitPath\bin;$pGitPath\mingw\bin;$pGitPath\usr\bin"

		if (Test-Path -Type Container "$env:LocalAppData\Apps\2.0\TL85DTYW.0WM\P59GNLLA.J5G\gith..tion_317444273a93ac29_0003.0000_f3a9f44c4e4f6514")
		{
			$appPath = Resolve-Path "$env:LocalAppData\Apps\2.0\TL85DTYW.0WM\P59GNLLA.J5G\gith..tion_317444273a93ac29_0003.0000_f3a9f44c4e4f6514"
			$env:Path = "$env:Path;$appPath"
		}

		if (Test-Path -Type Container "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319")
		{
			$msBuildPath = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319"
			$env:Path = "$env:Path;$msBuildPath"
		}

		# Setup SSH:
		if (Get-Command "GitHub.exe" -ErrorAction SilentlyContinue)
		{
			& GitHub.exe --set-up-ssh
		}

		Import-Module Posh-Git
		Enable-GitColors
		Start-SshAgent -Quiet
		
		# We prefer hub.exe to git.exe, if available
		if (Get-Command "hub.exe" -ErrorAction SilentlyContinue)
		{
			set-alias -Scope Global git hub.exe
		}
	}
	else 
	{
		Write-Verbose "GitHub shell environment already setup"
	}
}

Export-ModuleMember Initialize-Git
