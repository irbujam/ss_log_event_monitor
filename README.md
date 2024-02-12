# Readme: subspace_advanced_CLI_monitor.ps1
A simple to run lightweight windows powershell script that captures information from subspace advanced CLI farmer metrics endpoint. 
To launch save the ps1 and config file in same folder on a local computer, change config to your needs and double click ps1 file. Ensure that you have read the pre-requisites below.

Pre-requisites:
- Must use advanced CLI for the node and farmer
- Powershell version 5.1 is installed
- Add --prometheus-listen-on <ip:port> to your node start-up file, use an available port (example --prometheus-listen-on 192.168.2.251:1111)  
- Add --metrics-endpoints <ip:port> to your farmer start-up file, use an available port (example --metrics-endpoints 192.168.2.251:2222)
- Change settings in the config.txt file so that the ip:port are matching to your node and farmer set-up

Key features:
  - Multi Farmer (remote or local) and Node (remote or local) status monitor
  - Removed the need for log file as monitoring is now using metrics endpoints
  - Discord notifications to a webhook of your choice (refer to https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks on how to create a webhook for your own server notifications)
      - Node and Farmer process state is determined and notification is sent to discord if either is offline
  - Metrics information including:
      - Node(s) state
      - Farmer(s) state
      - Per Farmer disk level metrics:
          - plotting performance
          - rewards and misses
  - Auto-refresh custom timer set-up
  - Local Time Zone display
  
Upcoming features (Not yet available):
  - Add latest github version check and display if running version of node or farmer is outdated
  - Add overall plotting progress % completion
  - Add average overall progress rate by sector
  - Per disk metrics display to be added:
          - disk label and space allocated
          - Time to completion
          - plotting and replotting progress % completion 
          - time of last reward received  
  - Warning/Error messages summary with duplicates removed

*** For questions and feedback please contact (rs_00) in subspace discord channel.
