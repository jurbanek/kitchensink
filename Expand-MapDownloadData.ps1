function Expand-MapDownloadData{
   <#
   .SYNOPSIS
   Map Download Data Processor for 2018 Subuaru Outback Navigation System
   .DESCRIPTION
   Map Download Data Processor for 2018 Subuaru Outback Navigation System

   Download data through Map Download tool at https://subaru-maps.com/
   The tool then needs to write the map data to a USB flash drive which is
      1) extremely slow when writing 12+ GiB of data
      2) problemantic given the reliability of USB flash drives
   
   It is my preference to take the downloaded map data (which comes in 100+ ".chunk" files),
   merge the chunks together, zip extract (expand in PowerShel vernacular), and then copy the contents
   to media of my choosing (not limited to USB flash drives and not written using the Map Download tool).

   This PowerShell function takes an InputPath to the downloaded ".chunk" files and an OutputPath where the extracted
   contents will be placed. The chunk files are commonly located in the users home directory (see example)
   
   For my 2018 Subuaru Outback navigation system, the extracted contents ("update" folder and all children) can be dropped
   into the root of a NTFS formatted filesystem on removable media, plugged into the car via USB, and then the car turned on.

   This PowerShell function is little more than an in-order binary file appender/merger and extracter.
   .Parameter InputPath
   File system path where ".chunk" files are located
   .Parameter OutputPath
   File system path where where merged ".chunk" files and extracted content will be placed
   .Parameter WhatIf
   Supports WhatIf
   .NOTES
   Debug parameter for detailed diagnostics. Debug and WhatIf can be combined.
   .INPUTS
   None (nothing can be piped to this cmdlet)
   .OUTPUTS
   None (nothing is sent down pipeline)
   .EXAMPLE
   PS> Expand-MapDownloadData -InputPath "C:\Users\john\Map Downloader\anVyYmFuZWtAZ21haWwuY29t" -OutputPath "C:\Users\john\Downloads\processed"
   .EXAMPLE
   PS> Expand-MapDownloadData -InputPath ".\relative\path\to\input" -OutputPath "relative\path\to\output"
   Relative paths are supported as well
   #>
   [CmdletBinding(SupportsShouldProcess,ConfirmImpact='None')]
   param(
      [parameter(
         Position=0,
         Mandatory=$true,
         HelpMessage='Input Folder Path')]
      [String] $InputPath,
      [parameter(
         Position=1,
         Mandatory=$true,
         HelpMessage='Output Folder Path')]
      [String] $OutputPath
   )

   Begin {
      # If -Debug parameter, change to 'Continue' instead of 'Inquire'
      if($PSBoundParameters['Debug']) {
         $DebugPreference = 'Continue'
      }
      # If -Debug parameter, announce 
      Write-Debug ($MyInvocation.MyCommand.Name + ':')
      Write-Debug ($MyInvocation.MyCommand.Name + ': Begin block start')

      # Test the InputPath
      if(Test-Path -Path $PSBoundParameters['InputPath'] -PathType Container) {
         $ChunkFiles = Get-ChildItem -Path $PSBoundParameters['InputPath'] -Filter "*.chunk"
         if($ChunkFiles.Length -eq 0 ) {
            Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error. No changes made.')
            $Emsg = "No chunk files found."
            Write-Error -Message $Emsg -ErrorAction Stop
         }
      }
      else {
         Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error. No changes made.')
         $Emsg = "Invalid InputPath. Directory must exist."
         Write-Error -Message $Emsg -ErrorAction Stop
      }

      # Test the OutputPath
      if(-not (Test-Path -Path $PSBoundParameters['OutputPath'] -PathType Container)) {
         Write-Warning ($MyInvocation.MyCommand.Name + ': OutputPath not found. Attempting to create.')
         Try {
            if($PSCmdlet.ShouldProcess($PSBoundParameters['OutputPath'], 'Create new directory')){
               New-Item -Path $PSBoundParameters['OutputPath'] -ItemType Directory -Force | Out-Null
            }
         }
         Catch {
            Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error. No changes made.')
            $Emsg = "Error creating OutputPath."
            Write-Error -Message $Emsg -ErrorAction Stop
         }
      }

      # Determine the filename prefix "39_1.chunk" "39_2.chunk" prefix would be 39_
      $ChunkFilesPrefix = ($ChunkFiles[0].Name.Split('_'))[0] + '_'
      $ChunkFilesCount = $ChunkFiles.Length
      $MergeFileName = 'MergedChunks.zip'
      # Need to fully resolve OutputPath for FileStream operations. FileStream operations fail with relative paths.
      $MergeFilePath = Join-Path -Path (Resolve-Path -Path $PSBoundParameters['OutputPath']) -ChildPath $MergeFileName

      # Remove a pre-existing MergeFile if exists already (if running multiple times)
      if(Test-Path -Path $MergeFilePath) {
         Write-Warning ($MyInvocation.MyCommand.Name + ": Pre-existing MergeFile $MergeFilePath exists. Attempting to remove.")
         Try {
            if($PSCmdlet.ShouldProcess($MergeFilePath, 'Delete file')) {
               Write-Debug ($MyInvocation.MyCommand.Name + ': Removing ' + $MergeFilePath)
               Remove-Item -Path $MergeFilePath -Force
            }
         }
         Catch {
            Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error.')
            $Emsg = "Error removing pre-existing MergeFile $MergeFilePath."
            Write-Host $_.Message
            Write-Error -Message $Emsg -ErrorAction Stop
         }
      }

      # Create the MergeFile FileStream (far faster than using PowerShell Get-Content | Out-File at this scale)
      Try {
         if($PSCmdlet.ShouldProcess($MergeFilePath, 'Create file')) {
            $MergeFileStream = New-Object -TypeName 'System.IO.FileStream' -ArgumentList @(
               $MergeFilePath,
               [System.IO.FileMode]::Create,
               [System.IO.FileAccess]::Write,
               [System.IO.FileShare]::None,
               256KB,   
               [System.IO.FileOptions]::None)
         }
      }
      Catch {
         Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error.')
         $Emsg = "Error creating MergeFile."
         Write-Error -Message $Emsg -ErrorAction Stop
      }

      Write-Debug ($MyInvocation.MyCommand.Name + ': Begin block end')
   } # Begin block

   Process {
      Write-Debug ($MyInvocation.MyCommand.Name + ': Process block start')

      # Iterator $i is used to determine chunk file order. Chunk file names do not sort numerically in the way they must be reassembled
      for($i = 1;$i -le $ChunkFilesCount;$i++) {
         $ChunkFileCur = $ChunkFiles | Where-Object { $_.Name -eq ($ChunkFilesPrefix + $i + '.chunk')}
         if($PSCmdlet.ShouldProcess($ChunkFileCur.Name, "Append to $MergeFileName")){
            Write-Debug ($MyInvocation.MyCommand.Name + ': Processing: ' + $ChunkFileCur.Name)
            Try {
               Write-Progress -Activity 'Merging Chunks' -Status 'Merging' -PercentComplete (($i/$ChunkFilesCount)*100) -CurrentOperation $ChunkFileCur.Name
               $ChunkFileCurStream = New-Object -TypeName 'System.IO.FileStream' -ArgumentList @(
                  $ChunkFileCur.FullName,
                  [System.IO.FileMode]::Open,
                  [System.IO.FileAccess]::Read,
                  [System.IO.FileShare]::Read,
                  256KB,
                  [System.IO.FileOptions]::SequentialScan)
               
               $ChunkFileCurStream.CopyTo($MergeFileStream)
            }
            Catch {
               Write-Warning ($MyInvocation.MyCommand.Name + ': Halting due to error.')
               $ChunkFileCurStream.Dispose()
               $MergeFileStream.Dispose()
               $Emsg = 'Error processing ' + $ChunkFileCur.Name + '. Merge not completed.'
               Write-Error -Message $Emsg -ErrorAction Stop
            }
         } # if Should Process
      } # for

      Write-Debug ($MyInvocation.MyCommand.Name + ': Process block end')

   } # Process block

   End {
      Write-Debug ($MyInvocation.MyCommand.Name + ': End block start')

      if($PSCmdlet.ShouldProcess($MergeFilePath, 'Close file')){
         # Per code above, when -WhatIf is used, the $MergeFileStream will not exist.
         # To avoid errors calling Dispose() on a non-existing FileStream when -WhatIf is used, wrap the file handle close in ShouldProcess as well.
         $MergeFileStream.Dispose()
      }

      if($PSCmdlet.ShouldProcess($MergeFilePath, 'Expand-Archive (extract) to ' + $PSBoundParameters['OutputPath'])) {
         Write-Debug ($MyInvocation.MyCommand.Name + ': Expand (extract) contents of ' + $MergeFilePath + ' to ' + $PSBoundParameters['OutputPath'])
         Expand-Archive -Path $MergeFilePath -DestinationPath $PSBoundParameters['OutputPath'] -Force
      }

      Write-Debug ($MyInvocation.MyCommand.Name + ': End block end')
   } # End block 
} # Function