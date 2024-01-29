##header
$host.UI.RawUI.WindowTitle = "Subspace Log Event Monitor"

##Definitions
$bRefreshPage = $true
$bSuppressWarnings = $false
$fullPatternArr = @("Single disk farm","Successfully signed reward hash","plotting", "error")
$noWarnPatternArr = @("Single disk farm","Successfully signed reward hash","plotting")

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
			$uSuppressWarnings = $(Write-Host "Supress warnings (Y/N)? " -nonewline -ForegroundColor cyan; Read-Host)
			if ($uSuppressWarnings.ToLower() -eq 'y') {
				$bSuppressWarnings = $true
			}
			else {
				$bSuppressWarnings = $false
			}
			if ($bSuppressWarnings) {
				$patternArr = $noWarnPatternArr
			}
			else {
				$patternArr = $fullPatternArr
			}

			$allDetailsTextArr = Select-String -Path $logFileName -Pattern "Single disk farm", "Successfully signed reward hash", "plotting", "error"
			$diskCount = 0
			$rewardCount = 0
			$rewardByDiskCountArr = [System.Collections.ArrayList]@()
			$plotSizeByDiskCountArr = [System.Collections.ArrayList]@()
			for ($arrPos = 0; $arrPos -lt $allDetailsTextArr.Count; $arrPos++)
			{
				$allDetailsArrText = $allDetailsTextArr[$arrPos].ToString()
				if ($allDetailsArrText.IndexOf("Single disk farm") -ge 0) {
					$tempArrId = $rewardByDiskCountArr.Add(0)
					$tempArrId = $plotSizeByDiskCountArr.Add(0)
					$diskCount = $diskCount + 1
				}
				elseif ($allDetailsArrText.IndexOf("Successfully signed reward hash") -ge 0) {
					$rewardCount = $rewardCount + 1
					$diskInfoLabel = "{disk_farm_index="
					$diskInfoStartPos = $allDetailsArrText.IndexOf($diskInfoLabel)
					$diskInfoEndPos = $allDetailsArrText.IndexOf("}")
					$diskNumInfo = $allDetailsArrText.SubString($diskInfoStartPos+$diskInfoLabel.Length,$diskInfoEndPos-$diskInfoLabel.Length-$diskInfoStartPos)
					#Write-Host "diskNumInfo" $diskNumInfo
					$rewardByDiskCountArr[$diskNumInfo] = $rewardByDiskCountArr[$diskNumInfo] + 1
				}
				elseif ($allDetailsArrText.IndexOf("plotting") -ge 0) {
					$diskInfoLabel = "{disk_farm_index="
					$diskInfoStartPos = $allDetailsArrText.IndexOf($diskInfoLabel)
					$diskInfoEndPos = $allDetailsArrText.IndexOf("}")
					$diskNumInfo = $allDetailsArrText.SubString($diskInfoStartPos+$diskInfoLabel.Length,$diskInfoEndPos-$diskInfoLabel.Length-$diskInfoStartPos)
					#Write-Host "diskNumInfo" $diskNumInfo
					if ($allDetailsArrText.IndexOf("Replotting complete") -ge 0) {
						$plotSizeByDiskCountArr[$diskNumInfo] = "100%"
					}
					else {
						$plotSizeInfoLabel = "("
						$plotSizeStartPos = $allDetailsArrText.IndexOf($plotSizeInfoLabel)
						$plotSizeEndPos = $allDetailsArrText.IndexOf("%")
						$plotSizeInfo = $allDetailsArrText.SubString($plotSizeStartPos+$plotSizeInfoLabel.Length,$plotSizeEndPos-$plotSizeStartPos)
						#Write-Host "diskNumInfo" $diskNumInfo
						$plotSizeByDiskCountArr[$diskNumInfo] = $plotSizeInfo
					}
				}
			}
			Write-Host "------------------" -ForegroundColor yellow
			Write-Host "Summary:" -ForegroundColor green
			Write-Host "------------------" -ForegroundColor yellow
			Write-Host "Total Rewards " $rewardCount
			Write-Host "------------------" -ForegroundColor yellow
			Write-Host "Disk#" "Rewards" "Plot Status" -ForegroundColor cyan
			Write-Host "------------------" -ForegroundColor yellow
			for ($arrPos = 0; $arrPos -lt $rewardByDiskCountArr.Count; $arrPos++) {
				Write-Host $arrPos "   " $rewardByDiskCountArr[$arrPos] "     " $plotSizeByDiskCountArr[$arrPos]
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
				}
				elseif ($pattern.IndexOf("plotting") -ge 0) {
					$subHeaderText = "Plotting"
				}
				elseif ($pattern.IndexOf("error") -ge 0) {
					$subHeaderText = "Error"
					$subHeaderColor = "red"
				}
				Write-Host "------------------" -ForegroundColor yellow
				Write-Host $subHeaderText " details:" -ForegroundColor $subHeaderColor
				Write-Host "------------------" -ForegroundColor yellow
				#$meaningfulText = Select-String -Path $logFileName -Pattern $pattern
				$meaningfulText = $allDetailsTextArr | Select-String -Pattern $pattern
				#Write-Host $meaningfulText
				$meaningfulText = $meaningfulText -replace "\\", ".."
				$seperator = ":"
				$resultTextArr = parseInputStrToArr $meaningfulText $seperator

				for ($arrIndex =0;$arrIndex -lt $resultTextArr.Count; $arrIndex++)
				{
					if ($resultTextArr[$arrIndex] -ne "") {
						$partialText = $resultTextArr[2]
						break
					}
				}
				#Write-Host $partialText
				$meaningfulTextArr = $meaningfulText -split $partialText
				$textArrSize =  $meaningfulTextArr.Length
				#Write-Host $textArrSize
				
				#for ($arrIndex =0;$arrIndex -lt $textArrSize; $arrIndex++)
				$bDiskInfoMatchFound = $false
				$diskInfoHoldArr = [System.Collections.ArrayList]@()
				for ($arrIndex =$textArrSize-1;$arrIndex -ge 0; $arrIndex--)
				{
					if ($meaningfulTextArr[$arrIndex] -ne "") {
						#Write-Host "array element: "  $meaningfulTextArr[$arrIndex]
						$dispText = parseInputStr $meaningfulTextArr[$arrIndex] ":"
						#write-host "subHeaderText: " $subHeaderText
						if ($subHeaderText -eq "Plotting") {
							$diskInfoLabel = "{disk_farm_index="
							$diskInfoStartPos = $dispText.IndexOf($diskInfoLabel)
							$diskInfoHold = $dispText.SubString($diskInfoStartPos,$diskInfoLabel.Length+2)
							#write-host "diskInfoHold: " $diskInfoHold
							$bDiskInfoMatchFound = $false
							foreach($disk in $diskInfoHoldArr)
							{
								if ($diskInfoHold -eq $disk) {
									$bDiskInfoMatchFound = $true
									break
								}
							}							
							if ($bDiskInfoMatchFound -eq $false) {
								$diskInfoHoldArr.Add($diskInfoHold)
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
			Write-Host "Last refresh: " -ForegroundColor Yellow -nonewline; Write-Host "$currentDate" -ForegroundColor Green;
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

function parseInputStr([string]$ioSourceText, [string]$delimiter){
	#Write-Host $ioSourceText
	$i = $ioSourceText.IndexOf($delimiter)             # get the last separator
	#$i = $ioSourceText.IndexOf($delimiter, $i + 1)     # get the second to last separator, also the end of the column we are interested in
	#$i = $ioSourceText.IndexOf($delimiter, $i + 1)     # get the third to last separator, also the end of the column we are interested in
    #$j = $ioSourceText.LastIndexOf($delimiter, $i - 1)     # get the separator before the column we want
    #$j++                                    # more forward past the separator
	$textPart = $ioSourceText.SubString($i+1,$ioSourceText.Length-$i-1)
	return $textPart
}
function parseInputStrToArr([string]$ioSourceText, [string]$delimiter){
	#Write-Host $ioSourceText
	$i = $ioSourceText.IndexOf($delimiter)             # get the last separator
	$i = $ioSourceText.IndexOf($delimiter, $i + 1)     # get the second to last separator, also the end of the column we are interested in
	#$i = $ioSourceText.IndexOf($delimiter, $i + 1)     # get the third to last separator, also the end of the column we are interested in
    #$j = $ioSourceText.LastIndexOf($delimiter, $i - 1)     # get the separator before the column we want
    #$j++                                    # more forward past the separator
	$textPart1 = $ioSourceText.SubString(0,$i+1)
	$textPart2 = $ioSourceText.SubString($i+1,$ioSourceText.Length-$i-1)
	#Write-Host $textPart1
	#Write-Host $textPart2
	$ioReturnTextArr = [System.Collections.ArrayList]@()
	$ioTempArr = ($textPart1, $textPart2)
	foreach($item in $ioTempArr)
	{
		#Write-Host $item
		$ioReturnTextArr.Add($item)
	}
	return $ioReturnTextArr
}

main
