<#  ------------------------------------------------------------------------------------------------
	Script location on Github: https://github.com/irbujam/ss_log_event_monitor
	--------------------------------------------------------------------------------------------- #>

function fGenAlertNotifications ([string]$_io_alert_text) {
	try {
		$_seconds_elapsed = $_alert_stopwatch.Elapsed.TotalSeconds
		#if ($script:_b_first_time -eq $true -or $_seconds_elapsed -ge $_alert_frequency_seconds) {
		if ($_seconds_elapsed -ge $_alert_frequency_seconds) {
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
			$_io_nats_response_obj.ServerName = "No Active Nats Server"
		}
	}
	catch {
		$_alert_text = "Nats Server" + " status: Stopped, Host:" + $_io_nats_url
		fGenAlertNotifications $_alert_text
		$_io_nats_response_obj.ServerName = "No Active Nats Server"
	}
	return $_io_nats_response_obj
}

function fGetNatsServerActiveConnections ([string]$_io_nats_url) {
[array]$_io_nats_connections_obj_arr = $null
$_io_nats_connections_obj = [PSCustomObject]@{
	ServerName	= $null
	Controller	= $null
	Cache		= $null
	Farmer		= $null
	Plotter		= $null
}

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
					CID			= $_nats_connection_item.cid
					IP		 	= $_nats_connection_item.ip
					Port		= $_nats_connection_item.port
					StartTime	= $_nats_connection_item.start
					LastSeen	= $_nats_connection_item.last_activity
					Uptime		= $_nats_connection_item.uptime
				}
				[array]$_nats_connection_item_subs_arr = $_nats_connection_item.subscriptions_list
				if ($_nats_connection_item_subs_arr.toLower().IndexOf("subspace.controller.piece") -ge 0)
				{
					$_io_nats_connections_obj.Controller = $_nats_connection_item_details_obj
				}
				elseif ($_nats_connection_item_subs_arr.toLower().IndexOf("subspace.controller.default.cache-identify") -ge 0)
				{
					$_io_nats_connections_obj.Cache = $_nats_connection_item_details_obj
				}
				elseif ($_nats_connection_item_subs_arr.toLower().IndexOf("subspace.controller.farmer-identify") -ge 0)
				{
					$_io_nats_connections_obj.Farmer = $_nats_connection_item_details_obj
				}
				else
				{
					#if ($_nats_connection_item_subs_arr.toLower().IndexOf("subspace.plotter") -ge 0)
					#{
						##Write-Host "_nats_connection_item_subs_arr.IndexOf('subspace.plotter') = " $_nats_connection_item_subs_arr.toLower().IndexOf("subspace.plotter")
						$_io_nats_connections_obj.Plotter = $_nats_connection_item_details_obj
					#}
				}
			}
			$_io_nats_connections_obj_arr += $_io_nats_connections_obj
		}
	}
	catch {}
	#Write-Host "_io_nats_connections_obj_arr = " $_io_nats_connections_obj_arr
	return $_io_nats_connections_obj_arr
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
	#Write-Host "_io_nats_connections_obj_arr = " $_io_nats_connections_obj_arr
	return $_io_nats_connections_obj_arr
}

function fPreserveNatsConnectionsDetails ([string]$_io_nats_url) {
[array]$_nats_active_connection_obj_arr = $null
[array]$_nats_closed_connection_obj_arr = $null
	
	$_nats_server_response = fPingNatsServer $_io_nats_url
	$script:_nats_server_health_status = $_nats_server_response.Status
	$script:_nats_server_name = $_nats_server_response.ServerName
	if ($script:_nats_server_health_status) {
		$_nats_active_connection_obj_arr = fGetNatsServerActiveConnections $_io_nats_url
	}
	else 
	{
		$script:_ss_controller_obj_arr = $null
		$script:_ss_cache_obj_arr = $null
		$script:_ss_farmer_obj_arr = $null
		$script:_ss_plotter_obj_arr = $null
	}
	#
	for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
	{
			$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
			##
			if ($_nats_active_connection_obj_arr_item.Controller)
			{
				$_ss_controller_obj_item = [PSCustomObject]@{
					IP		 	= $_nats_active_connection_obj_arr_item.Controller.IP
					Port		= $_nats_active_connection_obj_arr_item.Controller.Port
				}
				$_b_new_controller = $true
				for ($_ss_controller_obj_arr_pos = 0; $_ss_controller_obj_arr_pos -lt $script:_ss_controller_obj_arr.Count; $_ss_controller_obj_arr_pos++)
				{
					$_ss_controller_obj_arr_item = $script:_ss_controller_obj_arr[$_ss_controller_obj_arr_pos]
					#if ($_ss_controller_obj_item.IP -eq $_ss_controller_obj_arr_item.IP -and $_ss_controller_obj_item.Port -eq $_ss_controller_obj_arr_item.Port)
					if ($_ss_controller_obj_item.IP -eq $_ss_controller_obj_arr_item.IP)
					{
						$_b_new_controller = $false
						break
					}
				}
				if ($_b_new_controller)
				{
					$script:_ss_controller_obj_arr += $_ss_controller_obj_item
				}
			}
			##
			if ($_nats_active_connection_obj_arr_item.Cache)
			{
				$_ss_cache_obj_item = [PSCustomObject]@{
					IP		 	= $_nats_active_connection_obj_arr_item.Cache.IP
					Port		= $_nats_active_connection_obj_arr_item.Cache.Port
				}
				$_b_new_cache = $true
				for ($_ss_cache_obj_arr_pos = 0; $_ss_cache_obj_arr_pos -lt $script:_ss_cache_obj_arr.Count; $_ss_cache_obj_arr_pos++)
				{
					$_ss_cache_obj_arr_item = $script:_ss_cache_obj_arr[$_ss_cache_obj_arr_pos]
					#if ($_ss_cache_obj_item.IP -eq $_ss_cache_obj_arr_item.IP -and $_ss_cache_obj_item.Port -eq $_ss_cache_obj_arr_item.Port)
					if ($_ss_cache_obj_item.IP -eq $_ss_cache_obj_arr_item.IP)
					{
						$_b_new_cache = $false
						break
					}
				}
				if ($_b_new_cache)
				{
					$script:_ss_cache_obj_arr += $_ss_cache_obj_item
				}
			}
			##
			if ($_nats_active_connection_obj_arr_item.Farmer)
			{
				$_ss_farmer_obj_item = [PSCustomObject]@{
					IP		 	= $_nats_active_connection_obj_arr_item.Farmer.IP
					Port		= $_nats_active_connection_obj_arr_item.Farmer.Port
				}
				$_b_new_farmer = $true
				for ($_ss_farmer_obj_arr_pos = 0; $_ss_farmer_obj_arr_pos -lt $script:_ss_farmer_obj_arr.Count; $_ss_farmer_obj_arr_pos++)
				{
					$_ss_farmer_obj_arr_item = $script:_ss_farmer_obj_arr[$_ss_farmer_obj_arr_pos]
					#if ($_ss_farmer_obj_item.IP -eq $_ss_farmer_obj_arr_item.IP -and $_ss_farmer_obj_item.Port -eq $_ss_farmer_obj_arr_item.Port)
					if ($_ss_farmer_obj_item.IP -eq $_ss_farmer_obj_arr_item.IP)
					{
						$_b_new_farmer = $false
						break
					}
				}
				if ($_b_new_farmer)
				{
					$script:_ss_farmer_obj_arr += $_ss_farmer_obj_item
				}
			}
			##
			if ($_nats_active_connection_obj_arr_item.Plotter)
			{
				$_ss_plotter_obj_item = [PSCustomObject]@{
					IP		 	= $_nats_active_connection_obj_arr_item.Plotter.IP
					Port		= $_nats_active_connection_obj_arr_item.Plotter.Port
				}
				$_b_new_farmer = $true
				for ($_ss_plotter_obj_arr_pos = 0; $_ss_plotter_obj_arr_pos -lt $script:_ss_plotter_obj_arr.Count; $_ss_plotter_obj_arr_pos++)
				{
					$_ss_plotter_obj_arr_item = $script:_ss_plotter_obj_arr[$_ss_plotter_obj_arr_pos]
					#if ($_ss_plotter_obj_item.IP -eq $_ss_plotter_obj_arr_item.IP -and $_ss_plotter_obj_item.Port -eq $_ss_plotter_obj_arr_item.Port)
					if ($_ss_plotter_obj_item.IP -eq $_ss_plotter_obj_arr_item.IP)
					{
						$_b_new_farmer = $false
						break
					}
				}
				if ($_b_new_farmer)
				{
					$script:_ss_plotter_obj_arr += $_ss_plotter_obj_item
				}
			}
	}
	return $_nats_active_connection_obj_arr
}

function fWriteNatsServerInfoToConsole ([string]$_io_nats_url, [array]$_io_process_arr) {
[array]$_nats_active_connection_obj_arr = $null

	$_nats_active_connection_obj_arr = fPreserveNatsConnectionsDetails $_io_nats_url
	##
	#Write-Host "_ss_controller_obj_arr = " $script:_ss_controller_obj_arr
	#Write-Host "_ss_cache_obj_arr      = " $script:_ss_cache_obj_arr
	#Write-Host "_ss_farmer_obj_arr     = " $script:_ss_farmer_obj_arr
	#Write-Host "_ss_plotter_obj_arr    = " $script:_ss_plotter_obj_arr
	##
	$_header_filler_length = 0
	$_console_msg = "|" 
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header cursor position for repositioning later
	$_upper_line_separator_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	Write-Host "" -ForegroundColor $_line_spacer_color
	#$_console_msg = "|" + $script:_nats_server_name
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
	##
	$_header_title = "   Controller    "
	$_console_msg = "|" 
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_header_filler_length += $_header_title.Length
	$_console_msg = $_header_title
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_console_msg = "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header cursor position for repositioning later
	$_header_controller_CursorPosition = $host.UI.RawUI.CursorPosition
	#[object]$_data_controller_CursorPosition = $null
	#
	Write-Host "" -ForegroundColor $_line_spacer_color
	$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
	$_console_msg = "|" + $_label_spacer
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header line separator cursor position for repositioning later
	$_line_separator_controller_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	#
	$_ss_controller_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	if ($script:_news_rows_written_to_console -lt $script:_ss_controller_obj_arr.Count) { $script:_news_rows_written_to_console = $script:_ss_controller_obj_arr.Count }
	for ($_ss_controller_obj_arr_pos = 0; $_ss_controller_obj_arr_pos -lt $script:_ss_controller_obj_arr.Count; $_ss_controller_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_controller_obj_arr_item = $script:_ss_controller_obj_arr[$_ss_controller_obj_arr_pos]
		for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
		{
			$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
			#if ($_ss_controller_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.IP -and $_ss_controller_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Port)
			if ($_ss_controller_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Controller.IP)
			{
				$_b_nats_connection_type_match_found = $true
				$_ss_controller_disp_name_length = $_ss_controller_obj_arr_item.IP.Length
				break
			}
		}
		if ($_ss_controller_disp_name_length -eq 0)
		{
			$_ss_controller_disp_name_length = $_ss_controller_obj_arr_item.IP.Length
		}
		#
		Write-Host "" -ForegroundColor $_line_spacer_color
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 0), ($_line_separator_controller_CursorPosition.Y+1+$_ss_controller_obj_arr_pos))
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
			$_alert_text = "SS Controller" + " status: Stopped, Host:" + $_ss_controller_obj_arr_item.IP
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_controller_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_controller_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	if ($script:_ss_controller_obj_arr.Count -le 0)
	{
		Write-Host "" -ForegroundColor $_line_spacer_color
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 0), ($_line_separator_controller_CursorPosition.Y+1))
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
			$_alert_text = "SS Controller" + " status: Inactive, Host:" + "None set-up"
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_controller_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_controller_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	##
	# set cursor position to last header location
	[Console]::SetCursorPosition($_header_controller_CursorPosition.X, $_header_controller_CursorPosition.Y)
	$_header_title = "      Cache      "
	$_console_msg = $_header_title
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_header_filler_length += $_header_title.Length
	$_console_msg = "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header cursor position for repositioning later
	$_header_cache_CursorPosition = $host.UI.RawUI.CursorPosition
	#[object]$_data_cache_CursorPosition = $null
	#
	# set cursor position to last header line separator location
	[Console]::SetCursorPosition($_line_separator_controller_CursorPosition.X, $_line_separator_controller_CursorPosition.Y)
	$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
	$_console_msg = "|" + $_label_spacer
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header line separator cursor position for repositioning later
	$_line_separator_cache_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	# set cursor position to last header data location
	#[Console]::SetCursorPosition($_data_controller_CursorPosition.X, $_data_controller_CursorPosition.Y)
	#
	$_ss_cache_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	if ($script:_news_rows_written_to_console -lt $script:_ss_cache_obj_arr.Count) { $script:_news_rows_written_to_console = $script:_ss_cache_obj_arr.Count }
	for ($_ss_cache_obj_arr_pos = 0; $_ss_cache_obj_arr_pos -lt $script:_ss_cache_obj_arr.Count; $_ss_cache_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_cache_obj_arr_item = $script:_ss_cache_obj_arr[$_ss_cache_obj_arr_pos]
		for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
		{
			$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
			#if ($_ss_cache_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.IP -and $_ss_cache_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Port)
			if ($_ss_cache_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Cache.IP)
			{
				$_b_nats_connection_type_match_found = $true
				$_ss_cache_disp_name_length = $_ss_cache_obj_arr_item.IP.Length
				break
			}
		}
		if ($_ss_cache_disp_name_length -eq 0)
		{
			$_ss_cache_disp_name_length = $_ss_cache_obj_arr_item.IP.Length
		}
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 1), ($_line_separator_controller_CursorPosition.Y+1+$_ss_cache_obj_arr_pos))
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
			$_alert_text = "SS Cache" + " status: Stopped, Host:" + $_ss_cache_obj_arr_item.IP
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_cache_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_cache_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	if ($script:_ss_cache_obj_arr.Count -le 0)
	{
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 1), ($_line_separator_controller_CursorPosition.Y+1))
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
			$_alert_text = "SS Cache" + " status: Inactive, Host:" + "None set-up"
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_cache_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_cache_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	##
	# set cursor position to last header location
	[Console]::SetCursorPosition($_header_cache_CursorPosition.X, $_header_cache_CursorPosition.Y)
	$_header_title = "      Farmer     "
	$_console_msg = $_header_title
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_header_filler_length += $_header_title.Length
	$_console_msg = "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header cursor position for repositioning later
	$_header_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
	#[object]$_data_farmer_CursorPosition = $null
	#
	# set cursor position to last header line separator location
	[Console]::SetCursorPosition($_line_separator_cache_CursorPosition.X, $_line_separator_cache_CursorPosition.Y)
	$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
	$_console_msg = "|" + $_label_spacer
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header line separator cursor position for repositioning later
	$_line_separator_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	# set cursor position to last header data location
	#[Console]::SetCursorPosition($_data_cache_CursorPosition.X, $_data_cache_CursorPosition.Y)
	#
	$_ss_farmer_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	if ($script:_news_rows_written_to_console -lt $script:_ss_farmer_obj_arr.Count) { $script:_news_rows_written_to_console = $script:_ss_farmer_obj_arr.Count }
	for ($_ss_farmer_obj_arr_pos = 0; $_ss_farmer_obj_arr_pos -lt $script:_ss_farmer_obj_arr.Count; $_ss_farmer_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_farmer_obj_arr_item = $script:_ss_farmer_obj_arr[$_ss_farmer_obj_arr_pos]
		for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
		{
			$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
			#if ($_ss_farmer_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.IP -and $_ss_farmer_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Port)
			if ($_ss_farmer_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Farmer.IP)
			{
				$_b_nats_connection_type_match_found = $true
				$_ss_farmer_disp_name_length = $_ss_farmer_obj_arr_item.IP.Length
				break
			}
		}
		if ($_ss_farmer_disp_name_length -eq 0)
		{
			$_ss_farmer_disp_name_length = $_ss_farmer_obj_arr_item.IP.Length
		}
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 2), ($_line_separator_controller_CursorPosition.Y+1+$_ss_farmer_obj_arr_pos))
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
					if ($_ss_farmer_obj_arr_item.IP.toString() -eq $_host_ip)
					{
						$_nats_farmer_hostname = $_hostname
						break
					}
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
			$_alert_text = "SS Farmer" + " status: Stopped, Host:" + $_ss_farmer_obj_arr_item.IP
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_farmer_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	if ($script:_ss_farmer_obj_arr.Count -le 0)
	{
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 2), ($_line_separator_controller_CursorPosition.Y+1))
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
			$_alert_text = "SS Farmer" + " status: Inactive, Host:" + "None set-up"
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_farmer_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_farmer_CursorPosition = $host.UI.RawUI.CursorPosition
	}
	##
	# set cursor position to last header location
	[Console]::SetCursorPosition($_header_farmer_CursorPosition.X, $_header_farmer_CursorPosition.Y)
	$_header_title = "     Plotter     "
	$_console_msg = $_header_title
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_header_filler_length += $_header_title.Length
	$_console_msg = "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header cursor position for repositioning later
	$_header_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
	#[object]$_data_plotter_CursorPosition = $null
	#
	# set cursor position to last header line separator location
	[Console]::SetCursorPosition($_line_separator_farmer_CursorPosition.X, $_line_separator_farmer_CursorPosition.Y)
	$_label_spacer = fBuildDynamicSpacer $_header_title.Length $_label_line_separator
	$_console_msg = "|" + $_label_spacer + "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the current header line separator cursor position for repositioning later
	$_line_separator_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
	#
	# set cursor position to last header data location
	#[Console]::SetCursorPosition($_data_farmer_CursorPosition.X, $_data_farmer_CursorPosition.Y)
	#
	$_ss_plotter_disp_name_length = 0
	$_b_nats_connection_type_match_found = $false
	if ($script:_news_rows_written_to_console -lt $script:_ss_plotter_obj_arr.Count) { $script:_news_rows_written_to_console = $script:_ss_plotter_obj_arr.Count }
	for ($_ss_plotter_obj_arr_pos = 0; $_ss_plotter_obj_arr_pos -lt $script:_ss_plotter_obj_arr.Count; $_ss_plotter_obj_arr_pos++)
	{
		$_b_nats_connection_type_match_found = $false
		[object]$_nats_active_connection_obj_arr_item = $null
		$_ss_plotter_obj_arr_item = $script:_ss_plotter_obj_arr[$_ss_plotter_obj_arr_pos]
		for ($_nats_active_connection_obj_arr_pos = 0; $_nats_active_connection_obj_arr_pos -lt $_nats_active_connection_obj_arr.Count; $_nats_active_connection_obj_arr_pos++)
		{
			$_nats_active_connection_obj_arr_item = $_nats_active_connection_obj_arr[$_nats_active_connection_obj_arr_pos]
			#if ($_ss_plotter_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.IP -and $_ss_plotter_obj_arr_item.Port -eq $_nats_active_connection_obj_arr_item.Port)
			if ($_ss_plotter_obj_arr_item.IP -eq $_nats_active_connection_obj_arr_item.Plotter.IP)
			{
				$_b_nats_connection_type_match_found = $true
				$_ss_plotter_disp_name_length = $_ss_plotter_obj_arr_item.IP.Length
				break
			}
		}
		if ($_ss_plotter_disp_name_length -eq 0)
		{
			$_ss_plotter_disp_name_length = $_ss_plotter_obj_arr_item.IP.Length
		}
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 3), ($_line_separator_controller_CursorPosition.Y+1+$_ss_plotter_obj_arr_pos))
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
			$_alert_text = "SS Plotter" + " status: Stopped, Host:" + $_ss_plotter_obj_arr_item.IP
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_plotter_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		#Finish only if last column
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	}
	if ($script:_ss_plotter_obj_arr.Count -le 0)
	{
		#
		# set cursor position to first header data location
		[Console]::SetCursorPosition(($_header_filler_length - $_header_title.Length + 3), ($_line_separator_controller_CursorPosition.Y+1))
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
			$_alert_text = "SS Plotter" + " status: Inactive, Host:" + "None set-up"
			fGenAlertNotifications $_alert_text
		}
		Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
		#
		$_spacer_length = $_header_title.Length - $_ss_plotter_disp_name_length - 2	##column separators
		$_label_spacer = fBuildDynamicSpacer $_spacer_length $_spacer
		Write-Host $_label_spacer -nonewline -ForegroundColor $_line_spacer_color
		# get the current header data cursor position for repositioning later
		#$_data_plotter_CursorPosition = $host.UI.RawUI.CursorPosition
		#
		#Finish only if last column
		$_console_msg = "|" 
		Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	}
	#
	##Write finish line seprator
	Write-Host "" -ForegroundColor $_line_spacer_color
	$_label_spacer = fBuildDynamicSpacer ($_header_filler_length + 3) $_label_line_separator_upper
	$_console_msg = " " + $_label_spacer
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# get the nats finish line separator cursor position for repositioning later
	$_finish_line_separator_nats_server_CursorPosition = $host.UI.RawUI.CursorPosition
	##
	##Write nats server header and wrap-up
	# set cursor position to last nats header top line separator location
	[Console]::SetCursorPosition($_upper_line_separator_nats_server_CursorPosition.X, $_upper_line_separator_nats_server_CursorPosition.Y)
	$_label_spacer = fBuildDynamicSpacer ($_header_filler_length + 3) $_label_line_separator_upper
	$_console_msg = $_label_spacer  + "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# set cursor position to last nats header bottom line separator location
	[Console]::SetCursorPosition($_header_nats_server_CursorPosition.X, $_header_nats_server_CursorPosition.Y)
	$_label_spacer = fBuildDynamicSpacer (($_header_filler_length + 3 - $script:_nats_server_name.Length - 2)/2) $_spacer
	$_console_msg = $_label_spacer
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	$_console_msg = $script:_nats_server_name + ":"
	$_console_msg_color = ""
	if ($script:_nats_server_health_status)
	{
		$_console_msg_color = $_html_green
		Write-Host $_console_msg -nonewline -ForegroundColor $_farmer_header_color
	}
	else 
	{
		$_console_msg_color = $_html_red
		Write-Host $_console_msg -nonewline -ForegroundColor $_html_red
	}
	$_process_state_disp = $_label_line_separator_upper
	$_console_msg = $_process_state_disp
	Write-Host $_console_msg -ForegroundColor $_fg_color_black -BackgroundColor $_console_msg_color -nonewline
	$_label_spacer = fBuildDynamicSpacer (($_header_filler_length + 3 - $script:_nats_server_name.Length - 2)/2) $_spacer
	$_console_msg = $_label_spacer + "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# set cursor position to last nats header bottom line separator location
	[Console]::SetCursorPosition($_bottom_line_separator_nats_server_CursorPosition.X, $_bottom_line_separator_nats_server_CursorPosition.Y)
	$_label_spacer = fBuildDynamicSpacer ($_header_filler_length + 3) $_label_line_separator
	$_console_msg = $_label_spacer + "|"
	Write-Host $_console_msg -nonewline -ForegroundColor $_line_spacer_color
	# set cursor position to nats finish line separator location
	[Console]::SetCursorPosition($_finish_line_separator_nats_server_CursorPosition.X, $_finish_line_separator_nats_server_CursorPosition.Y)
	##
	##NOT USED
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
	##
}

<#
function fMainProcess {
[array]$script:_ss_controller_obj_arr = $null
[array]$script:_ss_cache_obj_arr = $null
[array]$script:_ss_farmer_obj_arr = $null
[array]$script:_ss_plotter_obj_arr = $null
$script:_nats_server_health_status = $null
$script:_nats_server_name = $null
$script:_news_rows_written_to_console = 0

	while ($true) {
		Clear-Host
		####
		Write-Host "Begin"
		####
		$_nats_server_base_url = "192.168.2.22:18080"
		fWriteNatsServerInfoToConsole $_nats_server_base_url
		####
		Write-Host "Finish"
		Read-Host
		####
	}
}


fMainProcess
#>

