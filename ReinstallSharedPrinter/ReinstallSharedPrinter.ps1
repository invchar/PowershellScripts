param (
    [string]$printer = $(throw "You must specify a printer by name, specified as \\<server>\<share name>")
)

if (Get-Printer -Name $printer -ErrorAction SilentlyContinue) {
    Remove-Printer -Name $printer
}

Add-Printer -ConnectionName $printer
