<strong>DDO-ML an ultrafast lightweight launcher for the Dungeons and Dragons Online MMORPG</strong>

DDO-ML is a fast, lightweight game launcher I built using <em><strong>Python </strong>(networking)</em> and <em><strong>AutoIt3 </strong>(GUI)</em>.  It solves a few of the problems associated with the official game launcher as well as provides additional functionality, such as password saving/encryption and multi-box support.  

<a href="https://raw.githubusercontent.com/traversc/DDO-ML/master/ddo-ml_21.png"><img src="https://raw.githubusercontent.com/traversc/DDO-ML/master/ddo-ml_21.png" alt="ddo-ml_2" width="250" height="300" class="aligncenter size-medium wp-image-87" /></a>

<em>Cross-post here: https://www.ddo.com/forums/showthread.php/436296-DDO-ML-an-ultrafast-lightweight-DDO-launcher</em>

version 1.4<br>
3/9/2016

<b>Overview:</b>
This is a small GUI interace similar to PyLotro. It is derived from an excellent command line Python Launcher by Kahath, which you can find <a href="https://www.ddo.com/forums/showthread.php/382010-How-to-launch-DDO-from-command-line">here</a>.

<b>Updates:</b><br>
Ver 1.4 - Additional functionality and bug fixes by MIvanIsten.

Ver 1.3 - TLSv1 protocol update for data-center move.  Minor fixes.  

Ver 1.2 - NOTE: You will need to re-encrypt your passwords if moving the XML file from 1.11 to 1.2. 
Fixed issue with reserved characters (e.g. hypens) in account/passwords (probably)
Added option to choose subscription. See the example XML file.
Switched usage to long path folder names, should fix issue with deep folder names

Ver 1.11 - fixed issue with encryption
Ver 1.1
Included basic encryption - to encrypt your passwords, enter your passwords as usual and use the "Encrypt Passwords" tray menu option
Debugging option: to turn on debug mode, set debug=1 in the INI file. Output will be written to debug.txt

Ver 1.01 - Increased the connection timeout to 2 minutes (was 20 seconds). This helps with slower connections. 

<b>Known problems:</b>
Ver 1.1: Default coordinates of the launcher are set a little too high for some screens. If you can't see the launcher after starting, change the X and Y entries in the INI file.
Ver 1.1: If you have problems launching the game, move your installation directory to a shallow path (e.g., C:\DDO) and reset the directory in DDO-ML.
Ver 1.1: The DDO-ML icon is broken. Now it's just a generic program icon.
Accounts with multiple subscriptions. The launcher chooses the first subscription, which is hopefully the correct one
Patching feature is untested. If it doesn't work, run the official Turbine launcher.
Background game launch (experimental) attempts to lock your current DDO window into the foreground. It is sometimes finicky.


<b>Features:</b><br>
One-click log in to one or multiple accounts<br>
Automatic log in to specific toons<br>
Automatically rename multiple DDO instances on launch<br>
One-click close all non-active game windows (useful for multi-boxing)<br>
Awesomium management<br>
Game patching command<br>
Background game launch<br>


<b>How to use:</b>
Open ddo-ml.xml in notepad or another text editor and replace the values for account name, password, etc. with your own. I think it's pretty self-explanatory. You can also create additional entries as you see fit, just make sure it is properly formatted or it will break. <br><br>

Open up ddo-ml.exe. On the first run, it'll ask you to locate your DDO folder. Do so and press OK. Then enter your server name at the next prompt. Make sure you spell it correctly. If you need to change your server, right click on the tray icon and click "set server" and then restart DDO-ML. 

<b>Source code:</b>
Source code is included if you want to make changes and compile it yourself. However, please do NOT widely distribute a modified executable without my permission. To build DDO-ML, you will need the following:
Python for windows<br>
CxFreeze or pyinstaller (to create windows executable wrapper for python scripts)<br>

Instructions for pyinstaller:
1) Download and install Python 3.5, Visual Studio 2015 (with C++ support) and pip install pyinstaller
2) run pyinstaller --onefile --win-private-assemblies --win-no-prefer-redirects ddolauncher.py

AutoIt (GUI interface)<br>
