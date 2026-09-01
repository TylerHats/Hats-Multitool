<div align="center">
  <img src="HMTIcon.png" alt="Hat's Multitool Logo" width="150" />
  <h1>Hat's Multitool</h1>
  <p><b>A high-performance, native C# .NET utility for Windows PC setup, optimization, and troubleshooting.</b></p>
</div>

---

**Hat's Multitool** is an open-source, compiled native C# application designed to make setting up new PCs, optimizing current systems, and diagnosing issues as fast and painless as possible. Built directly on .NET WinForms and Win32 APIs, it provides instant startup, smooth dark-themed UI, zero script droppers, and comprehensive sysadmin tools.

*The latest release of this repo is always available at:* [**HatsThings.com/go/Hats-Multitool**](https://hatsthings.com/go/Hats-Multitool)

---

## ✨ Key Features

The multitool is divided into three primary categories, each packed with a robust set of functions.

### 🛠️ PC Setup & Configuration
Automate the tedious parts of Windows setup with built-in modules:
- **Time Zone:** Automatically set or correct the system's time zone and configure reliable NTP servers with auto-sync.
- **Local Accounts:** Easily create or modify local user accounts, set passwords with hold-to-peek toggle, and grant administrator rights.
- **Bloat Cleanup:** Remove common OEM and consumer bloatware (e.g., TikTok, Spotify, McAfee, promotional AppX packages), disable telemetry/diagnostic tracking services, and apply search privacy policies.
- **Programs:** Automate the installation of essential software with WinGet integration and high-speed Microsoft Office 365 Click-to-Run deployment.
- **System Properties & Setup Options:** Rename computers with NetBIOS validation, join domains/EntraID, configure classic Windows 11 context menus, enable hibernation, and optimize power savings.

### 🧰 Built-in Tools & Diagnostics
Access a curated library of essential sysadmin and maintenance utilities directly from the GUI:
- **Storage & Hardware:** SMART Info & Benchmarking, Windows Disk Cleanup, BitLocker Management, and external tool runners (WizTree, CrystalDiskInfo, DDU, HDDScan).
- **Network & Diagnostics:** Internet Speed Test (Cloudflare Anycast), Latency & Packet Loss Monitor, TCP Port Checker, and network stack resets.
- **System Repair:** SFC System File Checker, DISM Image Repair, Check Disk, and Windows Update Component Reset.
- **Viewers & Utilities:** Startup & Autoruns Manager, Reliability Monitor, Battery Report Generator, and OEM ACPI MSDM Product Key reader.

---

## 🚀 Running the Program

Hat's Multitool is a **single, portable, self-contained standalone executable** with **no installation** required.

Download the latest pre-packaged **[Release](https://github.com/TylerHats/Hats-Multitool/releases)**. The executable is portable and self-updating with EV Code Signing.

---

## 📂 Project Structure

- **`Program.cs`**: Main application entry point, Per-Monitor DPI initialization, and module orchestration.
- **`HMTForms.cs`**: Native dark-themed WinForms UI implementations (`MainMenuForm`, `SetupSelectorForm`, `ToolsForm`, `ProgramsForm`, `BloatCleanupForm`, `SpeedTestForm`, `StartupManagerForm`, etc.).
- **`HMTEngines.cs`**: Core background execution engines (`UpdateEngine`, `TimeZoneEngine`, `AccountEngine`, `BloatCleanupEngine`, `ProgramInstallerEngine`, `SetupOptionsEngine`).
- **`HMTNative.cs`**: Low-level Win32 P/Invoke interop library for DPI awareness, window theming, and hardware storage descriptor queries.
- **`HMTTools.cs`**: Custom GDI+ WinForms controls (`DarkButton`, `DarkTextBox`, `DarkTabControl`, `SmoothProgressBar`, `SmoothGraphControl`) and `FastSpeedTestEngine`.
- **`app.manifest`**: Application manifest requesting elevation (`requireAdministrator`) and Per-Monitor V2 DPI awareness.

---

## 📦 Building

To compile the standalone Windows executable from source:

```bash
mcs -target:winexe \
    -platform:anycpu \
    -win32manifest:app.manifest \
    -win32icon:HMTIcon.ico \
    -r:System.Windows.Forms \
    -r:System.Drawing \
    -r:System.IO.Compression \
    -r:System.IO.Compression.FileSystem \
    -r:System.Net.Http \
    -r:System.ServiceProcess \
    -r:System.Management \
    -resource:HMTIcon.png,HMTIcon.png \
    -resource:Splash.png,Splash.png \
    -out:Hats-Multitool.exe \
    HMTNative.cs HMTTools.cs HMTEngines.cs HMTForms.cs Program.cs
```

---

## 📄 License

This codebase is entirely open-source under the **[GPL 3.0 License](LICENSE)**. Feel free to use, modify, and distribute the code as long as it adheres to the license terms.
