# checkhash.ps1
Powershell script to take a hashfile and check the file hashes


Use -file to specify the text file containing the hashes and corresponding filenames

Use -algo to specify an algorithm, script uses sha256 by default


Script will print OK if hashes match, BAD if they don't, and "doesn't exist" if the file doesn't exist


The files being hashed and checked should be in the same directory as the hash file and this directory should be your current working directory when you run the script
