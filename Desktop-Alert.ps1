#*****This Powershell Script draws a GUI. Users can choose an option from a listbox and click the 'Submit' button, and the results get emailed (Assuming you are using MS Exchange) to an email address that you specify.*****

# Calling the classes for drawing up Windows forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Drawing the main form using x,y coordinates and giving the form a name
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select a Category'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

# Drawing the 'OK' Button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'Submit'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

# Drawing the 'Cancel' Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

# Drawing the label for the selection listbox
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select a category:'
$form.Controls.Add($label)

# Drawing the listbox and adding the items
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

[void] $listBox.Items.Add('Issue 1')
[void] $listBox.Items.Add('Issue 2')
[void] $listBox.Items.Add('Issue 3')
[void] $listBox.Items.Add('Issue 4')
[void] $listBox.Items.Add('Other')

# Adding the listbox to the form and making it the focused window
$form.Controls.Add($listBox)
$form.Topmost = $true
$result = $form.ShowDialog()

# If the user chooses 'Other' from the listbox, the script asks the user to free-type a description of the issue they are having, otherwise, if they choose another option, it will just email that selected option to the email address specified.
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
		if ($listBox.SelectedItem -eq "Other")
		{
			$OtherPrompt = Read-Host 'Please enter a brief description of the issue and press "Enter"'
			$compname = hostname
			$FromAddress = "ComputerAlert@company.com" #As long as you are using MS Exchange, it allows for anonymous emails from a made up address
			$ToAddress = "support@company.com" #Your organization's IT Support email address
			$SendingServer = "smtp.company.com" #Your organization's SMTP server
			$SMTPMessage = New-Object System.Net.Mail.MailMessage $FromAddress, $ToAddress, $compname, $OtherPrompt #Builds the email message to include the computer name and the user selection
			$SMTPClient = New-Object System.Net.Mail.SMTPClient $SendingServer
			$SMTPClient.Send($SMTPMessage)
		}
        else {
        $compname = hostname
		$FromAddress = "ComputerAlert@company.com" #As long as you are using MS Exchange, it allows for anonymous emails from a made up address
		$ToAddress = "support@company.com" #Your organization's IT Support email address
		$SendingServer = "smtp.company.com" #Your organization's SMTP server
        $SMTPMessage = New-Object System.Net.Mail.MailMessage $FromAddress, $ToAddress, $compname, $x #Builds the email message to include the computer name and the user selection
        $SMTPClient = New-Object System.Net.Mail.SMTPClient $SendingServer
        $SMTPClient.Send($SMTPMessage)
        }
}