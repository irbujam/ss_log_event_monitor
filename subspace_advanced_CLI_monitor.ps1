<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Subspace Advanced CLI Process Monitor"
function main {
	$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$gitVersion = Get-gitNewVersion
	$refreshTimeScaleInSeconds = 30		# defined in config, defaults to 30 if not provided
	$_url_discord = ""
	Clear-Host
	
	while ($true) {
		Clear-Host

		$_b_first_time = $True
		$_line_spacer_color = "gray"
		$_farmer_header_color = "cyan"
		$_farmer_header_data_color = "yellow"
		$_disk_header_color = "white"

		$_farmers_metrics_raw_arr = [System.Collections.ArrayList]@()
		$_node_metrics_raw_arr = [System.Collections.ArrayList]@()

		$_configFile = "./config.txt"
		$_farmers_ip_arr = Get-Content -Path $_configFile | Select-String -Pattern ":"
		for ($arrPos = 0; $arrPos -lt $_farmers_ip_arr.Count; $arrPos++)
		{
			$_farmer_metrics_raw = ""
			$_node_metrics_raw = ""
			[array]$_process_state_arr = $null
			if ($_farmers_ip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_farmers_ip_arr[$arrPos].toString().IndexOf("#") -le 0) {
				$_config = $_farmers_ip_arr[$arrPos].toString().split(":").Trim(" ")
				$_process_type = $_config[0].toString()
				if ($_process_type.toLower().IndexOf("discord") -ge 0) { $_url_discord = "https:" + $_config[2].toString() }
				elseif ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer") { 
					$_host_ip = $_config[1].toString()
					$_host_port = $_config[2].toString()
					$_host_url = $_host_ip + ":" + $_host_port
					$_hostname = ""
					
					## Experimental
					## Message: start changes here in case of host name resolution related issues while using this tool
					#
					# START COMMENT - Type # in front of the line until the line where it says "STOP COMMENT"
					## What is happening here is an attempt to hide IP info on screen display and use hostname instead
					#try {
					#	$_hostname_obj = [system.net.dns]::gethostentry($_host_ip)
					#	$_hostname = $_hostname_obj.NameHost
					#}
					#catch 
					#{
					#	$_hostname = $_host_ip
					#}
					# STOP COMMENT - Remove the # in front of the next 1 line directly below this line, this will display IP in display
					$_hostname = $_host_ip

					$_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $_url_discord
					$_b_process_running_ok = $_process_state_arr[1]

					if ($_process_type.toLower() -eq "farmer") {
						$_total_spacer_length = ("------------------------------------------------------------------------").Length
						$_spacer_length = $_total_spacer_length
						$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
						Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
						#echo `n
					}
					else {				# get node metrics
						$_node_metrics_raw = $_process_state_arr[0]
						[void]$_node_metrics_raw_arr.add($_node_metrics_raw)
						$_node_metrics_formatted_arr = fParseMetricsToObj $_node_metrics_raw_arr[$_node_metrics_raw_arr.Count - 1]

						$_node_metrics_arr = fGetNodeMetrics $_node_metrics_formatted_arr
						$_node_sync_state = $_node_metrics_arr[0].Sync.State
						$_node_peers_connected = $_node_metrics_arr[0].Peers.Connected
					}
					
					$_console_msg = $_process_type + " status: "
					Write-Host $_console_msg -nonewline -ForegroundColor $_farmer_header_color
					if ($_b_process_running_ok -eq $True) {
						Write-Host "Running" -ForegroundColor green -nonewline
					}
					else {
						Write-Host "Stopped" -ForegroundColor red -nonewline
					}
					Write-Host ", " -nonewline
					Write-Host "Hostname: " -nonewline -ForegroundColor $_farmer_header_color
					if ($_process_type.toLower() -eq "farmer") {
						Write-Host $_hostname -nonewline -ForegroundColor $_farmer_header_data_color
					}
					else {
						Write-Host $_hostname -nonewline
						
						Write-Host ", Synced: " -nonewline -ForegroundColor $_farmer_header_color
						$_node_sync_state_disp_color = "green"
						$_node_sync_state_disp = "Yes"
						if ($_node_sync_state -eq 1) {
							$_node_sync_state_disp = "No"
							$_node_sync_state_disp_color = "red"
						}
						Write-Host $_node_sync_state_disp -nonewline -ForegroundColor $_node_sync_state_disp_color
						Write-Host ", Peers: " -nonewline -ForegroundColor $_farmer_header_color
						Write-Host $_node_peers_connected -ForegroundColor $_farmer_header_data_color
					}
				}
				elseif ($_process_type.toLower().IndexOf("refresh") -ge 0) {
					$refreshTimeScaleInSeconds = [int]$_config[1].toString()
					if ($refreshTimeScaleInSeconds -eq 0 -or $refreshTimeScaleInSeconds -eq "" -or $refreshTimeScaleInSeconds -eq $null) {$refreshTimeScaleInSeconds = 30}
				}

				if ($_process_type.toLower() -ne "farmer") { continue }

				#$_farmer_metrics_raw = fPingMetricsUrl $_host_url
				$_farmer_metrics_raw = $_process_state_arr[0]
				[void]$_farmers_metrics_raw_arr.add($_farmer_metrics_raw)
				$_farmer_metrics_formatted_arr = fParseMetricsToObj $_farmers_metrics_raw_arr[$_farmers_metrics_raw_arr.Count - 1]
				
				# header lables
				$_b_write_header = $True
				#
				$_label_hostname = "Hostname"
				$_label_diskid = "Disk Id"
				$_label_sectors_per_hour = "Sectors/Hour"
				$_label_minutes_per_sectors = "Minutes/Sector"
				$_label_rewards = "Rewards"
				$_label_misses = "Misses"
				$_spacer = " "
				$_total_header_labels = 5
				#
				
				##
				$_disk_metrics_arr = fGetDiskSectorPerformance $_farmer_metrics_formatted_arr
				$_disk_UUId_arr = $_disk_metrics_arr[0].Id
				$_disk_sector_performance_arr = $_disk_metrics_arr[0].Performance
				$_disk_rewards_arr = $_disk_metrics_arr[0].Rewards

				# Write uptime information to console
				foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
				{
					
					if ($_disk_sector_performance_obj) {
					 if ($_disk_sector_performance_obj.Id -eq "overall") {
						$_avg_sectors_per_hour = 0.0
						$_avg_minutes_per_sector = 0.0
						if ($_disk_sector_performance_obj.TotalSeconds -gt 0) {
							$_avg_sectors_per_hour = [math]::Round(($_disk_sector_performance_obj.TotalSectors * 3600)/ $_disk_sector_performance_obj.TotalSeconds, 1)
						}
						if ($_disk_sector_performance_obj.TotalSectors) {
							$_avg_minutes_per_sector = [math]::Round($_disk_sector_performance_obj.TotalSeconds / ($_disk_sector_performance_obj.TotalSectors * 60), 1)
						}
						
						$_uptime = fGetElapsedTime $_disk_sector_performance_obj
						$_uptime_disp = $_uptime.days.ToString()+"d "+$_uptime.hours.ToString()+"h "+$_uptime.minutes.ToString()+"m "+$_uptime.seconds.ToString()+"s"

						Write-Host ", " -nonewline
						Write-Host "Uptime: " -nonewline -ForegroundColor $_farmer_header_color
						Write-Host $_uptime_disp -ForegroundColor $_farmer_header_data_color
						#Write-Host ", " -nonewline
						Write-Host "Sectors/Hour (avg): " -nonewline 
						Write-Host $_avg_sectors_per_hour.toString() -nonewline -ForegroundColor $_farmer_header_data_color
						Write-Host ", " -nonewline
						Write-Host "Minutes/Sector (avg): " -nonewline
						Write-Host  $_avg_minutes_per_sector.toString() -ForegroundColor $_farmer_header_data_color
						break
					 }
					}
				}

				$_total_spacer_length = ("------------------------------------------------------------------------").Length
				$_spacer_length = $_total_spacer_length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
				Write-Host $_label_spacer -ForegroundColor $_line_spacer_color

				#foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
				foreach ($_disk_UUId_obj in $_disk_UUId_arr)
				{
					# write header if not already done
					if ($_b_write_header -eq $True) {
						# Host name header info
						# draw line
						if ($_disk_UUId_obj -ne $null) {
							$_total_spacer_length = $_disk_UUId_obj.Id.toString().Length + $_label_sectors_per_hour.Length + $_label_minutes_per_sectors.Length + $_label_rewards.Length +  $_label_misses.Length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
						}
						else {$_total_spacer_length = ("------------------------------------------------------------------------").Length}
						$_spacer_length = $_total_spacer_length
						$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
						if ($_b_first_time -eq $True) {
							$_b_first_time = $False
						}
						 
						#
						$_spacer_length = 0
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline

						Write-Host $_label_diskid -nonewline -ForegroundColor $_disk_header_color
						if ($_disk_UUId_obj -ne $null) {
							$_spacer_length =  $_disk_UUId_obj.Id.toString().Length - $_label_diskid.Length + 1
						}
						else {$_spacer_length = ("------------------------------------------------------------------------").Length}
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline 
						Write-Host $_label_sectors_per_hour -nonewline -ForegroundColor $_disk_header_color

						$_spacer_length = 0
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_label_minutes_per_sectors -nonewline -ForegroundColor $_disk_header_color

						$_spacer_length = 0
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_label_rewards -nonewline -ForegroundColor $_disk_header_color
						
						$_spacer_length = 0
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_label_misses -nonewline -ForegroundColor $_disk_header_color

						$_spacer_length = 0
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer
						#
						# draw line
						if ($_disk_UUId_obj -ne $null) {
							$_spacer_length =  $_disk_UUId_obj.Id.toString().Length + $_label_sectors_per_hour.Length + $_label_minutes_per_sectors.Length + $_label_rewards.Length +  $_label_misses.Length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
						}
						else {$_spacer_length = ("------------------------------------------------------------------------").Length}
						$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
						Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
						#
						$_b_write_header = $False
					}
					#$_disk_sector_performance_obj = $_disk_sector_performance_arr[$arrPos]
					#$_disk_rewards_obj = $_disk_rewards_arr[$arrPos]

					# write data
					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_disk_UUId_obj.Id -nonewline
					
					# Build and write data to console
					$_b_printed_perf_metrics = $False
					$_minutes_per_sector_data_disp = "-"
					foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
					{
						if ($_disk_sector_performance_obj) {
							if ($_disk_sector_performance_obj.Id -eq "overall" -or $_disk_UUId_obj.Id -ne $_disk_sector_performance_obj.Id) { continue }
						}
						#
						$_minutes_per_sector_data_disp = $_disk_sector_performance_obj.MinutesPerSector.ToString()

						$_spacer_length = 1
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_disk_sector_performance_obj.SectorsPerHour -nonewline

						$_spacer_length = [int]($_label_sectors_per_hour.Length - ($_disk_sector_performance_obj.SectorsPerHour).toString().Length)
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_disk_sector_performance_obj.MinutesPerSector -nonewline

						$_b_printed_perf_metrics = $True
					}
					if ($_b_printed_perf_metrics -eq $False)
					{
						$_spacer_length = 1
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host "-" -nonewline

						$_spacer_length = [int]($_label_sectors_per_hour.Length - ("-").toString().Length)
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host "-" -nonewline
					}

					
					$_b_counted_missed_rewards = $False
					$_b_data_printed = $False
					$_missed_rewards_count = 0
					$_missed_rewards_color = "white"
					$_b_printed_reward_metrics = $False
					foreach ($_disk_rewards_obj in $_disk_rewards_arr)
					{
						if ($_disk_UUId_obj.Id -eq $_disk_rewards_obj.Id) {
							if ($_disk_rewards_obj.Misses -gt 0) {
								$_b_counted_missed_rewards = $True
								$_missed_rewards_count = $_disk_rewards_obj.Misses
								$_missed_rewards_color = "red"
								continue
							}

							$_b_data_printed = $True
							
							$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_minutes_per_sector_data_disp.Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer -nonewline
							Write-Host $_disk_rewards_obj.Rewards -nonewline

							$_spacer_length = [int]($_label_rewards.Length - $_disk_rewards_obj.Rewards.toString().Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer -nonewline
							#Write-Host $_disk_rewards_obj.Misses -nonewline
							Write-Host $_missed_rewards_count -nonewline -ForegroundColor $_missed_rewards_color

							$_spacer_length = [int]($_label_misses.Length - $_disk_rewards_obj.Misses.toString().Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer
							$_b_printed_reward_metrics = $True

						}
					}
					if ($_b_counted_missed_rewards -eq $True -and $_b_data_printed -eq $False) {
							# write data - combine missed and rewards into single line of display
							$_b_data_printed = $True

							$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_minutes_per_sector_data_disp.Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer -nonewline
							Write-Host 0 -nonewline		#no rewards data (only misses data) populated in endpoint

							$_spacer_length = [int]($_label_rewards.Length - (0).toString().Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer -nonewline
							#Write-Host $_disk_rewards_obj.Misses -nonewline
							Write-Host $_missed_rewards_count -nonewline

							$_spacer_length = [int]($_label_misses.Length - $_missed_rewards_count.toString().Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer
					}				
					if ($_b_printed_reward_metrics -eq $False) 				# rewards/misses not published yet in endpoint
					{
							$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_minutes_per_sector_data_disp.Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer -nonewline
							Write-Host "-" -nonewline

							$_spacer_length = [int]($_label_rewards.Length - ("-").toString().Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer -nonewline
							Write-Host "-" -nonewline

							$_spacer_length = [int]($_label_misses.Length - ("-").toString().Length)
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							$_label_spacer = $_label_spacer + "|"
							Write-Host $_label_spacer
					}
				}
				#
			}
		}
		#
		# draw finish line
		if ($_disk_sector_performance_obj) {
			if ($_disk_sector_performance_obj.Id -ne "overall") {
				$_spacer_length =  $_disk_sector_performance_obj.Id.toString().Length + $_label_sectors_per_hour.Length + $_label_minutes_per_sectors.Length + $_label_rewards.Length +  $_label_misses.Length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
			}
			else {$_spacer_length = ("------------------------------------------------------------------------").Length}
		}
		else {$_spacer_length = ("------------------------------------------------------------------------").Length}
		$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
		Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
		

		# display latest github version info
		$_gitVersionDisp = " - "
		$_gitVersionDispColor = "red"
		if ($null -ne $gitVersion) {
			$currentVersion = $gitVersion[0] -replace "[^.0-9]"
			$_gitVersionDisp = $gitVersion[0]
			$_gitVersionDispColor = "green"
		}
		echo `n
		Write-Host "Latest github version : " -nonewline
		Write-Host "$($_gitVersionDisp)" -nonewline -ForegroundColor $_gitVersionDispColor

		##
		# display last refresh time 
		#$currentDate = Get-Date -Format HH:mm:ss
		$currentDate = (Get-Date).ToLocalTime().toString()
		# Refresh
		echo `n
		Write-Host "Last refresh on: " -ForegroundColor Yellow -nonewline; Write-Host "$currentDate" -ForegroundColor Green;
		#
		####
		## Auto refresh wait cycle
		#Write-Host "Auto-refresh scheduled for every " -nonewline 
		#Write-Host $refreshTimeScaleInSeconds -nonewline -ForegroundColor yellow
		#Write-Host " seconds"
		#[System.Console]::CursorVisible = $false
		#$iterations = [math]::Ceiling($refreshTimeScaleInSeconds / 5)       
		#for ($i = 0; $i -lt $iterations; $i++) {
		#	Write-Host -NoNewline "." -ForegroundColor Cyan
		#	Start-Sleep 5
		#}
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
}

Function fStartCountdownTimer ([int]$_io_timer_duration) {
	$_sleep_interval_milliseconds = 1000
	$_spinner = '|', '/', '-', '\'
	$_spinnerPos = 0
	$_end_dt = [datetime]::UtcNow.AddSeconds($_io_timer_duration)
	[System.Console]::CursorVisible = $false
	try {
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
	catch { }
}

function fGetElapsedTime ([object]$_io_obj) {
	$_time_in_seconds = 0
	if ($_io_obj) {
		$_time_in_seconds = $_io_obj.Uptime
	}
	$_resp_total_uptime =  New-TimeSpan -seconds $_time_in_seconds
	
	return $_resp_total_uptime
}

function fBuildDynamicSpacer ([int]$ioSpacerLength, [string]$ioSpaceType) {
	$dataSpacerLabel = ""
	for ($k=1;$k -le $ioSpacerLength;$k++) {
		$dataSpacerLabel = $dataSpacerLabel + $ioSpaceType
	}
	return $dataSpacerLabel
}

function fPingMetricsUrl ([string]$ioUrl) {
	.{
		$_response = ""
		$_fullUrl = "http://" + $ioUrl + "/metrics"
		try {
			$farmerObj = Invoke-RestMethod -Method 'GET' -uri $_fullUrl
			if ($farmerObj) {
				$_response = $farmerObj.toString()
			}
		}
		catch {}
	}|Out-Null
	return $_response
}

function fParseMetricsToObj ([string]$_io_rest_str) {

	$_rest_arr = $_io_rest_str -split "# HELP"

	[array]$_response_metrics = $null
	foreach ($_rest_arr_element in $_rest_arr)
	{
		$_part_arr = $_rest_arr_element -split "`n"

		$Help = $_part_arr[0]
		$Type = $_part_arr[1]
		for ($_arr_pos = 2; $_arr_pos -lt $_part_arr.Count; $_arr_pos++)
		{
			$Criteria = ""
			$_part = $_part_arr[$_arr_pos].toString()
			if ($_arr_pos -eq 2 -and $_part.toLower().IndexOf(" unit ") -lt 0 -and $_part.Trim(' ') -ne "" -and $_part.toLower().IndexOf("eof") -lt 0)
			{
				# label
				[array]$_value_arr = ($Type -split ' ').Trim('#')
				$ValueName = $_value_arr[2]
				$LabelName = $_value_arr[1]
				$LabelValue = $null
				$Value = $_value_arr[3]
				
				$_metric = [PSCustomObject]@{
					Name		 = $ValueName
					Id			 = $LabelName
					Instance	 = $LabelValue
					Value		 = $Value
				}
				$_response_metrics += $_metric
				# data
				$_value_arr = ($_part -split ' ')
				$ValueName = $_value_arr[0]
				$LabelName = $null
				$LabelValue = $null
				$Value = $_value_arr[1]
				
				$_metric = [PSCustomObject]@{
					Name		 = $ValueName
					Id			 = $LabelName
					Instance	 = $LabelValue
					Value		 = $Value
				}
				$_response_metrics += $_metric
			}
			elseif ($_part.Trim(' ') -ne "" -and $_part.toLower().IndexOf("eof") -lt 0)
			{
				[array]$_value_arr = ($_part -split '[{}]').Trim(' ')
				#
				if ($_value_arr.Count -ne 1) 							# data with identifer
				{
					$ValueName = $_value_arr[0]
					$Label = $_value_arr[1] -split "="
					$LabelName = $Label[0]
					$LabelValue = $Label[1] -replace '"',''
					$Value = $_value_arr[2]
					$Criteria = $Label[2]
				}
				elseif ($_part.IndexOf("#") -lt 0)						# data no identifer
				{
					$_value_arr = ($_part -split ' ')
					$ValueName = $_value_arr[0]
					$LabelName = $null
					$LabelValue = $null
					$Value = $_value_arr[1]
				}
				else
				{														# unit label
					$_value_arr = ($_part -split ' ').Trim('#')
					$ValueName = $_value_arr[2]
					$LabelName = $_value_arr[1]
					$LabelValue = $null
					$Value = $_value_arr[3]
				}
				$_metric = [PSCustomObject]@{
					Name		 = $ValueName
					Id			 = $LabelName
					Instance	 = $LabelValue
					Value		 = $Value
					Criteria	 = $Criteria
				}
				$_response_metrics += $_metric
			}
		}
	}
	return $_response_metrics
}

function fGetNodeMetrics ([array]$_io_node_metrics_arr) {
	$_resp_node_metrics_arr = [System.Collections.ArrayList]@()

	[array]$_node_sync_arr = $null
	[array]$_node_peers_arr = $null

	$_chain_id_sync = ""
	$_chain_id_peer = ""
	$_node_sync_status = 0
	$_node_peer_count = 0
	#
	foreach ($_metrics_obj in $_io_node_metrics_arr)
	{
		if ($_metrics_obj.Name.IndexOf("substrate_sub_libp2p_is_major_syncing") -ge 0 -and $_metrics_obj.Name.IndexOf("chain") -ge 0) 
		{
			$_node_sync_status = $_metrics_obj.Value
			$_chain_id_sync = $_metrics_obj.Instance
			$_node_sync_info = [PSCustomObject]@{
				Id			= $_chain_id_sync
				State		= $_node_sync_status
			}
			$_node_sync_arr += $_node_sync_info
		}
		elseif ($_metrics_obj.Name.IndexOf("substrate_sub_libp2p_peers_count") -ge 0 -and $_metrics_obj.Name.IndexOf("chain") -ge 0) 
		{
			$_node_peer_count = $_metrics_obj.Value
			$_chain_id_peer = $_metrics_obj.Instance
			$_node_peer_info = [PSCustomObject]@{
				Id				= $_chain_id_peer
				Connected		= $_node_peer_count
			}
			$_node_peers_arr += $_node_peer_info
		}
	}
	#
	$_node_metrics = [PSCustomObject]@{
		Sync		= $_node_sync_arr
		Peers		= $_node_peers_arr
	}
	[void]$_resp_node_metrics_arr.add($_node_metrics)

	return $_resp_node_metrics_arr
}

function fGetDiskSectorPerformance ([array]$_io_farmer_metrics_arr) {
	$_resp_disk_metrics_arr = [System.Collections.ArrayList]@()

	[array]$_resp_UUId_arr = $null
	[array]$_resp_sector_perf_arr = $null
	[array]$_resp_rewards_arr = $null

	$_unit_type = ""
	$_unique_farm_id = ""
	$_farmer_disk_id = ""
	$_farmer_disk_sector_plot_time = 0.00
	$_farmer_disk_sector_plot_count = 0
	$_total_sectors_plot_count = 0
	$_uptime_seconds = 0
	$_total_sectors_plot_time_seconds = 0
	$_total_disk_per_farmer = 0
	#
	$_farmer_disk_id_rewards = ""
	$_farmer_disk_proving_success_count = 0
	$_farmer_disk_proving_misses_count = 0
	#
	foreach ($_metrics_obj in $_io_farmer_metrics_arr)
	{
		if ($_metrics_obj.Name.IndexOf("subspace_farmer_auditing_time_seconds_count") -ge 0 -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		{
			$_uptime_seconds = $_metrics_obj.Value
			$_unique_farm_id = $_metrics_obj.Instance
			$_farm_id_info = [PSCustomObject]@{
				Id		= $_unique_farm_id
			}
			$_resp_UUId_arr += $_farm_id_info
		}
		elseif ($_metrics_obj.Name.IndexOf("subspace_farmer_sector_plotting_time_seconds") -ge 0)
		{
			if ($_metrics_obj.Id.toLower().IndexOf("unit") -ge 0 -or $_metrics_obj.Id.toLower().IndexOf("type") -ge 0)
			{
				$_unit_type = $_metrics_obj.Value.toLower()
				$_farmer_disk_id = ""
			}
			elseif ($_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
			{
				$_farmer_disk_id = $_metrics_obj.Instance
				if ($_metrics_obj.Name.toLower().IndexOf("sum") -ge 0) { $_farmer_disk_sector_plot_time = [double]($_metrics_obj.Value) }
				if ($_metrics_obj.Name.toLower().IndexOf("count") -ge 0) { $_farmer_disk_sector_plot_count = [int]($_metrics_obj.Value) }
				if ($_farmer_disk_sector_plot_time -gt 0 -and $_farmer_disk_sector_plot_count -gt 0) 
				{
					$_sectors_per_hour = 0.0
					$_minutes_per_sector = 0.0
					switch ($_unit_type) {
						"seconds" 	{
							$_sectors_per_hour = [math]::Round(($_farmer_disk_sector_plot_count * 3600) / $_farmer_disk_sector_plot_time, 1)
							$_minutes_per_sector = [math]::Round($_farmer_disk_sector_plot_time / ($_farmer_disk_sector_plot_count * 60), 1)
							$_total_sectors_plot_time_seconds += $_farmer_disk_sector_plot_time
						}
						"minutes" 	{
							$_sectors_per_hour = [math]::Round($_farmer_disk_sector_plot_count / $_farmer_disk_sector_plot_time, 1)
							$_minutes_per_sector = [math]::Round($_farmer_disk_sector_plot_time / $_farmer_disk_sector_plot_count, 1)
							$_total_sectors_plot_time_seconds += ($_farmer_disk_sector_plot_time * 60)
						}
						"hours" 	{
							$_sectors_per_hour = [math]::Round($_farmer_disk_sector_plot_count / ($_farmer_disk_sector_plot_time * 60), 1)
							$_minutes_per_sector = [math]::Round(($_farmer_disk_sector_plot_time * 60) / $_farmer_disk_sector_plot_count, 1)
							$_total_sectors_plot_time_seconds += ($_farmer_disk_sector_plot_time * 3600)
						}
					}
					$_total_disk_per_farmer += 1
					
					$_farmer_disk_sector_plot_time = 0.00
					$_farmer_disk_sector_plot_count = 0
					#
					$_disk_sector_perf = [PSCustomObject]@{
						Id					= $_farmer_disk_id
						SectorsPerHour		= $_sectors_per_hour
						MinutesPerSector	= $_minutes_per_sector
					}
					$_resp_sector_perf_arr += $_disk_sector_perf
				}
			}
		}
		elseif ($_metrics_obj.Name.IndexOf("subspace_farmer_sector_plotted_counter_sectors_total") -ge 0) 
		{
			$_total_sectors_plot_count = [int]($_metrics_obj.Value) 
		}
		elseif ($_metrics_obj.Name.IndexOf("subspace_farmer_proving_time_seconds") -ge 0)
		{
			if ($_metrics_obj.Id.toLower().IndexOf("unit") -ge 0 -or $_metrics_obj.Id.toLower().IndexOf("type") -ge 0)
			{
				$_farmer_disk_id_rewards = ""
			}
			elseif ($_metrics_obj.Id.IndexOf("farm_id") -ge 0 -and $_metrics_obj.Name.toLower().IndexOf("count") -ge 0) 
			{
				$_farmer_id = $_metrics_obj.Instance -split ","
				$_farmer_disk_id_rewards = $_farmer_id[0]
				if ($_metrics_obj.Criteria.toLower().IndexOf("success") -ge 0) {$_farmer_disk_proving_success_count = [int]($_metrics_obj.Value)}
				if ($_metrics_obj.Criteria.toLower().IndexOf("success") -lt 0) {$_farmer_disk_proving_misses_count = [int]($_metrics_obj.Value)}
				#
				#
				$_disk_rewards_metric = [PSCustomObject]@{
					Id		= $_farmer_disk_id_rewards
					Rewards	= $_farmer_disk_proving_success_count
					Misses	= $_farmer_disk_proving_misses_count
				}
				$_resp_rewards_arr += $_disk_rewards_metric
				$_farmer_disk_proving_success_count = 0
				$_farmer_disk_proving_misses_count = 0
			}
		}
	}
	#
	$_disk_sector_perf = [PSCustomObject]@{
		Id					= "overall"
		TotalSectors		= $_total_sectors_plot_count
		TotalSeconds		= $_total_sectors_plot_time_seconds
		TotalDisks			= $_total_disk_per_farmer
		Uptime				= $_uptime_seconds
	}
	$_resp_sector_perf_arr += $_disk_sector_perf

	$_disk_metrics = [PSCustomObject]@{
		Id			= $_resp_UUId_arr
		Performance	= $_resp_sector_perf_arr
		Rewards		= $_resp_rewards_arr
	}
	[void]$_resp_disk_metrics_arr.add($_disk_metrics)

	#return $_resp_sector_perf_arr
	#return $_resp_rewards_arr
	return $_resp_disk_metrics_arr
}

function fSendDiscordNotification ([string]$ioUrl, [string]$ioMsg) {
	$JSON = @{ "content" = $ioMsg; } | convertto-json
	Invoke-WebRequest -uri $ioUrl -Method POST -Body $JSON -Headers @{'Content-Type' = 'application/json'}
}

function fGetProcessState ([string]$_io_process_type, [string]$_io_host_ip, [string]$_io_hostname, [string]$_io_alert_url) {
	$_resp_process_state_arr = [System.Collections.ArrayList]@()

	$_b_process_running_state = $False
	#
	# get process state, send notification if process is stopped/not running
	$_resp = fPingMetricsUrl $_io_host_ip		# needs to be outside of elapsed time check as response is used downstream to eliminiate dup call
	if ($_resp -eq "") {
		$_alert_text = $_io_process_type + " status: Stopped, Hostname:" + $_io_hostname
		try {
			fSendDiscordNotification $_io_alert_url $_alert_text
		}
		catch {}
		#
		$_b_process_running_state = $False
	}
	else { $_b_process_running_state = $True }

	[void]$_resp_process_state_arr.add($_resp)
	[void]$_resp_process_state_arr.add($_b_process_running_state)

	return $_resp_process_state_arr
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

main

