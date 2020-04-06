# Variables used
# $file specifies the hashfile containing the hashes and filenames to be checked
# $algo specifies the hashing algorithm to use, default is sha256
# $filetext is the text from $file
# $x is the counter for the loop
# $line is the current line from $filetext
# $expectedhash is the hash from current $line
# $filename is the name of the file to be checked from current $line
# $actualhash is the actual hash generated for the file with $filename from $line

param (
    [string]$file = $(throw "Specify hashfile with -file"),
    [string]$algo = "sha256"
)

$filetext = Get-Content($file)


for ($x = 0; $x -lt $filetext.Length; $x++) {
    $line = $filetext[$x]
    $expectedhash = $line.Split()[0].ToString().ToLower()
    $filename = $line.Split()[1] -replace "\*",""
    if (Test-Path $filename) {
        $actualhash = (Get-FileHash -Algorithm $algo $filename).hash.ToLower()
    
        if ($actualhash -eq $expectedhash) {
            Write-Output "$filename OK"
        } else {
            Write-Output "$filename BAD"
        }
    } else {
        Write-Output "$filename doesn't exist"
    }
}
