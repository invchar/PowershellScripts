param (
    [string]$printer = $(throw "You must specify a printer by name, specified as \\<server>\<share name>")
)

Get-CimInstance -Query "SELECT * from Win32_Printer WHERE name LIKE '%$printer%'" | Invoke-CimMethod -MethodName "PrintTestPage"
