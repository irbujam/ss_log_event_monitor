<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Subspace Log Event Monitor"

##Definitions
$bRefreshPage = $true
$bSuppressWarnings = $true
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
	while ($true) {
		if ($bRefreshPage -eq $true) {
			$bRefreshPage = $false
			#
			$object = @()
			Clear-Host
			#$uSuppressWarnings = $(Write-Host "Supress warnings (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
			#if ($uSuppressWarnings.ToLower() -eq 'y') {
			#	$bSuppressWarnings = $true
			#}
			#else {
			#	$bSuppressWarnings = $false
			#}
			#$allDetailsTextArr = Get-Content -Path $logFileName
			#$allDetailsTextArr = Select-String -Path $logFileName -Pattern "Single disk farm", "Successfully signed reward hash", "plotting", "error"
			$allDetailsTextArr = Get-Content -Path $logFileName | Select-String -Pattern "Single disk farm", "Successfully signed reward hash", "plotting", "error"
			$diskCount = 0
			$rewardCount = 0
			$rewardByDiskCountArr = [System.Collections.ArrayList]@()
			$lastRewardTimestampArr = [System.Collections.ArrayList]@()
			$plotSizeByDiskCountArr = [System.Collections.ArrayList]@()
			for ($arrPos = 0; $arrPos -lt $allDetailsTextArr.Count; $arrPos++)
			{
				$allDetailsArrText = $allDetailsTextArr[$arrPos].ToString()
				if ($allDetailsArrText.IndexOf("Single disk farm") -ge 0) {
					$tempArrId = $rewardByDiskCountArr.Add(0)
					$tempArrId = $lastRewardTimestampArr.Add(0)
					$tempArrId = $plotSizeByDiskCountArr.Add(0)
					$diskCount = $diskCount + 1
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
				elseif ($allDetailsArrText.IndexOf("plotting") -ge 0) {
					$diskInfoLabel = "{disk_farm_index="
					$diskInfoStartPos = $allDetailsArrText.IndexOf($diskInfoLabel)
					$diskInfoEndPos = $allDetailsArrText.IndexOf("}")
					$diskNumInfo = $allDetailsArrText.SubString($diskInfoStartPos+$diskInfoLabel.Length,$diskInfoEndPos-$diskInfoLabel.Length-$diskInfoStartPos)
					if ($allDetailsArrText.IndexOf("Replotting complete") -ge 0) {
						$plotSizeByDiskCountArr[$diskNumInfo] = "100%"
					}
					else {
						$plotSizeInfoLabel = "("
						$plotSizeStartPos = $allDetailsArrText.IndexOf($plotSizeInfoLabel)
						$plotSizeEndPos = $allDetailsArrText.IndexOf("%")
						$plotSizeInfo = $allDetailsArrText.SubString($plotSizeStartPos+$plotSizeInfoLabel.Length,$plotSizeEndPos-$plotSizeStartPos)
						$plotSizeByDiskCountArr[$diskNumInfo] = $plotSizeInfo
					}
				}
			}
			Write-Host "---------------------------------------------------------" -ForegroundColor yellow
			Write-Host "                         Summary:                        " -ForegroundColor green
			Write-Host "---------------------------------------------------------" -ForegroundColor yellow
			Write-Host "Total Rewards: " $rewardCount
			Write-Host "---------------------------------------------------------" -ForegroundColor yellow
			$diskLabel = "Disk#"
			$rewardLabel = "Rewards"
			$plotStatusLabel = "Plot Status"
			$lastRewardLabel = "Last Reward On"
			$spacerLabel = "  "
			Write-Host $diskLabel $spacerLabel $rewardLabel $spacerLabel $plotStatusLabel $spacerLabel $lastRewardLabel -ForegroundColor cyan
			Write-Host "---------------------------------------------------------" -ForegroundColor yellow
			for ($arrPos = 0; $arrPos -lt $rewardByDiskCountArr.Count; $arrPos++) {
				$diskText = $arrPos.ToString()
				$spacerLength = [int]($spacerLabel.Length+$diskLabel.Length-$diskText.Length)
				$diskRewardSpacerLabel = fBuildDynamicSpacer $spacerLength
				$rewardByDiskText = $rewardByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$rewardLabel.Length-$rewardByDiskText.Length)
				$rewardPlotSpacerLabel = fBuildDynamicSpacer $spacerLength
				$plotSizeByDiskText = $plotSizeByDiskCountArr[$arrPos].ToString()
				$spacerLength = [int]($spacerLabel.Length+$plotStatusLabel.Length-$plotSizeByDiskText.Length)
				$plotLastRewardSpacerLabel = fBuildDynamicSpacer $spacerLength
				Write-Host $arrPos $diskRewardSpacerLabel $rewardByDiskCountArr[$arrPos] $rewardPlotSpacerLabel $plotSizeByDiskCountArr[$arrPos] $plotLastRewardSpacerLabel	$lastRewardTimestampArr[$arrPos]
			}

			foreach($pattern in $patternArr)
			{
				$subHeaderText = ""
				$subHeaderColor = "green"
				if ($pattern.IndexOf("farm") -ge 0) {
					continue
				}
				elseif ($pattern.IndexOf("reward") -ge 0) {
					$subHeaderText = "Reward"
					continue
				}
				elseif ($pattern.IndexOf("plotting") -ge 0) {
					$subHeaderText = "Plotting"
				}
				elseif ($pattern.IndexOf("error") -ge 0) {
					if ($bSuppressWarnings -eq $true) {
						continue
					}
					else {
						$subHeaderText = "Error"
						$subHeaderColor = "red"
					}
				}
				Write-Host "---------------------------------------------------------" -ForegroundColor yellow
				Write-Host "                   " $subHeaderText " details:           " -ForegroundColor $subHeaderColor
				Write-Host "---------------------------------------------------------" -ForegroundColor yellow
				$meaningfulTextArr = $allDetailsTextArr | Select-String -Pattern $pattern
				$textArrSize =  $meaningfulTextArr.Length
				
				$bDiskInfoMatchFound = $false
				$diskInfoHoldArr = [System.Collections.ArrayList]@()
				for ($arrIndex =$textArrSize-1;$arrIndex -ge 0; $arrIndex--)
				{
					if ($meaningfulTextArr[$arrIndex] -ne "") {
						$dispText = $meaningfulTextArr[$arrIndex].ToString()
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
						if ($bDiskInfoMatchFound -eq $false) {
							Write-Host $dispText
						}
						#echo "`n"
					}
				}
			}
			#$currentDate = Get-Date -Format HH:mm:ss
			$currentDate = Get-Date -Format u
			# Refresh
			Write-Host `n                
			Write-Host "Last refresh On: " -ForegroundColor Yellow -nonewline; Write-Host "$currentDate" -ForegroundColor Green;
			#
			$uRefreshRequest = Read-Host 'Type (R) to refresh, (X) to Exit and press Enter'
			if ($uRefreshRequest.ToLower() -eq 'r') {
				$bRefreshPage = $true
			}
			elseif ($uRefreshRequest.ToLower() -eq 'x') {
				exit
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
function parseInputStr([string]$ioSourceText, [string]$delimiter){
	$i = $ioSourceText.IndexOf($delimiter)
	$textPart = $ioSourceText.SubString($i+1,$ioSourceText.Length-$i-1)
	return $textPart
}
#function parseInputStrToArr([string]$ioSourceText, [string]$delimiter){
#	$i = $ioSourceText.IndexOf($delimiter)             # get the first separator position
#	$i = $ioSourceText.IndexOf($delimiter, $i + 1)     # get the second from first separator position
#	$textPart1 = $ioSourceText.SubString(0,$i+1)
#	$textPart2 = $ioSourceText.SubString($i+1,$ioSourceText.Length-$i-1)
#	$ioReturnTextArr = [System.Collections.ArrayList]@()
#	$ioTempArr = ($textPart1, $textPart2)
#	foreach($item in $ioTempArr)
#	{
#		$ioReturnTextArr.Add($item)
#	}
#	return $ioReturnTextArr
#}

main
