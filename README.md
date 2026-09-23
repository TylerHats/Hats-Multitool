<div align="center">
  <img src="HMTIcon.png" alt="Hat's Multitool Logo" width="150" />
  <h1>Hat's Multitool</h1>
  <p><b>A high-performance, native C# .NET utility for Windows PC setup, optimization, and troubleshooting.</b></p>

  <p>
    <a href="https://github.com/TylerHats/Hats-Multitool/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/TylerHats/Hats-Multitool/build.yml?branch=main&style=flat-square&logo=github&label=Build" alt="Build Status" /></a>
    <a href="https://github.com/TylerHats/Hats-Multitool/releases/latest"><img src="https://img.shields.io/github/v/release/TylerHats/Hats-Multitool?style=flat-square&color=blue" alt="Latest Release" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/github/license/TylerHats/Hats-Multitool?style=flat-square&color=success" alt="License" /></a>
    <img src="https://img.shields.io/badge/.NET%20Framework-4.8-512BD4?style=flat-square&logo=dotnet&logoColor=white" alt=".NET 4.8" />
    <img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Platform Windows" />
  </p>
</div>

---

**Hat's Multitool** is an open-source, compiled native C# application designed to make setting up new PCs, optimizing current systems, and diagnosing issues as fast and painless as possible. Built directly on .NET WinForms and Win32 APIs, it provides instant startup, smooth dark-themed UI, zero script droppers, and comprehensive sysadmin tools.

*The latest release of this repo is always available at:* [**HatsThings.com/go/Hats-Multitool**](https://hatsthings.com/go/Hats-Multitool)

---

## ✨ Key Features

The multitool is divided into primary categories, each packed with a robust set of functions.

### 🛠️ PC Setup & Configuration
Automate the tedious parts of Windows setup with built-in modules:
- **Time Zone:** Automatically set or correct the system's time zone and configure reliable NTP servers with auto-sync.
- **Local Accounts:** Easily create or modify local user accounts, set passwords with hold-to-peek toggle, and grant administrator rights.
- **Bloat Cleanup:** Remove common OEM and consumer bloatware (e.g., TikTok, Spotify, McAfee, promotional AppX packages), disable telemetry/diagnostic tracking services, and apply search privacy policies.
- **Programs:** Automate the installation of essential software with WinGet integration and high-speed Microsoft Office 365 Click-to-Run deployment.
- **System Properties & Setup Options:** Rename computers with NetBIOS validation, join domains/EntraID, configure classic Windows 11 context menus, enable hibernation, and optimize power savings.

### 🧰 Built-in Tools & Diagnostics
Access a curated library of essential sysadmin and maintenance utilities directly from the GUI:
- **Storage & Hardware:** SMART Info & Benchmarking, Windows Disk Cleanup, BitLocker Management, and on-demand tool runners (WizTree, CrystalDiskInfo, DDU, HDDScan).
- **Network & Diagnostics:** Internet Speed Test (Cloudflare Anycast), Latency & Packet Loss Monitor, TCP Port Checker, and network stack resets.
- **System Repair:** SFC System File Checker, DISM Image Repair, Check Disk, and Windows Update Component Reset (all running in standalone elevated console windows that pause before closing).
- **Viewers & Utilities:** Startup & Autoruns Manager, Reliability Monitor, Battery Report Generator, and OEM ACPI MSDM Product Key reader.

---

## 🚀 Running the Program

Hat's Multitool is a **single, portable, self-contained standalone executable** with **no installation** required.

### Option 1: PowerShell Quick Launch (Recommended)
Open PowerShell as Administrator and run:
```powershell
irm mt.htsth.app | iex
```
> [!NOTE]
> The PowerShell one-liner automatically runs the program in **temporary mode** (`--cleanup-on-exit`). It downloads the latest signed release directly into your Downloads folder and launches it. Once you close the application, the executable and any temporary payload files are automatically deleted, leaving zero footprint on the machine.

### Option 2: Standalone Executable
Download the latest pre-packaged **[Release](https://github.com/TylerHats/Hats-Multitool/releases)**. The executable is portable and self-updating with Authenticode Code Signing.

### Command-Line Flags
| Flag | Description |
| :--- | :--- |
| `--cleanup-on-exit` / `--temp-run` | Automatically deletes the executable and purges `%LOCALAPPDATA%\HMT\ExtPrograms` when the program is closed. Ideal for technicians servicing customer machines. |

---

## 📂 Project Structure

- **`Program.cs`**: Main application entry point, Per-Monitor DPI initialization, and module orchestration.
- **`HMTForms.cs`**: Native dark-themed WinForms UI implementations (`MainMenuForm`, `SetupSelectorForm`, `ToolsForm`, `ProgramsForm`, `BloatCleanupForm`, `SpeedTestForm`, `StartupManagerForm`, etc.).
- **`HMTEngines.cs`**: Core background execution engines (`UpdateEngine`, `TimeZoneEngine`, `AccountEngine`, `BloatCleanupEngine`, `ProgramInstallerEngine`, `SetupOptionsEngine`, and dynamic catalog resolver).
- **`HMTNative.cs`**: Low-level Win32 P/Invoke interop library for DPI awareness, window theming, hardware storage queries, and in-memory cleanup.
- **`HMTTools.cs`**: Custom GDI+ WinForms controls (`DarkButton`, `DarkTextBox`, `DarkTabControl`, `SmoothProgressBar`, `SmoothGraphControl`) and `FastSpeedTestEngine`.
- **`ExternalTools.json`**: Dynamic remote tools catalog fetched on-demand at runtime.
- **`OneLineRun.ps1`**: Web downloader and bootstrap runner script for seamless one-liner execution.
- **`app.manifest`**: Application manifest requesting elevation (`requireAdministrator`) and Per-Monitor V2 DPI awareness.
- **`HatsMultitool.csproj`**: Modern SDK-style project file targeting .NET Framework 4.8 via `Microsoft.NETFramework.ReferenceAssemblies`.

---

## 📦 Building

To compile the standalone Windows executable from source using the .NET SDK:

```bash
dotnet build HatsMultitool.csproj -c Release -p:Version=6.3.5
```

The resulting standalone executable will be located at:
`bin/Release/net48/Hats-Multitool.exe`

---

## 📄 License

This codebase is entirely open-source under the **[GPL 3.0 License](LICENSE)**. Feel free to use, modify, and distribute the code as long as it adheres to the license terms.
