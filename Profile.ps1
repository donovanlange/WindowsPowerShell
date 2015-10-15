# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
$MaximumHistoryCount = 512
$FormatEnumerationLimit = 100

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------

# PSReadline provides Bash like keyboard cursor handling
if ($host.Name -eq 'ConsoleHost')
{
	Import-Module PSReadline
}

# Git support
Import-Module Git
Initialize-Git

# Utils
Import-Module JobControl
Import-Module StreamUtils
Import-Module StringUtils
Import-Module Profile

# ---------------------------------------------------------------------------
# Custom Aliases
# ---------------------------------------------------------------------------
set-alias unset      remove-variable
set-alias mo         measure-object
set-alias eval       invoke-expression
set-alias n          notepad.exe

# ---------------------------------------------------------------------------
# Visuals
# ---------------------------------------------------------------------------
set-variable -Scope Global WindowTitle ''

function prompt
{
	$local:pathObj = (get-location)
	$local:path    = $pathObj.Path
	$local:drive   = $pathObj.Drive.Name

	if(!$drive) # if there's no drive, it might be a special path (eg, a UNC path)
	{
		if($path.contains('::')) # if it's a special path, get the provider's path name
		{
			$path = $pathObj.ProviderPath
		}
		if($path -match "^\\\\([^\\]+)\\") # if it's a UNC path, use the server name as the drive
		{
			$drive = $matches[1]
		}
	}
	
	$local:title = $path
	if($WindowTitle) { $title += " - $WindowTitle" }

	$host.ui.rawUi.windowTitle = $title
	$path = [IO.Path]::GetFileName($path)
	if(!$path) { $path = '\' }

	# Check for completed background jobs:
	Show-CompletedJobs
 
	if($NestedPromptLevel)
	{
		Write-Host -NoNewline -ForeGroundColor Green "$NestedPromptLevel-";
	}
	
	$private:h = @(Get-History);
	$private:nextCommand = $private:h[$private:h.Count - 1].Id + 1;
	Write-Host -NoNewline -ForeGroundColor Red "${private:nextCommand}|";	 
	
	Write-Host -NoNewline -ForeGroundColor Blue "${drive}";
	Write-Host -NoNewline -ForeGroundColor White ":";
	Write-Host -NoNewline -ForeGroundColor White "$path";
	
	# Show GIT Status, if loaded:
	if (Get-Command "Write-VcsStatus" -ErrorAction SilentlyContinue)
	{
		$realLASTEXITCODE = $LASTEXITCODE
		Write-VcsStatus
		$global:LASTEXITCODE = $realLASTEXITCODE
	}

	return ">";
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

# starts a new execution scope
function Start-NewScope 
{
	param($Prompt = $null) Write-Host "Starting New Scope"
	if ($Prompt -ne $null)
	{
		if ($Prompt -is [ScriptBlock])
		{
			$null = New-Item function:Prompt -Value $Prompt -force
		}
		else
		{
			function Prompt {"$Prompt"}
		}
	}
	$host.EnterNestedPrompt()
}

# 'cause shutdown commands are too long and hard to type...
function Restart
{
	shutdown /r /t 1
}