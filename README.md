# Autonomys monitoring powershell script
A simple to run and lightweight windows powershell script that captures live information using prometheus metrics endpoint.
To launch the monitor save all files with extension *.ps1  and sample-config.txt file in the same folder on a local computer, copy contents of sample-config.txt to a new file and name it config.txt. Adjust config to your needs and run subspace_advanced_CLI_monitor.ps1 file. Ensure that you have read the pre-requisites below.

<img src="https://github.com/irbujam/images/blob/main/summary.PNG" width="410" height="240" />
    

> Note: If you recently restarted Farmer please wait for few minutes and the metrics will show eventually
> - Tip: To validate prometheus-listen-on endpoints defined in node & farmer start-up files are working correctly, use a web browser and check data is populated at endpoints - http://node-local-ip:port/metrics & http://farmer-local-ip:port/metrics

**Pre-requisites:**
- Must use advanced CLI release (Sep 17 or later)
- Powershell version 5.1 is installed
- Add --prometheus-listen-on [node-local-ip:port] to your node start-up script
- Add --prometheus-listen-on to respective component (farmer/controller/cache/plotter) start-up script
- Use an available and unique port for  each component
- Add [command line option] -m <http port> to nats-server start script and also add the same nats-server ip/port to  config.txt file
- Change settings in the config.txt file so that the ip:port are matching to your node, farmer, and nats set-up

> To enable web access, do the following:
> - Ensure to create an inbound rule under windows defender firewall for http listening port as specified in the config file. This must be done on the computer that hosts ps1 script
> - Must run the ps1 file as admin in powershell console
> - The endpoint to use is http://ip:port/summary
> - <img src="https://github.com/irbujam/images/blob/main/web.JPG" width="160" height="320" />


**Key features:**
  - monitoring support for cluster set-up
  - Multi component (remote or local) location and multi OS supported for monitoring
  
> Web service enabled to view stats using a web browser on phone/ pc or as a second screen to legacy monitor console display
  
  - Monitor script can run independently on a pc separate from cluster/farms/nodes hosted pc 
  - Run-time changes to config.txt reflected in minitor (only works with web ui disabled in config)
  - No need for log files as monitoring is now using metrics endpoints
  - discord and telegram alert notifications
  - Summary and detail stats view configurable (and sticks) at start-up
  - Local Time Zone display
  
>*** For questions and feedback please contact (rs_00) in autonomys discord channel.

