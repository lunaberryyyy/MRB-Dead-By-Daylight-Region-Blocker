Dead by Daylight AWS Region Firewall Tool
=========================================

READ THIS BEFORE USING
======================
Blocking us-east-1 / Virginia is known to cause errors with EAC, try to avoid blocking this region!

Obtaining the Script
--------------------
Download the latest release here:
https://github.com/MaybeMaidehnless/MRB-Dead-By-Daylight-Region-Blocker/releases

This script modifies your firewall settings to block specific server regions used by Dead by Daylight. It does *not* interact with the game client directly.

Frequently Asked Questions
--------------------------

Q: Does the program inject into Dead by Daylight or interact with the client?
A: No! The script does not interact with the game client at all. It only needs the path to the game executable so it can apply firewall rules.

Q: How does the script block regions?
A: The script fetches AWS IP ranges (used by DBD servers) and sorts them by region. When you choose to block or unblock a region, it creates or removes Windows Firewall rules for the relevant IPs.

Q: Why does it need admin privileges?
A: Because applying firewall rules requires administrator access.

Q: What platforms are supported?
A: This script is designed for Windows and supports game installs from Steam, Epic Games, and the Windows Store.

Q: Is the script safe?
A: Yes, the entire script is custom-written. You can review a VirusTotal scan of the file here:
https://www.virustotal.com/gui/file/18b32567b661a9155d5b67162932099bd240795e20b61d48ad93fe2a1781331c?nocache=1

That said, always verify any script you download. See the “Safety Precautions” section at the end for tips.

Q: Is this project still maintained?
A: Yes, but development is slowly shifting toward a more advanced universal AWS Region Blocker with:
 - AWS IP and region detection
 - Live ping timing per region
 - GUI (no more PowerShell or CLI)


First-Time Setup
----------------
1. Download and extract the files.
2. Run MRB_launcher.bat with Administrator privileges.
3. Choose your platform:
   - 1 for Steam
   - 2 for Epic Games
   - 3 for Windows Store

This sets up the environment for your game install.


Finding the Game Executable
---------------------------

Steam:
Right-click Dead by Daylight > Manage > Browse Local Files
Navigate to:
Dead by Daylight\DeadByDaylight\Binaries\Win64\
Select: DeadByDaylight-Win64-Shipping.exe

Epic Games:
From your Library, click the three dots on Dead by Daylight > Manage > Folder icon
Navigate to:
Dead by Daylight\DeadByDaylight\Binaries\EGS\
Select: DeadByDaylight-EGS-Shipping.exe

Windows Store:
Executable is named: DeadByDaylight-WinGDK-Shipping.exe
(Automatic path detection is still being improved)


Getting the IP Ranges
---------------------
After setting the executable path:

1. Select "Update IP Ranges" (usually option 1).
2. This will download all AWS IP ranges and organize them by region.


Block Region(s)
---------------
1. Select option 2 to block regions.
2. Use options 8 and 9 to scroll between pages of regions.
3. Enter the numbers for each region you want to block.
4. Press 'A' to apply. The script will write firewall rules for all selected regions.
   - Wait for the confirmation message.


Unblock Region(s)
-----------------
Option 3: Unblock ALL regions that were previously blocked for your platform.
Option 4: Selectively unblock individual regions.


More Information
----------------
I will be updating my Steam Guide more frequently with updated information, feel free to FAVOURITE that guide or use it to leave comments!
    https://steamcommunity.com/sharedfiles/filedetails/?id=3543686547
