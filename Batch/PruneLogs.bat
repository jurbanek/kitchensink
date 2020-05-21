:: 2015-05-10 John Urbanek
:: Adapted from original script to prune Windows log files
:: Run as scheduled task daily

:: /p - Path to start searching
:: /s - Recursively search directories (optional)
:: /m - searchmask, default is '*' (optional)
:: /d - date based selection, see forfiles /? for further help
::	   -30 would be files with lastmod 30 days and older
:: /c - command to execute


forfiles /p "C:\WINDOWS\system32\LogFiles" /s /m "*.log" /d -30 /c "cmd /c del /q @path"
