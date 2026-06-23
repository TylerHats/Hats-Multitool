<div align="center">
  <img src="HMTIcon.png" alt="Hat's Multitool Logo" width="150" />
  <h1>Hat's Multitool</h1>
  <p><b>A powerful, modular PowerShell utility for Windows PC setup, optimization, and troubleshooting.</b></p>
</div>

---

**Hat's Multitool** is an open-source, PowerShell-based application designed to make setting up new PCs, optimizing current systems, and diagnosing issues as fast and painless as possible. Whether you are an IT professional deploying machines or a power user tweaking your personal rig, Hat's Multitool has you covered.

*The latest release of this repo is always available at:* [**HatsThings.com/go/Hats-Multitool**](https://hatsthings.com/go/Hats-Multitool)

---

## ✨ Key Features

The multitool is divided into three primary categories, each packed with a robust set of functions.

### 🛠️ PC Setup & Configuration
Automate the tedious parts of Windows setup with built-in modules:
- **Time Zone:** Automatically set or correct the system's time zone.
- **Local Accounts:** Easily create or modify local user accounts.
- **Bloat Cleanup:** Remove common OEM and consumer bloatware (e.g., McAfee, TikTok, pre-installed promotional apps) to keep Windows clean.
- **Programs:** Automate the installation of essential software.
- **System Properties & Setup Options:** Tweak Windows settings for maximum performance and usability.

### 🧰 Built-in Tools
Access a curated library of essential sysadmin and maintenance utilities directly from the GUI:
- **System & Drive Utilities:** WizTree, Windows Disk Cleanup, Patch Cleaner, DISM++, BleachBit, HDDScan, Crystal Disk Mark, Crystal Disk Info.
- **Driver & Profile Management:** Display Driver Uninstaller (DDU), User Profile Wizard, Hat's User Move Tool.
- **Uninstaller & Removal Tools:** McAfee MCPR Tool, Ninja Removal Script.
- **Misc Tools:** BlueScreenView, Little Registry Cleaner, .NET 3.5 Installer, Windows 11 Upgrade Assistant.

### 🚑 Troubleshooting
Quickly run diagnostic commands and system fixes with a single click:
- **System Repair:** Run Check Disk (Read Only), DISM Repair, and SFC Repair.
- **Network Reset:** Flush DNS, release/renew IP, and clear the ARP cache.
- **Diagnostic Reports:** Generate a detailed Battery Report or launch the Windows Reliability Monitor.
- **Fixes:** Easily enable Safe Boot (with Networking) or restart a frozen Windows Explorer.

---

## 🚀 Running the Program

Hat's Multitool requires **no installation**. You can run it immediately in two ways:

### 1. PowerShell One-Liner
Open a standard PowerShell console (no elevation needed) and run the following command to download and execute the latest version automatically:

```powershell
IRM MT.HTSTH.APP | IEX
```

### 2. Standalone Executable
Download the latest pre-packaged **[Release](https://github.com/TylerHats/Hats-Multitool/releases)**. The executable is portable and self-updating, so you never have to redownload it to get the newest features!

---

## 📂 Project Structure

If you're interested in how it works under the hood, here's a breakdown of the core files:

- **`Core.ps1`**: The brain of the operation. This script prepares the environment, handles DPI scaling, initializes WinForms, and coordinates the modules.
- **`Common.ps1`**: A library of shared variables and helper functions used throughout the other scripts.
- **`GUIs.ps1`**: Contains the code for all the graphical interfaces, from the main menu to the tools and troubleshooting windows.
- **`[Module].ps1`**: Individual scripts (like `BloatCleanup.ps1` or `SystemManagement.ps1`) that handle specific tasks chosen by the user.
- **`HMTNative.cs` / `HMTNative.dll`**: A C# library compiled into a DLL via P/Invoke. It allows the PowerShell scripts to utilize advanced UI controls beyond standard WinForms capabilities.

---

## 📦 Packaging & Building

***[Releases](https://github.com/TylerHats/Hats-Multitool/releases)*** are packaged executables based on the codebase at the time of creation.

These executables are currently built using **NSIS** as simple, silent, self-extracting archives that launch the main `Core.ps1` file. Since version 3.7.4, C# methods are compiled into a DLL (`HMTNative.dll`) using Mono-MCS during the build process.

**To package the project yourself:**
1. Compile `HMTNative.cs` into `HMTNative.dll` and ensure it is in the root directory alongside the `.ps1` files and icons.
2. Using your preferred archiving software (like NSIS or 7-Zip SFX), pack the repository files into a self-extracting archive.
3. Set the archive to extract silently and execute the following command upon extraction:
   ```cmd
   PowerShell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "Core.ps1" -WindowStyle Minimized
   ```
   *(Note: If you are not code-signing the PS1 files, use `-ExecutionPolicy Bypass` instead of `RemoteSigned`)*

---

## 🐛 Issues & Feedback

Collaboration, bug reports, and feature requests are highly encouraged! 

Please drop any reports or ideas on the **[Issues](https://github.com/TylerHats/Hats-Multitool/issues)** page. Every issue will be reviewed and researched. Even if a feature cannot be implemented, a detailed explanation will be provided before the request is closed.

---

## 📄 License

This codebase is entirely open-source under the **[GPL 3.0 License](LICENSE)**. Feel free to use, modify, and distribute the code as long as it adheres to the license terms.

*(Note: While the multitool downloads and runs various third-party and closed-source tools, those tools are governed by their respective owners and licenses, and their code is not maintained within this repository.)*
