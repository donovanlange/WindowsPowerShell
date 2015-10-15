##
## Profile utilities
##

function Invoke-Profile() 
{
<#
.Synopsis
	Attempts to reload your profile.
#>
	@(
		$Profile.AllUsersAllHosts,
		$Profile.AllUsersCurrentHost,
		$Profile.CurrentUserAllHosts,
		$Profile.CurrentUserCurrentHost
	 ) | % {
		if (Test-Path $_)
		{
				Write-Verbose "Running $_"
				. $_
		}
	 }
}

function Edit-Profile
{
<#
.Synopsis
	Opens up an editor on the profile file.
#>
	n $profile.CurrentUserAllHosts
}

Export-ModuleMember Invoke-Profile

Export-ModuleMember Edit-Profile
Set-Alias ep Edit-Profile
Export-ModuleMember -Alias ep
