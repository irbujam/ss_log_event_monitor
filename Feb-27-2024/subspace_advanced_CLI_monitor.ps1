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
	$_b_write_process_details_to_console = $false
	$_b_write_process_summary_to_console = $true
	#
	####
	try {
		[System.Console]::CursorVisible = $false
	}
	catch {}
	
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
				$Stopwatch.Restart()
				Clear-Host

				$_line_spacer_color = "gray"
				$_farmer_header_color = "cyan"
				$_farmer_header_data_color = "yellow"
				$_disk_header_color = "white"
				$_html_red = "red"
				$_html_green = "green"
				$_html_blue = "blue"
				$_html_black = "black"
				$_html_yellow = "yellow"

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
					##fWriteDataToConsole $_farmers_ip_arr
					#fGetDataForConsole $_farmers_ip_arr
					Write-Host "Press (F12) for detail view, (F10) for summary view"
					Write-Host
					if ($_b_write_process_details_to_console)
					{
						fWriteDataToConsole $_farmers_ip_arr
					}
					elseif ($_b_write_process_summary_to_console)
					{
						fGetDataForConsole $_farmers_ip_arr
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
			Write-Host "Press (F12) for detail view, (F10) for summary view"
			Write-Host
			#if ($_seconds_elapsed -ge $refreshTimeScaleInSeconds -or $_b_first_time -eq $true) {
			if ($Stopwatch.Elapsed.TotalSeconds -ge $refreshTimeScaleInSeconds -or $_b_first_time -eq $true) { 
					if ($Stopwatch.Elapsed.TotalSeconds -ge $refreshTimeScaleInSeconds)
					{					
						$Stopwatch.Restart()
					}
					#fWriteDataToConsole $_io_farmers_ip_arr
					if ($_b_write_process_details_to_console)
					{
						fWriteDataToConsole $_farmers_ip_arr
					}
					elseif ($_b_write_process_summary_to_console)
					{
						fGetDataForConsole $_farmers_ip_arr
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

							switch ( $_x.key)
							{
								F12 {
									Clear-Host
									$_b_write_process_details_to_console = $true
									$_b_write_process_summary_to_console = $false
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									Write-Host
									Write-Host "Press (F12) for detail view, (F10) for summary view"
									Write-Host
									fWriteDataToConsole $_farmers_ip_arr
								}
								F10 {
									Clear-Host
									$_b_write_process_details_to_console = $false
									$_b_write_process_summary_to_console = $true
									$_prompt_listening_mode = "Listening at: " + $_url_prefix_listener + "summary"
									Write-Host -NoNewline ("`r {0} " -f $_prompt_listening_mode) -ForegroundColor White
									Write-Host
									Write-Host
									Write-Host "Press (F12) for detail view, (F10) for summary view"
									Write-Host
									fGetDataForConsole $_farmers_ip_arr
								}
							}
						} 
						####
						Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
						#Write-Host -NoNewLine ("Refreshing in {0,3} seconds..." -f [Math]::Ceiling($_remaining_time))
						Write-Host "Refreshing in " -NoNewline 
						Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
						Write-Host " seconds..." -NoNewline 
						#Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
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
	[System.Console]::CursorVisible = $false
	
	while (($_remaining_time = ($_end_dt - [datetime]::UtcNow).TotalSeconds) -gt 0) {
		#
		## check for user toggle on data display type while waiting for refresh
		####
		if ([console]::KeyAvailable)
		{
			$_x = [System.Console]::ReadKey() 

			switch ( $_x.key)
			{
				F12 {
					Clear-Host
					$_b_write_process_details_to_console = $true
					$_b_write_process_summary_to_console = $false
					Write-Host "Press (F12) for detail view, (F10) for summary view"
					Write-Host
					fWriteDataToConsole $_farmers_ip_arr
					$_resp_last_display_type_request = "detail"
				}
				F10 {
					Clear-Host
					$_b_write_process_details_to_console = $false
					$_b_write_process_summary_to_console = $true
					Write-Host "Press (F12) for detail view, (F10) for summary view"
					Write-Host
					fGetDataForConsole $_farmers_ip_arr
					$_resp_last_display_type_request = "summary"
				}
			}
		} 
		####
		#
		Write-Host -NoNewline ("`r {0} " -f $_spinner[$_spinnerPos++ % 4]) -ForegroundColor White 
		#Write-Host -NoNewLine ("Refreshing in {0,3} seconds..." -f [Math]::Ceiling($_remaining_time))
		Write-Host "Refreshing in " -NoNewline 
		Write-Host ([Math]::Ceiling($_remaining_time)) -NoNewline -ForegroundColor black -BackgroundColor gray
		Write-Host " seconds..." -NoNewline 
		#Start-Sleep -Milliseconds ([Math]::Min($_sleep_interval_milliseconds, $_remaining_time * 1000))
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
			$farmerObj = Invoke-RestMethod -Method 'GET' -uri $_fullUrl -TimeoutSec 20
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
						ExpiredSectors	= $_sectors
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

	#### Delete - start
	#Write-Host ""
	#Write-Host "_replot_sector_count_hold_arr: " $_replot_sector_count_hold_arr
	#Write-Host "_replot_sector_count_hold_arr: " $_replot_sector_count_hold_arr.Count
	#Write-Host ""
	#### Delete - end
	#
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

function fWriteDataToConsole ([array]$_io_farmers_ip_arr) {
	$_url_discord = ""

	for ($arrPos = 0; $arrPos -lt $_io_farmers_ip_arr.Count; $arrPos++)
	{
		$_farmer_metrics_raw = ""
		$_node_metrics_raw = ""
		[array]$_process_state_arr = $null
		if ($_io_farmers_ip_arr[$arrPos].toString().Trim(' ') -ne "" -and $_io_farmers_ip_arr[$arrPos].toString().IndexOf("#") -lt 0) {
			$_config = $_io_farmers_ip_arr[$arrPos].toString().split(":").Trim(" ")
			$_process_type = $_config[0].toString()
			if ($_process_type.toLower().IndexOf("discord") -ge 0) { $_url_discord = "https:" + $_config[2].toString() }
			elseif ($_process_type.toLower() -eq "node" -or $_process_type.toLower() -eq "farmer") { 
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

				$_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $_url_discord
				$_b_process_running_ok = $_process_state_arr[1]
				
				$_node_peers_connected = 0
				if ($_process_type.toLower() -eq "farmer") {
					$_total_spacer_length = ("---------------------------------------------------------------------------------------------------------").Length
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
				$_console_msg = ""
				$_console_msg_color = ""
				if ($_b_process_running_ok -eq $true) {
					$_console_msg = "Running"
					$_console_msg_color = $_html_green
				}
				else {
					$_console_msg = "Stopped"
					$_console_msg_color = $_html_red
				}
				Write-Host $_console_msg -ForegroundColor $_console_msg_color -nonewline
				Write-Host ", " -nonewline
				Write-Host "Hostname: " -nonewline -ForegroundColor $_farmer_header_color
				Write-Host $_hostname -nonewline -ForegroundColor $_farmer_header_data_color
				if ($_process_type.toLower() -eq "node") {
					Write-Host ", " -nonewline
					Write-Host "Synced: " -nonewline -ForegroundColor $_farmer_header_color
					$_node_sync_state_disp_color = $_html_green
					$_node_sync_state_disp = "Yes"
					if ($_node_sync_state -eq $null) {
						$_node_peers_connected = "-"
						$_node_sync_state_disp = "-"
						$_node_sync_state_disp_color = $_html_red
					}
					elseif ($_node_sync_state -eq 1 -or $_b_process_running_ok -ne $true) {
						$_node_sync_state_disp = "No"
						$_node_sync_state_disp_color = $_html_red
					}
					Write-Host $_node_sync_state_disp -nonewline -ForegroundColor $_node_sync_state_disp_color
					Write-Host ", " -nonewline
					Write-Host "Peers: " -nonewline -ForegroundColor $_farmer_header_color
					Write-Host $_node_peers_connected -ForegroundColor $_farmer_header_data_color
				}
			}
			#elseif ($_process_type.toLower().IndexOf("refresh") -ge 0) {
			#	$refreshTimeScaleInSeconds = [int]$_config[1].toString()
			#	if ($refreshTimeScaleInSeconds -eq 0 -or $refreshTimeScaleInSeconds -eq "" -or $refreshTimeScaleInSeconds -eq $null) {$refreshTimeScaleInSeconds = 30}
			#}

			if ($_process_type.toLower() -ne "farmer") { continue }

			#$_farmer_metrics_raw = fPingMetricsUrl $_host_url
			$_farmer_metrics_raw = $_process_state_arr[0]
			[void]$_farmers_metrics_raw_arr.add($_farmer_metrics_raw)
			$_farmer_metrics_formatted_arr = fParseMetricsToObj $_farmers_metrics_raw_arr[$_farmers_metrics_raw_arr.Count - 1]
			
			# header lables
			$_b_write_header = $true
			#
			$_label_hostname = "Hostname"
			$_label_diskid = "Disk Id"
			$_label_size = "Size     "
			$_label_percent_complete = "%    "
			$_label_eta = "ETA         "
			$_label_replot = "    Replots     "
			$_label_sectors_per_hour = "Sectors/"
			$_label_minutes_per_sectors = "Time/  "
			$_label_rewards = "Rewards"
			$_label_misses = "Miss"
			#
			$_label_hostname_row2 = "        "
			$_label_diskid_row2 = "       "
			$_label_size_row2 = "         "
			$_label_percent_complete_row2 = "Cmpl "
			$_label_eta_row2 = "            "
			$_label_replot_row2 = "expng/expd/%cmpl"
			$_label_sectors_per_hour_row2 = "Hour    "
			$_label_minutes_per_sectors_row2 = "Sector "
			$_label_rewards_row2 = "       "
			$_label_misses_row2 = "    "
			#
			$_spacer = " "
			$_total_header_length = $_label_size.Length + $_label_percent_complete.Length + $_label_eta.Length + $_label_replot.Length + $_label_sectors_per_hour.Length + $_label_minutes_per_sectors.Length + $_label_rewards.Length + $_label_misses.Length
			$_total_header_labels = 9
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
			$_avg_minutes_per_sector = 0.0
			$_avg_seconds_per_sector = 0.0
			$_rewards_per_hour = 0
			$_rewards_per_day_estimated = 0
			foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
			{
				
				if ($_disk_sector_performance_obj) {
					if ($_disk_sector_performance_obj.Id -eq "overall") {
						#$_avg_sectors_per_hour = 0.0
						#$_avg_minutes_per_sector = 0.0
						#if ($_disk_sector_performance_obj.TotalSeconds -gt 0) {
						##if ($_disk_sector_performance_obj.TotalSeconds -and $_disk_sector_performance_obj.TotalSeconds -gt 0) {
						#	$_avg_sectors_per_hour = [math]::Round(($_disk_sector_performance_obj.TotalSectors * 3600)/ $_disk_sector_performance_obj.TotalSeconds, 1)
						#}
						#if ($_disk_sector_performance_obj.TotalSectors) {
						#	$_avg_minutes_per_sector = [math]::Round($_disk_sector_performance_obj.TotalSeconds / ($_disk_sector_performance_obj.TotalSectors * 60), 1)
						#}
						
						$_uptime = fGetElapsedTime $_disk_sector_performance_obj
						$_uptime_disp = $_uptime.days.ToString()+"d "+$_uptime.hours.ToString()+"h "+$_uptime.minutes.ToString()+"m "+$_uptime.seconds.ToString()+"s"
						#
						if ($_uptime.TotalHours) {
							$_rewards_per_hour = [math]::Round([double]($_disk_sector_performance_obj.TotalRewards / $_uptime.TotalHours), 1)
							$_rewards_per_day_estimated = [math]::Round([double](($_disk_sector_performance_obj.TotalRewards / $_uptime.TotalHours) * 24), 1)
						}
						#

						Write-Host ", " -nonewline
						Write-Host "Uptime: " -nonewline -ForegroundColor $_farmer_header_color
						#Write-Host $_uptime_disp -ForegroundColor $_farmer_header_data_color
						##Write-Host ", " -nonewline
						Write-Host $_uptime_disp -nonewline -ForegroundColor $_farmer_header_data_color
						Write-Host ", " -nonewline
						#Write-Host "Rewards: " -nonewline -ForegroundColor $_farmer_header_color
						#Write-Host  $_disk_sector_performance_obj.TotalRewards.toString() -ForegroundColor $_farmer_header_data_color
						Write-Host "Rewards (total, per hour): " -nonewline -ForegroundColor $_farmer_header_color
						Write-Host  ($_disk_sector_performance_obj.TotalRewards.toString() + ", " + $_rewards_per_hour)  -ForegroundColor $_farmer_header_data_color

						#Write-Host "Sectors/Hour (avg): " -nonewline 
						#Write-Host $_avg_sectors_per_hour.toString() -nonewline -ForegroundColor $_farmer_header_data_color
						#Write-Host ", " -nonewline
						#Write-Host "Minutes/Sector (avg): " -nonewline
						#Write-Host  $_avg_minutes_per_sector.toString() -nonewline -ForegroundColor $_farmer_header_data_color
						#Write-Host ", " -nonewline
						#Write-Host "Rewards: " -nonewline
						#Write-Host  $_disk_sector_performance_obj.TotalRewards.toString() -ForegroundColor $_farmer_header_data_color
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
			$_farm_sector_times_disp = "-"
			if ($_actual_plotting_disk_count -gt 0) {
				$_avg_minutes_per_sector = [math]::Round($_avg_minutes_per_sector / $_actual_plotting_disk_count, 2)
				$_avg_sectors_per_hour = [math]::Round($_avg_sectors_per_hour / $_actual_plotting_disk_count, 2)
				
				$_farm_sector_times = [double]($_avg_seconds_per_sector / ($_actual_plotting_disk_count * $_actual_plotting_disk_count))	# average time/farm and then avg time/disk to get net sectors time per farm
				$_farm_sector_times_obj = New-TimeSpan -seconds $_farm_sector_times

				$_farm_sector_times_disp = $_farm_sector_times_obj.minutes.ToString() + "m " + $_farm_sector_times_obj.seconds.ToString() + "s"
			}


			Write-Host "Sector Time: " -nonewline 
			Write-Host $_farm_sector_times_disp -nonewline -ForegroundColor $_farmer_header_data_color
			Write-Host ", " -nonewline
			Write-Host "Sectors/Hour (avg): " -nonewline 
			Write-Host $_avg_sectors_per_hour.toString() -nonewline -ForegroundColor $_farmer_header_data_color
			Write-Host ", " -nonewline
			Write-Host "Minutes/Sector (avg): " -nonewline
			Write-Host  $_avg_minutes_per_sector.toString() -nonewline -ForegroundColor $_farmer_header_data_color
			#Write-Host  $_avg_minutes_per_sector.toString() -ForegroundColor $_farmer_header_data_color

			Write-Host ", " -nonewline
			Write-Host "Est rewards (per day): " -nonewline
			Write-Host  ($_rewards_per_day_estimated)  -ForegroundColor $_farmer_header_data_color

			#
			#
			## Write farm level Size, % progress and ETA - NEW
			$_process_completed_sectors = 0
			$_process_completed_sectors_disp = "-"
			$_process_remaining_sectors = 0
			$_process_remaining_sectors_disp = "-"
			$_process_total_sectors = 0
			$_process_total_sectors_disp = "-"
			$_process_total_disks = 0
			$_process_total_disks_disp = "-"
			#$_process_total_disks_for_eta = 0
			foreach ($_disk_UUId_obj in $_disk_UUId_arr)
			{
				# get size, % progresion and ETA at farm level
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

						if ($_reminaing_sectors -eq 0) {
							$_process_total_disks = $_process_total_disks - 1
							$_process_total_disks_disp = $_process_total_disks
						}
						
						$_process_remaining_sectors += $_reminaing_sectors
						$_process_remaining_sectors_disp = $_process_remaining_sectors

						$_process_completed_sectors += $_completed_sectors
						$_process_completed_sectors_disp = $_process_completed_sectors

						$_process_total_sectors = $_process_completed_sectors + $_process_remaining_sectors
						$_process_total_sectors_disp = $_process_total_sectors
					}
				}
			}
			#
			## build and display farm level progress and ETA
			#
			$_farm_progress = 0
			$_farm_progress_disp = "-"
			if ($_process_total_sectors_disp -ne "-") {
				$_farm_progress = [math]::Round(([int]($_process_completed_sectors) / [int]($_process_total_sectors)) * 100, 1)
				$_farm_progress_disp = $_farm_progress.toString() + "%"
			}
			#
			$_farm_eta = 0
			$_farm_eta_disp = "-"
			if ($_process_remaining_sectors -ne 0 -and $_process_total_disks_disp -ne 0) {
				#$_farm_eta = [math]::Round((([double]($_avg_minutes_per_sector) * $_process_remaining_sectors)) / ($_process_total_disks_disp * 60 * 24), 2)
				#$_farm_eta_disp = $_farm_eta.toString() + " days"
				$_farm_eta = [double](($_avg_seconds_per_sector * $_process_remaining_sectors) / ($_process_total_disks_disp * $_process_total_disks_disp))
				$_farm_eta_obj = New-TimeSpan -seconds $_farm_eta
				$_farm_eta_disp =  $_farm_eta_obj.days.ToString() + "d " + $_farm_eta_obj.hours.ToString() + "h " + $_farm_eta_obj.minutes.ToString() + "m " 	## + $_farm_eta_obj.seconds.ToString() + "s"
			}
			#
			$_farm_size = 0
			$_farm_size_disp = "-"
			if ($_process_total_sectors_disp -ne "-") {
				$_farm_size = [int]($_process_total_sectors)
				$_farm_size_TiB = [math]::Round($_farm_size / 1000, 2)
				$_farm_size_disp = $_farm_size_TiB.ToString() + " TiB"
			}
			#Write-Host ", " -nonewline
			Write-Host "Size: " -nonewline
			#Write-Host  $_disk_sector_performance_obj.TotalRewards.toString() -ForegroundColor $_farmer_header_data_color
			Write-Host  $_farm_size_disp -nonewline -ForegroundColor $_farmer_header_data_color
			Write-Host ", " -nonewline
			Write-Host "% Complete: " -nonewline
			#Write-Host  $_disk_sector_performance_obj.TotalRewards.toString() -ForegroundColor $_farmer_header_data_color
			Write-Host  $_farm_progress_disp -nonewline -ForegroundColor $_farmer_header_data_color
			Write-Host ", " -nonewline
			Write-Host "ETA: " -nonewline
			#Write-Host  $_disk_sector_performance_obj.TotalRewards.toString() -ForegroundColor $_farmer_header_data_color
			Write-Host  $_farm_eta_disp -ForegroundColor $_farmer_header_data_color
			#
			#
			## display break-up (disk level) information for a given farm
			#
			$_total_spacer_length = ("---------------------------------------------------------------------------------------------------------").Length
			$_spacer_length = $_total_spacer_length
			$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
			
			Write-Host $_label_spacer -ForegroundColor $_line_spacer_color

			#foreach ($_disk_sector_performance_obj in $_disk_sector_performance_arr)
			foreach ($_disk_UUId_obj in $_disk_UUId_arr)
			{
				# write header if not already done
				if ($_b_write_header -eq $true) {
					# Host name header info
					# draw line
					if ($_disk_UUId_obj -ne $null) {
						$_total_spacer_length = $_disk_UUId_obj.Id.toString().Length + $_total_header_length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
					}
					else {$_total_spacer_length = ("-------------------------------------------------------------------------------").Length}
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
					else {$_spacer_length = ("-------------------------------------------------------------------------------").Length}

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
					#
					#
					## header line #2
					Write-Host $_label_spacer -nonewline

					Write-Host $_label_diskid_row2 -nonewline -ForegroundColor $_disk_header_color
					if ($_disk_UUId_obj -ne $null) {
						$_spacer_length =  $_disk_UUId_obj.Id.toString().Length - $_label_diskid.Length + 1
					}
					else {$_spacer_length = ("-------------------------------------------------------------------------------").Length}

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

					# draw line
					if ($_disk_UUId_obj -ne $null) {
						$_spacer_length =  $_disk_UUId_obj.Id.toString().Length + $_total_header_length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
					}
					else {$_spacer_length = ("-------------------------------------------------------------------------------").Length}
					$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"
					Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
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
				$_replot_sector_count = "-"
				$_replot_sector_count_hold = "-"
				$_expiring_sector_count = "-"
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
							# expired sectors info
							#$_replot_sector_count = $_disk_sector_performance_obj.DiskSectorPlotCount				# replots were counted in original plot counts so not reliable data point doe replot calc
							foreach ($_disk_plots_expired_obj in $_disk_plots_expired_arr)
							{
								if ($_disk_plots_expired_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_expired_obj.Id) { continue }
								}
								$_replot_sector_count = $_disk_plots_expired_obj.Sectors
								for ($_h = 0; $_h -lt $_replot_sector_count_hold_arr.count; $_h++)
								{
									if ($_replot_sector_count_hold_arr[$_h]) {
										if ($_disk_UUId_obj.Id -ne $_replot_sector_count_hold_arr[$_h].Id) { continue }
									}
									if ($_replot_sector_count_hold_arr[$_h].ExpiredSectors -eq 0 -or $_replot_sector_count_hold_arr[$_h].ExpiredSectors -lt $_replot_sector_count) 
									{
										$_replot_sector_count_hold_arr[$_h].ExpiredSectors = $_replot_sector_count
									}
									$_replot_sector_count_hold = $_replot_sector_count_hold_arr[$_h].ExpiredSectors
									break
								}
								break
							}
							# expiring sectors info
							foreach ($_disk_plots_expiring_obj in $_disk_plots_expiring_arr)
							{
								if ($_disk_plots_expiring_obj) {
									if ($_disk_UUId_obj.Id -ne $_disk_plots_expiring_obj.Id) { continue }
								}
								$_expiring_sector_count = $_disk_plots_expiring_obj.Sectors
							}
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
						break
					}
				}

				# write size, % progresion and ETA
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
						$_total_sectors_GiB = $_completed_sectors + $_reminaing_sectors
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

						$_spacer_length = $_label_percent_complete.Length - $_plotting_percent_complete_disp.Length
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
				}

				# write replotting info
				$_spacer_length = $_label_eta.Length - $_eta_disp.Length
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				Write-Host $_label_spacer -nonewline
				#Write-Host $_replot_sector_count -nonewline
				$_replot_progress = "-"
				if ($_replot_sector_count -ne "-" -and $_replot_sector_count_hold -ne "-")
				{
					if ([int]($_replot_sector_count) -gt 0 -and [int]($_replot_sector_count_hold) -gt 0)
					{
						$_replot_progress = ([math]::Round([int]($_replot_sector_count) / [int]($_replot_sector_count_hold), 1)).ToString() + "%"
					}
				}
				## DO NOT DELETE (TBD add sectors remaining) ## - 	#$_replot_sector_count_disp = $_expiring_sector_count.ToString() + "/" + $_replot_sector_count_hold.ToString() + "/" + $_replot_sector_count.ToString()
				$_replot_sector_count_disp = $_expiring_sector_count.ToString() + "/" + $_replot_sector_count_hold.ToString() + "/" + $_replot_progress
				if ($_replot_sector_count_hold -eq 0)
				{
					if ($_expiring_sector_count -gt 0)
					{
						$_replot_sector_count_disp = $_expiring_sector_count.ToString() + "/" + "-" + "/" + "-"
					}
					else
					{
						$_replot_sector_count_disp = "-" + "/" + "-" + "/" + "-"
					}
				}
				Write-Host $_replot_sector_count_disp -nonewline
				
				# write performance data
				##$_spacer_length = $_label_eta.Length - $_eta_disp.Length
				#$_spacer_length = $_label_replot.Length - $_replot_sector_count.ToString().Length
				$_spacer_length = $_label_replot.Length - $_replot_sector_count_disp.Length 
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
			
				Write-Host $_label_spacer -nonewline
				Write-Host $_sectors_per_hour_data_disp -nonewline

				$_spacer_length = [int]($_label_sectors_per_hour.Length - $_sectors_per_hour_data_disp.Length)
				$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
				$_label_spacer = $_label_spacer + "|"
				
				Write-Host $_label_spacer -nonewline
				#Write-Host $_minutes_per_sector_data_disp -nonewline
				$_time_per_sector_disp = $_time_per_sector_data_obj.minutes.ToString() + "m " + $_time_per_sector_data_obj.seconds.ToString() + "s"
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

					#$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_minutes_per_sector_data_disp.Length)
					$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_time_per_sector_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
				
					Write-Host $_label_spacer -nonewline
					Write-Host $_disk_rewards_obj.Rewards -nonewline
					
					$_b_reward_data_printed = $true
				}
				if ($_b_reward_data_printed -eq $false) 				# rewards not published yet in endpoint
				{
					#$_spacer_length = [int]($_label_minutes_per_sectors.Length - $_minutes_per_sector_data_disp.Length)
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
					}
					
					$_spacer_length = [int]($_label_rewards.Length - $_rewards_data_disp.Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer -nonewline
					Write-Host $_disk_misses_obj.Misses -nonewline -ForegroundColor $_missed_rewards_color

					$_spacer_length = [int]($_label_misses.Length - $_disk_misses_obj.Misses.toString().Length)
					$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
					$_label_spacer = $_label_spacer + "|"
					
					Write-Host $_label_spacer
					
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
					Write-Host 0 -nonewline		#no rewards data (only misses data) populated in endpoint

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
	if ($_disk_UUId_obj) {
		$_spacer_length =  $_disk_UUId_obj.Id.toString().Length + $_total_header_length + $_total_header_labels + 2 	# 1 for leading and 1 for trailing
	}
	else {$_spacer_length = ("--------------------------------------------------------------------------------------").Length}
	$_label_spacer = fBuildDynamicSpacer $_spacer_length "-"

	Write-Host $_label_spacer -ForegroundColor $_line_spacer_color
	
	# display latest github version info
	$_gitVersionDisp = " - "
	$_gitVersionDispColor = $_html_red
	if ($null -ne $gitVersion) {
		$currentVersion = $gitVersion[0] -replace "[^.0-9]"
		$_gitVersionDisp = $gitVersion[0]
		$_gitVersionDispColor = $_html_green
	}

	Write-Host
	Write-Host "Latest github version : " -nonewline
	Write-Host "$($_gitVersionDisp)" -ForegroundColor $_gitVersionDispColor

	##
	# display last refresh time 
	$currentDate = (Get-Date).ToLocalTime().toString()
	# Refresh
	Write-Host "Last refresh on: " -ForegroundColor White -nonewline; Write-Host "$currentDate" -ForegroundColor Yellow;
	#echo `n
	#
}
			
main
