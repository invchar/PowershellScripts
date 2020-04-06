param (
    [int16]$duration = 60, # duration in minutes (seconds elapsed will be divided by 60, then compared)
    [string]$target = "127.0.0.1"
)
$starttime = Get-Date -UFormat %s
while ( ((Get-Date -UFormat %s) - $starttime) / 60 -lt $duration ) {
    $time = Get-Date -Format g
    $ping = ping -n 1 $target
    $ping.Split([Environment]::NewLine)[2] + " - " + $time | Out-File -FilePath ($target + ".txt") -Append
    Start-Sleep -Seconds 1
}
