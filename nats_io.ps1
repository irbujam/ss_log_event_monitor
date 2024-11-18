<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

function fGenAlertNotifications ([string]$_io_alert_text) {
	try {
		$_seconds_elapsed = $_alert_stopwatch.Elapsed.TotalSeconds
		if ($script:_b_first_time -eq $true -or $_seconds_elapsed -ge $_alert_frequency_seconds) {
			fSendDiscordNotification $script:_url_discord $_io_alert_text
			$_b_bot_msg_sent_ok = fSendTelegramBotNotification $_io_alert_text
		}
	}
	catch {}
}

function fPingNatsServer ([string]$_io_nats_url) {
[object]$_io_nats_response_obj = [PSCustomObject]@{
	ServerName	= $null
	Status		= $null
}
	
	$_nats_url_endpoint = "http://" + $_io_nats_url + "/healthz"
	try {
		$_nats_resp_obj = Invoke-RestMethod -Method 'GET' -uri $_nats_url_endpoint -TimeoutSec 5
		if ($_nats_resp_obj) {	
			$_io_nats_response_obj.Status = $_nats_resp_obj.status.toString()
		}
		$_nats_url_endpoint = "http://" + $_io_nats_url + "/varz"
		$_nats_resp_obj = Invoke-RestMethod -Method 'GET' -uri $_nats_url_endpoint -TimeoutSec 5
		if ($_nats_resp_obj) {
			$_io_nats_response_obj.ServerName = $_nats_resp_obj.server_name.toString()
		}
		else
		{
			$_io_nats_response_obj.ServerName = "Inactive"
		}
	}
	catch {
		$_alert_text = "Nats Server" + " status: Stopped, Host:" + $_io_nats_url
		fGenAlertNotifications $_alert_text
		$_io_nats_response_obj.ServerName = "Inactive"
	}
	return $_io_nats_response_obj
}

function fGetNatsServerActiveConnections ([string]$_io_nats_url) {
[array]$_controller_obj_arr = $null
[array]$_cache_obj_arr = $null
[array]$_farmer_obj_arr = $null
[array]$_plotter_obj_arr = $null
#
[array]$_io_nats_connections_obj_arr = $null
$_io_nats_connections_obj = [PSCustomObject]@{
	ServerName	= $script:_nats_server_name
	Controller	= $null
	Cache		= $null
	Farmer		= $null
	Plotter		= $null
}
#
##
	$_nats_url_endpoint = "http://" + $_io_nats_url + "/connz?subs=1"
	try {
		$_nats_resp_obj = Invoke-RestMethod -Method 'GET' -uri $_nats_url_endpoint -TimeoutSec 5
		if ($_nats_resp_obj) {
			$_nats_connection_count = $_nats_resp_obj.connections.Count
			$_nats_connections_arr = $_nats_resp_obj.connections
			#Write-Host "_nats_connections_arr.Count = " $_nats_connections_arr.Count
			for ($_nats_connections_arr_pos = 0; $_nats_connections_arr_pos -lt $_nats_connections_arr.Count; $_nats_connections_arr_pos++)
			{
				$_nats_connection_item = $_nats_connections_arr[$_nats_connections_arr_pos]
				$_nats_connection_item_details_obj = [PSCustomObject]@{
					ServerName	= $script:_nats_server_name
					CID			= $_nats_connection_item.cid
					IP		 	= $_nats_connection_item.ip
					Port		= $_nats_connection_item.port
					StartTime	= $_nats_connection_item.start
					LastSeen	= $_nats_connection_item.last_activity
					Uptime		= $_nats_connection_item.uptime
					#10/18/2024 - start change
					Subscriptions = $_nats_connection_item.subscriptions_list
					#10/18/2024 - end change
				}
				[array]$_nats_connection_item_subs_arr = $_nats_connection_item.subscriptions_list

				for ($_nats_connection_item_subs_arr_pos = 0; $_nats_connection_item_subs_arr_pos -lt $_nats_connection_item_subs_arr.Count; $_nats_connection_item_subs_arr_pos++)
				{
					if ($_nats_connection_item_subs_arr[$_nats_connection_item_subs_arr_pos].toLower().IndexOf("subspace.controller.piece") -ge 0)
					{
						$_controller_obj_arr += $_nats_connection_item_details_obj
						break
					}
					#elseif ($_nats_connection_item_subs_arr.toLower().IndexOf("subspace.controller.default.cache-identify") -ge 0)
					elseif ($_nats_connection_item_subs_arr[$_nats_connection_item_subs_arr_pos].toLower().IndexOf("cache-identify") -ge 0)
					{
						$_cache_obj_arr += $_nats_connection_item_details_obj
						break
					}
					elseif ($_nats_connection_item_subs_arr[$_nats_connection_item_subs_arr_pos].toLower().IndexOf("subspace.controller.farmer-identify") -ge 0 `
							-or $_nats_connection_item_subs_arr[$_nats_connection_item_subs_arr_pos].toLower().IndexOf("farm.read-piece") -ge 0 `
							-or $_nats_connection_item_subs_arr[$_nats_connection_item_subs_arr_pos].toLower().IndexOf("farm.plotted-sectors") -ge 0)
					{
						$_farmer_obj_arr += $_nats_connection_item_details_obj
						break
					}
					elseif ($_nats_connection_item_subs_arr[$_nats_connection_item_subs_arr_pos].toLower().IndexOf("subspace.plotter") -ge 0)
					{
						$_plotter_obj_arr += $_nats_connection_item_details_obj
						break
					}
				}
			}
		}
		#
		$_io_nats_connections_obj.Controller = $_controller_obj_arr
		$_io_nats_connections_obj.Cache = $_cache_obj_arr
		$_io_nats_connections_obj.Farmer = $_farmer_obj_arr
		$_io_nats_connections_obj.Plotter = $_plotter_obj_arr
		$_io_nats_connections_obj_arr += $_io_nats_connections_obj
	}
	catch {}
	return $_io_nats_connections_obj_arr
}

function fSanitizeConnections ([array]$_io_arr) {
	[array]$_sanitized_arr = $null
	#
	$_sorted_arr = $_io_arr
	if ($_io_arr.Count -gt 1)
	{
		$_sorted_arr = $_io_arr | Sort-Object @{Expression={$_.IP}; descending=$false}, @{Expression={$_.Port}; descending=$true}
	}
	for ($_i = 0; $_i -lt $_sorted_arr.Count; $_i++)
	{
		if ($_i -eq 0)
		{
			$_sanitized_arr += $_sorted_arr[$_i]
		}
		elseif ($_sorted_arr[$_i].IP -ne $_sorted_arr[$_i-1].IP)
		{
			$_sanitized_arr += $_sorted_arr[$_i]
		}
	}	
	#
	return $_sanitized_arr
}

function fGetNatsServerClosedConnections ([string]$_io_nats_url) {
[array]$_io_nats_connections_obj_arr = $null
[object]$_io_nats_connections_obj = $null

	$_nats_url_endpoint = "http://" + $_io_nats_url + "/connz?state=closed"
	try {
		$_nats_resp_obj = Invoke-RestMethod -Method 'GET' -uri $_nats_url_endpoint -TimeoutSec 5
		if ($_nats_resp_obj) {
			$_nats_connection_count = $_nats_resp_obj.connections.Count
			$_nats_connections_arr = $_nats_resp_obj.connections
			#Write-Host "_nats_connections_arr.Count = " $_nats_connections_arr.Count
			for ($_nats_connections_arr_pos = 0; $_nats_connections_arr_pos -lt $_nats_connections_arr.Count; $_nats_connections_arr_pos++)
			{
				$_nats_connection_item = $_nats_connections_arr[$_nats_connections_arr_pos]
				$_nats_connection_item_details_obj = [PSCustomObject]@{
					CID			= $_nats_connection_item.cid
					IP		 	= $_nats_connection_item.ip
					Port		= $_nats_connection_item.port
					StartTime	= $_nats_connection_item.start
					LastSeen	= $_nats_connection_item.last_activity
					StopTime	= $_nats_connection_item.stop
					Reason		= $_nats_connection_item.reason
					Uptime		= $_nats_connection_item.uptime
				}
				$_io_nats_connections_obj = $_nats_connection_item_details_obj
				$_io_nats_connections_obj_arr += $_io_nats_connections_obj
			}
		}
	}
	catch {}
	return $_io_nats_connections_obj_arr
}

function fPreserveNatsConnectionsDetails ([string]$_io_nats_url) {
[array]$_nats_active_connection_obj_arr = $null
[array]$_nats_closed_connection_obj_arr = $null
#
[array]$_tmp_conn_obj_arr = $null	
#
	$_nats_server_response = fPingNatsServer $_io_nats_url
	$script:_nats_server_health_status = $_nats_server_response.Status
	$script:_nats_server_name = $_nats_server_response.ServerName
	if ($script:_nats_server_health_status) {
		$_nats_active_connection_obj_arr = fGetNatsServerActiveConnections $_io_nats_url
		for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
		{
			$_tmp_conn_obj_arr = $null
			#$script:_ss_controller_obj_arr += $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos].Controller
			$_nats_controller_obj_item_arr = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos].Controller
			for ($_nats_controller_obj_item_arr_pos = 0; $_nats_controller_obj_item_arr_pos -lt $_nats_controller_obj_item_arr.Count; $_nats_controller_obj_item_arr_pos++)
			{
				$_nats_controller_obj_item = $_nats_controller_obj_item_arr[$_nats_controller_obj_item_arr_pos]
				[boolean]$_b_new_cluster_component = $true
				for ($_ss_controller_obj_arr_pos = 0; $_ss_controller_obj_arr_pos -lt $script:_ss_controller_obj_arr.Count; $_ss_controller_obj_arr_pos++)
				{
					#if ($script:_ss_controller_obj_arr.IP -eq $_nats_controller_obj_item.IP)
					if ($script:_ss_controller_obj_arr.IP -eq $_nats_controller_obj_item.IP -and $script:_ss_controller_obj_arr.Port -eq $_nats_controller_obj_item.Port)
					{
						$_b_new_cluster_component = $false
						break
					}
				}
				if ($_b_new_cluster_component)
				{
					#$script:_ss_controller_obj_arr += $_nats_controller_obj_item
					$_tmp_conn_obj_arr += $_nats_controller_obj_item
				}
				else { $_tmp_conn_obj_arr = $script:_ss_controller_obj_arr }
			}
			$script:_ss_controller_obj_arr = fSanitizeConnections $_tmp_conn_obj_arr
			#
			$_tmp_conn_obj_arr = $null
			$_nats_controller_obj_item_arr = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos].Cache
			for ($_nats_controller_obj_item_arr_pos = 0; $_nats_controller_obj_item_arr_pos -lt $_nats_controller_obj_item_arr.Count; $_nats_controller_obj_item_arr_pos++)
			{
				$_nats_controller_obj_item = $_nats_controller_obj_item_arr[$_nats_controller_obj_item_arr_pos]
				[boolean]$_b_new_cluster_component = $true
				for ($_ss_cache_obj_arr_pos = 0; $_ss_cache_obj_arr_pos -lt $script:_ss_cache_obj_arr.Count; $_ss_cache_obj_arr_pos++)
				{
					#if ($script:_ss_cache_obj_arr.IP -eq $_nats_controller_obj_item.IP)
					if ($script:_ss_cache_obj_arr.IP -eq $_nats_controller_obj_item.IP -and $script:_ss_cache_obj_arr.Port -eq $_nats_controller_obj_item.Port)
					{
						$_b_new_cluster_component = $false
						break
					}
				}
				if ($_b_new_cluster_component)
				{
					#$script:_ss_cache_obj_arr += $_nats_controller_obj_item
					$_tmp_conn_obj_arr += $_nats_controller_obj_item
				}
				else { $_tmp_conn_obj_arr = $script:_ss_cache_obj_arr }
			}
			$script:_ss_cache_obj_arr = fSanitizeConnections $_tmp_conn_obj_arr
			#
			$_tmp_conn_obj_arr = $null
			$_nats_controller_obj_item_arr = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos].Farmer
			for ($_nats_controller_obj_item_arr_pos = 0; $_nats_controller_obj_item_arr_pos -lt $_nats_controller_obj_item_arr.Count; $_nats_controller_obj_item_arr_pos++)
			{
				$_nats_controller_obj_item = $_nats_controller_obj_item_arr[$_nats_controller_obj_item_arr_pos]
				[boolean]$_b_new_cluster_component = $true
				for ($_ss_farmer_obj_arr_pos = 0; $_ss_farmer_obj_arr_pos -lt $script:_ss_farmer_obj_arr.Count; $_ss_farmer_obj_arr_pos++)
				{
					#if ($script:_ss_farmer_obj_arr.IP -eq $_nats_controller_obj_item.IP)
					if ($script:_ss_farmer_obj_arr.IP -eq $_nats_controller_obj_item.IP -and $script:_ss_farmer_obj_arr.Port -eq $_nats_controller_obj_item.Port)
					{
						$_b_new_cluster_component = $false
						break
					}
				}
				if ($_b_new_cluster_component)
				{
					#$script:_ss_farmer_obj_arr += $_nats_controller_obj_item
					$_tmp_conn_obj_arr += $_nats_controller_obj_item
				}
				else { $_tmp_conn_obj_arr = $script:_ss_farmer_obj_arr }
			}
			$script:_ss_farmer_obj_arr = fSanitizeConnections $_tmp_conn_obj_arr
			#
			$_tmp_conn_obj_arr = $null
			$_nats_controller_obj_item_arr = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos].Plotter
			for ($_nats_controller_obj_item_arr_pos = 0; $_nats_controller_obj_item_arr_pos -lt $_nats_controller_obj_item_arr.Count; $_nats_controller_obj_item_arr_pos++)
			{
				$_nats_controller_obj_item = $_nats_controller_obj_item_arr[$_nats_controller_obj_item_arr_pos]
				[boolean]$_b_new_cluster_component = $true
				for ($_ss_plotter_obj_arr_pos = 0; $_ss_plotter_obj_arr_pos -lt $script:_ss_plotter_obj_arr.Count; $_ss_plotter_obj_arr_pos++)
				{
					#if ($script:_ss_plotter_obj_arr.IP -eq $_nats_controller_obj_item.IP)
					if ($script:_ss_plotter_obj_arr.IP -eq $_nats_controller_obj_item.IP -and $script:_ss_plotter_obj_arr.Port -eq $_nats_controller_obj_item.Port)
					{
						$_b_new_cluster_component = $false
						break
					}
				}
				if ($_b_new_cluster_component)
				{
					#$script:_ss_plotter_obj_arr += $_nats_controller_obj_item
					$_tmp_conn_obj_arr += $_nats_controller_obj_item
				}
				else { $_tmp_conn_obj_arr = $script:_ss_plotter_obj_arr }
			}
			$script:_ss_plotter_obj_arr = fSanitizeConnections $_tmp_conn_obj_arr
		}
	}
	#
	#
	return $_nats_active_connection_obj_arr
}

function fWriteNatsServerInfoToConsole ([string]$_io_nats_url, [array]$_io_process_arr) {
[array]$_nats_active_connection_obj_arr = $null
[object]$_upper_line_separator_nats_server_CursorPosition = $null
[object]$_header_nats_server_CursorPosition = $null
[object]$_bottom_line_separator_nats_server_CursorPosition = $null
[object]$_cluster_data_begin_row_pos = $null
$_new_rows_for_console = 0
[boolean]$_b_cluster_alert_triggered = $false
$_cluster_header_column_num = 5
$_cluster_header_column_size = 17
$_b_cluster_information_printed = $true
#
	if ($script:_new_rows_written_to_console -eq 0)
	{
		$_b_cluster_information_printed = $false
	}
	else
	{
		$_cluster_data_begin_row_pos = $script:_cluster_data_prev_row_pos_hold
	}
	#
	$_nats_active_connection_obj_arr = fPreserveNatsConnectionsDetails $_io_nats_url
	$script:_custom_alert_text = "Nats Server Name: $script:_nats_server_name"
	##
	$_header_filler_length = 0
	if (!($_b_cluster_information_printed))
	{
		#$_console_msg = "|" 
		#Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = " " 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_upper_line_separator_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		Write-Host "" -ForegroundColor $_line_spacer_color
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_header_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		Write-Host "" -ForegroundColor $_line_spacer_color
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_bottom_line_separator_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		Write-Host "" -ForegroundColor $_line_spacer_color
		#
		$_nats_server_header_title = "   Server Name   "
		$_header_title = $_nats_server_header_title
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_header_filler_length += $_header_title.Length
		$_console_msg = $_header_title
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_header_nats_server_header_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		Write-Host "" -ForegroundColor $_line_spacer_color
		#
		$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
		$_console_msg = "|" + $_label_spacer
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header line separator cursor position for repositioning later
		$_line_separator_server_CursorPosition = $host.UI.RawUI.CursorPosition
		$_cluster_data_begin_row_pos = $_line_separator_server_CursorPosition
		#
	}
	#
	# set cursor position to first header data location
	[Console]::SetCursorPosition(0, ($_cluster_data_begin_row_pos.Y))
	Write-Host "" -ForegroundColor $_line_spacer_color
	#
	$_console_msg = "|" 
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_console_msg = $script:_nats_server_name + ":"
	$_console_msg_color = ""
	if ($script:_nats_server_name -eq $null -or $script:_nats_server_name.Length -eq 0 -or $script:_nats_server_name.toLower() -eq "inactive")
	{
		$_console_msg_color = $_html_red
	}
	else {
		$_console_msg_color = $_line_spacer_color
	}
	Write-Host $_console_msg -nonewline -ForegroundColor $_console_msg_color
	#
	$_console_msg = ""
	$_console_msg_color = ""
	$_process_state_disp = $_label_line_separator_upper
	$_console_msg = $_process_state_disp
	if ($script:_nats_server_name -eq $null -or $script:_nats_server_name.Length -eq 0 -or $script:_nats_server_name.toLower() -eq "inactive")
	{
		$_console_msg_color = $_html_red
	}
	else {
		$_console_msg_color = $_html_green
	}
	Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
	#
	$_spacer_length = $_cluster_header_column_size - $script:_nats_server_name.Length - 2    ##column separators
	$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
	Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
	# get the current header line separator cursor position for repositioning later
	$_data_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	##
	if (!($_b_cluster_information_printed))
	{
		# set cursor position to last header location
		[Console]::SetCursorPosition($_header_nats_server_header_CursorPosition.X, $_header_nats_server_header_CursorPosition.Y)
		#
		$_controller_header_title = "   Controller    "
		$_header_title = $_controller_header_title
		$_header_filler_length += $_header_title.Length
		$_console_msg = $_header_title
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_header_controller_CursorPosition = $host.UI.RawUI.CursorPosition
		[object]$_data_controller_CursorPosition = $null
		#
		# set cursor position to last header location
		[Console]::SetCursorPosition($_line_separator_server_CursorPosition.X, $_line_separator_server_CursorPosition.Y)
		$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
		$_console_msg = "|" + $_label_spacer
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header line separator cursor position for repositioning later
		$_line_separator_controller_CursorPosition = $host.UI.RawUI.CursorPosition
		$script:_cluster_data_prev_row_pos_hold = $_line_separator_controller_CursorPosition
		$_cluster_data_begin_row_pos = $script:_cluster_data_prev_row_pos_hold
	}
	#
	#
	$_ss_controller_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	[boolean]$_no_connection_exists = $true
	$_item_sequence_num = -1
	for ($_ss_controller_obj_arr_pos = 0; $_ss_controller_obj_arr_pos -lt $script:_ss_controller_obj_arr.Count; $_ss_controller_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_controller_obj_arr_item = $script:_ss_controller_obj_arr[$_ss_controller_obj_arr_pos]
		#
		#
		if ($_ss_controller_obj_arr_item.ServerName -eq $script:_nats_server_name)
		{
			$_no_connection_exists = $false
			$_item_sequence_num += 1
			if ($_new_rows_for_console -lt ($_item_sequence_num + 1)) { $_new_rows_for_console = $_item_sequence_num + 1 }
		#
		#
			for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
			{
				$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
				if ($_ss_controller_obj_arr_item.ServerName -eq $_nats_active_connection_obj_arr_item.ServerName)
				{
					for ($_connection_arr_pos = 0; $_connection_arr_pos -lt $_nats_active_connection_obj_arr_item.Controller.Count; $_connection_arr_pos++)
					{
						if ($_ss_controller_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Controller[$_connection_arr_pos].IP)
						#if ($_ss_controller_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Controller[$_connection_arr_pos].IP -and $_ss_controller_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Controller[$_connection_arr_pos].Port)
						{
							$_b_nats_connection_type_match_found = $true
							$_ss_controller_disp_name_length = $_ss_controller_obj_arr_item.IP.Length
							break
						}
					}
				}
				if ($_b_nats_connection_type_match_found) { break }
			}
			if ($_ss_controller_disp_name_length -eq 0)
			{
				$_ss_controller_disp_name_length = $_ss_controller_obj_arr_item.IP.Length
			}
			#
			[Console]::SetCursorPosition($_data_nats_server_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1+$_item_sequence_num))

			#
			$_console_msg = "|" 
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			$_console_msg = $_ss_controller_obj_arr_item.IP.toString() + ":"
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			#
			$_console_msg = ""
			$_console_msg_color = ""
			$_process_state_disp = $_label_line_separator_upper
			$_console_msg = $_process_state_disp
			if ($_b_nats_connection_type_match_found)
			{
				$_console_msg_color = $_html_green
			}
			else {
				$_console_msg_color = $_html_red
				if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
				$script:_custom_alert_text += "SS Controller" + " status: Stopped, Host:" + $_ss_controller_obj_arr_item.IP
				$_b_cluster_alert_triggered = $true
			}
			Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
			#
			$_spacer_length = $_cluster_header_column_size - $_ss_controller_disp_name_length - 2	##column separators
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
			# get the current header data cursor position for repositioning later
			$_data_controller_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		#
		}
		#
		#
	}
	#if ($script:_ss_controller_obj_arr.Count -le 0)
	if ($_no_connection_exists -or $script:_ss_controller_obj_arr.Count -le 0)
	{
		Write-Host "" -ForegroundColor $_line_spacer_color
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition($_data_nats_server_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1))
		#
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = "Inactive" + ":"
		$_ss_controller_disp_name_length = ("Inactive").Length
		Write-Host $_console_msg -nonewline -ForegroundColor $_html_red
		#
		$_console_msg = ""
		$_console_msg_color = ""
		$_process_state_disp = $_label_line_separator_upper
		$_console_msg = $_process_state_disp
		if ($_b_nats_connection_type_match_found)
		{
			$_console_msg_color = $_html_green
		}
		else {
			$_console_msg_color = $_html_red
			if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
			$script:_custom_alert_text += "SS Controller" + " status: Inactive, Host:" + "None set-up"
			$_b_cluster_alert_triggered = $true
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_cluster_header_column_size - $_ss_controller_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		$_data_controller_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	##
	if (!($_b_cluster_information_printed))
	{
		# set cursor position to last header location
		[Console]::SetCursorPosition($_header_controller_CursorPosition.X, $_header_controller_CursorPosition.Y)
		$_cache_header_title = "      Cache      "
		$_header_title = $_cache_header_title
		$_console_msg = $_header_title
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_header_filler_length += $_header_title.Length
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_header_cache_CursorPosition = $host.UI.RawUI.CursorPosition
		[object]$_data_cache_CursorPosition = $null
		#
		# set cursor position to last header line separator location
		[Console]::SetCursorPosition($_line_separator_controller_CursorPosition.X, $_line_separator_controller_CursorPosition.Y)
		$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
		$_console_msg = "|" + $_label_spacer
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header line separator cursor position for repositioning later
		$_line_separator_cache_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	}
	#
	$_ss_cache_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	[boolean]$_no_connection_exists = $true
	$_item_sequence_num = -1
	for ($_ss_cache_obj_arr_pos = 0; $_ss_cache_obj_arr_pos -lt $script:_ss_cache_obj_arr.Count; $_ss_cache_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_cache_obj_arr_item = $script:_ss_cache_obj_arr[$_ss_cache_obj_arr_pos]
		#
		if ($_ss_cache_obj_arr_item.ServerName -eq $script:_nats_server_name)
		{
			$_no_connection_exists = $false
			$_item_sequence_num += 1
			if ($_new_rows_for_console -lt ($_item_sequence_num + 1)) { $_new_rows_for_console = $_item_sequence_num + 1 }
		#
			for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
			{
				$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
				if ($_ss_cache_obj_arr_item.ServerName -eq $_nats_active_connection_obj_arr_item.ServerName)
				{
					for ($_connection_arr_pos = 0; $_connection_arr_pos -lt $_nats_active_connection_obj_arr_item.Cache.Count; $_connection_arr_pos++)
					{
						if ($_ss_cache_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Cache[$_connection_arr_pos].IP)
						#if ($_ss_cache_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Cache[$_connection_arr_pos].IP -and $_ss_cache_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Cache[$_connection_arr_pos].Port)
						{
							$_b_nats_connection_type_match_found = $true
							$_ss_cache_disp_name_length = $_ss_cache_obj_arr_item.IP.Length
							break
						}
					}
				}
				if ($_b_nats_connection_type_match_found) { break }
			}
			if ($_ss_cache_disp_name_length -eq 0)
			{
				$_ss_cache_disp_name_length = $_ss_cache_obj_arr_item.IP.Length
			}
			#
			# set cursor position to first header data location
			[Console]::SetCursorPosition($_data_controller_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1+$_item_sequence_num))
			#
			$_console_msg = "|" 
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			$_console_msg = $_ss_cache_obj_arr_item.IP.toString() + ":"
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			#
			$_console_msg = ""
			$_console_msg_color = ""
			$_process_state_disp = $_label_line_separator_upper
			$_console_msg = $_process_state_disp
			if ($_b_nats_connection_type_match_found)
			{
				$_console_msg_color = $_html_green
			}
			else {
				$_console_msg_color = $_html_red
				if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
				$script:_custom_alert_text += "SS Cache" + " status: Stopped, Host:" + $_ss_cache_obj_arr_item.IP
				$_b_cluster_alert_triggered = $true
			}
			Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
			#
			$_spacer_length = $_cluster_header_column_size - $_ss_cache_disp_name_length - 2	##column separators
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
			# get the current header data cursor position for repositioning later
			$_data_cache_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		}
		#			
	}
	if ($_no_connection_exists -or $script:_ss_cache_obj_arr.Count -le 0)
	{
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition($_data_controller_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1))
		#
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = "Inactive" + ":"
		$_ss_cache_disp_name_length = ("Inactive").Length
		Write-Host $_console_msg -nonewline -ForegroundColor $_html_red
		#
		$_console_msg = ""
		$_console_msg_color = ""
		$_process_state_disp = $_label_line_separator_upper
		$_console_msg = $_process_state_disp
		if ($_b_nats_connection_type_match_found)
		{
			$_console_msg_color = $_html_green
		}
		else {
			$_console_msg_color = $_html_red
			if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
			$script:_custom_alert_text += "SS Cache" + " status: Inactive, Host:" + "None set-up"
			$_b_cluster_alert_triggered = $true
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_cluster_header_column_size - $_ss_cache_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		$_data_cache_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	##
	if (!($_b_cluster_information_printed))
	{
		# set cursor position to last header location
		[Console]::SetCursorPosition($_header_cache_CursorPosition.X, $_header_cache_CursorPosition.Y)
		$_farmer_header_title = "      Farmer     "
		$_header_title = $_farmer_header_title
		$_console_msg = $_header_title
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_header_filler_length += $_header_title.Length
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_header_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
		[object]$_data_farmer_CursorPosition = $null
		#
		# set cursor position to last header line separator location
		[Console]::SetCursorPosition($_line_separator_cache_CursorPosition.X, $_line_separator_cache_CursorPosition.Y)
		$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
		$_console_msg = "|" + $_label_spacer
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header line separator cursor position for repositioning later
		$_line_separator_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	#
	#
	$_ss_farmer_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	[boolean]$_no_connection_exists = $true
	$_item_sequence_num = -1
	for ($_ss_farmer_obj_arr_pos = 0; $_ss_farmer_obj_arr_pos -lt $script:_ss_farmer_obj_arr.Count; $_ss_farmer_obj_arr_pos++)
	{
		$_ss_farmer_disp_name_length = 0
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_farmer_obj_arr_item = $script:_ss_farmer_obj_arr[$_ss_farmer_obj_arr_pos]
		#
		#
		if ($_ss_farmer_obj_arr_item.ServerName -eq $script:_nats_server_name)
		{
			$_no_connection_exists = $false
			$_item_sequence_num += 1
			if ($_new_rows_for_console -lt ($_item_sequence_num + 1)) { $_new_rows_for_console = $_item_sequence_num + 1 }
		#
		#
			for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
			{
				$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
				if ($_ss_farmer_obj_arr_item.ServerName -eq $_nats_active_connection_obj_arr_item.ServerName)
				{
					for ($_connection_arr_pos = 0; $_connection_arr_pos -lt $_nats_active_connection_obj_arr_item.Farmer.Count; $_connection_arr_pos++)
					{
						if ($_ss_farmer_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Farmer[$_connection_arr_pos].IP)
						#if ($_ss_farmer_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Farmer[$_connection_arr_pos].IP -and $_ss_farmer_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Farmer[$_connection_arr_pos].Port)
						{
							$_b_nats_connection_type_match_found = $true
							$_ss_farmer_disp_name_length = $_ss_farmer_obj_arr_item.IP.Length
							break
						}
					}
				}
				if ($_b_nats_connection_type_match_found) { break }
			}
			if ($_ss_farmer_disp_name_length -eq 0)
			{
				$_ss_farmer_disp_name_length = $_ss_farmer_obj_arr_item.IP.Length
			}
			#
			# set cursor position to first header data location
			[Console]::SetCursorPosition($_data_cache_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1+$_item_sequence_num))
			#
			$_console_msg = "|" 
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			#
			# match nats farmer hostname from config for console display
			$_nats_farmer_hostname = $_ss_farmer_obj_arr_item.IP.toString()
			$_hostname = ""
			for ($arrPos = 0; $arrPos -lt $_io_process_arr.Count; $arrPos++)
			{
				$_farmer_metrics_raw = ""
				$_node_metrics_raw = ""
				[array]$_process_state_arr = $null
				$_b_process_running_ok = $false
				if ($_io_process_arr[$arrPos].toString().Trim(' ') -ne "" -and $_io_process_arr[$arrPos].toString().IndexOf("#") -lt 0) {
					$_config = $_io_process_arr[$arrPos].toString().split(":").Trim(" ")
					$_process_type = $_config[0].toString()
					$_b_disk_plot_id_match_found = $false
					if ($_process_type.toLower() -eq "farmer") { 
						$_host_ip = $_config[1].toString()
						$_host_port = $_config[2].toString()
						$_host_friendly_name = ""
						if ($_config.Count -gt 3) {
							$_host_friendly_name = $_config[3].toString()
						}
						$_host_url = $_host_ip + ":" + $_host_port
						
						$_hostname = $_host_ip
						if ($_host_friendly_name -and $_host_friendly_name.length -gt 0)
						{	
							$_hostname = $_host_friendly_name
						}
						#10/18/2024 - Start change
						#if ($_ss_farmer_obj_arr_item.IP.toString() -eq $_host_ip)
						#{
						#	$_nats_farmer_hostname = $_hostname
						#	$_ss_farmer_disp_name_length = $_nats_farmer_hostname.Length
						#	break
						#}
						#
						####11/12 change start
						#$_tmp_process_state_arr = fGetProcessState $_process_type $_host_url $_hostname $script:_url_discord
						#$_tmp_farmer_metrics_raw = $_tmp_process_state_arr[0]
						#$_tmp_farmer_metrics_formatted_arr = fParseMetricsToObj $_tmp_farmer_metrics_raw
						#$_tmp_disk_metrics_arr = fGetDiskSectorPerformance $_tmp_farmer_metrics_formatted_arr
						[array]$_tmp_disk_metrics_arr = $null
						foreach ($_farmer_disk_metrics_arr_obj in $script:_farmer_disk_metrics_arr)
						{
							if ($_farmer_disk_metrics_arr_obj)
							{
								if ($_farmer_disk_metrics_arr_obj.Id -eq $_host_url)
								{
									$_tmp_disk_metrics_arr = $_farmer_disk_metrics_arr_obj.MetricsArr
									break
								}
							}
							else {break}
						}
						####11/12 change end
						#
						$_tmp_disk_UUId_arr = $_tmp_disk_metrics_arr[0].Id


						$_nats_farmer_subscriptions_arr = $_ss_farmer_obj_arr_item.Subscriptions
						#$_b_disk_plot_id_match_found = $false
						foreach ($_tmp_disk_UUId_obj in $_tmp_disk_UUId_arr)
						{
							if ($_tmp_disk_UUId_obj) {
								for ($_nats_farmer_subscriptions_arr_pos = 0; $_nats_farmer_subscriptions_arr_pos -lt $_nats_farmer_subscriptions_arr.Count; $_nats_farmer_subscriptions_arr_pos++)
								{
									if ($_nats_farmer_subscriptions_arr[$_nats_farmer_subscriptions_arr_pos].toLower().IndexOf($_tmp_disk_UUId_obj.Id.toLower()) -ge 0)
									{
										$_nats_farmer_hostname = $_hostname
										$_ss_farmer_disp_name_length = $_nats_farmer_hostname.Length
										$_b_disk_plot_id_match_found = $true
										break
									}
								}
							}
							if ($_b_disk_plot_id_match_found) { break }
						}
						if ($_b_disk_plot_id_match_found) { break }
						#10/18/2024 - End change
					}
				}
			}
			$_console_msg = $_nats_farmer_hostname + ":"
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			#
			$_console_msg = ""
			$_console_msg_color = ""
			$_process_state_disp = $_label_line_separator_upper
			$_console_msg = $_process_state_disp
			if ($_b_nats_connection_type_match_found)
			{
				$_console_msg_color = $_html_green
			}
			else {
				$_console_msg_color = $_html_red
				if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
				$script:_custom_alert_text += "SS Farmer" + " status: Stopped, Host:" + $_nats_farmer_hostname
				$_b_cluster_alert_triggered = $true
			}
			Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
			#
			$_spacer_length = $_cluster_header_column_size - $_ss_farmer_disp_name_length - 2	##column separators
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
			# get the current header data cursor position for repositioning later
			$_data_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		}
		#
	}
	if ($_no_connection_exists -or $script:_ss_farmer_obj_arr.Count -le 0)
	{
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition($_data_cache_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1))
		#
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = "Inactive" + ":"
		$_ss_farmer_disp_name_length = ("Inactive").Length
		Write-Host $_console_msg -nonewline -ForegroundColor $_html_red
		#
		$_console_msg = ""
		$_console_msg_color = ""
		$_process_state_disp = $_label_line_separator_upper
		$_console_msg = $_process_state_disp
		if ($_b_nats_connection_type_match_found)
		{
			$_console_msg_color = $_html_green
		}
		else {
			$_console_msg_color = $_html_red
			if ($_nats_farmer_hostname.Length -le 0) { $_nats_farmer_hostname = "None set-up" }
			if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
			$script:_custom_alert_text += "SS Farmer" + " status: Inactive, Host:" + $_nats_farmer_hostname
			$_b_cluster_alert_triggered = $true
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_cluster_header_column_size - $_ss_farmer_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		$_data_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	##
	if (!($_b_cluster_information_printed))
	{
		# set cursor position to last header location
		[Console]::SetCursorPosition($_header_farmer_CursorPosition.X, $_header_farmer_CursorPosition.Y)
		$_plotter_header_title = "     Plotter     "
		$_header_title = $_plotter_header_title
		$_console_msg = $_header_title
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_header_filler_length += $_header_title.Length
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header cursor position for repositioning later
		$_header_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
		[object]$_data_plotter_CursorPosition = $null
		#
		# set cursor position to last header line separator location
		[Console]::SetCursorPosition($_line_separator_farmer_CursorPosition.X, $_line_separator_farmer_CursorPosition.Y)
		$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
		$_console_msg = "|" + $_label_spacer + "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# get the current header line separator cursor position for repositioning later
		$_line_separator_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	#
	$_ss_plotter_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	[boolean]$_no_connection_exists = $true
	$_item_sequence_num = -1
	for ($_ss_plotter_obj_arr_pos = 0; $_ss_plotter_obj_arr_pos -lt $script:_ss_plotter_obj_arr.Count; $_ss_plotter_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_plotter_obj_arr_item = $script:_ss_plotter_obj_arr[$_ss_plotter_obj_arr_pos]
		#
		if ($_ss_plotter_obj_arr_item.ServerName -eq $script:_nats_server_name)
		{
			$_no_connection_exists = $false
			$_item_sequence_num += 1
			if ($_new_rows_for_console -lt ($_item_sequence_num + 1)) { $_new_rows_for_console = $_item_sequence_num + 1 }
		#
			for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
			{
				$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
				if ($_ss_plotter_obj_arr_item.ServerName -eq $_nats_active_connection_obj_arr_item.ServerName)
				{
					for ($_connection_arr_pos = 0; $_connection_arr_pos -lt $_nats_active_connection_obj_arr_item.Plotter.Count; $_connection_arr_pos++)
					{
						if ($_ss_plotter_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Plotter[$_connection_arr_pos].IP)
						#if ($_ss_plotter_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Plotter[$_connection_arr_pos].IP -and $_ss_plotter_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Plotter[$_connection_arr_pos].Port)
						{
							$_b_nats_connection_type_match_found = $true
							$_ss_plotter_disp_name_length = $_ss_plotter_obj_arr_item.IP.Length
							break
						}
					}
				}
				if ($_b_nats_connection_type_match_found) { break }
			}
			if ($_ss_plotter_disp_name_length -eq 0)
			{
				$_ss_plotter_disp_name_length = $_ss_plotter_obj_arr_item.IP.Length
			}
			#
			# set cursor position to first header data location
			[Console]::SetCursorPosition($_data_farmer_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1+$_item_sequence_num))
			#
			$_console_msg = "|" 
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			$_console_msg = $_ss_plotter_obj_arr_item.IP.toString() + ":"
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
			#
			$_console_msg = ""
			$_console_msg_color = ""
			$_process_state_disp = $_label_line_separator_upper
			$_console_msg = $_process_state_disp
			if ($_b_nats_connection_type_match_found)
			{
				$_console_msg_color = $_html_green
			}
			else {
				$_console_msg_color = $_html_red
				if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
				$script:_custom_alert_text += "SS Plotter" + " status: Stopped, Host:" + $_ss_plotter_obj_arr_item.IP
				$_b_cluster_alert_triggered = $true
			}
			Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
			#
			$_spacer_length = $_cluster_header_column_size - $_ss_plotter_disp_name_length - 2	##column separators
			$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
			Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
			# get the current header data cursor position for repositioning later
			$_data_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
			#
			#Finish only if last column
			$_console_msg = "|" 
			Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		#
		}
		#
	}
	#if ($script:_ss_plotter_obj_arr.Count -le 0)
	if ($_no_connection_exists -or $script:_ss_plotter_obj_arr.Count -le 0)
 	{
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition($_data_farmer_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+1))
		#
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = "Inactive" + ":"
		$_ss_plotter_disp_name_length = ("Inactive").Length
		Write-Host $_console_msg -nonewline -ForegroundColor $_html_red
		#
		$_console_msg = ""
		$_console_msg_color = ""
		$_process_state_disp = $_label_line_separator_upper
		$_console_msg = $_process_state_disp
		if ($_b_nats_connection_type_match_found)
		{
			$_console_msg_color = $_html_green
		}
		else {
			$_console_msg_color = $_html_red
			if ($script:_custom_alert_text.Length -gt 0) { $script:_custom_alert_text += " | " }
			$script:_custom_alert_text += "SS Plotter" + " status: Inactive, Host:" + "None set-up"
			$_b_cluster_alert_triggered = $true
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_cluster_header_column_size - $_ss_plotter_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		$_data_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		#Finish only if last column
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	}
	#
	##Write finish line seprator
	if ($_new_rows_for_console -eq 0) { $_new_rows_for_console = 1 }
	$script:_new_rows_written_to_console += $_new_rows_for_console
	#
	# set cursor position to first header data location
	[Console]::SetCursorPosition($_data_plotter_CursorPosition.X, ($_cluster_data_begin_row_pos.Y+$_new_rows_for_console))
	##
	## more than 1 nats server(s) separation line
	Write-Host "" -ForegroundColor $_line_spacer_color
	
	#$_label_spacer = fBuildDynamicSpacer (($_cluster_header_column_size * $_cluster_header_column_num) + $_cluster_header_column_num - 1) $_label_line_separator_upper
	$_label_spacer = fBuildDynamicSpacer $_cluster_header_column_size $_label_line_separator
	$_console_msg = "|" 
	for ($_cluster_header_column_num_pos = 0; $_cluster_header_column_num_pos -lt $_cluster_header_column_num; $_cluster_header_column_num_pos++)
	{
		$_console_msg += $_label_spacer + "|" 
	}
	#$_console_msg = " " 
	#$_label_spacer = fBuildDynamicSpacer ($_cluster_header_column_size * $_cluster_header_column_num + ($_cluster_header_column_num - 1)) $_label_line_separator_upper
	#$_console_msg += $_label_spacer 
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	##
	# get the nats finish line separator cursor position for repositioning later
	$_finish_line_separator_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
#
	#
	for ($_new_rows_for_console_pos = 0; $_new_rows_for_console_pos -lt $_new_rows_for_console; $_new_rows_for_console_pos++)
	{
		try {
		[Console]::SetCursorPosition((($_cluster_header_column_size+1)*0), ($_cluster_data_begin_row_pos.Y+1+$_new_rows_for_console_pos))
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		[Console]::SetCursorPosition((($_cluster_header_column_size+1)*1), ($_cluster_data_begin_row_pos.Y+1+$_new_rows_for_console_pos))
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		[Console]::SetCursorPosition((($_cluster_header_column_size+1)*2), ($_cluster_data_begin_row_pos.Y+1+$_new_rows_for_console_pos))
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		[Console]::SetCursorPosition((($_cluster_header_column_size+1)*3), ($_cluster_data_begin_row_pos.Y+1+$_new_rows_for_console_pos))
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		[Console]::SetCursorPosition((($_cluster_header_column_size+1)*4), ($_cluster_data_begin_row_pos.Y+1+$_new_rows_for_console_pos))
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		[Console]::SetCursorPosition((($_cluster_header_column_size+1)*5), ($_cluster_data_begin_row_pos.Y+1+$_new_rows_for_console_pos))
		$_console_msg = "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		}
		catch {}
	}
	##
	##Write nats server header and wrap-up
	if (!($_b_cluster_information_printed))
	{
		# set cursor position to last cluster header top line separator location
		[Console]::SetCursorPosition($_upper_line_separator_nats_server_CursorPosition.X, $_upper_line_separator_nats_server_CursorPosition.Y)
		#$_label_spacer = fBuildDynamicSpacer ($_header_filler_length + $_cluster_header_column_num - 1) $_label_line_separator_upper
		#$_console_msg = $_label_spacer  + "|"
		$_label_spacer = fBuildDynamicSpacer ($_header_filler_length + $_cluster_header_column_num - 1) $_label_line_separator
		$_console_msg = $_label_spacer
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# set cursor position to last cluster header location
		[Console]::SetCursorPosition($_header_nats_server_CursorPosition.X, $_header_nats_server_CursorPosition.Y)
		$_cluster_header_title = "Cluster:"
		$_label_spacer = fBuildDynamicSpacer (($_header_filler_length + ($_cluster_header_column_num - 1) - $_cluster_header_title.Length - 2)/2) $_spacer
		$_console_msg = $_label_spacer
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		$_console_msg = $_cluster_header_title + " "
		Write-Host $_console_msg -nonewline -ForegroundColor $_farmer_header_color
		#
		$_label_spacer = fBuildDynamicSpacer (($_header_filler_length + ($_cluster_header_column_num - 1) - $_cluster_header_title.Length - 2)/2) $_spacer
		$_console_msg = $_label_spacer + "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
		# set cursor position to last cluster header bottom line separator location
		[Console]::SetCursorPosition($_bottom_line_separator_nats_server_CursorPosition.X, $_bottom_line_separator_nats_server_CursorPosition.Y)
		$_label_spacer = fBuildDynamicSpacer ($_header_filler_length + $_cluster_header_column_num - 1) $_label_line_separator
		$_console_msg = $_label_spacer + "|"
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	}
	# set cursor position to cluster  finish line separator location
	[Console]::SetCursorPosition($_finish_line_separator_nats_server_CursorPosition.X, $_finish_line_separator_nats_server_CursorPosition.Y)
	$script:_cluster_data_prev_row_pos_hold = $_finish_line_separator_nats_server_CursorPosition
	##
	##NOT USED - below lines
	[array]$_nats_closed_connection_obj_arr = $null
	if ($script:_nats_server_health_status) 
	{
		$_nats_closed_connection_obj_arr = fGetNatsServerClosedConnections $_io_nats_url
	}
	for ($_nats_closed_connection_obj_arr_pos = 0; $_nats_closed_connection_obj_arr_pos -lt $_nats_closed_connection_obj_arr.Count; $_nats_closed_connection_obj_arr_pos++)
	{
		$_nats_closed_connection_obj_arr_item = $_nats_closed_connection_obj_arr[$_nats_closed_connection_obj_arr_pos]
		##Not used currently
		#Write-Host "_nats_closed_connection_obj_arr_item = " $_nats_closed_connection_obj_arr_item
	}
	##NOT USED - above lines
	#
	# send alerts
	if ($_b_cluster_alert_triggered)
	{
		fGenAlertNotifications $script:_custom_alert_text
	}
	#
}

