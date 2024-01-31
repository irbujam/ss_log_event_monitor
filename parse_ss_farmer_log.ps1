<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Subspace Log Event Monitor"
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
$patternArr = @("Single disk farm","Successfully signed reward hash","plotting", "error")

##Prompt for advanced CLI farmer log filer
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Text (*.txt)|*.txt|Logs (*.log)|*.log'
}
$null = $FileBrowser.ShowDialog()
$logFileName = $FileBrowser.filename

##functions
#Main process
function main {
	$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$gitVersion = Get-gitNewVersion
	
	Clear-Host
	#Console input for User choices on auto-refresh
	$uAutoRefresh = $(Write-Host "Auto Refresh (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
	if ($uAutoRefresh.ToLower() -eq "y") {$bAutoRefresh = $true}

	if ($bAutoRefresh) {
		$uTimeInputInSeconds = $(Write-Host "Enter time in seconds for auto-refresh (For example...set to 60 if refresh is desired every 1 minute): " -nonewline -ForegroundColor cyan; Read-Host)
		$refreshTimeScaleInSeconds = [int]$uTimeInputInSeconds
	}
	#Console input for User choices on console for suppressions
	$uShowWarnings = $(Write-Host "Show warnings (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
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
			Clear-Host

			# get Farmer process status
			$bProcess = Get-Process "subspace-farmer" -ErrorAction SilentlyContinue
			if ($bProcess) {
				Write-Host "Farmer status: " -nonewline
				Write-Host "Running" -ForegroundColor green
			}
			else {
				Write-Host "Farmer status: " -nonewline
				Write-Host "Stopped" -ForegroundColor red
			}
			Write-Host "----------------------" -ForegroundColor yellow

			if ($null -ne $gitVersion) {
				$currentVersion = $gitVersion -replace "[^.0-9]"
				Write-Host "Latest subspace github advance CLI version: " -nonewline
				Write-Host "$($gitVersion)" -ForegroundColor Green
			}

			#Build Summary
			$allDetailsTextArr = Get-Content -Path $logFileName | Select-String -Pattern "Allocated space:", "Directory:", "Single disk farm", "Successfully signed reward hash", "plotting sector", "error"
			$diskCount = 0
			$rewardCount = 0
			$diskSizeArr = [System.Collections.ArrayList]@()
			$driveArr = [System.Collections.ArrayList]@()
			$rewardByDiskCountArr = [System.Collections.ArrayList]@()
			$lastRewardTimestampArr = [System.Collections.ArrayList]@()
			$plotSizeByDiskCountArr = [System.Collections.ArrayList]@()
			$replotSizeByDiskCountArr = [System.Collections.ArrayList]@()
			for ($arrPos = 0; $arrPos -lt $allDetailsTextArr.Count; $arrPos++)
			{
				$allDetailsArrText = $allDetailsTextArr[$arrPos].ToString()
				if ($allDetailsArrText.IndexOf("Single disk farm") -ge 0) {
					$tempArrId = $diskSizeArr.Add(0)
					$tempArrId = $driveArr.Add(0)
					$tempArrId = $rewardByDiskCountArr.Add(0)
					$tempArrId = $lastRewardTimestampArr.Add(0)
					$tempArrId = $plotSizeByDiskCountArr.Add(0)
					$tempArrId = $replotSizeByDiskCountArr.Add(0)
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
				elseif ($allDetailsArrText.IndexOf("plotting:") -ge 0) {
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
						$replotSizeByDiskCountArr[$diskNumInfo] = "N/A"
					}
				}
			}
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
			Write-Host "                                                      Summary:                                                     " -ForegroundColor green
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
			Write-Host "Total Rewards: " $rewardCount
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
			$diskLabel = "Disk#"
			$driveLabel = "Drive Label"
			$diskSizeLabel = "Space Allocated       "
			$rewardLabel = "Rewards"
			$plotStatusLabel = "Plot Status"
			$replotStatusLabel = "Replot Status"
			$lastRewardLabel = "Last Reward On"
			$spacerLabel = "  "
			Write-Host $diskLabel $spacerLabel $driveLabel $spacerLabel $diskSizeLabel $spacerLabel $rewardLabel $spacerLabel $plotStatusLabel $spacerLabel $replotStatusLabel $spacerLabel $lastRewardLabel -ForegroundColor cyan
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
			for ($arrPos = 0; $arrPos -lt $rewardByDiskCountArr.Count; $arrPos++) {
				$diskText = $arrPos.ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskLabel.Length-$diskText.Length)
				$driveSpacerLabel = fBuildDynamicSpacer $spacerLength

				$driveText = $driveArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$driveLabel.Length-$driveText.Length)
				$diskSizeSpacerLabel = fBuildDynamicSpacer $spacerLength

				$diskSizeText = $diskSizeArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskSizeLabel.Length-$diskSizeText.Length)
				$diskRewardSpacerLabel = fBuildDynamicSpacer $spacerLength
				
				$rewardByDiskText = $rewardByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$rewardLabel.Length-$rewardByDiskText.Length)
				$plotSpacerLabel = fBuildDynamicSpacer $spacerLength
				
				$plotSizeByDiskText = $plotSizeByDiskCountArr[$arrPos].ToString() 
				if ($plotSizeByDiskText -eq "") {$plotSizeByDiskText = "100%"}
				$spacerLength = [int]($spacerLabel.Length+$plotStatusLabel.Length-$plotSizeByDiskText.Length)
				#$plotLastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength
				$replotSpacerLabel = fBuildDynamicSpacer $spacerLength
				
				$replotSizeByDiskText = $replotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$replotStatusLabel.Length-$replotSizeByDiskText.Length)
				$lastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength
				Write-Host $diskText $driveSpacerLabel $driveText $diskSizeSpacerLabel $diskSizeText $diskRewardSpacerLabel $rewardByDiskText $plotSpacerLabel $plotSizeByDiskText $replotSpacerLabel $replotSizeByDiskText $lastRewardSpacerLabel $lastRewardTimestampArr[$arrPos]
			}
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow

			#Build Details
			foreach($pattern in $patternArr)
			{
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
				}
				elseif ($pattern.IndexOf("plotting") -ge 0) {
					$subHeaderText = "Plotting"
					if ($bShowPlottingDetails -eq $false) {
						continue
					}
				}
				elseif ($pattern.IndexOf("error") -ge 0) {
					if ($bShowWarnings -eq $false) {
						continue
					}
					else {
						$subHeaderText = "Error"
						$subHeaderColor = "red"
					}
				}
				#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
				Write-Host "                                            " $subHeaderText " details:                                     " -ForegroundColor $subHeaderColor
				Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
				$meaningfulTextArr = $allDetailsTextArr | Select-String -Pattern $pattern
				$textArrSize =  $meaningfulTextArr.Length
				
				$bDiskInfoMatchFound = $false
				$bErrMsgInfoMatchFound = $false
				$diskInfoHoldArr = [System.Collections.ArrayList]@()
				$errMsgInfoHoldArr = [System.Collections.ArrayList]@()
				for ($arrIndex =$textArrSize-1;$arrIndex -ge 0; $arrIndex--)
				{
					$dispText = $meaningfulTextArr[$arrIndex].ToString()
					if ($dispText -ne "") {
						if ($subHeaderText -eq "Plotting") {
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
						elseif ($subHeaderText -eq "Error") {
							$errMsgLable = "{"
							$errMsgStartPos = $dispText.IndexOf($errMsgLable)
							$errMsgEndPos = $dispText.IndexOf("}")
							$errMsgInfoHold = $dispText.SubString($errMsgStartPos+$errMsgLable.Length,$errMsgEndPos-$errMsgLable.Length-$errMsgStartPos)
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
						if ($bDiskInfoMatchFound -eq $false -and $bErrMsgInfoMatchFound -eq $false) {
							$seperator = " "
							$i = $dispText.IndexOf($seperator)
							$textPart1 = $dispText.SubString(0,$i)
							$textPart2 = $dispText.SubString($i+1,$dispText.Length-$i-1)
							
							#Write-Host $dispText
							Write-Host (Get-Date $textPart1).ToLocalTime() $textPart2
						}
						#echo "`n"
					}
				}
				Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor yellow
			}
			
			#Finalize
			#
			#$currentDate = Get-Date -Format HH:mm:ss
			$currentDate = Get-Date -Format u
			# Refresh
			Write-Host `n                
			Write-Host "Last refresh On: " -ForegroundColor Yellow -nonewline; Write-Host "$currentDate" -ForegroundColor Green;
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

function fBuildDynamicSpacer ([int]$ioSpacerLength){
				$dataSpacerLabel = ""
				for ($k=0;$k -lt $ioSpacerLength;$k++) {
					$dataSpacerLabel = $dataSpacerLabel + " "
				}
				return $dataSpacerLabel
}
function Get-gitNewVersion {
	.{
		$gitNewVersion = Invoke-RestMethod -Method 'GET' -uri "https://api.github.com/repos/subspace/subspace/releases/latest" 2>$null
		if ($gitNewVersion) {
			$gitNewVersion = $gitNewVersion.tag_name
		}
	}|Out-Null
	return $gitNewVersion
}
#function parseInputStr([string]$ioSourceText, [string]$delimiter){
#	$i = $ioSourceText.IndexOf($delimiter)
#	$textPart = $ioSourceText.SubString($i+1,$ioSourceText.Length-$i-1)
#	return $textPart
#}

main
