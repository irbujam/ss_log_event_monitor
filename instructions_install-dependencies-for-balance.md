open powershell 
type winget install nodejs and press enter
close current powershell session 
open a new powershell session
type npm install @polkadot/api and press enter

====
powershell session is default to use wallet balance feature, but you can set use windows command too by following below steps:

Verify the PATH Environment Variable:

Open System Properties: Right-click on This PC (or Computer), and select Properties.
Advanced System Settings: In the left-hand menu, click on Advanced system settings.
Environment Variables: In the System Properties window, click Environment Variables.
Edit PATH:
In the System variables section, scroll down and find the Path variable. Click on Edit.
Make sure the path C:\Program Files\nodejs\ is included in the list of paths. If it's not, add it by clicking New and typing C:\Program Files\nodejs\.
Restart Command Prompt: After updating the PATH, close and reopen Command Prompt for the changes to take effect.