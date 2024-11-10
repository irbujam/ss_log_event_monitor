
function fGetSummaryDataForConsole ([array]$_io_process_arr) {
	#
	#
	$_num_rows = 0
	$_num_cols = 0
	#
	#
	## get process header and disk data
	$_process_metrics_arr = fGetDataForHtml $_io_process_arr
	$_process_header_arr = $_process_metrics_arr[0].ProcessHeader
	$_process_sub_header_arr = $_process_metrics_arr[0].ProcessSubHeader
	$_process_disk_data_arr = $_process_metrics_arr[0].ProcessData
	#
	# define color pallete
	$_header_color = "gray"
	$_header_inner_color = "cyan"
	$_info_label_color = "gray"
	$_info_label_data_color = "yellow"
	#
	##
	$_fg_color_black = "black"
	$_fg_color_white = "gray"
	$_fg_color_green = "green"
	$_fg_color_red = "red"
	$_process_fg_color = $_fg_color_white
	#
	$_bkg_color_green = "green"
	$_bkg_color_red = "red"
	$_process_bkg_color = $_bkg_color_green
	##
	#
	## define process header labels - set 1 of 3
	#$_label_process_type = "Process"
	$_label_serial_num = "#"
	$_label_process_alt_name = "Id"
	#$_label_process_state = "Status "
	#$_label_process_state = "P"
	$_label_process_uptime = "Uptime"
	$_label_process_size = "Size  "
	$_label_process_progress = "%     "
	$_label_process_eta = "ETA   "
	$_label_process_sector_time = "SCT   "
	$_label_process_total_sectors_per_hour = "SCT   "
	$_label_process_total_TiB_per_day = "   PL TiB   "
	$_label_process_disks = "  Plots   "
	$_label_process_replot_disks = "   Replots    "
	$_label_process_rewards = "           Rewards          "
	$_label_process_misses = "  Miss  "
	# node extra columns
	#$_label_process_sync_status = "Synced"
	#$_label_process_peers = "Peers"
	$_label_process_sync_status = "Synced:    "
	$_label_process_peers = "Peers:   "
	## define process header labels - set 2 of 3
	#$_label_process_type_row2 = "Type   "
	$_label_serial_num_row2 = " "
	$_label_process_alt_name_row2 = "  "
	#$_label_process_state_row2 = "       "
	#$_label_process_state_row2 = "W"
	$_label_process_uptime_row2 = "      "
	$_label_process_size_row2 = "(TiB) "
	$_label_process_progress_row2 = "Cmpl  "
	$_label_process_eta_row2 = "      "
	$_label_process_sector_time_row2 = "Time  "
	$_label_process_total_sectors_per_hour_row2 = "PH    "
	$_label_process_total_TiB_per_day_row2 = "------------"
	$_label_process_disks_row2 = "----------"
	$_label_process_replot_disks_row2 = "--------------"
	$_label_process_rewards_row2 = "----------------------------"
	$_label_process_misses_row2 = "--------"
	# node extra columns
	$_label_process_sync_status_row2 = "      "
	$_label_process_peers_row2 = "     "
	## define process header labels - set 3 of 3
	#$_label_process_type_row3 = "       "
	$_label_serial_num_row3 = " "
	$_label_process_alt_name_row3 = "  "
	#$_label_process_state_row3 = "       "
	#$_label_process_state_row3 = "R"
	$_label_process_uptime_row3 = "      "
	$_label_process_size_row3 = "      "
	$_label_process_progress_row3 = "      "
	$_label_process_eta_row3 = "      "
	$_label_process_sector_time_row3 = "      "
	$_label_process_total_sectors_per_hour_row3 = "      "
	$_label_process_total_TiB_per_day_row3 = "Tot/PD      "
	$_label_process_disks_row3 = "#/Cmpl/RM "
	$_label_process_replot_disks_row3 = "EX/RM/% Cmpl  "
	$_label_process_rewards_row3 = "Tot/PPTiB/PH/Est PD/PPTiB PD"
	$_label_process_misses_row3 = "TO/RJ/FL"
	# node extra columns
	$_label_process_sync_status_row3 = "      "
	$_label_process_peers_row3 = "     "
	#
	## node label sizing assessment
	$_label_count_node = 3
	$_label_total_length_node = $script:_process_alt_name_max_length + $_label_process_sync_status.Length + $_label_process_peers.Length
	$_label_separator_count_node = 4
	$_label_line_separator_length_node = $_label_total_length_node + $_label_separator_count_node
	#
	## farmer label sizing assessment
	$_label_count = 13
	$_label_total_length =  $_label_serial_num.Length + $script:_process_farmer_alt_name_max_length + $_label_process_uptime.Length +	$_label_process_size.Length + $_label_process_progress.Length + 
							$_label_process_eta.Length + $_label_process_sector_time.Length + $_label_process_total_sectors_per_hour.Length + $_label_process_total_TiB_per_day.Length + $_label_process_disks.Length + 
							$_label_process_replot_disks.Length + $_label_process_rewards.Length + $_label_process_misses.Length
	$_label_separator_count = 14
	$_num_cols = $_label_total_length + $_label_separator_count + 2
	#
	#
	$_label_line_separator = "_"
	$_label_line_separator_upper = [char](8254)			# overline unicode (reverse of underscore)
	$_label_line_separator_length = $_label_total_length + $_label_separator_count
	#
	$_data_line_separator = "-"
	#
	$_spacer = " "
	#
	for ($arrPos = 0; $arrPos -lt $_io_process_arr.Count; $arrPos++)
	{
		$_farmer_metrics_raw = ""
		$_node_metrics_raw = ""
		[array]$_process_state_arr = $null
		$_b_process_running_ok = $false
		if ($_io_process_arr[$arrPos].toString().Trim(' ') -ne "" -and $_io_process_arr[$arrPos].toString().IndexOf("#") -lt 0) {
			$_config = $_io_process_arr[$arrPos].toString().split(":").Trim(" ")
			$_process_type = $_config[0].toString()
			if ($_process_type.toLower().IndexOf("nats") -ge 0) { 
				$_host_ip = $_config[1].toString()
				$_host_port = $_config[2].toString()
				$_host_friendly_name = ""
				if ($_config.Count -gt 3) {
					$_host_friendly_name = $_config[3].toString()
				}
				$_host_url = $_host_ip + ":" + $_host_port
				$_hostname = ""
				
				$_hostname = $_host_ip
				if ($_host_friendly_name -and $_host_friendly_name.length -gt 0)
				{
					$_hostname = $_host_friendly_name
				}
				#Write-Host
				#$_num_rows += 1
				##
				fWriteNatsServerInfoToConsole $_host_url $_io_process_arr
				$_num_rows += $script:_new_rows_written_to_console + 6		##to acccount for headers and line seperator rows
				##
				Write-Host
				$_num_rows += 1
			}
		}
	}
	#
	## read and display node table
	$_console_header_log = ""
	$_console_header_row2_log = ""
	$_console_header_row3_log = ""
	$_console_header_log_finish_line = ""
	$_b_process_header_printed = $false
	foreach ($_header in $_process_header_arr)
	{
			#
			$_console_data_log_begin = ""
			$_console_data_log_process_state_filler = ""
			$_console_data_log_process_sync_state_filler = ""
			$_console_data_log = ""
			$_console_data_log_end = ""
			#
			## get process identifiers
			$_process_name = $_header.UUId
			$_process_alt_name = $_header.Hostname
			$_process_isOftype = $_header.ProcessType
			$_process_state = $_header.State
			$_process_sync_state = $_header.SyncStatus
			$_process_peers = $_header.Peers
			#
			$_process_state_disp = $_label_line_separator_upper
			#
			if ($_process_isOftype.toLower() -ne "node") { continue }
			#
			## build header and data for console display
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			#
			$_console_data_log_begin = $_label_spacer + $_process_alt_name
			#
			$_console_header_log += $_label_spacer + $_label_process_alt_name
			$_console_header_row2_log += $_label_spacer + $_label_process_alt_name_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_alt_name_row3
			####
			$_spacer_length = [int]($script:_process_alt_name_max_length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			if ($_process_state.toLower() -eq "running") {
				$_process_bkg_color = $_bkg_color_green
			}
			else{
				$_process_bkg_color = $_bkg_color_red
			}
			#
			#
			$_spacer_length = [int]($script:_process_alt_name_max_length - $_process_alt_name.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + ":"
			$_console_data_log_process_state_filler = $_label_spacer #+ $_spacer
			#
			$_spacer_length = [int]($script:_process_alt_name_max_length - $_label_process_alt_name.Length + $_console_data_log_process_state_filler.Length + 1)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_console_header_log += $_label_spacer
			$_console_header_row2_log += $_label_spacer
			$_console_header_row3_log += $_label_spacer
			$_spacer_length = 2
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			if ($_process_sync_state.toLower() -eq "yes") {
				#$_process_fg_color = $_fg_color_white
				$_process_fg_color = $_fg_color_green
			}
			else{
				$_process_fg_color = $_fg_color_red
				$_b_not_used_alert_status = fNotifyProcessOutOfSyncState $_process_isOftype $_process_alt_name
			}
			#
			#
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|" + "Synced: "
			$_console_data_log_process_sync_state_filler = $_label_spacer
			#
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_sync_status
			$_console_header_row2_log += $_label_spacer + $_label_process_sync_status_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_sync_status_row3
			####
			$_spacer_length = [int]($_label_process_sync_status.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_process_sync_status.Length - $_process_sync_state.Length - ("Synced: ").Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|" + "Peers: "
			$_console_data_log_end += $_label_spacer + $_process_peers
			#
			$_spacer_length = [int]($_label_process_sync_status.Length - $_label_process_sync_status.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_peers
			$_console_header_row2_log += $_label_spacer + $_label_process_peers_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_peers_row3
			####
			$_spacer_length = [int]($_label_process_peers.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			# last column delimiter only
			$_spacer_length = [int]($_label_process_peers.Length - $_process_peers.Length - ("Peers: ").Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log_end += $_label_spacer
			#
			$_spacer_length = [int]($_label_process_peers.Length - $_label_process_peers.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer
			$_console_header_row2_log += $_label_spacer
			$_console_header_row3_log += $_label_spacer
			####
			$_spacer_length = [int]($_label_process_peers.Length - $_label_process_peers.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			## write to console
			if (!($_b_process_header_printed))
			{
				###
				$_temp_label_ = "Node:"
				$_spacer_length = $_label_line_separator_length_node
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_label_line_separator
				Write-Host ($_spacer + $_line_separator) -Foregroundcolor $_header_color
				$_num_rows += 1
				$_spacer_length = [math]::Round(($_label_line_separator_length_node - $_temp_label_.Length)/ 2, 0)
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_spacer
				$_line_separator = "|" + $_line_separator 
				Write-Host $_line_separator -nonewline -Foregroundcolor $_header_color
				Write-Host $_temp_label_ -nonewline -Foregroundcolor $_header_inner_color
				$_end_filler_length = $_label_line_separator_length_node - ($_spacer_length + $_temp_label_.Length)
				$_spacer_length = $_end_filler_length
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_spacer
				$_line_separator = $_line_separator + "|"
				Write-Host $_line_separator -Foregroundcolor $_header_color
				$_num_rows += 1
				###
				$_spacer_length = $_label_line_separator_length_node
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_label_line_separator
				Write-Host ("|" + $_line_separator + "|") -Foregroundcolor $_header_color
				$_num_rows += 1
				#
				#Write-Host $_console_header_log -Foregroundcolor $_header_color
				#$_num_rows += 1
				#
				#$_spacer_length = $_label_line_separator_length_node
				#$_line_separator_upper = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				#Write-Host $_console_header_log_finish_line -Foregroundcolor $_header_color
				#$_num_rows += 1
				#
				Write-Host $_console_data_log_begin -nonewline
				Write-Host $_console_data_log_process_state_filler -nonewline
				Write-Host $_process_state_disp -nonewline -ForegroundColor $_fg_color_black -backgroundcolor $_process_bkg_color
				Write-Host $_console_data_log -nonewline
				Write-Host $_console_data_log_process_sync_state_filler -nonewline 
				Write-Host $_process_sync_state -nonewline -ForegroundColor $_process_fg_color
				Write-Host $_console_data_log_end
				$_num_rows += 1
				$_b_process_header_printed = $true
			}
			else 
			{
				Write-Host $_console_data_log_begin -nonewline
				Write-Host $_console_data_log_process_state_filler -nonewline
				Write-Host $_process_state_disp -nonewline -ForegroundColor $_fg_color_black -backgroundcolor $_process_bkg_color
				Write-Host $_console_data_log -nonewline
				Write-Host $_console_data_log_process_sync_state_filler -nonewline 
				Write-Host $_process_sync_state -nonewline -ForegroundColor $_process_fg_color
				Write-Host $_console_data_log_end
				$_num_rows += 1
			}
	}
	#
	# write finish line for node table
	$_spacer_length = $_label_line_separator_length_node
	$_line_separator_upper = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	Write-Host ($_spacer + $_line_separator_upper) -Foregroundcolor $_header_color
	$_num_rows += 1
	#
	#
	##
	## read and display farmer table
	$_console_header_log = ""
	$_console_header_row2_log = ""
	$_console_header_row3_log = ""
	$_console_header_log_finish_line = ""
	$_b_process_header_printed = $false
	#
	##
	$_all_process_sector_PH = 0

	$_all_process_sector_time = 0
	$_all_process_sector_time_eligibility_count = 0
	$_all_process_sectors_per_hour = 0
	#
	$_all_process_size_TiB = 0
	$_all_process_plotted_size_TiB = 0
	$_all_process_size_TiB_disp = "-"
	$_all_process_completed_sectors = 0
	$_all_process_total_sectors = 0
	#$_all_process_progress = 0
	$_all_process_progress_disp = "-"
	$_all_process_rewards = 0
	$_all_process_rewards_per_hour = 0
	$_all_process_misses = 0
	$_all_process_misses_timeout = 0
	$_all_process_misses_rejected = 0
	$_all_process_misses_failed = 0
	$_all_process_misses_disp = "-"
	#
	$_all_process_total_disks = 0
	$_all_process_plotted_disks = 0
	$_all_process_remaining_disks = 0
	$_all_process_disks_disp = "-"
	#
	$_all_process_replot_disks = 0
	$_all_process_replot_disks_hold = 0
	$_all_process_expiring_sectors_count = 0
	#
	##
	#$_individual_farmer_count = 0
	$_individual_farmer_count = -1
	$_individual_farmer_count_disp = "0"
	#
	$script:_individual_farmer_id_arr = $null
	foreach ($_header in $_process_header_arr)
	{
			#
			$_console_data_log_begin = ""
			$_console_data_log_process_state_filler = ""
			$_console_data_log = ""
			$_console_data_log_process_misses_filler = ""
			$_console_data_log_end = ""
			#
			## get process identifiers
			$_process_name = $_header.UUId
			$_process_alt_name = $_header.Hostname
			$_process_isOftype = $_header.ProcessType
			$_process_state = $_header.State
			$_process_sync_state = $_header.SyncStatus
			$_process_peers = $_header.Peers
			#
			$_process_state_disp = $_label_line_separator_upper
			#
			if ($_process_isOftype.toLower() -ne "farmer") { continue }
			#
			###
			$_individual_farmer_count += 1
			$_individual_farmer_count_disp = $_individual_farmer_count.toString()
			if ($_individual_farmer_count -gt 9)
			{
				#$_individual_farmer_count_disp = $script:_char_arr[$_individual_farmer_count - 10]
				$_individual_farmer_count_disp = $script:_char_arr[($_individual_farmer_count + 1) - 10]
			}
			$_individual_farmer_id = [PSCustomObject]@{
				SN					= $_individual_farmer_count_disp
				Id					= $_process_name
				Hostname			= $_process_alt_name
			}
			$script:_individual_farmer_id_arr += $_individual_farmer_id
			###
			#
			## build header and data for console display
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			#
			$_console_data_log_begin += $_label_spacer + $_individual_farmer_count_disp
			$_console_header_log += $_label_spacer + $_label_serial_num
			$_console_header_row2_log += $_label_spacer + $_label_serial_num_row2
			$_console_header_row3_log += $_label_spacer + $_label_serial_num_row3
			####
			$_spacer_length = [int]($_label_serial_num.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_serial_num.Length - $_individual_farmer_count_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			#
			#
			$_console_data_log_begin += $_label_spacer + $_process_alt_name
			#
			$_spacer_length = [int]($_label_serial_num.Length - $_label_serial_num.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_alt_name
			$_console_header_row2_log += $_label_spacer + $_label_process_alt_name_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_alt_name_row3
			####
			$_spacer_length = [int]($script:_process_farmer_alt_name_max_length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			if ($_process_state.toLower() -eq "running") {
				$_process_bkg_color = $_bkg_color_green
			}
			else{
				$_process_bkg_color = $_bkg_color_red
			}
			#
			$_spacer_length = [int]($script:_process_farmer_alt_name_max_length - $_process_alt_name.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + ":"
			$_console_data_log_process_state_filler += $_label_spacer #+ $_spacer
			#
			$_spacer_length = [int]($script:_process_farmer_alt_name_max_length - $_label_process_alt_name.Length + 1 + 1)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_console_header_log += $_label_spacer
			$_console_header_row2_log += $_label_spacer
			$_console_header_row3_log += $_label_spacer
			$_spacer_length = 2
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_console_header_log_finish_line += $_label_spacer
			#
			# get uptime, size, % complete, eta and sector time at process level
			$_process_uptime = "-"
			$_process_uptime_disp = "-"
			$_process_uptime_seconds = 0
			$_process_size_TiB = "-"
			$_plotted_size_TiB = 0
			$_overall_progress = "-"
			$_process_eta_disp = "-"
			#
			$_process_sector_time_disp = "-"
			$_process_total_sectors_per_hour_disp = "-"
			$_process_total_TiB_per_day = 0
			$_process_total_TiB_per_day_disp = "-"
			$_process_total_disks = "-"
			$_process_plotted_disks = "-"
			$_process_remaining_disks = "-"
			$_process_disks_disp = "-"
			$_all_process_sector_time = 0.0
			foreach ($_sub_header in $_process_sub_header_arr)
			{
				if ($_sub_header.UUId -eq $_process_name)
				{
					$_process_uptime = $_sub_header.Uptime
					$_process_uptime_disp = $_process_uptime
					if ($_sub_header.UptimeTSObj -ne $null) 
					{
						$_process_uptime_seconds = $_sub_header.UptimeTSObj.TotalSeconds
						$_process_uptime_disp = fConvertTimeSpanToString $_sub_header.UptimeTSObj
					}
					####
					$_tmp_disk_replot_sctors = 0
					foreach ($_disk_data_obj in $_process_disk_data_arr)
					{
						if ($_sub_header.UUId -eq $_disk_data_obj.UUId)
						{
							$_tmp_disk_replot_sctors += $_disk_data_obj.ReplotStatusHold
						}
					}
					####
					if ($_sub_header.TotalSectors -ne "-")
					{
						#$_process_size_TiB = ([math]::Round([int]($_sub_header.TotalSectors) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)).ToString()
						$_process_size_TiB = ([math]::Round(([int]($_sub_header.TotalSectors) + $_tmp_disk_replot_sctors) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)).ToString()
						#$_plotted_size_TiB = ([math]::Round([int]($_sub_header.CompletedSectors) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)).ToString()
						$_plotted_size_TiB = ([math]::Round(([int]($_sub_header.CompletedSectors) + $_tmp_disk_replot_sctors) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)).ToString()
						#$_all_process_size_TiB += [int]($_sub_header.TotalSectors)
						$_all_process_size_TiB += [int]($_sub_header.TotalSectors) + $_tmp_disk_replot_sctors
						#$_all_process_plotted_size_TiB += [int]($_sub_header.CompletedSectors)
						$_all_process_plotted_size_TiB += [int]($_sub_header.CompletedSectors) + $_tmp_disk_replot_sctors
						#
						#$_overall_progress = ([math]::Round(([int]($_sub_header.CompletedSectors) / [int]($_sub_header.TotalSectors)) * 100, 2)).toString() + "%"
						$_overall_progress = ([math]::Round(([int]($_sub_header.CompletedSectors) / [int]($_sub_header.TotalSectors)) * 100, 2)).toString() + "%"
						$_all_process_completed_sectors += [int]($_sub_header.CompletedSectors)
						$_all_process_total_sectors += [int]($_sub_header.TotalSectors)
						#
						if ($_sub_header.RemainingSectors -ne "-" -and $_sub_header.SectorTime -ne $null -and $_sub_header.TotalDisksForETA -ne 0) {
							$_temp_total_sectors_per_farm = 0
							if ($_sub_header.TotalSectors -ne "-")
							{
								$_temp_total_sectors_per_farm = [double]($_sub_header.TotalSectors)
							}
							$_temp_completed_sectors_per_farm = 0
							if ($_sub_header.CompletedSectors -ne "-")
							{
								$_temp_completed_sectors_per_farm = [double]($_sub_header.CompletedSectors)
							}
							
							$_temp_sector_time_per_farm = 0
							if ([double]($_sub_header.SectorsPerHourAvg) -gt 0 -and $_sub_header.TotalDisksForETA -gt 0)
							{
								$_temp_sector_time_per_farm = [double](3600/ ([double]($_sub_header.SectorsPerHourAvg) * $_sub_header.TotalDisksForETA))
							}
							$_process_eta = [double]($_temp_sector_time_per_farm * ($_temp_total_sectors_per_farm - $_temp_completed_sectors_per_farm))
							
							$_process_eta_obj = New-TimeSpan -seconds $_process_eta
							$_process_eta_disp = fConvertTimeSpanToString $_process_eta_obj
							
							if ($_process_eta -ge $script:_all_process_eta)
							{
								$script:_all_process_eta = $_process_eta
								$script:_all_process_eta_disp = $_process_eta_disp
							}
							#
							$_all_process_sector_PH += [math]::Round(([double]($_sub_header.SectorsPerHourAvg) * $_sub_header.TotalDisksForETA),1)
							if ($_all_process_sector_PH -gt 0)
							{
								$_all_process_sector_time += [double](3600/ $_all_process_sector_PH)
							}
							$_all_process_sector_time_eligibility_count += 1
							$_process_sector_time = New-TimeSpan -seconds $_temp_sector_time_per_farm
							$_process_sector_time_disp = fConvertTimeSpanToString $_process_sector_time
							if ($_temp_sector_time_per_farm -gt 0)
							{
								$_process_total_sectors_per_hour = [math]::Round([double]($_sub_header.SectorsPerHourAvg) * $_sub_header.TotalDisksForETA, 1)
								$_process_total_sectors_per_hour_disp = $_process_total_sectors_per_hour.toString()
								$_process_total_TiB_per_day = [math]::Round(($_process_total_sectors_per_hour * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter) * 24, 2)
								$_process_total_TiB_per_day_disp = $_process_total_TiB_per_day.toString()
							}
						}
					}
					#
					$_process_total_disks = $_sub_header.TotalDisks
					$_process_remaining_disks = $_sub_header.TotalDisksForETA
					if ($_process_remaining_disks -ne "-" -and $_process_total_disks -ne "-")
					{
						$_process_plotted_disks = $_process_total_disks - $_process_remaining_disks
						$_all_process_total_disks  += [int]($_process_total_disks)
						$_all_process_remaining_disks += [int]($_process_remaining_disks)
						$_all_process_plotted_disks += [int]($_process_plotted_disks)
					}
					$_process_disks_disp = $_process_total_disks.ToString() + "/" + $_process_plotted_disks.ToString() + "/" + $_process_remaining_disks.ToString()
					$_all_process_disks_disp = $_all_process_total_disks.ToString() + "/" + $_all_process_plotted_disks.ToString() + "/" + $_all_process_remaining_disks.ToString()
					break
				}
			}
			#
			#
			$_spacer_length = [int]($_process_state_disp.Length - $_spacer.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_uptime_disp
			#
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_uptime
			$_console_header_row2_log += $_label_spacer + $_label_process_uptime_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_uptime_row3
			####
			$_spacer_length = [int]($_label_process_uptime.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_process_uptime.Length - $_process_uptime_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_size_TiB
			#
			$_spacer_length = [int]($_label_process_uptime.Length - $_label_process_uptime.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_size
			$_console_header_row2_log += $_label_spacer + $_label_process_size_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_size_row3
			####
			$_spacer_length = [int]($_label_process_size.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_process_size.Length - $_process_size_TiB.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_overall_progress
			#
			$_spacer_length = [int]($_label_process_size.Length - $_label_process_size.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_progress
			$_console_header_row2_log += $_label_spacer + $_label_process_progress_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_progress_row3
			####
			$_spacer_length = [int]($_label_process_progress.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_process_progress.Length - $_overall_progress.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_eta_disp
			#
			$_spacer_length = [int]($_label_process_progress.Length - $_label_process_progress.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_eta
			$_console_header_row2_log += $_label_spacer + $_label_process_eta_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_eta_row3
			####
			$_spacer_length = [int]($_label_process_eta.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_process_eta.Length - $_process_eta_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_sector_time_disp
			#
			$_spacer_length = [int]($_label_process_eta.Length - $_label_process_eta.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_sector_time
			$_console_header_row2_log += $_label_spacer + $_label_process_sector_time_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_sector_time_row3
			####
			$_spacer_length = [int]($_label_process_sector_time.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			$_spacer_length = [int]($_label_process_sector_time.Length - $_process_sector_time_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_total_sectors_per_hour_disp
			#
			$_spacer_length = [int]($_label_process_sector_time.Length - $_label_process_sector_time.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_total_sectors_per_hour
			$_console_header_row2_log += $_label_spacer + $_label_process_total_sectors_per_hour_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_total_sectors_per_hour_row3
			####
			$_spacer_length = [int]($_label_process_total_sectors_per_hour.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			$_process_plotted_size = "-"
			$_process_plotted_size = $_plotted_size_TiB.ToString() + "/" + $_process_total_TiB_per_day_disp
			#
			#
			$_spacer_length = [int]($_label_process_total_sectors_per_hour.Length - $_process_total_sectors_per_hour_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_plotted_size
			#
			$_spacer_length = [int]($_label_process_total_sectors_per_hour.Length - $_label_process_total_sectors_per_hour.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_total_TiB_per_day
			$_console_header_row2_log += $_label_spacer + $_label_process_total_TiB_per_day_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_total_TiB_per_day_row3
			####
			$_spacer_length = [int]($_label_process_total_TiB_per_day.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			$_spacer_length = [int]($_label_process_total_TiB_per_day.Length - $_process_plotted_size.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_disks_disp
			#
			$_spacer_length = [int]($_label_process_total_TiB_per_day.Length - $_label_process_total_TiB_per_day.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_disks
			$_console_header_row2_log += $_label_spacer + $_label_process_disks_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_disks_row3
			####
			$_spacer_length = [int]($_label_process_disks.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			# get replot, rewards and misses from disk level data and roll-up to process (farm) level
			$_replot_count_ = 0
			$_replot_count_hold = 0
			$_about_to_expire_sectors_count = 0
			$_rewards_ = 0
			$_misses_ = 0
			$_misses_timeout_ = 0
			$_misses_rejected_ = 0
			$_misses_failed_ = 0
			$_process_replot_disks = 0
			$_process_replot_disks_hold = 0
			$_process_expiring_sectors_count = 0
			$_process_rewards = "-"
			$_process_misses = "-"
			$_process_misses_disp = "-"
			$_process_misses_timeout = "-"
			$_process_misses_rejected = "-"
			$_process_misses_failed = "-"
			foreach ($_data in $_process_disk_data_arr)
			{
				if ($_process_name -ne $_data.UUId) {
						continue
				}
				#
				if ($_data.ReplotStatus -ne "-")
				{
					$_replot_count_ += [int]($_data.ReplotStatus)
					$_process_replot_disks = $_replot_count_
					$_all_process_replot_disks += [int]($_data.ReplotStatus)
				}
				if ($_data.ReplotStatusHold -ne "-")
				{
					$_replot_count_hold += [int]($_data.ReplotStatusHold)
					$_process_replot_disks_hold = $_replot_count_hold
					$_all_process_replot_disks_hold  += [int]($_data.ReplotStatusHold)
				}
				if ($_data.ExpiringSectors -ne "-")
				{
					$_about_to_expire_sectors_count += [int]($_data.ExpiringSectors)
					$_process_expiring_sectors_count = $_about_to_expire_sectors_count
					$_all_process_expiring_sectors_count += [int]($_data.ExpiringSectors)
				}
				if ($_data.Rewards -ne "-")
				{
					$_rewards_ += [int]($_data.Rewards)
					$_process_rewards = $_rewards_.ToString()
					$_all_process_rewards += [int]($_data.Rewards)
				}
				if ($_data.Misses -ne "-")
				{
					$_misses_ += [int]($_data.Misses)
					$_misses_timeout_ += [int]($_data.Timeout)
					$_misses_rejected_ += [int]($_data.Rejected)
					$_misses_failed_ += [int]($_data.Failed)
					$_process_misses = $_misses_.ToString()
					if ($_misses_timeout_ -gt 0)
					{
						$_process_misses_timeout = $_misses_timeout_.ToString()
					}
					if ($_misses_rejected_ -gt 0)
					{
						$_process_misses_rejected = $_misses_rejected_.ToString()
					}
					if ($_misses_failed_ -gt 0)
					{
						$_process_misses_failed = $_misses_failed_.ToString()
					}
					$_process_misses_disp = $_process_misses_timeout + "/" + $_process_misses_rejected + "/" + $_process_misses_failed
					$_all_process_misses += [int]($_data.Misses)
					$_all_process_misses_timeout += [int]($_data.Timeout)
					$_all_process_misses_rejected += [int]($_data.Rejected)
					$_all_process_misses_failed += [int]($_data.Failed)
					$_all_process_misses_timeout_disp = "-"
					if ($_all_process_misses_timeout -gt 0)
					{
						$_all_process_misses_timeout_disp = $_all_process_misses_timeout.ToString()
					}
					$_all_process_misses_rejected_disp = "-"
					if ($_all_process_misses_rejected -gt 0)
					{
						$_all_process_misses_rejected_disp = $_all_process_misses_rejected.ToString()
					}
					$_all_process_misses_failed_disp = "-"
					if ($_all_process_misses_failed -gt 0)
					{
						$_all_process_misses_failed_disp = $_all_process_misses_failed.ToString()
					}
					$_all_process_misses_disp = $_all_process_misses_timeout_disp + "/" + $_all_process_misses_rejected_disp + "/" + $_all_process_misses_failed_disp
				}
			}
			$_daily_avg_process_rewards_per_TiB = 0
			$_process_rewards_per_TiB = 0
			$_process_rewards_per_hour = "-"
			$_process_rewards_per_day_estimated = "-"
			if ($_process_uptime_seconds -gt 0 -and $_process_uptime_seconds -ne "-" -and $_process_rewards -ne "-")
			{
				$_process_rewards_per_hour = [math]::Round(([int]($_process_rewards) / $_process_uptime_seconds) * 3600, 1)
				$_all_process_rewards_per_hour += $_process_rewards_per_hour
				$_process_rewards_per_day_estimated = [math]::Round(([int]($_process_rewards) / $_process_uptime_seconds) * 3600 * 24, 1)
			}
			$_process_rewards_disp = "-"
			if ($_process_rewards -ne "-" -and $_plotted_size_TiB -gt 0)
			{
				if ($_process_rewards_per_day_estimated -ne "-")
				{
					$_daily_avg_process_rewards_per_TiB = [math]::Round([int]($_process_rewards_per_day_estimated) / $_plotted_size_TiB, 1)
				}
				$_process_rewards_per_TiB = [math]::Round([int]($_process_rewards) / $_plotted_size_TiB, 1)
				$_process_rewards_disp = $_process_rewards + "/" + $_process_rewards_per_TiB.ToString() + "/" + $_process_rewards_per_hour.ToString() + "/" + $_process_rewards_per_day_estimated.ToString() + "/" + $_daily_avg_process_rewards_per_TiB.ToString()
			}
			#
			#
			$_spacer_length = [int]($_label_process_disks.Length - $_process_disks_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_replot_progress = "-"
			$_remaining_sectors_for_replot = $_process_replot_disks + $_process_expiring_sectors_count
			if ($_process_replot_disks_hold -gt 0)
			{
				$_replot_progress = ([math]::Round((($_process_replot_disks_hold - $_remaining_sectors_for_replot) / $_process_replot_disks_hold) * 100, 1)).ToString() + "%"
			}
			$_process_replot_sector_count_disp = $_process_replot_disks_hold.toString() + "/" + $_remaining_sectors_for_replot.toString() + "/" + $_replot_progress
			if ($_process_replot_disks_hold -eq 0) {
				if ($_process_expiring_sectors_count -gt 0)
				{
					$_process_replot_sector_count_disp = $_process_expiring_sectors_count.ToString() + "/" + "-" + "/" + "-"
				}
				else
				{
					$_process_replot_sector_count_disp = "-"
				}
			}
			$_console_data_log += $_label_spacer + $_process_replot_sector_count_disp
			#
			$_spacer_length = [int]($_label_process_disks.Length - $_label_process_disks.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_replot_disks
			$_console_header_row2_log += $_label_spacer + $_label_process_replot_disks_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_replot_disks_row3
			####
			$_spacer_length = [int]($_label_process_replot_disks.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			$_spacer_length = [int]($_label_process_replot_disks.Length - $_process_replot_sector_count_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log += $_label_spacer + $_process_rewards_disp
			#
			$_spacer_length = [int]($_label_process_replot_disks.Length - $_label_process_replot_disks.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_rewards
			$_console_header_row2_log += $_label_spacer + $_label_process_rewards_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_rewards_row3
			####
			$_spacer_length = [int]($_label_process_rewards.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			if ($_process_misses -eq "-" -or $_process_misses -eq "0") {
				$_process_fg_color = $_fg_color_white
			}
			else{
				$_process_fg_color = $_fg_color_red
			}
			#
			#
			$_spacer_length = [int]($_label_process_rewards.Length - $_process_rewards_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log_process_misses_filler = $_label_spacer
			#
			$_spacer_length = [int]($_label_process_rewards.Length - $_label_process_rewards.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer + $_label_process_misses
			$_console_header_row2_log += $_label_spacer + $_label_process_misses_row2
			$_console_header_row3_log += $_label_spacer + $_label_process_misses_row3
			####
			$_spacer_length = [int]($_label_process_misses.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			# last column delimiter only
			#$_spacer_length = [int]($_label_process_misses.Length - $_process_misses.Length)
			$_spacer_length = [int]($_label_process_misses.Length - $_process_misses_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_data_log_end += $_label_spacer
			#
			$_spacer_length = [int]($_label_process_misses.Length - $_label_process_misses.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			$_console_header_log += $_label_spacer
			$_console_header_row2_log += $_label_spacer
			$_console_header_row3_log += $_label_spacer
			####
			$_spacer_length = [int]($_label_process_misses.Length - $_label_process_misses.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			$_console_header_log_finish_line += $_label_spacer
			#
			#
			## write to console
			if (!($_b_process_header_printed))
			{
				###
				$_temp_label_ = "Farm:"
				$_spacer_length = $_label_line_separator_length
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_label_line_separator
				Write-Host ($_spacer + $_line_separator) -Foregroundcolor $_header_color
				$_num_rows += 1
				$_spacer_length = [math]::Round(($_label_line_separator_length - $_temp_label_.Length)/ 2, 0)
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_spacer
				$_line_separator = "|" + $_line_separator 
				Write-Host $_line_separator -nonewline -Foregroundcolor $_header_color
				Write-Host $_temp_label_ -nonewline -Foregroundcolor $_header_inner_color
				$_end_filler_length = $_label_line_separator_length - ($_spacer_length + $_temp_label_.Length)
				$_spacer_length = $_end_filler_length
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_spacer
				$_line_separator = $_line_separator + "|"
				Write-Host $_line_separator -Foregroundcolor $_header_color
				$_num_rows += 1
				###
				#
				# reserve spot for overall farm process summary line???
				#
				$_spacer_length = $_label_line_separator_length
				$_line_separator = fBuildDynamicSpacer $_spacer_length $_label_line_separator
				Write-Host ("|" + $_line_separator + "|") -Foregroundcolor $_header_color
				$_num_rows += 1
				#
				Write-Host $_console_header_log -Foregroundcolor $_header_color
				$_num_rows += 1
				Write-Host $_console_header_row2_log -Foregroundcolor $_header_color
				$_num_rows += 1
				Write-Host $_console_header_row3_log -Foregroundcolor $_header_color
				$_num_rows += 1
				#
				$_spacer_length = $_label_line_separator_length
				$_line_separator_upper = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				Write-Host $_console_header_log_finish_line -Foregroundcolor $_header_color
				$_num_rows += 1
				#
				Write-Host $_console_data_log_begin -nonewline
				Write-Host $_console_data_log_process_state_filler -nonewline
				Write-Host $_process_state_disp -nonewline -ForegroundColor $_fg_color_black -backgroundcolor $_process_bkg_color
				Write-Host $_console_data_log -nonewline
				Write-Host $_console_data_log_process_misses_filler -nonewline 
				#Write-Host $_process_misses -nonewline -ForegroundColor $_process_fg_color
				Write-Host $_process_misses_disp -nonewline -ForegroundColor $_process_fg_color
				Write-Host $_console_data_log_end
				$_num_rows += 1
				$_b_process_header_printed = $true
			}
			else 
			{
				Write-Host $_console_data_log_begin -nonewline
				Write-Host $_console_data_log_process_state_filler -nonewline
				Write-Host $_process_state_disp -nonewline -ForegroundColor $_fg_color_black -backgroundcolor $_process_bkg_color
				Write-Host $_console_data_log -nonewline
				Write-Host $_console_data_log_process_misses_filler -nonewline 
				#Write-Host $_process_misses -nonewline -ForegroundColor $_process_fg_color
				Write-Host $_process_misses_disp -nonewline -ForegroundColor $_process_fg_color
				Write-Host $_console_data_log_end
				$_num_rows += 1
			}
	}
	#
	## write finish line
	## write farm aggregates
	$_spacer_length = [int]($_label_serial_num.Length + $script:_process_farmer_alt_name_max_length + $_label_process_uptime.Length + 4)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = " " + $_label_spacer
	$_console_header_log_finish_line = $_label_spacer

	$_spacer_length = [int]($_label_process_size.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_progress.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_eta.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_sector_time.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_total_sectors_per_hour.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_total_TiB_per_day.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_disks.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_replot_disks.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_rewards.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	#$_label_process_misses = "Miss"
	$_spacer_length = [int]($_label_process_misses.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_misses.Length - $_label_process_misses.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	$_label_spacer = "|" + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer
	#
	Write-Host $_console_header_log_finish_line
	$_num_rows += 1

	##
	### write overall farm process summary line at previously reserved spot
	$_all_process_size_TiB_disp = ([math]::Round($_all_process_size_TiB * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2))
	$_all_process_plotted_size_TiB_disp = ([math]::Round($_all_process_plotted_size_TiB * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2))

	if ($_all_process_total_sectors -gt 0)
	{
		$_all_process_progress_disp = ([math]::Round(($_all_process_completed_sectors / $_all_process_total_sectors) * 100, 2)).toString() + "%"
	}
	## farm aggregate sector times
	$_all_process_sector_time_disp = "-"
	if ($_all_process_sector_time_eligibility_count -gt 0)
	{
		if ($_all_process_sector_PH -gt 0)
		{
			$_all_process_sector_time = [double](3600 / $_all_process_sector_PH)
		}
		if ($_all_process_sector_time -gt 0)
		{
			$_all_process_sector_time_obj = New-TimeSpan -seconds $_all_process_sector_time
			$_all_process_sector_time_disp = fConvertTimeSpanToString $_all_process_sector_time_obj
		}
	}
	## farm aggregate sectors per hour
	$_all_process_total_sectors_per_hour = 0
	$_all_process_total_sectors_per_hour_disp = "-"
	$_all_process_total_TiB_per_day = 0
	$_all_process_total_TiB_per_day_disp = "-"
	if ($_all_process_sector_time -gt 0)
	{
		$_all_process_total_sectors_per_hour = $_all_process_sector_PH
		$_all_process_total_sectors_per_hour_disp = ([math]::Round($_all_process_total_sectors_per_hour, 1)).toString()
		$_all_process_total_TiB_per_day = [math]::Round(($_all_process_total_sectors_per_hour * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter) * 24, 2)
		$_all_process_total_TiB_per_day_disp = $_all_process_total_tiB_per_day.toString()
	}
	## farm aggregate rewards
	$_all_process_rewards_per_day_estimated = [math]::Round($_all_process_rewards_per_hour * 24, 1)
	#
	#
	if ($_all_process_misses -eq 0) {
		$_process_fg_color = $_fg_color_white
	}
	else{
		$_process_fg_color = $_fg_color_red
	}
	$_all_process_rewards_per_TiB = 0
	$_all_process_daily_avg_rewards_per_TiB = 0
	if ($_all_process_size_TiB_disp -ne "-" -and [int]($_all_process_plotted_size_TiB_disp) -gt 0)
	{
		if ($_all_process_rewards_per_day_estimated -ne "-")
		{
			$_all_process_daily_avg_rewards_per_TiB = [math]::Round([int]($_all_process_rewards_per_day_estimated) / $_all_process_plotted_size_TiB_disp, 1)
		}
		$_all_process_rewards_per_TiB = [math]::Round([int]($_all_process_rewards) / [int]($_all_process_plotted_size_TiB_disp), 1)
	}
	###
	#
	$_spacer_length = [int]($_label_serial_num.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = " " + $_label_spacer
	$_console_header_log_finish_line = $_label_spacer

	$_spacer_length = [int]($script:_process_farmer_alt_name_max_length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = " " + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = 1
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = " " + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_uptime.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = " " + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_size.Length - $_all_process_size_TiB_disp.toString().Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_size_TiB_disp.toString() + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_progress.Length - $_all_process_progress_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_progress_disp + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_eta.Length - $script:_all_process_eta_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $script:_all_process_eta_disp + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_sector_time.Length - $_all_process_sector_time_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_sector_time_disp + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_total_sectors_per_hour.Length - $_all_process_total_sectors_per_hour_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_total_sectors_per_hour_disp + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_all_process_TiB_plotted_aggregate = "-"
	if ($_all_process_plotted_size_TiB_disp -ne "-" -and $_all_process_plotted_size_TiB_disp -ne 0)
	{
		$_all_process_TiB_plotted_aggregate = $_all_process_plotted_size_TiB_disp.ToString() + "/" + $_all_process_total_TiB_per_day_disp
	}

	$_spacer_length = [int]($_label_process_total_TiB_per_day.Length - $_all_process_TiB_plotted_aggregate.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_TiB_plotted_aggregate + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	$_spacer_length = [int]($_label_process_disks.Length - $_all_process_disks_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_disks_disp +  $_label_spacer
	$_console_header_log_finish_line += $_label_spacer
	#
	$_all_replot_progress = "-"
	$_all_remaining_sectors_for_replot = $_all_process_replot_disks + $_all_process_expiring_sectors_count
	if ($_all_process_replot_disks_hold -gt 0)
	{
		$_all_replot_progress = ([math]::Round((($_all_process_replot_disks_hold - $_all_remaining_sectors_for_replot) / $_all_process_replot_disks_hold) * 100, 1)).ToString() + "%"
	}
	$_all_process_replot_sector_count_disp = $_all_process_replot_disks_hold.toString() + "/" + $_all_remaining_sectors_for_replot.toString() + "/" + $_all_replot_progress
	if ($_all_process_replot_disks_hold -eq 0) {
		if ($_all_process_expiring_sectors_count -gt 0)
		{
			$_all_process_replot_sector_count_disp = $_all_process_expiring_sectors_count.ToString() + "/" + "-" + "/" + "-"
		}
		else
		{
			$_all_process_replot_sector_count_disp = "-"
		}
	}
	$_spacer_length = [int]($_label_process_replot_disks.Length) - $_all_process_replot_sector_count_disp.Length
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_all_process_replot_sector_count_disp + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer
	#
	$_aggregate_rewards_disp = "-"
	if ($_all_process_rewards -gt 0)
	{
		$_aggregate_rewards_disp = $_all_process_rewards.toString() + "/" + $_all_process_rewards_per_TiB.toString() + "/" + $_all_process_rewards_per_hour.toString() + "/" + 
									$_all_process_rewards_per_day_estimated.toString() + "/" + $_all_process_daily_avg_rewards_per_TiB.ToString()
	}
	$_spacer_length = [int]($_label_process_rewards.Length - $_aggregate_rewards_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_aggregate_rewards_disp + $_label_spacer
	$_console_header_log_finish_line += $_label_spacer

	#$_label_process_misses = "Miss"
	#$_spacer_length = [int]($_label_process_misses.Length - $_all_process_misses.toString().Length)
	$_spacer_length = [int]($_label_process_misses.Length - $_all_process_misses_disp.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	Write-Host ($_console_header_log_finish_line + "|")-nonewline
	#Write-Host $_all_process_misses.toString() -nonewline -ForegroundColor $_process_fg_color
	Write-Host $_all_process_misses_disp -nonewline -ForegroundColor $_process_fg_color
	Write-Host $_label_spacer -nonewline

	$_spacer_length = [int]($_label_process_misses.Length - $_label_process_misses.Length)
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	$_label_spacer = "|" + $_label_spacer
	Write-Host $_label_spacer
	$_num_rows += 1
	#
	# write finish line
	$_spacer_length = 2
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	Write-Host $_label_spacer -nonewline -Foregroundcolor $_header_color
	$_spacer_length = [int]($_label_serial_num.Length + $script:_process_farmer_alt_name_max_length + $_label_process_uptime.Length + 3)
	$_line_separator_upper = fBuildDynamicSpacer $_spacer_length $_spacer
	Write-Host $_line_separator_upper -nonewline -Foregroundcolor $_header_color
	$_spacer_length = $_label_line_separator_length - ($_label_serial_num.Length + $script:_process_farmer_alt_name_max_length + $_label_process_uptime.Length + 3) - 2
	$_line_separator_upper = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	Write-Host ($_spacer + $_line_separator_upper) -Foregroundcolor $_header_color
	$_num_rows += 1
	#
	####
	
	## display latest github version info
	$_gitVersionDisp = " - "
	$_gitVersionDispColor = $_html_red
	if ($null -ne $_ss_git_version) {
		$currentVersion = $_ss_git_version[0] -replace "[^.0-9]"
		$_gitVersionDisp = $_ss_git_version[0]
		$_gitVersionDispColor = $_html_green
	}
	
	fDisplayHelpSummary
	#Write-Host "Latest github version : " -nonewline -ForegroundColor $_info_label_color
	#Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor
	#$_num_rows += 1

	## display last refresh time 
	$currentDate = (Get-Date).ToLocalTime().toString()
	# Refresh
	#Write-Host "Last refresh on       : " -ForegroundColor $_info_label_color -nonewline; Write-Host "$currentDate" -ForegroundColor $_info_label_data_color;
	#$_num_rows += 1
	Write-Host "Last refresh on : " -ForegroundColor $_info_label_color -nonewline; Write-Host "$currentDate" -nonewline -ForegroundColor $_info_label_data_color;
	Write-Host ",    Latest autonomys cli github version : " -nonewline -ForegroundColor $_info_label_color
	Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor
	$_num_rows += 1
	#
	fResizePSWindow $_num_rows $_num_cols
	#
}

function fWriteDetailDataToConsole ([array]$_io_farmers_ip_arr) {
	#
	#
	$_num_rows = 0
	$_num_cols = 0
	#
	# define color pallete
	$_header_color = "gray"
	$_header_inner_color = "cyan"
	$_info_label_color = "gray"
	$_info_label_data_color = "yellow"
	#
	$_fg_color_white = "gray"
	$_fg_color_black = "black"
	$_fg_color_green = "green"
	$_fg_color_red = "red"
	#
	$_label_line_separator = "_"
	$_label_line_separator_upper = [char](8254)			# overline unicode (reverse of underscore)
	###
	#$_individual_farmer_count = 0
	$_individual_farmer_count = -1
	$_individual_farmer_count_disp = "0"
	$script:_individual_farmer_id_arr = $null
	###
	$_b_first_farm_process = $true
	#
	## disk id label length
	$_label_disk_id_length = 0
	#
	## header lables
	$_label_hostname = "Hostname"
	$_label_diskid = "Plot Id"
	$_label_size = "Size  "
	$_label_percent_complete = "%     "
	$_label_size_plotted = "PL TiB"
	$_label_eta = "ETA   "
	$_label_replot = "   Replots    "
	$_label_sectors_per_hour = "SCT   "
	$_label_minutes_per_sectors = "SCT   "
	$_label_rewards = "Rewards"
	$_label_misses = "  Miss  "
	#
	$_label_hostname_row2 = "        "
	$_label_diskid_row2 = "       "
	$_label_size_row2 = "(TiB) "
	$_label_percent_complete_row2 = "Cmpl  "
	$_label_size_plotted_row2 = "      "
	$_label_eta_row2 = "      "
	$_label_replot_row2 = "EX/RM/% Cmpl  "
	$_label_sectors_per_hour_row2 = "PH    "
	$_label_minutes_per_sectors_row2 = "Time  "
	$_label_rewards_row2 = "       "
	$_label_misses_row2 = "TO/RJ/FL"
	#
	$_spacer = " "
	$_total_header_length = $_label_size.Length + $_label_percent_complete.Length + $_label_size_plotted.Length + $_label_eta.Length + $_label_replot.Length + $_label_sectors_per_hour.Length + $_label_minutes_per_sectors.Length + $_label_rewards.Length + $_label_misses.Length
	$_total_header_labels = 10
	#
	for ($arrPos = 0; $arrPos -lt $_io_farmers_ip_arr.Count; $arrPos++)
	{
		$_farmer_metrics_raw = ""
		$_node_metrics_raw = ""
		[array]$_process_state_arr = $null
		$_b_process_running_ok = $false
		if ($_io_farmers_ip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_io_farmers_ip_arr[$arrPos].toString().IndexOf("#") -lt 0) {
			$_config = $_io_farmers_ip_arr[$arrPos].toString().split(":").Trim(" ")
			$_process_type = $_config[0].toString()
			if ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer" -or $_process_type.toLower().IndexOf("nats") -ge 0) { 
				$_host_ip = $_config[1].toString()
				$_host_port = $_config[2].toString()
				$_host_friendly_name = ""
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

				if (!($_process_type.toLower().IndexOf("nats") -ge 0))
				{
					$_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $script:_url_discord
					$_b_process_running_ok = $_process_state_arr[1]
				}
				
				$_node_peers_connected = 0
				if ($_process_type.toLower().IndexOf("nats") -ge 0)
				{
					fWriteNatsServerInfoToConsole $_host_url $_io_farmers_ip_arr
					$_num_rows += $script:_new_rows_written_to_console + 6		##to acccount for headers and line seperator rows
					Write-Host
					Write-Host
					$_num_rows += 1
				}
				else
				{
				if ($_process_type.toLower() -eq "farmer") {
					$_total_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length     #Change here if header length changes
					$_num_cols = $_total_spacer_length + 2		# extra seperators at start & end of line
					$_spacer_length = $_total_spacer_length - 2
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator
					#
					if ($_b_first_farm_process)
					{
						#Write-Host $_label_line_separator_upper -nonewline -ForegroundColor $_line_spacer_color
						#Write-Host ("" + $_label_spacer + " " ) -ForegroundColor $_line_spacer_color
						Write-Host (" " + $_label_spacer + " " ) -ForegroundColor $_line_spacer_color
						$_num_rows += 1
						$_b_first_farm_process = $false
					}
					else
					{
						#Write-Host " " -nonewline -ForegroundColor $_line_spacer_color
						#
						if($_label_disk_id_length -gt 0)
						{
							$_spacer_length = $_label_disk_id_length + 1
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
							Write-Host (" " + $_label_spacer + " ") -nonewline -ForegroundColor $_line_spacer_color
							$_spacer_length =  $_total_header_length + $_total_header_labels - 2	# excluding line under vertical separators
							$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
							Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
							$_num_rows += 1
						}
						#
						# write a line above process header to provide enclosure
						$_spacer_length = $_total_spacer_length - 2
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator
						Write-Host (" " + $_label_spacer + " " ) -ForegroundColor $_line_spacer_color
						$_num_rows += 1
					}
				}
				elseif ($_process_type.toLower() -eq "node") {				# get node metrics
					$_node_metrics_raw = $_process_state_arr[0]
					[void]$_node_metrics_raw_arr.add($_node_metrics_raw)
					$_node_metrics_formatted_arr = fParseMetricsToObj $_node_metrics_raw_arr[$_node_metrics_raw_arr.Count - 1]

					$_node_metrics_arr = fGetNodeMetrics $_node_metrics_formatted_arr
					$_node_sync_state = $_node_metrics_arr[0].Sync.State
					$_node_peers_connected = $_node_metrics_arr[0].Peers.Connected
				}
				
				#
				if ($_process_type.toLower() -eq "farmer") {
					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
				}
				#
				#
				$_process_header_filler_length = 0
				#
				$_console_msg = $_process_type + ":"
				if ($_process_type.toLower() -eq "farmer")
				{
					###
					$_individual_farmer_count += 1
					$_individual_farmer_count_disp = $_individual_farmer_count.toString()
					if ($_individual_farmer_count -gt 9)
					{
						#$_individual_farmer_count_disp = $script:_char_arr[$_individual_farmer_count - 10]
						$_individual_farmer_count_disp = $script:_char_arr[($_individual_farmer_count + 1) - 10]
					}
					###
					$_console_msg = "Farm #" + $_individual_farmer_count_disp + ":"
				}
				Write-Host $_console_msg -nonewline -ForegroundColor $_farmer_header_color
				$_process_header_filler_length += $_console_msg.Length
				#
				$_console_msg = ""
				$_console_msg_color = ""
				$_process_state_disp = $_label_line_separator_upper
				$_console_msg = $_process_state_disp
				if ($_b_process_running_ok -eq $true) {
					$_console_msg_color = $_html_green
				}
				else {
					$_console_msg_color = $_html_red
				}
				Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
				Write-Host ", " -nonewline
				Write-Host "Host:" -nonewline -ForegroundColor $_farmer_header_color
				Write-Host $_hostname -nonewline -ForegroundColor $_farmer_header_data_color
				$_process_header_filler_length += $_console_msg.Length + (", ").Length + ("Host:").Length + $_hostname.Length

				if ($_process_type.toLower() -eq "node") {
					Write-Host ", " -nonewline
					Write-Host "Synced:" -nonewline -ForegroundColor $_farmer_header_color
					$_node_sync_state_disp_color = $_html_green
					$_node_sync_state_disp = "Yes"
					if ($_node_sync_state -eq $null) {
						$_node_peers_connected = "-"
						$_node_sync_state_disp = "-"
						$_node_sync_state_disp_color = $_html_red
						$_b_not_used_alert_status = fNotifyProcessOutOfSyncState $_process_type $_hostname
					}
					elseif ($_node_sync_state -eq 1 -or $_b_process_running_ok -ne $true) {
						$_node_sync_state_disp = "No"
						$_node_sync_state_disp_color = $_html_red
						$_b_not_used_alert_status = fNotifyProcessOutOfSyncState $_process_type $_hostname
					}
					Write-Host $_node_sync_state_disp -nonewline -ForegroundColor $_node_sync_state_disp_color
					Write-Host ", " -nonewline
					Write-Host "Peers:" -nonewline -ForegroundColor $_farmer_header_color
					Write-Host $_node_peers_connected -ForegroundColor $_farmer_header_data_color
					$_num_rows += 1
				}
				}
			}

			if ($_process_type.toLower() -ne "farmer") { continue }
			
			#
			###
			$_individual_farmer_id = [PSCustomObject]@{
				SN					= $_individual_farmer_count_disp
				Id					= $_host_url
				Hostname			= $_hostname
			}
			$script:_individual_farmer_id_arr += $_individual_farmer_id
			###
			#
			$_farmer_metrics_raw = $_process_state_arr[0]
			[void]$_farmers_metrics_raw_arr.add($_farmer_metrics_raw)
			$_farmer_metrics_formatted_arr = fParseMetricsToObj $_farmers_metrics_raw_arr[$_farmers_metrics_raw_arr.Count - 1]
			
			# header lables
			$_b_write_header = $true
			#
			##
			$_disk_metrics_arr = fGetDiskSectorPerformance $_farmer_metrics_formatted_arr
			$_disk_UUId_arr = $_disk_metrics_arr[0].Id
			$_disk_sector_performance_arr = $_disk_metrics_arr[0].Performance
			$_disk_rewards_arr = $_disk_metrics_arr[0].Rewards
			$_disk_misses_arr = $_disk_metrics_arr[0].Misses
			$_disk_plots_completed_arr = $_disk_metrics_arr[0].PlotsCompleted
			$_disk_plots_remaining_arr = $_disk_metrics_arr[0].PlotsRemaining
			$_disk_plots_expired_arr = $_disk_metrics_arr[0].PlotsExpired
			$_disk_plots_expiring_arr = $_disk_metrics_arr[0].PlotsAboutToExpire
			# Write uptime information to console
			$_avg_sectors_per_hour = 0.0
			$_avg_sectors_per_hour_disp = "-"
			$_avg_minutes_per_sector = 0.0
			$_avg_minutes_per_sector_disp = "-"
			$_avg_seconds_per_sector = 0.0
			#
			[object]$_farm_level_rewards_CursorPosition = $null
			$_rewards_total = 0
			$_rewards_per_hour = 0
			$_rewards_per_day_estimated = 0
			foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
			{
				
				if ($_disk_sector_performance_obj) {
					if ($_disk_sector_performance_obj.Id -eq "overall") {
						$_uptime = fGetElapsedTime $_disk_sector_performance_obj
						$_uptime_disp = fConvertTimeSpanToString $_uptime
						#
						if ($_uptime.TotalHours) {
							$_rewards_per_hour = [math]::Round([double]($_disk_sector_performance_obj.TotalRewards / $_uptime.TotalHours), 1)
							$_rewards_per_day_estimated = [math]::Round([double](($_disk_sector_performance_obj.TotalRewards / $_uptime.TotalHours) * 24), 1)
						}
						#

						Write-Host ", " -nonewline
						Write-Host "Uptime:" -nonewline -ForegroundColor $_farmer_header_color
						Write-Host $_uptime_disp -nonewline -ForegroundColor $_farmer_header_data_color
						$_process_header_filler_length += (", ").Length + ("Uptime:").Length + $_uptime_disp.Length + (", ").Length

						$_rewards_total = [int]($_disk_sector_performance_obj.TotalRewards)
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
			$_farm_sector_times = 0.0
			$_farm_sector_times_disp = "-"
			
			$_farm_sectors_per_hour = 0
			$_farm_sectors_per_hour_disp = "-"
			
			if ($_actual_plotting_disk_count -gt 0) {
				$_avg_seconds_per_sector_disp = [math]::Round($_avg_seconds_per_sector / $_actual_plotting_disk_count, 2)
				$_avg_minutes_per_sector_obj = New-TimeSpan -seconds $_avg_seconds_per_sector_disp
				$_avg_minutes_per_sector_disp = $_avg_minutes_per_sector_obj.minutes.ToString() + "m" + $_avg_minutes_per_sector_obj.seconds.ToString() + "s"
				$_avg_sectors_per_hour = [math]::Round($_avg_sectors_per_hour / $_actual_plotting_disk_count, 2)
				$_avg_sectors_per_hour_disp = $_avg_sectors_per_hour.toString()
				
				$_farm_sectors_per_hour =  [math]::Round($_avg_sectors_per_hour * $_actual_plotting_disk_count, 1)
				$_farm_sectors_per_hour_disp = $_farm_sectors_per_hour.toString()
				#
				if ($_farm_sectors_per_hour -gt 0)
				{
					$_farm_sector_times = [double](3600 / $_farm_sectors_per_hour)
				}
				$_farm_sector_times_obj = New-TimeSpan -seconds $_farm_sector_times
				#
				if ($_farm_sector_times -gt 0)
				{
					$_farm_sector_times_disp = fConvertTimeSpanToString $_farm_sector_times_obj
				}
			}
			#
			#
			## Write farm level Size, % progress and ETA - NEW
			$_process_completed_sectors = 0
			$_process_completed_sectors_disp = "-"
			$_process_remaining_sectors = 0
			$_process_remaining_sectors_disp = "-"
			#
			$_max_process_remaining_sectors = 0
			#
			$_process_total_sectors = 0
			$_process_total_sectors_disp = "-"
			$_process_total_disks = 0
			$_process_total_disks_disp = "-"
			#$_process_total_disks_for_eta = 0
			$_tmp_farm_expired_sector_count = 0
			$_tmp_farm_expiring_sector_count = 0
			foreach ($_disk_UUId_obj in $_disk_UUId_arr)
			{
				$_label_disk_id_length = $_disk_UUId_obj.Id.Length
				#
				# get size, % progresion and ETA at farm level
				foreach ($_disk_plots_completed_obj in $_disk_plots_completed_arr)
				{
					if ($_disk_plots_completed_obj) {
						if ($_disk_UUId_obj.Id -ne $_disk_plots_completed_obj.Id) { continue }
					}
					else {break}
					#

					#$_label_disk_id_length = $_disk_UUId_obj.Id.Length
					foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
					{
						if ($_disk_plots_remaining_obj) {
							if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
						}
						else {break}




						$_disk_plots_remaining = [int]($_disk_plots_remaining_obj.Sectors)
						if ($_disk_plots_remaining -eq 0) # means plotting is at 100% and replotting may be ongoing depending on plotcount > 0
						{									
							# expired sectors info
							foreach ($_disk_plots_expired_obj in $_disk_plots_expired_arr)
							{
								if ($_disk_plots_expired_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_expired_obj.Id) { continue }
								}
								$_tmp_replot_sector_count = [int]($_disk_plots_expired_obj.Sectors)
								$_tmp_farm_expired_sector_count += $_tmp_replot_sector_count
								break
							}
							#
							## expiring sectors info
							foreach ($_disk_plots_expiring_obj in $_disk_plots_expiring_arr)
							{
								if ($_disk_plots_expiring_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_expiring_obj.Id) { continue }
								}
								$_tmp_expiring_sector_count = [int]($_disk_plots_expiring_obj.Sectors)
								$_tmp_farm_expiring_sector_count += $_tmp_expiring_sector_count
								break
							}
						}



						
						$_reminaing_sectors = [int]($_disk_plots_remaining_obj.Sectors)
						$_completed_sectors = [int]($_disk_plots_completed_obj.Sectors)
						$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors

						$_process_total_disks += 1
						$_process_total_disks_disp = $_process_total_disks

						if ($_reminaing_sectors -eq 0) {
							$_process_total_disks = $_process_total_disks - 1
							$_process_total_disks_disp = $_process_total_disks
						}
						
						$_process_remaining_sectors += $_reminaing_sectors
						$_process_remaining_sectors_disp = $_process_remaining_sectors
						#
						#
						if($_reminaing_sectors -gt $_max_process_remaining_sectors)
						{
							$_max_process_remaining_sectors = $_reminaing_sectors
						}	
						#
						#
						$_process_completed_sectors += $_completed_sectors
						$_process_completed_sectors_disp = $_process_completed_sectors

						$_process_total_sectors = $_process_completed_sectors + $_process_remaining_sectors
						$_process_total_sectors_disp = $_process_total_sectors
					}
				}
			}
			#
			#
			$_disk_plots_remaining_arr_sorted = fSortObjArrBySectorRemaining $_disk_plots_remaining_arr $_process_total_disks
			$_eta_hold_ = 0
			#
			for ($_h = 0; $_h -lt ($_disk_plots_remaining_arr_sorted | Measure-Object).count; $_h++)
			{
				$_disk_plots_remaining_arr_sorted[$_h].ETA = $_eta_hold_ + [double]($_farm_sector_times) * $_disk_plots_remaining_arr_sorted[$_h].AdditionalSectorsForETA * $_disk_plots_remaining_arr_sorted[$_h].PlotCountMultiplier
				$_eta_hold_ = $_disk_plots_remaining_arr_sorted[$_h].ETA
			}
			#
			#
			## write process header line end character
			$_spacer_length = $_label_disk_id_length + $_total_header_length + $_total_header_labels + 2 - $_process_header_filler_length
			if ($_label_disk_id_length -eq 0)
			{
				$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length - $_process_header_filler_length
			}
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			Write-Host $_label_spacer
			$_num_rows += 1
			# hold cursor position for farm level rewards
			Write-Host "|" -nonewline
			$_farm_level_rewards_CursorPosition = $host.UI.RawUI.CursorPosition
			Write-Host ""
			$_num_rows += 1
			#
			## build and display farm level progress and ETA
			#
			$_farm_progress = 0
			$_farm_progress_disp = "-"
			if ($_process_total_sectors_disp -ne "-") {
				$_farm_progress = [math]::Round(([int]($_process_completed_sectors) / [int]($_process_total_sectors)) * 100, 2)
				$_farm_progress_disp = $_farm_progress.toString() + "%"
			}
			#
			$_farm_eta = 0
			$_farm_eta_disp = "-"
			#
			if ($_max_process_remaining_sectors -gt 0) 
			{
				$_farm_eta = ($_farm_sector_times * $_process_remaining_sectors)
				$_farm_eta_obj = New-TimeSpan -seconds $_farm_eta
				$_farm_eta_disp =  fConvertTimeSpanToString $_farm_eta_obj
			}
			#
			$_farm_plotted_size = 0
			$_farm_plotted_size_TiB = 0.0
			$_farm_size = 0
			$_farm_size_TiB = 0.0
			$_farm_size_disp = "-"
			if ($_process_total_sectors_disp -ne "-") {
				#$_farm_plotted_size = [int]($_process_completed_sectors)
				$_farm_plotted_size = [int]($_process_completed_sectors) + $_tmp_farm_expired_sector_count + $_tmp_farm_expiring_sector_count
				$_farm_plotted_size_TiB = [math]::Round($_farm_plotted_size * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
				#
				#$_farm_size = [int]($_process_total_sectors)
				$_farm_size = [int]($_process_total_sectors) + $_tmp_farm_expired_sector_count + $_tmp_farm_expiring_sector_count
				$_farm_size_TiB = [math]::Round($_farm_size * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
				$_farm_size_disp = $_farm_size_TiB.ToString() + "TiB"
			}
			#
			#
			### got the farm size here, rewards and rewards position previously - proceed writing to farm header
			#
			# get the current farm header size data cursor position for repositioning later
			$_farm_level_header_data_current_CursorPosition = $host.UI.RawUI.CursorPosition
			#
			# set cursor position to farm header rewards data location
			[Console]::SetCursorPosition($_farm_level_rewards_CursorPosition.X, $_farm_level_rewards_CursorPosition.Y)
			$_rewards_per_TiB = 0
			$_farm_daily_avg_rewards_per_TiB = 0
			if ($_farm_plotted_size_TiB -gt 0)
			{
				$_rewards_per_TiB = [math]::Round($_rewards_total / $_farm_plotted_size_TiB, 1)
				if ($_rewards_per_day_estimated -ne "-")
				{
					$_farm_daily_avg_rewards_per_TiB = [math]::Round([int]($_rewards_per_day_estimated) / $_farm_plotted_size_TiB, 1)
				}
			}
			$_farm_rewards_disp_label = "Rewards(Tot/PPTiB/PH/Est PD/PPTiB PD):"
			$_farm_rewards_disp = $_rewards_total.toString() + "/" + $_rewards_per_TiB.toString() + "/" + $_rewards_per_hour.toString() + "/" + $_rewards_per_day_estimated.toString() + "/" + $_farm_daily_avg_rewards_per_TiB.toString()
			$_spacer_length = $_label_disk_id_length + $_total_header_length + $_total_header_labels - $_farm_rewards_disp.Length - $_farm_rewards_disp_label.Length
			if ($_label_disk_id_length -eq 0)
			{
				$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length - 2 - $_farm_rewards_disp.Length - $_farm_rewards_disp_label.Length
			}
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_farm_rewards_disp_label -nonewline -ForegroundColor $_farmer_header_color
			Write-Host $_farm_rewards_disp -nonewline -ForegroundColor $_farmer_header_data_color
			Write-Host ($_label_spacer + "|") -ForegroundColor $_fg_color_white
			$_num_rows += 1
			#
			#revert back cursor position to last written farm header size data
			[Console]::SetCursorPosition($_farm_level_header_data_current_CursorPosition.X, $_farm_level_header_data_current_CursorPosition.Y)
			###
			#
			## display break-up (disk level) information for a given farm
			#
			$_total_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length
			$_spacer_length = $_total_spacer_length - 2
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator
			Write-Host ("|" + $_label_spacer + "|") -ForegroundColor $_line_spacer_color
			$_num_rows += 1
			#
			$_farm_replot_sector_count = 0
			$_farm_replot_sector_count_hold = 0
			$_farm_expiring_sector_count = 0
			$_farm_misses_count = 0
			$_farm_misses_timeout_count = 0
			$_farm_misses_rejected_count = 0
			$_farm_misses_failed_count = 0
			$_farm_misses_count_disp = "-"
			foreach ($_disk_UUId_obj in $_disk_UUId_arr)
			{
				# write header if not already done
				if ($_b_write_header -eq $true) {
					# Host name header info
					# draw line
					if ($_disk_UUId_obj -ne $null) {
						$_total_spacer_length = $_disk_UUId_obj.Id.toString().Length + $_total_header_length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
					}
					else {$_total_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}
					$_spacer_length = $_total_spacer_length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
					 
					#
					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					#
					#
					## header line #2
					Write-Host $_label_spacer -nonewline

					Write-Host $_label_diskid -nonewline -ForegroundColor $_disk_header_color
					if ($_disk_UUId_obj -ne $null) {
						$_spacer_length =  $_disk_UUId_obj.Id.toString().Length - $_label_diskid.Length + 1
					}
					else {$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}

					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_size -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_percent_complete -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_size_plotted -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_eta -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_replot -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
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
					$_num_rows += 1
					#
					#
					## header line #2
					Write-Host $_label_spacer -nonewline

					Write-Host $_label_diskid_row2 -nonewline -ForegroundColor $_disk_header_color
					if ($_disk_UUId_obj -ne $null) {
						$_spacer_length =  $_disk_UUId_obj.Id.toString().Length - $_label_diskid.Length + 1
					}
					else {$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}

					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_size_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_percent_complete_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_size_plotted_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_eta_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_replot_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline 
					Write-Host $_label_sectors_per_hour_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_label_minutes_per_sectors_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_label_rewards_row2 -nonewline -ForegroundColor $_disk_header_color
					
					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_label_misses_row2 -nonewline -ForegroundColor $_disk_header_color

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer
					$_num_rows += 1

					## NEW - header finish line
					if ($_disk_UUId_obj -ne $null) {
						$_spacer_length =  $_disk_UUId_obj.Id.toString().Length + 1
					}
					else {$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}

					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_size.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_percent_complete.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_size_plotted.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_eta.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_replot.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_sectors_per_hour.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_minutes_per_sectors.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = $_label_rewards.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 
					
					$_spacer_length = $_label_misses.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
					$_label_spacer = "|" + $_label_spacer
					Write-Host $_label_spacer -nonewline 

					$_spacer_length = 0
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer
					$_num_rows += 1
					#
					$_b_write_header = $false
				}

				# write data table
				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"

				Write-Host $_label_spacer -nonewline
				Write-Host $_disk_UUId_obj.Id -nonewline

				# get disk performance data - write after eta is calculated
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
						break
					}
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
					if ($_disk_plots_remaining -eq 0) {									# means plotting is at 100% and replotting may be ongoing depending on plotcount > 0 						}
						# expired sectors info
						foreach ($_disk_plots_expired_obj in $_disk_plots_expired_arr)
						{
							if ($_disk_plots_expired_obj) {
								if ($_disk_UUId_obj.Id -ne $_disk_plots_expired_obj.Id) { continue }
							}
							$_replot_sector_count = [int]($_disk_plots_expired_obj.Sectors)
							$_farm_replot_sector_count += $_replot_sector_count
							break
						}
						#
						## expiring sectors info
						foreach ($_disk_plots_expiring_obj in $_disk_plots_expiring_arr)
						{
							if ($_disk_plots_expiring_obj) {
								if ($_disk_UUId_obj.Id -ne $_disk_plots_expiring_obj.Id) { continue }
							}
							$_expiring_sector_count = [int]($_disk_plots_expiring_obj.Sectors)
							$_farm_expiring_sector_count += $_expiring_sector_count
							break
						}
						## rebuild storage for replot if more sectors expired or expiring in the meantime as needed
						$_b_add_exp_arr_id = $true
						for ($_h = 0; $_h -lt $script:_replot_sector_count_hold_arr.count; $_h++)
						{
							if ($script:_replot_sector_count_hold_arr[$_h]) {
								if ($_disk_UUId_obj.Id -ne $script:_replot_sector_count_hold_arr[$_h].Id) { continue }
							}
							#
							if ($script:_replot_sector_count_hold_arr[$_h].ExpiredSectors -eq 0 -or $script:_replot_sector_count_hold_arr[$_h].ExpiredSectors -lt ($_replot_sector_count + $_expiring_sector_count))
							{
								$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = $_replot_sector_count + $_expiring_sector_count
							}
							elseif ($_replot_sector_count -eq 0 -and $_expiring_sector_count -eq 0)
							{
								$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = 0
							}
							$_replot_sector_count_hold = $script:_replot_sector_count_hold_arr[$_h].ExpiredSectors
							$_farm_replot_sector_count_hold += $_replot_sector_count_hold
							$_b_add_exp_arr_id = $false
							break
						}
						if ($_b_add_exp_arr_id)
						{
							$_expiring_plots_info = [PSCustomObject]@{
								Id				= $_disk_UUId_obj.Id
								ExpiredSectors	= ($_replot_sector_count + $_expiring_sector_count)
							}
							$script:_replot_sector_count_hold_arr += $_expiring_plots_info
							$_replot_sector_count_hold = $_replot_sector_count + $_expiring_sector_count
							$_farm_replot_sector_count_hold += $_replot_sector_count_hold
						}
					}
				}
				#
				## write size, % progresion and ETA
				$_b_printed_size_metrics = $false
				$_size_data_disp = "-"
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
					$_size_data_disp = $_disk_plots_completed_obj.Sectors

					foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
					{
						if ($_disk_plots_remaining_obj) {
							if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
						}
						else {break}
						
						$_reminaing_sectors = [int]($_disk_plots_remaining_obj.Sectors)
						$_completed_sectors = [int]($_disk_plots_completed_obj.Sectors)
						#$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors
						$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors + $_replot_sector_count_hold
						$_total_disk_sectors_TiB = [math]::Round($_total_sectors_GiB * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
						$_total_disk_sectors_disp = $_total_disk_sectors_TiB.ToString()
						if ($_total_sectors_GiB -ne 0) {
							#$_plotting_percent_complete = [math]::Round(($_completed_sectors / $_total_sectors_GiB) * 100, 2)
							$_plotting_percent_complete = [math]::Round(($_completed_sectors / ($_total_sectors_GiB - $_replot_sector_count_hold)) * 100, 2)
							$_plotting_percent_complete_disp = $_plotting_percent_complete.ToString() + "%"
						}
						if ($_minutes_per_sector_data_disp -ne "-") {
							foreach ($_disk_plots_remaining_sorted_obj in $_disk_plots_remaining_arr_sorted)
							{
								if ($_disk_plots_remaining_sorted_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_sorted_obj.Id) { continue }
								}
								else {break}
								$_eta = $_disk_plots_remaining_sorted_obj.ETA
							}
							$_eta_obj = $null
							if ($_eta -ne "-")
							{
								$_eta_obj = New-TimeSpan -seconds $_eta
							}
							$_eta_disp = fConvertTimeSpanToString $_eta_obj
						}
						
						$_spacer_length = 1
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_total_disk_sectors_disp -nonewline

						$_spacer_length = $_label_size.Length - $_total_disk_sectors_disp.Length
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_plotting_percent_complete_disp -nonewline

						#$_total_disk_plotted_TiB = [math]::Round($_completed_sectors * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
						$_total_disk_plotted_TiB = [math]::Round(($_completed_sectors + $_replot_sector_count_hold) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
						$_total_disk_plotted_TiB_disp = "-"
						if ($_total_disk_plotted_TiB -gt 0)
						{
							$_total_disk_plotted_TiB_disp = $_total_disk_plotted_TiB.ToString()
						}

						$_spacer_length = $_label_percent_complete.Length - $_plotting_percent_complete_disp.Length
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_total_disk_plotted_TiB_disp -nonewline

						$_spacer_length = $_label_size_plotted.Length - $_total_disk_plotted_TiB_disp.Length
						$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
						$_label_spacer = $_label_spacer + "|"
						Write-Host $_label_spacer -nonewline
						Write-Host $_eta_disp -nonewline
					}

					$_b_printed_size_metrics = $true
				}
				if ($_b_printed_size_metrics -eq $false)
				{
					$_spacer_length = 1
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host "-" -nonewline
					
					$_spacer_length = $_label_size.Length - ("-").Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host "-" -nonewline

					$_spacer_length = $_label_percent_complete.Length - ("-").Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host "-" -nonewline

					$_spacer_length = $_label_size_plotted.Length - ("-").Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host "-" -nonewline
				}

				# write replotting info
				$_spacer_length = $_label_eta.Length - $_eta_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				$_replot_progress = "-"
				$_remaining_sectors_for_replot = $_replot_sector_count + $_expiring_sector_count
				if ($_replot_sector_count_hold -gt 0)
				{
					$_replot_progress = ([math]::Round((($_replot_sector_count_hold - $_remaining_sectors_for_replot) / $_replot_sector_count_hold) * 100, 1)).ToString() + "%"
				}
				$_replot_sector_count_disp = $_replot_sector_count_hold.ToString() + "/" + $_remaining_sectors_for_replot.ToString() + "/" + $_replot_progress
				if ($_replot_sector_count_hold -eq 0)
				{
					if ($_expiring_sector_count -gt 0)
					{
						$_replot_sector_count_disp = $_expiring_sector_count.ToString() + "/" + "-" + "/" + "-"
					}
					else
					{
						$_replot_sector_count_disp = "-"
					}
				}
				Write-Host $_replot_sector_count_disp -nonewline
				
				# write performance data
				$_spacer_length = $_label_replot.Length - $_replot_sector_count_disp.Length 
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
			
				Write-Host $_label_spacer -nonewline
				Write-Host $_sectors_per_hour_data_disp -nonewline

				$_spacer_length = [int]($_label_sectors_per_hour.Length - $_sectors_per_hour_data_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer -nonewline
				if ($_time_per_sector_data_obj.minutes -gt 0 -or  $_time_per_sector_data_obj.seconds -gt 0)
				{
					$_time_per_sector_disp = $_time_per_sector_data_obj.minutes.ToString() + "m" + $_time_per_sector_data_obj.seconds.ToString() + "s"
				}
				else 
				{
					$_time_per_sector_disp = "-"
				}
				Write-Host $_time_per_sector_disp -nonewline
				
				
				$_b_counted_missed_rewards = $false
				$_b_data_printed = $false
				$_missed_rewards_count = 0
				$_missed_rewards_color = "white"
				$_b_reward_data_printed = $false
				$_rewards_data_disp = "-"
				foreach ($_disk_rewards_obj in $_disk_rewards_arr)
				{
					if ($_disk_UUId_obj.Id -ne $_disk_rewards_obj.Id) {
							continue
					}
					$_rewards_data_disp = $_disk_rewards_obj.Rewards.ToString()

					$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_time_per_sector_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
				
					Write-Host $_label_spacer -nonewline
					Write-Host $_disk_rewards_obj.Rewards -nonewline
					
					$_b_reward_data_printed = $true
				}
				if ($_b_reward_data_printed -eq $false) 				# rewards not published yet in endpoint
				{
					$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_time_per_sector_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer -nonewline
					Write-Host "-" -nonewline
				}


				$_b_misses_data_printed = $false
				foreach ($_disk_misses_obj in $_disk_misses_arr)
				{
					if ($_disk_UUId_obj.Id -ne $_disk_misses_obj.Id) {
							continue
					}
					
					if ($_disk_misses_obj.Misses -gt 0) {
						$_missed_rewards_color = $_html_red
						$_farm_misses_count += [int]($_disk_misses_obj.Misses)
						$_farm_misses_timeout_count += [int]($_disk_misses_obj.Timeout)
						$_farm_misses_rejected_count += [int]($_disk_misses_obj.Rejected)
						$_farm_misses_failed_count += [int]($_disk_misses_obj.Failed)
						$_farm_misses_timeout_count_disp = "-"
						if ($_farm_misses_timeout_count -gt 0)
						{
							$_farm_misses_timeout_count_disp = $_farm_misses_timeout_count.toString()
						}
						$_farm_misses_rejected_count_disp = "-"
						if ($_farm_misses_rejected_count -gt 0)
						{
							$_farm_misses_rejected_count_disp = $_farm_misses_rejected_count.toString()
						}
						$_farm_misses_failed_count_disp = "-"
						if ($_farm_misses_failed_count -gt 0)
						{
							$_farm_misses_failed_count_disp = $_farm_misses_failed_count.toString()
						}
						$_farm_misses_count_disp = $_farm_misses_timeout_count_disp + "/" + $_farm_misses_rejected_count_disp + "/" + $_farm_misses_failed_count_disp
					}
					
					$_spacer_length = [int]($_label_rewards.Length - $_rewards_data_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer -nonewline
					#Write-Host $_disk_misses_obj.Misses -nonewline -ForegroundColor $_missed_rewards_color
					$_disk_miss_disp = "-"
					$_disk_miss_timeout_disp = "-"
					if ($_disk_misses_obj.Timeout -gt 0) 
					{
						$_disk_miss_timeout_disp = $_disk_misses_obj.Timeout.ToString()
					}
					$_disk_miss_rejected_disp = "-"
					if ($_disk_misses_obj.Rejected -gt 0) 
					{
						$_disk_miss_rejected_disp = $_disk_misses_obj.Rejected.ToString()
					}
					$_disk_miss_failed_disp = "-"
					if ($_disk_misses_obj.Failed -gt 0) 
					{
						$_disk_miss_failed_disp = $_disk_misses_obj.Failed.ToString()
					}
					if ($_disk_misses_obj.Misses -gt 0) 
					{
						$_disk_miss_disp = $_disk_miss_timeout_disp + "/" + $_disk_miss_rejected_disp + "/" + $_disk_miss_failed_disp
					}
					Write-Host $_disk_miss_disp -nonewline -ForegroundColor $_missed_rewards_color

					#$_spacer_length = [int]($_label_misses.Length - $_disk_misses_obj.Misses.toString().Length)
					$_spacer_length = [int]($_label_misses.Length - $_disk_miss_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer
					$_num_rows += 1
					
					$_b_misses_data_printed = $true
				}
				if ($_b_misses_data_printed -eq $false) 				# misses not published yet in endpoint
				{
					# write data - combine missed and rewards into single line of display
					$_b_data_printed = $true

					$_spacer_length = [int]($_label_rewards.Length - $_rewards_data_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer -nonewline
					Write-Host "-" -nonewline		#no misses data populated in endpoint

					$_spacer_length = [int]($_label_misses.Length - ("-").toString().Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer
					$_num_rows += 1
				}				
			}
			#
			
			## write farmer summary at bottom of disk(s) table
			if ($_label_disk_id_length -gt 0 -and $_b_process_running_ok -eq $true)
			{
				$_spacer_length = $_label_disk_id_length + 1
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = " " + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_size.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_percent_complete.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_size_plotted.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_eta.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_replot.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_sectors_per_hour.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_minutes_per_sectors.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_rewards.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_misses.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer
				$_num_rows += 1
				#
				#
				$_spacer_length = $_label_disk_id_length + 1
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = " " + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_size.Length - $_farm_size_TiB.toString().Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_size_TiB.toString() + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_percent_complete.Length - $_farm_progress_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_progress_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_farm_plotted_size_TiB_disp = "-"
				if ($_farm_plotted_size_TiB -gt 0)
				{
					$_farm_plotted_size_TiB_disp = $_farm_plotted_size_TiB.ToString()
				}
				$_spacer_length = $_label_size_plotted.Length - $_farm_plotted_size_TiB_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_plotted_size_TiB_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_eta.Length - $_farm_eta_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_eta_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				#
				$_farm_replot_progress = "-"
				$_farm_remaining_sectors_for_replot = $_farm_replot_sector_count + $_farm_expiring_sector_count
				if ($_farm_replot_sector_count_hold -gt 0)
				{
					$_farm_replot_progress = ([math]::Round((($_farm_replot_sector_count_hold - $_farm_remaining_sectors_for_replot) / $_farm_replot_sector_count_hold) * 100, 1)).ToString() + "%"
				}
				$_farm_replot_sector_count_disp = $_farm_replot_sector_count_hold.ToString() + "/" + $_farm_remaining_sectors_for_replot.ToString() + "/" + $_farm_replot_progress
				if ($_farm_replot_sector_count_hold -eq 0)
				{
					if ($_farm_expiring_sector_count -gt 0)
					{
						$_farm_replot_sector_count_disp = $_farm_expiring_sector_count.ToString() + "/" + "-" + "/" + "-"
					}
					else
					{
						#$_farm_replot_sector_count_disp = "-" + "/" + "-" + "/" + "-"
						$_farm_replot_sector_count_disp = "-"
					}
				}
				$_spacer_length = $_label_replot.Length - $_farm_replot_sector_count_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_replot_sector_count_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				#
				if ($_farm_sectors_per_hour -le 0 -and $_farm_sector_times -gt 0)
				{
					$_farm_sectors_per_hour = [math]::Round(3600 / $_farm_sector_times, 1)
					$_farm_sectors_per_hour_disp = $_farm_sectors_per_hour.toString()
				}
				$_spacer_length = $_label_sectors_per_hour.Length - $_farm_sectors_per_hour_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_sectors_per_hour_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = $_label_minutes_per_sectors.Length - $_farm_sector_times_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_farm_sector_times_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_rewards_total_disp = "-"
				if ($_rewards_total -gt 0)
				{
					$_rewards_total_disp = $_rewards_total.toString()
				}
				$_spacer_length = $_label_rewards.Length - $_rewards_total_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = "|" + $_rewards_total_disp + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				#
				$_farm_misses_count_data_color = $_fg_color_white
				if ([int]($_farm_misses_count) -gt 0)
				{
					$_farm_misses_count_data_color = $_fg_color_red
				}
				#$_spacer_length = $_label_misses.Length - $_farm_misses_count.toString().Length
				$_spacer_length = $_label_misses.Length - $_farm_misses_count_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				Write-Host "|" -nonewline 
				#Write-Host $_farm_misses_count.toString() -nonewline -ForegroundColor $_farm_misses_count_data_color
				Write-Host $_farm_misses_count_disp -nonewline -ForegroundColor $_farm_misses_count_data_color
				Write-Host $_label_spacer -nonewline 
				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer
				$_num_rows += 1
			}
			##
			#
		}
	}
	#
	# draw finish line
	if ($_label_disk_id_length -gt 0)
	{
		$_spacer_length = $_label_disk_id_length + 1
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host (" " + $_label_spacer + " ") -nonewline -ForegroundColor $_line_spacer_color
		$_spacer_length =  $_total_header_length + $_total_header_labels - 2	# excluding line under vertical separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
		Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
		$_num_rows += 1
	}

	
	## display latest github version info
	$_gitVersionDisp = " - "
	$_gitVersionDispColor = $_html_red
	if ($null -ne $_ss_git_version) {
		$currentVersion = $_ss_git_version[0] -replace "[^.0-9]"
		$_gitVersionDisp = $_ss_git_version[0]
		$_gitVersionDispColor = $_html_green
	}

	fDisplayHelp
	#Write-Host "Latest github version : " -nonewline -ForegroundColor $_info_label_color
	#Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor
	#$_num_rows += 1

	##
	# display last refresh time 
	$currentDate = (Get-Date).ToLocalTime().toString()
	# Refresh
	#Write-Host "Last refresh on       : " -ForegroundColor $_info_label_color -nonewline; Write-Host "$currentDate" -ForegroundColor $_info_label_data_color;
	#$_num_rows += 1
	Write-Host "Last refresh on : " -ForegroundColor $_info_label_color -nonewline; Write-Host "$currentDate" -nonewline -ForegroundColor $_info_label_data_color;
	Write-Host ",    Latest autonomys cli github version : " -nonewline -ForegroundColor $_info_label_color
	Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor
	$_num_rows += 1
	#
	$_last_cursor_position = $host.UI.RawUI.CursorPosition
	fResizePSWindow $_num_rows $_num_cols
	[Console]::SetCursorPosition(0, 0)
	[Console]::SetCursorPosition($_last_cursor_position.X, $_last_cursor_position.Y)
	#
}

function fWriteIndividualProcessDataToConsole ([object]$_io_individual_farmer_id, [int]$_io_farmer_serial_num) {
	#
	#
	$_num_rows = 0
	$_num_cols = 0
	#
	#
	#
	# define color pallete
	$_header_color = "white"
	$_header_inner_color = "cyan"
	$_info_label_color = "gray"
	$_info_label_data_color = "yellow"
	#
	$_fg_color_white = "white"
	$_fg_color_black = "black"
	$_fg_color_green = "green"
	$_fg_color_red = "red"
	#
	$_label_line_separator = "_"
	$_label_line_separator_upper = [char](8254)			# overline unicode (reverse of underscore)
	###
	#$_individual_farmer_count = 0
	$_individual_farmer_count = -1
	$_individual_farmer_count_disp = "0"
	###
	$_b_first_farm_process = $true
	#
	## disk id label length
	$_label_disk_id_length = 0
	#
	# header lables
	$_label_hostname = "Hostname"
	$_label_diskid = "Plot Id"
	$_label_size = "Size  "
	$_label_percent_complete = "%     "
	$_label_size_plotted = "PL TiB"
	$_label_eta = "ETA   "
	$_label_replot = "   Replots    "
	$_label_sectors_per_hour = "SCT   "
	$_label_minutes_per_sectors = "Time/ "
	$_label_rewards = "Rewards"
	$_label_misses = "  Miss  "
	#
	$_label_hostname_row2 = "        "
	$_label_diskid_row2 = "       "
	$_label_size_row2 = "(TiB) "
	$_label_percent_complete_row2 = "Cmpl  "
	$_label_size_plotted_row2 = "      "
	$_label_eta_row2 = "      "
	$_label_replot_row2 = "EX/RM/% Cmpl  "
	$_label_sectors_per_hour_row2 = "PH    "
	$_label_minutes_per_sectors_row2 = "SCT   "
	$_label_rewards_row2 = "       "
	$_label_misses_row2 = "TO/RJ/FL"
	#
	$_spacer = " "
	$_total_header_length = $_label_size.Length + $_label_percent_complete.Length + $_label_size_plotted.Length + $_label_eta.Length + $_label_replot.Length + $_label_sectors_per_hour.Length + $_label_minutes_per_sectors.Length + $_label_rewards.Length + $_label_misses.Length
	$_total_header_labels = 10
	#
	$_individual_farmer_metrics_raw = ""
	[array]$_individual_farmer_state_arr = $null
	$_b_process_running_ok = $false
	if ($_io_individual_farmer_id) {
		#
		$_process_type = "Farmer"
		$_farmer_config = $_io_individual_farmer_id.Id.split(":")
		#
		$_host_ip = $_farmer_config[0].toString()
		$_host_port = $_farmer_config[1].toString()
		$_host_friendly_name = ""
		if ($_io_individual_farmer_id.Hostname) {
			$_host_friendly_name = $_io_individual_farmer_id.Hostname
		}
		$_host_url = $_host_ip + ":" + $_host_port
		$_hostname = ""
		
		$_hostname = $_host_ip
		if ($_host_friendly_name -and $_host_friendly_name.length -gt 0)
		{
			$_hostname = $_host_friendly_name
		}
		#
		$_individual_farmer_state_arr = fGetProcessState $_process_type $_host_url $_hostname $script:_url_discord
		$_b_process_running_ok = $_individual_farmer_state_arr[1]
		
		$_total_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length
		$_num_cols = $_total_spacer_length + 2		# extra seperators at start & end of line
		$_spacer_length = $_total_spacer_length - 2
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator
		#
		if ($_b_first_farm_process)
		{
			Write-Host (" " + $_label_spacer + " " ) -ForegroundColor $_line_spacer_color
			$_num_rows += 1
			$_b_first_farm_process = $false
		}
		else
		{
			if($_label_disk_id_length -gt 0)
			{
				$_spacer_length = $_label_disk_id_length + 1
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				Write-Host (" " + $_label_spacer + " ") -nonewline -ForegroundColor $_line_spacer_color
				$_spacer_length =  $_total_header_length + $_total_header_labels - 2	# excluding line under vertical separators
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
				$_num_rows += 1
			}
			#
			# write a blank line
			Write-Host " " -ForegroundColor $_line_spacer_color
			$_num_rows += 1
			#
			# write a line above process header to provide enclosure
			$_spacer_length = $_total_spacer_length - 2
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator
			Write-Host (" " + $_label_spacer + " " ) -ForegroundColor $_line_spacer_color
			$_num_rows += 1
		}
		
		#
		if ($_process_type.toLower() -eq "farmer") {
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			Write-Host $_label_spacer -nonewline
		}
		#
		$_process_header_filler_length = 0
		#
		$_console_msg = $_process_type + ":"
		if ($_process_type.toLower() -eq "farmer")
		{
			###
			#$_individual_farmer_count = $_io_farmer_serial_num + 1
			$_individual_farmer_count = $_io_farmer_serial_num
			$_individual_farmer_count_disp = $_individual_farmer_count.toString()
			if ($_individual_farmer_count -gt 9)
			{
				#$_individual_farmer_count_disp = $script:_char_arr[$_individual_farmer_count - 10]
				$_individual_farmer_count_disp = $script:_char_arr[($_individual_farmer_count + 1) - 10]
			}
			###
			$_console_msg = "Farm #" + $_individual_farmer_count_disp + ":"
		}
		Write-Host $_console_msg -nonewline -ForegroundColor $_farmer_header_color
		$_process_header_filler_length += $_console_msg.Length
		#
		$_console_msg = ""
		$_console_msg_color = ""
		$_process_state_disp = $_label_line_separator_upper
		$_console_msg = $_process_state_disp
		if ($_b_process_running_ok -eq $true) {
			$_console_msg_color = $_html_green
		}
		else {
			$_console_msg_color = $_html_red
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline

		Write-Host ", " -nonewline
		Write-Host "Host:" -nonewline -ForegroundColor $_farmer_header_color
		Write-Host $_hostname -nonewline -ForegroundColor $_farmer_header_data_color
		$_process_header_filler_length += $_console_msg.Length + (", ").Length + ("Host:").Length + $_hostname.Length
		#
		#
		$_individual_farmer_metrics_raw = $_individual_farmer_state_arr[0]
		$_individual_farmer_metrics_formatted_arr = fParseMetricsToObj $_individual_farmer_metrics_raw
		
		# header lables
		$_b_write_header = $true
		#
		##
		$_disk_metrics_arr = fGetDiskSectorPerformance $_individual_farmer_metrics_formatted_arr
		$_disk_UUId_arr = $_disk_metrics_arr[0].Id
		$_disk_sector_performance_arr = $_disk_metrics_arr[0].Performance
		$_disk_rewards_arr = $_disk_metrics_arr[0].Rewards
		$_disk_misses_arr = $_disk_metrics_arr[0].Misses
		$_disk_plots_completed_arr = $_disk_metrics_arr[0].PlotsCompleted
		$_disk_plots_remaining_arr = $_disk_metrics_arr[0].PlotsRemaining
		$_disk_plots_expired_arr = $_disk_metrics_arr[0].PlotsExpired
		$_disk_plots_expiring_arr = $_disk_metrics_arr[0].PlotsAboutToExpire

		# Write uptime information to console
		$_avg_sectors_per_hour = 0.0
		$_avg_sectors_per_hour_disp = "-"
		$_avg_minutes_per_sector = 0.0
		$_avg_minutes_per_sector_disp = "-"
		$_avg_seconds_per_sector = 0.0
		#
		[object]$_farm_level_rewards_CursorPosition = $null
		$_rewards_total = 0
		$_rewards_per_hour = 0
		$_rewards_per_day_estimated = 0
		foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
		{
			
			if ($_disk_sector_performance_obj) {
				if ($_disk_sector_performance_obj.Id -eq "overall") {
					$_uptime = fGetElapsedTime $_disk_sector_performance_obj
					$_uptime_disp = fConvertTimeSpanToString $_uptime
					#
					if ($_uptime.TotalHours) {
						$_rewards_per_hour = [math]::Round([double]($_disk_sector_performance_obj.TotalRewards / $_uptime.TotalHours), 1)
						$_rewards_per_day_estimated = [math]::Round([double](($_disk_sector_performance_obj.TotalRewards / $_uptime.TotalHours) * 24), 1)
					}
					#

					Write-Host ", " -nonewline
					Write-Host "Uptime:" -nonewline -ForegroundColor $_farmer_header_color

					Write-Host $_uptime_disp -nonewline -ForegroundColor $_farmer_header_data_color
					$_process_header_filler_length += (", ").Length + ("Uptime:").Length + $_uptime_disp.Length + (", ").Length

					$_rewards_total = [int]($_disk_sector_performance_obj.TotalRewards)
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

		$_farm_sectors_per_hour = 0
		$_farm_sectors_per_hour_disp = "-"
		$_farm_sector_times = 0.0

		$_farm_sector_times_disp = "-"
		if ($_actual_plotting_disk_count -gt 0) {
			$_avg_seconds_per_sector_disp = [math]::Round($_avg_seconds_per_sector / $_actual_plotting_disk_count, 2)
			$_avg_minutes_per_sector_obj = New-TimeSpan -seconds $_avg_seconds_per_sector_disp
			$_avg_minutes_per_sector_disp = $_avg_minutes_per_sector_obj.minutes.ToString() + "m" + $_avg_minutes_per_sector_obj.seconds.ToString() + "s"
			
			$_avg_sectors_per_hour = [math]::Round($_avg_sectors_per_hour / $_actual_plotting_disk_count, 2)
			$_avg_sectors_per_hour_disp = $_avg_sectors_per_hour.toString()
			
			$_farm_sectors_per_hour =  [math]::Round($_avg_sectors_per_hour * $_actual_plotting_disk_count, 1)
			$_farm_sectors_per_hour_disp = $_farm_sectors_per_hour.toString()
			#
			if ($_farm_sectors_per_hour -gt 0)
			{
				$_farm_sector_times = [double](3600 / $_farm_sectors_per_hour)
			}
			$_farm_sector_times_obj = New-TimeSpan -seconds $_farm_sector_times
			#
			if ($_farm_sector_times -gt 0)
			{
				$_farm_sector_times_disp = fConvertTimeSpanToString $_farm_sector_times_obj
			}
		}
		#
		#
		## Write farm level Size, % progress and ETA - NEW
		$_process_completed_sectors = 0
		$_process_completed_sectors_disp = "-"
		$_process_remaining_sectors = 0
		$_process_remaining_sectors_disp = "-"
		#
		$_max_process_remaining_sectors = 0
		#
		$_process_total_sectors = 0
		$_process_total_sectors_disp = "-"
		$_process_total_disks = 0
		$_process_total_disks_disp = "-"
		$_tmp_farm_expired_sector_count = 0
		$_tmp_farm_expiring_sector_count = 0
		foreach ($_disk_UUId_obj in $_disk_UUId_arr)
		{
			$_label_disk_id_length = $_disk_UUId_obj.Id.Length
			#
			# get size, % progresion and ETA at farm level
			foreach ($_disk_plots_completed_obj in $_disk_plots_completed_arr)
			{
				if ($_disk_plots_completed_obj) {
					if ($_disk_UUId_obj.Id -ne $_disk_plots_completed_obj.Id) { continue }
				}
				else {break}
				#

				#$_label_disk_id_length = $_disk_UUId_obj.Id.Length
				foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
				{
					if ($_disk_plots_remaining_obj) {
						if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
					}
					else {break}




						$_disk_plots_remaining = [int]($_disk_plots_remaining_obj.Sectors)
						if ($_disk_plots_remaining -eq 0) # means plotting is at 100% and replotting may be ongoing depending on plotcount > 0
						{									
							# expired sectors info
							foreach ($_disk_plots_expired_obj in $_disk_plots_expired_arr)
							{
								if ($_disk_plots_expired_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_expired_obj.Id) { continue }
								}
								$_tmp_replot_sector_count = [int]($_disk_plots_expired_obj.Sectors)
								$_tmp_farm_expired_sector_count += $_tmp_replot_sector_count
								break
							}
							#
							## expiring sectors info
							foreach ($_disk_plots_expiring_obj in $_disk_plots_expiring_arr)
							{
								if ($_disk_plots_expiring_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_expiring_obj.Id) { continue }
								}
								$_tmp_expiring_sector_count = [int]($_disk_plots_expiring_obj.Sectors)
								$_tmp_farm_expiring_sector_count += $_tmp_expiring_sector_count
								break
							}
						}



					
					$_reminaing_sectors = [int]($_disk_plots_remaining_obj.Sectors)
					$_completed_sectors = [int]($_disk_plots_completed_obj.Sectors)
					$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors

					$_process_total_disks += 1
					$_process_total_disks_disp = $_process_total_disks

					if ($_reminaing_sectors -eq 0) {
						$_process_total_disks = $_process_total_disks - 1
						$_process_total_disks_disp = $_process_total_disks
					}
					
					$_process_remaining_sectors += $_reminaing_sectors
					$_process_remaining_sectors_disp = $_process_remaining_sectors
					#
					#
					if($_reminaing_sectors -gt $_max_process_remaining_sectors)
					{
						$_max_process_remaining_sectors = $_reminaing_sectors
					}	
					#
					#
					$_process_completed_sectors += $_completed_sectors
					$_process_completed_sectors_disp = $_process_completed_sectors

					$_process_total_sectors = $_process_completed_sectors + $_process_remaining_sectors
					$_process_total_sectors_disp = $_process_total_sectors
				}
			}
		}
		#
		#
		$_disk_plots_remaining_arr_sorted = fSortObjArrBySectorRemaining $_disk_plots_remaining_arr $_process_total_disks
		$_eta_hold_ = 0
		for ($_h = 0; $_h -lt ($_disk_plots_remaining_arr_sorted | Measure-Object).count; $_h++)
		{
			$_disk_plots_remaining_arr_sorted[$_h].ETA = $_eta_hold_ + [double]($_farm_sector_times) * $_disk_plots_remaining_arr_sorted[$_h].AdditionalSectorsForETA * $_disk_plots_remaining_arr_sorted[$_h].PlotCountMultiplier
			$_eta_hold_ = $_disk_plots_remaining_arr_sorted[$_h].ETA
		}
		#
		#
		## write process header line end character
		$_spacer_length = $_label_disk_id_length + $_total_header_length + $_total_header_labels + 2 - $_process_header_filler_length
		if ($_label_disk_id_length -eq 0)
		{
			$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length - $_process_header_filler_length
		}
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		$_label_spacer = $_label_spacer + "|"
		Write-Host $_label_spacer
		$_num_rows += 1
		# hold cursor position for farm level rewards
		Write-Host "|" -nonewline
		$_farm_level_rewards_CursorPosition = $host.UI.RawUI.CursorPosition
		Write-Host ""
		$_num_rows += 1
		#
		## build and display farm level progress and ETA
		#
		$_farm_progress = 0
		$_farm_progress_disp = "-"
		if ($_process_total_sectors_disp -ne "-") {
			$_farm_progress = [math]::Round(([int]($_process_completed_sectors) / [int]($_process_total_sectors)) * 100, 2)
			$_farm_progress_disp = $_farm_progress.toString() + "%"
		}
		#
		$_farm_eta = 0
		$_farm_eta_disp = "-"
		#
		if ($_max_process_remaining_sectors -gt 0) 
		{
			$_farm_eta = ($_farm_sector_times * $_process_remaining_sectors)
			$_farm_eta_obj = New-TimeSpan -seconds $_farm_eta
			$_farm_eta_disp =  fConvertTimeSpanToString $_farm_eta_obj
		}
		#
		$_farm_plotted_size = 0
		$_farm_plotted_size_TiB = 0.0
		$_farm_size = 0
		$_farm_size_TiB = 0.0
		$_farm_size_disp = "-"
		if ($_process_total_sectors_disp -ne "-") {
			#$_farm_plotted_size = [int]($_process_completed_sectors)
			$_farm_plotted_size = [int]($_process_completed_sectors) + $_tmp_farm_expired_sector_count + $_tmp_farm_expiring_sector_count
			$_farm_plotted_size_TiB = [math]::Round($_farm_plotted_size * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
			#
			#$_farm_size = [int]($_process_total_sectors)
			$_farm_size = [int]($_process_total_sectors) + $_tmp_farm_expired_sector_count + $_tmp_farm_expiring_sector_count
			$_farm_size_TiB = [math]::Round($_farm_size * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
			$_farm_size_disp = $_farm_size_TiB.ToString() + "TiB"
		}
		#
		#
		### got the farm size here, rewards and rewards position previously - proceed writing to farm header
		#
		# get the current farm header size data cursor position for repositioning later
		$_farm_level_header_data_current_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		# set cursor position to farm header rewards data location
		[Console]::SetCursorPosition($_farm_level_rewards_CursorPosition.X, $_farm_level_rewards_CursorPosition.Y)
		$_rewards_per_TiB = 0
		$_farm_daily_avg_rewards_per_TiB = 0
		if ($_farm_plotted_size_TiB -gt 0)
		{
			$_rewards_per_TiB = [math]::Round($_rewards_total / $_farm_plotted_size_TiB, 1)
			if ($_rewards_per_day_estimated -ne "-")
			{
				$_farm_daily_avg_rewards_per_TiB = [math]::Round([int]($_rewards_per_day_estimated) / $_farm_plotted_size_TiB, 1)
			}
		}
		$_farm_rewards_disp_label = "Rewards(Tot/PPTiB/PH/Est PD/PPTiB PD):"
		$_farm_rewards_disp = $_rewards_total.toString() + "/" + $_rewards_per_TiB.toString() + "/" + $_rewards_per_hour.toString() + "/" + $_rewards_per_day_estimated.toString() + "/" + $_farm_daily_avg_rewards_per_TiB.toString()
		$_spacer_length = $_label_disk_id_length + $_total_header_length + $_total_header_labels - $_farm_rewards_disp.Length - $_farm_rewards_disp_label.Length
		if ($_label_disk_id_length -eq 0)
		{
			$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length - 2 - $_farm_rewards_disp.Length - $_farm_rewards_disp_label.Length
		}
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_farm_rewards_disp_label -nonewline -ForegroundColor $_farmer_header_color
		Write-Host ($_farm_rewards_disp) -nonewline -ForegroundColor $_farmer_header_data_color
		Write-Host ($_label_spacer + "|") -ForegroundColor $_fg_color_white
		$_num_rows += 1
		#
		#revert back cursor position to last written farm header size data
		[Console]::SetCursorPosition($_farm_level_header_data_current_CursorPosition.X, $_farm_level_header_data_current_CursorPosition.Y)
		###
		#
		## display break-up (disk level) information for a given farm
		#
		$_total_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length
		$_spacer_length = $_total_spacer_length - 2
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator
		Write-Host ("|" + $_label_spacer + "|") -ForegroundColor $_line_spacer_color
		$_num_rows += 1

		$_farm_replot_sector_count = 0
		$_farm_replot_sector_count_hold = 0
		$_farm_expiring_sector_count = 0
		$_farm_misses_count = 0
		$_farm_misses_timeout_count = 0
		$_farm_misses_rejected_count = 0
		$_farm_misses_failed_count = 0
		$_farm_misses_count_disp = "-"
		foreach ($_disk_UUId_obj in $_disk_UUId_arr)
		{
			# write header if not already done
			if ($_b_write_header -eq $true) {
				# Host name header info
				# draw line
				if ($_disk_UUId_obj -ne $null) {
					$_total_spacer_length = $_disk_UUId_obj.Id.toString().Length + $_total_header_length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
				}
				else {$_total_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}
				$_spacer_length = $_total_spacer_length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
				 
				#
				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				#
				#
				## header line #2
				Write-Host $_label_spacer -nonewline

				Write-Host $_label_diskid -nonewline -ForegroundColor $_disk_header_color
				if ($_disk_UUId_obj -ne $null) {
					$_spacer_length =  $_disk_UUId_obj.Id.toString().Length - $_label_diskid.Length + 1
				}
				else {$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}

				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_size -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_percent_complete -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_size_plotted -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_eta -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_replot -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
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
				$_num_rows += 1
				#
				#
				## header line #2
				Write-Host $_label_spacer -nonewline

				Write-Host $_label_diskid_row2 -nonewline -ForegroundColor $_disk_header_color
				if ($_disk_UUId_obj -ne $null) {
					$_spacer_length =  $_disk_UUId_obj.Id.toString().Length - $_label_diskid.Length + 1
				}
				else {$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}

				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_size_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_percent_complete_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_size_plotted_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_eta_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_replot_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline 
				Write-Host $_label_sectors_per_hour_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host $_label_minutes_per_sectors_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host $_label_rewards_row2 -nonewline -ForegroundColor $_disk_header_color
				
				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host $_label_misses_row2 -nonewline -ForegroundColor $_disk_header_color

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer
				$_num_rows += 1

				#
				## NEW - header finish line
				if ($_disk_UUId_obj -ne $null) {
					$_spacer_length =  $_disk_UUId_obj.Id.toString().Length + 1
				}
				else {$_spacer_length = ("-------------------------------------------------------------------------------------------------------").Length}

				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_size.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_percent_complete.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_size_plotted.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_eta.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_replot.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_sectors_per_hour.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_minutes_per_sectors.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = $_label_rewards.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 
				
				$_spacer_length = $_label_misses.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
				$_label_spacer = "|" + $_label_spacer
				Write-Host $_label_spacer -nonewline 

				$_spacer_length = 0
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer
				$_num_rows += 1
				#
				$_b_write_header = $false
			}

			# write data table
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"

			Write-Host $_label_spacer -nonewline
			Write-Host $_disk_UUId_obj.Id -nonewline

			# get disk performance data - write after eta is calculated
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
					break
				}
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
					foreach ($_disk_plots_expired_obj in $_disk_plots_expired_arr)
					{
						if ($_disk_plots_expired_obj) {
							if ($_disk_UUId_obj.Id -ne $_disk_plots_expired_obj.Id) { continue }
						}
						$_replot_sector_count = [int]($_disk_plots_expired_obj.Sectors)
						$_farm_replot_sector_count += $_replot_sector_count
						break
					}
					#
					# expiring sectors info
					foreach ($_disk_plots_expiring_obj in $_disk_plots_expiring_arr)
					{
						if ($_disk_plots_expiring_obj) {
							if ($_disk_UUId_obj.Id -ne $_disk_plots_expiring_obj.Id) { continue }
						}
						$_expiring_sector_count = [int]($_disk_plots_expiring_obj.Sectors)
						$_farm_expiring_sector_count += $_expiring_sector_count
						break
					}
					## rebuild storage for replot if more sectors expired or expiring in the meantime as needed
					$_b_add_exp_arr_id = $true
					for ($_h = 0; $_h -lt $script:_replot_sector_count_hold_arr.count; $_h++)
					{
						if ($script:_replot_sector_count_hold_arr[$_h]) {
							if ($_disk_UUId_obj.Id -ne $script:_replot_sector_count_hold_arr[$_h].Id) { continue }
						}
						if ($script:_replot_sector_count_hold_arr[$_h].ExpiredSectors -eq 0 -or $script:_replot_sector_count_hold_arr[$_h].ExpiredSectors -lt ($_replot_sector_count + $_expiring_sector_count))
						{
							$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = $_replot_sector_count + $_expiring_sector_count
						}
						elseif ($_replot_sector_count -eq 0 -and $_expiring_sector_count -eq 0)
						{
							$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = 0
						}
						$_replot_sector_count_hold = $script:_replot_sector_count_hold_arr[$_h].ExpiredSectors
						$_farm_replot_sector_count_hold += $_replot_sector_count_hold
						$_b_add_exp_arr_id = $false
						break
					}
					if ($_b_add_exp_arr_id)
					{
						$_expiring_plots_info = [PSCustomObject]@{
							Id				= $_disk_UUId_obj.Id
							ExpiredSectors	= ($_replot_sector_count + $_expiring_sector_count)
						}
						$script:_replot_sector_count_hold_arr += $_expiring_plots_info
						$_replot_sector_count_hold = $_replot_sector_count + $_expiring_sector_count
						$_farm_replot_sector_count_hold += $_replot_sector_count_hold
					}
				}
			}
			#
			## write size, % progresion and ETA
			$_b_printed_size_metrics = $false
			$_size_data_disp = "-"
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
				$_size_data_disp = $_disk_plots_completed_obj.Sectors

				foreach ($_disk_plots_remaining_obj in $_disk_plots_remaining_arr)
				{
					if ($_disk_plots_remaining_obj) {
						if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_obj.Id) { continue }
					}
					else {break}
					
					$_reminaing_sectors = [int]($_disk_plots_remaining_obj.Sectors)
					$_completed_sectors = [int]($_disk_plots_completed_obj.Sectors)
					#$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors
					$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors + $_replot_sector_count_hold
					$_total_disk_sectors_TiB = [math]::Round($_total_sectors_GiB * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
					$_total_disk_sectors_disp = $_total_disk_sectors_TiB.ToString()
					if ($_total_sectors_GiB -ne 0) {
						#$_plotting_percent_complete = [math]::Round(($_completed_sectors / $_total_sectors_GiB) * 100, 2)
						$_plotting_percent_complete = [math]::Round(($_completed_sectors / ($_total_sectors_GiB - $_replot_sector_count_hold)) * 100, 2)
						$_plotting_percent_complete_disp = $_plotting_percent_complete.ToString() + "%"
					}
					if ($_minutes_per_sector_data_disp -ne "-") {
						foreach ($_disk_plots_remaining_sorted_obj in $_disk_plots_remaining_arr_sorted)
						{
							if ($_disk_plots_remaining_sorted_obj) {
								if ($_disk_UUId_obj.Id -ne $_disk_plots_remaining_sorted_obj.Id) { continue }
							}
							else {break}
							$_eta = $_disk_plots_remaining_sorted_obj.ETA
						}
						$_eta_obj = $null
						if ($_eta -ne "-")
						{
							$_eta_obj = New-TimeSpan -seconds $_eta
						}
						$_eta_disp = fConvertTimeSpanToString $_eta_obj
					}
					
					$_spacer_length = 1
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_total_disk_sectors_disp -nonewline

					$_spacer_length = $_label_size.Length - $_total_disk_sectors_disp.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_plotting_percent_complete_disp -nonewline

					#$_total_disk_plotted_TiB = [math]::Round($_completed_sectors * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
					$_total_disk_plotted_TiB = [math]::Round(($_completed_sectors + $_replot_sector_count_hold) * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
					$_total_disk_plotted_TiB_disp = "-"
					if ($_total_disk_plotted_TiB -gt 0)
					{
						$_total_disk_plotted_TiB_disp = $_total_disk_plotted_TiB.ToString()
					}

					$_spacer_length = $_label_percent_complete.Length - $_plotting_percent_complete_disp.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_total_disk_plotted_TiB_disp -nonewline

					$_spacer_length = $_label_size_plotted.Length - $_total_disk_plotted_TiB_disp.Length
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					Write-Host $_label_spacer -nonewline
					Write-Host $_eta_disp -nonewline
				}

				$_b_printed_size_metrics = $true
			}
			if ($_b_printed_size_metrics -eq $false)
			{
				$_spacer_length = 1
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host "-" -nonewline
				
				$_spacer_length = $_label_size.Length - ("-").Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host "-" -nonewline

				$_spacer_length = $_label_percent_complete.Length - ("-").Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host "-" -nonewline

				$_spacer_length = $_label_size_plotted.Length - ("-").Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				Write-Host "-" -nonewline
			}

			# write replotting info
			$_spacer_length = $_label_eta.Length - $_eta_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			Write-Host $_label_spacer -nonewline
			$_replot_progress = "-"
			$_remaining_sectors_for_replot = $_replot_sector_count + $_expiring_sector_count
			if ($_replot_sector_count_hold -gt 0)
			{
				$_replot_progress = ([math]::Round((($_replot_sector_count_hold - $_remaining_sectors_for_replot) / $_replot_sector_count_hold) * 100, 1)).ToString() + "%"
			}
			$_replot_sector_count_disp = $_replot_sector_count_hold.ToString() + "/" + $_remaining_sectors_for_replot.ToString() + "/" + $_replot_progress
			if ($_replot_sector_count_hold -eq 0)
			{
				if ($_expiring_sector_count -gt 0)
				{
					$_replot_sector_count_disp = $_expiring_sector_count.ToString() + "/" + "-" + "/" + "-"
				}
				else
				{
					$_replot_sector_count_disp = "-"
				}
			}
			Write-Host $_replot_sector_count_disp -nonewline
			
			# write performance data
			$_spacer_length = $_label_replot.Length - $_replot_sector_count_disp.Length 
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
		
			Write-Host $_label_spacer -nonewline
			Write-Host $_sectors_per_hour_data_disp -nonewline

			$_spacer_length = [int]($_label_sectors_per_hour.Length - $_sectors_per_hour_data_disp.Length)
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			
			Write-Host $_label_spacer -nonewline
			if ($_time_per_sector_data_obj.minutes -gt 0 -or  $_time_per_sector_data_obj.seconds -gt 0)
			{
				$_time_per_sector_disp = $_time_per_sector_data_obj.minutes.ToString() + "m" + $_time_per_sector_data_obj.seconds.ToString() + "s"
			}
			else
			{
				$_time_per_sector_disp = "-"
			}
			Write-Host $_time_per_sector_disp -nonewline
			
			
			$_b_counted_missed_rewards = $false
			$_b_data_printed = $false
			$_missed_rewards_count = 0
			$_missed_rewards_color = "white"
			$_b_reward_data_printed = $false
			$_rewards_data_disp = "-"
			foreach ($_disk_rewards_obj in $_disk_rewards_arr)
			{
				if ($_disk_UUId_obj.Id -ne $_disk_rewards_obj.Id) {
						continue
				}
				$_rewards_data_disp = $_disk_rewards_obj.Rewards.ToString()

				$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_time_per_sector_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
			
				Write-Host $_label_spacer -nonewline
				Write-Host $_disk_rewards_obj.Rewards -nonewline
				
				$_b_reward_data_printed = $true
			}
			if ($_b_reward_data_printed -eq $false) 				# rewards not published yet in endpoint
			{
				$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_time_per_sector_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer -nonewline
				Write-Host "-" -nonewline
			}


			$_b_misses_data_printed = $false
			foreach ($_disk_misses_obj in $_disk_misses_arr)
			{
				if ($_disk_UUId_obj.Id -ne $_disk_misses_obj.Id) {
						continue
				}
				
				if ($_disk_misses_obj.Misses -gt 0) {
					$_missed_rewards_color = $_html_red
					$_farm_misses_count += [int]($_disk_misses_obj.Misses)
					$_farm_misses_timeout_count += [int]($_disk_misses_obj.Timeout)
					$_farm_misses_rejected_count += [int]($_disk_misses_obj.Rejected)
					$_farm_misses_failed_count += [int]($_disk_misses_obj.Failed)
					$_farm_misses_timeout_count_disp = "-"
					if ($_farm_misses_timeout_count -gt 0)
					{
						$_farm_misses_timeout_count_disp = $_farm_misses_timeout_count.toString()
					}
					$_farm_misses_rejected_count_disp = "-"
					if ($_farm_misses_rejected_count -gt 0)
					{
						$_farm_misses_rejected_count_disp = $_farm_misses_rejected_count.toString()
					}
					$_farm_misses_failed_count_disp = "-"
					if ($_farm_misses_failed_count -gt 0)
					{
						$_farm_misses_failed_count_disp = $_farm_misses_failed_count.toString()
					}
					$_farm_misses_count_disp = $_farm_misses_timeout_count_disp + "/" + $_farm_misses_rejected_count_disp + "/" + $_farm_misses_failed_count_disp
				}
				
				$_spacer_length = [int]($_label_rewards.Length - $_rewards_data_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer -nonewline
				#Write-Host $_disk_misses_obj.Misses -nonewline -ForegroundColor $_missed_rewards_color
				$_disk_miss_disp = "-"
				$_disk_miss_timeout_disp = "-"
				if ($_disk_misses_obj.Timeout -gt 0) 
				{
					$_disk_miss_timeout_disp = $_disk_misses_obj.Timeout.ToString()
				}
				$_disk_miss_rejected_disp = "-"
				if ($_disk_misses_obj.Rejected -gt 0) 
				{
					$_disk_miss_rejected_disp = $_disk_misses_obj.Rejected.ToString()
				}
				$_disk_miss_failed_disp = "-"
				if ($_disk_misses_obj.Failed -gt 0) 
				{
					$_disk_miss_failed_disp = $_disk_misses_obj.Failed.ToString()
				}
				if ($_disk_misses_obj.Misses -gt 0)
				{
					$_disk_miss_disp = $_disk_miss_timeout_disp + "/" + $_disk_miss_rejected_disp + "/" + $_disk_miss_failed_disp
				}
				Write-Host $_disk_miss_disp -nonewline -ForegroundColor $_missed_rewards_color
				
				#$_spacer_length = [int]($_label_misses.Length - $_disk_misses_obj.Misses.toString().Length)
				$_spacer_length = [int]($_label_misses.Length - $_disk_miss_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer
				$_num_rows += 1
				
				$_b_misses_data_printed = $true
			}
			if ($_b_misses_data_printed -eq $false) 				# misses not published yet in endpoint
			{
				# write data - combine missed and rewards into single line of display
				$_b_data_printed = $true

				$_spacer_length = [int]($_label_rewards.Length - $_rewards_data_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer -nonewline
				Write-Host "-" -nonewline		#no misses data populated in endpoint

				$_spacer_length = [int]($_label_misses.Length - ("-").toString().Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer
				$_num_rows += 1
			}
		}
		## write farmer summary at bottom of disk(s) table
		if ($_label_disk_id_length -gt 0)
		{
			$_spacer_length = $_label_disk_id_length + 1
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = " " + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_size.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_percent_complete.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 

			$_spacer_length = $_label_size_plotted.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 

			$_spacer_length = $_label_eta.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_replot.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_sectors_per_hour.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_minutes_per_sectors.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_rewards.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_misses.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
			$_label_spacer = "|" + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			Write-Host $_label_spacer
			$_num_rows += 1
			#
			#
			$_spacer_length = $_label_disk_id_length + 1
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = " " + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_size.Length - $_farm_size_TiB.toString().Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_size_TiB.toString() + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_percent_complete.Length - $_farm_progress_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_progress_disp + $_label_spacer
			Write-Host $_label_spacer -nonewline 

			$_farm_plotted_size_TiB_disp = "-"
			if ($_farm_plotted_size_TiB -gt 0)
			{
				$_farm_plotted_size_TiB_disp = $_farm_plotted_size_TiB.ToString()
			}
			$_spacer_length = $_label_size_plotted.Length - $_farm_plotted_size_TiB_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_plotted_size_TiB_disp + $_label_spacer
			Write-Host $_label_spacer -nonewline 

			$_spacer_length = $_label_eta.Length - $_farm_eta_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_eta_disp + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			#
			$_farm_replot_progress = "-"
			$_farm_remaining_sectors_for_replot = $_farm_replot_sector_count + $_farm_expiring_sector_count
			if ($_farm_replot_sector_count_hold -gt 0)
			{
				$_farm_replot_progress = ([math]::Round((($_farm_replot_sector_count_hold - $_farm_remaining_sectors_for_replot) / $_farm_replot_sector_count_hold) * 100, 1)).ToString() + "%"
			}
			$_farm_replot_sector_count_disp = $_farm_replot_sector_count_hold.ToString() + "/" + $_farm_remaining_sectors_for_replot.ToString() + "/" + $_farm_replot_progress
			if ($_farm_replot_sector_count_hold -eq 0)
			{
				if ($_farm_expiring_sector_count -gt 0)
				{
					$_farm_replot_sector_count_disp = $_farm_expiring_sector_count.ToString() + "/" + "-" + "/" + "-"
				}
				else
				{
					$_farm_replot_sector_count_disp = "-"
				}
			}
			$_spacer_length = $_label_replot.Length - $_farm_replot_sector_count_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_replot_sector_count_disp +  $_label_spacer
			Write-Host $_label_spacer -nonewline 
			#
			
			if ($_farm_sectors_per_hour -le 0 -and $_farm_sector_times -gt 0)
			{
				$_farm_sectors_per_hour = [math]::Round(3600 / $_farm_sector_times, 1)
				$_farm_sectors_per_hour_disp = $_farm_sectors_per_hour.toString()
			}
			$_spacer_length = $_label_sectors_per_hour.Length - $_farm_sectors_per_hour_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_sectors_per_hour_disp + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = $_label_minutes_per_sectors.Length - $_farm_sector_times_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_farm_sector_times_disp + $_label_spacer
			Write-Host $_label_spacer -nonewline 

			$_rewards_total_disp = "-"
			if ($_rewards_total -gt 0)
			{
				$_rewards_total_disp = $_rewards_total.toString()
			}
			$_spacer_length = $_label_rewards.Length - $_rewards_total_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = "|" + $_rewards_total_disp + $_label_spacer
			Write-Host $_label_spacer -nonewline 
			#
			$_farm_misses_count_data_color = $_fg_color_white
			if ([int]($_farm_misses_count) -gt 0)
			{
				$_farm_misses_count_data_color = $_fg_color_red
			}
			#$_spacer_length = $_label_misses.Length - $_farm_misses_count.toString().Length
			$_spacer_length = $_label_misses.Length - $_farm_misses_count_disp.Length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host "|" -nonewline 
			#Write-Host $_farm_misses_count.toString() -nonewline -ForegroundColor $_farm_misses_count_data_color
			Write-Host $_farm_misses_count_disp -nonewline -ForegroundColor $_farm_misses_count_data_color
			Write-Host $_label_spacer -nonewline 
			$_spacer_length = 0
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			$_label_spacer = $_label_spacer + "|"
			Write-Host $_label_spacer
			$_num_rows += 1
		}
		##
		#
	}
	#
	# draw finish line
	if ($_label_disk_id_length -gt 0 -and $_b_process_running_ok -eq $true)
	{
		$_spacer_length = $_label_disk_id_length + 1
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host (" " + $_label_spacer + " ") -nonewline -ForegroundColor $_line_spacer_color
		$_spacer_length =  $_total_header_length + $_total_header_labels - 2	# excluding line under vertical separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
		Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
		$_num_rows += 1
	}
	
	## display latest github version info
	$_gitVersionDisp = " - "
	$_gitVersionDispColor = $_html_red
	if ($null -ne $_ss_git_version) {
		$currentVersion = $_ss_git_version[0] -replace "[^.0-9]"
		$_gitVersionDisp = $_ss_git_version[0]
		$_gitVersionDispColor = $_html_green
	}

	fDisplayHelp
	#Write-Host "Latest github version : " -nonewline -ForegroundColor $_info_label_color
	#Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor
	#$_num_rows += 1


	## display last refresh time 
	$currentDate = (Get-Date).ToLocalTime().toString()
	# Refresh
	#Write-Host "Last refresh on       : " -ForegroundColor $_info_label_color -nonewline; Write-Host "$currentDate" -ForegroundColor $_info_label_data_color;
	#$_num_rows += 1
	Write-Host "Last refresh on : " -ForegroundColor $_info_label_color -nonewline; Write-Host "$currentDate" -nonewline -ForegroundColor $_info_label_data_color;
	Write-Host ",    Latest autonomys cli github version : " -nonewline -ForegroundColor $_info_label_color
	Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor
	$_num_rows += 1
	#
	$_last_cursor_position = $host.UI.RawUI.CursorPosition
	fResizePSWindow $_num_rows $_num_cols
	[Console]::SetCursorPosition(0, 0)
	[Console]::SetCursorPosition($_last_cursor_position.X, $_last_cursor_position.Y)
	#
}

function fDisplayHelpSummary() {
	$_help_text_1 = "SCT=Sector,PH=Per Hour,PD=Per Day,Tot=Total,Cmpl=Complete,PPTiB=Per Plotted TiB,PL=Plotted,EX=Expired,"
	$_help_text_2 = "RM=Remaining,Est=Estimated,TO=Timeout,RJ=Rejected,FL=Failed"
	Write-Host $_help_text_1 -BackgroundColor black -ForegroundColor darkgray
	Write-Host $_help_text_2 -BackgroundColor black -ForegroundColor darkgray
}

function fDisplayHelp() {
	$_help_text_1 = "SCT=Sector,PH=Per Hour,PD=Per Day,Tot=Total,Cmpl=Complete,PPTiB=Per Plotted TiB,"
	$_help_text_2 = "PL=Plotted,EX=Expired,RM=Remaining,Est=Estimated,TO=Timeout,RJ=Rejected,FL=Failed"
	Write-Host $_help_text_1 -BackgroundColor black -ForegroundColor darkgray
	Write-Host $_help_text_2 -BackgroundColor black -ForegroundColor darkgray
}