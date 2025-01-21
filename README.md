# Hat's Scripts

**Hat's Scripts** is a PowerShell script project aimed at making new PC setups more efficient. While the scripts are generally intended for use at QualityIP, no identifiable information is ever to be contained within the script. Collaboration, bug reports and feature requests are all welcome!

*The latest release of this repo is always available at:* ***HatsThings.com/go/Hats-Scripts***

## What do the scripts do?

**PC Setup Script.PS1:** *This script is the brain of the operation and is what the* ***[Release](https://github.com/TylerHats/Hats-Scripts/releases)*** *executables are running. This script prepares the environment, runs all important functions and carries out setup based on your options.*

**Windows Update Script.PS1:** *As the name suggests, this script contains the functions and code to run* ***Windows Updates*** *when called by* ***PC Setup Script.PS1***. *This script calls on modules and variables setup in* ***PC Setup Script.PS1*** *but could be modified to run on its own if desired.*

**Script Functions.PS1:** *This file contains functions called on by* ***PC Setup Script.PS1*** *and does nothing on its own.*

## Packaging

***[Releases](https://github.com/TylerHats/Hats-Scripts/releases)*** are packaged executables based on the code from the time of creation. Generally ***[Releases](https://github.com/TylerHats/Hats-Scripts/releases)*** are created when major changes have been made to the code base.

*Currently, these executables are made using WinRAR and are simple, silent, self extracting archives that launch the main* ***PC Setup Script.PS1*** *file with the -ExecutionPolicy Bypass flag to assist in automating script execution. As long as all three PS1 files are in the same folder, the* ***PC Setup Script.PS1*** *file can be launched directly.*

**Packaging Instructions:**
Using your archiving software of choice, pack the three PS1 files into a self extracting archive and add the following command to execute after extraction, and set the archive to silently extract if you desire:

    PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "PC Setup Script.ps1"

## Issues

Please feel free to drop reports for any bugs you come across or requests for any features you can think of on the ***[Issues](https://github.com/TylerHats/Hats-Scripts/issues)*** page! While I can't guarantee every feature or bug can be addressed, I'll make an effort to investigate every request. At the very least, each issue will be reviewed and researched. Whether it is something that can addressed or not, information will be added to each request explaining my choice before it is closed.

## Open Source Code

This code base is entirely open source under the GPL 3.0 license. Feel free to do whatever you want with this code so long as it adheres to the license. While I am working to incorporate the ability to work with Closed Source programs, code, executables and other information for those programs will not be maintained here.