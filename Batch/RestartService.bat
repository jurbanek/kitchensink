:: 2010-11-18 John Urbanek

:: Restarts Trend Micro ID Agent CSC-SSM Integration Service
:: The service itself contains a non-paged pool memory leak that
:: will bring down the box if left unattended.

:: This script will work with services that require lengthy stop
:: times.  "net stop" has a finite timeoute time where if the service
:: has not stopped the command will fail, causing problems with
:: scripting

set servicename="TMIDAgent"

:: Prime the script -- If service is stopped, jump to :start
sc query %servicename% | find /I "STATE" | find "RUNNING"
if errorlevel 1 goto :start

:stop
sc stop %servicename%

:: 10 second sleep
ping 127.0.0.1 -n 10 -w 1000 > nul

:: loop until stopped
sc query %servicename% | find /I "STATE" | find "STOPPED"
if errorlevel 1 goto :stop


:start
sc start %servicename%