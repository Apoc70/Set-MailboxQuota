<#
    .SYNOPSIS
    Set default mailbox quotas per Exchange Server 2013 mailbox
   
   	Thomas Stensitzki
	
	THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
	RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
	Version 1.0, 2015-056-03

    Ideas, comments and suggestions to support@granikos.eu 
	
    .DESCRIPTION
	
    This script configures the IssueWarning, ProhibitSend and ProhibitSendAndReceive attributes for Exchange Server 2013 databases

    .NOTES 
    Requirements 
    - Windows Server 2012 R2  
    - Exchange Server 2013

    Revision History 
    -------------------------------------------------------------------------------- 
    1.0     Initial release 
	
	.PARAMETER MailboxMaxSize  
    Maximum mailbox size (aka Prohibit Send and Receive) in GB

    .PARAMETER ProhibitSendPercent
    Prohibit send % of maximum mailbox size (default = 90)

    .PARAMETER IssueWarningPercent
    Issue warning % of maximum mailbox size (default = 80)

    .PARAMETER AllDatabases
    Apply quotas to all Exchange Server 2013 mailbox databases

    .PARAMETER EmailAddress
    Email address of user mailbox to apply quotas to

    .EXAMPLE
    Set all Exchange 2013 databases to 1GB max mailbox size and use default percentage (90%/80%) for prohibit send and issue warning
    .\Set-MailboxQuota.ps1 -MaxMailboxSize 1GB -AllDatabases

    .EXAMPLE
    Set max mailbox size to 10Gb for a dedicated user and use default percentage (90%/80%) for prohibit send and issue warning
    .\Set-MailboxQuota.ps1 -EmailAddress usera@mcsmemail.de -MaxMailboxSize 10GB

    #>

Param(
    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="AllDB")]
    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="UserMB")]
        [int64]$MaxMailboxSize,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="AllDB")]
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="UserMB")]
        [int]$ProhibitSendPercent=90,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="AllDB")]
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="UserMB")]
        [int]$IssueWarningPercent=80,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="AllDB")]
        [switch]$AllDatabases,
    [parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="UserMB")]
        [string]$EmailAddress
)

function Request-Choice {
    param([string]$Caption)
    $choices =  [System.Management.Automation.Host.ChoiceDescription[]]@("&Yes","&No")
    [int]$defaultChoice = 1

    $choiceReturn = $Host.UI.PromptForChoice($Caption, "", $choices, $defaultChoice)

    return $choiceReturn   
}

Set-StrictMode -Version Latest

# IMPORT GLOBAL MODULE
Import-Module GlobalFunctions

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ScriptName = $MyInvocation.MyCommand.Name
$logger = New-Logger -ScriptRoot $ScriptDir -ScriptName $ScriptName -LogFileRetention 14
$logger.Write("Script started")

$ProhibitSendReceiveSize = [System.ValueType]([math]::Round(($MaxMailboxSize / 1MB)))
$ProhibitSendSize = [System.ValueType]([math]::Round((($MaxMailboxSize * ($ProhibitSendPercent / 100)) / 1MB)))
$IssueWarningSize = [System.ValueType]([math]::Round((($MaxMailboxSize * ($IssueWarningPercent / 100)) / 1MB)))

Write-Host "New Quotas:"
Write-Host "ProhibitSendReceive[MB]: $($ProhibitSendReceiveSize)"
Write-Host "Prohibit Send [%]: $($ProhibitSendPercent)"
Write-Host "Prohibit Send Size [MB]: $($ProhibitSendSize)"
Write-Host "Issue Warning [%]: $($IssueWarningPercent)"
Write-Host "Issue Warning Size [MB]: $($IssueWarningSize)"

if($AllDatabases) {

    if((Request-Choice -Caption "Do you want to change the quotas of all mailbox databases?") -eq 0) {
        Write-Host "Setting selected quotas for all mailbox databases!" 
        $logger.Write("Setting all Exchange 2013 mailbox databases to ProhibitSendReceive $($ProhibitSendReceiveSize)MB, Prohibit Send Size $($ProhibitSendSize)MB, Issue Warning Size $($IssueWarningSize)MB")
        # fetch only NON recovery databases
        Get-MailboxDatabase | ?{$_.Recovery -eq $false} | Set-MailboxDatabase -IssueWarningQuota "$($IssueWarningSize)MB" -ProhibitSendQuota "$($ProhibitSendSize)MB" -ProhibitSendReceiveQuota "$($ProhibitSendReceiveSize)MB"
    }   
    Exit 0
}

if(![string]::IsNullOrWhiteSpace($EmailAddress)) {
    try {

        Write-Verbose "Fetching user mailbox $($EmailAddress)"

        $usermailbox = Get-Mailbox $EmailAddress

        Write-Host
        Write-Host "Current quotas of User : $($usermailbox.DisplayName)"

        if($usermailbox.UseDatabaseQuotaDefaults) {
            Write-Host "User mailbox is set to use DATABASE DEFAULTS!"
        }
        else {
            Write-Host "User mailbox is set to use mailbox QUOTA OVERRIDES!"
            Write-Host "ProhibitSendReceive[MB]: $($usermailbox.ProhibitSendReceiveQuota.Value.ToMB())"
            Write-Host "Prohibit Send Size [MB]: $($usermailbox.ProhibitSendQuota.Value.ToMB())"
            Write-Host "Issue Warning Size [MB]: $($usermailbox.IssueWarningQuota.Value.ToMB())"
        }

        if((Request-Choice -Caption "Do you want to change the quotas of mailbox $($usermailbox.DisplayName)?") -eq 0) {
            Write-Host "Setting selected quotas for mailbox $($usermailbox.DisplayName)"

            $logger.Write("Setting mailbox $($EmailAddress) to ProhibitSendReceive $($ProhibitSendReceiveSize)MB, Prohibit Send Size $($ProhibitSendSize)MB, Issue Warning Size $($IssueWarningSize)MB")

            Get-Mailbox $EmailAddress | Set-Mailbox -IssueWarningQuota "$($IssueWarningSize)MB" -ProhibitSendQuota "$($ProhibitSendSize)MB" -ProhibitSendReceiveQuota "$($ProhibitSendReceiveSize)MB" -UseDatabaseQuotaDefaults:$false
        }

    }
    catch {
        Write-Error "Error fetching mailbox data. Please verify email address!"
    }
}

Write-Host "Script finished!"
$logger.Write("Script finished")