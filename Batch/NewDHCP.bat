:: 2008-12-04 John Urbanek
::
:: Iterate over Dedicated network adapters and configures their IP,
:: DNS, and WINS to be assigned via DHCP
::
:: Note: This script will change ALL dedicated interfaces, careful before
:: running on servers.  It will handle renamed interfaces.
::
:: This script has no effect on interfaces that are configured for DHCP.

:: Parse output and store dedicated interface names in file.
netsh int show interface | findstr "Dedicated" > test.net

:: Using netsh, set IP, DNS, WINS
for /f "tokens=3*" %%i in (test.net) do netsh int ip set addr "%%i %%j" dhcp
for /f "tokens=3*" %%i in (test.net) do netsh int ip set dns "%%i %%j" dhcp
for /f "tokens=3*" %%i in (test.net) do netsh int ip set wins "%%i %%j" dhcp

:: Delete temporary file
del /q test.net
