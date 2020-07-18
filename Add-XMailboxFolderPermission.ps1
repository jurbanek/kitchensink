function Add-XMailboxFolderPermission {
   <#
   .SYNOPSIS
   Within Exchange Online, apply multiple access rights for multiple source user(s) on multiple target identity(s)
   .DESCRIPTION
   The 'X' is for 'multi'. Within Exchange Online, apply multiple access rights for multiple source user(s) on multiple target identity(s)
   Identity parameter, User parameter, and AccessRights parameter all accept array input. The resulting operations are foiled/multiplied out.
   Will make use of existing remote PSSession to Exchange Online if exists. If not, will create a remote PSSession to Exchange Online.
   .PARAMETER Identity
   Identity parameter specifies the target mailbox and folder. The syntax is <Mailbox>:\<Folder>. For the value of <Mailbox>, you can use any value that uniquely identifies the mailbox.

   For example:
   * Name
   * Display name
   * Alias
   * Distinguished name (DN)
   * Canonical DN
   * <domain name>\<account name>
   * Email address
   * GUID
   * LegacyExchangeDN
   * SamAccountName
   * User ID or user principal name (UPN)

   Example values for the Identity parameter are Alice.Foo:\Calendar or Bob.Bar@acme.com:\Marketing\Reports.
   .PARAMETER IdentitySuffix
   IdentitySuffix parameter is appended verbatim to each Identity parameter as a nicety. The idea is to, optionally, make the <Mailbox>:\<Folder> string build easier.

   For example:
      -Identity "Alice.Foo","Bob.Bar" -IdentitySuffix ":\Calendar"
   Results in the following identities being operated on:
      "Alice.Foo:\Calendar"
      "Bob.Bar:\Calendar"

   Given the IdentitySuffix parameter is optional, be cautious when using IdentitySuffix with an already valid <Mailbox>:\<Folder> for Identity.

   For example:
      -Identity "Alice.Foo:\Calendar","Bob.Bar:\Calendar" -IdentitySuffix ":\Calendar"
   Results in the following INVALID identities
      "Alice.Foo:\Calendar:\Calendar"
      "Bob.Bar:\Calendar:\Calendar"
   .PARAMETER User
   User parameter specifies who's granted permission to the mailbox folder. Valid values are mail-enabled security principals (mail-enabled accounts or groups that have security identifiers or SIDs that can have permissions assigned to them).
      
   For example:
   * User mailboxes
   * Mail users
   * Mail-enabled security groups
   You can use any value that uniquely identifies the user or group.

   For example:
   * Name
   * Display name
   * Alias
   * Distinguished name (DN)
   * Canonical DN
   * Email address
   * GUID
   .PARAMETER AccessRight
   The AccessRight parameter specifies the permissions that you want to add for the user on the mailbox folder.

   You can specify individual folder permissions or roles, which are combinations of permissions. You can specify multiple permissions and roles separated by commas.

   The following individual permissions are available:
   * CreateItems: The user can create items within the specified folder.
   * CreateSubfolders: The user can create subfolders in the specified folder.
   * DeleteAllItems: The user can delete all items in the specified folder.
   * DeleteOwnedItems: The user can only delete items that they created from the specified folder.
   * EditAllItems: The user can edit all items in the specified folder.
   * EditOwnedItems: The user can only edit items that they created in the specified folder.
   * FolderContact: The user is the contact for the specified public folder.
   * FolderOwner: The user is the owner of the specified folder. The user can view the folder, move the move the folder, and create subfolders. The user can't read items, edit items, delete items, or create items.
   * FolderVisible: The user can view the specified folder, but can't read or edit items within the specified public folder.
   * ReadItems: The user can read items within the specified folder.

   The roles that are available, along with the permissions that they assign, are described in the following list:
   * Author:CreateItems, DeleteOwnedItems, EditOwnedItems, FolderVisible, ReadItems
   * Contributor:CreateItems, FolderVisible
   * Editor:CreateItems, DeleteAllItems, DeleteOwnedItems, EditAllItems, EditOwnedItems, FolderVisible, ReadItems
   * None:FolderVisible
   * NonEditingAuthor:CreateItems, FolderVisible, ReadItems
   * Owner:CreateItems, CreateSubfolders, DeleteAllItems, DeleteOwnedItems, EditAllItems, EditOwnedItems, FolderContact, FolderOwner, FolderVisible, ReadItems
   * PublishingEditor:CreateItems, CreateSubfolders, DeleteAllItems, DeleteOwnedItems, EditAllItems, EditOwnedItems, FolderVisible, ReadItems
   * PublishingAuthor:CreateItems, CreateSubfolders, DeleteOwnedItems, EditOwnedItems, FolderVisible, ReadItems
   * Reviewer:FolderVisible, ReadItems

   The following roles apply specifically to calendar folders:
   * AvailabilityOnly: View only availability data
   * LimitedDetails: View availability data with subject and location
   .PARAMETER Credential
   Remote PSSession credentials. If not specified and required, will be prompted.

   Not required at all (will not be prompted either) if an existing PSSession is detected.
   .PARAMETER WhatIf
   Supports WhatIf parameter. No changes will be made to target identity. PSSession is created and removed.
   .NOTES
   Debug parameter for detailed diagnostics. Debug and WhatIf can be combined.
   .INPUTS
   System.String
   You can pipe target identities to this cmdlet.
   .OUTPUTS
   None
   .EXAMPLE
   PS> Add-XMailboxFolderPermission -Identity "Alice.Foo","Bob.Bar" -IdentitySuffix ":\Calendar" -User "Charlie.Baz" -AccessRight "Reviewer" 
      and
   PS> Add-XMailboxFolderPermission -Identity "Alice.Foo:\Calendar,"Bob.Bar:\Calendar" -User "Charlie.Baz" -AccessRight "Reviewer" 
         
   Are equivalent and demonstrate the -IdentitySuffix parameter.
   .EXAMPLE
   PS> Add-XMailboxFolderPermission -Identity "Alice.Foo","Bob.Bar" -IdentitySuffix ":\Calendar" -User "Charlie.Baz","David.Qux" -AccessRight "FolderVisible","ReadItems" 

   Example with multiple source users applying multiple access rights to multiple target identities.
   Source users "Charlie.Baz" and "David.Qux" will be granted "FolderVisible" and "ReadItems" access rights to target identities "Alice.Foo:\Calendar" and "Bob.Bar:\Calendar"
   .EXAMPLE
   PS> Get-Mailbox | Add-XMailboxFolderPermission -User "Alice.Foo","Bob.Bar" -IdentitySuffix ":\Calendar" -AccessRight "Reviewer"

   Grants source users "Alice.Foo" and "Bob.Bar" the "Reviewer" access right to all Mailbox calendars (piped via pipeline) in the organization.
      
   Demonstrates pipeline input, but not an administratively recommended example.
   #>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='None')]
   param(
      [parameter(
         Position=0,
         ValueFromPipeline=$true,
         Mandatory=$true,
         HelpMessage='Target mailbox(s) and folder. Accepts array input. Consider using IdentitySuffix when passing multiple Identity')]
      [String[]] $Identity,
      [parameter(
         Mandatory=$true,
         HelpMessage='Source user(s) to have permissions applied to target identity mailbox(s) and folder. Accepts array input')]
      [String[]] $User,
      [parameter(
         Mandatory=$true,
         HelpMessage='Specifies permission(s) to add for the source User(s) on the target Identity mailbox(s) folder. Accepts array input')]
      [String[]] $AccessRight,
      [parameter(
         Mandatory=$false,
         HelpMessage='Appended verbatim to each Identity')]
      [String] $IdentitySuffix,
      [parameter(
         Mandatory=$false,
         HelpMessage='Remote PSSession credentials. If not specified and required, will be prompted')]
      [PSCredential] $Credential
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
      Write-Debug ($MyInvocation.MyCommand.Name + ': Begin block start')

      # Verify whether an existing Session already exists by
      # 1) checking for existing PSSession with Exchange specific configuration name
      # 2) checking for the Add-MailboxFolderPermission command to ensure the session has been imported
      if(((Get-PSSession | Where-Object { $_.ConfigurationName -eq 'Microsoft.Exchange'} ).Count -gt 0) -and
         [bool](Get-Command -Name Add-MailboxFolderPermission)) {
         
         Write-Debug ($MyInvocation.MyCommand.Name + ': Using existing PSSession')
         $ExistingPSSession = $true
      }
      else {
         Write-Debug ($MyInvocation.MyCommand.Name + ': No existing PSSession found. Will create one.')
         $ExistingPSSession = $false

         # Verify WinRM exists and 'basic' authentication is enabled
         if(-not [bool](Get-Command -Name 'winrm' -ErrorAction SilentlyContinue)) {
            Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error. No changes made.')
            $Emsg = "WinRM not found. Platform not supported."
            Write-Error -Message $Emsg -ErrorAction Stop
         }
         else {
            # WinRM exists, now confirm WinRM 'basic' authentication is enabled
            # $Result will be an array of Strings, which we will screen scrape
            $Result = Invoke-Expression -Command 'winrm get winrm/config/client/auth'
            # Seed $Found as false
            $BasicEnabled = $false
            # Iterate through result and look for match
            foreach($Entry in $Result) {
               if( $Result -match "Basic = true") {
                  Write-Debug ($MyInvocation.MyCommand.Name + ": Confirmed WinRM 'basic' authentication is enabled")
                  $BasicEnabled = $true
                  break
               }
            }

            # If 'basic' authentication not enabled, errors will occur when we attempt remote PSSession. Error out now
            if(-not $BasicEnabled) {
               Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error. No changes made.')
               Write-Warning ($MyInvocation.MyCommand.Name + ': To enable WinRM basic authentication, as administrator: winrm set winrm/config/client/auth @{Basic="true"}')
               $Emsg = "WinRM 'basic' authentication not enabled."
               Write-Error -Message $Emsg -ErrorAction Stop
            }
         }

         # Establish remote PSSession
         Try {
            if(-not $PSBoundParameters['Credential']) {
               Write-Warning ($MyInvocation.MyCommand.Name + ': Credentials required and not provided. Please respond.')
               $Credential = Get-Credential
            }
            else {
               $Credential = $PSBoundParameters['Credential']
            }
            $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection -ErrorAction Stop
         }
         Catch {
            Write-Warning ($MyInvocation.MyCommand.Name + ': Caught exception. Halting due to error. No changes made.')
            $Emsg = "Unable to establish remote PSSession.`n"
            $Emsg += 'Exception type: ' + $_.Exception.GetType().FullName + "`n"
            $Emsg += 'Exception message: ' + $_.Exception.Message
            # Given we are in 'Begin' block, easy to break out now given 'Process' and 'End' not required
            Write-Error $Emsg -ErrorAction Stop
         }

         # Import remote cmdlets for use locally (use is limited to current session)
         Try {
            # Pipe to Out-Null to reduce screen output
            Import-PSSession -Session $Session -ErrorAction Stop | Out-Null
         }
         Catch {
            Write-Warning ($MyInvocation.MyCommand.Name + ': Caught exception. Halting due to error. No changes made.')
            # Cleanup the PSSession. O365 permits a finite number of active sessions per credential.
            Write-Debug ($MyInvocation.MyCommand.Name + ': Cleanup PSSession')
            Remove-PSSession -Session $Session
            $Emsg = "Unable to import remote PSSession.`n"
            $Emsg += 'Exception type: ' + $_.Exception.GetType().FullName + "`n"
            $Emsg += 'Exception message: ' + $_.Exception.Message
            # Given we are in 'Begin' block, easy to break out now given 'Process' and 'End' not required
            Write-Error $Emsg -ErrorAction Stop
         } # Catch
      } # if

      Write-Debug ($MyInvocation.MyCommand.Name + ': Begin block end')
   } # Begin block

   Process {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Process block start')

      # Turn $AccessRight array into single string, one time, for various messages
      if($PSBoundParameters['AccessRight'].Count -gt 1) {
         $AccessRightToString = [System.String]::Join(', ', $AccessRight)
      }
      else {
         $AccessRightToString = $AccessRight[0]
      }

      # Seed values for outer Write-Progress display
      $IdentityProgressCount = 1
      $IdentityProgressTotal = $PSBoundParameters['Identity'].Count
      # Outer foreach identity "target"
      foreach($IdentityCur in $PSBoundParameters['Identity']) {
         # Append (concatenate) the IdentitySuffix to the current Identity
         $IdentityCurConcat = $IdentityCur + $PSBoundParameters['IdentitySuffix']

         # Seed values for inner Write-Progress display
         $UserProgressCount = 1
         $UserProgressTotal = $PSBoundParameters['User'].Count
         # Inner foreach user "source" to apply to outer "target"
         foreach($UserCur in $PSBoundParameters['User']) {
            $Dmsg = "Target Identity: $IdentityCurConcat"
            $Dmsg += " Source User: $UserCur"
            $Dmsg += " Access Right(s): $AccessRightToString"
            Write-Debug ($MyInvocation.MyCommand.Name + ": $Dmsg") 

            # When -WhatIf is specified, $PSCmdlet.ShouldProcess evaluates to false $false
            # Thus, when "-WhatIf" is specified, the "What if:" output is written to the host and the if() body {} does *not* execute
            if($PSCmdlet.ShouldProcess($IdentityCurConcat, "Add $AccessRightToString for $UserCur")) {
               # Outer Write-Progress
               Write-Progress -Id 1 -Activity "Target Identity ($IdentityProgressCount of $IdentityProgressTotal): $IdentityCurConcat"
               # Inner Write-Progress
               Write-Progress -Id 2 -ParentId 1 -Activity "Source User ($UserProgressCount of $UserProgressTotal): $UserCur on $IdentityCurConcat" -Status $AccessRightToString

               Try {
                  Add-MailboxFolderPermission -Identity $IdentityCurConcat -User $UserCur -AccessRights $PSBoundParameters['AccessRight']
               }
               Catch {
                  Write-Warning ($MyInvocation.MyCommand.Name + ": Caught exception during $Dmsg")
                  # Build error message from existing debug message that captures the current iteration
                  $Emsg = "Error applying $Dmsg`n"
                  $Emsg += 'Exception type: ' + $_.Exception.GetType().FullName + "`n"
                  $Emsg += 'Exception message: ' + $_.Exception.Message
                  Write-Error $Emsg
               } # Catch
            } # if ShouldProcess

            # Incrememt inner Write-Progress counter
            $UserProgressCount++

         } # foreach inner

         # Incrememt outer Write-Progress counter
         $IdentityProgressCount++

      } # foreach outer
      Write-Debug ($MyInvocation.MyCommand.Name + ': Process block end')

   } # Process block

   End {
      Write-Debug ($MyInvocation.MyCommand.Name + ': End block start')

      # Cleanup PSSession only if it was created here. Exchange Online permits a finite number of active sessions per credential.
      if(-not $ExistingPSSession) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Cleanup PSSession')
         # Explicit -WhatIf:$false to ensure cleanup PSSession if it was created earlier, even with an active -WhatIf. Otherwise -WhatIf is passed,
         # session is not cleaned up, and the Exchange Online remote session limit can be reached on subsequent runs.
         Remove-PSSession -Session $Session -WhatIf:$false
      }

      Write-Debug ($MyInvocation.MyCommand.Name + ': End block end')
   } # End block 
} # Function