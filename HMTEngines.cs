using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Management;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
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
    public class PasswordPolicy {
        public int MinLength { get; set; }
        public bool ComplexityRequired { get; set; }
        public int PasswordHistory { get; set; }
        public int MaxPasswordAgeDays { get; set; }

        public bool HasPolicy {
            get { return MinLength > 0 || ComplexityRequired || PasswordHistory > 0; }
        }

        public string GetDescription() {
            if (!HasPolicy) {
                return "Enforced Password Policy: None (No restrictions)";
            }
            var parts = new List<string>();
            if (MinLength > 0) parts.Add(string.Format("Min Length: {0} chars", MinLength));
            if (ComplexityRequired) parts.Add("Complexity Required (Upper, Lower, Digits/Symbols)");
            if (PasswordHistory > 0) parts.Add(string.Format("History: {0} remembered", PasswordHistory));
            return "Enforced Policy: " + string.Join(" • ", parts.ToArray());
        }
    }

    public static class AccountEngine {
        public static PasswordPolicy GetPasswordPolicy() {
            var policy = new PasswordPolicy();
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
                    var matchLen = Regex.Match(output, @"Minimum password length\s+(\d+)", RegexOptions.IgnoreCase);
                    if (matchLen.Success) {
                        int len;
                        if (int.TryParse(matchLen.Groups[1].Value, out len)) policy.MinLength = len;
                    }
                    var matchHist = Regex.Match(output, @"Length of password history maintained\s+(\d+)", RegexOptions.IgnoreCase);
                    if (matchHist.Success) {
                        int hist;
                        if (int.TryParse(matchHist.Groups[1].Value, out hist)) policy.PasswordHistory = hist;
                    }
                    var matchAge = Regex.Match(output, @"Maximum password age\s*\(days\)\s*:\s*(\d+)", RegexOptions.IgnoreCase);
                    if (matchAge.Success) {
                        int age;
                        if (int.TryParse(matchAge.Groups[1].Value, out age)) policy.MaxPasswordAgeDays = age;
                    }
                }
            } catch { }

            // Inspect local security policy for complexity
            try {
                string tmpCfg = Path.Combine(Path.GetTempPath(), "hmt_secpol_" + Guid.NewGuid().ToString("N").Substring(0, 8) + ".inf");
                var psiSec = new ProcessStartInfo {
                    FileName = "secedit.exe",
                    Arguments = string.Format("/export /cfg \"{0}\" /areas SECURITYPOLICY", tmpCfg),
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psiSec)) {
                    proc.WaitForExit(3000);
                }
                if (File.Exists(tmpCfg)) {
                    string cfgText = File.ReadAllText(tmpCfg);
                    try { File.Delete(tmpCfg); } catch { }

                    var mComp = Regex.Match(cfgText, @"PasswordComplexity\s*=\s*([01])", RegexOptions.IgnoreCase);
                    if (mComp.Success && mComp.Groups[1].Value == "1") {
                        policy.ComplexityRequired = true;
                    }
                    if (policy.MinLength <= 0) {
                        var mLen = Regex.Match(cfgText, @"MinimumPasswordLength\s*=\s*(\d+)", RegexOptions.IgnoreCase);
                        if (mLen.Success) {
                            int l;
                            if (int.TryParse(mLen.Groups[1].Value, out l)) policy.MinLength = l;
                        }
                    }
                }
            } catch { }

            return policy;
        }

        public static int GetMinimumPasswordLength() {
            return GetPasswordPolicy().MinLength;
        }

        private static string ExtractProcessError(Process proc) {
            try {
                string err = proc.StandardError.ReadToEnd();
                if (string.IsNullOrWhiteSpace(err)) err = proc.StandardOutput.ReadToEnd();
                if (!string.IsNullOrWhiteSpace(err)) {
                    var lines = err.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (var l in lines) {
                        string trimmed = l.Trim();
                        if (trimmed.StartsWith("The syntax of", StringComparison.OrdinalIgnoreCase)) continue;
                        if (trimmed.StartsWith("More help is", StringComparison.OrdinalIgnoreCase)) continue;
                        if (trimmed.StartsWith("NET HELPMSG", StringComparison.OrdinalIgnoreCase)) continue;
                        if (trimmed.Length > 0) return trimmed;
                    }
                }
            } catch { }
            return "Windows rejected the operation. Ensure the password satisfies system security policies.";
        }

        public static bool CreateUser(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire, out string errorMessage) {
            errorMessage = "";
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = string.Format("user \"{0}\" \"{1}\" /add /y", username, password),
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) {
                        errorMessage = ExtractProcessError(proc);
                        return false;
                    }
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
                errorMessage = ex.Message;
                Logger.Log("User creation failed: " + ex.Message, "Error");
                return false;
            }
        }

        public static bool CreateUser(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire) {
            string err;
            return CreateUser(username, password, isAutoLogin, isAdmin, isDontExpire, out err);
        }

        public static bool UpdateUserPassword(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire, out string errorMessage) {
            errorMessage = "";
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = string.Format("user \"{0}\" \"{1}\"", username, password),
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) {
                        errorMessage = ExtractProcessError(proc);
                        return false;
                    }
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
                errorMessage = ex.Message;
                Logger.Log("Password update failed: " + ex.Message, "Error");
                return false;
            }
        }

        public static bool UpdateUserPassword(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire) {
            string err;
            return UpdateUserPassword(username, password, isAutoLogin, isAdmin, isDontExpire, out err);
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

        public static bool IsValidComputerName(string name) {
            if (string.IsNullOrWhiteSpace(name)) return false;
            return Regex.IsMatch(name, @"^(?!\d+$)[A-Za-z0-9](?:[A-Za-z0-9-]{0,13}[A-Za-z0-9])?$");
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

        public static void JoinDomain(string domainName) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "powershell.exe",
                    Arguments = string.Format("-NoProfile -NonInteractive -Command \"Add-Computer -DomainName '{0}' -Credential (Get-Credential) -ErrorAction Stop\"", domainName),
                    UseShellExecute = true
                };
                Process.Start(psi);
            } catch (Exception ex) {
                Logger.Log("Failed to join domain: " + ex.Message, "Error");
            }
        }

        public static void OpenWorkplaceSettings() {
            try {
                Process.Start(new ProcessStartInfo {
                    FileName = "ms-settings:workplace",
                    UseShellExecute = true
                });
            } catch { }
        }

        public static void UpgradeToProEdition(string productKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T") {
            try {
                if (string.IsNullOrWhiteSpace(productKey)) productKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T";
                var psiDism = new ProcessStartInfo {
                    FileName = "dism.exe",
                    Arguments = string.Format("/Online /Set-Edition:Professional /ProductKey:{0} /NoRestart /AcceptEula", productKey),
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psiDism)) {
                    proc.WaitForExit(15000);
                    if (proc.ExitCode != 0) {
                        var psiPk = new ProcessStartInfo {
                            FileName = "changepk.exe",
                            Arguments = "/ProductKey " + productKey,
                            UseShellExecute = true
                        };
                        Process.Start(psiPk);
                    }
                }
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
            "Spotify", "TikTok", "Disney", "Clipchamp", "McAfee", "Norton", "Instagram",
            "Facebook", "PrimeVideo", "Netflix", "LinkedIn", "Twitter", "Pandora",
            "CandyCrush", "Dolby", "Dropbox", "Grammarly", "Evernote", "WhatsApp",
            "Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.Getstarted",
            "Microsoft.MicrosoftSolitaireCollection", "Microsoft.People", "Microsoft.PowerAutomateDesktop",
            "Microsoft.Todos", "Microsoft.YourPhone", "Microsoft.ZuneVideo", "Microsoft.ZuneMusic"
        };

        public static async Task ExecuteBloatCleanupAsync(IProgress<BloatProgressInfo> progress) {
            await Task.Run(() => {
                try {
                    progress?.Report(new BloatProgressInfo {
                        Status = "Starting Bloatware Removal...",
                        Detail = "Scanning installed AppX packages across all users...",
                        ProgressPercentage = 5
                    });

                    // 1. Unified Batch AppX Package Removal
                    string appListLiteral = string.Join("','", BloatApps);
                    string psBatchScript = string.Format(@"$ErrorActionPreference = 'SilentlyContinue'; $bloat = @('{0}'); $packages = Get-AppxPackage -AllUsers; $provisioned = Get-AppxProvisionedPackage -Online; $i = 0; foreach ($app in $bloat) {{ $i++; [Console]::WriteLine(""PROGRESS:$i:$app""); $pkgs = $packages | Where-Object {{ $_.Name -like ""*$app*"" }}; if ($pkgs) {{ $pkgs | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; }} $prov = $provisioned | Where-Object {{ $_.DisplayName -like ""*$app*"" -or $_.PackageName -like ""*$app*"" }}; if ($prov) {{ foreach ($p in $prov) {{ Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue | Out-Null; }} }} }}", appListLiteral);

                    var psi = new ProcessStartInfo {
                        FileName = "powershell.exe",
                        Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command \"" + psBatchScript + "\"",
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        RedirectStandardOutput = true
                    };

                    using (var proc = Process.Start(psi)) {
                        string line;
                        while ((line = proc.StandardOutput.ReadLine()) != null) {
                            if (line.StartsWith("PROGRESS:")) {
                                var parts = line.Split(new char[] { ':' });
                                if (parts.Length >= 3) {
                                    int idx;
                                    int.TryParse(parts[1], out idx);
                                    string name = parts[2];
                                    progress?.Report(new BloatProgressInfo {
                                        Status = "Removing AppX Bloatware...",
                                        Detail = string.Format("Cleaning {0} ({1}/{2})...", name, idx, BloatApps.Length),
                                        ProgressPercentage = 5 + (int)((idx * 65.0) / BloatApps.Length)
                                    });
                                }
                            }
                        }
                        proc.WaitForExit(30000);
                    }

                    // 2. Disable Telemetry Services
                    progress?.Report(new BloatProgressInfo {
                        Status = "Optimizing Services...",
                        Detail = "Disabling telemetry and diagnostic tracking services...",
                        ProgressPercentage = 75
                    });

                    string[] services = new string[] { "DiagTrack", "dmwappushservice" };
                    foreach (var s in services) {
                        try {
                            using (var sc = new ServiceController(s)) {
                                if (sc.Status == ServiceControllerStatus.Running) sc.Stop();
                            }
                        } catch { }
                        try {
                            var psiSc = new ProcessStartInfo {
                                FileName = "sc.exe",
                                Arguments = "config " + s + " start= disabled",
                                CreateNoWindow = true,
                                UseShellExecute = false
                            };
                            using (var pSc = Process.Start(psiSc)) {
                                pSc.WaitForExit(3000);
                            }
                        } catch { }
                    }

                    // 3. Apply Registry Policies (Telemetry, Bing Search, Consumer Features, Advertising ID)
                    progress?.Report(new BloatProgressInfo {
                        Status = "Applying Privacy & Search Policies...",
                        Detail = "Disabling telemetry, Bing web search, and consumer suggestions...",
                        ProgressPercentage = 90
                    });

                    try {
                        // System-wide Telemetry
                        using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
                            if (key != null) key.SetValue("AllowTelemetry", 0, RegistryValueKind.DWord);
                        }
                        // Consumer Features
                        using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
                            if (key != null) {
                                key.SetValue("DisableWindowsConsumerFeatures", 1, RegistryValueKind.DWord);
                                key.SetValue("DisableCloudOptimizedContent", 1, RegistryValueKind.DWord);
                            }
                        }
                        // Explorer & Windows Search
                        using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
                            if (key != null) key.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
                            if (key != null) {
                                key.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                                key.SetValue("ConnectedSearchUseWeb", 0, RegistryValueKind.DWord);
                                key.SetValue("AllowCortana", 0, RegistryValueKind.DWord);
                            }
                        }
                        // Current User Search & Advertising
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Policies\Microsoft\Windows\Explorer")) {
                            if (key != null) key.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Search")) {
                            if (key != null) key.SetValue("BingSearchEnabled", 0, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
                            if (key != null) key.SetValue("Enabled", 0, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Privacy")) {
                            if (key != null) key.SetValue("TailoredExperiencesWithDiagnosticDataEnabled", 0, RegistryValueKind.DWord);
                        }
                        // Content Delivery Manager
                        using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager")) {
                            if (key != null) {
                                key.SetValue("ContentDeliveryAllowed", 0, RegistryValueKind.DWord);
                                key.SetValue("OemPreInstalledAppsEnabled", 0, RegistryValueKind.DWord);
                                key.SetValue("PreInstalledAppsEnabled", 0, RegistryValueKind.DWord);
                                key.SetValue("SilentInstalledAppsEnabled", 0, RegistryValueKind.DWord);
                                key.SetValue("SubscribedContent-338388Enabled", 0, RegistryValueKind.DWord);
                                key.SetValue("SubscribedContent-338389Enabled", 0, RegistryValueKind.DWord);
                            }
                        }
                    } catch { }

                    progress?.Report(new BloatProgressInfo {
                        Status = "Bloat Cleanup Complete!",
                        Detail = "All selected bloatware, telemetry, and promotional features have been removed.",
                        ProgressPercentage = 100
                    });

                    Thread.Sleep(400);
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

    public class InstallerPackageInfo {
        public string InstallerUrl { get; set; }
        public string SilentArgs { get; set; }
        public string InstallerType { get; set; }
    }

    public class ProgramProgressInfo {
        public string StatusText { get; set; }
        public string DetailText { get; set; }
        public int ProgressPercentage { get; set; }
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

        public static InstallerPackageInfo GetWingetInstallerInfo(string wingetId, CancellationToken ct) {
            var info = new InstallerPackageInfo();
            if (string.IsNullOrEmpty(wingetId)) return info;

            // App-specific fast-paths / verified overrides
            if (wingetId.Equals("Adobe.Acrobat.Reader.64-bit", StringComparison.OrdinalIgnoreCase)) {
                info.SilentArgs = "/sAll /rs /msi EULA_ACCEPT=YES /norestart";
            } else if (wingetId.Equals("Valve.Steam", StringComparison.OrdinalIgnoreCase)) {
                info.InstallerUrl = "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe";
                info.SilentArgs = "/S";
                return info;
            } else if (wingetId.IndexOf("Slack", StringComparison.OrdinalIgnoreCase) >= 0) {
                info.InstallerUrl = "https://slack.com/ssb/download-win64";
                info.SilentArgs = "/silent";
                return info;
            } else if (wingetId.IndexOf("AnyDesk", StringComparison.OrdinalIgnoreCase) >= 0) {
                info.InstallerUrl = "https://download.anydesk.com/AnyDesk.exe";
                info.SilentArgs = "--install \"" + Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86) + "\\AnyDesk\" --start-with-win --silent";
                return info;
            } else if (wingetId.Equals("Google.Chrome", StringComparison.OrdinalIgnoreCase)) {
                info.InstallerUrl = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B4F373802-9F19-C0FD-BA19-1EBE5394B73B%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_1%26installdataindex%3Dempty/update2/installers/ChromeStandaloneSetup64.exe";
                info.SilentArgs = "/silent /install";
                return info;
            } else if (wingetId.Equals("Mozilla.Firefox", StringComparison.OrdinalIgnoreCase)) {
                info.InstallerUrl = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US";
                info.SilentArgs = "/S";
                return info;
            } else if (wingetId.Equals("7zip.7zip", StringComparison.OrdinalIgnoreCase)) {
                info.InstallerUrl = "https://www.7-zip.org/a/7z2408-x64.exe";
                info.SilentArgs = "/S";
                return info;
            } else if (wingetId.Equals("Notepad++.Notepad++", StringComparison.OrdinalIgnoreCase)) {
                info.InstallerUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.x64.exe";
                info.SilentArgs = "/S";
                return info;
            } else if (wingetId.Equals("Git.Git", StringComparison.OrdinalIgnoreCase)) {
                info.InstallerUrl = "https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe";
                info.SilentArgs = "/VERYSILENT /NORESTART";
                return info;
            }

            try {
                var psi = new ProcessStartInfo {
                    FileName = "winget.exe",
                    Arguments = string.Format("show --id \"{0}\" --exact --source winget --architecture x64 --scope machine --accept-source-agreements --disable-interactivity", wingetId),
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true
                };
                using (var proc = Process.Start(psi)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit(10000);
                    if (!string.IsNullOrEmpty(output)) {
                        var lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                        foreach (var rawLine in lines) {
                            string line = rawLine.Trim();
                            var mUrl = Regex.Match(line, @"^Installer URL:\s*(.+)$", RegexOptions.IgnoreCase);
                            if (mUrl.Success) info.InstallerUrl = mUrl.Groups[1].Value.Trim();

                            var mType = Regex.Match(line, @"^Installer Type:\s*(.+)$", RegexOptions.IgnoreCase);
                            if (mType.Success) info.InstallerType = mType.Groups[1].Value.Trim();

                            var mSilent = Regex.Match(line, @"^Silent:\s*(.+)$", RegexOptions.IgnoreCase);
                            if (mSilent.Success && string.IsNullOrEmpty(info.SilentArgs)) info.SilentArgs = mSilent.Groups[1].Value.Trim();

                            var mSilentProg = Regex.Match(line, @"^Silent with Progress:\s*(.+)$", RegexOptions.IgnoreCase);
                            if (mSilentProg.Success && string.IsNullOrEmpty(info.SilentArgs)) info.SilentArgs = mSilentProg.Groups[1].Value.Trim();
                        }
                    }
                }
            } catch { }

            // Default silent argument inferencing if missing
            if (string.IsNullOrEmpty(info.SilentArgs)) {
                if (!string.IsNullOrEmpty(info.InstallerUrl)) {
                    if (info.InstallerUrl.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) || (info.InstallerType != null && info.InstallerType.IndexOf("msi", StringComparison.OrdinalIgnoreCase) >= 0)) {
                        info.SilentArgs = "/qn /norestart";
                    } else if (info.InstallerType != null && info.InstallerType.IndexOf("inno", StringComparison.OrdinalIgnoreCase) >= 0) {
                        info.SilentArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-";
                    } else if (info.InstallerType != null && info.InstallerType.IndexOf("nullsoft", StringComparison.OrdinalIgnoreCase) >= 0) {
                        info.SilentArgs = "/S";
                    } else {
                        info.SilentArgs = "/S";
                    }
                }
            }

            return info;
        }

        public static async Task<bool> InstallProgramDirectAsync(SoftwareItem item, int index, int total, IProgress<ProgramProgressInfo> progress, CancellationToken ct) {
            string phase = string.Format("Installing {0} of {1}: {2}", index + 1, total, item.Name);
            progress?.Report(new ProgramProgressInfo {
                StatusText = phase,
                DetailText = "Resolving installer package...",
                ProgressPercentage = 5
            });

            try {
                // 1. Scrape package URL and silent args
                var info = await Task.Run(() => GetWingetInstallerInfo(item.WingetID, ct));
                ct.ThrowIfCancellationRequested();

                if (!string.IsNullOrEmpty(info.InstallerUrl)) {
                    // 2. In-house HTTP download with speed tracking
                    string ext = ".exe";
                    if (info.InstallerUrl.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) || (info.InstallerType != null && info.InstallerType.IndexOf("msi", StringComparison.OrdinalIgnoreCase) >= 0)) {
                        ext = ".msi";
                    }
                    string tempFile = Path.Combine(Path.GetTempPath(), "hmt_installer_" + Guid.NewGuid().ToString("N").Substring(0, 8) + ext);

                    try {
                        using (var handler = new HttpClientHandler { AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate })
                        using (var client = new HttpClient(handler)) {
                            client.Timeout = TimeSpan.FromMinutes(15);
                            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 Safari/537.36");
                            client.DefaultRequestHeaders.Add("Accept", "*/*");

                            using (var response = await client.GetAsync(info.InstallerUrl, HttpCompletionOption.ResponseHeadersRead, ct)) {
                                response.EnsureSuccessStatusCode();
                                long totalBytes = response.Content.Headers.ContentLength ?? -1L;

                                using (var stream = await response.Content.ReadAsStreamAsync())
                                using (var fileStream = new FileStream(tempFile, FileMode.Create, FileAccess.Write, FileShare.None, 262144, true)) {
                                    byte[] buffer = new byte[262144];
                                    long totalRead = 0;
                                    long lastBytes = 0;
                                    int read;
                                    var swUi = Stopwatch.StartNew();
                                    var swWindow = Stopwatch.StartNew();
                                    double speedMbps = 0.0;

                                    while ((read = await stream.ReadAsync(buffer, 0, buffer.Length, ct)) > 0) {
                                        await fileStream.WriteAsync(buffer, 0, read, ct);
                                        totalRead += read;

                                        if (swUi.ElapsedMilliseconds >= 150) {
                                            swUi.Restart();
                                            double winSec = Math.Max(0.05, swWindow.Elapsed.TotalSeconds);
                                            long delta = totalRead - lastBytes;
                                            lastBytes = totalRead;
                                            swWindow.Restart();
                                            speedMbps = ((delta * 8.0) / 1048576.0) / winSec;

                                            double mbRead = Math.Round(totalRead / 1048576.0, 1);
                                            double mbTotal = Math.Round(totalBytes / 1048576.0, 1);
                                            int pct = totalBytes > 0 ? (int)((totalRead * 70.0) / totalBytes) : 40;
                                            string detail = (totalBytes > 0)
                                                ? string.Format("Downloading... {0}% ({1:F1} MB / {2:F1} MB @ {3:F1} Mbps)", pct, mbRead, mbTotal, speedMbps)
                                                : string.Format("Downloading... {0:F1} MB @ {1:F1} Mbps", mbRead, speedMbps);

                                            progress?.Report(new ProgramProgressInfo {
                                                StatusText = phase,
                                                DetailText = detail,
                                                ProgressPercentage = pct
                                            });
                                        }
                                    }
                                }
                            }
                        }

                        ct.ThrowIfCancellationRequested();

                        // 3. Direct Execution
                        progress?.Report(new ProgramProgressInfo {
                            StatusText = phase,
                            DetailText = "Running installer...",
                            ProgressPercentage = 80
                        });

                        var psi = new ProcessStartInfo();
                        if (tempFile.EndsWith(".msi", StringComparison.OrdinalIgnoreCase)) {
                            psi.FileName = "msiexec.exe";
                            psi.Arguments = string.Format("/i \"{0}\" {1}", tempFile, string.IsNullOrEmpty(info.SilentArgs) ? "/qn /norestart" : info.SilentArgs);
                        } else {
                            psi.FileName = tempFile;
                            psi.Arguments = info.SilentArgs ?? "/S";
                        }
                        psi.CreateNoWindow = true;
                        psi.UseShellExecute = false;

                        using (var proc = Process.Start(psi)) {
                            while (!proc.HasExited) {
                                if (ct.IsCancellationRequested) {
                                    try {
                                        Process.Start(new ProcessStartInfo {
                                            FileName = "taskkill.exe",
                                            Arguments = string.Format("/F /T /PID {0}", proc.Id),
                                            CreateNoWindow = true,
                                            UseShellExecute = false
                                        })?.WaitForExit(1000);
                                    } catch { }
                                    try { proc.Kill(); } catch { }
                                    try { File.Delete(tempFile); } catch { }
                                    return false;
                                }
                                await Task.Delay(200, ct);
                            }
                        }

                        try { File.Delete(tempFile); } catch { }

                        progress?.Report(new ProgramProgressInfo {
                            StatusText = "Finished: " + item.Name,
                            DetailText = "",
                            ProgressPercentage = 100
                        });
                        return true;
                    } catch (OperationCanceledException) {
                        try { File.Delete(tempFile); } catch { }
                        throw;
                    } catch {
                        try { File.Delete(tempFile); } catch { }
                    }
                }

                // Fallback to WinGet if direct download/run was not available or failed
                progress?.Report(new ProgramProgressInfo {
                    StatusText = phase,
                    DetailText = "Installing via WinGet package manager...",
                    ProgressPercentage = 50
                });

                var psiWinget = new ProcessStartInfo {
                    FileName = "winget.exe",
                    Arguments = string.Format("install --id \"{0}\" --exact --source winget --architecture x64 --silent --accept-package-agreements --accept-source-agreements --disable-interactivity", item.WingetID),
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psiWinget)) {
                    while (!proc.HasExited) {
                        if (ct.IsCancellationRequested) {
                            try {
                                Process.Start(new ProcessStartInfo {
                                    FileName = "taskkill.exe",
                                    Arguments = string.Format("/F /T /PID {0}", proc.Id),
                                    CreateNoWindow = true,
                                    UseShellExecute = false
                                })?.WaitForExit(1000);
                            } catch { }
                            try { proc.Kill(); } catch { }
                            return false;
                        }
                        await Task.Delay(200, ct);
                    }
                    return proc.ExitCode == 0;
                }
            } catch (OperationCanceledException) {
                return false;
            } catch (Exception ex) {
                Logger.Log(string.Format("Failed to install {0}: {1}", item.Name, ex.Message), "Warning");
                return false;
            }
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
                        ProgressPercentage = 5
                    });

                    try {
                        try {
                            var sp = ServicePointManager.FindServicePoint(new Uri(cdnUrl));
                            sp.ConnectionLimit = 64;
                            sp.UseNagleAlgorithm = false;
                            sp.Expect100Continue = false;
                        } catch { }

                        using (var handler = new HttpClientHandler { AutomaticDecompression = DecompressionMethods.None })
                        using (var client = new HttpClient(handler)) {
                        client.Timeout = TimeSpan.FromMinutes(30);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 Safari/537.36");

                        // 1. Probe CDN for Content-Length and Range support
                        long totalBytes = -1L;
                        bool supportsRange = false;
                        try {
                            var headReq = new HttpRequestMessage(HttpMethod.Get, cdnUrl);
                            headReq.Headers.Add("X-HMT-Token", "HMTDAT1");
                            headReq.Headers.Range = new RangeHeaderValue(0, 0);
                            using (var probeResp = await client.SendAsync(headReq, HttpCompletionOption.ResponseHeadersRead, ct)) {
                                if (probeResp.StatusCode == HttpStatusCode.PartialContent) {
                                    supportsRange = true;
                                    totalBytes = probeResp.Content.Headers.ContentRange?.Length ?? -1L;
                                } else if (probeResp.IsSuccessStatusCode) {
                                    totalBytes = probeResp.Content.Headers.ContentLength ?? -1L;
                                }
                            }
                        } catch { }

                        int workerCount = (supportsRange && totalBytes > 50 * 1024 * 1024) ? 12 : 1;

                        if (workerCount > 1) {
                            // Multi-Part Parallel Range Downloader with independent part files (zero disk contention)
                            long chunkSize = (totalBytes + workerCount - 1) / workerCount;
                            long totalRead = 0;
                            long lastBytes = 0;
                            var swWindow = Stopwatch.StartNew();
                            var swUi = Stopwatch.StartNew();
                            double speedMbps = 0.0;
                            object syncObj = new object();

                            var downloadTasks = new List<Task>();
                            for (int w = 0; w < workerCount; w++) {
                                int workerIndex = w;
                                long start = workerIndex * chunkSize;
                                long end = Math.Min(totalBytes - 1, start + chunkSize - 1);
                                if (start > end) break;

                                string partPath = zipPath + ".part" + workerIndex;

                                downloadTasks.Add(Task.Run(async () => {
                                    var req = new HttpRequestMessage(HttpMethod.Get, cdnUrl);
                                    req.Headers.Add("X-HMT-Token", "HMTDAT1");
                                    req.Headers.Range = new RangeHeaderValue(start, end);

                                    using (var resp = await client.SendAsync(req, HttpCompletionOption.ResponseHeadersRead, ct)) {
                                        resp.EnsureSuccessStatusCode();
                                        using (var stream = await resp.Content.ReadAsStreamAsync())
                                        using (var fs = new FileStream(partPath, FileMode.Create, FileAccess.Write, FileShare.None, 262144, true)) {
                                            byte[] buf = new byte[131072];
                                            int read;
                                            while ((read = await stream.ReadAsync(buf, 0, buf.Length, ct)) > 0) {
                                                await fs.WriteAsync(buf, 0, read, ct);
                                                long cur = Interlocked.Add(ref totalRead, read);

                                                if (swUi.ElapsedMilliseconds >= 120) {
                                                    lock (syncObj) {
                                                        if (swUi.ElapsedMilliseconds >= 120) {
                                                            swUi.Restart();
                                                            double winSec = Math.Max(0.05, swWindow.Elapsed.TotalSeconds);
                                                            long delta = cur - lastBytes;
                                                            lastBytes = cur;
                                                            swWindow.Restart();
                                                            double instSpeed = ((delta * 8.0) / 1048576.0) / winSec;
                                                            speedMbps = speedMbps <= 0.0 ? instSpeed : (speedMbps * 0.7 + instSpeed * 0.3);

                                                            int pct = (int)((cur * 75.0) / totalBytes);
                                                            double mbRead = Math.Round(cur / 1048576.0, 1);
                                                            double mbTotal = Math.Round(totalBytes / 1048576.0, 1);
                                                            string detail = string.Format("{0}% ({1:F1} MB / {2:F1} MB @ {3:F1} Mbps)", pct, mbRead, mbTotal, speedMbps);

                                                            progress?.Report(new BloatProgressInfo {
                                                                Status = "Downloading " + displayName + " (Multi-Stream)...",
                                                                Detail = detail,
                                                                ProgressPercentage = pct
                                                            });
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }, ct));
                            }

                            await Task.WhenAll(downloadTasks);

                            // High-speed sequential file assembly
                            progress?.Report(new BloatProgressInfo {
                                Status = "Finalizing " + displayName + " download...",
                                Detail = "Assembling multi-stream package...",
                                ProgressPercentage = 75
                            });

                            using (var outputFs = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None, 1048576, true)) {
                                byte[] mergeBuf = new byte[1048576];
                                for (int w = 0; w < workerCount; w++) {
                                    string partPath = zipPath + ".part" + w;
                                    if (File.Exists(partPath)) {
                                        using (var partFs = new FileStream(partPath, FileMode.Open, FileAccess.Read, FileShare.Read, 1048576, true)) {
                                            int r;
                                            while ((r = await partFs.ReadAsync(mergeBuf, 0, mergeBuf.Length, ct)) > 0) {
                                                await outputFs.WriteAsync(mergeBuf, 0, r, ct);
                                            }
                                        }
                                        try { File.Delete(partPath); } catch { }
                                    }
                                }
                            }
                        } else {
                            // High-speed single-stream fallback
                            var req = new HttpRequestMessage(HttpMethod.Get, cdnUrl);
                            req.Headers.Add("X-HMT-Token", "HMTDAT1");
                            using (var response = await client.SendAsync(req, HttpCompletionOption.ResponseHeadersRead, ct)) {
                                response.EnsureSuccessStatusCode();
                                if (totalBytes <= 0) totalBytes = response.Content.Headers.ContentLength ?? -1L;

                                using (var stream = await response.Content.ReadAsStreamAsync())
                                using (var fileStream = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None, 262144, true)) {
                                    byte[] buffer = new byte[262144];
                                    long totalRead = 0;
                                    long lastBytes = 0;
                                    int read;
                                    var swUi = Stopwatch.StartNew();
                                    var swWindow = Stopwatch.StartNew();
                                    double speedMbps = 0.0;

                                    while ((read = await stream.ReadAsync(buffer, 0, buffer.Length, ct)) > 0) {
                                        await fileStream.WriteAsync(buffer, 0, read, ct);
                                        totalRead += read;

                                        if (swUi.ElapsedMilliseconds >= 120) {
                                            swUi.Restart();
                                            double winSec = Math.Max(0.05, swWindow.Elapsed.TotalSeconds);
                                            long delta = totalRead - lastBytes;
                                            lastBytes = totalRead;
                                            swWindow.Restart();
                                            double instSpeed = ((delta * 8.0) / 1048576.0) / winSec;
                                            speedMbps = speedMbps <= 0.0 ? instSpeed : (speedMbps * 0.7 + instSpeed * 0.3);

                                            double mbRead = Math.Round(totalRead / 1048576.0, 1);
                                            double mbTotal = Math.Round(totalBytes / 1048576.0, 1);
                                            int pct = totalBytes > 0 ? (int)((totalRead * 75.0) / totalBytes) : 40;
                                            string detail = (totalBytes > 0)
                                                ? string.Format("{0}% ({1:F1} MB / {2:F1} MB @ {3:F1} Mbps)", pct, mbRead, mbTotal, speedMbps)
                                                : string.Format("{0:F1} MB downloaded @ {1:F1} Mbps", mbRead, speedMbps);

                                            progress?.Report(new BloatProgressInfo {
                                                Status = "Downloading " + displayName + "...",
                                                Detail = detail,
                                                ProgressPercentage = pct
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                    } catch {
                        try { if (File.Exists(zipPath)) File.Delete(zipPath); } catch { }
                        for (int w = 0; w < 16; w++) {
                            try { string p = zipPath + ".part" + w; if (File.Exists(p)) File.Delete(p); } catch { }
                        }
                        throw;
                    }
                }

                ct.ThrowIfCancellationRequested();

                // Smooth entry-by-entry extraction tracking
                progress?.Report(new BloatProgressInfo {
                    Status = "Extracting " + displayName + " payload...",
                    Detail = "Unpacking payload files into ExtPrograms\\MicrosoftOffice...",
                    ProgressPercentage = 80
                });

                await Task.Run(() => {
                    using (var archive = ZipFile.OpenRead(zipPath)) {
                        int totalEntries = archive.Entries.Count;
                        int currentEntry = 0;
                        foreach (var entry in archive.Entries) {
                            if (ct.IsCancellationRequested) ct.ThrowIfCancellationRequested();
                            currentEntry++;
                            string destinationPath = Path.Combine(officeDir, entry.FullName);
                            string destDir = Path.GetDirectoryName(destinationPath);
                            if (!Directory.Exists(destDir) && !string.IsNullOrEmpty(destDir)) {
                                Directory.CreateDirectory(destDir);
                            }
                            if (!string.IsNullOrEmpty(entry.Name)) {
                                entry.ExtractToFile(destinationPath, true);
                            }
                            if (currentEntry % 5 == 0 || currentEntry == totalEntries) {
                                int extractPct = 80 + (int)((currentEntry * 15.0) / Math.Max(1, totalEntries));
                                progress?.Report(new BloatProgressInfo {
                                    Status = "Extracting " + displayName + " payload...",
                                    Detail = string.Format("Extracting file {0} of {1}...", currentEntry, totalEntries),
                                    ProgressPercentage = extractPct
                                });
                            }
                        }
                    }
                }, ct);
            }

            ct.ThrowIfCancellationRequested();

            // Locate setup directory and files
            string setupExe = Path.Combine(officeDir, "setup.exe");
            if (!File.Exists(setupExe)) {
                var found = Directory.GetFiles(officeDir, "setup.exe", SearchOption.AllDirectories);
                if (found.Length > 0) setupExe = found[0];
            }
            string setupDir = Path.GetDirectoryName(setupExe);

            // Generate configuration.xml
            string xmlPath = Path.Combine(setupDir, "configuration.xml");
            string xmlContent = string.Format(
                "<Configuration>\n  <Add SourcePath=\"{0}\" OfficeClientEdition=\"64\" Channel=\"Current\">\n    <Product ID=\"{1}\">\n      <Language ID=\"en-us\" />\n    </Product>\n  </Add>\n  <Display Level=\"Full\" AcceptEULA=\"TRUE\" />\n  <Property Name=\"AUTOACTIVATE\" Value=\"0\" />\n</Configuration>",
                setupDir,
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
                WorkingDirectory = setupDir,
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

    public class ResolvedToolInfo {
        public string ToolName { get; set; }
        public string Version { get; set; }
        public string DownloadUrl { get; set; }
        public string ExeInsideArchive { get; set; }
    }

    public static class ToolVersionResolver {
        private static readonly Dictionary<string, ResolvedToolInfo> _cache = new Dictionary<string, ResolvedToolInfo>(StringComparer.OrdinalIgnoreCase);
        private static bool _manifestFetched = false;
        private static readonly object _lock = new object();

        public static async Task<ResolvedToolInfo> ResolveToolAsync(string toolName, string currentUrl, string currentExe) {
            if (string.IsNullOrEmpty(toolName)) {
                return new ResolvedToolInfo { ToolName = toolName, DownloadUrl = currentUrl, ExeInsideArchive = currentExe };
            }

            // 1. Check in-memory cache
            lock (_lock) {
                if (_cache.TryGetValue(toolName, out var cached) && cached != null) {
                    return cached;
                }
            }

            // 2. Fast Dynamic Client-Side Scrapers
            if (toolName.Equals("BleachBit", StringComparison.OrdinalIgnoreCase)) {
                try {
                    using (var cts = new CancellationTokenSource(2500))
                    using (var client = new HttpClient()) {
                        client.Timeout = TimeSpan.FromSeconds(3);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 Safari/537.36");
                        string html = await client.GetStringAsync("https://www.bleachbit.org/download/windows");
                        var m = Regex.Match(html, @"https://download\.bleachbit\.org/(?:get/)?(BleachBit-([0-9\.]+)-portable\.zip)", RegexOptions.IgnoreCase);
                        if (m.Success) {
                            var info = new ResolvedToolInfo {
                                ToolName = toolName,
                                Version = m.Groups[2].Value,
                                DownloadUrl = "https://download.bleachbit.org/" + m.Groups[1].Value,
                                ExeInsideArchive = "bleachbit.exe"
                            };
                            lock (_lock) { _cache[toolName] = info; }
                            return info;
                        }
                    }
                } catch { }
            } else if (toolName.Equals("WizTree", StringComparison.OrdinalIgnoreCase)) {
                try {
                    using (var cts = new CancellationTokenSource(2500))
                    using (var client = new HttpClient()) {
                        client.Timeout = TimeSpan.FromSeconds(3);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 Safari/537.36");
                        string html = await client.GetStringAsync("https://diskanalyzer.com/download");
                        var m = Regex.Match(html, @"files/(wiztree_([0-9_]+)_portable\.zip)", RegexOptions.IgnoreCase);
                        if (m.Success) {
                            var info = new ResolvedToolInfo {
                                ToolName = toolName,
                                Version = m.Groups[2].Value.Replace('_', '.'),
                                DownloadUrl = "https://antibodysoftware-17031.kxcdn.com/files/" + m.Groups[1].Value,
                                ExeInsideArchive = "WizTree64.exe"
                            };
                            lock (_lock) { _cache[toolName] = info; }
                            return info;
                        }
                    }
                } catch { }
            }

            // 3. Remote Central Manifest on hatsthings.com
            await EnsureManifestLoadedAsync();

            lock (_lock) {
                if (_cache.TryGetValue(toolName, out var manifestInfo) && manifestInfo != null) {
                    return manifestInfo;
                }
            }

            // 4. Fallback to default
            var fallback = new ResolvedToolInfo {
                ToolName = toolName,
                DownloadUrl = currentUrl,
                ExeInsideArchive = currentExe
            };
            lock (_lock) { _cache[toolName] = fallback; }
            return fallback;
        }

        private static async Task EnsureManifestLoadedAsync() {
            if (_manifestFetched) return;
            _manifestFetched = true;

            try {
                using (var cts = new CancellationTokenSource(3000))
                using (var client = new HttpClient()) {
                    client.Timeout = TimeSpan.FromSeconds(3);
                    client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 Safari/537.36");
                    string json = await client.GetStringAsync("https://hatsthings.com/MultitoolFiles/ExternalTools.json");
                    ParseManifestJson(json);
                }
            } catch { }
        }

        private static void ParseManifestJson(string json) {
            if (string.IsNullOrEmpty(json)) return;
            try {
                var blockMatches = Regex.Matches(json, @"""([^""]+)""\s*:\s*\{([^}]+)\}");
                foreach (Match bm in blockMatches) {
                    string tool = bm.Groups[1].Value;
                    string body = bm.Groups[2].Value;

                    var mUrl = Regex.Match(body, @"""url""\s*:\s*""([^""]+)""");
                    var mExe = Regex.Match(body, @"""exe""\s*:\s*""([^""]+)""");
                    var mVer = Regex.Match(body, @"""version""\s*:\s*""([^""]+)""");

                    if (mUrl.Success) {
                        var info = new ResolvedToolInfo {
                            ToolName = tool,
                            DownloadUrl = mUrl.Groups[1].Value,
                            ExeInsideArchive = mExe.Success ? mExe.Groups[1].Value : "",
                            Version = mVer.Success ? mVer.Groups[1].Value : ""
                        };
                        lock (_lock) {
                            _cache[tool] = info;
                        }
                    }
                }
            } catch { }
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
                new ExternalToolItem("WizTree", "Scans a selected drive or folder and displays all contents and relative disk space.", "Disk & Storage", "Download", "", "", "https://antibodysoftware-17031.kxcdn.com/files/wiztree_4_32_portable.zip", "WizTree64.exe"),
                new ExternalToolItem("BleachBit", "System and program temporary data cleaner to reclaim drive space.", "Disk & Storage", "Download", "", "", "https://download.bleachbit.org/BleachBit-6.0.2-portable.zip", "bleachbit.exe"),
                new ExternalToolItem("Patch Cleaner", "Scans and allows safe removal of orphaned installer/driver store files.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/PatchCleanerPortable-1-4-2-0.zip", "PatchCleaner.exe"),
                new ExternalToolItem("Windows Disk Cleanup", "Launches the native Windows Disk Cleanup utility.", "Disk & Storage", "Command", "cleanmgr.exe", ""),
                new ExternalToolItem("SMART Info & Benchmarking", "Hardware health summary, wearout gauge, temperature, and built-in direct sequential & 4K random speed benchmark.", "Disk & Storage", "InternalDialog", "storage_health"),
                new ExternalToolItem("Display Driver Uninstaller", "Runs Display Driver Uninstaller (DDU) to clean graphics/audio drivers for fresh installs.", "Disk & Storage", "Download", "", "", "https://hatsthings.com/MultitoolFiles/DDU.zip", "Display Driver Uninstaller.exe"),
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
                new ExternalToolItem("CredentialFileView", "Decrypts and displays credentials stored inside Windows Credentials files.", "Password & Keys", "Download", "", "", "https://hatsthings.com/MultitoolFiles/credentialfileview.zip", "CredentialsFileView.exe"),
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
