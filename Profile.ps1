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

	Set-PSReadLineOption -MaximumHistoryCount 4000
	Set-PSReadlineOption -ShowToolTips:$true

	# With these bindings, up arrow/down arrow will work like
	# PowerShell/cmd if the current command line is blank. If you've
	# entered some text though, it will search the history for commands
	# that start with the currently entered text.
	Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
	Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

	Set-PSReadlineKeyHandler -Key "Tab" -Function "MenuComplete"
	Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function "Complete"
}

# fzf is a fuzzy file finder, and will provide fuzzy location searching
# when using Ctrl+T, and will provide better reverse command searching via
# Ctrl-R.
Import-Module PSFzf -ArgumentList 'Ctrl+T','Ctrl+R'

Import-Module oh-my-posh
Set-PoshPrompt -Theme "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\.MyPoshTheme.omp.json"

# Colorize directory output
Import-Module Terminal-Icons

# Utils
Import-Module StreamUtils
Import-Module StringUtils
Import-Module Profile

# ---------------------------------------------------------------------------
# Custom Aliases
# ---------------------------------------------------------------------------
set-alias unset      remove-variable
set-alias mo         measure-object
set-alias eval       invoke-expression
set-alias n          vim.exe
set-alias vi         vim.exe

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

# --------------------------------------------------------------------------
# EXO Helpers
# --------------------------------------------------------------------------

function dev($project)
{
	cd "$(get-content Env:INETROOT)\sources\dev\$project"
}

function test($project)
{
	cd "$(get-content Env:INETROOT)\sources\test\$project"
}

function bcc
{
	build -Cc
}

# Workaround oh-my-posh rendering bug when Powershell is launched with -NoLogo
cls
