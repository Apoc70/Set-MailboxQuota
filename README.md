# Set-MailboxQuota.ps1

Set default mailbox and mailbox database quotas per Exchange Server 2013/2016 mailbox or mailbox database

## Description

This script configures the IssueWarning, ProhibitSend and ProhibitSendAndReceive attributes for Exchange Server 2013/2016 databases

## Parameters

### MailboxMaxSize  

Maximum mailbox size (aka Prohibit Send and Receive) in GB

### ProhibitSendPercent

Prohibit send % of maximum mailbox size (default = 90)

### IssueWarningPercent

Issue warning % of maximum mailbox size (default = 80)

### AllDatabases

Apply quotas to all Exchange Server 2013 mailbox databases

### EmailAddress

Email address of user mailbox to apply quotas to

## Examples

``` PowerShell
.\Set-MailboxQuota.ps1 -MaxMailboxSize 1GB -AllDatabases
```

Set all Exchange 2013 databases to 1GB max mailbox size and use default percentage (90%/80%) for prohibit send and issue warning

``` PowerShell
.\Set-MailboxQuota.ps1 -EmailAddress usera@mcsmemail.de -MaxMailboxSize 10GB
```

Set max mailbox size to 10Gb for a dedicated user and use default percentage (90%/80%) for prohibit send and issue warning

## TechNet Gallery

Download and vote at TechNet Gallery

* [https://gallery.technet.microsoft.com/Set-mailbox-quotas-at-c972c3f3](https://gallery.technet.microsoft.com/Set-mailbox-quotas-at-c972c3f3)

## Blog Post

* [https://www.granikos.eu/en/justcantgetenough/PostId/214/set-mailbox-quotas-at-database-or-mailbox-level-the-simple-way](https://www.granikos.eu/en/justcantgetenough/PostId/214/set-mailbox-quotas-at-database-or-mailbox-level-the-simple-way)

## Credits

Written by: Thomas Stensitzki
Stay connected:

* My Blog: [http://justcantgetenough.granikos.eu](http://justcantgetenough.granikos.eu)
* Twitter: [https://twitter.com/stensitzki](https://twitter.com/stensitzki)
* LinkedIn:	[http://de.linkedin.com/in/thomasstensitzki](http://de.linkedin.com/in/thomasstensitzki)
* Github: [https://github.com/Apoc70](https://github.com/Apoc70)

For more Office 365, Cloud Security, and Exchange Server stuff checkout services provided by Granikos

* Blog: [http://blog.granikos.eu](http://blog.granikos.eu)
* Website: [https://www.granikos.eu/en/](https://www.granikos.eu/en/)
* Twitter: [https://twitter.com/granikos_de](https://twitter.com/granikos_de)
