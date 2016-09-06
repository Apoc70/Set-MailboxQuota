# Set-MailboxQuota.ps1
Set default mailbox and mailbox database quotas per Exchange Server 2013/2016 mailbox or mailbox database

##Description
This script configures the IssueWarning, ProhibitSend and ProhibitSendAndReceive attributes for Exchange Server 2013/2016 databases

##Inputs
MailboxMaxSize  
Maximum mailbox size (aka Prohibit Send and Receive) in GB

ProhibitSendPercent
Prohibit send % of maximum mailbox size (default = 90)

IssueWarningPercent
Issue warning % of maximum mailbox size (default = 80)

AllDatabases
Apply quotas to all Exchange Server 2013 mailbox databases

EmailAddress
Email address of user mailbox to apply quotas to

##Outputs
None

##Examples
```
.\Set-MailboxQuota.ps1 -MaxMailboxSize 1GB -AllDatabases
```
et all Exchange 2013 databases to 1GB max mailbox size and use default percentage (90%/80%) for prohibit send and issue warning

```
.\Set-MailboxQuota.ps1 -EmailAddress usera@mcsmemail.de -MaxMailboxSize 10GB
```
Set max mailbox size to 10Gb for a dedicated user and use default percentage (90%/80%) for prohibit send and issue warning

##TechNet Gallery
Find the script at TechNet Gallery
* https://gallery.technet.microsoft.com/Set-mailbox-quotas-at-c972c3f3

##Blog Post
Corresponding blog post
* https://www.granikos.eu/en/justcantgetenough/PostId/214/set-mailbox-quotas-at-database-or-mailbox-level-the-simple-way


##Credits
Written by: Thomas Stensitzki

Stay connected:

* My Blog: http://justcantgetenough.granikos.eu
* Twitter:	https://twitter.com/stensitzki
* LinkedIn:	http://de.linkedin.com/in/thomasstensitzki
* Github:	https://github.com/Apoc70

For more Office 365, Cloud Security and Exchange Server stuff checkout services provided by Granikos

* Blog:     http://blog.granikos.eu/
* Website:	https://www.granikos.eu/en/
* Twitter:	https://twitter.com/granikos_de