::********************************************************************
:: Author: John Urbanek
:: Date: 2008-11-06
:: Script to delete Outlook temporary directory

@ECHO on

C:

CD "%USERPROFILE%\Local Settings\Temporary Internet Files\OLK*"

IF ERRORLEVEL 1 GOTO SKIP_OLK_DEL

DEL /f /s /q *

GOTO END

:SKIP_OLK_DEL

ECHO Outlook Temp Directory Not Found, Skipping Delete Operation

:END

::********************************************************************
