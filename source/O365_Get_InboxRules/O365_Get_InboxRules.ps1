﻿#
# Use the following PowerShell script to get an O365 mailboxes inbox rules.  This is a 
# good script to use after an account has been compromised to check for malicious looking inbox
# rules the attacker may have set.
# 
# Dependiences:
#  1) Install the 64-bit version of the Microsoft Online Services Sign-in Assistant:
# 	  	- https://go.microsoft.com/fwlink/p/?LinkId=286152
#  2) Install the MSOnline module
#	  	- Open an administrator-level PowerShell command prompt.
#		- Run the Install-Module MSOnline command
# MS White paper for more detail: https://docs.microsoft.com/en-us/office365/enterprise/powershell/connect-to-office-365-powershell
# 
# Instructions:
# Run script and enter your O365 admin creds
# Enter the primary SMTP of the O365 mailbox in question (EX: jdk63d@mail.missouri.edu)
# Enter q to exit script
# 
# Output: screen
#
# Written By: Josh Hartley
# University of Missouri
#


# load windows form support
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 


function accountInput($formName) {
    
    # Set the size of your form
    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 600
    $Form.height = 200
    $Form.Text = $formName
    $form.StartPosition = 'CenterScreen'
 
    # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font

    # Create input box for account address
    $inputBox = New-Object System.Windows.Forms.TextBox
    $inputBox.Location = '45,25'
    $inputBox.size = '400,400'
    $inputBox.text = "Enter Primary SMTP Address Here"
    $form.Controls.Add($inputBox)
 
    # Add an OK button
    $OKButton = new-object System.Windows.Forms.Button
    $OKButton.Location = '300,100'
    $OKButton.Size = '100,40' 
    $OKButton.Text = 'OK'
    $OKButton.DialogResult=[System.Windows.Forms.DialogResult]::OK
 
    #Add a cancel button
    $CancelButton = new-object System.Windows.Forms.Button
    $CancelButton.Location = '425,100'
    $CancelButton.Size = '100,40'
    $CancelButton.Text = "Quit Search"
    $CancelButton.DialogResult=[System.Windows.Forms.DialogResult]::Cancel
 
    # Add all the Form controls on one line 
    $form.Controls.AddRange(@($inputBox,$OKButton,$CancelButton))
    
    # Assign the Accept and Cancel options in the form to the corresponding buttons
    $form.AcceptButton = $OKButton
    $form.CancelButton = $CancelButton
 
    # Activate the form
    $form.Add_Shown({$form.Activate()})    
    
    # Get the results from the button click
    $dialogResult = $form.ShowDialog()

    $form.Topmost = $true

    # If the OK button is selected run search, else cancel button was selected so quit search
    if ($dialogResult -eq "OK"){
        
        $inputBox.Text

    } else {
        "quit"
    }          
}



# Do while to run authenication
Do {
    
    # set connection vars to NULL
    $UserCredential = $NULL
    $Session = $NULL

    # Get Credentials
    $UserCredential = Get-Credential

    # If credentials were entered, try connection
    If ($UserCredential -ne $NULL) {
        # Import MSOnline Module
        Import-Module MSOnline

        # Open session
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

        Import-PSSession $Session

        # Create a connection to O365
        $Connection = Connect-MsolService –Credential $UserCredential
    }

    # If the Session variable is NULL credentials failed
    If ($Session -eq $NULL -and $UserCredential -ne $NULL) {
        [System.Windows.Forms.MessageBox]::Show('Bad Username or Password','Error')
    }

 # Do until auth has not failed or creds were null (which means user clicked cancel)
} Until (($Session -ne $NULL) -or ($UserCredential -eq $NULL))



# If auth was successful or credentials not NULL, then run main program
If (($Session -ne $NULL) -or ($UserCredential -ne $NULL)) {
	Do {
		$email = accountInput "Get Account Inbox Rules"
	
		if ($email -ne "quit") {
		
			# Get and print inbox rule info:
            $returnedInfo = Get-InboxRule -Mailbox $email | Select-Object Identity, Enabled, Name, Description, ForwardTo, DeleteMessage | Format-List
            
            if ($returnedInfo -ne $NULL) {
                
                $returnedInfo = $returnedInfo | Format-List | Out-String
                Write-Host $returnedInfo
                # display account info
                [System.Windows.Forms.MessageBox]::Show($returnedInfo,'Inbox Rules')

            } else {
                
                $returnedInfo = 'Account Not Found'
                [System.Windows.Forms.MessageBox]::Show($returnedInfo,'Error')

            }
		}

	} Until ( $email -eq "quit")

	#Close session
	Remove-PSSession $Session -ErrorAction $WarningPreference
	Remove-Module MSOnline
}
