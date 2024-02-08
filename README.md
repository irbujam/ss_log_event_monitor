# Readme: parse_ss_farmer_log.ps1
A simple to run Windows Powershell script that captures information from subspace advance CLI farmer logs. 
To launch save the ps1 file to your pc, double click and follow prompts. Ensure that you have read the pre-requisites below.

Key features:
  - Discord notifications to a webhook of your choice (refer to https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks on how to create a webhook for your own server notifications)
      - Node and Farmer process state is determined and notification is sent to discord if either is offline (assuming node and farmer is running on single pc)  
  - Latest github version check and display if running version of node or farmer is outdated
  - Statistics information by disk including:
      - Node sync status
      - Farmer uptime
      - Overall plotting progress % completion
      - Total rewards and space allocated
      - Average overall progress rate by sector
      - Per disk metrics:
          - disk info and space allocated
          - rewards and misses  
          - plotting speeds and Time to completion
          - plotting and replotting progress % completion 
          - time of last reward received  
  - Warning/Error messages summary with duplicates removed to show only unique entries
  - Option for customizable auto-refresh time set-up or choice for manual refresh
  - Local Time Zone display
  - Choice of summary only view

Pre-requisites:
- Ensure that advance CLI is used for the farmer
- Must write the farmer console output to a file with extension .txt or .log

  Example Farmer file that writes to log:
  
            # Replace `PATH_TO_FARM` with location where you want you store plot files
            # Replace `WALLET_ADDRESS` below with your account address from Polkadot.js wallet
            # Replace `PLOT_SIZE` with plot size in gigabytes or terabytes, for example 100G or 2T (but leave at least 60G of disk space for node and some for OS)
            # Add "| Tee-Object -file <log file name>" at the end to write console oyutput to log file:
            #    - in example shown below current date is added to the log file name so it retains history in log file by date if the farmer were to be restarted due to a new release
            #
            $host.UI.RawUI.WindowTitle = "Subspace Farmer - Gemini 3g"
            $currentDate = Get-Date -Format "yyyy-MM-dd"
            $logFile = "ss_log_" + $currentDate + ".txt"
            .\subspace-farmer-windows-x86_64-skylake-gemini-3h-2024-feb-5.exe farm --reward-address WALLET_ADDRESS path=PATH_TO_FARM,size=PLOT_SIZE | Tee-Object -file $logFile

- powershell version 5.1 is installed
  
This script will open a windows dialog box at start asking user to select the log file. Please select appropriate subspace farmer log file and follow the prompts.

Thank you for using this script. Feedback is appreciated.
