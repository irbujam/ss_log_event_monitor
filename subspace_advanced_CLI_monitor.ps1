<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

##header
$host.UI.RawUI.WindowTitle = "Subspace Advanced CLI Process Monitor"
function main {
	$_b_allow_refresh = $false
	$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$_for_git_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$gitVersion = fCheckGitNewVersion
	$_refresh_duration_default = 30
	$refreshTimeScaleInSeconds = 0		# defined in config, defaults to 30 if not provided
	$_alert_frequency_seconds = 0		# defined in config, defaults to refreshTimeScaleInSeconds if not provided
	#
	$_b_console_disabled = $false
	####
	$_b_listener_running = $false
	$_api_enabled = "N"
	$_api_host = ""
	$_api_host_ip = ""
	$_api_host_port = ""
	$_url_prefix_listener = ""
	$_b_request_processed = $false
	#
	$_alert_stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$_b_first_time = $true
	#
	[array]$script:_replot_sector_count_hold_arr = $null
	#
	[array]$script:_individual_farmer_id_arr = $null
	$script:_individual_farmer_id_last_pos = -1
	#
	[array]$script:_char_arr = @("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z")
	[array]$script:_num_key_arr = @("D1","D2","D3","D4","D5","D6","D7","D8","D9","NumPad1","NumPad2","NumPad3","NumPad4","NumPad5","NumPad6","NumPad7","NumPad8","NumPad9")
	#
	$_b_write_process_details_to_console = $false
	$_b_write_process_summary_to_console = $true
	#
	####
	
	Clear-Host
	
	try {
		while ($true) {
			#
			if ($Stopwatch.Elapsed.TotalSeconds -ge $refreshTimeScaleInSeconds -or $_b_first_time -eq $true) 
			{
				$_b_allow_refresh = $true
			}
			if ($_b_allow_refresh) 
			{
				$script:_individual_farmer_id_arr = $null
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
				$_html_gray = "gray"

				$_farmers_metrics_raw_arr = [System.Collections.ArrayList]@()
				$_node_metrics_raw_arr = [System.Collections.ArrayList]@()

				$_configFile = "./config.txt"
				$_farmers_ip_arr = Get-Content -Path $_configFile | Select-String -Pattern ":"

				$_process_alt_name_max_length = 0
				for ($arrPos = 0; $arrPos -lt $_farmers_ip_arr.Count; $arrPos++)
				{
					if ($_farmers_ip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_farmers_ip_arr[$arrPos].toString().IndexOf("#") -lt 0) {
						$_config = $_farmers_ip_arr[$arrPos].toString().split(":").Trim(" ")
						$_process_type = $_config[0].toString()
						if ($_process_type.toLower().IndexOf("enable-api") -ge 0) { $_api_enabled = $_config[1].toString()}
						elseif ($_process_type.toLower().IndexOf("api-host") -ge 0) {$_api_host = $_config[1].toString() + ":" + $_config[2].toString()}
						elseif ($_process_type.toLower().IndexOf("refresh") -ge 0) {
							$refreshTimeScaleInSeconds = [int]$_config[1].toString()
							if ($refreshTimeScaleInSeconds -eq 0 -or $refreshTimeScaleInSeconds -eq "" -or $refreshTimeScaleInSeconds -eq $null) {$refreshTimeScaleInSeconds = $_refresh_duration_default}
						}
						elseif ($_process_type.toLower().IndexOf("alert-frequency") -ge 0) {
							$_alert_frequency_seconds = [int]$_config[1].toString()
						}
						elseif ($_process_type.toLower().IndexOf("start-up") -ge 0 -and $_b_first_time) {
							
							$_start_up_view = $_config[1].toString().toLower()
							if ($_start_up_view.IndexOf("s") -eq 0)
							{
								$_b_write_process_summary_to_console = $true
								$_b_write_process_details_to_console = $false
							}
							elseif ($_start_up_view.IndexOf("d") -eq 0)
							{
								$_b_write_process_summary_to_console = $false
								$_b_write_process_details_to_console = $true
							}
						}
						# get max lenght for host alt name
						elseif ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer") { 
							$_process_ip = $_config[1].toString()
							$_process_hostname_alt = ""
							if ($_config.Count -gt 3) {
								$_process_hostname_alt = $_config[3].toString()
							}
							$_process_hostname = $_process_ip
							if ($_process_hostname_alt -and $_process_hostname_alt.length -gt 0)
							{
								$_process_hostname = $_process_hostname_alt
							}
							if ($_process_hostname.Length -gt $_process_alt_name_max_length) { $_process_alt_name_max_length = $_process_hostname.Length }
						}
					}
				}
				# check if alert frequency was provided in config and if not default to aut-refresh frequency 
				if ($_alert_frequency_seconds -eq 0 -or $_alert_frequency_seconds -eq "" -or $_alert_frequency_seconds -eq $null -or $_alert_frequency_seconds -lt $refreshTimeScaleInSeconds) {$_alert_frequency_seconds = $refreshTimeScaleInSeconds}
				#
				### Check if API mode enabled and we have a host
				#
				if ($_api_enabled.toLower() -eq "y" -and $_api_host -ne $null -and $_api_host -ne "")
				{
					$_b_console_disabled = $true

					if ($_b_request_processed -eq $false) 
					{
						#### create listener object for later use
						# create a listener for inbound http request
						$_api_host_arr = $_api_host.split(":").Trim(" ")
						$_api_host_ip = $_api_host_arr[0]
						$_api_host_port = $_api_host_arr[1]
						
						#Write-Host ("_api_host_ip: " + $_api_host_ip)
						#Write-Host ("_api_host_port: " + $_api_host_port)
						$_api_host_url = $_api_host_ip + ":" + $_api_host_port
						if ($_api_host_ip -eq "0.0.0.0" ){ $_api_host_url = "*:" + $_api_host_port }
						
						$_url_prefix = "http://" + $_api_host_url + "/"
						$_url_prefix_listener = $_url_prefix.toString().replace("http://127.0.0.1", "http://localhost")
						#Write-Host ("_url_prefix_listener: " + $_url_prefix_listener)

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
					#$_http_listener.Close()	
				}
				else{
					##fWriteDetailDataToConsole $_farmers_ip_arr
					#fGetSummaryDataForConsole $_farmers_ip_arr
					Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
					if ($_b_write_process_summary_to_console)
					{
						Write-Host " Press number key to view single farmer detail." -ForegroundColor $_html_gray
					}
					else {
						Write-Host
					}
					Write-Host
					if ($_b_write_process_details_to_console)
					{
						fWriteDetailDataToConsole $_farmers_ip_arr
					}
					elseif ($_b_write_process_summary_to_console)
					{
						fGetSummaryDataForConsole $_farmers_ip_arr
					}
					# check previous alerts and reset for the next event
					if ($_alert_stopwatch.Elapsed.TotalSeconds -ge $_alert_frequency_seconds)
					{
						$_alert_stopwatch.Restart()
					}
					$_b_first_time = $false
					$_last_display_type_request = fStartCountdownTimer $refreshTimeScaleInSeconds
					if ($_last_display_type_request.toLower() -eq "summary") { $_b_write_process_summary_to_console = $true; $_b_write_process_details_to_console = $false }
					elseif ($_last_display_type_request.toLower() -eq "detail") { $_b_write_process_summary_to_console = $false; $_b_write_process_details_to_console = $true }
				}
				
				###### Auto refresh
				$_for_git_HoursElapsed = $_for_git_stopwatch.Elapsed.TotalHours
				if ($_for_git_HoursElapsed -ge 1) {
					$gitNewVersion = fCheckGitNewVersion
					if ($gitNewVersion) {
						$gitVersion = $gitNewVersion
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

function fInvokeHttpRequestListener ([array]$_io_farmers_ip_arr, [object]$_io_context_task) {
	$_html_full = $null
	$_font_size = 5
	
	
	while (!($_context_task.AsyncWaitHandle.WaitOne(200))) { 
			
			# wait for request - async
			$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
			Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
			Write-Host
			Write-Host
			Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
			Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
			Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
			Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
			Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
			if ($_b_write_process_summary_to_console)
			{
				Write-Host " Press number key to view single farmer detail." -ForegroundColor $_html_gray
			}
			else {
				Write-Host
			}
			Write-Host
			#if ($_seconds_elapsed -ge $refreshTimeScaleInSeconds -or $_b_first_time -eq $true) {
			if ($Stopwatch.Elapsed.TotalSeconds -ge $refreshTimeScaleInSeconds -or $_b_first_time -eq $true) { 
					if ($Stopwatch.Elapsed.TotalSeconds -ge $refreshTimeScaleInSeconds)
					{					
						$Stopwatch.Restart()
					}
					#fWriteDetailDataToConsole $_io_farmers_ip_arr
					if ($_b_write_process_details_to_console)
					{
						fWriteDetailDataToConsole $_farmers_ip_arr
					}
					elseif ($_b_write_process_summary_to_console)
					{
						fGetSummaryDataForConsole $_farmers_ip_arr
					}

					if ($_alert_stopwatch.Elapsed.TotalSeconds -ge $_alert_frequency_seconds)
					{
						$_alert_stopwatch.Restart()
					}

					$_sleep_interval_milliseconds = 1000
					$_spinner = '|', '/', '-', '\'
					$_spinnerPos = 0
					$_end_dt = [datetime]::UtcNow.AddSeconds($refreshTimeScaleInSeconds)
					#[System.Console]::CursorVisible = $false
					
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
									$_b_write_process_details_to_console = $true
									$_b_write_process_summary_to_console = $false
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									Write-Host
									Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
									#Write-Host " Press number key to view single farmer detail." -ForegroundColor $_html_gray
									Write-Host
									Write-Host
									fWriteDetailDataToConsole $_farmers_ip_arr
								}
								F10 {
									$script:_individual_farmer_id_last_pos = -1
									Clear-Host
									$_b_write_process_details_to_console = $false
									$_b_write_process_summary_to_console = $true
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									Write-Host
									Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
									Write-Host " Press number key to view single farmer detail." -ForegroundColor $_html_gray
									Write-Host
									fGetSummaryDataForConsole $_farmers_ip_arr
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
										Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
										Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
										Write-Host " Arrow keys [" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
										Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
										Write-Host "] will loop thru single farmer." -ForegroundColor $_html_gray
										Write-Host
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
									}
								}
								LeftArrow {
									Clear-Host
									Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
									Write-Host " Arrow keys [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "] will loop thru single farmer." -ForegroundColor $_html_gray
									Write-Host
									$script:_individual_farmer_id_last_pos -= 1
									if ($script:_individual_farmer_id_last_pos -ge 0)
									{
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
									}
									else{
										$script:_individual_farmer_id_last_pos = $script:_individual_farmer_id_arr.Count - 1
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
									}
								}
								RightArrow {
									Clear-Host
									Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
									Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
									Write-Host " Arrow keys [" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
									Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
									Write-Host "] will loop thru single farmer" -ForegroundColor $_html_gray
									Write-Host
									$script:_individual_farmer_id_last_pos += 1
									if ($script:_individual_farmer_id_last_pos -lt $script:_individual_farmer_id_arr.Count)
									{
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
									}
									else{
										$script:_individual_farmer_id_last_pos = 0
										$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
										fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
									}
								}
							}
						} 
						####
						Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
						#Write-Host -NoNewLine ("Refreshing in {0,3} seconds..." -f [Math]::Ceiling($_remaining_time))
						Write-Host "Refreshing in " -NoNewline 
						Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
						Write-Host " seconds..." -NoNewline 
						Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
						if ($_context_task.AsyncWaitHandle.WaitOne(200)) { break }
					}
					Write-Host

					Clear-Host
					$_b_first_time = $false
			}
	}
	## process request received
	$_context = $_context_task.GetAwaiter().GetResult()
	#
	#
	## build html for web ui
	#
	$_process_metrics_arr = fGetDataForHtml $_io_farmers_ip_arr
	$_process_header_arr = $_process_metrics_arr[0].ProcessHeader
	$_process_sub_header_arr = $_process_metrics_arr[0].ProcessSubHeader
	$_process_disk_data_arr = $_process_metrics_arr[0].ProcessData
	$_process_disk_data_js_arr = fConverPSArrToJScriptArr $_process_disk_data_arr
	
	$_b_initial_entry = $true
	#
	##
	$_chart_labels = '['
	$_chart_alt_labels = '['
	$_chart_progess_data = '['
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
		$_overall_progress = "-"
		$_overall_progress_disp = "-"
		$_process_eta = 0.0
		$_process_eta_disp = "-"
		$_process_size = 0.0
		$_process_size_disp = "-"
		$_process_sector_time = 0.0
		$_b_i_was_here = $false

		if ($_process_farm_sub_header.TotalSectors -ne "-")
		{
			$_overall_progress = [math]::Round(([int]($_process_farm_sub_header.CompletedSectors) / [int]($_process_farm_sub_header.TotalSectors)) * 100, 1)
			$_overall_progress_disp = $_overall_progress.toString() + "%"
			#
			#if ($_process_farm_sub_header.RemainingSectors -ne "-" -and $_process_farm_sub_header.MinutesPerSectorAvg -ne "-" -and $_process_farm_sub_header.TotalDisksForETA -ne 0) {
			if ($_process_farm_sub_header.RemainingSectors -ne "-" -and $_process_farm_sub_header.SectorTime -ne $null -and $_process_farm_sub_header.TotalDisksForETA -ne 0) {
				$_process_sector_time = New-TimeSpan -seconds ($_process_farm_sub_header.SectorTime / $_process_farm_sub_header.TotalDisksForETA)
				$_b_i_was_here = $true
				#$_process_eta = [math]::Round((([double]($_process_farm_sub_header.MinutesPerSectorAvg) * $_process_farm_sub_header.RemainingSectors)) / ($_process_farm_sub_header.TotalDisksForETA * 60 * 24), 2)
				#$_process_eta_disp = $_process_eta.toString() + " days"
				$_process_eta = [double](($_process_farm_sub_header.SectorTime * $_process_farm_sub_header.RemainingSectors) / $_process_farm_sub_header.TotalDisksForETA)
				$_process_eta_obj = New-TimeSpan -seconds $_process_eta
				$_process_eta_disp = $_process_eta_obj.days.toString() + "d " + $_process_eta_obj.hours.toString() + "h " + $_process_eta_obj.minutes.toString() + "m" 
			}
			$_process_size = [int]($_process_farm_sub_header.TotalSectors)
			$_process_size_TiB = [math]::Round($_process_size / 1000, 2)
			$_process_size_disp = $_process_size_TiB.ToString()
		}

		if ($_b_initial_entry)
		{
			$_chart_labels += '"' + $_process_farm_sub_header.UUId + '"'
			$_chart_alt_labels += '"' + $_process_farm_sub_header.Hostname + '"'
			$_chart_progess_data += '"' + $_overall_progress + '"'
			if ($_b_i_was_here) {
				$_chart_sector_time_data += '"' + $_process_sector_time.minutes.ToString() + "m " + $_process_sector_time.seconds.ToString() + "s" + '"' 
			}
			else {
				$_chart_sector_time_data += '"' + 0 + "m " + 0 + "s" + '"' 
			}
			$_chart_total_sector_time_data += '"' + [math]::Round($_process_sector_time.TotalSeconds / 60, 1) + '"' 
			if ($_b_i_was_here) {
				if ($_process_sector_time.TotalSeconds -gt 0)
				{
					$_chart_total_sectors_per_hour_data += '"' + ([math]::Round(3600 / $_process_sector_time.TotalSeconds)).ToString() + '"'
				}
				else {
					$_chart_total_sectors_per_hour_data += '"' + 0 + '"'
				}
			}
			else {
				$_chart_total_sectors_per_hour_data += '"' + 0 + '"'
			}
			#$_chart_eta_data += '"' + $_process_eta + '"'
			$_chart_eta_data += '"' + $_process_eta_disp + '"'
			$_chart_size_data += '"' + $_process_size_disp + '"'
			$_chart_uptime_data += '"' + $_process_farm_sub_header.Uptime + '"'
			$_chart_perf_sectorsPerHour_data += '"' + $_process_farm_sub_header.SectorsPerHourAvg + '"'
			$_chart_perf_minutesPerSector_data += '"' + $_process_farm_sub_header.MinutesPerSectorAvg + '"'
			$_chart_rewards_data += '"' + $_process_farm_sub_header.TotalRewards + '"'
			$_b_initial_entry = $false
		}
		else {
			$_chart_labels += ',"' +$_process_farm_sub_header.UUId + '"'
			$_chart_alt_labels += ',"' +$_process_farm_sub_header.Hostname + '"'
			$_chart_progess_data += ',"' + $_overall_progress + '"'
			if ($_b_i_was_here) {
				$_chart_sector_time_data += ',"' + $_process_sector_time.minutes.ToString() + "m " + $_process_sector_time.seconds.ToString() + "s" + '"' 
			}
			else {
				$_chart_sector_time_data += ',"' + 0 + "m " + 0 + "s" + '"' 
			}
			$_chart_total_sector_time_data += ',"' + [math]::Round($_process_sector_time.TotalSeconds / 60, 1) + '"' 
			if ($_b_i_was_here) {
				if ($_process_sector_time.TotalSeconds -gt 0)
				{
					$_chart_total_sectors_per_hour_data += ',"' + ([math]::Round(3600 / $_process_sector_time.TotalSeconds)).ToString() + '"'
				}
				else {
					$_chart_total_sectors_per_hour_data += ',"' + 0 + '"'
				}
			}
			else {
				$_chart_total_sectors_per_hour_data += ',"' + 0 + '"'
			}
			#$_chart_eta_data += ',"' + $_process_eta + '"'
			$_chart_eta_data += ',"' + $_process_eta_disp + '"'
			$_chart_size_data += ',"' + $_process_size_disp + '"'
			$_chart_uptime_data += ',"' + $_process_farm_sub_header.Uptime + '"'
			$_chart_perf_sectorsPerHour_data += ',"' + $_process_farm_sub_header.SectorsPerHourAvg + '"'
			$_chart_perf_minutesPerSector_data += ',"' + $_process_farm_sub_header.MinutesPerSectorAvg + '"'
			$_chart_rewards_data += ',"' + $_process_farm_sub_header.TotalRewards + '"'
		}
	}
	$_chart_labels += ']'
	$_chart_alt_labels += ']'
	$_chart_progess_data += ']'
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
				<meta name="viewport" content="width=device-width, initial-scale=1">
				<style>
				body {
					#padding: 25px;
					background-color: white;
					color: black;
					font-size: 15px;
				}
				.dark-mode {
					background-color: black;
					color: white;
					font-size: 15px;
				}

				.chart_font_header {
					#background-color: white;
					#color: black;
					font-size: 15px;
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

	$_html_bar_chart = fBuildBarChart $_chart_labels $_chart_alt_labels $_chart_progess_data $_chart_sector_time_data $_chart_eta_data $_chart_size_data $_chart_uptime_data $_chart_perf_sectorsPerHour_data $_chart_perf_minutesPerSector_data $_process_disk_data_js_arr 'Farm Plotting Progress'
	$_html_radar_chart = fBuildRadarChart $_chart_labels $_chart_alt_labels $_chart_perf_sectorsPerHour_data $_chart_perf_minutesPerSector_data $_chart_rewards_data $_process_disk_data_js_arr 'Farm Performance (Avg)'
	
	
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
	#$_html_full += "<Table>"
	#$_html_full += "<tr><td>"
	$_html_full += $_html_bar_chart
	#$_html_full += "</td></tr>"
	#$_html_full += "<tr><td>"
	$_html_full += '<div id=progress onclick="fClearBarChartDetails()"></div>'
	#$_html_full += "</td></tr>"
	#$_html_full += "<tr><td>"
	$_html_full += $_html_radar_chart
	
	
	$_html_full += $_html_net_performance_chart
	
	
	#$_html_full += "</td></tr>"
	#$_html_full += "<tr><td>"
	$_html_full += $_html_pie_chart
	#$_html_full += "</td></tr>"
	#$_html_full += "<tr><td>"
	$_html_full += '<div id=rewards onclick="fClearPieChartDetails()"></div>'
	#$_html_full += "</td></tr>"
	#$_html_full += "</Table>"

	$_html_full +=
				'</body>
				</html>'
	
	#$_context = $_io_context_task
	
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
		#Write-Host $_console_log
		$_response = $_html_full
		if ($_response) {
			$_response_bytes = [System.Text.Encoding]::UTF8.GetBytes($_response)
			$_context.Response.OutputStream.Write($_response_bytes, 0, $_response_bytes.Length)
		}
	}
	#else {
	#	$_console_log =  "invalid url: " + $_request_url + ", method: " + $_request_method
	#	#Write-Host $_console_log
	#	$_response = "<html><body>Invalid url...</body></html>"
	#	$_response_bytes = [System.Text.Encoding]::UTF8.GetBytes($_response)
	#	$_context.Response.OutputStream.Write($_response_bytes, 0, $_response_bytes.Length)
	#}

	# end response and close listener
	#Start-Sleep -Milliseconds 200
	#Start-Sleep -Seconds 1
	$_context.Response.Close()
	
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
					$_b_write_process_details_to_console = $true
					$_b_write_process_summary_to_console = $false
					Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
					#Write-Host " Press number key to view single farmer detail." -ForegroundColor $_html_gray
					Write-Host
					Write-Host
					fWriteDetailDataToConsole $_farmers_ip_arr
					$_resp_last_display_type_request = "detail"
				}
				F10 {
					$script:_individual_farmer_id_last_pos = -1
					Clear-Host
					$_b_write_process_details_to_console = $false
					$_b_write_process_summary_to_console = $true
					Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
					Write-Host " Press number key to view single farmer detail." -ForegroundColor $_html_gray
					Write-Host
					fGetSummaryDataForConsole $_farmers_ip_arr
					$_resp_last_display_type_request = "summary"
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
						Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
						Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
						Write-Host " Arrow keys [" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
						Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
						Write-Host "] will loop thru single farmer." -ForegroundColor $_html_gray
						Write-Host
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
					}
				}
				LeftArrow {
					Clear-Host
					Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
					Write-Host " Arrow keys [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "] will loop thru single farmer." -ForegroundColor $_html_gray
					Write-Host
					$script:_individual_farmer_id_last_pos -= 1
					if ($script:_individual_farmer_id_last_pos -ge 0)
					{
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
					}
					else{
						$script:_individual_farmer_id_last_pos = $script:_individual_farmer_id_arr.Count - 1
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
					}
				}
				RightArrow {
					Clear-Host
					Write-Host "Press to toggle views: [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F10" -NoNewLine -ForegroundColor $_html_yellow 
					Write-Host "]-summary, [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "F12" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "]-everything." -NoNewLine -ForegroundColor $_html_gray
					Write-Host " Arrow keys [" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "->" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "/" -NoNewLine -ForegroundColor $_html_gray
					Write-Host "<-" -NoNewLine -ForegroundColor $_html_yellow
					Write-Host "] will loop thru single farmer" -ForegroundColor $_html_gray
					Write-Host
					$script:_individual_farmer_id_last_pos += 1
					if ($script:_individual_farmer_id_last_pos -lt $script:_individual_farmer_id_arr.Count)
					{
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
					}
					else{
						$script:_individual_farmer_id_last_pos = 0
						$_individual_farmer_id_requested = $script:_individual_farmer_id_arr[$script:_individual_farmer_id_last_pos]
						fWriteIndividualProcessDataToConsole $_individual_farmer_id_requested
					}
				}
			}
		} 
		####
		#
		[System.Console]::CursorVisible = $false
		Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
		#Write-Host -NoNewLine ("Refreshing in {0,3} seconds..." -f [Math]::Ceiling($_remaining_time))
		Write-Host "Refreshing in " -NoNewline 
		Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
		Write-Host " seconds..." -NoNewline 
		Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
	}
	Write-Host
	return $_resp_last_display_type_request
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
	#$_resp_ts_str = $_io_ts_obj.days.toString() + "d " + $_io_ts_obj.hours.toString() + "h " + $_io_ts_obj.minutes.toString() + "m"
	if ($_io_ts_obj) {
		if ($_io_ts_obj.days -gt 0)
		{
			$_resp_ts_str = $_io_ts_obj.days.toString() + "d " + $_io_ts_obj.hours.toString() + "h"
		}
		elseif ($_io_ts_obj.hours -gt 0)
		{
			$_resp_ts_str = $_io_ts_obj.hours.toString() + "h " + $_io_ts_obj.minutes.toString() + "m"
		}
		else
		{
			$_resp_ts_str = $_io_ts_obj.hours.toString() + "m " + $_io_ts_obj.seconds.toString() + "s"
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

function fPingMetricsUrl ([string]$ioUrl) {
	.{
		$_response = ""
		$_fullUrl = "http://" + $ioUrl + "/metrics"
		try {
			#$farmerObj = Invoke-RestMethod -Method 'GET' -uri $_fullUrl -TimeoutSec 20
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
	$_total_rewards_per_farmer = 0
	#
	foreach ($_metrics_obj in $_io_farmer_metrics_arr)
	{
		if ($_metrics_obj.Name.IndexOf("subspace_farmer_sectors_total_sectors") -ge 0 -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		{
			$_plot_id = ($_metrics_obj.Instance -split ",")[0]
			$_plot_state = $_metrics_obj.Criteria.ToString().Trim('"')
			$_sectors = $_metrics_obj.Value
			
			$_plots_info = [PSCustomObject]@{
				Id			= $_plot_id
				PlotState	= $_plot_state
				Sectors		= $_sectors
			}
			if ($_plot_state.toLower() -eq "notplotted") {
				$_resp_plots_remaining_arr += $_plots_info
			}
			elseif ($_plot_state.toLower() -eq "plotted") {
				$_resp_plots_completed_arr += $_plots_info
			}
			elseif ($_plot_state.toLower() -eq "abouttoexpire") {
				$_resp_plots_expiring_arr += $_plots_info
			}
			elseif ($_plot_state.toLower() -eq "expired") {
				$_resp_plots_expired_arr += $_plots_info
				if ($_b_first_time)				#no need to reset first time sqitch after the fact as the same is done in parent function
				{
					$_expired_plots_info = [PSCustomObject]@{
						Id				= $_plot_id
						ExpiredSectors	= [int]($_sectors)
					}
					$script:_replot_sector_count_hold_arr += $_expired_plots_info
				}
			}
		}
		elseif ($_metrics_obj.Name.IndexOf("subspace_farmer_auditing_time_seconds_count") -ge 0 -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
		#elseif ($_metrics_obj.Name.IndexOf("subspace_farmer_sector_downloading_time_seconds_count") -ge 0 -and $_metrics_obj.Id.IndexOf("farm_id") -ge 0) 
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
				if ($_metrics_obj.Criteria.toLower().IndexOf("success") -ge 0) {
					$_farmer_disk_proving_success_count = [int]($_metrics_obj.Value)
					
					$_disk_rewards_metric = [PSCustomObject]@{
						Id		= $_farmer_disk_id_rewards
						Rewards	= $_farmer_disk_proving_success_count
						#Misses	= $_farmer_disk_proving_misses_count
					}
					$_resp_rewards_arr += $_disk_rewards_metric
				}
				elseif ($_metrics_obj.Criteria.toLower().IndexOf("timeout") -ge 0) {
					$_farmer_disk_proving_misses_count = [int]($_metrics_obj.Value)
					
					$_disk_misses_metric = [PSCustomObject]@{
						Id		= $_farmer_disk_id_rewards
						#Rewards	= $_farmer_disk_proving_success_count
						Misses	= $_farmer_disk_proving_misses_count
					}
					$_resp_misses_arr += $_disk_misses_metric
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
	Invoke-WebRequest -uri $ioUrl -Method POST -Body $JSON -Headers @{'Content-Type' = 'application/json'}
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
			if ($_b_first_time -eq $true -or $_seconds_elapsed -ge $_alert_frequency_seconds) {
				fSendDiscordNotification $_io_alert_url $_alert_text
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

function fCheckGitNewVersion {
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
