# Web/Application Server Watchdog
This script loops through a list of servers and monitors services and application pools (app pools only if IIS/web services are installed).

1. Checks services for "stopped" state and starts them (unless set to disabled/manual start types).
2. Checks application pools for "stopped" state and starts them
3. Sends an email alert to the provided email address via SMTP for both successful and failed start attempts
