using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Management;
using System.Net;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32;

namespace HMT.Engines {
    // --- Logging & Notification ---
    public static class Logger {
        public static event Action<string, string> OnLogMessage;

        public static void Log(string message, string level = "Info") {
            try {
                OnLogMessage?.Invoke(message, level);
            } catch { }
            Debug.WriteLine(string.Format("[{0}] [{1}] {2}", DateTime.Now.ToString("HH:mm:ss"), level, message));
        }
    }

    // --- Update Engine ---
    public static class UpdateEngine {
        public const string RemoteVersionUrl = "https://hatsthings.com/MultitoolFiles/HatsMultitoolVersion.txt";
        public const string ReleaseDownloadBase = "https://github.com/TylerHats/Hats-Multitool/releases/download/v{0}/Hats-Multitool-v{0}.exe";

        public static async Task<Version> CheckRemoteVersionAsync() {
            try {
                using (var client = new HttpClient()) {
                    client.DefaultRequestHeaders.UserAgent.ParseAdd("Hats-Multitool");
                    client.Timeout = TimeSpan.FromSeconds(5);
                    string verStr = (await client.GetStringAsync(RemoteVersionUrl)).Trim();
                    Version v;
                    if (Version.TryParse(verStr, out v)) {
                        return v;
                    }
                }
            } catch (Exception ex) {
                Logger.Log("Remote version check failed: " + ex.Message, "Warning");
            }
            return null;
        }

        public static async Task<bool> DownloadUpdateAsync(Version remoteVersion, string destinationPath, IProgress<int> progress = null) {
            try {
                string downloadUrl = string.Format(ReleaseDownloadBase, remoteVersion.ToString());
                using (var client = new HttpClient()) {
                    client.DefaultRequestHeaders.UserAgent.ParseAdd("Hats-Multitool");
                    client.Timeout = TimeSpan.FromMinutes(5);
                    using (var response = await client.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead)) {
                        response.EnsureSuccessStatusCode();
                        long totalBytes = response.Content.Headers.ContentLength ?? -1L;
                        using (var stream = await response.Content.ReadAsStreamAsync())
                        using (var fileStream = new FileStream(destinationPath, FileMode.Create, FileAccess.Write, FileShare.None, 65536, true)) {
                            byte[] buffer = new byte[65536];
                            long totalRead = 0;
                            int read;
                            while ((read = await stream.ReadAsync(buffer, 0, buffer.Length)) > 0) {
                                await fileStream.WriteAsync(buffer, 0, read);
                                totalRead += read;
                                if (totalBytes > 0 && progress != null) {
                                    int pct = (int)((totalRead * 100) / totalBytes);
                                    progress.Report(pct);
                                }
                            }
                        }
                    }
                }
                return true;
            } catch (Exception ex) {
                Logger.Log("Download update failed: " + ex.Message, "Error");
                return false;
            }
        }
    }

    // --- Time Zone Engine ---
    public static class TimeZoneEngine {
        public static List<string> GetAvailableTimeZones() {
            var list = new List<string>();
            try {
                foreach (var tz in TimeZoneInfo.GetSystemTimeZones()) {
                    list.Add(tz.Id);
                }
            } catch { }
            return list;
        }

        public static string GetCurrentTimeZoneId() {
            try {
                return TimeZoneInfo.Local.Id;
            } catch {
                return "Eastern Standard Time";
            }
        }

        public static void SetTimeZone(string timeZoneId) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "tzutil.exe",
                    Arguments = string.Format("/s \"{0}\"", timeZoneId),
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit(5000);
                }
                Logger.Log("Set Time Zone to: " + timeZoneId, "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to set time zone: " + ex.Message, "Error");
            }
        }

        public static void ConfigureNtpAndSync() {
            try {
                using (var key = Registry.LocalMachine.CreateSubKey(@"SYSTEM\CurrentControlSet\Services\W32Time\Parameters")) {
                    if (key != null) {
                        key.SetValue("NtpServer", "pool.ntp.org,0x1 time.windows.com,0x1", RegistryValueKind.String);
                        key.SetValue("Type", "NTP", RegistryValueKind.String);
                    }
                }

                try {
                    using (var sc = new ServiceController("W32Time")) {
                        if (sc.Status != ServiceControllerStatus.Running) {
                            sc.Start();
                            sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(5));
                        }
                    }
                } catch { }

                var psi = new ProcessStartInfo {
                    FileName = "w32tm.exe",
                    Arguments = "/resync /nowait",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit(4000);
                }
                Logger.Log("Configured NTP servers and initiated clock sync.", "Success");
            } catch (Exception ex) {
                Logger.Log("NTP sync failed: " + ex.Message, "Warning");
            }
        }
    }

    // --- Local Accounts Engine ---
    public static class AccountEngine {
        public static int GetMinimumPasswordLength() {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = "accounts",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true
                };
                using (var proc = Process.Start(psi)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();
                    var match = Regex.Match(output, @"Minimum password length\s+(\d+)");
                    if (match.Success) {
                        int len;
                        if (int.TryParse(match.Groups[1].Value, out len)) {
                            return len;
                        }
                    }
                }
            } catch { }
            return 0;
        }

        public static bool CreateUser(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = string.Format("user \"{0}\" \"{1}\" /add /y", username, password),
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) return false;
                }

                if (isAdmin) {
                    var psiAdmin = new ProcessStartInfo {
                        FileName = "net.exe",
                        Arguments = string.Format("localgroup Administrators \"{0}\" /add", username),
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    using (var procAdmin = Process.Start(psiAdmin)) {
                        procAdmin.WaitForExit();
                    }
                }

                if (isDontExpire) {
                    var psiExpire = new ProcessStartInfo {
                        FileName = "net.exe",
                        Arguments = string.Format("user \"{0}\" /expires:never", username),
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    using (var procExp = Process.Start(psiExpire)) {
                        procExp.WaitForExit();
                    }
                }

                if (isAutoLogin) {
                    SetAutoLogon(username, password);
                }

                Logger.Log("Successfully created user: " + username, "Success");
                return true;
            } catch (Exception ex) {
                Logger.Log("User creation failed: " + ex.Message, "Error");
                return false;
            }
        }

        public static bool UpdateUserPassword(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = string.Format("user \"{0}\" \"{1}\"", username, password),
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) return false;
                }

                if (isAdmin) {
                    var psiAdmin = new ProcessStartInfo {
                        FileName = "net.exe",
                        Arguments = string.Format("localgroup Administrators \"{0}\" /add", username),
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    using (var procAdmin = Process.Start(psiAdmin)) {
                        procAdmin.WaitForExit();
                    }
                }

                if (isAutoLogin) {
                    SetAutoLogon(username, password);
                }

                Logger.Log("Successfully updated password for: " + username, "Success");
                return true;
            } catch (Exception ex) {
                Logger.Log("Password update failed: " + ex.Message, "Error");
                return false;
            }
        }

        private static void SetAutoLogon(string username, string password) {
            try {
                using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon")) {
                    if (key != null) {
                        key.SetValue("AutoAdminLogon", "1", RegistryValueKind.String);
                        key.SetValue("DefaultUserName", username, RegistryValueKind.String);
                        key.SetValue("DefaultPassword", password, RegistryValueKind.String);
                    }
                }
            } catch { }
        }
    }

    // --- System Properties Engine ---
    public static class SystemPropertiesEngine {
        public static string GetCurrentComputerName() {
            return Environment.MachineName;
        }

        public static string GetSerialNumber() {
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_BIOS")) {
                    foreach (ManagementObject obj in searcher.Get()) {
                        string serial = obj["SerialNumber"]?.ToString();
                        if (!string.IsNullOrEmpty(serial)) return serial.Trim();
                    }
                }
            } catch { }
            return "Unknown";
        }

        public static string GetWindowsEdition() {
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT Caption FROM Win32_OperatingSystem")) {
                    foreach (ManagementObject obj in searcher.Get()) {
                        string caption = obj["Caption"]?.ToString();
                        if (!string.IsNullOrEmpty(caption)) return caption.Trim();
                    }
                }
            } catch { }
            return "Windows";
        }

        public static bool IsDomainJoined(out string domainName) {
            domainName = string.Empty;
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT PartOfDomain, Domain FROM Win32_ComputerSystem")) {
                    foreach (ManagementObject obj in searcher.Get()) {
                        bool partOfDomain = (bool)(obj["PartOfDomain"] ?? false);
                        domainName = obj["Domain"]?.ToString() ?? "";
                        return partOfDomain;
                    }
                }
            } catch { }
            return false;
        }

        public static bool RenameComputer(string newName) {
            try {
                using (var obj = new ManagementObject(string.Format("Win32_ComputerSystem.Name='{0}'", Environment.MachineName))) {
                    var inParams = obj.GetMethodParameters("Rename");
                    inParams["Name"] = newName;
                    var outParams = obj.InvokeMethod("Rename", inParams, null);
                    uint ret = (uint)(outParams["ReturnValue"] ?? 1);
                    return ret == 0;
                }
            } catch {
                try {
                    var psi = new ProcessStartInfo {
                        FileName = "wmic.exe",
                        Arguments = string.Format("computersystem where caption='{0}' rename '{1}'", Environment.MachineName, newName),
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    using (var proc = Process.Start(psi)) {
                        proc.WaitForExit();
                        return proc.ExitCode == 0;
                    }
                } catch {
                    return false;
                }
            }
        }

        public static void UpgradeToProEdition(string productKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T") {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "changepk.exe",
                    Arguments = "/ProductKey " + productKey,
                    UseShellExecute = true
                };
                Process.Start(psi);
            } catch (Exception ex) {
                Logger.Log("Failed to start edition upgrade: " + ex.Message, "Error");
            }
        }
    }

    // --- Setup Options Engine ---
    public static class SetupOptionsEngine {
        public static void SetNumLockOn() {
            try {
                using (var key = Registry.Users.CreateSubKey(@".DEFAULT\Control Panel\Keyboard")) {
                    if (key != null) key.SetValue("InitialKeyboardIndicators", "2", RegistryValueKind.String);
                }
                using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Keyboard")) {
                    if (key != null) key.SetValue("InitialKeyboardIndicators", "2", RegistryValueKind.String);
                }
                Logger.Log("Enabled NumLock on boot.", "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to set NumLock: " + ex.Message, "Warning");
            }
        }

        public static void SetClassicWin11ContextMenu() {
            try {
                using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32")) {
                    if (key != null) key.SetValue("", "", RegistryValueKind.String);
                }
                Logger.Log("Enabled classic Windows 11 context menu.", "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to set classic context menu: " + ex.Message, "Warning");
            }
        }

        public static void DisableHelloPinReminder() {
            try {
                using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System")) {
                    if (key != null) key.SetValue("DisablePostLogonProvisioning", 1, RegistryValueKind.DWord);
                }
                Logger.Log("Disabled Hello PIN setup reminder.", "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to disable PIN reminder: " + ex.Message, "Warning");
            }
        }

        public static void DisableAspmPowerSaving() {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "powercfg.exe",
                    Arguments = "/setacvalueindex scheme_current sub_pci express 0",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                }
                var psiActive = new ProcessStartInfo {
                    FileName = "powercfg.exe",
                    Arguments = "/setactive scheme_current",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psiActive)) {
                    proc.WaitForExit();
                }
                Logger.Log("Disabled PCIe ASPM power saving.", "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to disable ASPM: " + ex.Message, "Warning");
            }
        }

        public static void DisableStickyKeysPrompt() {
            try {
                using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Accessibility\StickyKeys")) {
                    if (key != null) key.SetValue("Flags", "506", RegistryValueKind.String);
                }
                Logger.Log("Disabled Sticky Keys keyboard shortcut prompt.", "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to disable sticky keys: " + ex.Message, "Warning");
            }
        }

        public static void EnableHibernation() {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "powercfg.exe",
                    Arguments = "/hibernate on",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                }
                Logger.Log("Enabled Windows Hibernation.", "Success");
            } catch (Exception ex) {
                Logger.Log("Failed to enable hibernation: " + ex.Message, "Warning");
            }
        }

        public static void ApplyOption(string tag) {
            switch (tag) {
                case "numlock":
                    SetNumLockOn();
                    break;
                case "classic_context":
                    SetClassicWin11ContextMenu();
                    break;
                case "disable_pin":
                    DisableHelloPinReminder();
                    break;
                case "disable_aspm":
                    DisableAspmPowerSaving();
                    break;
                case "disable_sticky":
                    DisableStickyKeysPrompt();
                    break;
                case "enable_hibernation":
                    EnableHibernation();
                    break;
            }
        }
    }

    // --- Bloat Cleanup Engine ---
    public class BloatProgressInfo {
        public string Status { get; set; }
        public string Detail { get; set; }
        public int ProgressPercentage { get; set; }
    }

    public static class BloatCleanupEngine {
        private static readonly string[] BloatApps = new string[] {
            "*Spotify*", "*TikTok*", "*Disney*", "*Clipchamp*", "*McAfee*", "*Norton*", "*Instagram*",
            "*Facebook*", "*PrimeVideo*", "*Netflix*", "*LinkedIn*", "*Twitter*", "*Pandora*",
            "*CandyCrush*", "*Dolby*", "*Dropbox*", "*Grammarly*", "*Evernote*", "*WhatsApp*",
            "*Microsoft.BingNews*", "*Microsoft.BingWeather*", "*Microsoft.GetHelp*", "*Microsoft.Getstarted*",
            "*Microsoft.MicrosoftSolitaireCollection*", "*Microsoft.People*", "*Microsoft.PowerAutomateDesktop*",
            "*Microsoft.Todos*", "*Microsoft.YourPhone*", "*Microsoft.ZuneVideo*", "*Microsoft.ZuneMusic*"
        };

        public static async Task ExecuteBloatCleanupAsync(IProgress<BloatProgressInfo> progress) {
            await Task.Run(() => {
                try {
                    progress?.Report(new BloatProgressInfo {
                        Status = "Starting Bloatware Removal...",
                        Detail = "Scanning installed AppX packages...",
                        ProgressPercentage = 5
                    });

                    // 1. Remove AppX Packages
                    int total = BloatApps.Length;
                    for (int i = 0; i < total; i++) {
                        string appPattern = BloatApps[i];
                        progress?.Report(new BloatProgressInfo {
                            Status = "Removing AppX Bloatware...",
                            Detail = string.Format("Cleaning {0} ({1}/{2})...", appPattern.Replace("*", ""), i + 1, total),
                            ProgressPercentage = 10 + (int)((i * 55) / total)
                        });

                        try {
                            var psi = new ProcessStartInfo {
                                FileName = "powershell.exe",
                                Arguments = string.Format("-NoProfile -NonInteractive -Command \"Get-AppxPackage -Name '{0}' -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like '{0}' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue\"", appPattern),
                                CreateNoWindow = true,
                                UseShellExecute = false
                            };
                            using (var proc = Process.Start(psi)) {
                                proc.WaitForExit(8000);
                            }
                        } catch { }
                    }

                    // 2. Disable Telemetry Services
                    progress?.Report(new BloatProgressInfo {
                        Status = "Optimizing Services...",
                        Detail = "Disabling telemetry and diagnostic tracking services...",
                        ProgressPercentage = 70
                    });

                    string[] services = new string[] { "DiagTrack", "dmwappushservice" };
                    foreach (var s in services) {
                        try {
                            using (var sc = new ServiceController(s)) {
                                if (sc.Status == ServiceControllerStatus.Running) sc.Stop();
                            }
                            var psi = new ProcessStartInfo {
                                FileName = "sc.exe",
                                Arguments = "config " + s + " start= disabled",
                                CreateNoWindow = true,
                                UseShellExecute = false
                            };
                            using (var proc = Process.Start(psi)) {
                                proc.WaitForExit(3000);
                            }
                        } catch { }
                    }

                    // 3. Apply Registry Tweaks (Bing Search, Advertising ID)
                    progress?.Report(new BloatProgressInfo {
                        Status = "Applying Privacy Policies...",
                        Detail = "Disabling Start Menu web search & Advertising ID...",
                        ProgressPercentage = 85
                    });

                    try {
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Policies\Microsoft\Windows\Explorer")) {
                            if (key != null) key.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
                            if (key != null) key.SetValue("Enabled", 0, RegistryValueKind.DWord);
                        }
                    } catch { }

                    progress?.Report(new BloatProgressInfo {
                        Status = "Bloat Cleanup Complete!",
                        Detail = "All selected bloatware and telemetry services have been optimized.",
                        ProgressPercentage = 100
                    });

                    Thread.Sleep(500);
                } catch (Exception ex) {
                    Logger.Log("Bloat cleanup error: " + ex.Message, "Error");
                }
            });
        }
    }

    // --- Programs & Software Installer Engine ---
    public class SoftwareItem {
        public string Name { get; set; }
        public string Category { get; set; }
        public string WingetID { get; set; }
        public string Type { get; set; } // "Winget", "MSOffice", "MSOutlook"

        public SoftwareItem(string name, string category, string wingetId, string type = "Winget") {
            Name = name;
            Category = category;
            WingetID = wingetId;
            Type = type;
        }
    }

    public static class ProgramInstallerEngine {
        public static Dictionary<string, List<SoftwareItem>> GetCategorizedCatalog() {
            var cat = new Dictionary<string, List<SoftwareItem>>();

            // Browsers & Comms
            cat["Browsers & Comms"] = new List<SoftwareItem> {
                new SoftwareItem("Google Chrome", "Browsers & Comms", "Google.Chrome"),
                new SoftwareItem("Mozilla Firefox", "Browsers & Comms", "Mozilla.Firefox"),
                new SoftwareItem("Brave Browser", "Browsers & Comms", "Brave.Brave"),
                new SoftwareItem("Discord", "Browsers & Comms", "Discord.Discord"),
                new SoftwareItem("Microsoft Teams", "Browsers & Comms", "Microsoft.Teams"),
                new SoftwareItem("Zoom", "Browsers & Comms", "Zoom.Zoom"),
                new SoftwareItem("Slack", "Browsers & Comms", "SlackTechnologies.Slack"),
                new SoftwareItem("Telegram Desktop", "Browsers & Comms", "Telegram.TelegramDesktop"),
                new SoftwareItem("Mozilla Thunderbird", "Browsers & Comms", "Mozilla.Thunderbird")
            };

            // Productivity
            cat["Productivity"] = new List<SoftwareItem> {
                new SoftwareItem("7-Zip", "Productivity", "7zip.7zip"),
                new SoftwareItem("WinRAR", "Productivity", "RARLab.WinRAR"),
                new SoftwareItem("Notepad++", "Productivity", "Notepad++.Notepad++"),
                new SoftwareItem("Adobe Acrobat Reader", "Productivity", "Adobe.Acrobat.Reader.64-bit"),
                new SoftwareItem("Adobe Creative Cloud", "Productivity", "Adobe.CreativeCloud"),
                new SoftwareItem("Microsoft Office (64-Bit)", "Productivity", "", "MSOffice"),
                new SoftwareItem("Outlook Classic", "Productivity", "", "MSOutlook"),
                new SoftwareItem("LibreOffice", "Productivity", "TheDocumentFoundation.LibreOffice"),
                new SoftwareItem("Microsoft PowerToys", "Productivity", "Microsoft.PowerToys"),
                new SoftwareItem("Everything Search", "Productivity", "voidtools.Everything"),
                new SoftwareItem("ShareX", "Productivity", "ShareX.ShareX"),
                new SoftwareItem("Greenshot", "Productivity", "Greenshot.Greenshot")
            };

            // IT & Dev Tools
            cat["IT & Dev Tools"] = new List<SoftwareItem> {
                new SoftwareItem("Visual Studio Code", "IT & Dev Tools", "Microsoft.VisualStudioCode"),
                new SoftwareItem("Git for Windows", "IT & Dev Tools", "Git.Git"),
                new SoftwareItem("Python 3.12", "IT & Dev Tools", "Python.Python.3.12"),
                new SoftwareItem("Node.js LTS", "IT & Dev Tools", "OpenJS.NodeJS.LTS"),
                new SoftwareItem("Windows Terminal", "IT & Dev Tools", "Microsoft.WindowsTerminal"),
                new SoftwareItem("PuTTY", "IT & Dev Tools", "PuTTY.PuTTY"),
                new SoftwareItem("WinSCP", "IT & Dev Tools", "WinSCP.WinSCP"),
                new SoftwareItem("Wireshark", "IT & Dev Tools", "WiresharkFoundation.Wireshark"),
                new SoftwareItem("Twingate Client", "IT & Dev Tools", "Twingate.Client"),
                new SoftwareItem("Tailscale", "IT & Dev Tools", "Tailscale.Tailscale"),
                new SoftwareItem("AnyDesk", "IT & Dev Tools", "AnyDeskSoftwareGmbH.AnyDesk"),
                new SoftwareItem("TeamViewer", "IT & Dev Tools", "TeamViewer.TeamViewer")
            };

            // Media & Design
            cat["Media & Design"] = new List<SoftwareItem> {
                new SoftwareItem("VLC Media Player", "Media & Design", "VideoLAN.VLC"),
                new SoftwareItem("Spotify", "Media & Design", "Spotify.Spotify"),
                new SoftwareItem("OBS Studio", "Media & Design", "OBSProject.OBSStudio"),
                new SoftwareItem("Audacity", "Media & Design", "Audacity.Audacity"),
                new SoftwareItem("HandBrake", "Media & Design", "HandBrake.HandBrake"),
                new SoftwareItem("GIMP", "Media & Design", "GIMP.GIMP"),
                new SoftwareItem("Inkscape", "Media & Design", "Inkscape.Inkscape"),
                new SoftwareItem("K-Lite Codec Pack Mega", "Media & Design", "CodecGuide.K-LiteCodecPack.Mega")
            };

            // Cloud & Gaming
            cat["Cloud & Gaming"] = new List<SoftwareItem> {
                new SoftwareItem("Google Drive", "Cloud & Gaming", "Google.Drive"),
                new SoftwareItem("Dropbox", "Cloud & Gaming", "Dropbox.Dropbox"),
                new SoftwareItem("Steam", "Cloud & Gaming", "Valve.Steam"),
                new SoftwareItem("Epic Games Launcher", "Cloud & Gaming", "EpicGames.EpicGamesLauncher"),
                new SoftwareItem("GOG Galaxy", "Cloud & Gaming", "GOG.Galaxy"),
                new SoftwareItem("CPUID HWMonitor", "Cloud & Gaming", "CPUID.HWMonitor"),
                new SoftwareItem("CPUID CPU-Z", "Cloud & Gaming", "CPUID.CPU-Z"),
                new SoftwareItem("TechPowerUp GPU-Z", "Cloud & Gaming", "TechPowerUp.GPU-Z"),
                new SoftwareItem("MSI Afterburner", "Cloud & Gaming", "Guru3D.Afterburner")
            };

            return cat;
        }

        public static HashSet<string> GetInstalledDisplayNames() {
            var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            try {
                string[] uninstallKeys = new string[] {
                    @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                    @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                };
                foreach (var rootKey in new RegistryKey[] { Registry.LocalMachine, Registry.CurrentUser }) {
                    foreach (var sub in uninstallKeys) {
                        try {
                            using (var key = rootKey.OpenSubKey(sub, false)) {
                                if (key != null) {
                                    foreach (var appSubName in key.GetSubKeyNames()) {
                                        try {
                                            using (var appKey = key.OpenSubKey(appSubName, false)) {
                                                if (appKey != null) {
                                                    var dn = appKey.GetValue("DisplayName") as string;
                                                    if (!string.IsNullOrEmpty(dn)) set.Add(dn);
                                                }
                                            }
                                        } catch { }
                                    }
                                }
                            }
                        } catch { }
                    }
                }
            } catch { }
            return set;
        }

        public static bool IsProgramInstalled(SoftwareItem item, HashSet<string> installedSet) {
            if (item == null || installedSet == null) return false;
            string pName = item.Name;
            foreach (var dn in installedSet) {
                if (dn.IndexOf(pName, StringComparison.OrdinalIgnoreCase) >= 0) return true;
            }
            if (!string.IsNullOrEmpty(item.WingetID)) {
                string[] parts = item.WingetID.Split(new char[] { '.' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts != null && parts.Length > 0) {
                    string tail = parts[parts.Length - 1];
                    if (tail.Length >= 4) {
                        foreach (var dn in installedSet) {
                            if (dn.IndexOf(tail, StringComparison.OrdinalIgnoreCase) >= 0) return true;
                        }
                    }
                }
            }
            return false;
        }

        public static async Task DeployOfficeAsync(bool isAll, IProgress<BloatProgressInfo> progress, CancellationToken ct) {
            string productID = isAll ? "O365BusinessRetail" : "OutlookRetail";
            string displayName = isAll ? "Microsoft Office (x64)" : "Outlook (Classic)";
            string extDir = ExternalToolsEngine.GetExtProgramDir();
            string officeDir = Path.Combine(extDir, "MicrosoftOffice");
            string zipName = "o365_payload.zip";
            string zipPath = Path.Combine(extDir, zipName);
            string cdnUrl = "https://cdn.hatsthings.com/O365/" + zipName;

            if (!Directory.Exists(officeDir)) {
                Directory.CreateDirectory(officeDir);
            }

            // Check if Office\Data and setup.exe are already unpacked
            bool existingData = Directory.Exists(Path.Combine(officeDir, "Office", "Data"));
            bool existingSetup = File.Exists(Path.Combine(officeDir, "setup.exe"));

            if (existingData && existingSetup) {
                progress?.Report(new BloatProgressInfo {
                    Status = "Found local " + displayName + " payload...",
                    Detail = "Using existing decompressed payload in ExtPrograms\\MicrosoftOffice...",
                    ProgressPercentage = 85
                });
            } else {
                // Download office payload from CDN with authentication token
                if (!File.Exists(zipPath)) {
                    progress?.Report(new BloatProgressInfo {
                        Status = "Starting " + displayName + " download...",
                        Detail = "Connecting to CDN...",
                        ProgressPercentage = 10
                    });

                    using (var handler = new HttpClientHandler { AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate })
                    using (var client = new HttpClient(handler)) {
                        client.Timeout = TimeSpan.FromMinutes(30);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0");
                        client.DefaultRequestHeaders.Add("X-HMT-Token", "HMTDAT1");

                        using (var response = await client.GetAsync(cdnUrl, HttpCompletionOption.ResponseHeadersRead, ct)) {
                            response.EnsureSuccessStatusCode();
                            long totalBytes = response.Content.Headers.ContentLength ?? -1L;

                            using (var stream = await response.Content.ReadAsStreamAsync())
                            using (var fileStream = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None, 1048576, true)) {
                                byte[] buffer = new byte[1048576];
                                long totalRead = 0;
                                int read;
                                var sw = Stopwatch.StartNew();

                                while ((read = await stream.ReadAsync(buffer, 0, buffer.Length, ct)) > 0) {
                                    await fileStream.WriteAsync(buffer, 0, read, ct);
                                    totalRead += read;

                                    if (sw.ElapsedMilliseconds > 150) {
                                        sw.Restart();
                                        double mbRead = Math.Round(totalRead / 1048576.0, 1);
                                        double mbTotal = Math.Round(totalBytes / 1048576.0, 1);
                                        int pct = totalBytes > 0 ? (int)((totalRead * 70) / totalBytes) + 10 : 50;
                                        progress?.Report(new BloatProgressInfo {
                                            Status = "Downloading " + displayName + "...",
                                            Detail = string.Format("{0} MB / {1} MB downloaded", mbRead, mbTotal),
                                            ProgressPercentage = pct
                                        });
                                    }
                                }
                            }
                        }
                    }
                }

                progress?.Report(new BloatProgressInfo {
                    Status = "Extracting " + displayName + " payload...",
                    Detail = "Unpacking payload files...",
                    ProgressPercentage = 85
                });

                await Task.Run(() => {
                    try {
                        ZipFile.ExtractToDirectory(zipPath, officeDir);
                    } catch { }
                });
            }

            // Generate configuration.xml
            string setupExe = Path.Combine(officeDir, "setup.exe");
            string xmlPath = Path.Combine(officeDir, "configuration.xml");
            string xmlContent = string.Format(
                "<Configuration>\n  <Add SourcePath=\"{0}\" OfficeClientEdition=\"64\" Channel=\"Current\">\n    <Product ID=\"{1}\">\n      <Language ID=\"en-us\" />\n    </Product>\n  </Add>\n  <Display Level=\"Full\" AcceptEULA=\"TRUE\" />\n  <Property Name=\"AUTOACTIVATE\" Value=\"0\" />\n</Configuration>",
                officeDir,
                productID
            );
            File.WriteAllText(xmlPath, xmlContent, Encoding.UTF8);

            progress?.Report(new BloatProgressInfo {
                Status = "Launching " + displayName + " setup...",
                Detail = "Starting Office Click-to-Run installer...",
                ProgressPercentage = 95
            });

            var psiSetup = new ProcessStartInfo {
                FileName = setupExe,
                Arguments = "/configure \"" + xmlPath + "\"",
                WorkingDirectory = officeDir,
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true
            };
            Process.Start(psiSetup);

            progress?.Report(new BloatProgressInfo {
                Status = "Launched: " + displayName,
                Detail = "Office Click-to-Run setup is running in the background.",
                ProgressPercentage = 100
            });
        }

        public static async Task InstallWingetPackageAsync(string wingetId, IProgress<string> statusCallback, CancellationToken ct) {
            await Task.Run(() => {
                try {
                    statusCallback?.Report("Installing " + wingetId + " via WinGet...");
                    var psi = new ProcessStartInfo {
                        FileName = "winget.exe",
                        Arguments = string.Format("install --id \"{0}\" --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity", wingetId),
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        RedirectStandardOutput = true
                    };
                    using (var proc = Process.Start(psi)) {
                        while (!proc.HasExited) {
                            if (ct.IsCancellationRequested) {
                                try { proc.Kill(); } catch { }
                                return;
                            }
                            Thread.Sleep(200);
                        }
                    }
                } catch (Exception ex) {
                    Logger.Log("Winget installation error: " + ex.Message, "Error");
                }
            });
        }
    }

    // --- External Tools Catalog & Execution Engine ---
    public class ExternalToolItem {
        public string Name { get; set; }
        public string Description { get; set; }
        public string Category { get; set; }
        public string ActionType { get; set; } // "Command", "Download", "InternalDialog", "Special"
        public string Target { get; set; }
        public string Arguments { get; set; }
        public string DownloadUrl { get; set; }
        public string ExeInsideArchive { get; set; }

        public ExternalToolItem(string name, string desc, string category, string actionType, string target = "", string args = "", string downloadUrl = "", string exeInsideArchive = "") {
            Name = name;
            Description = desc;
            Category = category;
            ActionType = actionType;
            Target = target;
            Arguments = args;
            DownloadUrl = downloadUrl;
            ExeInsideArchive = exeInsideArchive;
        }
    }

    public static class ExternalToolsEngine {
        public static string GetExtProgramDir() {
            string dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HMT", "ExtPrograms");
            if (!Directory.Exists(dir)) {
                Directory.CreateDirectory(dir);
            }
            return dir;
        }

        public static List<ExternalToolItem> GetSystemRepairTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("DISM Repair", "Launches DISM image health restore with live progress in a styled console.", "System Repair", "Command", "dism.exe", "/Online /Cleanup-Image /RestoreHealth"),
                new ExternalToolItem("SFC Repair", "Executes System File Checker (sfc /scannow) in a styled console window.", "System Repair", "Command", "sfc.exe", "/scannow"),
                new ExternalToolItem("Check Disk (Read Only)", "Runs Check Disk (chkdsk C:) in read-only mode to check for file system errors.", "System Repair", "Command", "chkdsk.exe", "C:"),
                new ExternalToolItem(".NET 3.5 (Includes v2 and v3)", "Installs .NET Framework 3.5/2.0/3.0 via DISM with live status output.", "System Repair", "Command", "dism.exe", "/Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart"),
                new ExternalToolItem("Windows Update Reset", "Stops update services, clears SoftwareDistribution & catroot2 caches, and resets components.", "System Repair", "InternalDialog", "winupdate_reset"),
                new ExternalToolItem("Reset HOSTS File to Default", "Resets Windows HOSTS file back to clean Microsoft default (creates a backup .bak).", "System Repair", "Special", "hosts_reset"),
                new ExternalToolItem("Reset Settings Page Visibility", "Clears SettingsPageVisibility registry policy to unhide blocked Windows Settings pages.", "System Repair", "Special", "settings_visibility")
            };
        }

        public static List<ExternalToolItem> GetDiskTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("WizTree", "Scans a selected drive or folder and displays all contents and relative disk space.", "Disk & Storage", "Download", "", "", "https://antibodysoftware-17031.kxcdn.com/files/wiztree_4_26_portable.zip", "WizTree64.exe"),
                new ExternalToolItem("BleachBit", "System and program temporary data cleaner to reclaim drive space.", "Disk & Storage", "Download", "", "", "https://download.bleachbit.org/BleachBit-4.6.2-portable.zip", "bleachbit.exe"),
                new ExternalToolItem("Patch Cleaner", "Scans and allows safe removal of orphaned installer/driver store files.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/PatchCleanerPortable-1-4-2-0.zip", "PatchCleaner.exe"),
                new ExternalToolItem("Windows Disk Cleanup", "Launches the native Windows Disk Cleanup utility.", "Disk & Storage", "Command", "cleanmgr.exe", ""),
                new ExternalToolItem("SMART Info & Benchmarking", "Hardware health summary, wearout gauge, temperature, and built-in direct sequential & 4K random speed benchmark.", "Disk & Storage", "InternalDialog", "storage_health"),
                new ExternalToolItem("Display Driver Uninstaller", "Runs Display Driver Uninstaller (DDU) to clean graphics/audio drivers for fresh installs.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/DDU.exe", "Display Driver Uninstaller.exe"),
                new ExternalToolItem("HDDScan", "Runs HDDScan to verify block health and SMART diagnostics.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/HDDScan-4.1.zip", "HDDScan.exe"),
                new ExternalToolItem("Crystal Disk Mark", "SSD/HDD storage benchmark utility.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/CrystalDiskMark8_0_4c.zip", "DiskMark64.exe"),
                new ExternalToolItem("Crystal Disk Info", "Drive health and temperature monitoring utility.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/CrystalDiskInfo9_2_3.zip", "DiskInfo64.exe"),
                new ExternalToolItem("BitLocker Management", "Inspect status, enable/disable encryption, manage recovery keys, and unlock locked drives.", "Disk & Storage", "InternalDialog", "bitlocker_manager")
            };
        }

        public static List<ExternalToolItem> GetNetworkTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("Internet Speed Test", "Native, real-time speed test against Cloudflare Anycast measuring Ping, Jitter, Download, and Upload.", "Network & Connectivity", "InternalDialog", "speed_test"),
                new ExternalToolItem("Packet Loss & Latency Test", "High-precision async latency & packet loss tester with real-time jitter, loss metrics, and smooth GDI+ graph.", "Network & Connectivity", "InternalDialog", "packet_loss"),
                new ExternalToolItem("TCP Port & Connection Checker", "Tests IP/hostname reachability and open TCP ports with response time.", "Network & Connectivity", "InternalDialog", "tcp_checker"),
                new ExternalToolItem("Flush DNS & Reset IP", "Releases/renews IP, flushes DNS client cache, and clears ARP entries.", "Network & Connectivity", "Special", "flush_dns"),
                new ExternalToolItem("Advanced IP Scanner", "Fast network scanner for remote subnet discovery and device inventory.", "Network & Connectivity", "Download", "", "", "https://hatsthings.com/MultitoolFiles/advanced_ip_scanner_portable.exe", "advanced_ip_scanner_portable.exe"),
                new ExternalToolItem("PuTTY", "SSH and Telnet client for Windows.", "Network & Connectivity", "Download", "", "", "https://hatsthings.com/MultitoolFiles/putty.exe", "putty.exe"),
                new ExternalToolItem("CurrPorts", "Displays all currently opened TCP/IP and UDP ports with process owner details.", "Network & Connectivity", "Download", "", "", "https://www.nirsoft.net/utils/cports-x64.zip", "cports.exe")
            };
        }

        public static List<ExternalToolItem> GetViewerTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("BlueScreenView", "Memory dump & minidump reader to identify crash causes and BSOD drivers.", "Viewers & Utilities", "Download", "", "", "https://www.nirsoft.net/utils/bluescreenview-x64.zip", "BlueScreenView.exe"),
                new ExternalToolItem("USBDeview", "Lists all USB devices currently connected or previously used on this system.", "Viewers & Utilities", "Download", "", "", "https://www.nirsoft.net/utils/usbdeview-x64.zip", "USBDeview.exe"),
                new ExternalToolItem("DriverView", "Lists all installed device drivers loaded in the operating system.", "Viewers & Utilities", "Download", "", "", "https://www.nirsoft.net/utils/driverview-x64.zip", "DriverView.exe"),
                new ExternalToolItem("UninstallView", "Fast, comprehensive viewer for installed software with batch uninstall options.", "Viewers & Utilities", "Download", "", "", "https://www.nirsoft.net/utils/uninstallview-x64.zip", "UninstallView.exe"),
                new ExternalToolItem("DISM++", "Advanced GUI based around DISM for Windows image management and optimization.", "Viewers & Utilities", "Download", "", "", "https://hatsthings.com/MultitoolFiles/Dism++10.1.1002.1.zip", "Dism++x64.exe"),
                new ExternalToolItem("ProfileShift", "Collects and migrates user and system profile data for transferring to new machines.", "Viewers & Utilities", "Download", "", "", "https://hatsthings.com/MultitoolFiles/ProfileShift.exe", "ProfileShift.exe"),
                new ExternalToolItem("User Profile Wizard", "Migrates user profile data between domains or computers (Profwiz).", "Viewers & Utilities", "Download", "", "", "https://hatsthings.com/MultitoolFiles/Profwiz.exe", "Profwiz.exe"),
                new ExternalToolItem("Generate Battery Report", "Generates and opens a detailed HTML report of laptop battery health and cycle history.", "Viewers & Utilities", "Special", "battery_report"),
                new ExternalToolItem("Startup & Autoruns Manager", "Inspect, enable, disable, or remove startup applications and registry autorun entries.", "Viewers & Utilities", "InternalDialog", "startup_manager"),
                new ExternalToolItem("Reliability Monitor", "Opens Windows Reliability Monitor timeline to view crash and software install history.", "Viewers & Utilities", "Command", "perfmon.exe", "/rel"),
                new ExternalToolItem("Read OEM OS Key", "Reads OEM Windows product key embedded in BIOS/ACPI MSDM table.", "Viewers & Utilities", "InternalDialog", "oem_key"),
                new ExternalToolItem("Enable Safe Boot (w/Network)", "Configures BCD to boot into Safe Mode with networking enabled.", "Viewers & Utilities", "Special", "safeboot_net"),
                new ExternalToolItem("Disable Safe Boot (Normal Boot)", "Removes Safe Boot configuration from BCD and restores normal Windows startup.", "Viewers & Utilities", "Special", "safeboot_disable"),
                new ExternalToolItem("Restart Windows Explorer", "Forcefully kills and restarts explorer.exe to resolve frozen taskbars or stuck folders.", "Viewers & Utilities", "Special", "restart_explorer"),
                new ExternalToolItem("McAfee MCPR Tool", "Official McAfee Consumer Product Removal tool.", "Viewers & Utilities", "Download", "", "", "https://hatsthings.com/MultitoolFiles/MCPR.exe", "MCPR.exe"),
                new ExternalToolItem("Ninja Removal Script", "Launches the NinjaOne Agent removal script.", "Viewers & Utilities", "Special", "ninja_removal"),
                new ExternalToolItem("Win11 Upgrade Assistant", "Runs Microsoft Windows 11 Upgrade Assistant.", "Viewers & Utilities", "Download", "", "", "https://go.microsoft.com/fwlink/?linkid=2171764", "Windows11InstallationAssistant.exe")
            };
        }

        public static List<ExternalToolItem> GetPasswordTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("WebBrowserPassView", "Password recovery tool for all major web browsers (Edge, Chrome, Firefox, Opera).", "Password & Keys", "Download", "", "", "https://hatsthings.com/MultitoolFiles/webbrowserpassview.zip", "WebBrowserPassView.exe"),
                new ExternalToolItem("WirelessKeyView", "Recovers all wireless network keys (WEP/WPA/WPA2/WPA3) stored in Windows.", "Password & Keys", "Download", "", "", "https://hatsthings.com/MultitoolFiles/wirelesskeyview-x64.zip", "WirelessKeyView.exe"),
                new ExternalToolItem("Dialupass", "Recovers passwords for VPN, Dialup, and RAS connections.", "Password & Keys", "Download", "", "", "https://hatsthings.com/MultitoolFiles/dialupass.zip", "Dialupass.exe"),
                new ExternalToolItem("CredentialFileView", "Decrypts and displays credentials stored inside Windows Credentials files.", "Password & Keys", "Download", "", "", "https://hatsthings.com/MultitoolFiles/credentialfileview.zip", "CredentialFileView.exe"),
                new ExternalToolItem("VaultPasswordView", "Decrypts and displays passwords stored in Windows Vault and Windows Credentials Manager.", "Password & Keys", "Download", "", "", "https://hatsthings.com/MultitoolFiles/vaultpasswordview.zip", "VaultPasswordView.exe")
            };
        }

        public static string ReadOemProductKey() {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "wmic.exe",
                    Arguments = "path softwarelicensingservice get OA3xOriginalProductKey",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true
                };
                using (var proc = Process.Start(psi)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();
                    var lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (var line in lines) {
                        string trimmed = line.Trim();
                        if (!string.IsNullOrEmpty(trimmed) && trimmed.IndexOf("OA3xOriginalProductKey", StringComparison.OrdinalIgnoreCase) < 0) {
                            if (Regex.IsMatch(trimmed, @"^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$")) {
                                return trimmed;
                            }
                        }
                    }
                }
            } catch { }
            return "No OEM Product Key found in BIOS / ACPI MSDM table.";
        }
    }
}
