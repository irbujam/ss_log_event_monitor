<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Autonomys Network Monitor"
function main {
	$_b_allow_refresh = $false
	$script:_b_enable_new_sector_times_calc = $true
	$script:_total_time_elpased_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$_for_git_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$_ss_git_url = "https://api.github.com/repos/subspace/subspace/releases/latest"
	$_ss_git_version = fCheckGitNewVersion ($_ss_git_url)
	$_monitor_git_url = "https://api.github.com/repos/irbujam/ss_log_event_monitor/releases/latest"
	$_monitor_git_version = fCheckGitNewVersion $_monitor_git_url
	$_monitor_file_curr_local_path = $PSCommandPath
	$_monitor_file_name = "v0.4.1"
	#
	$_refresh_duration_default = 30
	$script:refreshTimeScaleInSeconds = 0		# defined in config, defaults to 30 if not provided
	$script:_alert_frequency_seconds = 0		# defined in config, defaults to refreshTimeScaleInSeconds if not provided
	$script:_url_discord = ""
	$script:_telegram_api_token = ""
	$script:_telegram_chat_id = ""
	#
	$script:_piece_cache_size_text = ""
	$script:_piece_cache_size_percent = 0		# default to 0 if no user specified value
	$script:_TiB_to_GiB_converter = 1024
	$script:_sector_size_GiB = 0.9843112		# sector size for 1000 pieces (current default) is 1056896064 bytes
	$script:_mulitplier_size_converter = 1 
	#
	$_b_console_disabled = $false
	####
	$_b_listener_running = $false
	$script:_api_enabled = "N"
	$script:_api_host = ""
	$_api_host_ip = ""
	$_api_host_port = ""
	$_url_prefix_listener = ""
	$_b_request_processed = $false
	#
	$script:_b_user_refresh = $false
	[array]$script:_global_process_metrics_arr = $null
	#
	$_alert_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$script:_b_first_time = $true
	#
	[array]$script:_process_status_arr = $null
	[array]$script:_farmer_disk_metrics_arr = $null
	[array]$script:_replot_sector_count_hold_arr = $null
	#
	[array]$script:_incremental_plot_elapsed_time_arr = $null
	#
	[array]$script:_individual_farmer_id_arr = $null
	$script:_individual_farmer_id_last_pos = -1
	#
	[array]$script:_char_arr = @("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")
	[array]$script:_num_key_arr = @("D0","D1","D2","D3","D4","D5","D6","D7","D8","D9","NumPad0","NumPad1","NumPad2","NumPad3","NumPad4","NumPad5","NumPad6","NumPad7","NumPad8","NumPad9")
	#
	$script:_b_write_process_details_to_console = $false
	$script:_b_write_process_summary_to_console = $true
	#
	$script:_cluster_id_seq = 0
	$script:_nats_server_name = ""
	$script:_b_cluster_mode = $false
	$script:_b_disable_farmer_display_at_cluster = $true	#disabled by default
	[array]$script:_ss_controller_obj_arr = $null
	[array]$script:_ss_cache_obj_arr = $null
	[array]$script:_ss_farmer_obj_arr = $null
	[array]$script:_ss_plotter_obj_arr = $null
	$script:_nats_server_health_status = $null
	[object]$script:_cluster_data_row_pos_hold = $null
	$script:_new_rows_written_to_console = 0
	$script:_custom_alert_text = ""
	#$script:_b_ps_window_resize_enabled = "N"
	$script:_alert_category_txt = "all"				#default set to send  alerts for all components
	$script:_process_alt_name_max_length = 0
	$script:_process_farmer_alt_name_max_length = 0
	$script:_label_all_dash = "---------------------------------------------------------------------------------------------------------"
	##
	$script:_node_url = "wss://rpc.mainnet.subspace.foundation/ws"
	$script:_vlt_addr_filename = ""
	$script:_vlt_addr_arr = [System.Collections.ArrayList]@()
	$script:_vlt_address = ""
	$_b_remove_duplicate_address = $true
	$script:_vlt_balance = 0
	$script:_vlt_balance_refresh_frequency = 3600	#defaults to hourly refresh
	$_balance_refresh_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$script:_show_rank = "N"
	$script:_current_rank = 0
	$script:_rank_direction = ""
	$script:_rank_refresh_frequency = 12
	$_rank_refresh_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$script:_rank_filename = "rank.txt"
	$script:_b_file_exists = $false
	$script:_b_redo_rank = $false
	##
	$script:_node_cursor_pos = $null
	$script:_num_rows = 0
	$script:_num_cols = 0
	#
	[array]$script:_accts_obj_arr_showVltDetails = $null
	$script:_rank_showVltDetails = ""
	[array]$script:_rank_obj_arr_showVltDetails = $null
	####
	
	$script:_b_windows_host = fCheckPlatformType
	Clear-Host
	
	try {
		while ($true) {
			#
			if ($Stopwatch.Elapsed.TotalSeconds -ge $script:refreshTimeScaleInSeconds -or $script:_b_first_time -eq $true) 
			{
				$_b_allow_refresh = $true
			}
			if ($_b_allow_refresh -or $script:_b_user_refresh -eq $true) 
			{
				$script:_cluster_data_row_pos_hold = $null
				$script:_new_rows_written_to_console = 0
				$script:_custom_alert_text = ""
				##
				$script:_all_process_eta = 0
				$script:_all_process_eta_disp = "-"
				#
				$script:_url_discord = ""
				$script:_telegram_api_token = ""
				$script:_telegram_chat_id = ""
				$script:_individual_farmer_id_arr = $null
				$script:_farmer_disk_metrics_arr = $null
				$script:_process_status_arr = $null
				$Stopwatch.Restart()
				Clear-Host
				[System.Console]::CursorVisible = $false

				$_line_spacer_color = "gray"
				$_farmer_header_color = "cyan"
				$_farmer_header_data_color = "yellow"
				$_disk_header_color = "gray"
				$_html_red = "red"
				$_html_green = "green"
				$_html_blue = "blue"
				$_html_black = "black"
				$_html_yellow = "yellow"
				$_html_cyan = "cyan"
				$_html_gray = "gray"
				$_html_white = "white"
				$_html_dark_blue = "darkblue"
				$_html_dark_magenta = "darkmagenta"

				$_farmers_metrics_raw_arr = [System.Collections.ArrayList]@()
				$_node_metrics_raw_arr = [System.Collections.ArrayList]@()

				$_farmers_ip_arr = fReloadConfig
				
				# check if alert frequency was provided in config and if not default to aut-refresh frequency 
				if ($script:_alert_frequency_seconds -eq 0 -or $script:_alert_frequency_seconds -eq "" -or $script:_alert_frequency_seconds -eq $null -or $script:_alert_frequency_seconds -lt $script:refreshTimeScaleInSeconds) {$script:_alert_frequency_seconds = $script:refreshTimeScaleInSeconds}
				#
				# set piece_cache_size to user input or to default as needed
				if ($script:_piece_cache_size_text -eq "" -or $script:_piece_cache_size_text.Length -le 0) { $script:_piece_cache_size_percent = 0 }
				else { $script:_piece_cache_size_percent = [int]($script:_piece_cache_size_text) }
				# set size multiplier
				$script:_mulitplier_size_converter = $script:_sector_size_GiB / (1 - ($script:_piece_cache_size_percent * 0.01))
				#
				### Check if API mode enabled and we have a host
				#
				if ($script:_api_enabled.toLower() -eq "y" -and $script:_api_host -ne $null -and $script:_api_host -ne "")
				{
					$_b_console_disabled = $true

					if ($_b_request_processed -eq $false) 
					{
						#### create listener object for later use
						# create a listener for inbound http request
						$_api_host_arr = $script:_api_host.split(":").Trim(" ")
						$_api_host_ip = $_api_host_arr[0]
						$_api_host_port = $_api_host_arr[1]
						
						$_api_host_url = $_api_host_ip + ":" + $_api_host_port
						if ($_api_host_ip -eq "0.0.0.0" ){ $_api_host_url = "*:" + $_api_host_port }
						
						$_url_prefix = "http://" + $_api_host_url + "/"
						$_url_prefix_listener = $_url_prefix.toString().replace("http://127.0.0.1", "http://localhost")

						$_http_listener = New-Object System.Net.HttpListener
						$_http_listener.Prefixes.Add($_url_prefix_listener)

						$_http_listener.Start()
						$_b_listener_running = $true
					}
					$_context_task = $_http_listener.GetContextAsync()
					#$_context_task = $_http_listener.GetContext()
				}

				#Write data to appropriate destination
				if ($_b_console_disabled) {
					$_b_request_processed = fInvokeHttpRequestListener  $_farmers_ip_arr $_context_task
					$script:_b_first_time = $false
				}
				else{
					#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
					if ($script:_b_write_process_summary_to_console)
					{
						Write-Host "Number key" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "] for individual farmer detail" -ForegroundColor $_html_gray
					}
					else {
						Write-Host
					}
					##
					## check monitor git version and display variance in console
					fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
					##
					Write-Host
					if ($script:_b_write_process_details_to_console)
					{
						fWriteDetailDataToConsole $_farmers_ip_arr
					}
					elseif ($script:_b_write_process_summary_to_console)
					{
						fGetSummaryDataForConsole $_farmers_ip_arr
					}
					# check previous alerts and reset for the next event
					if ($_alert_stopwatch.Elapsed.TotalSeconds -ge $script:_alert_frequency_seconds)
					{
						$_alert_stopwatch.Restart()
					}
					$script:_b_first_time = $false
					$_last_display_type_request = fStartCountdownTimer $script:refreshTimeScaleInSeconds
					if ($_last_display_type_request.toLower() -eq "summary") { $script:_b_write_process_summary_to_console = $true; $script:_b_write_process_details_to_console = $false }
					elseif ($_last_display_type_request.toLower() -eq "detail") { $script:_b_write_process_summary_to_console = $false; $script:_b_write_process_details_to_console = $true }
				}
				
				###### Auto refresh
				$_for_git_HoursElapsed = $_for_git_stopwatch.Elapsed.TotalHours
				if ($_for_git_HoursElapsed -ge 1) {
					$_ss_git_version_new = fCheckGitNewVersion ($_ss_git_url)
					$_monitor_git_version_new = fCheckGitNewVersion ($_monitor_git_url)
					if ($_ss_git_version_new) {
						$_ss_git_version = $_ss_git_version_new
						$_monitor_git_version = $_monitor_git_version_new
					}
					$_for_git_stopwatch.Restart()
				}
				######
				$_b_allow_refresh = $false
			}
		}
	}
	finally 
	{
		if ($_b_listener_running -eq $true) 
		{
			$_http_listener.Close()	
			Write-Host ""
			Write-Host " Listener stopped, exiting..." -ForegroundColor $_html_yellow
		}
	}
}

. "$PSScriptRoot\charts.ps1"
. "$PSScriptRoot\data.ps1"
. "$PSScriptRoot\console.ps1"
. "$PSScriptRoot\nats_io.ps1"

function fInvokeHttpRequestListener ([array]$_io_farmers_ip_arr, [object]$_io_context_task) {
	$_html_full = $null
	$_font_size = 5
	
	
	while (!($_context_task.AsyncWaitHandle.WaitOne(200))) { 
			
			# wait for request - async
			##
			$script:_cluster_data_row_pos_hold = $null
			$script:_new_rows_written_to_console = 0
			$script:_custom_alert_text = ""
			##
			#
			$script:_all_process_eta = 0
			$script:_all_process_eta_disp = "-"
			#
			$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
			Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
			Write-Host
			Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
			Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
			Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
			Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
			Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
			Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
			Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
			if ($script:_b_write_process_summary_to_console)
			{
				Write-Host "Number key" -NoNewLine -ForegroundColor $_html_yellow
				Write-Host "] for individual farmer detail" -ForegroundColor $_html_gray
			}
			else {
				Write-Host
			}
			##
			## check monitor git version and report on variance
			fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
			##
			Write-Host
			if ($Stopwatch.Elapsed.TotalSeconds -ge $script:refreshTimeScaleInSeconds -or $script:_b_first_time -eq $true -or $script:_b_user_refresh -eq $true) { 
					$_farmers_ip_arr = $_io_farmers_ip_arr
					if ($Stopwatch.Elapsed.TotalSeconds -ge $script:refreshTimeScaleInSeconds)
					{					
						$script:_farmer_disk_metrics_arr = $null
						$script:_process_status_arr = $null
						$_farmers_ip_arr = fReloadConfig
						$Stopwatch.Restart()
					}
					if ($script:_b_write_process_details_to_console)
					{
						fWriteDetailDataToConsole $_farmers_ip_arr
					}
					elseif ($script:_b_write_process_summary_to_console)
					{
						fGetSummaryDataForConsole $_farmers_ip_arr
					}

					if ($_alert_stopwatch.Elapsed.TotalSeconds -ge $script:_alert_frequency_seconds)
					{
						$_alert_stopwatch.Restart()
					}

					$_sleep_interval_milliseconds = 1000
					$_spinner = '|', '/', '-', '\'
					$_spinnerPos = 0
					$_end_dt = [datetime]::UtcNow.AddSeconds($script:refreshTimeScaleInSeconds)
					
					$script:_b_first_time = $false
					while (($_remaining_time = ($_end_dt - [datetime]::UtcNow).TotalSeconds) -gt 0) {
						#
						## check for user toggle on data display type while waiting for refresh
						####
						if ([console]::KeyAvailable)
						{
							$_x = [System.Console]::ReadKey() 

							$_key_value = $_x.key
							switch ( $_x.key)
							{
								F12 {
									$script:_individual_farmer_id_last_pos = -1
									Clear-Host
									##
									$script:_cluster_data_row_pos_hold = $null
									$script:_new_rows_written_to_console = 0
									$script:_custom_alert_text = ""
									##
									$script:_b_write_process_details_to_console = $true
									$script:_b_write_process_summary_to_console = $false
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything" -NoNewLine -ForegroundColor $_html_gray
									##
									## check monitor git version and display variance in console
									Write-Host
									fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
									##
									#Write-Host
									Write-Host
									fWriteDetailDataToConsole $_farmers_ip_arr
								}
								F9 {
									$script:_individual_farmer_id_last_pos = -1
									Clear-Host
									##
									$script:_cluster_data_row_pos_hold = $null
									$script:_new_rows_written_to_console = 0
									$script:_custom_alert_text = ""
									##
									$script:_b_write_process_details_to_console = $false
									$script:_b_write_process_summary_to_console = $true
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "Number key" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "] for individual farmer detail" -ForegroundColor $_html_gray
									##
									## check monitor git version and display variance in console
									fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
									##
									Write-Host
									fGetSummaryDataForConsole $_farmers_ip_arr
								}
								F6 {
									fDisplayVltDetails $script:_accts_obj_arr_showVltDetails $script:_rank_showVltDetails $script:_rank_obj_arr_showVltDetails
								}
								{ $script:_num_key_arr -contains $_ -or $script:_char_arr -contains $_ } {
									$script:_individual_farmer_id_last_pos = -1
									if ( $script:_char_arr -contains $_key_value )
									{
										for($_i=0; $_i -lt $script:_char_arr.Count; $_i++)
										{
											if ( $script:_char_arr[$_i] -eq $_key_value)
											{
												$script:_individual_farmer_id_last_pos = 10 + $_i
												break
											}
										}
									}
									elseif ( $script:_num_key_arr -contains $_key_value ) 
									{
										for($_i=0; $_i -lt $script:_num_key_arr.Count; $_i++)
										{
											if ( $script:_num_key_arr[$_i] -eq $_key_value)
											{
												$script:_individual_farmer_id_last_pos = $_i
												break
											}
										}
									}
									#
									if ($script:_individual_farmer_id_last_pos -ge 0 -and $script:_individual_farmer_id_last_pos -lt $script:_individual_farmer_id_arr.Count)
									{
										Clear-Host
										$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
										Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
										Write-Host
										#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
										Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "] to loop thru individual farmer" -ForegroundColor $_html_gray
										##
										## check monitor git version and display variance in console
										fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
										##
										Write-Host
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
									}
								}
								LeftArrow {
									Clear-Host
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "] to loop thru individual farmer" -ForegroundColor $_html_gray
									##
									## check monitor git version and display variance in console
									fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
									##
									Write-Host
									$script:_individual_farmer_id_last_pos -= 1
									if ($script:_individual_farmer_id_last_pos -ge 0)
									{
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
									}
									else{
										$script:_individual_farmer_id_last_pos = $script:_individual_farmer_id_arr.Count - 1
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
									}
								}
								RightArrow {
									Clear-Host
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "] to loop thru individual farmer" -ForegroundColor $_html_gray
									##
									## check monitor git version and display variance in console
									fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
									##
									Write-Host
									$script:_individual_farmer_id_last_pos += 1
									if ($script:_individual_farmer_id_last_pos -lt $script:_individual_farmer_id_arr.Count)
									{
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
									}
									else{
										$script:_individual_farmer_id_last_pos = 0
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
									}
								}
							}
						} 
						####
						Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
						Write-Host "Refreshing in " -NoNewline 
						Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
						Write-Host " seconds..." -NoNewline 
						Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
						if ($_context_task.AsyncWaitHandle.WaitOne(200)) { break }
					}
					Write-Host

					Clear-Host
					#$script:_b_first_time = $false
			}
	}
	## process request received
	$_context = $_context_task.GetAwaiter().GetResult()
	#
	#
	## build html for web ui
	#
	[array]$_process_metrics_arr = $null
	$_process_metrics_arr = fGetDataForHtml $_io_farmers_ip_arr
	$_process_header_arr = $_process_metrics_arr[0].ProcessHeader
	$_process_sub_header_arr = $_process_metrics_arr[0].ProcessSubHeader
	$_process_disk_data_arr = $_process_metrics_arr[0].ProcessData
	$_process_disk_data_js_arr = fConverPSArrToJScriptArr $_process_disk_data_arr
	
	$_b_initial_entry = $true
	#
	##
	####11/11 change start
	<#
	$_html_bar_chart_arr = [System.Collections.ArrayList]@()
	$_ind_chart_seq_num = 0
	#>
	####11/11 change end
	#
	$_chart_labels = '['
	$_chart_alt_labels = '['
	$_chart_progess_data = '['
	$_chart_plotted_size_data = '['
	$_chart_sector_time_data = '['
	$_chart_total_sector_time_data = '['
	$_chart_total_sectors_per_hour_data = '['
	$_chart_eta_data = '['
	$_chart_size_data = '['
	$_chart_uptime_data = '['
	$_chart_perf_sectorsPerHour_data = '['
	$_chart_perf_minutesPerSector_data = '['
	$_chart_rewards_data = '['
	foreach ($_process_farm_sub_header in $_process_sub_header_arr)
	{
		####11/11 change start
		<#
		$_ind_chart_label = '"' + '' + '"'
		$_ind_chart_alt_label = '"' + '' + '"'
		$_ind_chart_progess_data = '"' + '' + '"'
		$_ind_chart_plotted_size_data = '"' + '' + '"'
		$_ind_chart_eta_data = '"' + '' + '"'
		$_ind_chart_size_data = '"' + '' + '"'
		$_ind_chart_uptime_data = '"' + '' + '"'
		$_ind_chart_sector_time_data = '"' + '' + '"' 
		$_ind_chart_total_sectors_per_hour_data = '"' + '' + '"'
		#>
		####11/11 change end
		$_overall_progress = "-"
		$_overall_progress_disp = "-"
		$_overall_plotted_size = "-"
		$_process_eta = 0.0
		$_process_eta_disp = "-"
		$_process_size = 0.0
		$_process_size_disp = "-"
		$_process_sector_time = 0.0
		$_b_i_was_here = $false

		####
		$_tmp_disk_replot_sctors = 0
		foreach ($_disk_data_obj in $_process_disk_data_arr)
		{
			if ($_process_farm_sub_header.UUId -eq $_disk_data_obj.UUId)
			{
				$_tmp_disk_replot_sctors += $_disk_data_obj.ReplotStatus + $_disk_data_obj.ExpiringSectors
			}
		}
			####
		if ($_process_farm_sub_header.TotalSectors -ne "-")
		{
			$_overall_progress = [math]::Round(([int]($_process_farm_sub_header.CompletedSectors) / ([int]($_process_farm_sub_header.TotalSectors) - $_tmp_disk_replot_sctors)) * 100, 2)
			$_overall_progress_disp = $_overall_progress.toString() + "%"
			#
			$_overall_plotted_size = [int]($_process_farm_sub_header.CompletedSectors) + $_tmp_disk_replot_sctors
			$_overall_plotted_size_TiB = [math]::Round($_overall_plotted_size * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)
			if ($_process_farm_sub_header.RemainingSectors -ne "-" -and $_process_farm_sub_header.SectorTime -ne $null -and $_process_farm_sub_header.SectorsPerHourAvg -ne 0 -and $_process_farm_sub_header.TotalDisksForETA -ne 0) {
				$_tmp_sector_time_farm = [double](3600/ ([double]($_process_farm_sub_header.SectorsPerHourAvg) * $_process_farm_sub_header.TotalDisksForETA))
				$_process_sector_time = New-TimeSpan -seconds $_tmp_sector_time_farm
				$_tmp_sectors_per_hour_farm = [math]::Round([double]($_process_farm_sub_header.SectorsPerHourAvg) * $_process_farm_sub_header.TotalDisksForETA, 1)

				$_b_i_was_here = $true
				$_temp_total_sectors_per_farm = 0
				if ($_process_farm_sub_header.TotalSectors -ne "-")
				{
					$_temp_total_sectors_per_farm = [double]($_process_farm_sub_header.TotalSectors)
				}
				$_temp_completed_sectors_per_farm = 0
				if ($_process_farm_sub_header.CompletedSectors -ne "-")
				{
					$_temp_completed_sectors_per_farm = [double]($_process_farm_sub_header.CompletedSectors)
				}
				$_process_eta = [double]($_tmp_sector_time_farm * ($_temp_total_sectors_per_farm - $_temp_completed_sectors_per_farm - $_tmp_disk_replot_sctors))
				$_process_eta_obj = New-TimeSpan -seconds $_process_eta
				$_process_eta_disp = fConvertTimeSpanToString $_process_eta_obj
			}
			$_process_size = [int]($_process_farm_sub_header.TotalSectors)
			$_process_size_TiB = [math]::Round($_process_size * $script:_mulitplier_size_converter / $script:_TiB_to_GiB_converter, 2)

			$_process_size_disp = $_process_size_TiB.ToString()
		}

		####11/11 change start
		<#
		$_ind_chart_label = '"' + $_process_farm_sub_header.UUId + '"'
		$_ind_chart_alt_label = '"' + $_process_farm_sub_header.Hostname + '"'
		$_ind_chart_progess_data = '"' + $_overall_progress + '"'
		$_ind_chart_plotted_size_data = '"' + $_overall_plotted_size_TiB + '"'
		$_ind_chart_eta_data = '"' + $_process_eta_disp + '"'
		$_ind_chart_size_data = '"' + $_process_size_disp + '"'
		$_ind_chart_uptime_data = '"' + $_process_farm_sub_header.Uptime + '"'
		$_ind_chart_sector_time_data = '"' + (fConvertTimeSpanToString $_process_sector_time) + '"' 
		if ($_process_sector_time.TotalSeconds -gt 0)
		{
			$_ind_chart_total_sectors_per_hour_data = '"' + ([math]::Round(3600 / $_process_sector_time.TotalSeconds, 1)).ToString() + '"'
		}
		#>		
		####11/11 change end
		if ($_b_initial_entry)
		{
			$_chart_labels += '"' + $_process_farm_sub_header.UUId + '"'
			$_chart_alt_labels += '"' + $_process_farm_sub_header.Hostname + '"'
			$_chart_progess_data += '"' + $_overall_progress + '"'
			$_chart_plotted_size_data += '"' + $_overall_plotted_size_TiB + '"'

			if ($_b_i_was_here) {
				$_chart_sector_time_data += '"' + (fConvertTimeSpanToString $_process_sector_time) + '"' 
			}
			else {
				$_chart_sector_time_data += '"' + 0 + "m " + 0 + "s" + '"' 
			}
			$_chart_total_sector_time_data += '"' + [math]::Round($_process_sector_time.TotalSeconds, 2) + '"' 
			if ($_b_i_was_here) {
				if ($_process_sector_time.TotalSeconds -gt 0)
				{
					$_chart_total_sectors_per_hour_data += '"' + ([math]::Round(3600 / $_process_sector_time.TotalSeconds, 1)).ToString() + '"'
				}
				else {
					$_chart_total_sectors_per_hour_data += '"' + 0 + '"'
				}
			}
			else {
				$_chart_total_sectors_per_hour_data += '"' + 0 + '"'
			}
			$_chart_eta_data += '"' + $_process_eta_disp + '"'
			$_chart_size_data += '"' + $_process_size_disp + '"'
			$_chart_uptime_data += '"' + $_process_farm_sub_header.Uptime + '"'
			$_chart_perf_sectorsPerHour_data += '"' + ([math]::Round([double]($_process_farm_sub_header.SectorsPerHourAvg), 1)).ToString() + '"'
			$_chart_perf_minutesPerSector_data += '"' + ([math]::Round([double]($_process_farm_sub_header.MinutesPerSectorAvg), 2)).ToString() + '"'
			$_chart_rewards_data += '"' + $_process_farm_sub_header.TotalRewards + '"'
			$_b_initial_entry = $false
		}
		else {
			$_chart_labels += ',"' +$_process_farm_sub_header.UUId + '"'
			$_chart_alt_labels += ',"' +$_process_farm_sub_header.Hostname + '"'
			$_chart_progess_data += ',"' + $_overall_progress + '"'
			$_chart_plotted_size_data += ',"' + $_overall_plotted_size_TiB + '"'
			if ($_b_i_was_here) {
				$_chart_sector_time_data += ',"' + (fConvertTimeSpanToString $_process_sector_time) + '"' 
			}
			else {
				$_chart_sector_time_data += ',"' + 0 + "m " + 0 + "s" + '"' 
			}
			$_chart_total_sector_time_data += ',"' + [math]::Round($_process_sector_time.TotalSeconds, 1) + '"' 
			if ($_b_i_was_here) {
				if ($_process_sector_time.TotalSeconds -gt 0)
				{
					$_chart_total_sectors_per_hour_data += ',"' + ([math]::Round(3600 / $_process_sector_time.TotalSeconds, 1)).ToString() + '"'
				}
				else {
					$_chart_total_sectors_per_hour_data += ',"' + 0 + '"'
				}
			}
			else {
				$_chart_total_sectors_per_hour_data += ',"' + 0 + '"'
			}
			$_chart_eta_data += ',"' + $_process_eta_disp + '"'
			$_chart_size_data += ',"' + $_process_size_disp + '"'
			$_chart_uptime_data += ',"' + $_process_farm_sub_header.Uptime + '"'
			$_chart_perf_sectorsPerHour_data += ',"' + ([math]::Round([double]($_process_farm_sub_header.SectorsPerHourAvg), 1)).ToString() + '"'
			$_chart_perf_minutesPerSector_data += ',"' + ([math]::Round([double]($_process_farm_sub_header.MinutesPerSectorAvg), 2)).ToString() + '"'
			$_chart_rewards_data += ',"' + $_process_farm_sub_header.TotalRewards + '"'
		}
		####11/11 change start
		<#
		$_tmp_html_bar_chart = fBuildDonutProgressBarChart $_ind_chart_seq_num $_ind_chart_label $_ind_chart_alt_label $_ind_chart_progess_data $_ind_chart_plotted_size_data $_ind_chart_sector_time_data $_ind_chart_eta_data $_ind_chart_size_data $_ind_chart_uptime_data $_ind_chart_total_sectors_per_hour_data $_process_disk_data_js_arr 'Farm Plotting Progress'
		[void]$_html_bar_chart_arr.add($_tmp_html_bar_chart)
		$_ind_chart_seq_num += 1
		#>
		####11/11 change end
	}
	$_chart_labels += ']'
	$_chart_alt_labels += ']'
	$_chart_progess_data += ']'
	$_chart_plotted_size_data += ']'
	$_chart_sector_time_data += ']'
	$_chart_total_sector_time_data += ']'
	$_chart_total_sectors_per_hour_data += ']'
	$_chart_eta_data += ']'
	$_chart_size_data += ']'
	$_chart_uptime_data += ']'
	$_chart_perf_sectorsPerHour_data += ']'
	$_chart_perf_minutesPerSector_data += ']'
	
	$_chart_rewards_data += ']'
	
#				<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.5.0/Chart.min.js"></script>
#				<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.8.0/Chart.min.js"></script>
	$_html_full +=
				'<!DOCTYPE html>
				<html>
				<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.8.0/Chart.min.js"></script>

				<head>
				<title>Autonomys Network Monitor</title>
				<meta name="viewport" content="width=device-width, initial-scale=1">
				<!--<meta http-equiv="refresh" content="' + $script:refreshTimeScaleInSeconds + '">-->
				<style>
				body {
					#padding: 25px;
					background-color: white;
					color: black;
					font-size: 15px;
					font-family: Arial, Helvetica, sans-serif;
				}
				.dark-mode {
					//background-color: black;
					background-color: #181818;
					color: white;
					font-size: 15px;
				}

				.chart_font_header {
					#background-color: white;
					#color: black;
					font-size: 12px;
				}
				.chart_font {
					#background-color: white;
					#color: black;
					font-size: 10px;
				}
				
				.container
				{
					height: 100%; 
					min-height: 100%;
				}
				.process_tile {
					#color:white;
					border-style: solid;
					border-width: 1px;
					text-align: center;
					float: left;
					#width: 8%;
					#height: 10%;
					background-color: #00994d;
				}
				.process_tile_red {
					color:white;
					border-style: solid;
					border-width: 1px;
					text-align: center;
					float: left;
					#width: 8%;
					#height: 10%;
					background-color: #800000;
				}
				.divtable
				{
					font-family: Arial, Helvetica, sans-serif;
					font-size: 11px;
				}
				</style>
				</head>
				<button onclick="fToggleDisplayMode()">Toggle dark mode</font></button>
				<script>
				function fToggleDisplayMode() {
				   var element = document.body;
				   element.classList.toggle("dark-mode");
				}
				</script>
				
				<body onload=fToggleDisplayMode()>
				<script>
				function fGenerateColorRandom() {
				  var _l = "0123456789ABCDEF";
				  var _c = "#";
				  for (var i = 0; i < 6; i++) {
					_c += _l[Math.floor(Math.random() * 16)];
				  }
				  return _c;
				}
				function fClearBarChartDetails() {
				   document.getElementById("progress").innerHTML = "";
				}
				function fClearPieChartDetails() {
				   document.getElementById("rewards").innerHTML = "";
				}
				</script>'

	$_html_bar_chart = fBuildBarChart $_chart_labels $_chart_alt_labels $_chart_progess_data $_chart_plotted_size_data $_chart_sector_time_data $_chart_eta_data $_chart_size_data $_chart_uptime_data $_chart_total_sectors_per_hour_data $_process_disk_data_js_arr 'Farm Plotting Progress'
	#$_html_radar_chart = fBuildRadarChart $_chart_labels $_chart_alt_labels $_chart_perf_sectorsPerHour_data $_chart_perf_minutesPerSector_data $_chart_rewards_data $_process_disk_data_js_arr 'Farm Performance (Avg)'
	
	$_html_net_performance_chart = fBuildNetPerformanceChart $_chart_labels $_chart_alt_labels $_chart_total_sectors_per_hour_data $_chart_total_sector_time_data $_process_disk_data_js_arr 'Farm Performance (Net)'
	
	$_html_pie_chart = fBuildPieChart $_chart_labels $_chart_alt_labels $_chart_rewards_data $_process_disk_data_js_arr 'Farm Rewards'

	$_process_status = "<table><tr>"
	foreach ($_header in $_process_header_arr)
	{
			$_process_name = $_header.UUId
			$_process_alt_name = $_header.Hostname
			$_process_isOftype = $_header.ProcessType
			$_process_state = $_header.State
			$_process_sync_state = $_header.SyncStatus
			$_process_peers = $_header.Peers

			$_process_uptime = "-"
			foreach ($_sub_header in $_process_sub_header_arr)
			{
				if ($_sub_header.UUId -eq $_process_name)
				{
					$_process_uptime = $_sub_header.Uptime
					break
				}
			}
			if ($_process_state.toLower() -eq "running") {
				$_process_status += "<div class=process_tile>"
			}
			else{
				$_process_status += "<div class=process_tile_red>"
			}
			$_process_status += "<h3 class=chart_font_header>" + $_process_isOftype + ": " + $_process_alt_name + "</h3>"
			$_process_status += "<p class=chart_font>" + $_process_state + "</p>"
			if ($_process_isOftype.toLower() -eq "node") {
				$_process_status += "<p class=chart_font>" + "Synced: " + $_process_sync_state + ", Peers: " + $_process_peers + "</p>"
			}
			else {
				$_process_status += "<p class=chart_font>" + "Uptime: " + $_process_uptime + "</p>"
			}
			$_process_status += "</div>"
	}
	$_process_status += "</tr></table>"
	$_html_full += "<div id=container>" + $_process_status + "</div>"
	$_html_full += "<br>"
	$_html_full += "<br>"
	$_html_full += "<br>"
	$_html_full += "<br>"
	$_html_full += "<br>"
	$_html_full += "<br>"
	$_html_full += "<br>"

	$_html_full += $_html_bar_chart
	####11/11 change start
	<#
	$_html_full += "<br>"
	if ($_html_bar_chart_arr) {
		$_html_full += "<Table border=1>"
		$_html_full += "<tr>"
		for ($_i = 0; $_i -lt $_html_bar_chart_arr.Count; $_i++)
		{
			$_html_full += "<td>"
			$_html_full += $_html_bar_chart_arr[$_i]
			$_html_full += "</td>"
		}
		#$_html_full += "</tr>"
		#$_html_full += "<tr>"
		#for ($_i = 0; $_i -lt $_html_bar_chart_arr.Count; $_i++)
		#{
		#	$_html_full += "<td>"
		#	$_html_full += '<div id="progress' + $_i + '" onclick="fClearBarChartDetails()" class="divtable"></div>'
		#	$_html_full += "</td>"
		#}
		$_html_full += "</tr>"
		$_html_full += "</Table>"
	}
	#>
	####11/11 change end

	$_html_full += '<div id="progress" onclick="fClearBarChartDetails()" class="divtable"></div>'
	#$_html_full += $_html_radar_chart
	$_html_full += $_html_net_performance_chart
	$_html_full += $_html_pie_chart
	$_html_full += '<div id=rewards onclick="fClearPieChartDetails()" class="divtable"></div>'

	$_html_full +=
				'</body>
				</html>'
	
	
	# read request properties
	$_request_method = $_context.Request.HttpMethod
	$_request_url = $_context.Request.Url
	
	# adjust matching for localhost url flavours
	$_request_url_for_matching = $_request_url.toString().replace("http://127.0.0.1", "http://localhost")
	$_request_url_endpoint = ($_request_url_for_matching -split $_api_host_port)[1]

	# set and send response 
	$_context.Response.StatusCode = 200
	if (($_request_method -eq "GET" -or $_request_method -eq "get") -and $_request_url_endpoint.toLower() -eq "/summary") {
		$_console_log =  "valid url: " + $_request_url + ", method: " + $_request_method
		$_response = $_html_full
		if ($_response) {
			$_response_bytes = [System.Text.Encoding]::UTF8.GetBytes($_response)
			$_context.Response.OutputStream.Write($_response_bytes, 0, $_response_bytes.Length)
		}
	}

	$_context.Response.Close()

	$script:_b_user_refresh = $true

	return $true 
}

Function fStartCountdownTimer ([int]$_io_timer_duration) {
	$_resp_last_display_type_request = ""
	
	$_sleep_interval_milliseconds = 1000
	$_spinner = '|', '/', '-', '\'
	$_spinnerPos = 0
	$_end_dt = [datetime]::UtcNow.AddSeconds($_io_timer_duration)
	
	while (($_remaining_time = ($_end_dt - [datetime]::UtcNow).TotalSeconds) -gt 0) {
		#
		## check for user toggle on data display type while waiting for refresh
		####
		if ([console]::KeyAvailable)
		{
			$_x = [System.Console]::ReadKey() 
			
			$_key_value = $_x.key
			switch ( $_x.key)
			{
				F12 {
					$script:_individual_farmer_id_last_pos = -1
					Clear-Host
					##
					$script:_cluster_data_row_pos_hold = $null
					$script:_new_rows_written_to_console = 0
					$script:_custom_alert_text = ""
					##
					$script:_b_write_process_details_to_console = $true
					$script:_b_write_process_summary_to_console = $false
					#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything" -NoNewLine -ForegroundColor $_html_gray
					Write-Host
					##
					## check monitor git version and display variance in console
					fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
					##
					Write-Host
					fWriteDetailDataToConsole $_farmers_ip_arr
					$_resp_last_display_type_request = "detail"
				}
				F9 {
					$script:_individual_farmer_id_last_pos = -1
					Clear-Host
					##
					$script:_cluster_data_row_pos_hold = $null
					$script:_new_rows_written_to_console = 0
					$script:_custom_alert_text = ""
					##
					$script:_b_write_process_details_to_console = $false
					$script:_b_write_process_summary_to_console = $true
					#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything. [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "Number key" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "] for individual farmer detail" -ForegroundColor $_html_gray
					##
					## check monitor git version and display variance in console
					fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
					##
					Write-Host
					fGetSummaryDataForConsole $_farmers_ip_arr
					$_resp_last_display_type_request = "summary"
				}
				F6 {
					fDisplayVltDetails $script:_accts_obj_arr_showVltDetails $script:_rank_showVltDetails $script:_rank_obj_arr_showVltDetails
				}
				{ $script:_num_key_arr -contains $_ -or $script:_char_arr -contains $_ } {
					$script:_individual_farmer_id_last_pos = -1
					if ( $script:_char_arr -contains $_key_value )
					{
						for($_i=0; $_i -lt $script:_char_arr.Count; $_i++)
						{
							if ( $script:_char_arr[$_i] -eq $_key_value)
							{
								$script:_individual_farmer_id_last_pos = 10 + $_i
								break
							}
						}
					}
					elseif ( $script:_num_key_arr -contains $_key_value ) 
					{
						for($_i=0; $_i -lt $script:_num_key_arr.Count; $_i++)
						{
							if ( $script:_num_key_arr[$_i] -eq $_key_value)
							{
								$script:_individual_farmer_id_last_pos = $_i
								break
							}
						}
					}
					#
					if ($script:_individual_farmer_id_last_pos -ge 0 -and $script:_individual_farmer_id_last_pos -lt $script:_individual_farmer_id_arr.Count)
					{
						Clear-Host
						#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
						Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "] to loop thru individual farmer" -ForegroundColor $_html_gray
						##
						## check monitor git version and display variance in console
						fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
						##
						Write-Host
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
					}
				}
				LeftArrow {
					Clear-Host
					#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "] to loop thru individual farmer." -ForegroundColor $_html_gray
					##
					## check monitor git version and display variance in console
					fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
					##
					Write-Host
					$script:_individual_farmer_id_last_pos -= 1
					if ($script:_individual_farmer_id_last_pos -ge 0)
					{
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
					}
					else{
						$script:_individual_farmer_id_last_pos = $script:_individual_farmer_id_arr.Count - 1
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
					}
				}
				RightArrow {
					Clear-Host
					#Write-Host "Press to view: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "[" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F6" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-wallet details, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F9" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "] to loop thru individual farmer" -ForegroundColor $_html_gray
					##
					## check monitor git version and display variance in console
					fDisplayMonitorGitVersionVariance $_monitor_git_version $_monitor_file_curr_local_path $_monitor_file_name
					##
					Write-Host
					$script:_individual_farmer_id_last_pos += 1
					if ($script:_individual_farmer_id_last_pos -lt $script:_individual_farmer_id_arr.Count)
					{
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
					}
					else{
						$script:_individual_farmer_id_last_pos = 0
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested $script:_individual_farmer_id_last_pos
					}
				}
			}
		} 
		####
		#
		[System.Console]::CursorVisible = $false
		Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
		Write-Host "Refreshing in " -NoNewline 
		Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
		Write-Host " seconds..." -NoNewline 
		Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
	}
	Write-Host
	return $_resp_last_display_type_request
}

function fReloadConfig() {
	$_configFile = "./config.txt"
	$_process_ip_arr = Get-Content -Path $_configFile | Select-String -Pattern ":"

	$script:_process_alt_name_max_length = 0
	$script:_process_farmer_alt_name_max_length = 0
	$script:_b_cluster_mode = $false
	$script:_cluster_id_seq = 0
	$script:_vlt_address = ""
	$script:_vlt_addr_filename = ""
	$script:_b_file_exists = $false
	$script:_b_redo_rank = $false
	$script:_rank_direction = ""
	#
	for ($arrPos = 0; $arrPos -lt $_process_ip_arr.Count; $arrPos++)
	{
		if ($_process_ip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_process_ip_arr[$arrPos].toString().IndexOf("#") -lt 0) {
			$_config = $_process_ip_arr[$arrPos].toString().split(":").Trim(" ")
			$_process_type = $_config[0].toString()
			if ($_process_type.toLower().IndexOf("enable-api") -ge 0) { $script:_api_enabled = $_config[1].toString()}
			elseif ($_process_type.toLower().IndexOf("api-host") -ge 0) {$script:_api_host = $_config[1].toString() + ":" + $_config[2].toString()}
			elseif ($_process_type.toLower().IndexOf("balance-refresh") -ge 0) { $script:_vlt_balance_refresh_frequency = $_config[1].toString() }
			elseif ($_process_type.toLower().IndexOf("show-rank") -ge 0) { $script:_show_rank = $_config[1].toString() }
			elseif ($_process_type.toLower().IndexOf("refresh") -ge 0) {
				$script:refreshTimeScaleInSeconds = [int]$_config[1].toString()
				if ($script:refreshTimeScaleInSeconds -eq 0 -or $script:refreshTimeScaleInSeconds -eq "" -or $script:refreshTimeScaleInSeconds -eq $null) {$script:refreshTimeScaleInSeconds = $_refresh_duration_default}
			}
			elseif ($_process_type.toLower().IndexOf("send-an-alert") -ge 0) { $script:_alert_category_txt = $_config[1].toString() }
			elseif ($_process_type.toLower().IndexOf("wallet-address") -ge 0) {
				$script:_vlt_address = $_config[1].toString()
				if ($script:_vlt_address.toLower().IndexOf(".txt") -ge 0) { $script:_vlt_addr_filename = $_config[1].toString() }
			}
			elseif ($_process_type.toLower().IndexOf("discord") -ge 0) { $script:_url_discord = "https:" + $_config[2].toString() }
			elseif ($_process_type.toLower().IndexOf("telegram-api-token") -ge 0) { $script:_telegram_api_token = $_config[1].toString() + ":" + $_config[2].toString() }
			elseif ($_process_type.toLower().IndexOf("telegram-chat-id") -ge 0) { $script:_telegram_chat_id = $_config[1].toString() }
			elseif ($_process_type.toLower().IndexOf("piece_cache_size") -ge 0) { $script:_piece_cache_size_text = [int](fExtractTextFromString $_config[1].toString() "%") }
			elseif ($_process_type.toLower().IndexOf("alert-frequency") -ge 0) {
				$script:_alert_frequency_seconds = [int]$_config[1].toString()
			}
			elseif ($_process_type.toLower().IndexOf("start-up") -ge 0 -and $script:_b_first_time) {
				
				$_start_up_view = $_config[1].toString().toLower()
				if ($_start_up_view.IndexOf("s") -eq 0)
				{
					$script:_b_write_process_summary_to_console = $true
					$script:_b_write_process_details_to_console = $false
				}
				elseif ($_start_up_view.IndexOf("d") -eq 0)
				{
					$script:_b_write_process_summary_to_console = $false
					$script:_b_write_process_details_to_console = $true
				}
			}
			elseif ($_process_type.toLower().IndexOf("nats") -ge 0) { $script:_b_cluster_mode = $true }
			# get max length for host alt name
			elseif ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer") { 
				$_process_ip = $_config[1].toString()
				$_host_port = $_config[2].toString()
				$_host_url = $_process_ip + ":" + $_host_port

				$_host_friendly_name = ""
				if ($_config.Count -gt 3) {
					$_host_friendly_name = $_config[3].toString()
				}
				$_hostname = $_process_ip
				if ($_host_friendly_name -and $_host_friendly_name.length -gt 0)
				{
					$_hostname = $_host_friendly_name
				}

				$_process_hostname_alt = ""
				if ($_config.Count -gt 3) {
					$_process_hostname_alt = $_config[3].toString()
				}
				$_process_hostname = $_process_ip
				if ($_process_hostname_alt -and $_process_hostname_alt.length -gt 0)
				{
					$_process_hostname = $_process_hostname_alt
				}
				switch ($_process_type.toLower()) {
					"node" {
						if ($_process_hostname.Length -gt $script:_process_alt_name_max_length) 
						{
							$script:_process_alt_name_max_length = $_process_hostname.Length
						}
						$_tmp_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $script:_url_discord
						$_tmp_process_status_arr_obj = [PSCustomObject]@{
							Id				= $_host_url
							ProcessType 	= $_process_type
							ProcessStatus 	= $_tmp_process_state_arr[1]
							ProcessResp		= $_tmp_process_state_arr[0]
						}
						$script:_process_status_arr += $_tmp_process_status_arr_obj
					}
					"farmer" {
						if ($_process_hostname.Length -gt $script:_process_farmer_alt_name_max_length) 
						{
							$script:_process_farmer_alt_name_max_length = $_process_hostname.Length
						}
						#
						$_tmp_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $script:_url_discord
						$_tmp_process_status_arr_obj = [PSCustomObject]@{
							Id				= $_host_url
							ProcessType 	= $_process_type
							ProcessStatus 	= $_tmp_process_state_arr[1]
							ProcessResp		= $_tmp_process_state_arr[0]
						}
						$script:_process_status_arr += $_tmp_process_status_arr_obj
						$_tmp_farmer_metrics_raw = $_tmp_process_state_arr[0]
						$_tmp_farmer_metrics_formatted_arr = fParseMetricsToObj $_tmp_farmer_metrics_raw
						$_tmp_disk_metrics_arr = fGetDiskSectorPerformance $_tmp_farmer_metrics_formatted_arr					
						$_tmp_disk_metrics_arr_obj = [PSCustomObject]@{
							Id				= $_host_url
							ProcessType 	= $_process_type
							MetricsArr		= $_tmp_disk_metrics_arr
						}
						$script:_farmer_disk_metrics_arr += $_tmp_disk_metrics_arr_obj
						#
					}
				}
			}
		}
	}
	#
	if ($script:_vlt_balance_refresh_frequency -eq 0 -or $script:_vlt_balance_refresh_frequency -eq "" -or $script:_vlt_balance_refresh_frequency -eq $null -or $script:_vlt_balance_refresh_frequency.Length -le 0)
	{
		$script:_vlt_balance_refresh_frequency = 3600	#revert to default hourly refresh if config value was emptied
	}
	##
	if ($script:_vlt_address.Length -gt 0 -and $script:_vlt_address -ne $null) {
		if ($script:_vlt_addr_filename.Length -gt 0 -and $script:_vlt_addr_filename -ne $null) 
		{
			$script:_vlt_addr_arr = fLoadVltAddr $script:_vlt_addr_filename
		}
		else
		{
			$_tmp_vlt_addr_obj = [PSCustomObject]@{
				AddressId		= $script:_vlt_address
			}
			[void]$script:_vlt_addr_arr.add($_tmp_vlt_addr_obj)
		}
		#
		$script:_b_file_exists = Test-Path ("./" + $script:_rank_filename)
		if ($script:_b_file_exists)
		{
			$_rank_obj_arr = fLoadPreviousRank $script:_rank_filename $script:_vlt_addr_arr
			foreach ($_rank_obj in $_rank_obj_arr)
			{
				if ($_rank_obj.AddressId -eq "overall")
				{
					$_previous_rank = $_rank_obj.CurrentRank
					$script:_current_rank = $_previous_rank

					if ([int]($_rank_obj.PreviousRank) -gt [int]($_rank_obj.CurrentRank))
					{
						$script:_rank_direction = "up"
					}
					elseif ([int]($_rank_obj.PreviousRank) -lt [int]($_rank_obj.CurrentRank))
					{
						if ([int]($_rank_obj.PreviousRank) -eq 0 -and [int]($_rank_obj.CurrentRank) -gt 0)
						{
							$script:_rank_direction = "up"
						}
						else
						{
							$script:_rank_direction = "down"
						}
					}
				}
				else
				{
					# set flag to redo rank if rank has previous excess data compared with wallet file
					$script:_b_redo_rank = $true
					foreach ($_vlt_addr_obj in $script:_vlt_addr_arr)
					{
						if ($_vlt_addr_obj.AddressId -eq $_rank_obj.AddressId)
						{ 
							$script:_b_redo_rank = $false
							break
						}					
					}
				}
			}
			# set flag to redo rank if wallet file changed
			if (!($script:_b_redo_rank))
			{
				foreach ($_vlt_addr_obj in $script:_vlt_addr_arr)
				{
					$script:_b_redo_rank = $true
					foreach ($_rank_obj in $_rank_obj_arr)
					{
						if ($_vlt_addr_obj.AddressId -eq $_rank_obj.AddressId)
						{ 
							$script:_b_redo_rank = $false
							break
						}					
					}
				}
			}
		}
		#
		if (($script:_vlt_addr_arr | Measure-Object).Count -gt 0 -and $script:_vlt_addr_arr -ne $null) {
			if ($script:_b_first_time -or $script:_vlt_balance -eq 0 -or $_balance_refresh_stopwatch.Elapsed.TotalSeconds -ge $script:_vlt_balance_refresh_frequency)
			{
				$_balance_refresh_stopwatch.Restart()
				$script:_vlt_balance = fGetVltBalance $script:_node_url $script:_vlt_addr_arr
			}
		}
	}
	else { 	$script:_vlt_balance = 0 }
	#
	## return from function
	return $_process_ip_arr
}

function  fGetVltBalance([string]$_io_node_url, [array]$_io_vlt_address_arr) {
	$_balance = 0
	$_vlt_addr_arrJS = fConverPSObjArrToJScriptArr $_io_vlt_address_arr
	#
	#
	try {
		#if ($script:_b_first_time -or ($script:_show_rank.toLower() -eq "y" -and (!($script:_b_file_exists) -or $_rank_refresh_stopwatch.Elapsed.TotalHours -ge $script:_rank_refresh_frequency)))
		if ($script:_show_rank.toLower() -eq "y" -and (!($script:_b_file_exists) -or $script:_b_redo_rank -or $_rank_refresh_stopwatch.Elapsed.TotalHours -ge $script:_rank_refresh_frequency))
		{
			if ($_rank_refresh_stopwatch.Elapsed.TotalHours -ge $script:_rank_refresh_frequency)
			{
				$_rank_refresh_stopwatch.Restart()
			}
			$_balance = fGetVltRank $_io_node_url $_vlt_addr_arrJS
		}
		else
		{
			if ($script:_b_windows_host)
			{
				$_balance_resp_Json = node .\getAcctBalance.js $_io_node_url $_vlt_addr_arrJS
			}
			else 
			{
				$_balance_resp_Json = node ./getAcctBalance.js $_io_node_url $_vlt_addr_arrJS
			}
			$_balance_resp_PS =  ConvertFrom-Json -InputObject $_balance_resp_Json
			$_balance_resp = $_balance_resp_PS.Response
			foreach ($_balance_obj in $_balance_resp)
			{
				if ($_balance_obj.address_id.toLower() -eq "overall")
				{
					$_balance = [double]($_balance_obj.balance)
					break
				}
			}
			#fDisplayVltDetails $_balance_resp "balance" $null
			if ($script:_rank_showVltDetails -eq "rank")
			{
				#do nothing
			}
			else
			{
				$script:_accts_obj_arr_showVltDetails = $_balance_resp
				$script:_rank_showVltDetails = "balance"
				$script:_rank_obj_arr_showVltDetails = $null
			}
		}
	}
	catch {}
	$_balance = [math]::Round($_balance / [math]::Pow(10, 18), 4)
	return $_balance
}

function  fGetVltRank([string]$_io_node_url, [string]$_io_vlt_address_arr) {
$_balance = 0

	Clear-Host
	$_rank_obj_arr = fLoadPreviousRank $script:_rank_filename $script:_vlt_addr_arr
	#$_previous_rank = 0
	####
	$_msg = "Grab a treat and/or a cup of coffee while i get things ready..."
	Write-Host $_msg
	fPrintTree
	####
	$_my_accts_json = ""
	
	if (($script:_vlt_addr_arr | Measure-Object).Count -gt 0 -and $script:_vlt_addr_arr -ne $null) {
		try {
			if ($script:_b_windows_host)
			{
				$_my_accts_json = node .\ranking_info.js $_io_node_url $_io_vlt_address_arr
			}
			else
			{
				$_my_accts_json = node ./ranking_info.js $_io_node_url $_io_vlt_address_arr
			}
		}
		catch {}
	}
	Clear-Host
	
	####
	## convert to ps object array from json
	$_my_accts_obj_PS =  ConvertFrom-Json -InputObject $_my_accts_json
	$_my_accts_obj_arr = $_my_accts_obj_PS.Response
	#
	$_unique_accounts = 0
	#$_balance = 0
	foreach ($_my_accts_obj in $_my_accts_obj_arr)
	{
		if ($_my_accts_obj.address_id -eq "overall")
		{
			$_unique_accounts = $_my_accts_obj.unique_accounts.toString()
			$_my_addr_ = $_my_accts_obj.address_id.toString()
			$_balance = [double]($_my_accts_obj.balance)
			#$_total_balance_disp = [math]::Round($_total_balance / [math]::Pow(10, 18), 4)
			$script:_current_rank = $_my_accts_obj.rank_id
			##
			$_previous_rank = 0
			foreach ($_rank_obj_ in $_rank_obj_arr)
			{
				if ($_rank_obj_.AddressId -eq "overall")
				{
					$_previous_rank = $_rank_obj_.CurrentRank
					break
				}
			}
			#
			if ([int]($_previous_rank) -gt [int]($script:_current_rank))
			{
				$script:_rank_direction = "up"
			}
			elseif ([int]($_previous_rank) -lt [int]($script:_current_rank))
			{
				if ([int]($_previous_rank) -eq 0 -and [int]($script:_current_rank) -gt 0)
				{
					$script:_rank_direction = "up"
				}
				else
				{
					$script:_rank_direction = "down"
				}
			}
			break
		}
	}
	##
	$_rank_file_content = "0 0"				# only used in function if the file does not exists previously
	fWriteToRankFile $script:_rank_filename $script:_vlt_addr_arr $_rank_file_content $_my_accts_obj_arr
	#
	#fDisplayVltDetails $_my_accts_obj_arr "rank" $_rank_obj_arr
	$script:_accts_obj_arr_showVltDetails = $_my_accts_obj_arr
	$script:_rank_showVltDetails = "rank"
	$script:_rank_obj_arr_showVltDetails = $_rank_obj_arr
	#
	return $_balance
}

function fDisplayVltDetails([array]$_io_accounts_obj_arr, [string]$_io_accounts_obj_type, [array]$_io_rank_obj_arr) {
	$_spacer = " "
	$_label_line_separator = "_"
	$_label_line_separator_upper = [char](8254)			# overline unicode (reverse of underscore)
	#
	#$_num_rows_ = $script:_num_rows
	$_num_cols_ = $script:_num_cols
	#
	$_spacer_length = 1
	$_leading_spaces_filler = fBuildDynamicSpacer $_spacer_length $_spacer
	$_trailing_spaces_filler = ""
	$_data_length = 50
	$_spacer_length = $_data_length
	$_all_spaces_filler = fBuildDynamicSpacer $_spacer_length $_spacer
	$_all_line_filler = fBuildDynamicSpacer $_spacer_length $_label_line_separator
	##
	# get the current cursor position
	$_Last_CursorPosition_ = $host.UI.RawUI.CursorPosition
	$_cursor_position_ = $script:_node_cursor_pos
	$_start_cursor_pos = $_cursor_position_.Y - 2
	$_finish_cursor_pos = ($_io_accounts_obj_arr | Measure-Object).Count
	$_cursor_pos_x = ($_num_cols_ - $_data_length) / 2
	$_cursor_pos_y = $_start_cursor_pos
	# set cursor position to write wallet balance/rank data as an overlay
	[Console]::SetCursorPosition($_cursor_pos_x, $_cursor_pos_y)
	Write-Host $_all_line_filler -ForegroundColor $_html_cyan
	$_cursor_pos_y += 1
	#
	# write header
	$_lbl_addr = "    Address    "
	$_lbl_bal = "   Bal (AI3)   "
	$_lbl_rank = "    Rank    "
	$_lbl_rank_direction = "  "
	[Console]::SetCursorPosition($_cursor_pos_x, $_cursor_pos_y)
	Write-Host "|" -NoNewline -ForegroundColor $_html_cyan
	Write-Host $_leading_spaces_filler -NoNewline
	Write-Host $_lbl_addr -NoNewline -ForegroundColor $_html_cyan
	Write-Host $_lbl_bal -NoNewline -ForegroundColor $_html_cyan
	if ($_io_accounts_obj_type -eq "rank")
	{
		Write-Host $_lbl_rank -NoNewline -ForegroundColor $_html_cyan
		Write-Host $_lbl_rank_direction -NoNewline -ForegroundColor $_html_cyan
		$_spacer_length = $_all_line_filler.Length - ("|").Length - $_leading_spaces_filler.Length - $_lbl_addr.Length - $_lbl_bal.Length - $_lbl_rank.Length - $_lbl_rank_direction.Length - 1
	}
	else
	{
		$_spacer_length = $_all_line_filler.Length - ("|").Length - $_leading_spaces_filler.Length - $_lbl_addr.Length - $_lbl_bal.Length - 1
	}
	$_trailing_spaces_filler = fBuildDynamicSpacer $_spacer_length $_spacer
	Write-Host $_trailing_spaces_filler -NoNewline
	Write-Host "|" -ForegroundColor $_html_cyan
	$_cursor_pos_y += 1
	[Console]::SetCursorPosition($_cursor_pos_x, $_cursor_pos_y)
	$_spacer_length = $_data_length - 2
	$_header_separator_filler = fBuildDynamicSpacer $_spacer_length $_label_line_separator
	Write-Host "|" -NoNewline -ForegroundColor $_html_cyan
	Write-Host $_header_separator_filler -NoNewline -ForegroundColor $_html_cyan
	Write-Host "|" -ForegroundColor $_html_cyan
	$_cursor_pos_y += 1
	##
	#
	# determine input account object type and write data
	if ($_io_accounts_obj_type -eq "rank")
	{
		$_unique_accounts = 0
		$_rank_direction_ = ""
		foreach ($_io_accounts_obj in $_io_accounts_obj_arr)
		{
			if ($_io_accounts_obj.address_id -eq "overall") { $_unique_accounts = $_io_accounts_obj.unique_accounts.toString(); continue; }
			#
			$_addr_ = $_io_accounts_obj.address_id.toString()
			$_addr_disp_ = "...." + $_addr_.Substring($_addr_.Length - 6, 6)
			$_balance_ = [double]($_io_accounts_obj.balance)
			$_balance_disp = [math]::Round($_balance_ / [math]::Pow(10, 18), 4)
			$_rank_ = $_io_accounts_obj.rank_id
			##
			$_previous_rank = 0
			foreach ($_rank_obj_ in $_io_rank_obj_arr)
			{
				if ($_rank_obj_.AddressId -eq $_io_accounts_obj.address_id)
				{
					$_previous_rank = $_rank_obj_.CurrentRank
					break
				}
			}
			#
			if ([int]($_previous_rank) -gt [int]($_rank_))
			{
				$_rank_direction_ = "up"
			}
			elseif ([int]($_previous_rank) -lt [int]($_rank_))
			{
				if ([int]($_previous_rank) -eq 0 -and [int]($_rank_) -gt 0)
				{
					$_rank_direction_ = "up"
				}
				else
				{
					$_rank_direction_ = "down"
				}
			}
			##
			[Console]::SetCursorPosition($_cursor_pos_x, $_cursor_pos_y)
			Write-Host "|" -NoNewline -ForegroundColor $_html_cyan
			Write-Host $_leading_spaces_filler -NoNewline
			Write-Host $_addr_disp_ -NoNewline -ForegroundColor $_html_yellow
			Write-Host "        " -NoNewline
			Write-Host $_balance_disp.ToString() -NoNewline -ForegroundColor $_html_yellow
			Write-Host "        " -NoNewline
			Write-Host $_rank_.ToString() -NoNewline -ForegroundColor $_html_yellow
			Write-Host "        " -NoNewline
			if ($_rank_direction_.toLower() -eq "up") {
				$_fg_color = $_html_green
				$_rank_direction_label = [char]::ConvertFromUtf32(0x2191)
			}
			elseif ($_rank_direction_.toLower() -eq "down") {
				$_fg_color = $_html_red
				$_rank_direction_label = [char]::ConvertFromUtf32(0x2193)
			}
			Write-Host (" " + $_rank_direction_label) -Foregroundcolor $_fg_color
			#
			$_spacer_length = $_all_line_filler.Length - ("|").Length - $_leading_spaces_filler.Length - $_addr_disp_.Length - $_balance_disp.ToString().Length - $_rank_.ToString().Length - $_rank_direction_label.Length - 1 - 1 - (8 * 23)
			$_trailing_spaces_filler = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_trailing_spaces_filler -NoNewline
			Write-Host "|" -ForegroundColor $_html_cyan
			$_cursor_pos_y += 1
		}
	}
	elseif ($_io_accounts_obj_type -eq "balance")
	{
		foreach ($_io_accounts_obj in $_io_accounts_obj_arr)
		{
			if ($_io_accounts_obj.address_id -eq "overall") { continue; }
			#
			$_addr_ = $_io_accounts_obj.address_id.toString()
			$_addr_disp_ = "...." + $_addr_.Substring($_addr_.Length - 6, 6)
			$_balance_ = [double]($_io_accounts_obj.balance)
			$_balance_disp = [math]::Round($_balance_ / [math]::Pow(10, 18), 4)
			##
			[Console]::SetCursorPosition($_cursor_pos_x, $_cursor_pos_y)
			Write-Host "|" -NoNewline -ForegroundColor $_html_cyan
			Write-Host $_leading_spaces_filler -NoNewline
			Write-Host $_addr_disp_ -NoNewline -ForegroundColor $_html_yellow
			Write-Host "        " -NoNewline
			Write-Host $_balance_disp.ToString() -NoNewline -ForegroundColor $_html_yellow
			$_spacer_length = $_all_line_filler.Length - ("|").Length - $_leading_spaces_filler.Length - $_addr_disp_.Length - $_balance_disp.ToString().Length - 1 - (8 * 1)
			$_trailing_spaces_filler = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_trailing_spaces_filler -NoNewline
			Write-Host "|" -ForegroundColor $_html_cyan
			$_cursor_pos_y += 1
		}
	}
	##
	# write footer
	$_spacer_length = $_data_length
	$_all_line_filler = fBuildDynamicSpacer $_spacer_length $_label_line_separator_upper
	[Console]::SetCursorPosition($_cursor_pos_x, $_cursor_pos_y)
	Write-Host $_all_line_filler -ForegroundColor $_html_cyan
	$_cursor_pos_y += 1
	##
	# return to last know cursor position before function entry
	[Console]::SetCursorPosition($_Last_CursorPosition_.X, $_Last_CursorPosition_.Y)
}

function fLoadPreviousRank([string]$_io_filename, [array]$_io_address_arr) {
[array]$_resp_obj_arr = $null

	$_file = "./" + $_io_filename
	$_b_file_exists = Test-Path ("./" + $_io_filename)
	if (!($_b_file_exists))
	{
		fWriteToRankFile $_io_filename $_io_address_arr "0 0" $null
	}

	$_stored_rank_line = Get-Content -Path $_file
	for ($_line_index = 0; $_line_index -lt $_stored_rank_line.Count; $_line_index++)
	{
		if ($_stored_rank_line[$_line_index].toString().Trim(' ') -ne "" -and $_stored_rank_line[$_line_index].toString().IndexOf("#") -lt 0) 
		{
			$_stored_ranks_arr = $_stored_rank_line[$_line_index].toString().split(" ").Trim(" ")
			$_tmp_rank_obj = [PSCustomObject]@{
				AddressId		= $_stored_ranks_arr[0]
				CurrentRank		= [int]($_stored_ranks_arr[1])
				PreviousRank	= [int]($_stored_ranks_arr[2])
			}
			$_resp_obj_arr += $_tmp_rank_obj
		}
	}
	#
	return $_resp_obj_arr
}

function fWriteToRankFile([string]$_io_filename, [array]$_io_address_arr, [string]$_io_file_content, [array]$_io_accts_obj_arr) {
[array]$_rank_obj_arr = $null

	$_path = "./" + $_io_filename
	$_b_file_exists = Test-Path ($_path)
	if ($_b_file_exists)
	{
		# update existing file with set values
		
		$_stored_rank_line = Get-Content -Path $_path
		for ($_line_index = 0; $_line_index -lt $_stored_rank_line.Count; $_line_index++)
		{
			if ($_stored_rank_line[$_line_index].toString().Trim(' ') -ne "" -and $_stored_rank_line[$_line_index].toString().IndexOf("#") -lt 0) 
			{
				$_stored_ranks_arr = $_stored_rank_line[$_line_index].toString().split(" ").Trim(" ")
				$_tmp_rank_obj = [PSCustomObject]@{
					AddressId		= $_stored_ranks_arr[0]
					CurrentRank		= [int]($_stored_ranks_arr[1])
					PreviousRank	= [int]($_stored_ranks_arr[2])
				}
				$_rank_obj_arr += $_tmp_rank_obj
			}
		}
		# rewrite file with modified contents
		Clear-Content -path $_path
		foreach ($_address_ in $_io_address_arr) 
		{
			$_current_rank = 0
			foreach ($_acct_obj in $_io_accts_obj_arr)
			{
				if ($_acct_obj.address_id -eq $_address_.AddressId)
				{
					$_current_rank = $_acct_obj.rank_id
					break
				}
			}
			$_previous_rank = 0
			foreach ($_rank_ in $_rank_obj_arr)
			{
				if ($_rank_.AddressId -eq $_address_.AddressId)
				{
					$_previous_rank = $_rank_.CurrentRank
					break
				}
			}
			$_content_ = $_address_.AddressId + " " + $_current_rank.toString() + " " + $_previous_rank.toString()
			Add-Content -path $_path -value $_content_
		}
		#
		## write overall rank data to file
		$_current_rank = 0
		foreach ($_acct_obj in $_io_accts_obj_arr)
		{
			if ($_acct_obj.address_id -eq "overall")
			{
				$_current_rank = $_acct_obj.rank_id
				$_previous_rank = 0
				foreach ($_rank_ in $_rank_obj_arr)
				{
					if ($_rank_.AddressId -eq "overall")
					{
						$_previous_rank = $_rank_.CurrentRank
						break
					}
				}
				$_content_ = $_acct_obj.address_id + " " + $_current_rank.toString() + " " + $_previous_rank.toString()
				Add-Content -path $_path -value $_content_
				break
			}
		}
	}
	else
	{
		# create file with default initial values
		New-Item -path "./" -name $_io_filename -type "file" -value ""
		foreach ($_address_ in $_io_address_arr) 
		{
			$_content_ = $_address_.AddressId + " " + $_io_file_content
			Add-Content -path $_path -value $_content_
		}
		$_content_ = "overall" + " " + $_io_file_content
		Add-Content -path $_path -value $_content_
	}
}

function fLoadVltAddr([string]$_io_vlt_addr_filename) {
[array]$_resp_vlt_addr_arr = $null
[array]$_vlt_addr_arr = $null

	$_pattern_to_match = " "
	$_vlt_addr_file = "./" + $_io_vlt_addr_filename
	#$_vlt_addr_line = Get-Content -Path $_vlt_addr_file
	ForEach ($line in Get-Content -Path $_vlt_addr_file) 
	{ 
		$_vlt_addr_line = $line 
		if ($_vlt_addr_line.toString().Trim(' ') -ne "" -and $_vlt_addr_line.toString().IndexOf("#") -lt 0) {
			$_vlt_addr_line_arr = $_vlt_addr_line.toString().split($_pattern_to_match).Trim(" ")
			foreach ($_vlt_addr_line_arr_item in $_vlt_addr_line_arr)
			{
				$_tmp_vlt_addr_obj = [PSCustomObject]@{
					AddressId		= $_vlt_addr_line_arr_item
				}
				$_vlt_addr_arr += $_tmp_vlt_addr_obj
			}
		}
	}
	$_resp_vlt_addr_arr = fSanitizeAddr $_vlt_addr_arr $_b_remove_duplicate_address
	#
	return $_resp_vlt_addr_arr
}

function fSanitizeAddr ([array]$_io_vlt_addr_arr, [array]$_io_b_remove_duplicates) {
	[array]$_sanitized_arr = $null
	#
	$_sorted_arr = $_io_vlt_addr_arr
	# sort array if more than one entry
	if ($_io_vlt_addr_arr.Count -gt 1)
	{
		$_sorted_arr = $_io_vlt_addr_arr | Sort-Object @{Expression={$_.AddressId}; descending=$false}
	}
	# eliminate blank array elements
	for ($_i = 0; $_i -lt $_sorted_arr.Count; $_i++)
	{
		if ($_sorted_arr[$_i].AddressId -ne "" -and $_sorted_arr[$_i].AddressId -ne $null)
		{
			$_sanitized_arr += $_sorted_arr[$_i]
		}
	}
	# move array to hold for duplicate cleanup
	if ($_sanitized_arr -and $_sanitized_arr.count -gt 0)
	{
		$_sorted_arr = $_sanitized_arr
	}
	# eliminate duplicate array elements
	if ($_io_b_remove_duplicates)
	{
		$_sanitized_arr = $null
		for ($_i = 0; $_i -lt $_sorted_arr.Count; $_i++)
		{
			if ($_i -eq 0) 
			{
				$_sanitized_arr += $_sorted_arr[$_i]
			}
			elseif ($_sorted_arr[$_i].AddressId -ne $_sorted_arr[$_i-1].AddressId)
			{
				$_sanitized_arr += $_sorted_arr[$_i]
			}
		}
	}	
	#
	return $_sanitized_arr
}

function fConverPSObjArrToJScriptArr ([array]$_io_arr) {
	$_resp_js = ''

	$_resp_js += '['
	for ($j=0; $j -lt $_io_arr.Count; $j++)
	{
		if ($j -eq 0) {
			$_resp_js += '{'
			if ($script:_b_windows_host)
			{
				$_resp_js += '\"acct_id\":' + ' \"' + $_io_arr[$j].AddressId + '\"'
			}
			else
			{
				$_resp_js += '"acct_id":' + ' "' + $_io_arr[$j].AddressId + '"'
			}
			$_resp_js += '}'
			#$_resp_js += '\"' + $_io_arr[$j].AddressId + '\"'
		}
		else
		{
			$_resp_js += ',{'
			if ($script:_b_windows_host)
			{
				$_resp_js += '\"acct_id\":' + ' \"' + $_io_arr[$j].AddressId + '\"'
			}
			else
			{
				$_resp_js += '"acct_id":' + ' "' + $_io_arr[$j].AddressId + '"'
			}
			$_resp_js += '}'
			#$_resp_js += ','
			#$_resp_js += '\"' + $_io_arr[$j].AddressId + '\"'
		}
	}
	$_resp_js += ']'
	
	return $_resp_js
}

function fPrintTree {
$height = 11
$Message = "Happy Holidays!!"

	0..($height-1) | % { Write-Host ' ' -NoNewline }
	Write-Host -ForegroundColor Yellow '*'
	0..($height - 1) | %{
		$width = $_ * 2 
		1..($height - $_) | %{ Write-Host ' ' -NoNewline}

		Write-Host '/' -NoNewline -ForegroundColor Green
		while($Width -gt 0){
			switch (Get-Random -Minimum 1 -Maximum 20) {
				1       { Write-Host -BackgroundColor Green -ForegroundColor Red '@' -NoNewline }
				2       { Write-Host -BackgroundColor Green -ForegroundColor Green '@' -NoNewline }
				3       { Write-Host -BackgroundColor Green -ForegroundColor Blue '@' -NoNewline }
				4       { Write-Host -BackgroundColor Green -ForegroundColor Yellow '@' -NoNewline }
				5       { Write-Host -BackgroundColor Green -ForegroundColor Magenta '@' -NoNewline }
				Default { Write-Host -BackgroundColor Green ' ' -NoNewline }
			}
			$Width--
		}
		 Write-Host '\' -ForegroundColor Green
	}
	0..($height*2) | %{ Write-Host -ForegroundColor Green '~' -NoNewline }
	Write-Host -ForegroundColor Green '~'
	0..($height-1) | % { Write-Host ' ' -NoNewline }
	Write-Host -BackgroundColor Black -ForegroundColor Black ' '
	$Padding = ($Height * 2 - $Message.Length) / 2
	if($Padding -gt 0){
		1..$Padding | % { Write-Host ' ' -NoNewline }
	}
	0..($Message.Length -1) | %{
		$Index = $_
		switch ($Index % 2 ){
			0 { Write-Host -ForegroundColor Green $Message[$Index] -NoNewline }
			1 { Write-Host -ForegroundColor Red $Message[$Index] -NoNewline }
		}
	} 
}

function fGetElapsedTime ([object]$_io_obj) {
	$_time_in_seconds = 0
	if ($_io_obj) {
		$_time_in_seconds = $_io_obj.Uptime
	}
	$_resp_total_uptime =  New-TimeSpan -seconds $_time_in_seconds
	
	return $_resp_total_uptime
}

function fConvertTimeSpanToString ([object]$_io_ts_obj) {
	$_resp_ts_str = "-"
	if ($_io_ts_obj) {
		if ($_io_ts_obj.days -gt 0)
		{
			$_resp_ts_str = $_io_ts_obj.days.toString() + "d" + $_io_ts_obj.hours.toString() + "h"
		}
		elseif ($_io_ts_obj.hours -gt 0)
		{
			$_resp_ts_str = $_io_ts_obj.hours.toString() + "h" + $_io_ts_obj.minutes.toString() + "m"
		}
		elseif ($_io_ts_obj.minutes -gt 0 -or $_io_ts_obj.seconds -gt 0)
		{
			$_resp_ts_str = $_io_ts_obj.minutes.toString() + "m" + $_io_ts_obj.seconds.toString() + "s"
		}
		elseif ($_io_ts_obj.Milliseconds -gt 0)
		{
			$_resp_ts_str = $_io_ts_obj.seconds.toString() + "s" + $_io_ts_obj.Milliseconds.toString() + "ms"
		}
		else
		{
			$_resp_ts_str = "-"
		}
	}
	
	return $_resp_ts_str
}

function fBuildDynamicSpacer ([int]$ioSpacerLength, [string]$ioSpaceType) {
	$dataSpacerLabel = ""
	for ($k=1;$k -le $ioSpacerLength;$k++) {
		$dataSpacerLabel = $dataSpacerLabel + $ioSpaceType
	}
	return $dataSpacerLabel
}

function fExtractTextFromString([string]$_io_source_str, [string]$_delimiter) {
	$_return_text = ""
	$iPos = $_io_source_str.IndexOf($_delimiter)
	$_return_text = $_io_source_str.SubString(0,$iPos)
	return $_return_text
}

function fSortObjArrBySectorRemaining ([array]$_io_source_arr, [int]$_io_incomplete_plots_count) {
	[array]$_arr_sorted = $null
	
	$_incomplete_plots_count_iterator = 0
	foreach ($_tmp_obj in $_io_source_arr)
	{
		$_disk_id_obj = $null
		$_sectors_remain_count_lowest_hold = -1
		foreach ($_source_arr_obj in $_io_source_arr)
		{
			$_plot_id = $_source_arr_obj.Id
			$_sectors_remain_count = $_source_arr_obj.Sectors
			#
			$_b_add_to_sorted_arr = $true
			for ($_h = 0; $_h -lt $_arr_sorted.count; $_h++)
			{
				if ($_arr_sorted[$_h]) {
					if ($_plot_id -eq $_arr_sorted[$_h].Id)
					{
						$_b_add_to_sorted_arr = $false
						break
					}
				}
			}
			if ($_b_add_to_sorted_arr -eq $true)
			{

				if ($_sectors_remain_count_lowest_hold -eq -1 -or $_sectors_remain_count -le $_sectors_remain_count_lowest_hold)
				{
					$_sectors_remain_count_lowest_hold = $_sectors_remain_count
					$_disk_obj = [PSCustomObject]@{
						Id						= $_plot_id
						PlotState				= $_source_arr_obj.PlotState
						Sectors					= $_sectors_remain_count_lowest_hold
						AdditionalSectorsForETA = 0
						PlotCountMultiplier 	= 0
						ETA = 0
					}
					$_disk_id_obj = $_disk_obj
				}
			}
		}
		#
		if ($_disk_id_obj)
		{
			if ($_disk_id_obj.Sectors -gt 0)
			{
				$_disk_id_obj.PlotCountMultiplier = $_io_incomplete_plots_count - $_incomplete_plots_count_iterator
				$_incomplete_plots_count_iterator += 1
			}
			else 
			{
				$_disk_id_obj.PlotCountMultiplier = 0
			}
			$_arr_sorted += $_disk_id_obj
		}
	}
	# add the last element of unsorted array to sorted array
	foreach ($_source_arr_obj in $_io_source_arr)
	{
		$_disk_obj = [PSCustomObject]@{
			Id						= $_source_arr_obj.Id
			PlotState				= $_source_arr_obj.PlotState
			Sectors					= $_source_arr_obj.Sectors
			AdditionalSectorsForETA = 0
			PlotCountMultiplier 	= 0
			ETA = 0
		}
		$_disk_id_obj = $_disk_obj
		#
		for ($_h = 0; $_h -lt $_arr_sorted.count; $_h++)
		{
			$_b_add_to_sorted_arr = $true
			if ($_disk_id_obj.Id -eq $_arr_sorted[$_h].Id)
			{
				$_b_add_to_sorted_arr = $false
				break
			}
		}
		if ($_b_add_to_sorted_arr -eq $true)
		{
			if ($_disk_id_obj.Sectors -gt 0)
			{
				$_disk_id_obj.PlotCountMultiplier = $_io_incomplete_plots_count - $_incomplete_plots_count_iterator
			}
			else 
			{
				$_disk_id_obj.PlotCountMultiplier = 0
			}
			$_arr_sorted += $_disk_id_obj
		}
	}
	# calc remaining sectors multiplier [P(n+1) - P(n-1)]
	for ($_h = 0; $_h -lt $_arr_sorted.count; $_h++)
	{
		if ($_h -eq 0)
		{
			$_arr_sorted[$_h].AdditionalSectorsForETA = $_arr_sorted[$_h].Sectors
		}
		else 
		{
			$_arr_sorted[$_h].AdditionalSectorsForETA = $_arr_sorted[$_h].Sectors - $_arr_sorted[$_h - 1].Sectors
		}
	}

	return $_arr_sorted
}

function fCheckPlatformType () {
	$_b_windows_os = $true
	$_env = [System.Environment]::OSVersion.Platform
	Switch ($_env) {
		Win32NT {
			$_b_windows_os = $true
		}
		Unix {
			$_b_windows_os = $false
		}
		#default {
		#	$_b_windows_os = $false
		#}
	}
	
	return $_b_windows_os
}

function fResizePSWindow ([int]$_io_ps_window_height, [int]$_io_ps_window_width) {
	#if ($_b_ps_window_resize_enabled.toLower() -eq 'y')
	if ($script:_b_windows_host)
	{
		$_height = $_io_ps_window_height + 8
		$_width = $_io_ps_window_width + 2
		#
		$_pswindow = $host.ui.rawui
		# check user supplied height & width are less than max allowed size, resize to max allowed if needed
		if ($_height -gt $_pswindow.MaxPhysicalWindowSize.Height) { $_height = $_pswindow.MaxPhysicalWindowSize.Height }
		if ($_width -gt $_pswindow.MaxPhysicalWindowSize.Width)	{ $_width = $_pswindow.MaxPhysicalWindowSize.Width }

		# Set window dimensions if smaller than buffer, if not then this step will be skipped so we need to set window dimensions later also to cover all scenarios
		$_window  = $_pswindow.WindowSize
		$_buffer  = $_pswindow.BufferSize
		If ($_buffer.Width -gt $_width ) { $_window.Width = $_width }
		If ($_buffer.Height -gt $_height ) { $_window.Height = $_height }

		# if window is smaller than buffer, resize window
		$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.size($_window.Width,$_window.Height)
		# buffer resize, follwed by window resize 
		$host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.size($_width,3000)
		$host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.size($_width,$_height)
	}
}

function fPingMetricsUrl ([string]$ioUrl) {
	.{
		$_response = ""
		$_fullUrl = "http://" + $ioUrl + "/metrics"
		try {
			$farmerObj = Invoke-RestMethod -Method 'GET' -uri $_fullUrl -TimeoutSec 5
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
		if ($_metrics_obj.Name.toLower().IndexOf("substrate_sub_libp2p_is_major_syncing") -ge 0 -and $_metrics_obj.Name.toLower().IndexOf("chain") -ge 0) 
		{
			$_node_sync_status = $_metrics_obj.Value
			$_chain_id_sync = $_metrics_obj.Instance
			$_node_sync_info = [PSCustomObject]@{
				Id			= $_chain_id_sync
				State		= $_node_sync_status
			}
			$_node_sync_arr += $_node_sync_info
		}
		elseif ($_metrics_obj.Name.toLower().IndexOf("substrate_sub_libp2p_peers_count") -ge 0 -and $_metrics_obj.Name.toLower().IndexOf("chain") -ge 0) 
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

	[array]$_most_recent_uptime_by_farmId_arr = $null

	[array]$_resp_UUId_arr = $null
	[array]$_resp_sector_perf_arr = $null
	[array]$_resp_rewards_arr = $null
	[array]$_resp_misses_arr = $null
	[array]$_resp_plots_completed_arr = $null
	[array]$_resp_plots_remaining_arr = $null
	[array]$_resp_plots_expired_arr = $null
	[array]$_resp_plots_expiring_arr = $null

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
	$_farmer_disk_proving_misses_timeout_count = 0
	$_farmer_disk_proving_misses_rejected_count = 0
	$_farmer_disk_proving_misses_failed_count = 0
	$_total_rewards_per_farmer = 0
	#
	##
	foreach ($_metrics_obj in $_io_farmer_metrics_arr)
	{
		if (($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_auditing_time_seconds_count") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_auditing_time_seconds_count") -ge 0) -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		##
		{
			$_uptime_value_int_ = [int]($_metrics_obj.Value)
			if ($_uptime_seconds -lt $_uptime_value_int_)
			{
				$_uptime_seconds = $_uptime_value_int_
			}
			$_unique_farm_id = $_metrics_obj.Instance
			$_farm_id_info = [PSCustomObject]@{
				Id		= $_unique_farm_id
			}
			#
			$_b_add_UUId_arr_id = $true
			for ($_h = 0; $_h -lt $_resp_UUId_arr.count; $_h++)
			{
				if ($_resp_UUId_arr[$_h]) {
					if ($_unique_farm_id -eq $_resp_UUId_arr[$_h].Id)
					{
						$_b_add_UUId_arr_id = $false
						break
					}
				}
			}
			if ($_uptime_value_int_ -gt 0)
			{
				if ($_b_add_UUId_arr_id)
				{
					$_resp_UUId_arr += $_farm_id_info
				}
				$_elapsed_time_info = [PSCustomObject]@{
					Id							= $_unique_farm_id
					TotalElapsedTime			= $_uptime_value_int_
				}
				#
				$_b_add_item_to_arr = $true
				for ($_h = 0; $_h -lt $_most_recent_uptime_by_farmId_arr.count; $_h++)
				{
					if ($_most_recent_uptime_by_farmId_arr[$_h]) {
						if ($_unique_farm_id -eq $_most_recent_uptime_by_farmId_arr[$_h].Id)
						{
							$_most_recent_uptime_by_farmId_arr[$_h].TotalElapsedTime = $_uptime_value_int_
							$_b_add_item_to_arr = $false
							break
						}
					}
				}
				if ($_b_add_item_to_arr)
				{
					$_most_recent_uptime_by_farmId_arr += $_elapsed_time_info
				}
			}
		}
		elseif (($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_sector_plotting_time_seconds_sum") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_sector_plotting_time_seconds_sum") -ge 0) -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		##
		{
			$_uptime_value_int_ = [int]($_metrics_obj.Value)
			if ($_uptime_seconds -le 0)
			{
				$_uptime_seconds = $_uptime_value_int_
			}
			$_unique_farm_id = $_metrics_obj.Instance
			$_farm_id_info = [PSCustomObject]@{
				Id		= $_unique_farm_id
			}
			#
			$_b_add_UUId_arr_id = $true
			for ($_h = 0; $_h -lt $_resp_UUId_arr.count; $_h++)
			{
				if ($_resp_UUId_arr[$_h]) {
					if ($_unique_farm_id -eq $_resp_UUId_arr[$_h].Id)
					{
						$_b_add_UUId_arr_id = $false
						break
					}
				}
			}
			if ($_uptime_value_int_ -gt 0)
			{
				if ($_b_add_UUId_arr_id)
				{
					$_resp_UUId_arr += $_farm_id_info
				}
				$_elapsed_time_info = [PSCustomObject]@{
					Id							= $_unique_farm_id
					TotalElapsedTime			= $_uptime_value_int_
				}
				#
				$_b_add_item_to_arr = $true
				for ($_h = 0; $_h -lt $_most_recent_uptime_by_farmId_arr.count; $_h++)
				{
					if ($_most_recent_uptime_by_farmId_arr[$_h]) {
						if ($_unique_farm_id -eq $_most_recent_uptime_by_farmId_arr[$_h].Id)
						{
							if ($_most_recent_uptime_by_farmId_arr[$_h].TotalElapsedTime -le 0)
							{
								$_most_recent_uptime_by_farmId_arr[$_h].TotalElapsedTime = $_uptime_value_int_
							}
							$_b_add_item_to_arr = $false
							break
						}
					}
				}
				if ($_b_add_item_to_arr)
				{
					$_most_recent_uptime_by_farmId_arr += $_elapsed_time_info
				}
			}
		}
	}
	##
	foreach ($_metrics_obj in $_io_farmer_metrics_arr)
	{
		$_b_incremental_sector_count_changed = $false
		##
		if (($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_sectors_total_sectors") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_sectors_total_sectors") -ge 0) -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		##
		{
			$_plot_id = ($_metrics_obj.Instance -split ",")[0]
			$_plot_state = $_metrics_obj.Criteria.ToString().Trim('"')
			$_sectors = [int]($_metrics_obj.Value)
			
			$_plots_info = [PSCustomObject]@{
				Id			= $_plot_id
				PlotState	= $_plot_state
				Sectors		= [int]($_sectors)
			}
			if ($_plot_state.toLower() -eq "notplotted") {
				$_resp_plots_remaining_arr += $_plots_info
			}
			elseif ($_plot_state.toLower() -eq "plotted") {
				$_resp_plots_completed_arr += $_plots_info
			}
			elseif ($_plot_state.toLower() -eq "abouttoexpire") {
				$_resp_plots_expiring_arr += $_plots_info
				if ($script:_b_first_time)				#no need to reset first time sqitch after the fact as the same is done in parent function
				{
					$_expiring_plots_info = [PSCustomObject]@{
						Id				= $_plot_id
						ExpiredSectors	= [int]($_sectors)
					}
					$_b_add_exp_arr_id = $true
					for ($_h = 0; $_h -lt $script:_replot_sector_count_hold_arr.count; $_h++)
					{
						if ($script:_replot_sector_count_hold_arr[$_h]) {
							if ($_plot_id -eq $script:_replot_sector_count_hold_arr[$_h].Id)
							{
								$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = [int]($_sectors)
								$_b_add_exp_arr_id = $false
								break
							}
						}
					}
					if ($_b_add_exp_arr_id)
					{
						$script:_replot_sector_count_hold_arr += $_expiring_plots_info
					}
				}
			}
			elseif ($_plot_state.toLower() -eq "expired") {
				$_resp_plots_expired_arr += $_plots_info
				if ($script:_b_first_time)				#no need to reset first time sqitch after the fact as the same is done in parent function
				{
					$_expired_plots_info = [PSCustomObject]@{
						Id				= $_plot_id
						ExpiredSectors	= [int]($_sectors)
					}
					$_b_add_exp_arr_id = $true
					for ($_h = 0; $_h -lt $script:_replot_sector_count_hold_arr.count; $_h++)
					{
						if ($script:_replot_sector_count_hold_arr[$_h]) {
							if ($_plot_id -eq $script:_replot_sector_count_hold_arr[$_h].Id)
							{
								$script:_replot_sector_count_hold_arr[$_h].ExpiredSectors = [int]($_sectors)
								$_b_add_exp_arr_id = $false
								break
							}
						}
					}
					if ($_b_add_exp_arr_id)
					{
						$script:_replot_sector_count_hold_arr += $_expired_plots_info
					}
				}
			}
		}
		##
		elseif (($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_sector_downloading_time_seconds_count") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_sector_downloading_time_seconds_count") -ge 0) -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		##
		{
			$_unique_farm_id = $_metrics_obj.Instance
			$_farm_id_info = [PSCustomObject]@{
				Id		= $_unique_farm_id
			}
			#
			$_b_add_UUId_arr_id = $true
			for ($_h = 0; $_h -lt $_resp_UUId_arr.count; $_h++)
			{
				if ($_resp_UUId_arr[$_h]) {
					if ($_unique_farm_id -eq $_resp_UUId_arr[$_h].Id)
					{
						$_b_add_UUId_arr_id = $false
						break
					}
				}
			}
			if ($_b_add_UUId_arr_id)
			{
				$_resp_UUId_arr += $_farm_id_info
			}
		}
		##
		elseif ($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_sector_encoding_time_seconds_count") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_sector_encoding_time_seconds_count") -ge 0)
		##
		{
			$_total_elpased_time = 0
			if ($_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
			{
				$_farmer_disk_id = $_metrics_obj.Instance
				$_completed_sectors = [int]($_metrics_obj.Value)
				#
				for ($_h = 0; $_h -lt $_most_recent_uptime_by_farmId_arr.count; $_h++)
				{
					if ($_most_recent_uptime_by_farmId_arr[$_h]) {
						if ($_farmer_disk_id -eq $_most_recent_uptime_by_farmId_arr[$_h].Id)
						{
							$_total_elpased_time = $_most_recent_uptime_by_farmId_arr[$_h].TotalElapsedTime
							break
						}
					}
				}
				#
				$_incremental_plot_info = [PSCustomObject]@{
					Id							= $_farmer_disk_id
					CompletedSectorsInSession	= $_completed_sectors
					ElapsedTime					= $_total_elpased_time
					DeltaSectorsCompleted		= $_completed_sectors
					DeltaElapsedTime			= $_total_elpased_time
					PlottingElapsedTime			= 0
				}
				#
				$_b_add_to_arr = $true
				for ($_h = 0; $_h -lt $script:_incremental_plot_elapsed_time_arr.count; $_h++)
				{
					if ($script:_incremental_plot_elapsed_time_arr[$_h]) {
						if ($_farmer_disk_id -eq $script:_incremental_plot_elapsed_time_arr[$_h].Id)
						{
							if ($script:_incremental_plot_elapsed_time_arr[$_h].CompletedSectorsInSession -lt $_completed_sectors)
							{
								$_b_incremental_sector_count_changed = $true

								if ($script:_b_enable_new_sector_times_calc -and $_completed_sectors -gt 0) 
								{
									if ($script:_total_time_elpased_stopwatch.Elapsed.TotalSeconds -gt (2 * [math]::Round($_total_elpased_time / $_completed_sectors,0)))
									{								
										$script:_incremental_plot_elapsed_time_arr[$_h].DeltaSectorsCompleted = $_completed_sectors - $script:_incremental_plot_elapsed_time_arr[$_h].CompletedSectorsInSession
										$script:_incremental_plot_elapsed_time_arr[$_h].DeltaElapsedTime = $_total_elpased_time - $script:_incremental_plot_elapsed_time_arr[$_h].ElapsedTime
									}
								}
								else
								{
									$script:_incremental_plot_elapsed_time_arr[$_h].DeltaSectorsCompleted = $_completed_sectors
									$script:_incremental_plot_elapsed_time_arr[$_h].DeltaElapsedTime = $_total_elpased_time
								}
								$script:_incremental_plot_elapsed_time_arr[$_h].CompletedSectorsInSession = $_completed_sectors
								$script:_incremental_plot_elapsed_time_arr[$_h].ElapsedTime = $_total_elpased_time
							}
							$_b_add_to_arr = $false
							break
						}
					}
				}
				if ($_b_add_to_arr)
				{
					$script:_incremental_plot_elapsed_time_arr += $_incremental_plot_info
				}
			}
		}
		##
		elseif ($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_sector_plotting_time_seconds") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_sector_plotting_time_seconds") -ge 0)
		##
		{
			if ($_metrics_obj.Id.toLower().IndexOf("unit") -ge 0 -or $_metrics_obj.Id.toLower().IndexOf("type") -ge 0)
			{
				$_unit_type = $_metrics_obj.Value.toLower()
				$_farmer_disk_id = ""
			}
			elseif ($_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
			{
				$_farmer_disk_id = $_metrics_obj.Instance
				$_completed_sectors = [int]($_metrics_obj.Value)
				$_delta_elapsed_time = 0
				$_delta_sectors_completed = 0
				#
				for ($_h = 0; $_h -lt $script:_incremental_plot_elapsed_time_arr.count; $_h++)
				{
					if ($script:_incremental_plot_elapsed_time_arr[$_h]) {
						if ($_farmer_disk_id -eq $script:_incremental_plot_elapsed_time_arr[$_h].Id)
						{
							if ($_b_incremental_sector_count_changed -and $_metrics_obj.Name.toLower().IndexOf("sum") -ge 0)
							{
								if ($script:_incremental_plot_elapsed_time_arr[$_h].PlottingElapsedTime -gt 0)
								{
									# NOT USED anymore as it does not provide valid results, using elapsed time instead
									#$script:_incremental_plot_elapsed_time_arr[$_h].DeltaElapsedTime = $_metrics_obj.Value - $script:_incremental_plot_elapsed_time_arr[$_h].PlottingElapsedTime
								}
								$script:_incremental_plot_elapsed_time_arr[$_h].PlottingElapsedTime = $_metrics_obj.Value
							}
							$_delta_elapsed_time = $script:_incremental_plot_elapsed_time_arr[$_h].DeltaElapsedTime
							$_delta_sectors_completed = $script:_incremental_plot_elapsed_time_arr[$_h].DeltaSectorsCompleted
							break
						}
					}
				}
				#
				if ($_metrics_obj.Name.toLower().IndexOf("sum") -ge 0) { $_farmer_disk_sector_plot_time = [double]($_delta_elapsed_time) }
				
				if ($_metrics_obj.Name.toLower().IndexOf("count") -ge 0) { $_farmer_disk_sector_plot_count = [int]($_delta_sectors_completed) }
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
					#
					$_disk_sector_perf = [PSCustomObject]@{
						Id					= $_farmer_disk_id
						SectorsPerHour		= $_sectors_per_hour
						MinutesPerSector	= $_minutes_per_sector
						DiskSectorPlotTime 	= $_farmer_disk_sector_plot_time
						PlotTimeUnit		= $_unit_type
						DiskSectorPlotCount	= $_farmer_disk_sector_plot_count
					}
					$_resp_sector_perf_arr += $_disk_sector_perf
					#
					$_farmer_disk_sector_plot_time = 0.00
					$_farmer_disk_sector_plot_count = 0
				}
			}
		}
		##
		elseif ($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_sector_plotted_counter_sectors_total") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_sector_plotted_counter_sectors_total") -ge 0) 
		##
		{
			$_total_sectors_plot_count = [int]($_metrics_obj.Value) 
		}
		##
		elseif ($_metrics_obj.Name.toLower().IndexOf("subspace_farmer_farm_proving_time_seconds") -ge 0 -or $_metrics_obj.Name.toLower().IndexOf("subspace_farmer_proving_time_seconds") -ge 0)
		##
		{
			if ($_metrics_obj.Id.toLower().IndexOf("unit") -ge 0 -or $_metrics_obj.Id.toLower().IndexOf("type") -ge 0)
			{
				$_farmer_disk_id_rewards = ""
			}
			elseif ($_metrics_obj.Id.IndexOf("farm_id") -ge 0 -and $_metrics_obj.Name.toLower().IndexOf("count") -ge 0) 
			{
				$_farmer_id = $_metrics_obj.Instance -split ","
				$_farmer_disk_id_rewards = $_farmer_id[0]
				switch ($true) {
					($_metrics_obj.Criteria.toLower().IndexOf("success") -ge 0) 
					{
						$_farmer_disk_proving_success_count = [int]($_metrics_obj.Value)
						
						$_disk_rewards_metric = [PSCustomObject]@{
							Id		= $_farmer_disk_id_rewards
							Rewards	= $_farmer_disk_proving_success_count
						}
						$_resp_rewards_arr += $_disk_rewards_metric
					}
					default  
					{
						$_farmer_disk_proving_misses_count = [int]($_metrics_obj.Value)
						$_farmer_disk_proving_misses_timeout_count = 0
						$_farmer_disk_proving_misses_rejected_count = 0
						$_farmer_disk_proving_misses_failed_count = 0
						switch ($true) {
							($_metrics_obj.Criteria.toLower().IndexOf("timeout") -ge 0) {
								$_farmer_disk_proving_misses_timeout_count = [int]($_metrics_obj.Value)
							}
							($_metrics_obj.Criteria.toLower().IndexOf("rejected") -ge 0) {
								$_farmer_disk_proving_misses_rejected_count = [int]($_metrics_obj.Value)
							}
							($_metrics_obj.Criteria.toLower().IndexOf("failed") -ge 0) {
								$_farmer_disk_proving_misses_failed_count = [int]($_metrics_obj.Value)
							}
						}
								
						$_b_miss_captured_prev = $false
						for ($_m = 0; $_m -lt $_resp_misses_arr.Count; $_m++)
						{
							$_miss_obj = $_resp_misses_arr[$_m]
							if($_miss_obj.Id -eq $_farmer_disk_id_rewards)
							{
								$_resp_misses_arr[$_m].Misses += $_farmer_disk_proving_misses_count
								$_resp_misses_arr[$_m].Timeout = $_farmer_disk_proving_misses_timeout_count
								$_resp_misses_arr[$_m].Rejected = $_farmer_disk_proving_misses_rejected_count
								$_resp_misses_arr[$_m].Failed = $_farmer_disk_proving_misses_failed_count
								$_b_miss_captured_prev = $true
								break
							}
						}
						if ($_b_miss_captured_prev -eq $false)
						{
							$_disk_misses_metric = [PSCustomObject]@{
								Id			= $_farmer_disk_id_rewards
								Misses		= $_farmer_disk_proving_misses_count
								Timeout		= $_farmer_disk_proving_misses_timeout_count
								Rejected	= $_farmer_disk_proving_misses_rejected_count
								Failed		= $_farmer_disk_proving_misses_failed_count
							}
							$_resp_misses_arr += $_disk_misses_metric
						}
					}
				}
				$_total_rewards_per_farmer += $_farmer_disk_proving_success_count
				#
				#
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
		TotalRewards		= $_total_rewards_per_farmer
	}
	$_resp_sector_perf_arr += $_disk_sector_perf

	$_disk_metrics = [PSCustomObject]@{
		Id					= $_resp_UUId_arr
		Performance			= $_resp_sector_perf_arr
		Rewards				= $_resp_rewards_arr
		Misses				= $_resp_misses_arr
		PlotsCompleted		= $_resp_plots_completed_arr
		PlotsRemaining		= $_resp_plots_remaining_arr
		PlotsExpired		= $_resp_plots_expired_arr
		PlotsAboutToExpire	= $_resp_plots_expiring_arr
	}
	[void]$_resp_disk_metrics_arr.add($_disk_metrics)

	#
	return $_resp_disk_metrics_arr
}

function fSendDiscordNotification ([string]$ioUrl, [string]$ioMsg) {
	$JSON = @{ "content" = $ioMsg; } | convertto-json
	if ($ioUrl -and $ioUrl.Trim(" ").length -gt 0)
	{
		$_resp = Invoke-WebRequest -uri $ioUrl -Method POST -Body $JSON -Headers @{'Content-Type' = 'application/json'}
	}
}

function fSendTelegramBotNotification ([string]$_io_bot_msg) {
	$_b_bot_msg_sent_success = $false
	#
	##
	#
	$_bot_api_token = $script:_telegram_api_token
	#
	## base url
	$_host_base_url = "https://api.telegram.org/bot"
	#
	## url endpoint to fetch chat_id
	$_host_url_endpoint = "/getUpdates"
	## api method
	$_bot_invoke_method = "GET"
	## full url
	$_bot_url = $_host_base_url + $_bot_api_token + $_host_url_endpoint
	## fetch chat_id for bot alert
	$_bot_resp = fInvokeTelegramBot $_bot_url $_bot_invoke_method
	$_bot_chat_id = $script:_telegram_chat_id
	#
	## outbound msg url endpoint
	$_host_url_endpoint = "/sendMessage?chat_id=$($_bot_chat_id)&text=$($_io_bot_msg)"
	## full url
	$_bot_url = $_host_base_url + $_bot_api_token + $_host_url_endpoint
	## api method
	$_bot_invoke_method = "POST"
	## send msg
	$_bot_resp = fInvokeTelegramBot $_bot_url $_bot_invoke_method
	if ($_bot_resp)
	{
		$_b_bot_msg_sent_success = $true
	}
	#
	return $_b_bot_msg_sent_success
}

function fInvokeTelegramBot ([string]$_io_bot_url, [string]$_io_method) {
	$_response = ""
	$_respObj = $null
	
	try {
		$_respObj = Invoke-RestMethod -uri $_io_bot_url -Method $_io_method
		#
		if ($_respObj) {
			$_response = $_respObj.result
		}
	}
	catch { }
	return $_response
}

function fGetProcessState ([string]$_io_process_type, [string]$_io_host_ip, [string]$_io_hostname, [string]$_io_alert_url) {
	$_resp_process_state_arr = [System.Collections.ArrayList]@()

	$_b_process_running_state = $false
	#

	# get process state, send notification if process is stopped/not running
	$_resp = fPingMetricsUrl $_io_host_ip		# needs to be outside of elapsed time check as response is used downstream to eliminiate dup call
	if ($_resp -eq "") {
		$_alert_text = $_io_process_type + " status: Stopped, Hostname:" + $_io_hostname
		try {
			$_seconds_elapsed = $_alert_stopwatch.Elapsed.TotalSeconds
			if ($script:_b_first_time -eq $true -or $_seconds_elapsed -ge $script:_alert_frequency_seconds) {
				$_b_generate_selective_alert = $false
				if ($script:_alert_category_txt.toLower().IndexOf("all") -ge 0 -or $script:_alert_category_txt.toLower().IndexOf("everything") -ge 0 -or $script:_alert_category_txt.toLower().IndexOf("cluster") -ge 0 -or $script:_alert_category_txt.toLower().IndexOf($_io_process_type.toLower()) -ge 0) {
					$_b_generate_selective_alert = $true
				}
				#
				if ($_b_generate_selective_alert) 
				{
					fSendDiscordNotification $_io_alert_url $_alert_text
					$_b_bot_msg_sent_ok = fSendTelegramBotNotification $_alert_text
				}
			}
		}
		catch {}
		#
		$_b_process_running_state = $false
	}
	else { $_b_process_running_state = $true }

	[void]$_resp_process_state_arr.add($_resp)
	[void]$_resp_process_state_arr.add($_b_process_running_state)

	return $_resp_process_state_arr
}

function fNotifyProcessOutOfSyncState ([string]$_io_process_type, [string]$_io_hostname) {

	$_b_resp_ok = $false
	#

	$_alert_text = $_io_process_type + " is out of sync, Hostname:" + $_io_hostname
	try {
		$_seconds_elapsed = $_alert_stopwatch.Elapsed.TotalSeconds
		if ($script:_b_first_time -eq $true -or $_seconds_elapsed -ge $script:_alert_frequency_seconds) {
			if ($script:_alert_category_txt.toLower().IndexOf("all") -ge 0 -or $script:_alert_category_txt.toLower().IndexOf("everything") -ge 0 -or $script:_alert_category_txt.toLower().IndexOf($_io_process_type.toLower()) -ge 0) {
				fSendDiscordNotification  $script:_url_discord $_alert_text
				$_b_bot_msg_sent_ok = fSendTelegramBotNotification $_alert_text
				$_b_resp_ok = $_b_bot_msg_sent_ok
			}
		}
	}
	catch {}
	#

	return $_b_resp_ok
}

function fCheckGitNewVersion ([string]$_io_git_url) {
	.{
		$gitVersionArr = [System.Collections.ArrayList]@()
		try {
			$gitVersionCurrObj = Invoke-RestMethod -Method 'GET' -uri $_io_git_url 2>$null
		}
		catch {}
		
		if ($gitVersionCurrObj) {
			[void]$gitVersionArr.add($gitVersionCurrObj.tag_name)
			$gitNewVersionReleaseDate = (Get-Date $gitVersionCurrObj.published_at).ToLocalTime() 
			[void]$gitVersionArr.add($gitNewVersionReleaseDate)
			[void]$gitVersionArr.add($gitVersionCurrObj.body)
		}
	}|Out-Null
	return $gitVersionArr
}

function fDisplayMonitorGitVersionVariance ([object]$_io_process_git_version, [string]$_io_process_path, [string]$_io_process_name) {
	## check monitor git version and report on variance
	if ($_io_process_git_version)
	{
		if ($_monitor_file_name -ne $_io_process_git_version[0])
		{
			$_bg_color = $_html_gray
			Write-Host "New monitor release available: " -NoNewline -ForegroundColor $_html_black -BackgroundColor $_bg_color
			Write-Host $_io_process_git_version[0].toString() -NoNewline -ForegroundColor $_html_dark_magenta -BackgroundColor $_bg_color
			Write-Host ", Dated: " -NoNewline -ForegroundColor $_html_black -BackgroundColor $_bg_color
			Write-Host $_io_process_git_version[1].toString('yyyy-MM-dd') -NoNewline -ForegroundColor $_html_dark_magenta -BackgroundColor $_bg_color
			Write-Host ", ChangeLog: " -NoNewline -ForegroundColor $_html_black -BackgroundColor $_bg_color
			Write-Host $_io_process_git_version[2].toString() -NoNewline -ForegroundColor $_html_dark_magenta -BackgroundColor $_bg_color
			Write-Host
		}
		else 
		{ 
			#do nothing
		}
	}
}

main
