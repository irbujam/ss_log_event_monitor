# subspace monitoring powershell script
A simple to run and lightweight windows powershell script that captures live information from subspace advanced CLI farmer and node metrics endpoint (farmer and node themselves can run on any OS).
To launch save all files with extension *.ps1  and sample-config.txt file in the same folder on a local computer, copy contents of sample-config.txt to a new file and name it config.txt. Adjust config to your needs and run subspace_advanced_CLI_monitor.ps1 file. Ensure that you have read the pre-requisites below.

<img src="https://github.com/irbujam/images/blob/main/summary.PNG" width="410" height="240" />
    

> Note: If you recently restarted Farmer please wait for few minutes and the metrics will show eventually
> - Tip: To validate prometheus-listen-on endpoints defined in node & farmer start-up files are working correctly, use a web browser and check data is populated at endpoints - http://node-local-ip:port/metrics & http://farmer-local-ip:port/metrics

**Pre-requisites:**
- Must use subspace advanced CLI release (Feb 15 or later) for the node and farmer
- Powershell version 5.1 is installed
- Add --prometheus-listen-on [node-local-ip:port] to your node start-up file, use an available port and do not reuse any port on same machine (example --prometheus-listen-on 192.168.2.251:1111)  
- Add --prometheus-listen-on [farmer-local-ip:port] to your farmer start-up file, use an available port and do not reuse any port on same machine (example --prometheus-listen-on 192.168.2.251:2222)
- Change settings in the config.txt file so that the ip:port are matching to your node and farmer set-up

> To enable web access, do the following:
> - Ensure to create an inbound rule under windows defender firewall for http listening port as specified in the config file. This must be done on the computer that hosts ps1 script
> - Must run the ps1 file as admin in powershell console
> - The endpoint to use is http://ip:port/summary
> - <img src="https://github.com/irbujam/images/blob/main/web.JPG" width="160" height="320" />


**Key features:**
  - Multi Farmer (remote or local) and Node (remote or local) status monitor
  
> Web service enabled to view stats using a web browser on phone/ pc or as a second screen to legacy monitor console display
  
  - Metrics for farmer/node running on windows/linux systems
  - Script can run on a pc separate from farms/nodes hosted pc 
  - Ability to add or remove node/farmer ip(s) in config without restarting the script, just add a new line for node or farmer below existing entries (currently works for console mode only with web ui disabled in config)
  - No need for log files as monitoring is now using metrics endpoints
  - downtime notifications to telegram
  - downtime notifications to discord (refer to https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks on how to create a webhook for your own server notifications)
      - Node and Farmer process state is determined and notification is sent to discord if either is offline
  - Summary view providing overall node/farms stats
      - node(s)/farm(s) status, size, plotting progress, sector times, eta, rewards
  - Detail view including:
      - node(s) sync state and peers connected
      - farmer(s) state and uptime, rewards, sector times etc
      - Disk(s) metrics break-up by farmer:
          - space allocated
          - % completion 
          - eta
          - plotting performance
          - rewards and misses
  - Auto-refresh custom timer set-up with ability to change value in config without restarting the script (currently works in console mode only)
  - Alert notification timer set-up with ability to change value in config without restarting the script (currently works in console mode only)
  - Local Time Zone display
  - Display subspace advanced CLI latest github version
  
**Known issue:**
  - config file is not reloaded dynamically when web view is enabled, currently only works in console display only mode with web ui disabled. Fix coming...
    
**Wish List (awaiting metrics endpoint data availability) :**
  - Display version variance for subspace advanced CLI latest github version v/s running node and farmer version
  - Add disk metrics information as below:
          - disk label
          - time of last reward received

>*** For questions and feedback please contact (rs_00) in subspace discord channel.

