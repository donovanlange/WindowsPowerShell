##
## More userfriendly job control. hurray! 
##

function Show-CompletedJobs
{
<#
.Synopsis
	Check for completed jobs, displaying any status changes.  Intended to be
	invoked from your prompt function.
#>
[CmdletBinding()]
Param()
	# check for completed jobs
	$jobs = @(Get-Job);

	for([int] $iJob = 0; $iJob -lt $jobs.Count; $iJob++)
	{
		$job = $jobs[$iJob]
		if($job -ne $null)
		{
			# if the job is not running anymore, display that to the user and null the array entry
			if($job.State -ne "Running" -and !$job._promptSaw)
			{
				write-host ('[' + $job.Id + ']- (' + $job.State + ') ' + (truncateStringAt $job.Command 40))
				$job | add-member NoteProperty _promptSaw $true # make sure we don't keep printing it over and over
			}
		}
	}
}

function Select-History([long[]] $ids)
{
<#
.Synopsis
	Combines several history events into a batchable statement.
.Description
	Combines several history events into a batch and returns the batch as a 
	string that can be executed with the eval (invoke-expression) command
.Parameter ids
	The history items to return in the batch.
.Example
	Select-History 7,8,10

	Description
	-----------
	Retrieves history commands 7, 8, and 10 in a batchable form.
.Example
	Select-History $(7..11) 

	Description
	-----------
	Batch history commands 7, 8, 9, 10, and 11
.Example
	$x = Select-History $(7..10)
	...
	eval $x  

	Description
	-----------
	Re-executes commands 7-10
.Example
	$x = Select-History $(7..10)
	eval "function doit { $x }"  
	doit

	Description
	-----------
	Create a function 'doit' that performs the commands 7, 8, 9, and 10 and
	invokes the doit function.
.Link
	eval
#>
	if(!$ids)
	{
		write-error "You must specify some history IDs."
		return
	}

	$local:batch = ""
	foreach($local:hi in (get-history -ID $ids))
	{
		$batch += $hi.commandLine + "; "
	}
	return $batch
}

function Update-Environment($varFile) 
{
<#
.Synopsis
	Update environment variables from a serialized set of command shell 
	variables into our environment
.Description
	Update environment variables from a serialized set of command shell 
	variables into our environment.  Particularly useful when rejoining child
	shell instances (for instance command prompt instances).
.Parameter varFile
	A file with the serialized environment variables (cmd /c "set > file")
.Example
	cmd /c "set > $env:TEMP\vars"; Update-Environment $env:TEMP\vars

	Description
	-----------
	Enumerate the environment variable from a dos prompt, and merge those values
	with our powershell instance.
#>
	$oldEnv = New-Object 'System.Collections.Generic.Dictionary[String,String]' ([System.StringComparer]::Ordinal)
	Get-ChildItem env:* | ForEach-Object { $oldEnv.Add($_.Key, $_.Value) }

	$newEnv = New-Object 'System.Collections.Generic.Dictionary[String,String]' ([System.StringComparer]::Ordinal)
	switch -regex -file $varFile {
		'^(.+?)=(.*)$' { $newEnv.Add($matches[1], $matches[2]) }
	}

	# Remove missing variables.
	$oldEnv.Keys |
		Where-Object { !$newEnv.ContainsKey($_) } |
		Sort-Object |
		ForEach-Object { Remove-Item "env:$_" }

	# Update changed variables.
	$newEnv.Keys |
		Where-Object { $oldEnv.ContainsKey($_) -and !$oldEnv[$_].Equals($newEnv[$_], 'Ordinal') } |
		Sort-Object |
		ForEach-Object { Set-Item "env:$_" $newEnv[$_] }

	# Add new variables.
	$newEnv.Keys |
		Where-Object { !$oldEnv.ContainsKey($_) } |
		Sort-Object |
		ForEach-Object { $null = New-Item "env:$_" -Value $newEnv[$_] }
}

function Invoke-CmdShell([String] $Command, [String] $CommandArguments)
{
<#
.Synopsis
	Invoke the given command script, and merge the resultant environment 
	variables and current working directory back into our shell.
.Description
	When running a .bat or .cmd file from Powershell a new shell instance will
	be created, and all changes to that environment will be lost when that shell
	exits. Invoke-Cmd-Script will remedy that by running the command shell and
	merging in all environment variable changes and updating the curren 
	location from the child shell.
.Parameter Command
	The command to run.
.Parameter CommandArguments
	The arguments to pass to the command
.Example
	Invoke-Cmd-Script "foo.bat"

	Description
	-----------
	Runs foo.bat and merges the environment variables and current directory.
#>
	$tempFiles = @{}
	try 
	{
		# Some temporary files for capturing updated environment.
		$tempFiles.base = [System.IO.Path]::GetTempFileName()  
		$tempFiles.dir = [System.IO.Path]::ChangeExtension($tempFiles.base, '.dir.tmp')
		$tempFiles.var = [System.IO.Path]::ChangeExtension($tempFiles.base, '.var.tmp')
		Write-Verbose "${myName}: tempFiles: $($tempFiles.Values)"

		# Execute the command, capture environment.
		Write-Verbose "cmd /c `"$Command`" $CommandArguments && cd > `"$($tempFiles.dir)`" && set > `"$($tempFiles.var)`" "

		cmd /c " `"$Command`" $CommandArguments && cd > `"$($tempFiles.dir)`" && set > `"$($tempFiles.var)`" "

		# Apply changes to the local environment.
		Update-Environment $($tempFiles.var)

		Set-Location (Get-Content $($tempFiles.dir))
	} 
	finally 
	{
		# Remove the temporary files, ignoring errors
		$tempFiles.Values | ForEach-Object { if ($_) { Remove-Item -LiteralPath $_ -ErrorAction 0 } }
	}
}

Export-ModuleMember Show-CompletedJobs

Set-Alias bg Start-Job
Export-ModuleMember -Alias bg

Set-Alias jobs Get-Job
Export-ModuleMember -Alias jobs

Export-ModuleMember Select-History
Set-Alias batch Select-History
Export-ModuleMember -Alias batch

Export-ModuleMember Update-Environment
Export-ModuleMember Invoke-CmdShell
