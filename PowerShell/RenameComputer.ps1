[CmdletBinding()]
[Alias()]
[OutputType([int])]
Param (
    # Param1 help description
    [Parameter(Mandatory=$true,
    ValueFromPipelineByPropertyName=$true,
    Position=0)]
    $VMName
)

Begin {    
####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path c:\temp) -eq $false) {
    Add-Content -LiteralPath C:\RenameComputer.log "Create C:\temp Directory"
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path c:\temp -ItemType Directory
}
else {
    Add-Content -LiteralPath C:\RenameComputer.log "C:\temp Already Exists"
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}
New-Item -Path c:\ -Name C:\RenameComputer.log -ItemType File
Add-Content -LiteralPath C:\RenameComputer.log `
"
CurrentName     = $env:COMPUTERNAME
TargetName      = $VMName
"

}

Process {
    Add-Content -LiteralPath C:\RenameComputer.log "Current ComputerName = $env:COMPUTERNAME, Rename Target = $VMName"
    Rename-Computer -NewName $VMName -Restart -Verbose
}

End
{
    
}


