
function fGetDataForHtml ([array]$_io_farmers_hostip_arr) {
	$_resp_process_metrics_arr = [System.Collections.ArrayList]@()
	[array]$_process_header_arr = $null
	[array]$_process_sub_header_arr = $null
	[array]$_process_data_arr = $null

	$_url_discord = ""
	for ($arrPos = 0; $arrPos -lt $_io_farmers_hostip_arr.Count; $arrPos++)
	{
		$_farmer_metrics_raw = ""
		$_node_metrics_raw = ""
		$_host_friendly_name = ""
		[array]$_process_state_arr = $null
		if ($_io_farmers_hostip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_io_farmers_hostip_arr[$arrPos].toString().IndexOf("#") -lt 0) {
			$_config = $_io_farmers_hostip_arr[$arrPos].toString().split(":").Trim(" ")
			$_process_type = $_config[0].toString()
			if ($_process_type.toLower().IndexOf("discord") -ge 0) { $_url_discord = "https:" + $_config[2].toString() }
			elseif ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer") { 
				$_host_ip = $_config[1].toString()
				$_host_port = $_config[2].toString()
				if ($_config.Count -gt 3) {
					$_host_friendly_name = $_config[3].toString()
				}
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
				if ($_host_friendly_name -and $_host_friendly_name.length -gt 0)
				{
					$_hostname = $_host_friendly_name
				}

				$_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $_url_discord
				$_b_process_running_ok = $_process_state_arr[1]
				#
				# get process header information
				$_process_status = "Running"
				if ($_b_process_running_ok -eq $True) {
					$_process_status = "Running"
				}
				else {
					$_process_status = "Stopped"
				}
				
				$_node_sync_state_disp = ""
				$_node_peers_connected = ""
				if ($_process_type.toLower() -eq "node") {				# get node metrics
					$_node_metrics_raw = $_process_state_arr[0]
					[void]$_node_metrics_raw_arr.add($_node_metrics_raw)
					$_node_metrics_formatted_arr = fParseMetricsToObj $_node_metrics_raw_arr[$_node_metrics_raw_arr.Count - 1]

					$_node_metrics_arr = fGetNodeMetrics $_node_metrics_formatted_arr
					$_node_sync_state = $_node_metrics_arr[0].Sync.State
					$_node_peers_connected = $_node_metrics_arr[0].Peers.Connected
					$_node_sync_state_disp = "Yes"
					if ($_node_sync_state -eq $null) {
						$_node_peers_connected = "-"
						$_node_sync_state_disp = "-"
					}
					elseif ($_node_sync_state -eq 1 -or $_b_process_running_ok -eq $false) {
						$_node_sync_state_disp = "No"
					}
				}
				#
				# build process header
				$_process_header = [PSCustomObject]@{
					UUId				= $_host_url
					Hostname			= $_hostname
					ProcessType			= $_process_type
					State				= $_process_status
					SyncStatus			= $_node_sync_state_disp
					Peers				= $_node_peers_connected
				}
				$_process_header_arr += $_process_header
			}

			if ($_process_type.toLower() -ne "farmer") { continue }

			$_farmer_metrics_raw = $_process_state_arr[0]
			[void]$_farmers_metrics_raw_arr.add($_farmer_metrics_raw)
			$_farmer_metrics_formatted_arr = fParseMetricsToObj $_farmers_metrics_raw_arr[$_farmers_metrics_raw_arr.Count - 1]
			#
			$_disk_metrics_arr = fGetDiskSectorPerformance $_farmer_metrics_formatted_arr
			$_disk_UUId_arr = $_disk_metrics_arr[0].Id
			$_disk_sector_performance_arr = $_disk_metrics_arr[0].Performance
			$_disk_rewards_arr = $_disk_metrics_arr[0].Rewards
			$_disk_misses_arr = $_disk_metrics_arr[0].Misses
			$_disk_plots_completed_arr = $_disk_metrics_arr[0].PlotsCompleted
			$_disk_plots_remaining_arr = $_disk_metrics_arr[0].PlotsRemaining

			# get process data information
			$_process_completed_sectors = 0
			$_process_completed_sectors_disp = "-"
			$_process_total_sectors = 0
			$_process_total_sectors_disp = "-"
			$_process_remaining_sectors = 0
			$_process_remaining_sectors_disp = "-"
			$_process_total_disks = 0
			$_process_total_disks_disp = "-"
			$_process_total_disks_for_eta = 0
			$_process_total_disks_net_plotting = 0
			foreach ($_disk_UUId_obj in $_disk_UUId_arr)
			{
				# get performance - must do first as ETA is calculated based on this information
				$_minutes_per_sector_data_disp = "-"
				$_sectors_per_hour_data_disp = "-"
				$_time_per_sector_data_obj = New-TimeSpan -seconds 0
				$_replot_sector_count = "-"
				foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
				{
					if ($_disk_sector_performance_obj) {
						if ($_disk_sector_performance_obj.Id -eq "overall" -or $_disk_UUId_obj.Id -ne $_disk_sector_performance_obj.Id) { continue }
					}
					#
					foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
					{
						if ($_disk_plots_remaining_obj) {
							if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
						}
						else {break}
						### DELETE - start
						#Write-Host
						#Write-Host "_disk_plots_remaining_obj: " $_disk_plots_remaining_obj
						#Write-Host "_disk_plots_remaining_obj.PlotsRemaining: " $_disk_plots_remaining_obj.Sectors
						#Write-Host "_disk_sector_performance_obj.DiskSectorPlotCount: " $_disk_sector_performance_obj.DiskSectorPlotCount
						#Write-Host "_disk_sector_performance_obj.DiskSectorPlotTime: " $_disk_sector_performance_obj.DiskSectorPlotTime
						#Write-Host "_disk_sector_performance_obj.PlotTimeUnit: " $_disk_sector_performance_obj.PlotTimeUnit
						#Write-Host
						### DELETE - end
						$_disk_plots_remaining = $_disk_plots_remaining_obj.Sectors
						if ($_disk_plots_remaining -gt 0) {									# determine if actually plotting and not replotting
							$_minutes_per_sector_data_disp = $_disk_sector_performance_obj.MinutesPerSector.ToString()
							$_sectors_per_hour_data_disp = $_disk_sector_performance_obj.SectorsPerHour.ToString()
							switch ($_disk_sector_performance_obj.PlotTimeUnit) {
								"seconds" 	{
									$_time_per_sector_data_obj = New-TimeSpan -seconds ($_disk_sector_performance_obj.DiskSectorPlotTime / $_disk_sector_performance_obj.DiskSectorPlotCount)
								}
								"minutes" 	{
									$_time_per_sector_data_obj = New-TimeSpan -seconds (($_disk_sector_performance_obj.DiskSectorPlotTime * 60) / $_disk_sector_performance_obj.DiskSectorPlotCount)
								}
								"hours" 	{
									$_time_per_sector_data_obj = New-TimeSpan -seconds (($_disk_sector_performance_obj.DiskSectorPlotTime * 3600) / $_disk_sector_performance_obj.DiskSectorPlotCount)
								}
							}

						}
						else {																# means plotting is at 100% and replotting may be ongoing depending on plotcount > 0 - check TBD
							$_replot_sector_count = $_disk_sector_performance_obj.DiskSectorPlotCount				# that is all we know as of feb 19 subspace release
							<#
							switch ($_disk_sector_performance_obj.PlotTimeUnit) {
								"seconds" 	{
									$_sectors_per_hour_data_disp = [math]::Round(($_disk_sector_performance_obj.DiskSectorPlotCount * 3600) / $_disk_sector_performance_obj.DiskSectorPlotTime, 1)
									$_minutes_per_sector_data_disp = [math]::Round($_disk_sector_performance_obj.DiskSectorPlotTime / ($_disk_sector_performance_obj.DiskSectorPlotCount * 60), 1)
								}
								"minutes" 	{
									$_sectors_per_hour_data_disp = [math]::Round($_disk_sector_performance_obj.DiskSectorPlotCount / $_disk_sector_performance_obj.DiskSectorPlotTime, 1)
									$_minutes_per_sector_data_disp = [math]::Round($_disk_sector_performance_obj.DiskSectorPlotTime / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
								}
								"hours" 	{
									$_sectors_per_hour_data_disp = [math]::Round($_disk_sector_performance_obj.DiskSectorPlotCount / ($_disk_sector_performance_obj.DiskSectorPlotTime * 60), 1)
									$_minutes_per_sector_data_disp = [math]::Round(($_disk_sector_performance_obj.DiskSectorPlotTime * 60) / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
								}
							}
							#>
						}
					}
					#$_minutes_per_sector_data_disp = $_disk_sector_performance_obj.MinutesPerSector.ToString()
					#$_sectors_per_hour_data_disp = $_disk_sector_performance_obj.SectorsPerHour.ToString()
				}
				# get size, % progresion and ETA
				$_b_printed_size_metrics = $False
				$_total_disk_sectors_disp = "-"
				$_plotting_percent_complete = "-"
				$_plotting_percent_complete_disp = "-"
				$_eta = "-"
				$_eta_disp = "-"
				foreach ($_disk_plots_completed_obj in $_disk_plots_completed_arr)
				{
					if ($_disk_plots_completed_obj) {
						if ($_disk_UUId_obj.Id -ne $_disk_plots_completed_obj.Id) { continue }
					}
					else {break}
					#

					foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
					{
						if ($_disk_plots_remaining_obj) {
							if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
						}
						else {break}
						
						$_reminaing_sectors = [int]($_disk_plots_remaining_obj.Sectors)
						$_completed_sectors = [int]($_disk_plots_completed_obj.Sectors)
						$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors

						$_process_total_disks += 1
						$_process_total_disks_disp = $_process_total_disks
						
						$_process_total_disks_net_plotting += 1
						$_process_total_disks_for_eta = $_process_total_disks_net_plotting
						
						if ($_reminaing_sectors -eq 0) {
							$_process_total_disks_net_plotting = $_process_total_disks_net_plotting - 1
							$_process_total_disks_for_eta = $_process_total_disks_net_plotting
						}
						
						$_process_remaining_sectors += $_reminaing_sectors
						$_process_remaining_sectors_disp = $_process_remaining_sectors

						$_process_completed_sectors += $_completed_sectors
						$_process_completed_sectors_disp = $_process_completed_sectors
						$_process_total_sectors += $_total_sectors_GiB
						$_process_total_sectors_disp = $_process_total_sectors
						
						$_total_disk_sectors_TiB = [math]::Round($_total_sectors_GiB / 1000, 2)
						$_total_disk_sectors_disp = $_total_disk_sectors_TiB.ToString() + " TiB"
						if ($_total_sectors_GiB -ne 0) {
							$_plotting_percent_complete = [math]::Round(($_completed_sectors / $_total_sectors_GiB) * 100, 1)
							$_plotting_percent_complete_disp = $_plotting_percent_complete.ToString() + "%"
						}
						if ($_minutes_per_sector_data_disp -ne "-") {
							#$_eta = [math]::Round((([double]($_minutes_per_sector_data_disp) * $_reminaing_sectors)) / (60 * 24), 2)
							#$_eta_disp = $_eta.toString() + " days"
							$_eta = [double]($_time_per_sector_data_obj.TotalSeconds) * $_reminaing_sectors
							$_eta_obj = New-TimeSpan -seconds $_eta
							$_eta_disp = $_eta_obj.days.ToString()+"d " + $_eta_obj.hours.ToString()+"h " + $_eta_obj.minutes.ToString() + "m "
						}
					}
				}
				# get rewards and misses
				$_rewards_data_disp = "-"
				foreach ($_disk_rewards_obj in $_disk_rewards_arr)
				{
					if ($_disk_UUId_obj.Id -ne $_disk_rewards_obj.Id) {
							continue
					}
					$_rewards_data_disp = $_disk_rewards_obj.Rewards.ToString()
				}

				$_misses_data_disp = "-"
				foreach ($_disk_misses_obj in $_disk_misses_arr)
				{
					if ($_disk_UUId_obj.Id -ne $_disk_misses_obj.Id) {
							continue
					}
					$_misses_data_disp = $_disk_misses_obj.Misses.ToString()
				}
				#
				# build process data
				$_process_data = [PSCustomObject]@{
					UUId					= $_host_url
					Hostname				= $_hostname
					ProcessType				= $_process_type
					DiskId					= $_disk_UUId_obj.Id
					Size					= $_total_disk_sectors_disp
					PercentComplete			= $_plotting_percent_complete_disp
					ETA						= $_eta_disp
					SectorsPerHour			= $_sectors_per_hour_data_disp
					#MinutesPerSector		= $_minutes_per_sector_data_disp
					MinutesPerSector		= $_time_per_sector_data_obj.TotalSeconds
					Rewards					= $_rewards_data_disp
					Misses					= $_misses_data_disp
				}
				$_process_data_arr += $_process_data
			}
			
			# get process sub-header information
			$_avg_sectors_per_hour = 0.0
			$_avg_minutes_per_sector = 0.0
			$_avg_seconds_per_sector = 0.0
			foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
			{
				# get process sub header information
				if ($_disk_sector_performance_obj) {
					if ($_disk_sector_performance_obj.Id -eq "overall") {
						#$_avg_sectors_per_hour = 0.0
						#$_avg_minutes_per_sector = 0.0
						#if ($_disk_sector_performance_obj.TotalSeconds -gt 0) {
						#	$_avg_sectors_per_hour = [math]::Round(($_disk_sector_performance_obj.TotalSectors * 3600)/ $_disk_sector_performance_obj.TotalSeconds, 1)
						#}
						#if ($_disk_sector_performance_obj.TotalSectors) {
						#	$_avg_minutes_per_sector = [math]::Round($_disk_sector_performance_obj.TotalSeconds / ($_disk_sector_performance_obj.TotalSectors * 60), 1)
						#}
						$_uptime = fGetElapsedTime $_disk_sector_performance_obj
						$_uptime_disp = $_uptime.days.ToString()+"d "+$_uptime.hours.ToString()+"h "+$_uptime.minutes.ToString()+"m "+$_uptime.seconds.ToString()+"s"
						#
						## build process sub header
						#$_process_sub_header = [PSCustomObject]@{
						#	UUId				= $_host_url
						#	Hostname			= $_hostname
						#	ProcessType			= $_process_type
						#	Uptime				= $_uptime_disp
						#	SectorsPerHourAvg	= $_avg_sectors_per_hour.toString()
						#	MinutesPerSectorAvg	= $_avg_minutes_per_sector.toString()
						#	TotalSectors		= $_process_total_sectors_disp
						#	CompletedSectors	= $_process_completed_sectors_disp
						#	RemainingSectors	= $_process_remaining_sectors_disp
						#	TotalDisks			= $_process_total_disks_disp
						#	TotalDisksForETA	= $_process_total_disks_for_eta
						#	TotalRewards		= $_disk_sector_performance_obj.TotalRewards.toString()
						#}
						#$_process_sub_header_arr += $_process_sub_header
						#
						break
					}
				}
			}
			#
			## write farm level averages for sector times
			$_actual_plotting_disk_count = 0
			foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
			{
				if ($_disk_sector_performance_obj) {
					if ($_disk_sector_performance_obj.Id -eq "overall") { continue }
				}
				#
				foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
				{
					if ($_disk_plots_remaining_obj) {
						if ($_disk_sector_performance_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
					}
					else {break}
					### DELETE - start
					#Write-Host
					#Write-Host "_disk_plots_remaining_obj: " $_disk_plots_remaining_obj
					#Write-Host "_disk_plots_remaining_obj.PlotsRemaining: " $_disk_plots_remaining_obj.Sectors
					#Write-Host "_disk_sector_performance_obj.DiskSectorPlotCount: " $_disk_sector_performance_obj.DiskSectorPlotCount
					#Write-Host "_disk_sector_performance_obj.DiskSectorPlotTime: " $_disk_sector_performance_obj.DiskSectorPlotTime
					#Write-Host "_disk_sector_performance_obj.PlotTimeUnit: " $_disk_sector_performance_obj.PlotTimeUnit
					#Write-Host
					### DELETE - end
					$_disk_plots_remaining = $_disk_plots_remaining_obj.Sectors
					if ($_disk_plots_remaining -gt 0) {									# determine if actually plotting and not replotting
						#$_avg_minutes_per_sector += $_disk_sector_performance_obj.MinutesPerSector
						#$_avg_sectors_per_hour += $_disk_sector_performance_obj.SectorsPerHour
						$_actual_plotting_disk_count += 1
						switch ($_disk_sector_performance_obj.PlotTimeUnit) {
							"seconds" 	{
								$_avg_sectors_per_hour += [math]::Round(($_disk_sector_performance_obj.DiskSectorPlotCount * 3600) / $_disk_sector_performance_obj.DiskSectorPlotTime, 1)
								$_avg_minutes_per_sector += [math]::Round($_disk_sector_performance_obj.DiskSectorPlotTime / ($_disk_sector_performance_obj.DiskSectorPlotCount * 60), 1)
								$_avg_seconds_per_sector += [math]::Round($_disk_sector_performance_obj.DiskSectorPlotTime / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
							}
							"minutes" 	{
								$_avg_sectors_per_hour += [math]::Round($_disk_sector_performance_obj.DiskSectorPlotCount / $_disk_sector_performance_obj.DiskSectorPlotTime, 1)
								$_avg_minutes_per_sector += [math]::Round($_disk_sector_performance_obj.DiskSectorPlotTime / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
								$_avg_seconds_per_sector += [math]::Round(($_disk_sector_performance_obj.DiskSectorPlotTime * 60) / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
							}
							"hours" 	{
								$_avg_sectors_per_hour += [math]::Round($_disk_sector_performance_obj.DiskSectorPlotCount / ($_disk_sector_performance_obj.DiskSectorPlotTime * 60), 1)
								$_avg_minutes_per_sector += [math]::Round(($_disk_sector_performance_obj.DiskSectorPlotTime * 60) / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
								$_avg_seconds_per_sector += [math]::Round(($_disk_sector_performance_obj.DiskSectorPlotTime * 3600) / $_disk_sector_performance_obj.DiskSectorPlotCount, 1)
							}
						}
					}
					else {																# means plotting is at 100% and replotting may be ongoing depending on plotcount > 0 - check TBD
						# Not needing info for replotting at farm level yet
					}
				}
			}
			### DELETE - start
			#Write-Host "_actual_plotting_disk_count: " $_actual_plotting_disk_count
			### DELETE - end
			$_avg_minutes_per_sector = $_avg_minutes_per_sector / $_actual_plotting_disk_count
			$_avg_sectors_per_hour = $_avg_sectors_per_hour / $_actual_plotting_disk_count
			$_farm_sector_times = $_avg_seconds_per_sector / $_actual_plotting_disk_count

			# build process sub header
			$_process_sub_header = [PSCustomObject]@{
				UUId				= $_host_url
				Hostname			= $_hostname
				ProcessType			= $_process_type
				Uptime				= $_uptime_disp
				SectorsPerHourAvg	= $_avg_sectors_per_hour.toString()
				MinutesPerSectorAvg	= $_avg_minutes_per_sector.toString()
				SectorTime			= $_farm_sector_times
				TotalSectors		= $_process_total_sectors_disp
				CompletedSectors	= $_process_completed_sectors_disp
				RemainingSectors	= $_process_remaining_sectors_disp
				TotalDisks			= $_process_total_disks_disp
				TotalDisksForETA	= $_process_total_disks_for_eta
				TotalRewards		= $_disk_sector_performance_obj.TotalRewards.toString()
			}
			$_process_sub_header_arr += $_process_sub_header




			#
		}
	}
	# get latest github version
	$_gitVersionDisp = " - "
	$_gitVersionDispColor = $_html_red
	if ($null -ne $gitVersion) {
		$currentVersion = $gitVersion[0] -replace "[^.0-9]"
		$_gitVersionDisp = $gitVersion[0]
	}
	# get last refresh datetime 
	$_refresh_date = (Get-Date).ToLocalTime().toString()
	#
	## build process metrics
	$_process_metrics = [PSCustomObject]@{
		ProcessHeader		= $_process_header_arr
		ProcessSubHeader	= $_process_sub_header_arr
		ProcessData			= $_process_data_arr
		GithubVersion		= $_gitVersionDisp
		RefreshedOn			= $_refresh_date			
	}
	[void]$_resp_process_metrics_arr.add($_process_metrics)

	return $_resp_process_metrics_arr
}

function fConverPSArrToJScriptArr ([array]$_io_arr) {
	$_resp_js = ''

	$_resp_js += '['
	for ($j=0; $j -lt $_io_arr.Count; $j++)
	{
		if ($j -eq 0) {
			$_resp_js += '{'
			$_resp_js += 'UUId:' + ' "' + $_io_arr[$j].UUId + '"'
			$_resp_js += ',Hostname:' + ' "' + $_io_arr[$j].Hostname + '"'
			$_resp_js += ',ProcessType:' + ' "' + $_io_arr[$j].ProcessType + '"'
			$_resp_js += ',DiskId:' + ' "' + $_io_arr[$j].DiskId + '"'
			$_resp_js += ',Size:' + ' "' + $_io_arr[$j].Size + '"'
			$_resp_js += ',PercentComplete:' + ' "' + $_io_arr[$j].PercentComplete + '"'
			$_resp_js += ',ETA:' + ' "' + $_io_arr[$j].ETA + '"'
			$_resp_js += ',SectorsPerHour:' + ' "' + $_io_arr[$j].SectorsPerHour + '"'
			#$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			if ($_io_arr[$j].MinutesPerSector -eq "-") {
				$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			}
			else{
				$_temp_min_per_sector = New-TimeSpan -seconds $_io_arr[$j].MinutesPerSector
				$_resp_js += ',MinutesPerSector:' + ' "' + ($_temp_min_per_sector.minutes.ToString() + "m " + $_temp_min_per_sector.seconds.ToString() + "s") + '"'
			}
			$_resp_js += ',Rewards:' + ' "' + $_io_arr[$j].Rewards + '"'
			$_resp_js += ',Misses:' + ' "' + $_io_arr[$j].Misses + '"'
			$_resp_js += '}'
		}
		else
		{
			$_resp_js += ',{'
			$_resp_js += 'UUId:' + ' "' + $_io_arr[$j].UUId + '"'
			$_resp_js += ',Hostname:' + ' "' + $_io_arr[$j].Hostname + '"'
			$_resp_js += ',ProcessType:' + ' "' + $_io_arr[$j].ProcessType + '"'
			$_resp_js += ',DiskId:' + ' "' + $_io_arr[$j].DiskId + '"'
			$_resp_js += ',Size:' + ' "' + $_io_arr[$j].Size + '"'
			$_resp_js += ',PercentComplete:' + ' "' + $_io_arr[$j].PercentComplete + '"'
			$_resp_js += ',ETA:' + ' "' + $_io_arr[$j].ETA + '"'
			$_resp_js += ',SectorsPerHour:' + ' "' + $_io_arr[$j].SectorsPerHour + '"'
			#$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			if ($_io_arr[$j].MinutesPerSector -eq "-") {
				$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			}
			else {
				$_temp_min_per_sector = New-TimeSpan -seconds $_io_arr[$j].MinutesPerSector
				$_resp_js += ',MinutesPerSector:' + ' "' + ($_temp_min_per_sector.minutes.ToString() + "m " + $_temp_min_per_sector.seconds.ToString() + "s") + '"'
			}
			$_resp_js += ',Rewards:' + ' "' + $_io_arr[$j].Rewards + '"'
			$_resp_js += ',Misses:' + ' "' + $_io_arr[$j].Misses + '"'
			$_resp_js += '}'
		}
	}
	$_resp_js += ']'
	
	return $_resp_js
}
