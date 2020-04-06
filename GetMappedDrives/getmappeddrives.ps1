$drives = Get-PSDrive -PSProvider FileSystem
[System.Collections.ArrayList]$results = @()

foreach ($drive in $drives) {
    if ($drive.DisplayRoot) {
        [void] $results.Add($drive.Name + ":" + $drive.DisplayRoot + ";")
    }
}

return $results
