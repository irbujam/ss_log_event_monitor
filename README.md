# Autonomys monitoring powershell script
A simple to run and lightweight powershell script that captures live information using prometheus metrics endpoint.

To use the monitor:
- Save all files from latest monitor release in a folder on local computer
- Copy contents of sample-config.txt to a new file and save it in the same folder. Name the new file as config.txt
- Adjust config.txt to match your node, farmer and (optional) cluster set-up [refer to [**Requirements:**] section below] 
- Run subspace_advanced_CLI_monitor.ps1 file in powershell

<img src="https://github.com/irbujam/images/blob/main/summary.PNG" width="410" height="240" />
    
> Note: If you recently restarted Farmer please wait for few minutes and the metrics will show eventually
> - Tip: To validate prometheus-listen-on endpoints defined in node & farmer start-up files are working correctly, use a web browser and check data is populated at endpoints - http://node-local-ip:port/metrics & http://farmer-local-ip:port/metrics

**Requirements:**
- Must use latest CLI release (see https://github.com/autonomys/subspace/releases)
- Powershell is installed (Windows should have powershell pre-installed. For installing powershell on linux see https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.4)
- Add --prometheus-listen-on [node-local-ip:port] to node start-up script
- Add --prometheus-listen-on [farmer-local-ip:port] to farmer start-up script
- Change node/farmer settings in the config.txt file so that the ip:port are matching to the values set for --prometheus-listen-on your node and farmer
  
> If using cluster, apply additional settings as below:
- Add command line options -m <http listener port> and -n <server name> to nats-server start-up script (example: nats-server -n my-nats-server1 -m 18080 -c nats.config)
- Change nats-server settings in the config.txt file so that the ip matches to the computer running nats-server and port matches to 'http listener port' as in option scpecified for -m in the nats-server start-up script 

> To enable web access, do the following:
> - Ensure to create an inbound rule under windows defender firewall for http listening port as specified in the config file. This must be done on the computer that hosts ps1 script
> - Must run the ps1 file as admin in powershell console
> - The endpoint to use is http://ip:port/summary
> - <img src="https://github.com/irbujam/images/blob/main/web.JPG" width="160" height="320" />


**Key features:**
  - monitoring support for multi component (remote or local) nodes, farmer and (optional) cluster set-up, using prometheus metrics endpoints
  - Monitor script can run independently on a pc separate from cluster/farms/nodes hosted pc 
  - multi OS (Windows and Linux) support for running the monitoring tool
  - Web service enabled to view stats using a web browser on phone/ pc or as a second screen to legacy monitor console display
  - Run-time changes to config.txt reflected in minitor (currently only works with API/web ui disabled in config.txt)
  - customizable alerts enabled for discord and telegram 
  - Summary and detail stats view that is user configurable (and sticks) at start-up
  - Local Time Zone display
  
>*** For questions and feedback please contact (rs_00) in autonomys discord channel.

