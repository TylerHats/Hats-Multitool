# Hat's Multitool

**Hat's Multitool** is a PowerShell-based project aimed at making new PC setups more efficient, along with offering common troubleshooting tools and programs. Collaboration, bug reports and feature requests are all welcome!

*The latest release of this repo is always available at:* ***HatsThings.com/go/Hats-Multitool***

## Running the Program

The **Hat's Multitool** can be run by downloading a **[release](https://github.com/TylerHats/Hats-Multitool/releases)** from GitHub and executing the file directly (the program self updates for portability so you do not need to redownload for new versions), or by running the following line in a standard PowerShell console, no elevation needed:

    IRM MT.HTSTH.APP | IEX

## What do the scripts do?

**Core.PS1:** *This script is the brain of the operation and is what the* ***[Release](https://github.com/TylerHats/Hats-Multitool/releases)*** *executables are running. This script prepares the environment, runs all important functions and carries out setup based on your options.*

**Common.PS1:** *This file contains common variables and functions used in other scripts throughout the program.*

**-Modules-.PS1:** *These are modules called on by* ***Core.PS1*** *that carry out various tasks as setup by user inputs.*

## Packaging

***[Releases](https://github.com/TylerHats/Hats-Multitool/releases)*** are packaged executables based on the code from the time of creation. Generally ***[Releases](https://github.com/TylerHats/Hats-Multitool/releases)*** are created when major changes have been made to the code base.

*Currently, these executables are made using WinRAR and are simple, silent, self extracting archives that launch the main* ***Core.PS1*** *file with the -ExecutionPolicy Bypass flag to assist in automating program execution. As long as all of the PS1 files and icons are in the same folder, the* ***Core.PS1*** *file can be launched directly.*

**Packaging Instructions:**
Using your archiving software of choice, pack the three PS1 files into a self extracting archive and add the following command to execute after extraction, and set the archive to silently extract if you desire:

    PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "Core.ps1" -WindowStyle Minimized

## Issues

Please feel free to drop reports for any bugs you come across or requests for any features you can think of on the ***[Issues](https://github.com/TylerHats/Hats-Multitool/issues)*** page! While I can't guarantee every feature or bug can be addressed, I'll make an effort to investigate every request. At the very least, each issue will be reviewed and researched. Whether it is something that can addressed or not, information will be added to each request explaining my choice before it is closed.

## Open Source Code

This code base is entirely open source under the GPL 3.0 license. Feel free to do whatever you want with this code so long as it adheres to the license. While I am working to incorporate the ability to work with Closed Source programs, code, executables and other information for those programs will not be maintained here.
