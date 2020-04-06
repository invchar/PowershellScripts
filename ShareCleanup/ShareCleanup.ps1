[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

### Variables

# Allows toggling select all/deselect all
$allSelectedState = $false
# Paths - properties are Share (which may be a parent if the path is a child), Path, Child which is a bool indicating whether it is a child (subfolder) of a share
[System.Collections.ArrayList]$paths = @()
# Accesses - properties are Path, Username, AccessType, AccessLevel
[System.Collections.ArrayList]$accesses = @()
# Groups - properties are GroupName, Path, AccessType, AccessLevel
[System.Collections.ArrayList]$groups = @()
# Set to true if we need to stop execution
$terminate = $True

### Functions and blocks

# Function for select all button in share select form
function selectAll() {
    $state = $false
    if ($allSelectedState -eq $false) {
        $state = $True
    }
    for ($i = 0;$i -lt $checkList.Items.Count;$i++) {
        $checkList.SetItemChecked($i, $state)
    }
    $script:allSelectedState = $state
}

### Forms

# Info form
$infoForm = New-Object System.Windows.Forms.Form
$infoForm.Text = "Enter information"
$infoForm.Size = New-Object System.Drawing.Size(600,200)
$serverFieldLabel = New-Object System.Windows.Forms.Label
$serverFieldLabel.Text = "Enter server name:"
$serverFieldLabel.Size = New-Object System.Drawing.Size(175,20)
$serverFieldLabel.Location = New-Object System.Drawing.Size(5,20)
$infoForm.Controls.Add($serverFieldLabel)
$serverField = New-Object System.Windows.Forms.TextBox
$serverField.Size = New-Object System.Drawing.Size(375,20)
$serverField.Location = New-Object System.Drawing.Size(180,20)
$infoForm.Controls.Add($serverField)
$grouplocFieldLabel = New-Object System.Windows.Forms.Label
$grouplocFieldLabel.Text = "Enter location for groups: (DN)"
$grouplocFieldLabel.Size = New-Object System.Drawing.Size(175,20)
$grouplocFieldLabel.Location = New-Object System.Drawing.Size(5,40)
$infoForm.Controls.Add($grouplocFieldLabel)
$grouplocField = New-Object System.Windows.Forms.TextBox
$grouplocField.Size = New-Object System.Drawing.Size(375,20)
$grouplocField.Location = New-Object System.Drawing.Size(180,40)
$infoForm.Controls.Add($grouplocField)
$domainFieldLabel = New-Object System.Windows.Forms.Label
$domainFieldLabel.Text = "Enter your domain (NOT FQDN):"
$domainFieldLabel.Size = New-Object System.Drawing.Size(175,20)
$domainFieldLabel.Location = New-Object System.Drawing.Size(5,60)
$infoForm.Controls.Add($domainFieldLabel)
$domainField = New-Object System.Windows.Forms.TextBox
$domainField.Size = New-Object System.Drawing.Size(375,20)
$domainField.Location = New-Object System.Drawing.Size(180,60)
$infoForm.Controls.Add($domainField)
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Add_Click({$infoForm.Close(); $script:terminate = $false})
$okButton.Location = New-Object System.Drawing.Size(10,80)
$infoForm.Controls.Add($okButton)
$infoForm.Add_Shown({$infoForm.Activate()})
# Share selection form
$selectForm = New-Object System.Windows.Forms.Form
$selectForm.Text = "Select shares to ignore"
$selectForm.Size = New-Object System.Drawing.Size(430,500)
$checkList = New-Object System.Windows.Forms.CheckedListBox
$checkList.CheckOnClick = $True
$checkList.Size = New-Object System.Drawing.Size(400,300)
$checkList.Location = New-Object System.Drawing.Size(5,40)
$selectForm.Controls.Add($checkList)
$checkAll = New-Object System.Windows.Forms.Button
$checkAll.Text = "Select All"
$checkAll.Location = New-Object System.Drawing.Size(5,5)
$checkAll.Add_Click({selectAll})
$selectForm.Controls.Add($checkAll)
$includeSubs = New-Object System.Windows.Forms.CheckBox
$includeSubs.Text = "Include Subfolders"
$selectForm.Controls.Add($includeSubs)
$includeSubs.Location = New-Object System.Drawing.Size(5,335)
$ignoreChecked = New-Object System.Windows.Forms.Button
$ignoreChecked.Text = "Ignore checked and continue"
$ignoreChecked.Location = New-Object System.Drawing.Size(5,365)
$ignoreChecked.Size = New-Object System.Drawing.Size(200,20)
$ignoreChecked.Add_Click({$selectForm.Close(); $script:terminate = $false})
$selectForm.Controls.Add($ignoreChecked)
$selectForm.Add_Shown({$selectForm.Activate()})
# Continue with found accesses form
$continueForm = New-Object System.Windows.Forms.Form
$continueForm.Text = "Continue?"
$continueForm.Size = New-Object System.Drawing.Size(300,300)
$continueLabel = New-Object System.Windows.Forms.Label
$continueLabel.Size = New-Object System.Drawing.Size(300,20)
$continueForm.Controls.Add($continueLabel)
$continueButton = New-Object System.Windows.Forms.Button
$continueButton.Text = "Continue"
$continueButton.Location = New-Object System.Drawing.Size(5,40)
$continueButton.Size = New-Object System.Drawing.Size(200,20)
$continueButton.Add_Click({$continueForm.Close(); $terminate = $false; return $terminate})
$continueForm.Controls.Add($continueButton)
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Size(5,65)
$cancelButton.Size = New-Object System.Drawing.Size(200,20)
$cancelButton.Add_Click({$continueForm.Close(); $terminate = $True; return $terminate})
$continueForm.Controls.Add($cancelButton)
$continueForm.Add_Shown({$selectForm.Activate()})

### Begin script

# Show info form to get target server, location for new groups, and domain
[void] $infoForm.ShowDialog()
if ($serverField.Text -eq "") {
    $serverField.Text = "localhost"
}
# if the form closed for any reason other than the OK button being pressed, $terminate should be true and we will exit
if ($terminate) {
    exit(0)
}
# if $terminate was set to false because OK button was pressed, reset it to $True for use with the next GUI box
$terminate = $True

# Get a list of shares from target server
try {
    $shares = Get-WmiObject -Class Win32_Share -ComputerName $serverField.Text -ErrorAction Stop
}
catch {
    Write-Output ("Unable to get shares from server " + $serverField.Text)

}

# Begin populating paths from the shares we got from the server
foreach ($share in $shares) {
    if ($share.Path -ne "") {
        $addpath = New-Object psobject -Property @{
            Share = $share.Name
            Path = "\\" + $serverField.Text + "\" + $share.Name
            Child = $false
        }
        [void] $paths.Add($addpath)
        [void] $checkList.Items.Add($addpath.Share)
    }
}

# Show selection form
[void] $selectForm.ShowDialog()
# if the form closed for any reason other than the continue button being pressed, $terminate should be true and we will exit
if ($terminate) {
    exit(0)
}
# if $terminate was set to false because continue button was pressed, reset it to $True for use with the next GUI box
$terminate = $True

# Remove selected items from paths
for ($i = $paths.Count - 1; $i -ge 0; $i--) {
    if ($checkList.CheckedItems.Contains($paths[$i].Share)) {
        $paths.RemoveAt($i)
    }
}
# paths now has the share paths from the server, minues those we checked to ignore

# Add subfolders, if checked
if ($includeSubs.Checked -eq $True) {
    $x = $paths.Count
    for ($i = 0; $i -lt $x; $i++) {
        try {
            $subs = Get-ChildItem -Recurse -Directory $paths[$i].Path
            foreach ($sub in $subs) {
                $addpath = New-Object psobject -Property @{
                    Share = $paths[$i].Share
                    Path = $sub.FullName
                    Child = $True
                }
                [void] $paths.Add($addpath)
            }
        }
        catch {
            Write-Output ("Unable to get all subdirectories for " + $paths[$i])
        }
    }
}
# paths now has the share paths from the server, minus those we checked to ignore, and, if subs was checked, the subfolders of those shares not ignored

# Populate Accesses and Groups
foreach ($path in $paths) {
    $acl = $path.Path | Get-Acl
    foreach ($ace in $acl.Access) {
        if ($ace.IdentityReference -like "*" + $domainField.Text + "*" -and $ace.IsInherited -eq $false) {
            $name = ($ace.IdentityReference -split "\\")[1]
            $adobject = Get-ADObject -Filter {SamAccountName -like $name}
            if ($adobject.ObjectClass -eq "user") {
                if ($ace.FileSystemRights -like '*FullControl*') {
                    $level = "FullControl"
                }
                elseif ($ace.FileSystemRights -like '*Modify*') {
                    $level = "Modify"
                }
                elseif ($ace.FileSystemRights -like '*ReadAndExecute*') {
                    $level = "ReadAndExecute"
                }
                else {
                    $level = "Unknown Permissions"
                }
                if ($ace.AccessControlType -eq "Allow") {
                    $type = "Allow"
                }
                else {
                    $type = "Deny"
                }
                $addaccess = New-Object psobject -Property @{
                    Path = $path.Path
                    Username = $name
                    AccessType = $type
                    AccessLevel = $level
                }
                [void] $accesses.Add($addaccess)
                $addgroup = New-Object psobject -Property @{
                    # Modify how the group name is constructed to your liking
                    Name = $serverField.Text + "-" + ($path.Path -split "\\")[-1] + "-" + $level
                    Path = $path.Path
                    AccessType = $type
                    AccessLevel = $level
                }
                if ($groups.Contains($addgroup) -eq $false) {
                    [void] $groups.Add($addgroup)
                }
            }
        }
    }
}
# we now have collections of access rights granted to individual users which will need to be proccessed into group memberships
# and we have a collection of the groups needed to accomodate equivilant access rights for those individual users

# Show continue form
$continueLabel.Text = "Number of access lines to process: " + $accesses.Count
$terminate = $continueForm.ShowDialog()
# if the form closed for any reason other than the continue button being pressed, $terminate should be true and we will exit
if ($terminate) {
    exit(0)
}

# Create groups, add users to groups, set group permissions in NTFS ACLs, and remove users from NTFS ACLs
foreach ($group in $groups) {
    New-ADGroup -Name $group.Name -DisplayName $group.Name -SamAccountName $group.Name -GroupScope Global -GroupCategory Security -Description ($group.AccessLevel + " NTFS access for " + $group.Path) -Path $grouplocField.Text
    $acl = Get-Acl $group.Path
    $acetoadd = New-Object System.Security.AccessControl.FileSystemAccessRule(($domainField.Text + "\" + $group.Name),$group.AccessLevel,'ContainerInherit,ObjectInherit','None',$group.AccessType)
    $acl.AddAccessRule($acetoadd)
    Set-Acl $group.Path $acl
    foreach ($access in $accesses) {
        if ($access.Path -eq $group.Path -and $access.AccessLevel -eq $group.AccessLevel -and $access.AccessType -eq $group.AccessType) {
            Add-ADGroupMember -Identity $group.Name -Members $access.Username
            $acl = Get-Acl $access.Path
            $x = $acl.Access.Count - 1
            for ($i = $x; $i -ge 0; $i--) {
                if ($acl.Access[$i].IdentityReference -eq $domainField.Text + "\" + $access.Username) {
                    [void] $acl.RemoveAccessRule($acl.Access[$i])
                }
            }
            Set-Acl $access.Path $acl
        }
    }
}
