$servers = @("server01","server02")

# How long to wait between pings
$interval = 3

#-- function start --#

# function for waiting for the server to come back online
# functions are faster and re-usable
# passes in the server name as a parameter
function waitForOnline {

    param([string]$ComputerName)

    Write-Host "  Waiting for $ComputerName to come back online..."

    # check if the server is offline
    while (-not (Test-Connection -ComputerName $server -Count 1 -Quiet)) {
        Start-Sleep -Seconds $interval
    }

    # the loop breaks when the server is back online
    Write-Host "  $ComputerName is back online."
}
#-- function end --#


# iterate through servers
foreach ($server in $servers) {

    Write-Host "Checking if $server is online..." 

    # check if the server is online, then attempt a reboot
    if (Test-Connection -ComputerName $server -Count 1 -Quiet) {

        Write-Host "$server is online. Rebooting now..."

        # using try...catch to continue gracefully in the event the reboot fails
        # attempt to reboot the server, and if anything goes wrong, stop
        try {
            Restart-Computer -ComputerName $server -Force -ErrorAction Stop
        }
        # output a message that the server could not reboot and continue
        catch {
            Write-Host "  Failed to reboot $server"
            continue
        }

        # wait for server to go offline
        Write-Host "  Waiting for $server to go offline..."

        # sleep while the server is waiting to reboot before continuing
        while (Test-Connection -ComputerName $server -Count 1 -Quiet) {
            Start-Sleep -Seconds $interval
        }

        # call the waitForOnline function
        waitForOnline -ComputerName $server

        Write-Host "$server reboot completed."

    # if the initial online check fails, skip this server
    } else {
        Write-Host "$server is not online. Skipping."
    }
}
