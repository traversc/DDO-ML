# DDO-ML an ultrafast lightweight launcher for the Dungeons and Dragons Online MMORPG

DDO-ML is a fast, lightweight game launcher I built using ~~**_Python_ (networking)** and~~ **_AutoIt3_ (GUI)**.  It solves a few of the problems associated with the official game launcher as well as provides additional functionality, such as password saving/encryption and multi-box support.

<a href="https://raw.githubusercontent.com/traversc/DDO-ML/master/ddo-ml_21.png"><img src="https://raw.githubusercontent.com/traversc/DDO-ML/master/ddo-ml_21.png" alt="ddo-ml_2" width="250" height="300" class="aligncenter size-medium wp-image-87" /></a>

*Cross-post here: https://www.ddo.com/forums/showthread.php/436296-DDO-ML-an-ultrafast-lightweight-DDO-launcher*

# Overview:
This is a small GUI interace similar to PyLotro. It is derived from an excellent command line Python Launcher by Kahath, which you can find <a href="https://www.ddo.com/forums/showthread.php/382010-How-to-launch-DDO-from-command-line">here</a>.

# Changelog:
## [1.5.3.0] - 2020-12-01
### Fixed
- error caused by changes in configuration xml as of Update 51.2 

### Added
- preferences file support for lammania
 (lamma has only 32 bit executable, you can create separate UserPreferences.ini files for lamma and normal servers, having executable set to 32 bit for lamma and 64 bit executable set for others, see sample ddo-ml.xml)

### Changed
- moved preloading from external executable into DDO-ML
- prefer ddo.launcherconfig file over TurbineLauncher.exe.config

## [1.5.2.0] - 2020-08-11
### Fixed
- App fails to work when any server is offline, even if its not the selected server.

## [1.5.1.0] - 2020-05-02
### Added
- support for installations with launcher configuration in 'ddo.launcherconfig'

## [1.5.0.0] - 2020-02-23
### Fixed
- compatibility with latest (v3.3.14.5) AutoIt compiler // ty Redgob
- windows position saved when exiting minimized app // ty Redgob
- failed to start Win32 Legacy launcher // ty Redgob

### Changed
- ddolauncher.exe reading launcher type preference (Win64 / Win32 / Win32Legacy) from UserPreferences.ini // ty Redgob

### Added
- Optionaly specify preferences file location in ddo-ml.xml

## [1.4.4.2] - 2019-12-05
### Fixed
- ddolauncher.exe problems caused by offline Hardcore server.

## [1.4.4.1] - 2018-07-23
### Fixed
- ddolauncher.exe Windows Vista compatibility.

## [1.4.4.0] - 2018-01-13
### Added
- More debug.

## [1.4.3.0] - 2018-01-10
### Added
- Debug log to ddolauncher.exe.

## [1.4.2.0] - 2017-10-25
### Fixed
- 'Error: Variable must be of type "Object"' if datacenter down.

### Added
- Error notifications to ddolauncher errors.

## [1.4.1.1] - 2017-06-22
### Changed
- Moved sources to /src.

## [1.4.1] - 2017-06-22
### Changed
- Changed window type to have minimize button.
- Readme.md markup.

### Fixed
- Version number information in output and exe properties.

## [1.4]
- Additional functionality and bug fixes by MIvanIsten.

## [1.3]
- TLSv1 protocol update for data-center move.  Minor fixes.

## [1.2]
- NOTE: You will need to re-encrypt your passwords if moving the XML file from 1.11 to 1.2.
- Fixed issue with reserved characters (e.g. hypens) in account/passwords (probably)
- Added option to choose subscription. See the example XML file.
- Switched usage to long path folder names, should fix issue with deep folder names

## [1.11]
- fixed issue with encryption

## [1.1]
- Included basic encryption - to encrypt your passwords, enter your passwords as usual and use the "Encrypt Passwords" tray menu option
- Debugging option: to turn on debug mode, set debug=1 in the INI file. Output will be written to debug.txt

## [1.01]
- Increased the connection timeout to 2 minutes (was 20 seconds). This helps with slower connections.

# Known problems:
- [1.1]: Default coordinates of the launcher are set a little too high for some screens. If you can't see the launcher after starting, change the X and Y entries in the INI file.
- [1.1]: If you have problems launching the game, move your installation directory to a shallow path (e.g., C:\DDO) and reset the directory in DDO-ML.
- ~~[1.1]: The DDO-ML icon is broken. Now it's just a generic program icon.~~
- Accounts with multiple subscriptions. The launcher chooses the first subscription, which is hopefully the correct one.
- Patching feature is untested. If it doesn't work, run the official Turbine launcher.
- Background game launch (experimental) attempts to lock your current DDO window into the foreground. It is sometimes finicky.

# Features:
- One-click log in to one or multiple accounts
- Automatic log in to specific toons
- Automatically rename multiple DDO instances on launch
- One-click close all non-active game windows (useful for multi-boxing)
- Awesomium management
- Game patching command
- Background game launch

# How to use:
Open ddo-ml.xml in notepad or another text editor and replace the values for account name, password, etc. with your own. I think it's pretty self-explanatory. You can also create additional entries as you see fit, just make sure it is properly formatted or it will break.

Open up ddo-ml.exe. On the first run, it'll ask you to locate your DDO folder. Do so and press OK. Then enter your server name at the next prompt. Make sure you spell it correctly. If you need to change your server, right click on the tray icon and click "set server" and then restart DDO-ML.

# Source code:
Source code is included if you want to make changes and compile it yourself. However, please do NOT widely distribute a modified executable without my permission. To build DDO-ML, you will need the following:
- AutoIt (GUI interface)
- ~~Python for windows~~
- ~~CxFreeze or pyinstaller (to create windows executable wrapper for python scripts)~~
