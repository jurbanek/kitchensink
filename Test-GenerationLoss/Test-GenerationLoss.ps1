# One evening after too many drinks in a townie bar someone claimed the Xerox effect
# (Generation Loss) on computer filesystem file copy. I asserted they did not understand
# one of the foundational disparities between digital and analog systems -- EXACT replication.
# See https://en.wikipedia.org/wiki/Generation_loss
# See https://en.wikipedia.org/wiki/Analog_signal#Noise

$CopyStart = 1
$Copies = 100
$File = 'http3-explained-en.pdf'

# Can't claim credit for this beautiful regex
# https://stackoverflow.com/a/43211246/12254608
if((Test-Path -Path $File) -and $File -match '^(.*?)(\.[^.]*)?$') {
   $Name = $Matches[1]
   $Ext = $Matches[2]

   for($i = $CopyStart;$i -lt ($CopyStart + $Copies);$i++) {
      # First copy - copy from original
      if($i -eq $CopyStart) {
         Copy-Item -Path $File -Destination ($Name + '-' + ('{0:0000}' -f $i) + $Ext)
         Write-Host ($Name + '-' + ('{0:0000}' -f $i) + $Ext)
      }
      # Subsequent copy - copy from previous copy
      else {
         Copy-Item -Path ($Name + '-' + ('{0:0000}' -f ($i - 1)) + $Ext) -Destination ($Name + '-' + ('{0:0000}' -f $i) + $Ext)
         Write-Host ($Name + '-' + ('{0:0000}' -f $i) + $Ext)
      }
   }
   
   # After copies have been created, calculate file hashes. No Xerox effect here...
   Get-ChildItem -Path ($Matches[1] + '*') | Get-FileHash -Algorithm SHA256
}
else {
   Write-Error "$File not found or regular expression failure"
}