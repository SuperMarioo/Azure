$OctopusURL = "http://octopusdsc" #Your Octopus URL
$OctopusAPIKey = "API-ORT9F3DASQOL6HXPCOTEOZXDG " #Your Octopus API Key
$header = @{ "X-Octopus-ApiKey" = $OctopusAPIKey }



$machine = (Invoke-WebRequest $OctopusURL/api/machines/all -Headers $Header -UseBasicParsing ).content | ConvertFrom-Json | ?{$_.Name -eq $env:COMPUTERNAME}
$machine  = $machine | ? {$_.name -eq $env:COMPUTERNAME }



Invoke-WebRequest $OctopusURL/api/machines/$($machine.Id)  -Method Delete -Headers $header