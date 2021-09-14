# Monitors the total percentage of all processors present on the machine and only selects the rows that reach the 90% threshold
Get-Counter '\Processor(_Total)\% Processor Time' -Continuous | select -expand CounterSamples | where {$_.CookedValue -gt 90} |

#Each time the processor utilization reaches 90%, there is an email sent to IT support staff (if your ticketing system monitors the support email address, this will auto-generate a ticket)
ForEach {
    Write-Host $_.CookedValue
    $compname = hostname
    $FromAddress = "ProcessorAlert@company.com"
    $ToAddress = "support@company.com"
    $SendingServer = "smtp.company.com"
    $SMTPMessage = New-Object System.Net.Mail.MailMessage $FromAddress, $ToAddress, $compname, $_.CookedValue
    $SMTPClient = New-Object System.Net.Mail.SMTPClient $SendingServer
    $SMTPClient.Send($SMTPMessage)
}