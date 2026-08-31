# start logging
Start-Transcript "path\to\log\file\output.log" -Append

$servers = "server01","server02"

# loop through servers
foreach ($server in $servers) {
    
    # -- START APP POOL CHECKS FOR WEB SERVERS ONLY -- #
	
    # get web servers
    $webCheck = Invoke-Command -ComputerName $server -ScriptBlock {Get-Service -Name "w3svc" -ErrorAction SilentlyContinue}
    
    # loop through web servers
    if ($webCheck) {
        $stoppedAppPools = Invoke-Command -ComputerName $server -ScriptBlock { get-iisapppool | Where-Object {$_.State -ne "Started"} } # filter for downed app pools

        # run if downed app pools are found
        if ($stoppedAppPools) {
            
            # this is mainly for humans, the script does not care about table formats
            # create empty table/array for downed app pools
            $tableStoppedAP = @()

            foreach ($app in $stoppedAppPools) {

                # store downed app pools in a  table...
                $stoppedAP = [pscustomobject]@{
                    "Server Name: "     = $server
                    "App Pool Name: "   = $app.Name
                    "App Pool State: "  = $app.State
                }

                # add each downed app pool as a new row
                $tableStoppedAP += $stoppedAP

                # start the app pools
                start-sleep -Seconds 10
                Invoke-Command -ComputerName $server -ScriptBlock { Start-WebAppPool -Name $using:app.Name }
                Start-Sleep -Seconds 1
            }

            # output stopped app pools to log
            $tableStoppedAP | Format-Table | Out-String
        }

        # create empty table/array for restarted app pools
        $tableStartedAP = @()

        foreach ($app in $stoppedAppPools) {

            # refresh the state of the app pools (this should show 'Started' now)
            $appUpdate = Invoke-Command -ComputerName $server -ScriptBlock { get-iisapppool -Name $using:app.Name }

            # store restarted app pools in a table
            $startedAP = [pscustomobject]@{
                "Server Name: "     = $server
                "App Pool Name: "   = $appUpdate.Name
                "App Pool State: "  = $appUpdate.State
            }

            # add each restarted app pool as a new row
            $tableStartedAP += $startedAP
        }

        # output restarted app pools to log
        $tableStartedAP | Format-Table | Out-String
    }

    # -- END WEB SERVER CHECK -- #

    # -- START SERVICES CHECK FOR ALL SERVERS -- #

    # look for stopped services (change the 'service1*' and 'service2*' to match your service names for your application
    $stoppedServices = Invoke-Command -ComputerName $server -ScriptBlock { Get-Service -Name "service*","service2*" | Where-Object {$_.Status -eq "Stopped" -and $_.StartType -ne "Disabled" -and $_.StartType -ne "Manual" }}

    # run if downed services are found
    if ($stoppedServices) {

        # again...this is mainly for humans, the script does not care about table formats
        # create empty table/array for downed services
        $tableStoppedSVC = @()

        foreach ($service in $stoppedServices) {

            # store downed services in a table
            $stoppedSVC = [pscustomobject]@{
                "Server Name: "    = $server
                "Service Name: "   = $service.Name
                "Service Status: " = $service.Status
            }

            # add each downed service as a row
            $tableStoppedSVC += $stoppedSVC

            # start services
            Start-Sleep -Seconds 10
            Invoke-Command -ComputerName $server -ScriptBlock { Start-Service $using:service }
            Start-Sleep -Seconds 1
        }

        # output stoppe services to log
        $tableStoppedSVC | Format-Table | Out-String

        # create an empty table/array for restarted services
        $tableStartedSVC = @()

        foreach ($service in $stoppedServices) {
            
            # refresh the status of the services
            $serviceUpdate = Invoke-Command -ComputerName $server -ScriptBlock { Get-Service -Name $using:service }

            # store restarted services in a table
            $startedSVC = [pscustomobject]@{
                "Server Name: "    = $server
                "Service Name: "   = $serviceUpdate.Name
                "Service Status: " = $serviceUpdate.Status
            }

            # add each restarted service as a row
            $tableStartedSVC += $startedSVC
        }

        # output started services to log
        $tableStartedSVC | Format-Table | Out-String
    }
}

# if any of the above occurs, then alert the IT team with an email
# email for stopped app pools
if ($stoppedAP) {
    $From = "no_reply@company.com"
    $To = "techsupport@company.com"
    $Subject = "App Pool Alert"
    $Body = "The following app pools were agitated:`n" + ($tableStoppedAP | Format-List | Out-String) + "App Pool Repairs:`n" + ($tableStartedAP | Format-List | Out-String)
    $SMTPServer = "smtp.company.com"
    $SMTPPort = "25"

    Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort
}

# email for stopped services
if ($stoppedSVC) {
    $From = "no_reply@company.com"
    $To = "techsupport@company.com"
    $Subject = "Service Alert"
    $Body = "The following services were agitated:`n" + ($tableStoppedSVC | Format-List | Out-String) + "Service Repairs:`n" + ($tableStartedSVC | Format-List | Out-String)
    $SMTPServer = "smtp.company.com"
    $SMTPPort = "25"

    Send-MailMessage -To $To -From $From -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort
}

# End Logging
Stop-Transcript
