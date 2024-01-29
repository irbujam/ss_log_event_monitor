# Readme: parse_ss_farmer_log.ps1
Windows Powershell script that captures information from subspace advance CLI farmer logs:

Key features:
  - Local Time display
  - Summary information by disk listing rewards, plot status and last reward received timeframe
  - Warning/Error messages summarized to remove duplicates and show only unique warnings/errors

Pre-requisites:
- Ensure that advance CLI is used for the farmer and the farmer console output is written to a file with extension .txt or .log

  Example Farmer file that writes to log:
  
            # Replace `PATH_TO_FARM` with location where you want you store plot files
            # Replace `WALLET_ADDRESS` below with your account address from Polkadot.js wallet
            # Replace `PLOT_SIZE` with plot size in gigabytes or terabytes, for example 100G or 2T (but leave at least 60G of disk space for node and some for OS)
            # Add "| Tee-Object -file log.txt" at the end to write console oyutput to log file, as seen in example below
            .\subspace-farmer-windows-x86_64-skylake-gemini-3g-2024-jan-29.exe farm --reward-address WALLET_ADDRESS path=PATH_TO_FARM,size=PLOT_SIZE | Tee-Object -file log.txt

- powershell version 5.1 is installed
  
This script will open a windows dialog box at start asking user to select the log file. Please select appropriate subspace farmer log file and follow the prompts.

Thank you for using this script. Feedback is appreciated.
