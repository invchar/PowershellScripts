param (
    # server
    [string]$server = $(throw "Specify server with -server"),
    # dbfile
    [string]$dbfile = $(throw "Specify dbfile with -dbfile"),
    # recurse - recurse or not
    [switch]$recurse = $false,
    # ignore inherited permissions
    [switch]$ignoreinherited = $false,
    # expand groups option will expand the groups in results into users
    [switch]$expandgroups = $false,
    # share, all on server if omitted
    [string]$share,
    # user - enumerates accesses only for specified user, includes memberships recursively
    [string]$user,
    # group - enumerates accesses only for specified group, includes memberships recursively
    [string]$group
)

$ErrorActionPreference = "Stop"
$completeIDs = @()
$script:domain = ""

function processError($error) {
    Write-Information($error)
}
function createDB() {
    $application = New-Object -ComObject Access.Application
    $application.NewCurrentDatabase($dbfile,12)
    $application.CloseCurrentDatabase()
    $application.Quit()
    $connection = New-Object -ComObject ADODB.Connection
    $connection.Open("Provider = Microsoft.ACE.OLEDB.12.0; Data Source=$dbfile")
    [void]$connection.Execute("CREATE TABLE enumAccess `(ID TEXT, viaID TEXT, Path TEXT, Type TEXT, Inherited TEXT, Access TEXT`)")
    $connection.Close()
}

function openDB() {
    $cursor = 3
    $lock = 3
    $script:ado = New-Object -ComObject ADODB.Connection
    $script:recordset = New-Object -ComObject ADODB.Recordset
    $script:ado.open("Provider = Microsoft.ACE.OLEDB.12.0; Data Source=$dbfile")
    $script:recordset.open("SELECT * FROM enumAccess",$script:ado,$cursor,$lock)
}

function closeDB() {
    $script:recordset.close()
    $script:ado.close()
}

function addRecord($ID, $viaID, $path, $type, $inherited, $access) {
    $script:recordset.AddNew()
    $script:Recordset.Fields.Item("ID") = $ID
    $script:Recordset.Fields.Item("viaID") = $viaID
    $script:Recordset.Fields.Item("Path") = $path
    $script:Recordset.Fields.Item("Type") = [string]$type
    $script:Recordset.Fields.Item("Inherited") = [string]$inherited
    $script:Recordset.Fields.Item("Access") = [string]$access
    $script:recordset.Update()
}

function validateOptions() {
    if ($user -and $group) {
        # error - specify user or group or neither but not both
        Write-Error -Message "Cannot specify both user and group options"
    }
    if (($user -or $group) -and $expandgroups) {
        # error - expand groups option only available when no user or group is specified
        Write-Error -Message "Expand groups option is only available when no user or group is specified"
    }
}

function processPath($path) {
    try {
        $acl = Get-Acl $path
        foreach ($access in $acl.access) {
            if ((!$user -and !$group) -or $script:completeIDs.Contains($access.IdentityReference.Value.ToLower())) {
                if (($ignoreinherited -and $access.IsInherited -eq $false) -or ($ignoreinherited -eq $false)) {
                    if (!$user -and !$group -and !$expandgroups) {
                        addRecord $access.IdentityReference.Value $access.IdentityReference.Value $path $access.AccessControlType $access.IsInherited $access.FileSystemRights
                    } elseif (!$user -and !$group -and $expandgroups) {
                        if (($access.IdentityReference.Value -split ($script:domain + '\\'))[1]) {
                            $canfilter = $true
                            $filter = ($access.IdentityReference.Value -split ($script:domain + '\\'))[1]
                        } else {
                            $canfilter = $false
                        }
                        if ($canfilter) {
                            if ((Get-ADObject -Filter {SamAccountName -like $filter}).ObjectClass -eq "group") {
                                processADMembers $path $access $filter
                            } else {
                                addRecord $access.IdentityReference.Value $access.IdentityReference.Value $path $access.AccessControlType $access.IsInherited $access.FileSystemRights
                            }
                        } else {
                            addRecord $access.IdentityReference.Value $access.IdentityReference.Value $path $access.AccessControlType $access.IsInherited $access.FileSystemRights
                        }
                    } else {
                        addRecord $script:completeIDs[0] $access.IdentityReference.Value $path $access.AccessControlType $access.IsInherited $access.FileSystemRights
                    }
                }
            }
        }
    } catch {
        processError $_
    }
    if ($recurse) {
        try {
            $children = Get-ChildItem -Directory $path
            $counter3 = 0
            foreach ($child in $children) {
                $counter3++
                $progress3 = $counter3 / $children.Count * 100
                Write-Progress -Id 3 -Activity ("Processing children of " + $path) -CurrentOperation ("Processing " + $child.Name) -ParentId 2 -PercentComplete $progress3
                processPath ($path + "\" + $child.Name)
            }
        } catch {
            processError $_
        }
    }
}

function processADMemberships($sid) {
    # process memberships recursively
    try {
        $groups = Get-ADPrincipalGroupMembership -Identity $sid
    } catch {
        processError $_
    }
    if ($groups) {
        foreach ($group in $groups) {
            try {
                $script:completeIDs = $script:completeIDs + ($script:domain + "\" + $group.name).ToLower()
                processADMemberships $group.sid.value
            } catch {
                processError $_
            }
        }
    }
}

function processADMembers($path, $access, $groupname) {
    try {
        $members = Get-ADGroupMember -Identity $groupname -Recursive
        foreach ($member in $members) {
            addRecord (($script:domain + "\") + $member.SamAccountName) $access.IdentityReference.Value $path $access.AccessControlType $access.IsInherited $access.FileSystemRights
        }
    } catch {
        processError $_
    }

}

function main() {
    $domainobj = Get-ADDomain
    $script:domain = $domainobj.Name
    if ($user) {
        # grab user, grab memberships recursively, add to $ids
        try {
            $userobj = Get-ADUser -Identity $user
            $script:completeIDs = $script:completeIDs + ($script:domain + "\" + $userobj.SamAccountName).ToLower()
            processADMemberships $userobj.sid.value
        } catch {
            processError $_
        }
    } elseif ($group) {
        # grab group, grab memberships recursively, add to $ids
        try {
            $groupobj = Get-ADGroup -Identity $group
            $script:completeIDs = $script:completeIDs + ($script:domain + "\" + $groupobj.name).ToLower()
            processADMemberships $groupobj.sid.value
        } catch {
            processError $_
        }
    }

    if ($share) {
        # process for specified share
        Write-Progress -Id 2 -Activity "Enumerating Access" -CurrentOperation ("Collecting information for " + $share) -PercentComplete 50
        processPath ("\\" + $server + "\" + $share)
    } else {
        # get all shares and process
        $wmishares = Get-WmiObject -Class Win32_Share -ComputerName $server -ErrorAction Stop | Where-Object {$_.Type -eq 0}
        $counter2 = 0
        foreach ($share in $wmishares) {
            $counter2++
            $progress2 = $counter2 / $wmishares.Count * 100
            Write-Progress -Id 2 -Activity "Enumerating Access" -CurrentOperation ("Collecting information for " + $share.Name) -PercentComplete $progress2
            processPath ("\\" + $server + "\" + $share.name)
        }
    }
}

Write-Progress -Id 1 -Activity "Enumerating Access" -CurrentOperation "Reading options" -PercentComplete 0
validateOptions
Write-Progress -Id 1 -Activity "Enumerating Access" -CurrentOperation "Creating database" -PercentComplete 20
createDB
Write-Progress -Id 1 -Activity "Enumerating Access" -CurrentOperation "Opening database" -PercentComplete 40
openDB
Write-Progress -Id 1 -Activity "Enumerating Access" -CurrentOperation "Collecting information" -PercentComplete 60
main
Write-Progress -Id 1 -Activity "Enumerating Access" -CurrentOperation "Closing database" -PercentComplete 80
closeDB