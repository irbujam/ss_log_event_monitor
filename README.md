# Autonomys monitoring powershell script
A simple to run and lightweight windows powershell script that captures live information using prometheus metrics endpoint.
* To use the monitor:
- Save all files from latest monitor release in the a folder on local computer
- Copy contents of sample-config.txt to a new file and save it in the same folder. Name the new file as config.txt
- Adjust config to your needs (see reuirements section below)
- Run subspace_advanced_CLI_monitor.ps1 file in powershell

<img src="https://github.com/irbujam/images/blob/main/summary.PNG" width="410" height="240" />
    
> Note: If you recently restarted Farmer please wait for few minutes and the metrics will show eventually
> - Tip: To validate prometheus-listen-on endpoints defined in node & farmer start-up files are working correctly, use a web browser and check data is populated at endpoints - http://node-local-ip:port/metrics & http://farmer-local-ip:port/metrics

**Requirements:**
- Must use latest advanced CLI release
- Powershell version 5.1 is installed
- Add --prometheus-listen-on [node-local-ip:port] to node start-up script
- Add --prometheus-listen-on [farmer-local-ip:port] to farmer start-up script
- Change node/farmer settings in the config.txt file so that the ip:port are matching to the values set for --prometheus-listen-on your node and farmer
> If using cluster, apply additional settings as below:
- Add command line options -m <http listener port> and -n <server name> to nats-server start-up script (example: nats-server -n my-nats-server1 -m 18080 -c nats.config)
- Change nats-server settings in the config.txt file so that the ip matches to the computer running nats-server and port matches to <http listener port> as in nats-server start-up script 

> To enable web access, do the following:
> - Ensure to create an inbound rule under windows defender firewall for http listening port as specified in the config file. This must be done on the computer that hosts ps1 script
> - Must run the ps1 file as admin in powershell console
> - The endpoint to use is http://ip:port/summary
> - <img src="https://github.com/irbujam/images/blob/main/web.JPG" width="160" height="320" />


**Key features:**
  - monitoring support for cluster set-up
  - Multi component (remote or local) location and multi OS supported for monitoring
  - Web service enabled to view stats using a web browser on phone/ pc or as a second screen to legacy monitor console display
  
  - Monitor script can run independently on a pc separate from cluster/farms/nodes hosted pc 
  - Run-time changes to config.txt reflected in minitor (only works with web ui disabled in config)
  - No need for log files as monitoring is now using metrics endpoints
  - discord and telegram alert notifications
  - Summary and detail stats view configurable (and sticks) at start-up
  - Local Time Zone display
  
>*** For questions and feedback please contact (rs_00) in autonomys discord channel.

