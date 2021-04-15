function global:prompt{
    <#
    .SYNOPSIS
       Change console prompt
    .DESCRIPTION
        replace the default console prompt with a custom prompt.
    .EXAMPLE
        
    .NOTES
        function            : global:prompt{}
        Author              : Bart Lievers
        Dependencies        :
    #>

    Write-Host "brtlvrs " -NoNewLine -ForegroundColor DarkGreen
    Write-Host ((Get-location).Path + ">") -NoNewLine
    return " "
}