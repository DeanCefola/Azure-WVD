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

Begin
{
    $CurrentName = $env:COMPUTERNAME
}

Process
{
    Rename-Computer -NewName $VMName -Restart -Verbose
}

End
{
    
}


