

New-AzWvdHostPool `
    -ResourceGroupName rg-wth-wvd-d-uks `
    -Name hp-wth-wvd-d-uks `
    -Location 'northeurope' `
    -HostPoolType 'Pooled' `
    -LoadBalancerType 'DepthFirst' `
    -MaxSessionLimit 30 `
    -Description 'Remote Apps Pool for UK' `
    -FriendlyName 'UK South Remote App Pool' `
    -PreferredAppGroupType RailApplications `
    -RegistrationTokenOperation 'Update' `
    -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')) `
    -Tag @{Application="wvdAZ-140";costcenter="AZ-140";Environment="Lab";Owner="WVD Admin";SupportContact="x1234"} `
    -CustomRdpProperty "audiocapturemode:i:0;camerastoredirect:s:;use multimon:i:0;encode redirected video capture:i:0;audiomode:i:2;redirectclipboard:i:0;redirectprinters:i:0" `
    -ValidationEnvironment:$false












