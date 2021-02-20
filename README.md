# So... what's this?

This is a script that will output the documentation of a function of your script to an md file per function for documentation purposes.

## Can you get a little more in depth?

Yes sure, so Microsoft has created a pseudo-language to help people document their script in using a "standard", more info here https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1 

Now if you want this to be documented in an external file due to whatever reasons, you are out of luck. 

This script will output currently the following Comment Based Help keywords to a markdown file and all their information per function in your script. 

| Keyword Name | Type     |
| ------------ | -------- |
| SYNOPSIS     | Single   |
| DESCRIPTION  | Single   |
| PARAMETER    | Multiple |
| INPUTS       | Single   |
| OUTPUTS      | Single   |
| EXAMPLE      | Multiple |
| LINK         | Multiple |

## OK, I think I got it now, is there something I should know before running it?

Yes you should:

- **It will install MarkdownPS module and ask you about it.**
- The above script is work in progress therefore results might not be perfect for your use case, feel free to alert the script
- The comment based help should be inside the function immediately after the declaration of the function, see example below

```powershell
function Get-Something
{
	param ([string]$something)
	<#
		.SYNOPSIS
		This function get's something
	#>
	Do-Something -Path $something
}
```

- The script only excepts the comment based help keywords with type Multiple (see table above) to have multiple entries per function. Therefore if you have more than one SYNOPSIS the script might not work correctly. Feel free to test it.

## Hm... now I am hooked, how does it work?

Really easy, download the .ps1 to a folder of your liking and do the following

``` powershell
PS> .\FunctionDocumentationToMarkdown.ps1 -script "C:\Users\Administrator\myFancyScript\myFancyScript.ps1" -outputfolder "C:\Users\Administrator\myFancyScript\docs"
```

Please note that the output folder parameter does not have a trailing `\`



