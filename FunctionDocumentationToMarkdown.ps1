param(
  [parameter(Mandatory = $true)]
  [string]$script,
  [parameter(Mandatory = $true)]
  [string]$outputFolder
) 

function Get-SingleHelpComment {
  param ([string]$commentName,
         [string]$commentType)
  if ($commentType -eq "Single")
  {
    $pattern = ($helpCommentPatterns | Where-Object Name -eq $commentName | Select-Object -ExpandProperty Pattern)
    $value = $FunctionDefinition | Select-String -Pattern $pattern -AllMatches
    $value = $value.Matches.Value
    return $value
  }else {
    $pattern = $helpCommentPatterns | Where-Object Name -eq $commentName | Select-Object -ExpandProperty Pattern
    $value = $FunctionDefinition | Select-String -Pattern $pattern -AllMatches
    $values = @()
    for ($i = 0; $i -le $value.Matches.Count - 1; $i++) {
      $values += $value.Matches[$i].Value
    }
  
    return $values
  }
  
}

function Get-MDHeader {
  # Getting the first line of the help comment and removing the dot
  # e.g. .SYNOPSIS will become SYNOPSIS
  param($header)
  try{
    return ($header | Select-String -Pattern "\.\w.*").Matches.Value.Replace('.', '')
  }catch{
    Write-Host $_
    return ""
  }

}


function New-MarkDownFunctionDocumentationSingleComment {
  param ([string]$name,
         [string]$type)

  Write-Host "Processing: $name" -BackgroundColor DarkGreen -ForegroundColor  Black
 
  # if help comment is expected to be found only once e.g. SYNOSPIS
  if ($type -eq "Single")
  {
   
    $data = Get-SingleHelpComment -commentName "$name" -commentType $type
    if ($data.length -gt 0){
      $global:mdFile += New-MDHeader (Get-MDHeader -header $data) -Level 3
      $global:mdFile += New-MDParagraph -Lines ($data -replace "\.\w.*", "").TrimStart()
    }
  }else {
    $datei = Get-SingleHelpComment -commentName "$name" -commentType $type
    foreach ($data in $datei) {
      $global:mdFile += New-MDHeader (Get-MDHeader -header $data) -Level 3
      $header  = (Get-MDHeader -header $data)
      $headerReplacement = ".$($header)"
      $global:mdFile += New-MDParagraph -Lines ($data -replace "$headerReplacement", "").TrimStart()
      
    }
  }
  
}
function Load-Module ($m) {

  # If module is imported say that and do nothing
  if (Get-Module | Where-Object {$_.Name -eq $m}) {
      write-host "Module $m is already imported."
  }
  else {

      # If module is not imported, but available on disk then import
      if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
          Import-Module $m -Verbose
      }
      else {

          # If module is not imported, not available on disk, but is in online gallery then install and import
          if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
              Install-Module -Name $m -Force -Verbose -Scope CurrentUser
              Import-Module $m -Verbose
          }
          else {

              # If module is not imported, not available and not in online gallery then abort
              write-host "Module $m not imported, not available and not in online gallery, exiting."
              EXIT 1
          }
      }
  }
}

Load-Module "MarkdownPS"


if ($script -eq $null -or $outputFolder -eq $null -or $script.lengh -eq 0 -or $outputFolder.length -eq 0) {
  Write-Host "Please enter a valid -script and a -outputFolder parameter." -ForegroundColor Red
  Write-Host "Example:"
  Write-Host "PS> .\FunctionDocumentationToMarkdown.ps1 -script C:\users\Administrator\myFancyScript\myFancyScript.ps1 -OutputFolder C:\users\Administrator\myFancyScript\docs" -ForegroundColor Yellow
}
else {
  
  Write-Host "Gathering info" -ForegroundColor Yellow
  $functionsInScript = Get-Content $script | select-string function

  . "$script"

  Write-Host "Creating function information and regex patterns" -ForegroundColor Yellow
  $helpCommentPatterns = @()
  $helpComments = @("SYNOPSIS", "DESCRIPTION", "PARAMETER", "INPUTS", "OUTPUTS", "EXAMPLE", "LINK")
  foreach ($helpComment in $helpComments) {
    if ($helpComment -eq "PARAMETER" -or $helpComment -eq "EXAMPLE" -or $helpComment -eq "LINK") {
      $patternHashtable = @{
        Name    = $helpComment
        Pattern = "(?msi)(.$($helpComment))(.*?)(?=[\n\r]{2})$"
        Type    = "Multiple"
      }
    }
    else {
      $patternHashtable = @{
        Name    = $helpComment
        Pattern = "(?msi)(.$($helpComment))(.*?)(?=[\n\r]{2})$"
        Type    = "Single"
      }
    }
    $helpCommentPattern = New-Object -TypeName PSObject -Property $patternHashtable
    $helpCommentPatterns += $helpCommentPattern
  } 

  foreach ($functionInScript in $functionsInScript) {

    $global:mdFile = ""
    $global:mdFile += New-MDHeader ([cultureinfo]::GetCultureInfo("en-US").TextInfo.ToTitleCase("$functionInScript"))
    Write-Host "Processing Function:" $FunctionObject.Name -BackgroundColor DarkYellow -ForegroundColor Black
    $FunctionName = $functionInScript.ToString()
    $FunctionName = [string]$FunctionName.Replace("function ", "")
    Write-Host "Gathering function info..." -BackgroundColor Yellow -ForegroundColor Black
    $FunctionObject = Get-ChildItem function: | Where-Object Name -eq "$FunctionName"

    $FunctionDefinition = $FunctionObject.Definition
    $FunctionDefinition = $FunctionDefinition.ToString().Replace("<#", "{{") 
    $FunctionDefinition = $FunctionDefinition.Replace("#>", "`r`n`r`n}}")

    $pattern = "(?s){{(.*)}}"

    $FunctionDefinition = $FunctionDefinition  | Select-String  -pattern $pattern -AllMatches
    $FunctionDefinition = $FunctionDefinition.Matches.Value
    
    foreach ($helpCommentPattern in $helpCommentPatterns)
    {      
      New-MarkDownFunctionDocumentationSingleComment -name $helpCommentPattern.Name -type $helpCommentPattern.Type
    }
    Write-Host "Markdown file path:" $OutputFolder\$FunctionName.md -BackgroundColor Green -ForegroundColor  Black
    $global:mdFile | Out-File "$OutputFolder\$FunctionName.md"
    $global:mdFile = $null
    Write-Host ""
  }
}
