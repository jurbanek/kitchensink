:: 2007-06-19 John Urbanek
:: Deletes files from UCEArchive folder older than 14 days

forfiles -p "C:\Program Files\Exchsrvr\Mailroot\vsi 1\UceArchive" -s -d -14 -c "cmd /c del /q @path"
