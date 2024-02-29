<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Subspace Farmer Log Monitor"
##-------------------------------------------------------------------------
##				>>>>>>>>>>> DO NOT MAKE CHANGES below this line <<<<<<<<<<<
##-------------------------------------------------------------------------
##
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
	
	##
	#Prompt user for console input and test initial ping for dicord notification set-up
	$bAlertSkipped = $false
	$alertSetStatusColor = "white"
	$testAlertText = " "
	$discord_webhook_url = $(Write-Host "Discord server notification url: " -nonewline -ForegroundColor cyan; Read-Host)
	##
	#Console choice for user to set and test discord alerts
	if ($discord_webhook_url -eq "" -or $discord_webhook_url -eq $null) {
		$alertSetStatusColor = "yellow"
		$testAlertText = "Info: Discord alert were not set...notifications will be skipped" 
	}
	else {
		$uTestAlertKey = $(Write-Host "Test discord subscription? (Y/N): " -nonewline -ForegroundColor cyan; Read-Host)
		if ($uTestAlertKey.ToLower().IndexOf("y") -eq 0) {
				$alertStatusArr = fTestDiscordPing $hostName $discord_webhook_url
				$bAlertSkipped = $alertStatusArr[1]
				$alertSetStatusColor = $alertStatusArr[2]
				$testAlertText = $alertStatusArr[3]
		}
		else {
				$alertSetStatusColor = "yellow"
				$testAlertText = "Warn: Discord connectivity test skipped, notifications may be missed." 
		}
	}
	Write-Host $testAlertText -ForegroundColor $alertSetStatusColor
	
	##
	#Console choice for User to set auto-refresh
	$uAutoRefresh = $(Write-Host "Auto Refresh (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uAutoRefresh.ToLower().IndexOf("y") -eq 0) {$bAutoRefresh = $true}

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
	#Console choice for User to set detailed data suppression 
	$uShowWarnings = $(Write-Host "Show warnings/errors (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uShowWarnings.ToLower().IndexOf("y") -eq 0) {
		$bShowWarnings = $true
	}
	else {
		$bShowWarnings = $false
	}
	$uShowRewardDetails = $(Write-Host "Show reward details (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uShowRewardDetails.ToLower().IndexOf("y") -eq 0) {
		$bShowRewardDetails = $true
	}
	else {
		$bShowRewardDetails = $false
	}
	$uShowPlottingDetails = $(Write-Host "Show plotting details (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uShowPlottingDetails.ToLower().IndexOf("y") -eq 0) {
		$bShowPlottingDetails = $true
	}
	else {
		$bShowPlottingDetails = $false
	}

	##
	$bNodeAlertSet = $false
	$bFarmerAlertSet = $false
	$nodeAlertStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$farmerAlertStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	#
	#process begins here
	while ($true) {
		if ($bRefreshPage -or $bAutoRefresh) {
			$bRefreshPage = $false
			#
			#check if last discord alert sent was within an hour of start, exception is for first notification that can be sent within this window
			$nodeAlertHoursElapsed = $nodeAlertStopwatch.Elapsed.TotalHours
			if ($nodeAlertHoursElapsed -ge 1) {
				$nodeAlertStopwatch.Restart()
				$bNodeAlertSet = $false
			}
			$farmerAlertHoursElapsed = $farmerAlertStopwatch.Elapsed.TotalHours
			if ($farmerAlertHoursElapsed -ge 1) {
				$farmerAlertStopwatch.Restart()
				$bFarmerAlertSet = $false
			}
			#
			# get Subspace node and farmer process state, send notification if process is stopped/not running
			$oNodeProcess = Get-Process | where {$_.ProcessName -like '*subspace-node*'} -ErrorAction SilentlyContinue
			if (!($oNodeProcess)) {
				$alertText = "Subspace Node status: Stopped, Hostname:" + $hostName
				if ($bNodeAlertSet -eq $false) {
					try {
						fSendDiscordNotification $discord_webhook_url $alertText
					}
					catch {}
					#
					$bNodeAlertSet = $true
				}
			}
			else {
				$processPath = $oNodeProcess.path 
				#$processFileCreationDate = Get-ChildItem -Path  $processPath | select CreationTime 
				$processFileCreationDate = Get-ChildItem -Path  $processPath | select LastWriteTime  
				if ($null -ne $gitVersion) {
					$gitCurrVersionReleaseDate = $gitVersion[1]
					$gitNodeReleasesVerDateDiff = New-TimeSpan -start $processFileCreationDate.LastWriteTime -end $gitCurrVersionReleaseDate
				}
				else {
					$gitNodeReleasesVerDateDiff = New-TimeSpan -start $processFileCreationDate.LastWriteTime -end $processFileCreationDate.LastWriteTime
				}
			}
			$oFarmerProcess = Get-Process | where {$_.ProcessName -like '*subspace-farmer*'} -ErrorAction SilentlyContinue
			if (!($oFarmerProcess)) {
				$alertText = "Subspace Farmer status: Stopped, Hostname:" + $hostName
				if ($bFarmerAlertSet -eq $false) {
					try {
						fSendDiscordNotification $discord_webhook_url $alertText
					}
					catch {}
					#
					$bFarmerAlertSet = $true
				}
			}
			else {
				$processPath = $oFarmerProcess.path 
				#$processFileCreationDate = Get-ChildItem -Path  $processPath | select CreationTime 
				$processFileCreationDate = Get-ChildItem -Path  $processPath | select LastWriteTime 
				if ($null -ne $gitVersion) {
					$gitCurrVersionReleaseDate = $gitVersion[1]
					$gitFarmerReleasesVerDateDiff = New-TimeSpan -start $processFileCreationDate.LastWriteTime -end $gitCurrVersionReleaseDate
				}
				else {
					$gitFarmerReleasesVerDateDiff = New-TimeSpan -start $processFileCreationDate.LastWriteTime -end $processFileCreationDate.LastWriteTime
				}
			}
			Clear-Host

			##
			#Build Summary
			$bPlottingStarted = $false
			#
			$allDetailsTextArr = Get-Content -Path $logFileName | Select-String -Pattern "Finished collecting", "Allocated space:", "Directory:", "Single disk farm", "Successfully signed reward hash", "plotting:", "error", " WARN "
			$isNodeSynced = " - "
			$upTimeDisp = "-"
			$diskCount = 0
			$rewardCount = 0
			$totalSizeAllocated = 0
			$diskSizeArr = [System.Collections.ArrayList]@()
			$gibSizeByDiskArr = [System.Collections.ArrayList]@()
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
					$tempArrId =  $gibSizeByDiskArr.Add(0.0)
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
					#
					$seperator = " ("
					$sizeTextPos = $sizeInfo.IndexOf($seperator)
					$sizeText = $sizeInfo.SubString(0,$sizeTextPos)
					$seperator = " "
					$sizeNumPos = $sizeText.IndexOf($seperator)
					$sizeType = $sizeText.SubString($sizeNumPos+1,$sizeText.Length-$sizeNumPos-1)
					$sizeNum = [decimal]($sizeText.SubString(0,$sizeNumPos))
					$_SizeInGib  = 0.0
					if ($sizeType.ToLower() -eq "tib") {
						$_SizeInGib = $sizeNum * 1024					#convert to GiB
					}
					else {
						$_SizeInGib = $sizeNum							#size already in GiB
					}
					$gibSizeByDiskArrPos = $gibSizeByDiskArr.Count - 1
					$gibSizeByDiskArr[$gibSizeByDiskArrPos] = $_SizeInGib
					$totalSizeAllocated = $totalSizeAllocated + $_SizeInGib
				}
				elseif ($allDetailsArrText.IndexOf("Directory: ") -ge 0) {
					$driveInfoLabel = "Directory: "
					$driveInfoStartPos = $allDetailsArrText.IndexOf($driveInfoLabel)
					$driveInfoEndPos = $allDetailsArrText.IndexOf("\")
					if ($driveInfoEndPos -lt 0) {$driveInfoEndPos = $allDetailsArrText.Length}
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
				elseif ($allDetailsArrText.IndexOf("plotting:") -ge 0 -and $allDetailsArrText.IndexOf("Subscribing") -lt 0 -and $allDetailsArrText.IndexOf("sync") -lt 0 -and $allDetailsArrText.IndexOf("Initial plotting complete") -lt 0) {
					$isNodeSynced = "Yes"
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
						$plotSizeInfo = [decimal]($allDetailsArrText.SubString($plotSizeStartPos+$plotSizeInfoLabel.Length,$plotSizeEndPos-$plotSizeStartPos-1))
						$replotSizeByDiskCountArr[$diskNumInfo] = ([math]::Round($plotSizeInfo, 1)).ToString() + "%"
					}
					else {
						$plotSizeInfoLabel = "("
						$plotSizeStartPos = $allDetailsArrText.IndexOf($plotSizeInfoLabel)
						$plotSizeEndPos = $allDetailsArrText.IndexOf("%")
						$plotSizeInfo = [decimal]($allDetailsArrText.SubString($plotSizeStartPos+$plotSizeInfoLabel.Length,$plotSizeEndPos-$plotSizeStartPos-1))
						$plotSizeByDiskCountArr[$diskNumInfo] = ([math]::Round($plotSizeInfo, 1)).ToString() + "%"
						$replotSizeByDiskCountArr[$diskNumInfo] = "-"
					}
				}
				elseif ($allDetailsArrText.IndexOf("plotting:") -ge 0 -and $allDetailsArrText.IndexOf("Subscribing") -lt 0 -and $allDetailsArrText.IndexOf("not synced") -ge 0 ) {
					$isNodeSynced = "No "
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
			$LastSectorPlottedByDiskArr = @(0) * $driveArr.Count
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
					if ($diskFarmIndexRow.ToLower().IndexOf("sector_index=") -ge 0 -and $diskFarmIndexRow.ToLower().IndexOf("plotting:") -ge 0 -and $diskFarmIndexRow.ToLower().IndexOf("replotting") -lt 0) {
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
				$LastSectorPlottedByDiskArr[$diskNum] = $currSectorNum
			}
			#
			##
			$_label_line_separator = "_"
			$_label_line_separator_upper = [char](8254)			# overline unicode (reverse of underscore)
			#
			##
			#Build overall progress and average sectors processed data 
			$overallProgress = 0
			$avgSectorPerMinute = 0.0
			$avgSectorPerMinuteDiskCount = 0
			$avgMinutesPerSector = 0.0
			$avgTimeInSecondsPerSector = 0.0
			$avgMinutesPerSectorDiskCount = 0
			$plotRateForProgressBar = 0
			$_eta_ByDisk = @(0) * $plotSpeedByDiskArr.Count
			for ($arrPos = 0; $arrPos -lt $plotSpeedByDiskArr.Count; $arrPos++) {
				$sectorPlotRate = "-"
				$minutesPerSector = "-"
				$TimeInSecondsPerSector = 0
				$plottingRate = "-"
				$_eta_ByDisk[$arrPos] = "-"
				if ($plotSpeedByDiskArr[$arrPos] -gt 0) {
					$sectorPlotRate = [math]::Round(($sectorCountByDiskArr[$arrPos] * 3600) / $plotSpeedByDiskArr[$arrPos], 1)
					$minutesPerSector = [math]::Round($plotSpeedByDiskArr[$arrPos] / ($sectorCountByDiskArr[$arrPos] * 60), 1)
					$TimeInSecondsPerSector = [math]::Round($plotSpeedByDiskArr[$arrPos] / $sectorCountByDiskArr[$arrPos], 1)
					$plottingRate = [math]::Round(($sectorPlotRate * $singleSectorSize) / 60, 1)
					#
					#calculation for ETA
					$_sectorsInDisk = $gibSizeByDiskArr[$arrPos] 																							# 1 sector = 1024 GiB and disk size is in GiB
					if ($LastSectorPlottedByDiskArr[$arrPos] -lt $_sectorsInDisk) {
						#$_eta_ByDisk[$arrPos] = [math]::Round(($_sectorsInDisk - $LastSectorPlottedByDiskArr[$arrPos]) / ($sectorPlotRate * 24),2)		# convert ETA to days
						$_eta_ByDisk[$arrPos] = [math]::Round((($_sectorsInDisk - $LastSectorPlottedByDiskArr[$arrPos]) * 3600) / ($sectorPlotRate),2)		# convert ETA to days
					}
					#calculation for average progression
					$avgSectorPerMinute = $avgSectorPerMinute + $sectorPlotRate
					$avgSectorPerMinuteDiskCount = $avgSectorPerMinuteDiskCount + 1
					$avgMinutesPerSector = $avgMinutesPerSector + $minutesPerSector
					$avgTimeInSecondsPerSector = $avgTimeInSecondsPerSector + $TimeInSecondsPerSector
					$avgMinutesPerSectorDiskCount = $avgMinutesPerSectorDiskCount + 1
					#
				}
				if ($bPlottingStarted -and $plotSizeByDiskCountArr[$arrPos] -eq "-") {
					$plotSizeByDiskCountArr[$arrPos] = "100%"
				}
				if ($bPlottingStarted) {
					$plotRateForProgressBar = $plotRateForProgressBar + [double]($plotSizeByDiskCountArr[$arrPos].SubString(0,$plotSizeByDiskCountArr[$arrPos].IndexOf("%")))
				}
			}
			#
			#Build overall progress
			if ($plotSpeedByDiskArr.Count -gt 0) {
				$overallProgress = [math]::Round($plotRateForProgressBar / $plotSpeedByDiskArr.Count, 1)
			}
			#
			#Build averages for sector processed
			$_avgSectorPerMinuteDisp = "-"
			if ($avgSectorPerMinuteDiskCount -gt 0) {
				$_avgSectorPerMinuteDisp = ([math]::Round($avgSectorPerMinute / $avgSectorPerMinuteDiskCount, 1)).ToString()
			}
			#
			$_avgMinutesPerSectorDisp = "-"
			$_avgTimeInSecondsPerSectorDisp = "-"
			if ($avgMinutesPerSectorDiskCount -gt 0) {
				$_avgMinutesPerSectorDisp = ([math]::Round($avgMinutesPerSector / $avgMinutesPerSectorDiskCount, 1)).ToString()
				$_avgTimeInSecondsPerSectorDisp = ([math]::Round($avgTimeInSecondsPerSector / $avgMinutesPerSectorDiskCount, 1))
			}
			#
			##
			# display subspace node process state to console
			if ($oNodeProcess) {
				Write-Host "Node status: " -nonewline
				Write-Host "Running" -ForegroundColor green -NoNewline
			}
			else {
				Write-Host "Node status: " -nonewline
				Write-Host "Stopped" -ForegroundColor red -NoNewline
			}
			# display subspace farmer process state to console
			$_second_block_top_data_spacer = "------------------------------------"
			$_second_block_top_data_spacer_gap =  $_second_block_top_data_spacer.Length - ("Node status: ").Length - ("Running").Length
			$_second_block_top_data_spacer_label = fBuildDynamicSpacer $_second_block_top_data_spacer_gap " "
			$_second_block_top_data_spacer_label = $_second_block_top_data_spacer_label + "| "
			#Write-Host "                | " -nonewline -ForegroundColor gray
			Write-Host $_second_block_top_data_spacer_label -nonewline -ForegroundColor gray
			Write-Host "Farmer status: " -nonewline
			if ($oFarmerProcess) {
				Write-Host "Running" -nonewline -ForegroundColor green
			}
			else {
				Write-Host "Stopped" -nonewline -ForegroundColor red
			}
			# display overall metrics
			$_third_block_top_data_spacer = "--------------------------------------"
			$_third_block_top_data_spacer_gap =  $_third_block_top_data_spacer.Length - ("Farmer status: ").Length - ("Running").Length
			$_third_block_top_data_spacer_label = fBuildDynamicSpacer $_third_block_top_data_spacer_gap " "
			$_third_block_top_data_spacer_label = $_third_block_top_data_spacer_label + "| "
			#Write-Host "                | " -nonewline -ForegroundColor gray
			Write-Host $_third_block_top_data_spacer_label -nonewline -ForegroundColor gray
			Write-Host "Total rewards   : " -nonewline
			#Write-Host $rewardCount -ForegroundColor green
			Write-Host $rewardCount
			#
			# Sync and uptime header info
			Write-host "Node synced: " -NoNewline
			if ($isNodeSynced = "Yes") {
				Write-Host $isNodeSynced -NoNewline -ForegroundColor green
			}
			else {
				Write-Host $isNodeSynced -NoNewline -ForegroundColor red
			}
			$_second_block_top_data_spacer = "------------------------------------"
			$_second_block_top_data_spacer_gap =  $_second_block_top_data_spacer.Length - ("Node synced: ").Length - $isNodeSynced.Length
			$_second_block_top_data_spacer_label = fBuildDynamicSpacer $_second_block_top_data_spacer_gap " "
			$_second_block_top_data_spacer_label = $_second_block_top_data_spacer_label + "| "
			#Write-Host "                    | " -nonewline -ForegroundColor gray
			Write-Host $_second_block_top_data_spacer_label -nonewline -ForegroundColor gray
			Write-host "Farmer uptime: " -NoNewline
			Write-host $upTimeDisp -nonewline -ForegroundColor yellow
			#
			$totalSizeAllocatedTiB = [math]::Round([Math]::Ceiling($totalSizeAllocated*10/1024)/10,1)
			$totalSizeAllocatedTB = [math]::Round([Math]::Ceiling($totalSizeAllocatedTiB*1.1*10)/10,1)
			$_third_block_top_data_spacer = "--------------------------------------"
			$_third_block_top_data_spacer_gap =  $_third_block_top_data_spacer.Length - ("Farmer uptime: ").Length - $upTimeDisp.Length
			$_third_block_top_data_spacer_label = fBuildDynamicSpacer $_third_block_top_data_spacer_gap " "
			$_third_block_top_data_spacer_label = $_third_block_top_data_spacer_label + "| "
			#Write-Host "          | " -nonewline -ForegroundColor gray
			Write-Host $_third_block_top_data_spacer_label -nonewline -ForegroundColor gray
			#Write-Host "Total space allocated: " -nonewline
			Write-Host "Total size      : " -nonewline
			#write-Host $totalSizeAllocatedTiB "TiB ($totalSizeAllocatedTB TB)" -ForegroundColor green
			write-Host ($totalSizeAllocatedTiB.ToString() +"TiB (" + $totalSizeAllocatedTB + "TB)")
			#
			# display running version info
			Write-Host "----------------------------------------------------------------------------" -nonewline -ForegroundColor gray
			Write-Host "| " -nonewline -ForegroundColor gray
			#Write-Host "Overall plotting progress: $overallProgress% complete" -nonewline -BackgroundColor yellow -ForegroundColor black
			Write-Host "% Complete      : $overallProgress%" -nonewline
			Write-Host " "  -ForegroundColor white
			if ($null -ne $gitVersion) {
				Write-Host "Node running on latest version? " -nonewline
				if ($gitNodeReleasesVerDateDiff.days -ne 0) {
					if ($oNodeProcess) {
						Write-Host "No " -NoNewline -ForegroundColor red
					}
					else {
						Write-Host " - " -NoNewline -ForegroundColor red
					}
				}
				else {
					Write-Host "Yes" -NoNewline -ForegroundColor green
				}
				$_second_block_top_data_spacer = "------------------------------------"
				$_second_block_top_data_spacer_gap =  $_second_block_top_data_spacer.Length - ("Node running on latest version? ").Length - ("Yes").Length
				$_second_block_top_data_spacer_label = fBuildDynamicSpacer $_second_block_top_data_spacer_gap " "
				$_second_block_top_data_spacer_label = $_second_block_top_data_spacer_label + "| "
				#Write-Host " | " -nonewline -ForegroundColor gray
				Write-Host $_second_block_top_data_spacer_label -nonewline -ForegroundColor gray
				Write-Host "Farmer running on latest version? " -nonewline
				if ($gitFarmerReleasesVerDateDiff.days -ne 0) {
					if ($oFarmerProcess) {
						Write-Host "No " -nonewline -ForegroundColor red
					}
					else {
						Write-Host " - " -nonewline  -ForegroundColor red
					}
				}
				else {
					Write-Host "Yes" -nonewline -ForegroundColor green
				}
				#
			}
			else {
				Write-Host "Node running on latest version? " -nonewline
				Write-Host " - " -NoNewline -ForegroundColor red
				$_second_block_top_data_spacer = "--------------------------------------"
				$_second_block_top_data_spacer_gap =  $_second_block_top_data_spacer.Length - ("Node running on latest version? ").Length - ("Yes").Length
				$_second_block_top_data_spacer_label = fBuildDynamicSpacer $_second_block_top_data_spacer_gap " "
				$_second_block_top_data_spacer_label = $_second_block_top_data_spacer_label + "| "
				#Write-Host " | " -nonewline -ForegroundColor gray
				Write-Host $_second_block_top_data_spacer_label -nonewline -ForegroundColor gray
				Write-Host "Farmer running on latest version? " -nonewline
				Write-Host " - " -nonewline  -ForegroundColor red
			}
			#
			$_third_block_top_data_spacer = "--------------------------------------"
			$_third_block_top_data_spacer_gap =  $_third_block_top_data_spacer.Length - ("Farmer running on latest version? ").Length - ("Yes").Length
			$_third_block_top_data_spacer_label = fBuildDynamicSpacer $_third_block_top_data_spacer_gap " "
			$_third_block_top_data_spacer_label = $_third_block_top_data_spacer_label + "| "
			#Write-Host " | " -nonewline -ForegroundColor gray
			Write-Host $_third_block_top_data_spacer_label -nonewline -ForegroundColor gray
			Write-Host "Sectors/h (avg) : " -nonewline
			$avgSectorsPerMinuteCursorPosition = $host.UI.RawUI.CursorPosition
			#Write-Host $_avgSectorPerMinuteDisp -ForegroundColor green
			Write-Host $_avgSectorPerMinuteDisp
			#
			# github version info
			$_gitVersionDisp = " - "
			$_gitVersionDispColor = "red"
			if ($null -ne $gitVersion) {
				$currentVersion = $gitVersion[0] -replace "[^.0-9]"
				$_gitVersionDisp = $gitVersion[0]
				$_gitVersionDispColor = "green"
				#Write-Host "$($gitVersion[0])" -nonewline -ForegroundColor Green
			}
			Write-Host "Latest github advanced CLI version  : " -nonewline
			Write-Host "$($_gitVersionDisp)" -nonewline -ForegroundColor $_gitVersionDispColor
			#
			$_third_block_top_data_spacer = "----------------------------------------------------------------------------"
			$_third_block_top_data_spacer_gap =  $_third_block_top_data_spacer.Length - ("Latest github advanced CLI version  : ").Length - $_gitVersionDisp.Length
			$_third_block_top_data_spacer_label = fBuildDynamicSpacer $_third_block_top_data_spacer_gap " "
			$_third_block_top_data_spacer_label = $_third_block_top_data_spacer_label + "| "
			#Write-Host "                 | " -nonewline -ForegroundColor gray
			Write-Host $_third_block_top_data_spacer_label -nonewline -ForegroundColor gray
			Write-Host "Min/sector (avg): " -nonewline
			$avgMinutesPerSectorCursorPosition = $host.UI.RawUI.CursorPosition
			#Write-Host $_avgMinutesPerSectorDisp -ForegroundColor green
			if ($_avgTimeInSecondsPerSectorDisp -ne "-" -and $_avgTimeInSecondsPerSectorDisp -gt 0)
			{
				$_avgTimeInSecondsPerSectorObj = New-TimeSpan -seconds $_avgTimeInSecondsPerSectorDisp
				$__avgTimeInSecondsPerSectorDisp = $_avgTimeInSecondsPerSectorObj.minutes.ToString() + "m " + $_avgTimeInSecondsPerSectorObj.seconds.ToString() + "s"
			}
			else
			{
				$__avgTimeInSecondsPerSectorDisp = "0" + "m " + "0" + "s"
			}
			Write-Host $__avgTimeInSecondsPerSectorDisp




			#
			##Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			#Write-Host "-----------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			$_seperator_line_length = ("-----------------------------------------------------------------------------------------------------------------").Length
			$_seperator_line = fBuildDynamicSpacer $_seperator_line_length $_label_line_separator_upper
			Write-Host $_seperator_line -ForegroundColor gray
			#
			##
			#Write summary header and data table
			echo `n
			#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-Host "                                                  Summary by disk:                                                 " -ForegroundColor cyan
			##Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			#Write-Host "-----------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			$_start_line_length = ("-----------------------------------------------------------------------------------------------------------------").Length
			$_start_line_label = fBuildDynamicSpacer $_start_line_length $_label_line_separator
			Write-Host $_start_line_label -ForegroundColor gray
			#
			#Sub-header label definition
			$diskLabel 				= "Disk"
			$driveLabel 			= "Disk "
			$diskSizeLabel 			= "Space allocated      "
			$rewardLabel 			= "Rewards"
			$missesLabel 			= "Misses"
			$sectorPlotSpeedLabel 	= "Sectors/"
			$minutesPerSectorLabel 	= "Time/  "
			#$plottingSpeedLabel 	= "Plot   "
			$_eta_Label 			= "ETA        "
			$plotStatusLabel 		= "Plot  "
			$replotStatusLabel 		= "Replot"
			$lastRewardLabel 		= "Last reward on        "
			
			$spacerLabel = "|"

			$diskLabel2 			= "#   "
			$driveLabel2 			= "label"
			$diskSizeLabel2 		= "                     "
			$rewardLabel2 			= "       "
			$missesLabel2			= "      "
			$sectorPlotSpeedLabel2 	= "hour    "
			$minutesPerSectorLabel2	= "sector "
			#$plottingSpeedLabel2	= "speed  "
			$_eta_Label2 			= "           "
			$plotStatusLabel2 		= "status"
			$replotStatusLabel2 	= "status"
			$lastRewardLabel2 		= "                      "
			
			#$diskLabel3 			= "    "
			#$driveLabel3 			= "     "
			#$diskSizeLabel3 		= "                     "
			#$rewardLabel3 			= "       "
			#$missesLabel3			= "      "
			#$sectorPlotSpeedLabel3 	= "         "
			#$minutesPerSectorLabel3	= "       "
			##$plottingSpeedLabel3	= "(MiB/m)"
			#$_eta_Label3 			= "           "
			#$plotStatusLabel3 		= "      "
			#$replotStatusLabel3 	= "      "
			#$lastRewardLabel3 		= "                      "
			##
			#Write sub-headers
			#$header = $diskLabel + $spacerLabel + $driveLabel + $spacerLabel + $diskSizeLabel + $spacerLabel + $rewardLabel + $spacerLabel + $missesLabel + $spacerLabel + $sectorPlotSpeedLabel + $spacerLabel + $minutesPerSectorLabel + $spacerLabel + $plottingSpeedLabel + $spacerLabel + $_eta_Label + $spacerLabel + $plotStatusLabel + $spacerLabel + $replotStatusLabel + $spacerLabel + $lastRewardLabel + $spacerLabel
			$header = $diskLabel + $spacerLabel + $driveLabel + $spacerLabel + $diskSizeLabel + $spacerLabel + $rewardLabel + $spacerLabel + $missesLabel + $spacerLabel + $sectorPlotSpeedLabel + $spacerLabel + $minutesPerSectorLabel + $spacerLabel + $_eta_Label + $spacerLabel + $plotStatusLabel + $spacerLabel + $replotStatusLabel + $spacerLabel + $lastRewardLabel + $spacerLabel
			Write-Host $header -ForegroundColor cyan
			#$header = $diskLabel2 + $spacerLabel + $driveLabel2 + $spacerLabel + $diskSizeLabel2 + $spacerLabel + $rewardLabel2 + $spacerLabel + $missesLabel2 + $spacerLabel + $sectorPlotSpeedLabel2 + $spacerLabel + $minutesPerSectorLabel2 + $spacerLabel + $plottingSpeedLabel2 + $spacerLabel + $_eta_Label2 + $spacerLabel + $plotStatusLabel2 + $spacerLabel + $replotStatusLabel2 + $spacerLabel + $lastRewardLabel2 + $spacerLabel
			$header = $diskLabel2 + $spacerLabel + $driveLabel2 + $spacerLabel + $diskSizeLabel2 + $spacerLabel + $rewardLabel2 + $spacerLabel + $missesLabel2 + $spacerLabel + $sectorPlotSpeedLabel2 + $spacerLabel + $minutesPerSectorLabel2 + $spacerLabel + $_eta_Label2 + $spacerLabel + $plotStatusLabel2 + $spacerLabel + $replotStatusLabel2 + $spacerLabel + $lastRewardLabel2 + $spacerLabel
			Write-Host $header -ForegroundColor cyan
			##$header = $diskLabel3 + $spacerLabel + $driveLabel3 + $spacerLabel + $diskSizeLabel3 + $spacerLabel + $rewardLabel3 + $spacerLabel + $missesLabel3 + $spacerLabel + $sectorPlotSpeedLabel3 + $spacerLabel + $minutesPerSectorLabel3 + $spacerLabel + $plottingSpeedLabel3 + $spacerLabel + $_eta_Label3 + $spacerLabel + $plotStatusLabel3 + $spacerLabel + $replotStatusLabel3 + $spacerLabel + $lastRewardLabel3 + $spacerLabel
			#$header = $diskLabel3 + $spacerLabel + $driveLabel3 + $spacerLabel + $diskSizeLabel3 + $spacerLabel + $rewardLabel3 + $spacerLabel + $missesLabel3 + $spacerLabel + $sectorPlotSpeedLabel3 + $spacerLabel + $minutesPerSectorLabel3 + $spacerLabel + $_eta_Label3 + $spacerLabel + $plotStatusLabel3 + $spacerLabel + $replotStatusLabel3 + $spacerLabel + $lastRewardLabel3 + $spacerLabel
			#Write-Host $header -ForegroundColor cyan
			##$header = (fBuildDynamicSpacer $diskLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $driveLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $diskSizeLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $rewardLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $missesLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $sectorPlotSpeedLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $minutesPerSectorLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $plottingSpeedLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $_eta_Label.Length "-") + $spacerLabel + (fBuildDynamicSpacer $plotStatusLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $replotStatusLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $lastRewardLabel.Length "-") + $spacerLabel
			#$header = (fBuildDynamicSpacer $diskLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $driveLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $diskSizeLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $rewardLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $missesLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $sectorPlotSpeedLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $minutesPerSectorLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $_eta_Label.Length "-") + $spacerLabel + (fBuildDynamicSpacer $plotStatusLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $replotStatusLabel.Length "-") + $spacerLabel + (fBuildDynamicSpacer $lastRewardLabel.Length "-") + $spacerLabel

			$header = 	(fBuildDynamicSpacer $diskLabel.Length $_label_line_separator_upper) + $spacerLabel + (fBuildDynamicSpacer $driveLabel.Length $_label_line_separator_upper) + $spacerLabel + 
						(fBuildDynamicSpacer $diskSizeLabel.Length $_label_line_separator_upper) + $spacerLabel + (fBuildDynamicSpacer $rewardLabel.Length $_label_line_separator_upper) + $spacerLabel + 
						(fBuildDynamicSpacer $missesLabel.Length $_label_line_separator_upper) + $spacerLabel + (fBuildDynamicSpacer $sectorPlotSpeedLabel.Length $_label_line_separator_upper) + $spacerLabel + 
						(fBuildDynamicSpacer $minutesPerSectorLabel.Length $_label_line_separator_upper) + $spacerLabel + (fBuildDynamicSpacer $_eta_Label.Length $_label_line_separator_upper) + $spacerLabel + 
						(fBuildDynamicSpacer $plotStatusLabel.Length $_label_line_separator_upper) + $spacerLabel + (fBuildDynamicSpacer $replotStatusLabel.Length $_label_line_separator_upper) + $spacerLabel + 
						(fBuildDynamicSpacer $lastRewardLabel.Length $_label_line_separator_upper) + $spacerLabel

			Write-Host $header -ForegroundColor gray
			#
			#write summary data
			#$avgSectorPerMinute = 0.0
			#$avgSectorPerMinuteDiskCount = 0
			#$avgMinutesPerSector = 0.0
			#$avgMinutesPerSectorDiskCount = 0
			for ($arrPos = 0; $arrPos -lt $rewardByDiskCountArr.Count; $arrPos++) {
				$diskText = $arrPos.ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskLabel.Length-$diskText.Length-1)
				$driveSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$driveText = $driveArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$driveLabel.Length-$driveText.Length-1)
				$diskSizeSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$diskSizeText = $diskSizeArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskSizeLabel.Length-$diskSizeText.Length-1)
				$diskRewardSpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				$rewardByDiskText = $rewardByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$rewardLabel.Length-$rewardByDiskText.Length-1)
				$missesSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$missesByDiskText = $missesByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$missesLabel.Length-$missesByDiskText.Length-1)
				$plottingSpeedByDiskSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				#$plotSpeedByDiskArr[0]*$singleSectorSize
				$sectorPlotRate = "-"
				$minutesPerSector = "-"
				$secondsPerSector = 0
				$plottingRate = "-"
				if ($plotSpeedByDiskArr[$arrPos] -gt 0) {
					$sectorPlotRate = [math]::Round(($sectorCountByDiskArr[$arrPos] * 3600) / $plotSpeedByDiskArr[$arrPos], 1)
					$minutesPerSector = [math]::Round($plotSpeedByDiskArr[$arrPos] / ($sectorCountByDiskArr[$arrPos] * 60), 1)
					$secondsPerSector = $plotSpeedByDiskArr[$arrPos] / $sectorCountByDiskArr[$arrPos]
					$plottingRate = [math]::Round(($sectorPlotRate * $singleSectorSize) / 60 , 1)
					#
					#$avgSectorPerMinute = $avgSectorPerMinute + $sectorPlotRate
					#$avgSectorPerMinuteDiskCount = $avgSectorPerMinuteDiskCount + 1
					#$avgMinutesPerSector = $avgMinutesPerSector + $minutesPerSector
					#$avgMinutesPerSectorDiskCount = $avgMinutesPerSectorDiskCount + 1
				}
				$sectorPlotSpeedByDiskText = $sectorPlotRate.ToString()
				$spacerLength = [int]($spacerLabel.Length+$sectorPlotSpeedLabel.Length-$sectorPlotSpeedByDiskText.Length-1)
				$sectorPlotSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				#$minutesPerSectorText = $minutesPerSector.ToString()
				$TimePerSectorText = New-TimeSpan -seconds $secondsPerSector
				if ($secondsPerSector -gt 0) {
					$minutesPerSectorText = $TimePerSectorText.minutes.ToString() + "m " + $TimePerSectorText.seconds.ToString() + "s"
				}
				else {
					$minutesPerSectorText = "0" + "m " + "0" + "s"
				}
				$spacerLength = [int]($spacerLabel.Length+$minutesPerSectorLabel.Length-$minutesPerSectorText.Length-1)
				$minutesPerSectorSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				#$plottingSpeedByDiskText = $plottingRate.ToString()
				#$spacerLength = [int]($spacerLabel.Length+$plottingSpeedLabel.Length-$plottingSpeedByDiskText.Length-1)
				#$plotSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				#$_eta_Text = $_eta_ByDisk[$arrPos].ToString()
				if ($_eta_ByDisk[$arrPos] -ne "-" -and $_eta_ByDisk[$arrPos] -ne 0)
				{
					$_eta_obj = New-TimeSpan -seconds $_eta_ByDisk[$arrPos]
					$_eta_Text = $_eta_obj.days.ToString() + "d " + $_eta_obj.hours.ToString() + "h " + $_eta_obj.minutes.ToString() + "m"
				}
				else{
					$_eta_Text = "0" + "d " + "0" + "h " + "0" + "m"
				}
				$spacerLength = [int]($spacerLabel.Length+$_eta_Label.Length-$_eta_Text.Length-1)
				$_eta_SpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				#if ($bPlottingStarted -and $plotSizeByDiskCountArr[$arrPos] -eq "-") {
				#	$plotSizeByDiskCountArr[$arrPos] = "100%"
				#}
				$plotSizeByDiskText = $plotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$plotStatusLabel.Length-$plotSizeByDiskText.Length-1)
				$replotSpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				$replotSizeByDiskText = $replotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$replotStatusLabel.Length-$replotSizeByDiskText.Length-1)
				$lastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$_lastRewardDispText = $lastRewardTimestampArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$lastRewardLabel.Length-$_lastRewardDispText.Length-1)
				$_endSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				$summaryData =  $diskText + $driveSpacerLabel + $spacerLabel + $driveText + $diskSizeSpacerLabel + $spacerLabel + $diskSizeText + $diskRewardSpacerLabel + $spacerLabel + $rewardByDiskText + $missesSpacerLabel + $spacerLabel
				Write-Host $summaryData -NoNewline
				if ([int]$missesByDiskText -eq 0) {
					Write-Host $missesByDiskText -NoNewline
				}
				else {
					Write-Host $missesByDiskText -NoNewline -ForegroundColor red
				}
				#$summaryData = $plottingSpeedByDiskSpacerLabel + $spacerLabel + $sectorPlotSpeedByDiskText + $sectorPlotSpacerLabel + $spacerLabel + $minutesPerSectorText + $minutesPerSectorSpacerLabel + $spacerLabel + $plottingSpeedByDiskText + $plotSpacerLabel + $spacerLabel + $_eta_Text + $_eta_SpacerLabel + $spacerLabel + $plotSizeByDiskText + $replotSpacerLabel + $spacerLabel + $replotSizeByDiskText + $lastRewardSpacerLabel + $spacerLabel + $_lastRewardDispText + $_endSpacerLabel + $spacerLabel
				$summaryData = $plottingSpeedByDiskSpacerLabel + $spacerLabel + $sectorPlotSpeedByDiskText + $sectorPlotSpacerLabel + $spacerLabel + $minutesPerSectorText + $minutesPerSectorSpacerLabel + $spacerLabel + $_eta_Text + $_eta_SpacerLabel + $spacerLabel + $plotSizeByDiskText + $replotSpacerLabel + $spacerLabel + $replotSizeByDiskText + $lastRewardSpacerLabel + $spacerLabel + $_lastRewardDispText + $_endSpacerLabel + $spacerLabel
				Write-Host $summaryData
				#
			}
			##Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			#Write-Host "-----------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			$_finish_line_length = ("-----------------------------------------------------------------------------------------------------------------").Length
			$_finish_line_label = fBuildDynamicSpacer $_finish_line_length $_label_line_separator_upper
			Write-Host $_finish_line_label -ForegroundColor gray
			#
			#remember the last written summary data for later repositioning after writing averages in sub-header at a high-level
			$mostRecentSummaryDataCursorPosition = $host.UI.RawUI.CursorPosition
			#
			#reposition cursor for writing averages for sectors/min & min/sector information
			#[Console]::SetCursorPosition($avgSectorsPerMinuteCursorPosition.X, $avgSectorsPerMinuteCursorPosition.Y)
			#$_avgSectorPerMinuteDisp = "-"
			#if ($avgSectorPerMinuteDiskCount -gt 0) {
			#	$_avgSectorPerMinuteDisp = ([math]::Round($avgSectorPerMinute / $avgSectorPerMinuteDiskCount, 1)).ToString()
			#}
			#[System.Console]::Write($_avgSectorPerMinuteDisp) 
			#
			#[Console]::SetCursorPosition($avgMinutesPerSectorCursorPosition.X, $avgMinutesPerSectorCursorPosition.Y)
			#$_avgMinutesPerSectorDisp = "-"
			#if ($avgMinutesPerSectorDiskCount -gt 0) {
			#	$_avgMinutesPerSectorDisp = ([math]::Round($avgMinutesPerSector / $avgMinutesPerSectorDiskCount, 1)).ToString()
			#}
			#[System.Console]::Write($_avgMinutesPerSectorDisp) 
			#
			#revert back cursor position to last written summary data
			#[Console]::SetCursorPosition($mostRecentSummaryDataCursorPosition.X, $mostRecentSummaryDataCursorPosition.Y)

			##
			#Build Details Header and Data
			$bWarnAndErrHeaderPrinted = $false
			$errMsgInfoHoldArr = [System.Collections.ArrayList]@()
			foreach($pattern in $patternArr)
			{
				$bHeaderOther = $false
				$bWarnAndErrHeader = $false
				$subHeaderText = ""
				$subHeaderColor = "cyan"
				if ($pattern.IndexOf("farm") -ge 0) {
					continue
				}
				elseif ($pattern.IndexOf("reward") -ge 0) {
					$subHeaderText = "Reward details:"
					if ($bShowRewardDetails -eq $false) {
						continue
					}
					$bHeaderOther = $true
				}
				elseif ($pattern.IndexOf("plotting") -ge 0) {
					$subHeaderText = "Plotting details:"
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
						$subHeaderText = "Warnings and Errors:"
						$subHeaderColor = "red"
					}
				}
				#
				if ($bHeaderOther -or $bWarnAndErrHeaderPrinted -eq $false) {
					#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
					echo `n
					Write-Host "                                            " $subHeaderText -ForegroundColor $subHeaderColor
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
				for ($arrIndex =$textArrSize-1;$arrIndex -ge 0; $arrIndex--)
				{
					$dispText = $meaningfulTextArr[$arrIndex].ToString()
					if ($dispText -ne "") {
						if ($dispText.IndexOf("Subscribing") -ge 0) {
							$bSkipDisplay = $true
						}
						elseif ($subHeaderText -eq "Plotting details:") {
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
						elseif ($subHeaderText -eq "Warnings and Errors:") {
							$errMsgInfoHold = ""
							if ($dispText.IndexOf("error") -ge 0) {
								$errMsgLable = "{"
								$errMsgStartPos = $dispText.IndexOf($errMsgLable)
								$errMsgEndPos = $dispText.IndexOf("}")
								try {
									$errMsgInfoHold = $dispText.SubString($errMsgStartPos+$errMsgLable.Length,$errMsgEndPos-$errMsgLable.Length-$errMsgStartPos)
								}
								catch {
									$errMsgInfoHold = fParseStr $dispText " " "first"
								}
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
			#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			#
			#$currentDate = Get-Date -Format HH:mm:ss
			$currentDate = (Get-Date).ToLocalTime().ToString()
			# Refresh
			echo `n
			Write-Host "Last refresh on: " -ForegroundColor Yellow -nonewline; Write-Host "$currentDate" -ForegroundColor Green;
			#
			####
			## Auto refresh wait cycle
			if ($bAutoRefresh) {
				<#
				Write-Host "Auto-refresh scheduled for every " -nonewline 
				Write-Host $refreshTimeScaleInSeconds -nonewline -ForegroundColor yellow
				Write-Host " seconds"
				[System.Console]::CursorVisible = $false
				$iterations = [math]::Ceiling($refreshTimeScaleInSeconds / 5)       
				for ($i = 0; $i -lt $iterations; $i++) {
					Write-Host -NoNewline "." -ForegroundColor Cyan
					Start-Sleep 5
				}
				#>
				fStartCountdownTimer $refreshTimeScaleInSeconds

				###### Auto refresh
				$HoursElapsed = $Stopwatch.Elapsed.TotalHours
				if ($HoursElapsed -ge 1) {
					$gitNewVersion = Get-gitNewVersion
					if ($gitNewVersion) {
						$gitVersion = $gitNewVersion
					}
					$Stopwatch.Restart()
				}
				######
			}
			else {
				[System.Console]::CursorVisible = $true
				$uRefreshRequest = Read-Host 'Type (R) to refresh, (X) to Exit and press Enter'
				if ($uRefreshRequest.ToLower() -eq 'r') {
					$bRefreshPage = $true
					$HoursElapsed = $Stopwatch.Elapsed.TotalHours
					if ($HoursElapsed -ge 1) {
						$gitNewVersion = Get-gitNewVersion
						if ($gitNewVersion) {
							$gitVersion = $gitNewVersion
						}
						$Stopwatch.Restart()
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
Function fStartCountdownTimer ([int]$_io_timer_duration) {
	$_sleep_interval_milliseconds = 1000
	$_spinner = '|', '/', '-', '\'
	$_spinnerPos = 0
	$_end_dt = [datetime]::UtcNow.AddSeconds($_io_timer_duration)
	[System.Console]::CursorVisible = $false
	
	while (($_remaining_time = ($_end_dt - [datetime]::UtcNow).TotalSeconds) -gt 0) {
		Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
		#Write-Host -NoNewLine ("Refreshing in {0,3} seconds..." -f [Math]::Ceiling($_remaining_time))
		Write-Host "Refreshing in " -NoNewline 
		Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
		Write-Host " seconds..." -NoNewline 
		Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
	}
	Write-Host
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
function fTestDiscordPing ([string]$ioHostName, [string]$ioUrl) {
	#$alertArr = [System.Collections.ArrayList]@()
	$alertSkipped = $false
	$pingOk = $false
	$alertColor = "white"
	$alertStatusMsg = ""
	do {
		if ($ioUrl -eq "" -or $ioUrl -eq $null) {
			$alertColor = "yellow"
			$alertStatusMsg = "Info: Discord alert were not set...notifications will be skipped" 
			$alertSkipped = $true
		}
		else {
			[System.Console]::CursorVisible = $false
			try {
				$alertColor = "green"
				$alertStatusMsg = "Successfully subscribed to receiving alerts from Hostname: " + $ioHostName
				fSendDiscordNotification $ioUrl $alertStatusMsg
				$pingOk = $true
			}
			catch {
				$alertColor = "red"
				$alertStatusMsg = "Can not reach url provided, please check and provide corrected url. Press [R] to retry Or any other key to skip:"
				Write-Host $alertStatusMsg -nonewline -ForegroundColor $alertColor
				$uRetryAlertKey = $Host.UI.RawUI.ReadKey()
				Switch ($uRetryAlertKey.Character.ToString().ToLower()) {
					r {
						[System.Console]::CursorVisible = $true
						write-host ""
						$ioUrl = $(Write-Host "Discord server notification url: " -nonewline -ForegroundColor cyan; Read-Host)
					}
					default {
						$alertColor = "yellow"
						$alertStatusMsg = "Info: Discord alert were not set...notifications will be skipped" 
						$alertSkipped = $true
						write-host ""
					}
				}
			}
			finally {
				[System.Console]::CursorVisible = $true
			}
		}
	} until ($alertSkipped -or $pingOk)
	#
	$alertArr = @($alertSkipped, $alertColor, $alertStatusMsg)
	return $alertArr
}
function fBuildDynamicSpacer ([int]$ioSpacerLength, [string]$ioSpaceType){
	$dataSpacerLabel = ""
	for ($k=1;$k -le $ioSpacerLength;$k++) {
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

