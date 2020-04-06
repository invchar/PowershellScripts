
cls
for ($i = 1; $i -lt 5; $i++) {
    Write-Progress -Activity "Starting up" -Status "Percent complete" -PercentComplete ($i / 5 * 100)
    Start-Sleep -s 1
}
while (0 -lt 1) {
    for ($i = 1; $i -lt 60; $i++) {
        Write-Progress -Activity "Copying data" -Status "Percent complete" -PercentComplete ($i / 60 * 100)
        Start-Sleep -m 200
        if ($i -eq 30) {
            Start-Sleep -s 2
        }
    }
    for ($i = 1; $i -lt 60; $i++) {
        Write-Progress -Activity "Backing up" -Status "Percent complete" -PercentComplete ($i / 60 * 100)
        if ($i -lt 20) {
            Start-Sleep -s 1
        }
        elseif ($i -lt 40) {
            Start-Sleep -m 500
        }
        else {
            Start-Sleep -m 100
        }
    }
    for ($i = 1; $i -lt 60; $i++) {
        Write-Progress -Activity "Verifying backup" -Status "Percent complete" -PercentComplete ($i / 60 * 100)
        if ($i -lt 30) {
            Start-Sleep -m 50
        }
        else {
            Start-Sleep -m 150
        }
    }
    for ($i = 1; $i -lt 60; $i++) {
        Write-Progress -Activity "Sorting data" -Status "Percent complete" -PercentComplete ($i / 60 * 100)
        Start-Sleep -m 500
    }
    for ($i = 1; $i -lt 60; $i++) {
        Write-Progress -Activity "De-duplicating data" -Status "Percent complete" -PercentComplete ($i / 60 * 100)
        Start-Sleep -m 700
    }
    for ($i = 1; $i -lt 60; $i++) {
        Write-Progress -Activity "Writing data" -Status "Percent complete" -PercentComplete ($i / 60 * 100)
        Start-Sleep -m 100
        if ($i -eq 20 -or $i -eq 50) {
            Start-Sleep -m 150
        }
    }
}
