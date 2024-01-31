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

			# get Subspace node process state
			$bNodeProcess = Get-Process | where {$_.ProcessName -like '*subspace-node*'} -ErrorAction SilentlyContinue
			if ($bNodeProcess) {
				Write-Host "Node status: " -nonewline
				Write-Host "Running" -ForegroundColor green -NoNewline
			}
			else {
				Write-Host "Node status: " -nonewline
				Write-Host "Stopped" -ForegroundColor red -NoNewline
			}

			# get Subspace farmer process state
			#$bFarmerProcess = Get-Process "subspace-farmer" -ErrorAction SilentlyContinue
			$bFarmerProcess = Get-Process | where {$_.ProcessName -like '*subspace-farmer*'} -ErrorAction SilentlyContinue
			if ($bFarmerProcess) {
				Write-Host "    |    " -nonewline -ForegroundColor yellow
				Write-Host "Farmer status: " -nonewline
				Write-Host "Running" -ForegroundColor green
			}
			else {
				Write-Host "    |    " -nonewline
				Write-Host "Farmer status: " -nonewline
				Write-Host "Stopped" -ForegroundColor red
			}
			#Write-Host "---------------------------------------------------" -ForegroundColor gray

			if ($null -ne $gitVersion) {
				$currentVersion = $gitVersion -replace "[^.0-9]"
				Write-Host "Latest subspace github advance CLI version: " -nonewline
				Write-Host "$($gitVersion)" -ForegroundColor Green
			}
			echo "`n"

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
					$tempArrId = $driveArr.Add("-")
					$tempArrId = $rewardByDiskCountArr.Add(0)
					$tempArrId = $lastRewardTimestampArr.Add("-")
					$tempArrId = $plotSizeByDiskCountArr.Add("-")
					$tempArrId = $replotSizeByDiskCountArr.Add("-")
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
						$replotSizeByDiskCountArr[$diskNumInfo] = "-"
					}
				}
			}
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-Host "                                                      Summary:                                                     " -ForegroundColor green
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-Host "Total Rewards: " -nonewline
			Write-Host $rewardCount -ForegroundColor Yellow
			#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			$diskLabel = "Disk#"
			$driveLabel = "Drive Label"
			$diskSizeLabel = "Space Allocated       "
			$rewardLabel = "Rewards"
			$plotStatusLabel = "Plot Status"
			$replotStatusLabel = "Replot Status"
			$lastRewardLabel = "Last Reward On"
			$spacerLabel = "  "
			Write-Host (fBuildDynamicSpacer $diskLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $driveLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $diskSizeLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $rewardLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $plotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $replotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $lastRewardLabel.Length "-") -ForegroundColor gray
			Write-Host $diskLabel $spacerLabel $driveLabel $spacerLabel $diskSizeLabel $spacerLabel $rewardLabel $spacerLabel $plotStatusLabel $spacerLabel $replotStatusLabel $spacerLabel $lastRewardLabel -ForegroundColor cyan
			#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
			Write-Host (fBuildDynamicSpacer $diskLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $driveLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $diskSizeLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $rewardLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $plotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $replotStatusLabel.Length "-") $spacerLabel (fBuildDynamicSpacer $lastRewardLabel.Length "-") -ForegroundColor gray
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
				$plotSpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				#if ($plotSizeByDiskCountArr[$arrPos] -eq "-") {
				#	$plotSizeByDiskCountArr[$arrPos] = "100%"
				#	$replotSizeByDiskCountArr[$arrPos] = "-"
				#}
				$plotSizeByDiskText = $plotSizeByDiskCountArr[$arrPos].ToString() 
				$spacerLength = [int]($spacerLabel.Length+$plotStatusLabel.Length-$plotSizeByDiskText.Length)
				#$plotLastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength
				$replotSpacerLabel = fBuildDynamicSpacer $spacerLength " "
				
				$replotSizeByDiskText = $replotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$replotStatusLabel.Length-$replotSizeByDiskText.Length)
				$lastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength " "

				Write-Host $diskText $driveSpacerLabel $driveText $diskSizeSpacerLabel $diskSizeText $diskRewardSpacerLabel $rewardByDiskText $plotSpacerLabel $plotSizeByDiskText $replotSpacerLabel $replotSizeByDiskText $lastRewardSpacerLabel $lastRewardTimestampArr[$arrPos]
			}
			Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray

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
				#Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
				Write-Host "                                            " $subHeaderText " details:                                     " -ForegroundColor $subHeaderColor
				Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
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
				Write-Host "-------------------------------------------------------------------------------------------------------------------" -ForegroundColor gray
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

function fBuildDynamicSpacer ([int]$ioSpacerLength, [string]$ioSpaceType){
				$dataSpacerLabel = ""
				for ($k=0;$k -lt $ioSpacerLength;$k++) {
					$dataSpacerLabel = $dataSpacerLabel + $ioSpaceType
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
