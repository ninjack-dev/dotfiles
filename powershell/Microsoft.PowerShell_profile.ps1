function Prettify-Json ($jsonfile) {
  (get-content $jsonfile) | convertfrom-json | convertto-json -depth 100 | 
    set-content $jsonfile
}

Set-PSReadLineKeyHandler -Chord 'Alt+l' -BriefDescription "DisplayCurrentDir" -Description "Displays the current directory without erasing current command" -ScriptBlock {
    # This seems inconsistent. At times, the prompt appears mid-way through the directory listing;
    # in other sessions, the glyph rendering failed entirely. 
    Get-ChildItem . | Out-Host;
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
oh-my-posh init pwsh | Invoke-Expression
