# subspace_advanced_CLI_monitor.ps1
A web-enabled, simple to run and lightweight windows powershell script that captures information from subspace advanced CLI farmer and node metrics endpoint (farmer and node themselves can run on any OS).
To launch save the ps1 and config file in same folder on a local computer, change config to your needs and run ps1 file. Ensure that you have read the pre-requisites below.
![](https://github.com/irbujam/images/blob/main/ss_monitor.JPG)

> Note: If you recently restarted Farmer please wait for few minutes and the metrics will show eventually (just needs little time for data to show up in the metrics endpoint after restart)

**Pre-requisites:**
- Must use advanced CLI for the node and farmer
- Powershell version 5.1 is installed
- Add --prometheus-listen-on <ip:port> to your node start-up file, use an available port (example --prometheus-listen-on 192.168.2.251:1111)  
- Add --metrics-endpoints <ip:port> to your farmer start-up file, use an available port (example --metrics-endpoints 192.168.2.251:2222)
- Change settings in the config.txt file so that the ip:port are matching to your node and farmer set-up

> To enable web access, do the following:
> - Ensure to create an inbound roule under windows defender firewall for http listening port as specified in the config file. This must be done on the computer that hosts ps1 script
> - Must run the ps1 file as admin in powershell console
> - The endpoint to use is http://ip:port/summary



**Key features:**
  - Multi Farmer (remote or local) and Node (remote or local) status monitor
  
  > (New) choice of using web service to view stats using a web browser on phone/pc, Or could still use the console based monitor on any windows pc
  
  - Ability to read metrics for farmer/node running on windows/linux systems
  - Ability to add or remove node/farmer ip(s) in config without restarting the script
  - Removed the need for log file as monitoring is now using metrics endpoints
  - Discord notifications to a webhook of your choice (refer to https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks on how to create a webhook for your own server notifications)
      - Node and Farmer process state is determined and notification is sent to discord if either is offline
  - Metrics information including:
      - Node(s) running/sync state and peers connected
      - Farmer(s) state and uptime
      - plotting performance averages 
      - Per Farmer disk level metrics:
          - plotting performance
          - rewards and misses
  - Auto-refresh custom timer set-up with ability to change value in config without restarting the script
  - Local Time Zone display
  - Display subspace advanced CLI latest github version
  
**Upcoming features (not yet available):**
  - Show variance bewteen subspace advanced CLI latest github version v/s running node and farmer version(s)
  - Add overall plotting progress % completion
  - Add disk metrics information as below:
          - disk label and space allocated
          - Time to completion
          - plotting and replotting progress % completion 
          - time of last reward received
  - Warning/Error messages summary with duplicates removed

>*** For questions and feedback please contact (rs_00) in subspace discord channel.

