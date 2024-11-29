
function fGetDataForHtml ([array]$_io_farmers_hostip_arr) {
	$_resp_process_metrics_arr = [System.Collections.ArrayList]@()
	[array]$_process_header_arr = $null
	[array]$_process_sub_header_arr = $null
	[array]$_process_data_arr = $null

	for ($arrPos = 0; $arrPos -lt $_io_farmers_hostip_arr.Count; $arrPos++)
	{
		$_farmer_metrics_raw = ""
		$_node_metrics_raw = ""
		$_host_friendly_name = ""
		$_process_resp_raw = $null
		if ($_io_farmers_hostip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_io_farmers_hostip_arr[$arrPos].toString().IndexOf("#") -lt 0) {
			$_config = $_io_farmers_hostip_arr[$arrPos].toString().split(":").Trim(" ")
			$_process_type = $_config[0].toString()
			if ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer") { 
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
				#
				$_process_resp_raw = $null
				foreach ($_process_status_arr_obj in $script:_process_status_arr)
				{
					if ($_process_status_arr_obj)
					{
						if ($_process_status_arr_obj.Id -eq $_host_url)
						{
							$_b_process_running_ok = $_process_status_arr_obj.ProcessStatus
							$_process_resp_raw = $_process_status_arr_obj.ProcessResp
							break
						}
					}
					else {break}
				}
				#
				# get process header information
				$_process_status = "Running"
				if ($_b_process_running_ok -eq $true) {
					$_process_status = "Running"
				}
				else {
					$_process_status = "Stopped"
				}
				
				$_node_sync_state_disp = ""
				$_node_peers_connected = ""
				if ($_process_type.toLower() -eq "node") {				# get node metrics
					$_node_metrics_raw = $_process_resp_raw
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

			$_farmer_metrics_raw = $_process_resp_raw
			[void]$_farmers_metrics_raw_arr.add($_farmer_metrics_raw)
			$_farmer_metrics_formatted_arr = fParseMetricsToObj $_farmers_metrics_raw_arr[$_farmers_metrics_raw_arr.Count - 1]
			#
			[array]$_disk_metrics_arr = $null
			foreach ($_farmer_disk_metrics_arr_obj in $script:_farmer_disk_metrics_arr)
			{
				if ($_farmer_disk_metrics_arr_obj)
				{
					if ($_farmer_disk_metrics_arr_obj.Id -eq $_host_url)
					{
						$_disk_metrics_arr = $_farmer_disk_metrics_arr_obj.MetricsArr
						break
					}
				}
				else {break}
			}
			$_disk_UUId_arr = $_disk_metrics_arr[0].Id
			$_disk_sector_performance_arr = $_disk_metrics_arr[0].Performance
			$_disk_rewards_arr = $_disk_metrics_arr[0].Rewards
			$_disk_misses_arr = $_disk_metrics_arr[0].Misses
			$_disk_plots_completed_arr = $_disk_metrics_arr[0].PlotsCompleted
			$_disk_plots_remaining_arr = $_disk_metrics_arr[0].PlotsRemaining
			$_disk_plots_expired_arr = $_disk_metrics_arr[0].PlotsExpired
			$_disk_plots_expiring_arr = $_disk_metrics_arr[0].PlotsAboutToExpire

			# get process data information
			$_process_completed_sectors = 0
			$_process_completed_sectors_disp = "-"
			$_process_total_sectors = 0
			$_process_total_sectors_disp = "-"
			$_process_remaining_sectors = 0
			$_process_remaining_sectors_disp = "-"
			#
			#
			$_max_process_remaining_sectors = 0
			#
			#
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
				$_replot_sector_count = 0
				$_replot_sector_count_hold = 0
				$_expiring_sector_count = 0
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
						$_disk_plots_remaining = [int]($_disk_plots_remaining_obj.Sectors)
						if ($_disk_plots_remaining -gt 0) {									# determine if actually plotting and not replotting
							$_minutes_per_sector_data_disp = $_disk_sector_performance_obj.MinutesPerSector.ToString()
							$_sectors_per_hour_data_disp = $_disk_sector_performance_obj.SectorsPerHour.ToString()
							if ($_disk_sector_performance_obj.DiskSectorPlotCount -gt 0) {
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

						}
					}
					#$_minutes_per_sector_data_disp = $_disk_sector_performance_obj.MinutesPerSector.ToString()
					#$_sectors_per_hour_data_disp = $_disk_sector_performance_obj.SectorsPerHour.ToString()
				}
				#
				## replot info gathering
				foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
				{
					if ($_disk_plots_remaining_obj) {
						if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
					}
					else {break}
					$_disk_plots_remaining = [int]($_disk_plots_remaining_obj.Sectors)
					if ($_disk_plots_remaining -eq 0) {									# means plotting is at 100% and replotting may be ongoing depending on plotcount > 0
						# expired sectors info
						#$_replot_sector_count = $_disk_sector_performance_obj.DiskSectorPlotCount				# replots were counted in original plot counts so not reliable data point doe replot calc
						foreach ($_disk_plots_expired_obj in $_disk_plots_expired_arr)
						{
							if ($_disk_plots_expired_obj) {
								if ($_disk_UUId_obj.Id -ne $_disk_plots_expired_obj.Id) { continue }
							}
							$_replot_sector_count = [int]($_disk_plots_expired_obj.Sectors)
							break
							#
						}
						#
						# expiring sectors info
						foreach ($_disk_plots_expiring_obj in $_disk_plots_expiring_arr)
						{
							if ($_disk_plots_expiring_obj) {
								if ($_disk_UUId_obj.Id -ne $_disk_plots_expiring_obj.Id) { continue }
							}
							$_expiring_sector_count = [int]($_disk_plots_expiring_obj.Sectors)
							break
						}
						## rebuild storage for replot if more sectors expired or expiring in the meantime as needed
						$_b_add_exp_arr_id = $true
						$_replot_sector_count_hold = 0
						for ($_h = 0; $_h -lt $script:_replot_sector_count_hold_arr.count; $_h++)
						{
							if ($script:_replot_sector_count_hold_arr[$_h]) {
								if ($_disk_UUId_obj.Id -ne $script:_replot_sector_count_hold_arr[$_h].Id) { continue }
								
								if ($script:_replot_sector_count_hold_arr[$_h].ExpiredSectors -eq 0 -or $script:_replot_sector_count_hold_arr[$_h].ExpiredSectors -lt ($_replot_sector_count + $_expiring_sector_count)) 
								{
									$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = $_replot_sector_count + $_expiring_sector_count
								}
								elseif ($_replot_sector_count -eq 0 -and $_expiring_sector_count -eq 0)
								{
									$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = 0
								}
								$_replot_sector_count_hold = $script:_replot_sector_count_hold_arr[$_h].ExpiredSectors
								$_b_add_exp_arr_id = $false
								break
							}
						}
						if ($_b_add_exp_arr_id -eq $true)
						{
							$_expiring_plots_info = [PSCustomObject]@{
								Id				= $_disk_UUId_obj.Id
								ExpiredSectors	= ($_replot_sector_count + $_expiring_sector_count)
							}
							$script:_replot_sector_count_hold_arr += $_expiring_plots_info
							$_replot_sector_count_hold = $_replot_sector_count + $_expiring_sector_count
						}
					}
				}
				#
				## get size, % progresion and ETA
				$_b_printed_size_metrics = $false
				$_total_disk_sectors_disp = "-"
				$_plotting_percent_complete = "-"
				$_plotting_percent_complete_disp = "-"
				$_eta = "-"
				$_eta_disp = "-"
				$_completed_sectors = 0
				$_disk_plotted_size_TiB = "-"
				$_remaining_sectors = 0
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
						
						$_remaining_sectors = [int]($_disk_plots_remaining_obj.Sectors)
						$_completed_sectors = [int]($_disk_plots_completed_obj.Sectors)
						$_disk_plotted_size_TiB = [math]::Round(($_completed_sectors + $_expiring_sector_count + $_replot_sector_count) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
						#$_total_sectors_GiB = $_completed_sectors + $_remaining_sectors
						$_total_sectors_GiB = $_completed_sectors + $_remaining_sectors + $_expiring_sector_count + $_replot_sector_count
						
						$_process_total_disks += 1
						$_process_total_disks_disp = $_process_total_disks
						
						$_process_total_disks_net_plotting += 1
						$_process_total_disks_for_eta = $_process_total_disks_net_plotting
						
						if ($_remaining_sectors -eq 0) {
							$_process_total_disks_net_plotting = $_process_total_disks_net_plotting - 1
							$_process_total_disks_for_eta = $_process_total_disks_net_plotting
						}
						
						$_process_remaining_sectors += $_remaining_sectors
						$_process_remaining_sectors_disp = $_process_remaining_sectors
						#
						#
						if($_remaining_sectors -gt $_max_process_remaining_sectors)
						{
							$_max_process_remaining_sectors = $_remaining_sectors
						}	
						#
						#
						$_process_completed_sectors += $_completed_sectors
						$_process_completed_sectors_disp = $_process_completed_sectors
						$_process_total_sectors += $_total_sectors_GiB
						$_process_total_sectors_disp = $_process_total_sectors
						
						#$_total_disk_sectors_TiB = [math]::Round($_total_sectors_GiB / 1000, 2)
						$_total_disk_sectors_TiB = [math]::Round($_total_sectors_GiB * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)

						#$_total_disk_sectors_disp = $_total_disk_sectors_TiB.ToString() + " TiB"
						$_total_disk_sectors_disp = $_total_disk_sectors_TiB.ToString()
						if ($_total_sectors_GiB -ne 0 -and ($_total_sectors_GiB - $_expiring_sector_count - $_replot_sector_count) -ne 0) {
							#$_plotting_percent_complete = [math]::Round(($_completed_sectors / $_total_sectors_GiB) * 100, 1)
							$_plotting_percent_complete = [math]::Round(($_completed_sectors / ($_total_sectors_GiB - $_expiring_sector_count - $_replot_sector_count)) * 100, 2)
							$_plotting_percent_complete_disp = $_plotting_percent_complete.ToString() + "%"
						}
						if ($_minutes_per_sector_data_disp -ne "-" -and $_sectors_per_hour_data_disp -ne "-") {
							#$_eta = [math]::Round((([double]($_minutes_per_sector_data_disp) * $_remaining_sectors)) / (60 * 24), 2)
							#$_eta_disp = $_eta.toString() + " days"
							$_eta = [double]($_time_per_sector_data_obj.TotalSeconds) * $_remaining_sectors
							$_eta_obj = New-TimeSpan -seconds $_eta
							#$_eta_disp = $_eta_obj.days.ToString()+"d " + $_eta_obj.hours.ToString()+"h " + $_eta_obj.minutes.ToString() + "m "
							$_eta_disp = fConvertTimeSpanToString $_eta_obj
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
				$_misses_data_timeout_disp = "-"
				$_misses_data_rejected_disp = "-"
				$_misses_data_failed_disp = "-"
				foreach ($_disk_misses_obj in $_disk_misses_arr)
				{
					if ($_disk_UUId_obj.Id -ne $_disk_misses_obj.Id) {
							continue
					}
					$_misses_data_disp = $_disk_misses_obj.Misses.ToString()
					$_misses_data_timeout_disp = $_disk_misses_obj.Timeout.ToString()
					$_misses_data_rejected_disp = $_disk_misses_obj.Rejected.ToString()
					$_misses_data_failed_disp = $_disk_misses_obj.Failed.ToString()
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
					SectorsCompleted		= $_disk_plotted_size_TiB
					ETA						= $_eta_disp
					ReplotStatus			= $_replot_sector_count
					ReplotStatusHold		= $_replot_sector_count_hold
					ExpiringSectors			= $_expiring_sector_count
					SectorsPerHour			= $_sectors_per_hour_data_disp
					#MinutesPerSector		= $_minutes_per_sector_data_disp
					MinutesPerSector		= $_time_per_sector_data_obj.TotalSeconds
					Rewards					= $_rewards_data_disp
					Misses					= $_misses_data_disp
					Timeout					= $_misses_data_timeout_disp
					Rejected				= $_misses_data_rejected_disp
					Failed					= $_misses_data_failed_disp
				}
				$_process_data_arr += $_process_data
			}
			
			# get process sub-header information
			$_avg_sectors_per_hour = 0.0
			$_avg_minutes_per_sector = 0.0
			$_avg_seconds_per_sector = 0.0
			$_farm_sector_times = 0.0
			$_uptime = $null
			#$_uptime_disp = "0d 0h 0m 0a"
			$_uptime_disp = "-"
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
						#$_uptime_disp = $_uptime.days.ToString()+"d "+$_uptime.hours.ToString()+"h "+$_uptime.minutes.ToString()+"m "+$_uptime.seconds.ToString()+"s"
						$_uptime_disp = fConvertTimeSpanToString $_uptime
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
			if ($_actual_plotting_disk_count -gt 0)
			{
				$_avg_minutes_per_sector = $_avg_minutes_per_sector / $_actual_plotting_disk_count
				$_avg_sectors_per_hour = $_avg_sectors_per_hour / $_actual_plotting_disk_count
				$_farm_sector_times = $_avg_seconds_per_sector / $_actual_plotting_disk_count
			}
			$_tmp_sector_time_farm = 0
			if ($_process_total_disks_for_eta -gt 0 -and $_avg_sectors_per_hour -gt 0)
			{
				$_tmp_sector_time_farm = [double](3600/ ([double]($_avg_sectors_per_hour) * $_process_total_disks_for_eta))
			}
			$_disk_plots_remaining_arr_sorted = fSortObjArrBySectorRemaining $_disk_plots_remaining_arr $_process_total_disks_for_eta
			$_eta_hold_ = 0
			for ($_h = 0; $_h -lt ($_disk_plots_remaining_arr_sorted | Measure-Object).count; $_h++)
			{
				$_disk_plots_remaining_arr_sorted[$_h].ETA = $_eta_hold_ + [double]($_tmp_sector_time_farm) * $_disk_plots_remaining_arr_sorted[$_h].AdditionalSectorsForETA * $_disk_plots_remaining_arr_sorted[$_h].PlotCountMultiplier
				$_eta_hold_ = $_disk_plots_remaining_arr_sorted[$_h].ETA
			}
			for ($_i = 0; $_i -lt $_process_data_arr.Count; $_i++)
			{
				$_tmp_eta = 0
				$_process_data_arr_obj = $_process_data_arr[$_i]
				if ($_process_data_arr_obj) {
					foreach ($_disk_plots_remaining_sorted_obj in $_disk_plots_remaining_arr_sorted)
					{
						if ($_disk_plots_remaining_sorted_obj) {
							if ($_process_data_arr_obj.DiskId -ne $_disk_plots_remaining_sorted_obj.Id) { continue }
						}
						else {break}
						$_tmp_eta = $_disk_plots_remaining_sorted_obj.ETA
						$_tmp_eta_obj = New-TimeSpan -seconds $_tmp_eta
						$_process_data_arr[$_i].ETA = fConvertTimeSpanToString $_tmp_eta_obj
						break
					}
				}
			}
			
			# build process sub header
			$_process_sub_header = [PSCustomObject]@{
				UUId				= $_host_url
				Hostname			= $_hostname
				ProcessType			= $_process_type
				UptimeTSObj			= $_uptime
				Uptime				= $_uptime_disp
				SectorsPerHourAvg	= $_avg_sectors_per_hour.toString()
				MinutesPerSectorAvg	= $_avg_minutes_per_sector.toString()
				SectorTime			= $_farm_sector_times
				TotalSectors		= $_process_total_sectors_disp
				CompletedSectors	= $_process_completed_sectors_disp
				#RemainingSectors	= $_process_remaining_sectors_disp
				#
				#
				RemainingSectors	= $_max_process_remaining_sectors
				#
				#
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
			$_resp_js += ',SectorsCompleted:' + ' "' + $_io_arr[$j].SectorsCompleted + '"'
			$_resp_js += ',ETA:' + ' "' + $_io_arr[$j].ETA + '"'
			$_resp_js += ',ReplotStatus:' + ' "' + $_io_arr[$j].ReplotStatus + '"'
			$_resp_js += ',SectorsPerHour:' + ' "' + $_io_arr[$j].SectorsPerHour + '"'
			#$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			if ($_io_arr[$j].MinutesPerSector -eq "-") {
				$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			}
			else{
				$_temp_min_per_sector = New-TimeSpan -seconds $_io_arr[$j].MinutesPerSector
				#$_resp_js += ',MinutesPerSector:' + ' "' + ($_temp_min_per_sector.minutes.ToString() + "m " + $_temp_min_per_sector.seconds.ToString() + "s") + '"'
				$_resp_js += ',MinutesPerSector:' + ' "' + (fConvertTimeSpanToString $_temp_min_per_sector) + '"'
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
			$_resp_js += ',SectorsCompleted:' + ' "' + $_io_arr[$j].SectorsCompleted + '"'
			$_resp_js += ',ETA:' + ' "' + $_io_arr[$j].ETA + '"'
			$_resp_js += ',ReplotStatus:' + ' "' + $_io_arr[$j].ReplotStatus + '"'
			$_resp_js += ',SectorsPerHour:' + ' "' + $_io_arr[$j].SectorsPerHour + '"'
			#$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			if ($_io_arr[$j].MinutesPerSector -eq "-") {
				$_resp_js += ',MinutesPerSector:' + ' "' + $_io_arr[$j].MinutesPerSector + '"'
			}
			else {
				$_temp_min_per_sector = New-TimeSpan -seconds $_io_arr[$j].MinutesPerSector
				#$_resp_js += ',MinutesPerSector:' + ' "' + ($_temp_min_per_sector.minutes.ToString() + "m " + $_temp_min_per_sector.seconds.ToString() + "s") + '"'
				$_resp_js += ',MinutesPerSector:' + ' "' + (fConvertTimeSpanToString $_temp_min_per_sector) + '"'
			}
			$_resp_js += ',Rewards:' + ' "' + $_io_arr[$j].Rewards + '"'
			$_resp_js += ',Misses:' + ' "' + $_io_arr[$j].Misses + '"'
			$_resp_js += '}'
		}
	}
	$_resp_js += ']'
	
	return $_resp_js
}
