<#
    .SYNOPSIS
    Set default mailbox quotas per Exchange Server 2013 mailbox
   
    Thomas Stensitzki
	
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
    Version 1.4, 2017-04-20

    Ideas, comments and suggestions to support@granikos.eu 
	
    .DESCRIPTION
	
    This script configures the IssueWarning, ProhibitSend and ProhibitSendAndReceive attributes for Exchange Server 2013 databases.
    Using the -Archive switch configures the mailbox archive properties ArchiveQuota and ArchiveWarningQuota

    .NOTES 
    Requirements 
    - Windows Server 2012R2+
    - Exchange Server 2013+ Managemeht Shell
    - GlobalFunction Librry as desribed here: http://scripts.granikos.eu 

    Revision History 
    -------------------------------------------------------------------------------- 
    1.0 Initial release 
    1.1 Archive support added
    1.2 Refactored to functions
    1.3 PowerShell hygiene
    1.4 Parameters reordered, PowerShell hygiene
	
    .PARAMETER MailboxMaxSize  
    Maximum mailbox size (aka Prohibit Send and Receive) in GB

    .PARAMETER ProhibitSendPercent
    Prohibit send % of maximum mailbox size (default = 90)

    .PARAMETER IssueWarningPercent
    Issue warning % of maximum mailbox size (default = 80). IssueWarningPercent is used to calculate ArchiveWarningQuota as well.

    .PARAMETER AllDatabases
    Apply quotas to all Exchange Server 2013+ mailbox databases

    .PARAMETER EmailAddress
    Email address of user mailbox to apply quotas to

    .PARAMETER Archive
    Switch parameter to configure the archive properties of the mailbox specified using the EmailAddress parameter

    .EXAMPLE
    Set all Exchange databases to 1GB max mailbox size and use default percentage (90%/80%) for prohibit send and issue warning
    .\Set-MailboxQuota.ps1 -MaxMailboxSize 1GB -AllDatabases

    .EXAMPLE
    Set max mailbox size to 10GB for a dedicated user and use default percentage (90%/80%) for prohibit send and issue warning
    .\Set-MailboxQuota.ps1 -EmailAddress usera@mcsmemail.de -MaxMailboxSize 10GB

#>

Param(
  [parameter(ParameterSetName='UserMB',Position=0)]
  [string]$EmailAddress,
  [parameter(Mandatory,HelpMessage='New max mailbox size',ParameterSetName='AllDB')]
  [parameter(Mandatory,ParameterSetName='UserMB')]
  [int64]$MaxMailboxSize,
  [parameter(ParameterSetName='AllDB')]
  [parameter(ParameterSetName='UserMB')]
  [int]$ProhibitSendPercent=90,
  [parameter(ParameterSetName='AllDB')]
  [parameter(ParameterSetName='UserMB')]
  [int]$IssueWarningPercent=80,
  [parameter(ParameterSetName='AllDB')]
  [switch]$AllDatabases,
  [parameter(ParameterSetName='UserMB')]
  [switch]$Archive
)

# IMPORT GLOBAL FUNCTIONS MODULE
Import-Module -Name BDRFunctions

function Request-Choice {
  [CmdletBinding()]
  param([string]$Caption)
  $choices =  [System.Management.Automation.Host.ChoiceDescription[]]@('&Yes','&No')
  [int]$defaultChoice = 1

  $choiceReturn = $Host.UI.PromptForChoice($Caption, '', $choices, $defaultChoice)

  return $choiceReturn   
}

function Set-MailboxUserQuota {
  [CmdletBinding()]
  param(
    [string]$EmailAddress
  )
  try {
    Write-Verbose ('Fetching user mailbox {0}' -f $EmailAddress)

    $UserMailbox = Get-Mailbox -Identity $EmailAddress

    Write-Host

    if(!($Archive)) {
      # Configure user mailbox settings
      Write-Host ('Current quotas of User : {0}' -f $UserMailbox.DisplayName)

      if($UserMailbox.UseDatabaseQuotaDefaults) {
        Write-Host 'User mailbox is set to use DATABASE DEFAULTS!' -ForegroundColor Yellow
      }
      else {
        Write-Host 'User mailbox is set to use mailbox QUOTA OVERRIDES!' -ForegroundColor Yellow
                
        if($UserMailbox.ProhibitSendReceiveQuota -ne 'unlimited') {
          Write-Host ('ProhibitSendReceive [MB]: {0}' -f $UserMailbox.ProhibitSendReceiveQuota.Value.ToMB())
          Write-Host ('Prohibit Send Size  [MB]: {0}' -f $UserMailbox.ProhibitSendQuota.Value.ToMB())
          Write-Host ('Issue Warning Size  [MB]: {0}' -f $UserMailbox.IssueWarningQuota.Value.ToMB())
        }
        else {
          Write-Host 'User mailbox is set to unlimited quota'
        }
      }

      if((Request-Choice -Caption ('Do you want to change the quotas of mailbox {0}?' -f $UserMailbox.DisplayName)) -eq 0) {
        # Set user mailbox quotas
        Write-Host ('Setting selected quotas for mailbox {0}' -f $UserMailbox.DisplayName)

        $logger.Write(('Setting mailbox {0} to ProhibitSendReceive {1}MB, Prohibit Send Size {2}MB, Issue Warning Size {3}MB' -f $EmailAddress, $ProhibitSendReceiveSize, $ProhibitSendSize, $IssueWarningSize))

        $null = Get-Mailbox -Identity $EmailAddress | Set-Mailbox -IssueWarningQuota ('{0}MB' -f $IssueWarningSize) -ProhibitSendQuota ('{0}MB' -f $ProhibitSendSize) -ProhibitSendReceiveQuota ('{0}MB' -f $ProhibitSendReceiveSize) -UseDatabaseQuotaDefaults:$false
      }
      else {
        # user selected 'N'
        Write-Host 'Nothing changed!'
      }
    }  
  }
  catch {
    Write-Error -Message 'Error fetching mailbox data. Please verify email address.'
  }
}

function Set-ArchiveQuota {
  [CmdletBinding()]
  param(
    [string]$EmailAddress
  )
  try {
    Write-Verbose ('Fetching user mailbox {0}' -f $EmailAddress)

    $UserMailbox = Get-Mailbox -Identity $EmailAddress

    # Configure user mailbox archive settings
    Write-Host ('Current archive quotas of User : {0}' -f $UserMailbox.DisplayName)
    if($UserMailbox.ArchiveQuota.IsUnlimited -ne $true) {
      Write-Host ('Archive Quota Size         [MB]: {0}' -f $UserMailbox.ArchiveQuota.Value.ToMB())
    }
    else {
      Write-Host 'Archive Quota Size         [MB]: Unlimited'
    }
    if($UserMailbox.ArchiveWarningQuota.IsUnlimited -ne $true) {
      Write-Host ('Archive Warning Quota Size [MB]: {0}' -f $UserMailbox.ArchiveWarningQuota.Value.ToMB())
    }
    else {
      Write-Host 'Archive Warning Quota Size [MB]: Unlimited'
    }
    if((Request-Choice -Caption ('Do you want to change the archive quotas of mailbox {0}?' -f $UserMailbox.DisplayName)) -eq 0) {
      # Set user mailbox archive quotas
      Write-Host ('Setting selected archive quotas for mailbox {0}' -f $UserMailbox.DisplayName)
                
      $logger.Write(('Setting archive {0} to ArchiveQuota {1}MB, ArchiveWarningQuota {2}MB' -f $EmailAddress, $ProhibitSendReceiveSize, $IssueWarningSize))

      $null = Get-Mailbox -Identity $EmailAddress | Set-Mailbox -ArchiveWarningQuota "$($IssueWarningSize)MB" -ArchiveQuota ('{0}MB' -f $ProhibitSendReceiveSize)
    }
    else {
      # user selected 'N'
      Write-Host 'Nothing changed!'
    }
  }
  catch {
    Write-Error -Message 'Error fetching mailbox data. Please verify email address.'
  }
}

# IMPORT GLOBAL FUNCTIONS MODULE
Import-Module -Name BDRFunctions

$ScriptDir = Split-Path -Path $script:MyInvocation.MyCommand.Path
$ScriptName = $MyInvocation.MyCommand.Name
$logger = New-Logger -ScriptRoot $ScriptDir -ScriptName $ScriptName -LogFileRetention 14
$logger.Write('Script started')

$ProhibitSendReceiveSize = [System.ValueType]([math]::Round(($MaxMailboxSize / 1MB)))
$ProhibitSendSize = [System.ValueType]([math]::Round((($MaxMailboxSize * ($ProhibitSendPercent / 100)) / 1MB)))
$IssueWarningSize = [System.ValueType]([math]::Round((($MaxMailboxSize * ($IssueWarningPercent / 100)) / 1MB)))

Write-Host

if(!($Archive)) {
  # Display new quota settings for user mailbox
  Write-Host 'New Quotas:'
  Write-Host ('ProhibitSendReceive[MB]: {0}' -f $ProhibitSendReceiveSize) 
  Write-Host ('Prohibit Send [%]: {0}' -f $ProhibitSendPercent)
  Write-Host ('Prohibit Send Size [MB]: {0}' -f $ProhibitSendSize)
  Write-Host ('Issue Warning [%]: {0}' -f $IssueWarningPercent)
  Write-Host ('Issue Warning Size [MB]: {0}' -f $IssueWarningSize)
}
else {
  # Display new quota settings for user mailbox archive
  Write-Host 'New Archive Quotas:'
  Write-Host ('Archive Quota Size   [MB]: {0}' -f $ProhibitSendReceiveSize)
  Write-Host ('Archive Warning [%]: {0}' -f $IssueWarningPercent)
  Write-Host ('Archive Warning Size [MB]: {0}' -f $IssueWarningSize)
}

if($AllDatabases) {

  if((Request-Choice -Caption 'Do you want to change the quotas of ALL mailbox databases?') -eq 0) {

    Write-Host 'Setting selected quotas for all mailbox databases!' 

    $logger.Write(('Setting all Exchange mailbox databases to ProhibitSendReceive {0}MB, Prohibit Send Size {1}MB, Issue Warning Size {2}MB' -f $ProhibitSendReceiveSize, $ProhibitSendSize, $IssueWarningSize))

    # fetch only NON recovery databases
    $null = Get-MailboxDatabase | Where-Object{$_.Recovery -eq $false} | Set-MailboxDatabase -IssueWarningQuota ('{0}MB' -f $IssueWarningSize) -ProhibitSendQuota ('{0}MB' -f $ProhibitSendSize) -ProhibitSendReceiveQuota ('{0}MB' -f $ProhibitSendReceiveSize)
  } 
  # Exit  
  Exit 0
}

if(![string]::IsNullOrWhiteSpace($EmailAddress)) {
  try {

    Write-Verbose ('Fetching user mailbox {0}' -f $EmailAddress)

    $UserMailbox = Get-Mailbox -Identity $EmailAddress

    Write-Host

    if(!($Archive)) {
      Set-MailboxUserQuota -EmailAddress $EmailAddress
    }
    else { 
      Set-ArchiveQuota -EmailAddress $EmailAddress
    }
  }
  catch {
    # mailbox not found
    Write-Error 'Error fetching mailbox data. Please verify email address!'
  }
}

Write-Host 'Script finished!'
$logger.Write('Script finished')