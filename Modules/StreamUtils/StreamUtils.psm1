##
## Handy stream utilities that provide more unix-like capabilities
##

filter get($property)
{
<#
.Synopsis
	Retrieves a given property from the stream of input objects
.Example
	ls | get length

	Description
	-----------
	retrieve a list of file lengths; equivalent to ls | % { $_.length }
#>
	return $_.$property
}

function grep($match, $property)
{
<#
.Synopsis
	Searches input objects for a regex match, optionally using a given property 
	of the input objects.
.Example
	gcm | grep ^add

	Description
	-----------
	List the shell commands starting with 'add'
.Example
	ls alias: | grep ^set definition

	Description
	-----------
	List all aliases bound to commands starting with 'set'
.Example
	gcm | grep cmdlet commandtype -invert

	Description
	-----------
	List the commands that are NOT CommandLets
#>
	begin { 
		$local:invert = $args -contains "-invert" 
		echo "$match";
	}
	process
	{
		if($property) { $local:value = $_.$property }
		else { $local:value = $_ }

		if($invert)
		{
			if(!($value -match $match)) { return $_ }
		}
		elseif($value -match $match) { return $_ }
	}
}

function head($max)
{
<#
.Synopsis
	Returns the first N items in the input stream
.Example
	gcm | head 5

	Description
	-----------
	Returns the first 5 commands
#>
	$INPUT | select-object -First $max
}

function reverse
{
<#
.Synopsis
	Reverses the items in the input stream
.Example
	get-history | reverse

	Description
	-----------
	Display history in reverse order
#>
	begin { $local:items = new-object Collections.ArrayList }
	process { [void]$items.Add($_); }
	end
	{
		$items.Reverse()
		return $items.ToArray([object])
	}
}

function tail($max)
{
<#
.Synopsis
	Returns the last N items in the input stream
.Example
	get-history | tail 5

	Description
	-----------
	Returns the last 5 history items
#>
	$INPUT | select-object -Last $max
}

function unique($property)
{
<#
.Synopsis
	Filters out non-unique items from the input stream, while preserving order.
	Note that get-unique or sort-object -unique do not preserve order.
.Example
	3,1,8,2,3,5,2 | unique

	Description
	-----------
	Outputs 3,1,8,2,5
.Example
	ls | unique mode

	Description
	-----------
	Lists the first item with each mode
#>
	begin
	{
		$local:items	 = new-object Collections.Hashtable
		$local:sawNull = $false
	}
	process
	{
		if($property) { $local:value = $_.$property }
		else { $local:value = $_ }

		if($value -eq $null)
		{
			if(!$sawNull)
			{
				$sawNull = $true
				return $_
			}
		}
		else
		{
			if(!$items.contains($value))
			{
				$items.add($value, $null)
				return $_
			}
		}
	}
}

Export-ModuleMember get
Export-ModuleMember grep
Export-ModuleMember head
Export-ModuleMember reverse
Export-ModuleMember tail
Export-ModuleMember unique
