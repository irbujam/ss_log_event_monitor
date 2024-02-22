
function fBuildBarChart ([string]$_io_chart_labels, [string]$_io_chart_alt_labels, [string]$_io_chart_progress_data, [string]$_chart_sector_time_data, [string]$_io_chart_eta_data, [string]$_io_chart_size_data, [string]$_io_chart_uptime_data, [string]$_io_chart_sectorsPerHour_data, [string]$_io_chart_minutesPerSector_data, [string]$_io_chart_disk_data_arr, [string]$_io_chart_title)
{
	$_io_html_bar_chart = ""

	$_io_html_bar_chart +=

	'<canvas id="barChart" onclick="fBarChartClick()" style="width:100%;max-width:600px"></canvas>

	<script>
	var c = document.getElementById("barChart");
	var ctx = c.getContext("2d");
	var bkgrd = ctx.createLinearGradient(0, 0, 650, 0);

	var xValues = ' + $_io_chart_labels + ';
	var xValues_alt = ' + $_io_chart_alt_labels + ';
	var yValues = ' + $_io_chart_progress_data + ';
	var ce_sector_time = ' + $_chart_sector_time_data + ';
	var ce_eta = ' + $_io_chart_eta_data + ';
	var ce_size = ' + $_io_chart_size_data + ';
	var ce_uptime = ' + $_io_chart_uptime_data + ';
	var ce_sectorsPerHourAvg = ' + $_io_chart_sectorsPerHour_data + ';
	var ce_minutesPerSectorAvg = ' + $_io_chart_minutesPerSector_data + ';
	var _ce_disk_data_arr = ' + $_io_chart_disk_data_arr + ';
	
	//alert(ce_sector_time);
	
	bkgrd.addColorStop(0, "yellow");
	bkgrd.addColorStop(0.25, "orange");
	//bkgrd.addColorStop(0.75, "lightgreen");
	bkgrd.addColorStop(1, "green");
	
	//ctx.fillStyle = bkgrd;
	//ctx.fillRect(20, 20, 150, 100);
	var barColors = bkgrd;

	var xValues_alt_labels = [];
	for (var i=0; i<xValues.length; i++)
	{
		if (xValues_alt[i].length > 0) {
				xValues_alt_labels.push(xValues_alt[i].toString());
		}
		else {
				xValues_alt_labels.push(xValues[i].toString());
		}
	}


	new Chart("barChart", {
	  type: "horizontalBar",
	  data: {
		//labels: xValues,
		labels: xValues_alt_labels,
		datasets: [{
			label: "% Complete",
			backgroundColor: barColors,
			data: yValues
		}]
	  },
	  options: {
		responsive: true,
		//maintainAspectRatio: false,
		hover: { animationDuration: 1 },
		scales: {
            xAxes: [{
				stacked: true,
                ticks: { min: 0, max: 100 }
            }],
            yAxes: [{
                stacked: true
            }]
        },
		legend: { display: false },
		title: {
			display: true,
			text: "' + $_io_chart_title + ' "
		},
		onClick: function(c,i){
			e = i[0];
			//document.getElementById("rewards").innerHTML = e._index;
			var x_value = this.data.labels[e._index];
			var y_value = this.data.datasets[0].data[e._index];

			var bFoundUUIdMatch = false;
			//_div_html = "<Table>";
			var _div_html = "";
			for (var i=0; i<xValues_alt_labels.length; i++)
			{
				if (xValues_alt_labels[i].toString() == x_value) {
					bFoundUUIdMatch = true;
					_el_uptime = ce_uptime[i];
					_el_sector_time = ce_sector_time[i];
					_el_sectorsPerHourAvg = ce_sectorsPerHourAvg[i];
					_el_minutesPerSectorAvg = ce_minutesPerSectorAvg[i];
					//disk header
					_div_html += "<Table>";
					_div_html += "<tr>";
					//_div_html += "<td>Farmer: " + x_value + ", Uptime: " + _el_uptime + ", Sectors/Hour (Avg): " + _el_sectorsPerHourAvg + ", Minutes/Sector (Avg): " + _el_minutesPerSectorAvg + "</td>";
					_div_html += "<td>Farmer: " + x_value + ", Uptime: " + _el_uptime + ", Sector Time: " + _el_sector_time + ", Sectors/Hour (Avg): " + _el_sectorsPerHourAvg + ", Minutes/Sector (Avg): " + _el_minutesPerSectorAvg + "</td>";
					_div_html += "</tr>";
					_div_html += "</Table>";
					//disk header
					_div_html += "<Table border=1>";
					_div_html += "<tr>";
					_div_html += "<td>Disk Id</td>";
					_div_html += "<td>Size</td>";
					_div_html += "<td>% Complete</td>";
					_div_html += "<td>ETA</td>";
					_div_html += "<td>Sectors/Hour</td>";
					_div_html += "<td>Time/Sector</td>";
					_div_html += "<td>Rewards</td>";
					_div_html += "<td>Misses</td>";
					_div_html += "</tr>";
					//data
					for (var j=0; j<_ce_disk_data_arr.length; j++)
					{
						if (_ce_disk_data_arr[j].UUId == x_value || _ce_disk_data_arr[j].Hostname == x_value) {
							_div_html += "<tr>";
							_div_html += "<td>" + _ce_disk_data_arr[j].DiskId + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].Size + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].PercentComplete + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].ETA + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].SectorsPerHour + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].MinutesPerSector + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].Rewards + "</td>";
							_div_html += "<td>" + _ce_disk_data_arr[j].Misses + "</td>";
							_div_html += "</tr>";
						}
					}
					_div_html += "</Table>";
					document.getElementById("progress").innerHTML = _div_html;
					break;
				}
			}
			if (bFoundUUIdMatch == false) {
				document.getElementById("progress").innerHTML = "something off, xValues_alt_labels length:" + xValues_alt_labels.length;
			}
			//_div_html += "</Table>";
		},
		animation: {
		onComplete: function () {
			var ctx = this.chart.ctx;
			ctx.font = Chart.helpers.fontString(Chart.defaults.global.defaultFontFamily, "normal", Chart.defaults.global.defaultFontFamily);
			ctx.textAlign = "left";
			ctx.textBaseline = "bottom";

			this.data.datasets.forEach(function (dataset) {
				for (var i = 0; i < dataset.data.length; i++) {
					var model = dataset._meta[Object.keys(dataset._meta)[0]].data[i]._model,
					left = dataset._meta[Object.keys(dataset._meta)[0]].data[i]._xScale.left;
					ctx.fillStyle = "#444"; // _bar_label color
					var _label = model.label;
					
					var _bar_label = "";
					for (var i=0; i<xValues_alt_labels.length; i++)
					{
						if (xValues_alt_labels[i].toString() == _label) {
							//_bar_label = "ETA: " + ce_eta[i] + " days";
							_bar_label = "Size: " + ce_size[i] + " TiB, " + "ETA: " + ce_eta[i] + " days";
							break;
						}
					}
					ctx.fillText(_bar_label, left + 15, model.y + 8);
				}
			});               
        }
		}
	  }
	});
	</script>'

	return $_io_html_bar_chart
}

function fBuildRadarChart ([string]$_io_chart_farm_labels, [string]$_chart_farm_alt_labels, [string]$_io_chart_farm_sectorsPerHour_data, [string]$_io_chart_farm_minutesPerSector_data, [string]$_io_chart_rewards_data, [string]$_io_chart_farm_disk_data_arr, [string]$_io_chart_title)
{
	$_io_html_radar_chart = ""

	$_io_html_radar_chart +=
	'<canvas id="radarChart" style="width:100%;max-width:500px"></canvas>
	<script>


	var _c_farm_arr = ' + $_io_chart_farm_labels + ';
	var _c_farm_alt_arr = ' + $_chart_farm_alt_labels + ';
	var c_sectorsPerHourAvg = ' + $_io_chart_farm_sectorsPerHour_data + ';
	var c_minutesPerSectorAvg = ' + $_io_chart_farm_minutesPerSector_data + ';
	var _ce_disk_data_arr = ' + $_io_chart_farm_disk_data_arr + ';
	

	var _cc_filter = "Misses" ;
	//var _size_label = ["Size", "(TiB)"];
	var _sectors_per_hour_avg_label = ["Sectors/", "Hour (Avg)"];
	var _minutes_per_sector_avg_label = ["Minutes/", "Sector (Avg)"];

	//var _label_values = [_size_label, _sectors_per_hour_avg_label, _minutes_per_sector_avg_label];
	var _label_values = [_sectors_per_hour_avg_label, _minutes_per_sector_avg_label];

	var _c = document.getElementById("radarChart");
	var _bar_chart = new Chart(_c, {
		//type: "radar",
		type: "bar",
		data: {
			labels: _label_values,
			datasets: []
			},
		  options: {
			responsive: true,
			//maintainAspectRatio: false,
			scales: {
				xAxes: [{
					stacked: true,
				}],
				yAxes: [{
					stacked: true,
					//ticks: { min: 0, max: 40 }
					ticks: { min: 0 }
				}]
			},
			legend: { display: true },
			title: {
				display: true,
				text: "' + $_io_chart_title + ' "
			}
			/* Below is for bar element values display
			,
			"hover": {
			  "animationDuration": 0
			},
			"animation": {
			  "duration": 1,
			  "onComplete": function() {
				var chartInstance = this.chart,
				  ctx = chartInstance.ctx;

				ctx.font = Chart.helpers.fontString(Chart.defaults.global.defaultFontSize, Chart.defaults.global.defaultFontStyle, Chart.defaults.global.defaultFontFamily);
				ctx.textAlign = "center";
				ctx.textBaseline = "bottom";

				this.data.datasets.forEach(function(dataset, i) {
				  var meta = chartInstance.controller.getDatasetMeta(i);
				  meta.data.forEach(function(bar, index) {
					var data = dataset.data[index];
					ctx.fillText(data, bar._model.x, bar._model.y - 5);
				  });
				});
			  }
			}
			*/
		  }
	});

	function fAddChartData(_io_chart, _io_label, _io_color, _io_data, _io_stack) {
		_io_chart.data.datasets.push({
			label: _io_label,
			backgroundColor: _io_color,
			data: _io_data,
			stack: _io_stack
		});
		_io_chart.update();
	}

	for (var i=0; i<_c_farm_arr.length; i++)
	{
		var _dataset_sectors_per_hour = 0;
		var _dataset_minutes_per_sector = 0;
		var _ds_values = [0, 0];
		
		_dataset_sectors_per_hour = c_sectorsPerHourAvg[i];
		_ds_values[0] = _dataset_sectors_per_hour;
		
		_dataset_minutes_per_sector = c_minutesPerSectorAvg[i];
		_ds_values[1] = _dataset_minutes_per_sector;
		
		var _random_color = fGenerateColorRandom();
		//fAddChartData(_bar_chart, _c_farm_arr[i], "rgba(0,0,200,0.2)", _ds_values, i);
		if (_c_farm_alt_arr[i].length > 0) {
			fAddChartData(_bar_chart, _c_farm_alt_arr[i], _random_color, _ds_values, i);
		}
		else {
			fAddChartData(_bar_chart, _c_farm_arr[i], _random_color, _ds_values, i);
		}
	}	

	</script>'
	
	return $_io_html_radar_chart
}

function fBuildNetPerformanceChart ([string]$_io_chart_farm_labels, [string]$_chart_farm_alt_labels, [string]$_chart_total_sectors_per_hour_data, [string]$_chart_sector_time_data, [string]$_io_chart_farm_disk_data_arr, [string]$_io_chart_title)
{
	$_io_html_NetPerf_chart = ""

	$_io_html_NetPerf_chart +=
	'<canvas id="NetPerfChart" style="width:100%;max-width:500px"></canvas>
	<script>


	var _c_farm_arr = ' + $_io_chart_farm_labels + ';
	var _c_farm_alt_arr = ' + $_chart_farm_alt_labels + ';
	var c_total_sectors_per_hour = ' + $_chart_total_sectors_per_hour_data + ';
	var c_sector_time = ' + $_chart_sector_time_data + ';
	var _ce_disk_data_arr = ' + $_io_chart_farm_disk_data_arr + ';

	var _total_sectors_per_hour_label = ["Sectors/", "Hour (Total)"];
	var _sector_time_label = ["Sector", "Time"];

	var _label_values = [_total_sectors_per_hour_label, _sector_time_label];

	var _c = document.getElementById("NetPerfChart");
	var _bar_chart = new Chart(_c, {
		type: "bar",
		data: {
			labels: _label_values,
			datasets: []
			},
		  options: {
			responsive: true,
			//maintainAspectRatio: false,
			scales: {
				xAxes: [{
					stacked: true,
				}],
				yAxes: [{
					stacked: true,
					//ticks: { min: 0, max: 40 }
					ticks: { min: 0 }
				}]
			},
			legend: { display: true },
			title: {
				display: true,
				text: "' + $_io_chart_title + ' "
			}
			/* Below is for bar element values display
			,
			"hover": {
			  "animationDuration": 0
			},
			"animation": {
			  "duration": 1,
			  "onComplete": function() {
				var chartInstance = this.chart,
				  ctx = chartInstance.ctx;

				ctx.font = Chart.helpers.fontString(Chart.defaults.global.defaultFontSize, Chart.defaults.global.defaultFontStyle, Chart.defaults.global.defaultFontFamily);
				ctx.textAlign = "center";
				ctx.textBaseline = "bottom";

				this.data.datasets.forEach(function(dataset, i) {
				  var meta = chartInstance.controller.getDatasetMeta(i);
				  meta.data.forEach(function(bar, index) {
					var data = dataset.data[index];
					ctx.fillText(data, bar._model.x, bar._model.y - 5);
				  });
				});
			  }
			}
			*/
		  }
	});

	function fAddChartData(_io_chart, _io_label, _io_color, _io_data, _io_stack) {
		_io_chart.data.datasets.push({
			label: _io_label,
			backgroundColor: _io_color,
			data: _io_data,
			stack: _io_stack
		});
		_io_chart.update();
	}

	for (var i=0; i<_c_farm_arr.length; i++)
	{
		var _dataset_total_sectors_per_hour = 0;
		var _dataset_sector_time = 0;
		var _ds_values = [0, 0];
		
		_dataset_total_sectors_per_hour = c_total_sectors_per_hour[i];
		_ds_values[0] = _dataset_total_sectors_per_hour;
		
		//const _min = Math.floor(c_sector_time[i] / 60);
		//const _sec = c_sector_time[i] % 60;
		//_dataset_sector_time = _min + "m " + _sec + "s";
		_dataset_sector_time = c_sector_time[i];
		_ds_values[1] = _dataset_sector_time;

		var _random_color = fGenerateColorRandom();
		//fAddChartData(_bar_chart, _c_farm_arr[i], "rgba(0,0,200,0.2)", _ds_values, i);
		if (_c_farm_alt_arr[i].length > 0) {
			fAddChartData(_bar_chart, _c_farm_alt_arr[i], _random_color, _ds_values, i);
		}
		else {
			fAddChartData(_bar_chart, _c_farm_arr[i], _random_color, _ds_values, i);
		}
	}	

	</script>'
	
	return $_io_html_NetPerf_chart
}

function fBuildPieChart ([string]$_io_chart_labels, [string]$_chart_alt_labels, [string]$_chart_rewards_data, [string]$_io_chart_disk_data_arr, [string]$_io_chart_title)
{
	$_io_html_pie_chart = ""

	$_io_html_pie_chart += 
	'<canvas id="pieChart" onclick="fPieChartClick()" style="width:100%;max-width:500px"></canvas>

	<script>
	var xValues = ' + $_io_chart_labels + ';
	var xValues_alt = ' + $_chart_alt_labels + ';
	var yValues = ' + $_chart_rewards_data + ';
	var _ce_disk_data_arr = ' + $_io_chart_disk_data_arr + ';


	var xValues_alt_labels = [];
	for (var i=0; i<xValues.length; i++)
	{
		if (xValues_alt[i].length > 0) {
				xValues_alt_labels.push(xValues_alt[i].toString());
		}
		else {
				xValues_alt_labels.push(xValues[i].toString());
		}
	}
	
	var _pie_colors = [];
	for (var i=0; i<xValues.length; i++)
	{
		_pie_colors.push(fGenerateColorRandom());
	}

	new Chart("pieChart", {
	  type: "pie",
	  data: {
		//labels: xValues,
		labels: xValues_alt_labels,
		datasets: [{
		  backgroundColor: _pie_colors,
		  data: yValues
		}]
	  },
	  options: {
		title: {
		  display: true,
		  text: "' + $_io_chart_title + '"
		},
	  onClick: function(c,i){
		e = i[0];
		//document.getElementById("rewards").innerHTML = e._index
		var x_value = this.data.labels[e._index];
		var y_value = this.data.datasets[0].data[e._index];
		

		//document.getElementById("rewards").innerHTML = x_value
		var bFoundUUIdMatch = false;
		_div_html = "<Table>"
		for (var i=0; i<xValues_alt_labels.length; i++)
		{
			if (xValues_alt_labels[i].toString() == x_value) {
				bFoundUUIdMatch = true;
				_el_uptime = ce_uptime[i];
				_el_sectorsPerHourAvg = ce_sectorsPerHourAvg[i];
				_el_minutesPerSectorAvg = ce_minutesPerSectorAvg[i];
				//disk header
				_div_html += "<Table border=1>";
				_div_html += "<tr>";
				_div_html += "<td>Disk Id</td>";
				_div_html += "<td>Rewards</td>";
				_div_html += "<td>Misses</td>";
				_div_html += "</tr>";
				//data
				for (var j=0; j<_ce_disk_data_arr.length; j++)
				{
					if (_ce_disk_data_arr[j].UUId == x_value || _ce_disk_data_arr[j].Hostname == x_value) {
						_div_html += "<tr>";
						_div_html += "<td>" + _ce_disk_data_arr[j].DiskId + "</td>";
						_div_html += "<td>" + _ce_disk_data_arr[j].Rewards + "</td>";
						_div_html += "<td>" + _ce_disk_data_arr[j].Misses + "</td>";
						_div_html += "</tr>";
					}
				}
				_div_html += "</Table>";
				document.getElementById("rewards").innerHTML = _div_html;
				break;
			}
		}
		if (bFoundUUIdMatch == false) {
			document.getElementById("rewards").innerHTML = "something off, xValues_alt_labels length:" + xValues_alt_labels.length;
		}
		_div_html += "</Table>"
		}
	  }
	});
	</script>'

	return $_io_html_pie_chart
}

