<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Subspace Farmer Log Monitor"
##-------------------------------------------------------------------------
##				>>>>>>>>>>> DO NOT MAKE CHANGES below this line <<<<<<<<<<<
##-------------------------------------------------------------------------
##Console Input for User refresh definitions 
$bAutoRefresh = $false
$refreshTimeScaleInSeconds = 20			#Time in seconds (For example...set to 600 if refresh is desired every 10 minutes)
##Other definitions
$bRefreshPage = $true
$bShowWarnings = $false
$bShowRewardDetails = $false
$bShowPlottingDetails = $false
$patternArr = @("Single disk farm","Successfully signed reward hash","plotting", "error" ," WARN ")		#reserved for details section
$singleSectorSize = 1024				#(1024Mib=1GiB)

##functions
#Main process
function main {
	$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$gitVersion = Get-gitNewVersion

	#Get current folder info
	$seperator = "\"
	$currFolderName = fParseStr $pwd.Path $seperator "LAST"
	##Prompt for advanced CLI farmer log filer
	Add-Type -AssemblyName System.Windows.Forms
	$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
		InitialDirectory = [Environment]::GetFolderPath('Desktop') 
		Filter = 'Text (*.txt)|*.txt|Logs (*.log)|*.log'
	}
	$null = $FileBrowser.ShowDialog()
	$logFileName = $FileBrowser.filename
	
	Clear-Host
	#Write-Host $currFolderName
	#
	$hostName = [System.Net.Dns]::GetHostName()
	#
	#Console input for dicord notifications
	$discord_webhook_url = $(Write-Host "Discord server notification url: " -nonewline -ForegroundColor cyan; Read-Host)
	#
	#Console input for User choices on auto-refresh
	$uAutoRefresh = $(Write-Host "Auto Refresh (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uAutoRefresh.ToLower() -eq "y") {$bAutoRefresh = $true}

	if ($bAutoRefresh) {
		# Get original position of cursor
		$originalPosition = $host.UI.RawUI.CursorPosition
		
		$uTimeInputInSeconds = $(Write-Host "Enter time in seconds for auto-refresh (For example...set to 60 if refresh is desired every 1 minute): " -nonewline -ForegroundColor cyan; Read-Host)
		
		$uInputTimeValue = 0
		do {
			$uInputTimeValueValid = [int]::TryParse($uTimeInputInSeconds, [ref]$uInputTimeValue)
			if (-not $uInputTimeValueValid) {
				$clearmsg = " " * ([System.Console]::WindowWidth - 1)  
				[Console]::SetCursorPosition($originalPosition.X, $originalPosition.Y)
				[System.Console]::Write($clearmsg) 
				[Console]::SetCursorPosition($originalPosition.X, $originalPosition.Y)
				Write-Host "Invalid value provided, please try again..." -ForegroundColor red -nonewline				
				$uTimeInputInSeconds = $(Write-Host "Enter time in seconds for auto-refresh (For example...set to 60 if refresh is desired every 1 minute): " -nonewline -ForegroundColor cyan; Read-Host)
			}
		} while (-not $uInputTimeValueValid)
		$refreshTimeScaleInSeconds = [int]$uTimeInputInSeconds
	}
	#Console input for User choices on console for suppressions
	$uShowWarnings = $(Write-Host "Show warnings/errors (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uShowWarnings.ToLower() -eq 'y') {
		$bShowWarnings = $true
	}
	else {
		$bShowWarnings = $false
	}
	$uShowRewardDetails = $(Write-Host "Show reward details (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uShowRewardDetails.ToLower() -eq 'y') {
		$bShowRewardDetails = $true
	}
	else {
		$bShowRewardDetails = $false
	}
	$uShowPlottingDetails = $(Write-Host "Show plotting details (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uShowPlottingDetails.ToLower() -eq 'y') {
		$bShowPlottingDetails = $true
	}
	else {
		$bShowPlottingDetails = $false
	}

	while ($true) {
		if ($bRefreshPage -or $bAutoRefresh) {
			$bRefreshPage = $false
			#
			# get Subspace node and farmer process state
			$oNodeProcess = Get-Process | where {$_.ProcessName -like '*subspace-node*'} -ErrorAction SilentlyContinue
			if (!($oNodeProcess)) {
				$alterText = "Subspace Node status: Stopped, Hostname:" + $hostName
				fSendDiscordNotification $discord_webhook_url $alterText
			}
			else {
				$processPath = $oNodeProcess.path 
				$processFileCreationDate = Get-ChildItem -Path  $processPath | select CreationTime 
				$gitCurrVersionReleaseDate = $gitVersion[1]
				$gitNodeReleasesVerDateDiff = New-TimeSpan -start $processFileCreationDate.CreationTime -end $gitCurrVersionReleaseDate
			}
			$oFarmerProcess = Get-Process | where {$_.ProcessName -like '*subspace-farmer*'} -ErrorAction SilentlyContinue
			if (!($oFarmerProcess)) {
				$alterText = "Subspace Farmer status: Stopped, Hostname:" + $hostName
				fSendDiscordNotification $discord_webhook_url $alterText
			}
			else {
				$processPath = $oFarmerProcess.path 
				$processFileCreationDate = Get-ChildItem -Path  $processPath | select CreationTime 
				$gitCurrVersionReleaseDate = $gitVersion[1]
				$gitFarmerReleasesVerDateDiff = New-TimeSpan -start $processFileCreationDate.CreationTime -end $gitCurrVersionReleaseDate
			}
			Clear-Host

			# check  Subspace node process state
			if ($oNodeProcess) {
				Write-Host "Node status: " -nonewline
				Write-Host "Running" -ForegroundColor green -NoNewline
			}
			else {
				Write-Host "Node status: " -nonewline
				Write-Host "Stopped" -ForegroundColor red -NoNewline
			}

			# get Subspace farmer process state
			if ($oFarmerProcess) {
				Write-Host "                | " -nonewline -ForegroundColor gray
				Write-Host "Farmer status: " -nonewline
				Write-Host "Running" -ForegroundColor green
			}
			else {
				Write-Host "                | " -nonewline -ForegroundColor gray
				Write-Host "Farmer status: " -nonewline
				Write-Host "Stopped" -ForegroundColor red
			}

			if ($null -ne $gitVersion) {
				Write-Host "Node running on latest version? " -nonewline
				if ($gitNodeReleasesVerDateDiff.days -ne 0) {
					Write-Host "No" -NoNewline -ForegroundColor red
				}
				else {
					Write-Host "Yes" -NoNewline -ForegroundColor green
				}
				Write-Host " | " -nonewline -ForegroundColor gray
				Write-Host "Farmer running on latest version? " -nonewline
				if ($gitFarmerReleasesVerDateDiff.days -ne 0) {
					Write-Host "No" -ForegroundColor red
				}
				else {
					Write-Host "Yes" -ForegroundColor green
				}
				#
				Write-Host "---------------------------------------------------------------------------" -ForegroundColor gray
				$currentVersion = $gitVersion[0] -replace "[^.0-9]"
				Write-Host "Latest github advanced CLI version: " -nonewline
				Write-Host "$($gitVersion[0])" -ForegroundColor Green
				Write-Host "---------------------------------------------------------------------------" -ForegroundColor gray
			}
			echo "`n"

			#Build Summary
			$bPlottingStarted = $false
			#
			$allDetailsTextArr = Get-Content -Path $logFileName | Select-String -Pattern "Finished collecting", "Allocated space:", "Directory:", "Single disk farm", "Successfully signed reward hash", "plotting:", "error", " WARN "
			$isNodeSynced = "-"
			$upTimeDisp = "-"
			$diskCount = 0
			$rewardCount = 0
			$diskSizeArr = [System.Collections.ArrayList]@()
			$driveArr = [System.Collections.ArrayList]@()
			$rewardByDiskCountArr = [System.Collections.ArrayList]@()
			$lastRewardTimestampArr = [System.Collections.ArrayList]@()
			$plotSizeByDiskCountArr = [System.Collections.ArrayList]@()
			$replotSizeByDiskCountArr = [System.Collections.ArrayList]@()
			$missesByDiskCountArr = [System.Collections.ArrayList]@()
			#
			$sectorCountByDiskArr = [System.Collections.ArrayList]@()
			$plotSpeedByDiskArr = [System.Collections.ArrayList]@()
			#
			for ($arrPos = 0; $arrPos -lt $allDetailsTextArr.Count; $arrPos++)
			{
				$allDetailsArrText = $allDetailsTextArr[$arrPos].ToString()
				if ($allDetailsArrText.IndexOf("Finished collecting") -ge 0) {
					$seperator = " "
					$startTimePos = $allDetailsArrText.IndexOf($seperator)
					$startTimeUTC = $allDetailsArrText.SubString(0,$startTimePos-1)
					$currDateTime=(GET-DATE)
					$beginDateTime=(Get-Date $startTimeUTC).ToLocalTime()
					$oTS_totalUpTime = New-TimeSpan -start $beginDateTime -end $currDateTime 
					$upTimeDisp = $oTS_totalUpTime.days.ToString()+"d "+$oTS_totalUpTime.hours.ToString()+"h "+$oTS_totalUpTime.minutes.ToString()+"m "+$oTS_totalUpTime.seconds.ToString()+"s"
				}
				elseif ($allDetailsArrText.IndexOf("Single disk farm") -ge 0) {
					$tempArrId = $diskSizeArr.Add(0)
					$tempArrId = $driveArr.Add("-")
					$tempArrId = $rewardByDiskCountArr.Add(0)
					$tempArrId = $lastRewardTimestampArr.Add("-")
					$tempArrId = $plotSizeByDiskCountArr.Add("-")
					$tempArrId = $replotSizeByDiskCountArr.Add("-")
					$tempArrId = $missesByDiskCountArr.Add(0)
					#
					$tempArrId = $sectorCountByDiskArr.Add(0)
					$tempArrId = $plotSpeedByDiskArr.Add(0)
					#
					$diskCount = $diskCount + 1
				}
				elseif ($allDetailsArrText.IndexOf("Allocated space: ") -ge 0) {
					$sizeInfoLabel = "Allocated space: "
					$sizeInfoStartPos = $allDetailsArrText.IndexOf($sizeInfoLabel)
					$sizeInfo = $allDetailsArrText.SubString($sizeInfoStartPos+$sizeInfoLabel.Length,$allDetailsArrText.Length-$sizeInfoLabel.Length-$sizeInfoStartPos)
					$diskSizeArr[$diskCount-1] = $sizeInfo
				}
				elseif ($allDetailsArrText.IndexOf("Directory: ") -ge 0) {
					$driveInfoLabel = "Directory: "
					$driveInfoStartPos = $allDetailsArrText.IndexOf($driveInfoLabel)
					$driveInfoEndPos = $allDetailsArrText.IndexOf("\")
					$driveInfo = $allDetailsArrText.SubString($driveInfoStartPos+$driveInfoLabel.Length,$driveInfoEndPos-$driveInfoLabel.Length-$driveInfoStartPos)
					$driveArr[$diskCount-1] = $driveInfo
				}
				elseif ($allDetailsArrText.IndexOf("Successfully signed reward hash") -ge 0) {
					$rewardCount = $rewardCount + 1
					$diskInfoLabel = "{disk_farm_index="
					$diskInfoStartPos = $allDetailsArrText.IndexOf($diskInfoLabel)
					$diskInfoEndPos = $allDetailsArrText.IndexOf("}")
					$diskNumInfo = $allDetailsArrText.SubString($diskInfoStartPos+$diskInfoLabel.Length,$diskInfoEndPos-$diskInfoLabel.Length-$diskInfoStartPos)
					$rewardByDiskCountArr[$diskNumInfo] = $rewardByDiskCountArr[$diskNumInfo] + 1
					#Write-Host $allDetailsArrText
					$seperator = " "
					$i = $allDetailsArrText.IndexOf($seperator)
					$textPart = $allDetailsArrText.SubString(0,$i)
					$lastRewardTimestampArr[$diskNumInfo] = (Get-Date $textPart).ToLocalTime()
				}
				elseif ($allDetailsArrText.IndexOf("plotting:") -ge 0 -and $allDetailsArrText.IndexOf("Subscribing") -lt 0 -and $allDetailsArrText.IndexOf("sync") -lt 0 ) {
					$isNodeSynced = "Y"
					$bPlottingStarted = $true
					$diskInfoLabel = "{disk_farm_index="
					$diskInfoStartPos = $allDetailsArrText.IndexOf($diskInfoLabel)
					$diskInfoEndPos = $allDetailsArrText.IndexOf("}")
					$diskNumInfo = $allDetailsArrText.SubString($diskInfoStartPos+$diskInfoLabel.Length,$diskInfoEndPos-$diskInfoLabel.Length-$diskInfoStartPos)
					if ($allDetailsArrText.IndexOf("Replotting complete") -ge 0) {
						$plotSizeByDiskCountArr[$diskNumInfo] = "100%"
						$replotSizeByDiskCountArr[$diskNumInfo] = "100%"
					}
					elseif ($allDetailsArrText.IndexOf("Replotting sector") -ge 0) {
						$plotSizeByDiskCountArr[$diskNumInfo] = "100%"
						#
						$plotSizeInfoLabel = "("
						$plotSizeStartPos = $allDetailsArrText.IndexOf($plotSizeInfoLabel)
						$plotSizeEndPos = $allDetailsArrText.IndexOf("%")
						$plotSizeInfo = $allDetailsArrText.SubString($plotSizeStartPos+$plotSizeInfoLabel.Length,$plotSizeEndPos-$plotSizeStartPos)
						$replotSizeByDiskCountArr[$diskNumInfo] = $plotSizeInfo
					}
					else {
						$plotSizeInfoLabel = "("
						$plotSizeStartPos = $allDetailsArrText.IndexOf($plotSizeInfoLabel)
						$plotSizeEndPos = $allDetailsArrText.IndexOf("%")
						$plotSizeInfo = $allDetailsArrText.SubString($plotSizeStartPos+$plotSizeInfoLabel.Length,$plotSizeEndPos-$plotSizeStartPos)
						$plotSizeByDiskCountArr[$diskNumInfo] = $plotSizeInfo
						$replotSizeByDiskCountArr[$diskNumInfo] = "-"
					}
				}
				elseif ($allDetailsArrText.IndexOf("plotting:") -ge 0 -and $allDetailsArrText.IndexOf("Subscribing") -lt 0 -and $allDetailsArrText.IndexOf("not synced") -ge 0 ) {
					$isNodeSynced = "N"
				}
				elseif ($allDetailsArrText.IndexOf(" WARN ") -ge 0 -and $allDetailsArrText.IndexOf("disk_farm_index") -ge 0) {
					$diskInfoLabel = "{disk_farm_index="
					$diskInfoStartPos = $allDetailsArrText.IndexOf($diskInfoLabel)
					$diskInfoEndPos = $allDetailsArrText.IndexOf("}")
					$diskNumInfo = $allDetailsArrText.SubString($diskInfoStartPos+$diskInfoLabel.Length,$diskInfoEndPos-$diskInfoLabel.Length-$diskInfoStartPos)
					$missesByDiskCountArr[$diskNumInfo] = $missesByDiskCountArr[$diskNumInfo] + 1
				}
			}
			#
			#Get sector and time info for plotting speed calculation
			for ($diskNum = 0; $diskNum -lt $driveArr.Count; $diskNum++) 
			{
				$diskFarmIndexPattern = "{disk_farm_index=" + $diskNum.ToString()
				$allDiskFarmIndexArr = $allDetailsTextArr | Select-String -Pattern $diskFarmIndexPattern
				$allDiskFarmIndexArrSize =  $allDiskFarmIndexArr.Count
				#
				$timeOfLastSector = $null
				$initialSectorNum = 0
				$totalSectorsPlotted = 0
				for ($diskFarmIndexArrPos = 0; $diskFarmIndexArrPos -lt $allDiskFarmIndexArrSize; $diskFarmIndexArrPos++) 
				{
					$diskFarmIndexRow = $allDiskFarmIndexArr[$diskFarmIndexArrPos].ToString()
					if ($diskFarmIndexRow.ToLower().IndexOf("sector_index=") -ge 0 -and $diskFarmIndexRow.ToLower().IndexOf("replotting") -lt 0) {
						$timeElapsedBetweenSectors = 0
						$seperator = " "
						$i = $diskFarmIndexRow.IndexOf($seperator)
						$textPart = $diskFarmIndexRow.SubString(0,$i)
						$timeOfCurrSector = (Get-Date $textPart).ToLocalTime()
						if ($timeOfLastSector -eq $null) { 
							$timeOfLastSector = $timeOfCurrSector
						}
						elseif ($timeOfCurrSector -ne $timeOfLastSector) {
							$timeElapsedBetweenSectors = New-TimeSpan -start $timeOfLastSector -end $timeOfCurrSector
							$timeOfLastSector = $timeOfCurrSector
						}
						$plotSpeedByDiskArr[$diskNum] = $plotSpeedByDiskArr[$diskNum] + $timeElapsedBetweenSectors.TotalSeconds
						#
						$seperator = "sector_index="
						$i = $diskFarmIndexRow.IndexOf($seperator)
						$currSectorNumText = $diskFarmIndexRow.SubString($i+$seperator.Length,$diskFarmIndexRow.Length-$i-$seperator.Length)
						$currSectorNum = [int]$currSectorNumText
						if ($initialSectorNum -eq 0) { 
							$initialSectorNum = $currSectorNum
							$totalSectorsPlotted = $currSectorNum - $initialSectorNum
						}
						elseif ($currSectorNum -ne $initialSectorNum) {
							$totalSectorsPlotted = $currSectorNum - $initialSectorNum
						}
						$sectorCountByDiskArr[$diskNum] = $totalSectorsPlotted
					}
				}
			}
			#
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-Host "                                                      Summary:                                                     " -ForegroundColor green
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-host "Node Synced: " -NoNewline
			Write-host $isNodeSynced -NoNewline -ForegroundColor yellow
			Write-Host "   |   " -nonewline -ForegroundColor gray
			Write-host "Farmer uptime: " -NoNewline
			Write-host $upTimeDisp -NoNewline -ForegroundColor yellow
			Write-Host "   |   " -nonewline -ForegroundColor gray
			Write-Host "Total Rewards: " -nonewline
			Write-Host $rewardCount -ForegroundColor Yellow
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			#Sub-header label definition
			$diskLabel 				= "Disk#"
			$driveLabel 			= "Disk "
			$diskSizeLabel 			= "Space allocated       "
			$rewardLabel 			= "Rewards"
			$missesLabel 			= "Misses"
			$plottingSpeedLabel 	= "Plotting     "
			$plotStatusLabel 		= "Plot   "
			$replotStatusLabel 		= "Replot "
			$lastRewardLabel 		= "Last reward on"
			
			$spacerLabel = " "

			$diskLabel2 			= "     "
			$driveLabel2 			= "label"
			$diskSizeLabel2 		= "                      "
			$rewardLabel2 			= "       "
			$missesLabel2			= "      "
			$plottingSpeedLabel2	= "Speed (MiB/s)"
			$plotStatusLabel2 		= "status "
			$replotStatusLabel2 	= "status "
			$lastRewardLabel2 		= "             "
			
			#Write sub-headers
			#
			#Write-Host (fBuildDynamicSpacer $diskLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $driveLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $diskSizeLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $rewardLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $plotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $replotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $lastRewardLabel.Length "-") -ForegroundColor gray
			Write-Host $diskLabel $spacerLabel $driveLabel $spacerLabel $diskSizeLabel $spacerLabel $rewardLabel $spacerLabel $missesLabel $spacerLabel $plottingSpeedLabel $spacerLabel $plotStatusLabel $spacerLabel $replotStatusLabel $spacerLabel $lastRewardLabel -ForegroundColor cyan
			Write-Host $diskLabel2 $spacerLabel $driveLabel2 $spacerLabel $diskSizeLabel2 $spacerLabel $rewardLabel2 $spacerLabel $missesLabel2 $spacerLabel $plottingSpeedLabel2 $spacerLabel $plotStatusLabel2 $spacerLabel $replotStatusLabel2 $spacerLabel $lastRewardLabel2 -ForegroundColor cyan
			#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-Host (fBuildDynamicSpacer $diskLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $driveLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $diskSizeLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $rewardLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $missesLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $plottingSpeedLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $plotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $replotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $lastRewardLabel.Length "-") -ForegroundColor gray
			for ($arrPos = 0; $arrPos -lt $rewardByDiskCountArr.Count; $arrPos++) {
				$diskText = $arrPos.ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskLabel.Length-$diskText.Length)
				$driveSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$driveText = $driveArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$driveLabel.Length-$driveText.Length)
				$diskSizeSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$diskSizeText = $diskSizeArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskSizeLabel.Length-$diskSizeText.Length)
				$diskRewardSpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				$rewardByDiskText = $rewardByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$rewardLabel.Length-$rewardByDiskText.Length)
				$missesSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$missesByDiskText = $missesByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$missesLabel.Length-$missesByDiskText.Length)
				$plottingSpeedByDiskSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				#$plotSpeedByDiskArr[0]*$singleSectorSize
				$plottingRate = "-"
				if ($plotSpeedByDiskArr[$arrPos] -gt 0) {
					$plottingRate = [math]::Round(($sectorCountByDiskArr[$arrPos] * $singleSectorSize) / $plotSpeedByDiskArr[$arrPos], 2)
				}
				$plottingSpeedByDiskText = $plottingRate.ToString()
				$spacerLength = [int]($spacerLabel.Length+$plottingSpeedLabel.Length-$plottingSpeedByDiskText.Length)
				$plotSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				if ($bPlottingStarted -and $plotSizeByDiskCountArr[$arrPos] -eq "-") {
					$plotSizeByDiskCountArr[$arrPos] = "100%"
				}
				$plotSizeByDiskText = $plotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$plotStatusLabel.Length-$plotSizeByDiskText.Length)
				$replotSpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				$replotSizeByDiskText = $replotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$replotStatusLabel.Length-$replotSizeByDiskText.Length)
				$lastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				Write-Host $diskText $driveSpacerLabel $driveText $diskSizeSpacerLabel $diskSizeText $diskRewardSpacerLabel $rewardByDiskText $missesSpacerLabel $missesByDiskText $plottingSpeedByDiskSpacerLabel $plottingSpeedByDiskText $plotSpacerLabel $plotSizeByDiskText $replotSpacerLabel $replotSizeByDiskText $lastRewardSpacerLabel $lastRewardTimestampArr[$arrPos]
			}

			#Build Details
			$bWarnAndErrHeaderPrinted = $false
			foreach($pattern in $patternArr)
			{
				$bHeaderOther = $false
				$bWarnAndErrHeader = $false
				$subHeaderText = ""
				$subHeaderColor = "green"
				if ($pattern.IndexOf("farm") -ge 0) {
					continue
				}
				elseif ($pattern.IndexOf("reward") -ge 0) {
					$subHeaderText = "Reward"
					if ($bShowRewardDetails -eq $false) {
						continue
					}
					$bHeaderOther = $true
				}
				elseif ($pattern.IndexOf("plotting") -ge 0) {
					$subHeaderText = "Plotting"
					if ($bShowPlottingDetails -eq $false) {
						continue
					}
					$bHeaderOther = $true
				}
				elseif ($pattern.IndexOf("error") -ge 0 -or $pattern.IndexOf(" WARN ") -ge 0) {
					$bWarnAndErrHeader = $true
					if ($bShowWarnings -eq $false) {
						continue
					}
					else {
						$subHeaderText = "Warning and Error"
						$subHeaderColor = "red"
					}
				}
				#
				if ($bHeaderOther -or $bWarnAndErrHeaderPrinted -eq $false) {
					Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
					Write-Host "                                            " $subHeaderText " details:                                     " -ForegroundColor $subHeaderColor
					Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
				}
				if ($bWarnAndErrHeader -and $bWarnAndErrHeaderPrinted -eq $false) {
						$bWarnAndErrHeaderPrinted = $true
				}
				$meaningfulTextArr = $allDetailsTextArr | Select-String -Pattern $pattern
				$textArrSize =  $meaningfulTextArr.Length
				
				$bSkipDisplay = $false
				$bDiskInfoMatchFound = $false
				$bErrMsgInfoMatchFound = $false
				$diskInfoHoldArr = [System.Collections.ArrayList]@()
				$errMsgInfoHoldArr = [System.Collections.ArrayList]@()
				for ($arrIndex =$textArrSize-1;$arrIndex -ge 0; $arrIndex--)
				{
					$dispText = $meaningfulTextArr[$arrIndex].ToString()
					if ($dispText -ne "") {
						if ($dispText.IndexOf("Subscribing") -ge 0) {
							$bSkipDisplay = $true
						}
						elseif ($subHeaderText -eq "Plotting") {
							$diskInfoLabel = "{disk_farm_index="
							$diskInfoStartPos = $dispText.IndexOf($diskInfoLabel)
							$diskInfoHold = $dispText.SubString($diskInfoStartPos,$diskInfoLabel.Length+2)
							$bDiskInfoMatchFound = $false
							foreach($disk in $diskInfoHoldArr)
							{
								if ($diskInfoHold -eq $disk) {
									$bDiskInfoMatchFound = $true
									break
								}
							}							
							if ($bDiskInfoMatchFound -eq $false) {
								$tempArrId = $diskInfoHoldArr.Add($diskInfoHold)
							}
						}
						elseif ($subHeaderText -eq "Warning and Error") {
							if ($dispText.IndexOf("error") -ge 0) {
								$errMsgLable = "{"
								$errMsgStartPos = $dispText.IndexOf($errMsgLable)
								$errMsgEndPos = $dispText.IndexOf("}")
								$errMsgInfoHold = $dispText.SubString($errMsgStartPos+$errMsgLable.Length,$errMsgEndPos-$errMsgLable.Length-$errMsgStartPos)
							}
							else {
								$errMsgLable = " WARN "
								$errMsgStartPos = $dispText.IndexOf($errMsgLable)
								$errMsgInfoHold = $dispText.SubString($errMsgStartPos+$errMsgLable.Length,$dispText.Length-$errMsgStartPos-+$errMsgLable.Length)
							}
							$bErrMsgInfoMatchFound = $false
							foreach($errMsg in $errMsgInfoHoldArr)
							{
								if ($errMsgInfoHold -eq $errMsg) {
									$bErrMsgInfoMatchFound = $true
									break
								}
							}							
							if ($bErrMsgInfoMatchFound -eq $false) {
								$tempArrId = $errMsgInfoHoldArr.Add($errMsgInfoHold)
							}
						}
						#
						if ($bSkipDisplay -eq $false -and $bDiskInfoMatchFound -eq $false -and $bErrMsgInfoMatchFound -eq $false) {
							$seperator = " "
							$i = $dispText.IndexOf($seperator)
							$textPart1 = $dispText.SubString(0,$i)
							$textPart2 = $dispText.SubString($i+1,$dispText.Length-$i-1)
							
							#Write-Host $dispText
							Write-Host (Get-Date $textPart1).ToLocalTime() $textPart2
						}
					}
				}
			}
			
			#Finalize
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			#
			#$currentDate = Get-Date -Format HH:mm:ss
			$currentDate = Get-Date -Format u
			# Refresh
			Write-Host `n                
			Write-Host "Last refresh on: " -ForegroundColor Yellow -nonewline; Write-Host "$currentDate" -ForegroundColor Green;
			#
			####
			## Auto refresh wait cycle
			if ($bAutoRefresh) {
				Write-Host "Auto-refresh scheduled for every " $refreshTimeScaleInSeconds " seconds"
				[System.Console]::CursorVisible = $false
				$iterations = [math]::Ceiling($refreshTimeScaleInSeconds / 5)       
				for ($i = 0; $i -lt $iterations; $i++) {
					Write-Host -NoNewline "." -ForegroundColor Cyan
					Start-Sleep 5
				}
				###### Auto refresh
				$gitNewVersion = Get-gitNewVersion
				if ($gitNewVersion) {
					$gitVersion = $gitNewVersion
				}
				$Stopwatch.Restart()
				######
			}
			else {
				[System.Console]::CursorVisible = $true
				$uRefreshRequest = Read-Host 'Type (R) to refresh, (X) to Exit and press Enter'
				if ($uRefreshRequest.ToLower() -eq 'r') {
					$bRefreshPage = $true
					$gitNewVersion = Get-gitNewVersion
					if ($gitNewVersion) {
						$gitVersion = $gitNewVersion
					}
				}
				elseif ($uRefreshRequest.ToLower() -eq 'x') {
					exit
				}
			}
		}
		else {
			$uRefreshRequest = Read-Host 'Type (R) to refresh, (X) to Exit and press Enter'
			if ($uRefreshRequest.ToLower() -eq 'r') {
				$bRefreshPage = $true
			}
			elseif ($uRefreshRequest.ToLower() -eq 'x') {
				exit
			}
		}
	}
}

function fSendDiscordNotification ([string]$ioUrl, [string]$ioMsg){
	$JSON = @{ "content" = $ioMsg; } | convertto-json
	Invoke-WebRequest -uri $ioUrl -Method POST -Body $JSON -Headers @{'Content-Type' = 'application/json'}
}
function Get-gitNewVersion {
	.{
		$gitVersionArr = [System.Collections.ArrayList]@()
		$gitVersionCurrObj = Invoke-RestMethod -Method 'GET' -uri "https://api.github.com/repos/subspace/subspace/releases/latest" 2>$null
		if ($gitVersionCurrObj) {
			$tempArr_1 = $gitVersionArr.add($gitVersionCurrObj.tag_name)
			$gitNewVersionReleaseDate = (Get-Date $gitVersionCurrObj.published_at).ToLocalTime() 
			$tempArr_1 = $gitVersionArr.add($gitNewVersionReleaseDate)
		}
	}|Out-Null
	return $gitVersionArr
}
function fBuildDynamicSpacer ([int]$ioSpacerLength, [string]$ioSpaceType){
				$dataSpacerLabel = ""
				for ($k=0;$k -lt $ioSpacerLength;$k++) {
					$dataSpacerLabel = $dataSpacerLabel + $ioSpaceType
				}
				return $dataSpacerLabel
}
function fParseStr([string]$ioSourceText, [string]$delimiter, [string]$ioSplitPosition){
	$returnTextValue = $ioSourceText
	$iPos = $ioSourceText.IndexOf($delimiter)
	if ($ioSplitPosition.ToLower() -eq "last") {
		do {
			$returnTextValue = $returnTextValue.SubString($iPos+1,$returnTextValue.Length-$iPos-1)
			$iPos = $returnTextValue.IndexOf($delimiter)
		} while ($iPos -ge 0)
	}
	elseif ($ioSplitPosition.ToLower() -eq "first") {
		$returnTextValue = $returnTextValue.SubString($iPos+1,$returnTextValue.Length-$iPos-1)
	}
	return $returnTextValue
}

main
