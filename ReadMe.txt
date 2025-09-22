Dead by Daylight AWS Region Firewall Tool - README
=================================================

This tool allows you to control which AWS server regions Dead by Daylight can connect to by adding or removing Windows Firewall outbound rules for the game. All actions must be run as administrator.

-------------------------------------------------
1. Simply run MRB_Launcher.bat as admin
-------------------------------------------------
Before you begin, the script will try to automatically locate the DeadByDaylight-Win64-Shipping.exe, however if DBD is installed outside of its default location you will need to manually find the directory 
and give it to the script in order for it to continue - This is purely so the script doesnt block any IPs for any other software, service, or website and limits it to just DBD.
 - Go to Steam> right click DBD> Manage> Browse local files
 - Follow this example link to find the launcher
	"...\steamapps\common\Dead by Daylight\DeadByDaylight\Binaries\Win64\DeadByDaylight-Win64-Shipping.exe"

-------------------------------------------------
2. Initial Step: Run "Update IP Ranges"
-------------------------------------------------
The first time you launch the tool, select:

  1 - Update IP Ranges

This downloads the latest AWS server IP ranges and saves them in text files (one per region) in the "Region Codes" folder.
*Important*: You MUST run this step first, and repeat it occasionally (after game updates or every month) to keep server lists accurate.

-------------------------------------------------
3. Menu Functions Explained
-------------------------------------------------

1 - Update IP Ranges
--------------------
Downloads and updates the list of AWS IP addresses by region.  
**Run this first and repeat as needed to keep server data current.**

2 - Block Server Regions
------------------------
Lets you select which AWS server regions to block for Dead by Daylight.  
- Select a region by its number, confirm, and a new window will add firewall rules for all IPs in that region.

3 - Remove Server Region Blocks (ALL)
-------------------------------------
Removes all Windows Firewall rules created by this tool for all regions at once.

4 - Remove Server Region Blocks (SELECTED)
------------------------------------------
Lets you pick individual regions to remove rules for only those regions.    
Each removal is confirmed and performed in a new window, so you can see progress.

-------------------------------------------------
TIPS:
-------------------------------------------------
- You MUST run the tool as administrator or the firewall commands will not work.
- Always update IP ranges after a Dead by Daylight update or every month.
- Use the block and remove functions as needed for best matchmaking experience.
