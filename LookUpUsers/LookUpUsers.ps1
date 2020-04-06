[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Look up users"
$objForm.Size = New-Object System.Drawing.Size(600,500) 
$objForm.StartPosition = "CenterScreen"

$PerformLookup = {
    if ($objFirstName.Text -eq "")
    {
        $objFirstName.Text = "*"
    }
    If ($objLastName.Text -eq "")
    {
        $objLastName.Text = "*"
    }
    $QueryResults = Get-ADUser -filter {(givenname -like $objFirstName.Text) -and (surname -like $objLastName.Text)}
    foreach ($i in $QueryResults)
    {
        $objResultsField.Text = $objResultsField.Text + "First Name: " + $i.GivenName + "`n"
        $objResultsField.Text = $objResultsField.Text + "Last Name: " + $i.Surname + "`n"
        $objResultsField.Text = $objResultsField.Text + "Username: " + $i.SamAccountName + "`n"
        $objResultsField.Text = $objResultsField.Text + "Distinguished Name: " + $i.DistinguishedName + "`n"
        $objResultsField.Text = $objResultsField.Text + "Enabled: " + $i.Enabled + "`n"
        $objResultsField.Text = $objResultsField.Text + "`n"
    }
}

$objFirstNameLabel = New-Object System.Windows.Forms.Label
$objFirstNameLabel.Location = New-Object System.Drawing.Size(10,20) 
$objFirstNameLabel.Size = New-Object System.Drawing.Size(80,20) 
$objFirstNameLabel.Text = "First Name:"
$objForm.Controls.Add($objFirstNameLabel) 

$objFirstName = New-Object System.Windows.Forms.TextBox 
$objFirstName.Location = New-Object System.Drawing.Size(95,20) 
$objFirstName.Size = New-Object System.Drawing.Size(210,20) 
$objForm.Controls.Add($objFirstName) 

$objLastNameLabel = New-Object System.Windows.Forms.Label
$objLastNameLabel.Location = New-Object System.Drawing.Size(10,50) 
$objLastNameLabel.Size = New-Object System.Drawing.Size(80,20) 
$objLastNameLabel.Text = "Last Name:"
$objForm.Controls.Add($objLastNameLabel) 

$objLastName = New-Object System.Windows.Forms.TextBox 
$objLastName.Location = New-Object System.Drawing.Size(95,50) 
$objLastName.Size = New-Object System.Drawing.Size(210,20) 
$objForm.Controls.Add($objLastName) 

$LookupButton = New-Object System.Windows.Forms.Button
$LookupButton.Location = New-Object System.Drawing.Size(100,85)
$LookupButton.Size = New-Object System.Drawing.Size(150,23)
$LookupButton.Text = "Look up username"
$LookupButton.Add_Click($PerformLookup)
$objForm.Controls.Add($LookupButton)

$objResultsField = New-Object System.Windows.Forms.RichTextBox
$objResultsField.Location = New-Object System.Drawing.Size(50,130)
$objResultsField.Size = New-Object System.Drawing.Size(490,300)
$objForm.Controls.Add($objResultsField)

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
