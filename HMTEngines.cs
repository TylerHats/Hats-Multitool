using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
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

        public static bool SetTimeZone(string timeZoneId) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "tzutil.exe",
                    Arguments = "/s \"" + timeZoneId + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    return proc.ExitCode == 0;
                }
            } catch (Exception ex) {
                Logger.Log("SetTimeZone failed: " + ex.Message, "Error");
                return false;
            }
        }

        public static void ConfigureNtpAndSync() {
            try {
                Logger.Log("Configuring NTP servers...", "Info");
                RunProcess("w32tm", "/config /manualpeerlist:\"pool.ntp.org,0x8 time.windows.com,0x8 time.google.com,0x8 time.cloudflare.com,0x8\" /syncfromflags:manual /reliable:YES /update");

                // Configure w32time service to Automatic and ensure running
                try {
                    using (var sc = new ServiceController("w32time")) {
                        RunProcess("sc.exe", "config w32time start= auto");
                        if (sc.Status != ServiceControllerStatus.Running) {
                            sc.Start();
                            sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(5));
                        } else {
                            RunProcess("net.exe", "stop w32time");
                            RunProcess("net.exe", "start w32time");
                        }
                    }
                } catch { }

                Thread.Sleep(2000);
                RunProcess("w32tm", "/resync /force");
                Logger.Log("NTP synchronization complete.", "Success");
            } catch (Exception ex) {
                Logger.Log("NTP sync failed: " + ex.Message, "Error");
            }
        }

        private static int RunProcess(string exe, string args) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = exe,
                    Arguments = args,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    return proc.ExitCode;
                }
            } catch {
                return -1;
            }
        }
    }

    // --- Account Management Engine ---
    public static class AccountEngine {
        public static int GetMinimumPasswordLength() {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = "accounts",
                    RedirectStandardOutput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                using (var proc = Process.Start(psi)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();
                    var match = Regex.Match(output, @"Minimum password length:\s+(\d+)", RegexOptions.IgnoreCase);
                    if (match.Success) {
                        return int.Parse(match.Groups[1].Value);
                    }
                }
            } catch { }
            return 0;
        }

        public static bool CreateOrUpdateUser(string username, string password, bool updatePassword, bool makeAdmin, out string errorMessage) {
            errorMessage = null;
            try {
                bool exists = UserExists(username);

                if (!exists) {
                    // Create User
                    string passArg = string.IsNullOrEmpty(password) ? "\"\"" : "\"" + password + "\"";
                    int exitCode = RunCommand("net.exe", string.Format("user \"{0}\" {1} /add /passwordchg:no", username, passArg), out string err);
                    if (exitCode != 0) {
                        errorMessage = "Failed to create user: " + err;
                        return false;
                    }
                    Logger.Log("Created local user " + username, "Success");
                } else {
                    Logger.Log("User " + username + " already exists.", "Skip");
                    if (updatePassword && !string.IsNullOrEmpty(password)) {
                        int exitCode = RunCommand("net.exe", string.Format("user \"{0}\" \"{1}\"", username, password), out string err);
                        if (exitCode != 0) {
                            errorMessage = "Failed to update password: " + err;
                            return false;
                        }
                        Logger.Log("Updated password for user " + username, "Success");
                    }
                }

                if (makeAdmin) {
                    int exitCode = RunCommand("net.exe", string.Format("localgroup Administrators \"{0}\" /add", username), out string err);
                    if (exitCode == 0) {
                        Logger.Log("Added " + username + " to Administrators group.", "Success");
                    } else if (err.Contains("already a member") || err.Contains("1378")) {
                        Logger.Log("User " + username + " is already an Administrator.", "Skip");
                    } else {
                        errorMessage = "Failed to elevate to Administrator: " + err;
                        return false;
                    }
                }

                return true;
            } catch (Exception ex) {
                errorMessage = ex.Message;
                return false;
            }
        }

        private static bool UserExists(string username) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = "user \"" + username + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    return proc.ExitCode == 0;
                }
            } catch {
                return false;
            }
        }

        private static int RunCommand(string exe, string args, out string output) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = exe,
                    Arguments = args,
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (var proc = Process.Start(psi)) {
                    string stdOut = proc.StandardOutput.ReadToEnd();
                    string stdErr = proc.StandardError.ReadToEnd();
                    proc.WaitForExit();
                    output = string.IsNullOrEmpty(stdErr) ? stdOut : stdErr;
                    return proc.ExitCode;
                }
            } catch (Exception ex) {
                output = ex.Message;
                return -1;
            }
        }
    }

    // --- System Properties & Management Engine ---
    public static class SystemPropertiesEngine {
        public static string GetSerialNumber() {
            try {
                using (var searcher = new System.Management.ManagementObjectSearcher("SELECT SerialNumber FROM Win32_BIOS")) {
                    foreach (var obj in searcher.Get()) {
                        return obj["SerialNumber"]?.ToString()?.Trim() ?? "Unknown";
                    }
                }
            } catch { }
            return "Unknown";
        }

        public static bool IsDomainJoined(out string domainName) {
            domainName = "";
            try {
                using (var searcher = new System.Management.ManagementObjectSearcher("SELECT PartOfDomain, Domain FROM Win32_ComputerSystem")) {
                    foreach (var obj in searcher.Get()) {
                        bool partOfDomain = (bool)(obj["PartOfDomain"] ?? false);
                        domainName = obj["Domain"]?.ToString() ?? "";
                        return partOfDomain;
                    }
                }
            } catch { }
            return false;
        }

        public static bool IsWindowsPro() {
            try {
                using (var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion")) {
                    string edition = key?.GetValue("EditionID")?.ToString() ?? "";
                    string prodName = key?.GetValue("ProductName")?.ToString() ?? "";
                    return edition.IndexOf("Pro", StringComparison.OrdinalIgnoreCase) >= 0 ||
                           edition.IndexOf("Enterprise", StringComparison.OrdinalIgnoreCase) >= 0 ||
                           prodName.IndexOf("Pro", StringComparison.OrdinalIgnoreCase) >= 0 ||
                           prodName.IndexOf("Enterprise", StringComparison.OrdinalIgnoreCase) >= 0;
                }
            } catch { }
            return false;
        }

        public static bool TestComputerName(string name) {
            if (string.IsNullOrEmpty(name)) return false;
            return Regex.IsMatch(name, @"^(?!\d+$)[A-Za-z0-9](?:[A-Za-z0-9-]{0,13}[A-Za-z0-9])?$");
        }

        public static bool RenameComputer(string newName, out string error) {
            error = null;
            try {
                var psi = new ProcessStartInfo {
                    FileName = "powershell.exe",
                    Arguments = string.Format("-NoProfile -Command \"Rename-Computer -NewName '{0}' -Force\"", newName.Replace("'", "''")),
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardError = true
                };
                using (var proc = Process.Start(psi)) {
                    string err = proc.StandardError.ReadToEnd();
                    proc.WaitForExit();
                    if (proc.ExitCode == 0) {
                        Logger.Log("Computer renamed to " + newName + " (Reboot required)", "Success");
                        return true;
                    } else {
                        error = err;
                        return false;
                    }
                }
            } catch (Exception ex) {
                error = ex.Message;
                return false;
            }
        }

        public static bool UpgradeToPro(string productKey, out string error) {
            error = null;
            try {
                string key = string.IsNullOrEmpty(productKey) ? "VK7JG-NPHTM-C97JM-9MPGT-3V66T" : productKey;
                var psi = new ProcessStartInfo {
                    FileName = "changepk.exe",
                    Arguments = "/ProductKey " + key,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    Logger.Log("Windows Edition upgrade initiated.", "Success");
                    return true;
                }
            } catch (Exception ex) {
                error = ex.Message;
                return false;
            }
        }
    }

    // --- Setup Options (Final Options) Engine ---
    public static class SetupOptionsEngine {
        public static void ApplyOption(string tag) {
            try {
                switch (tag) {
                    case "numlock":
                        ApplyNumLock();
                        break;
                    case "defprint":
                        ApplyDisableDefaultPrinter();
                        break;
                    case "classicmenu":
                        ApplyClassicContextMenu();
                        break;
                    case "hellopin":
                        ApplyDisableHelloPinPrompt();
                        break;
                    case "devicepower":
                        ApplyDisableDevicePowerSaving();
                        break;
                    case "disablefaststartup":
                        ApplyDisableFastStartup();
                        break;
                    case "enablehibernation":
                        ApplyEnableHibernation();
                        break;
                    case "disablestickykeys":
                        ApplyDisableStickyKeys();
                        break;
                }
            } catch (Exception ex) {
                Logger.Log(string.Format("Option {0} failed: {1}", tag, ex.Message), "Error");
            }
        }

        private static void ApplyNumLock() {
            try {
                using (var key = Registry.Users.CreateSubKey(@".DEFAULT\Control Panel\Keyboard")) {
                    key?.SetValue("InitialKeyboardIndicators", "2", RegistryValueKind.String);
                }
                ModifyDefaultUserProfile((hive) => {
                    using (var key = Registry.Users.CreateSubKey(hive + @"\Control Panel\Keyboard")) {
                        key?.SetValue("InitialKeyboardIndicators", "2", RegistryValueKind.String);
                    }
                });
                Logger.Log("Enabled NUM Lock on Login Screen & Default Profile.", "Success");
            } catch (Exception ex) {
                Logger.Log("NumLock configuration error: " + ex.Message, "Error");
            }
        }

        private static void ApplyDisableDefaultPrinter() {
            try {
                using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows NT\Printers")) {
                    key?.SetValue("LegacyDefaultPrinterMode", 1, RegistryValueKind.DWord);
                }
                using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows NT\CurrentVersion\Windows")) {
                    key?.SetValue("LegacyDefaultPrinterMode", 1, RegistryValueKind.DWord);
                }
                ModifyDefaultUserProfile((hive) => {
                    using (var key = Registry.Users.CreateSubKey(hive + @"\Software\Microsoft\Windows NT\CurrentVersion\Windows")) {
                        key?.SetValue("LegacyDefaultPrinterMode", 1, RegistryValueKind.DWord);
                    }
                });
                Logger.Log("Disabled automatic Windows default printer management.", "Success");
            } catch (Exception ex) {
                Logger.Log("Default printer policy error: " + ex.Message, "Error");
            }
        }

        private static void ApplyClassicContextMenu() {
            try {
                using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32")) {
                    key?.SetValue("", "", RegistryValueKind.String);
                }
                ModifyDefaultUserProfile((hive) => {
                    using (var key = Registry.Users.CreateSubKey(hive + @"\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32")) {
                        key?.SetValue("", "", RegistryValueKind.String);
                    }
                });
                Logger.Log("Restored classic Windows 11 right-click context menu.", "Success");
            } catch (Exception ex) {
                Logger.Log("Classic context menu error: " + ex.Message, "Error");
            }
        }

        private static void ApplyDisableHelloPinPrompt() {
            try {
                using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\PassportForWork")) {
                    key?.SetValue("Enabled", 1, RegistryValueKind.DWord);
                    key?.SetValue("DisablePostLogonProvisioning", 1, RegistryValueKind.DWord);
                }
                Logger.Log("Disabled automatic Windows Hello PIN prompt on first login.", "Success");
            } catch (Exception ex) {
                Logger.Log("Hello PIN policy error: " + ex.Message, "Error");
            }
        }

        private static void ApplyDisableDevicePowerSaving() {
            try {
                RunProcess("powercfg.exe", "/SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48672f3c-7a97-4e7d-b77e-4600e11c3a61 0");
                RunProcess("powercfg.exe", "/SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48672f3c-7a97-4e7d-b77e-4600e11c3a61 0");
                RunProcess("powercfg.exe", "/SETACVALUEINDEX SCHEME_CURRENT 503e4fe8-3593-4916-84e3-524f0c436b72 ee12f904-d8a3-4309-947e-72b44c6d3d57 0");
                RunProcess("powercfg.exe", "/SETDCVALUEINDEX SCHEME_CURRENT 503e4fe8-3593-4916-84e3-524f0c436b72 ee12f904-d8a3-4309-947e-72b44c6d3d57 0");
                RunProcess("powercfg.exe", "/SETACTIVE SCHEME_CURRENT");

                using (var key = Registry.LocalMachine.CreateSubKey(@"SYSTEM\CurrentControlSet\Services\USB")) {
                    key?.SetValue("DisableSelectiveSuspend", 1, RegistryValueKind.DWord);
                }
                Logger.Log("Disabled USB selective suspend, PCIe ASPM, and NIC power saving.", "Success");
            } catch (Exception ex) {
                Logger.Log("Device power saving error: " + ex.Message, "Error");
            }
        }

        private static void ApplyDisableFastStartup() {
            try {
                using (var key = Registry.LocalMachine.CreateSubKey(@"SYSTEM\CurrentControlSet\Control\Session Manager\Power")) {
                    key?.SetValue("HiberbootEnabled", 0, RegistryValueKind.DWord);
                }
                Logger.Log("Disabled Windows Fast Startup (forces true kernel shutdown).", "Success");
            } catch (Exception ex) {
                Logger.Log("Fast startup config error: " + ex.Message, "Error");
            }
        }

        private static void ApplyEnableHibernation() {
            try {
                RunProcess("powercfg.exe", "/hibernate on");
                using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
                    key?.SetValue("ShowHibernateOption", 1, RegistryValueKind.DWord);
                }
                using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel")) {
                    key?.SetValue("ShowHibernateOption", 1, RegistryValueKind.DWord);
                }
                Logger.Log("Enabled Hibernation and added Hibernate option to Start Power menu.", "Success");
            } catch (Exception ex) {
                Logger.Log("Hibernation config error: " + ex.Message, "Error");
            }
        }

        private static void ApplyDisableStickyKeys() {
            try {
                using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Accessibility\StickyKeys")) {
                    key?.SetValue("Flags", "506", RegistryValueKind.String);
                }
                using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Accessibility\ToggleKeys")) {
                    key?.SetValue("Flags", "58", RegistryValueKind.String);
                }
                using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Accessibility\Keyboard Response")) {
                    key?.SetValue("Flags", "122", RegistryValueKind.String);
                }

                ModifyDefaultUserProfile((hive) => {
                    using (var key = Registry.Users.CreateSubKey(hive + @"\Control Panel\Accessibility\StickyKeys")) {
                        key?.SetValue("Flags", "506", RegistryValueKind.String);
                    }
                    using (var key = Registry.Users.CreateSubKey(hive + @"\Control Panel\Accessibility\ToggleKeys")) {
                        key?.SetValue("Flags", "58", RegistryValueKind.String);
                    }
                    using (var key = Registry.Users.CreateSubKey(hive + @"\Control Panel\Accessibility\Keyboard Response")) {
                        key?.SetValue("Flags", "122", RegistryValueKind.String);
                    }
                });
                Logger.Log("Disabled Sticky Keys and Toggle Keys shortcut prompts.", "Success");
            } catch (Exception ex) {
                Logger.Log("Sticky keys config error: " + ex.Message, "Error");
            }
        }

        public static void ModifyDefaultUserProfile(Action<string> registryAction) {
            string defNtUser = @"C:\Users\Default\NTUSER.DAT";
            if (!File.Exists(defNtUser)) return;

            string tempKey = "HMT_DefUser_" + Guid.NewGuid().ToString("N").Substring(0, 8);
            int exitCode = RunProcess("reg.exe", string.Format("load \"HKU\\{0}\" \"{1}\"", tempKey, defNtUser));
            if (exitCode == 0) {
                try {
                    registryAction(tempKey);
                } finally {
                    RunProcess("reg.exe", string.Format("unload \"HKU\\{0}\"", tempKey));
                }
            }
        }

        private static int RunProcess(string exe, string args) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = exe,
                    Arguments = args,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    return proc.ExitCode;
                }
            } catch {
                return -1;
            }
        }
    }

    // --- Bloatware Cleanup Engine ---
    public static class BloatCleanupEngine {
        public static readonly string[] BloatApps = new string[] {
            "*TikTok*",
            "*Instagram*",
            "*Facebook*",
            "*Spotify*",
            "*Disney*",
            "*Netflix*",
            "*PrimeVideo*",
            "*WhatsApp*",
            "*LinkedIn*",
            "*LinkedInForWindows*",
            "*Clipchamp*",
            "*McAfee*",
            "*Norton*",
            "*BingNews*",
            "*BingWeather*",
            "*WindowsMaps*",
            "*ZuneVideo*",
            "*ZuneMusic*",
            "*Cortana*",
            "*MicrosoftSolitaireCollection*",
            "*GetHelp*",
            "*Getstarted*",
            "*YourPhone*",
            "*windowscommunicationsapps*"
        };

        public static async Task ExecuteBloatCleanupAsync(IProgress<BloatProgressInfo> progress) {
            await Task.Run(() => {
                int total = BloatApps.Length;
                int removed = 0;

                for (int i = 0; i < total; i++) {
                    string app = BloatApps[i];
                    string cleanName = app.Trim('*');
                    int pct = (int)(((i + 1) / (double)(total + 3)) * 100);

                    progress?.Report(new BloatProgressInfo {
                        Status = string.Format("Removing Bloatware: {0} ({1} of {2})", cleanName, i + 1, total),
                        Detail = "Checking AppX user and provisioned package registrations...",
                        ProgressPercentage = pct
                    });

                    try {
                        string script = string.Format(
                            "Get-AppxPackage -Name '{0}' -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; " +
                            "Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {{ $_.DisplayName -like '{0}' -or $_.PackageName -like '{0}' }} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue",
                            app
                        );
                        RunPowerShellScript(script);
                        removed++;
                    } catch { }
                }

                // Phase 2: Telemetry & Services
                progress?.Report(new BloatProgressInfo {
                    Status = "Optimizing System: Disabling Telemetry & Diagnostic Services...",
                    Detail = "Configuring DiagTrack and dmwappushservice policies...",
                    ProgressPercentage = 85
                });

                try {
                    RunProcess("sc.exe", "stop DiagTrack");
                    RunProcess("sc.exe", "config DiagTrack start= disabled");
                    RunProcess("sc.exe", "stop dmwappushservice");
                    RunProcess("sc.exe", "config dmwappushservice start= disabled");

                    using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\DataCollection")) {
                        key?.SetValue("AllowTelemetry", 0, RegistryValueKind.DWord);
                    }
                    using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
                        key?.SetValue("DisableWindowsConsumerFeatures", 1, RegistryValueKind.DWord);
                        key?.SetValue("DisableCloudOptimizedContent", 1, RegistryValueKind.DWord);
                    }
                } catch { }

                // Phase 3: Bing Search & Ads
                progress?.Report(new BloatProgressInfo {
                    Status = "Optimizing System: Disabling Bing Search & Web Ads...",
                    Detail = "Applying explorer and search policies...",
                    ProgressPercentage = 95
                });

                try {
                    using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
                        key?.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                    }
                    using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
                        key?.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                        key?.SetValue("ConnectedSearchUseWeb", 0, RegistryValueKind.DWord);
                        key?.SetValue("AllowCortana", 0, RegistryValueKind.DWord);
                    }
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Policies\Microsoft\Windows\Explorer")) {
                        key?.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                    }
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Search")) {
                        key?.SetValue("BingSearchEnabled", 0, RegistryValueKind.DWord);
                    }
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
                        key?.SetValue("Enabled", 0, RegistryValueKind.DWord);
                    }
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Privacy")) {
                        key?.SetValue("TailoredExperiencesWithDiagnosticDataEnabled", 0, RegistryValueKind.DWord);
                    }

                    SetupOptionsEngine.ModifyDefaultUserProfile((hive) => {
                        using (var key = Registry.Users.CreateSubKey(hive + @"\Software\Policies\Microsoft\Windows\Explorer")) {
                            key?.SetValue("DisableSearchBoxSuggestions", 1, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.Users.CreateSubKey(hive + @"\Software\Microsoft\Windows\CurrentVersion\Search")) {
                            key?.SetValue("BingSearchEnabled", 0, RegistryValueKind.DWord);
                        }
                        using (var key = Registry.Users.CreateSubKey(hive + @"\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
                            key?.SetValue("Enabled", 0, RegistryValueKind.DWord);
                        }
                    });
                } catch { }

                progress?.Report(new BloatProgressInfo {
                    Status = "Bloat Cleanup Complete",
                    Detail = "Finished removing bloatware and optimizing policies.",
                    ProgressPercentage = 100
                });
            });
        }

        private static void RunPowerShellScript(string script) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = "powershell.exe",
                    Arguments = "-NoProfile -NonInteractive -Command \"" + script.Replace("\"", "\\\"") + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                }
            } catch { }
        }

        private static int RunProcess(string exe, string args) {
            try {
                var psi = new ProcessStartInfo {
                    FileName = exe,
                    Arguments = args,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    return proc.ExitCode;
                }
            } catch {
                return -1;
            }
        }
    }

    public class BloatProgressInfo {
        public string Status { get; set; }
        public string Detail { get; set; }
        public int ProgressPercentage { get; set; }
    }

    // --- Programs & Software Catalog Engine ---
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
        public static List<SoftwareItem> GetCatalog() {
            var list = new List<SoftwareItem>();
            // Browsers & Comms
            list.Add(new SoftwareItem("Google Chrome", "Browsers & Comms", "Google.Chrome"));
            list.Add(new SoftwareItem("Mozilla Firefox", "Browsers & Comms", "Mozilla.Firefox"));
            list.Add(new SoftwareItem("Brave Browser", "Browsers & Comms", "Brave.Brave"));
            list.Add(new SoftwareItem("Discord", "Browsers & Comms", "Discord.Discord"));
            list.Add(new SoftwareItem("Microsoft Teams", "Browsers & Comms", "Microsoft.Teams"));
            list.Add(new SoftwareItem("Zoom", "Browsers & Comms", "Zoom.Zoom"));
            list.Add(new SoftwareItem("Slack", "Browsers & Comms", "SlackTechnologies.Slack"));
            list.Add(new SoftwareItem("Telegram Desktop", "Browsers & Comms", "Telegram.TelegramDesktop"));
            list.Add(new SoftwareItem("Mozilla Thunderbird", "Browsers & Comms", "Mozilla.Thunderbird"));

            // Productivity
            list.Add(new SoftwareItem("7-Zip", "Productivity", "7zip.7zip"));
            list.Add(new SoftwareItem("WinRAR", "Productivity", "RARLab.WinRAR"));
            list.Add(new SoftwareItem("Notepad++", "Productivity", "Notepad++.Notepad++"));
            list.Add(new SoftwareItem("Adobe Acrobat Reader", "Productivity", "Adobe.Acrobat.Reader.64-bit"));
            list.Add(new SoftwareItem("Adobe Creative Cloud", "Productivity", "Adobe.CreativeCloud"));
            list.Add(new SoftwareItem("Microsoft Office (64-Bit)", "Productivity", "", "MSOffice"));
            list.Add(new SoftwareItem("Outlook Classic", "Productivity", "", "MSOutlook"));
            list.Add(new SoftwareItem("LibreOffice", "Productivity", "TheDocumentFoundation.LibreOffice"));
            list.Add(new SoftwareItem("Microsoft PowerToys", "Productivity", "Microsoft.PowerToys"));
            list.Add(new SoftwareItem("Everything Search", "Productivity", "voidtools.Everything"));
            list.Add(new SoftwareItem("ShareX", "Productivity", "ShareX.ShareX"));
            list.Add(new SoftwareItem("Greenshot", "Productivity", "Greenshot.Greenshot"));

            // IT & Dev Tools
            list.Add(new SoftwareItem("Visual Studio Code", "IT & Dev Tools", "Microsoft.VisualStudioCode"));
            list.Add(new SoftwareItem("Git for Windows", "IT & Dev Tools", "Git.Git"));
            list.Add(new SoftwareItem("Python 3.12", "IT & Dev Tools", "Python.Python.3.12"));
            list.Add(new SoftwareItem("Node.js LTS", "IT & Dev Tools", "OpenJS.NodeJS.LTS"));
            list.Add(new SoftwareItem("Windows Terminal", "IT & Dev Tools", "Microsoft.WindowsTerminal"));
            list.Add(new SoftwareItem("PuTTY", "IT & Dev Tools", "PuTTY.PuTTY"));
            list.Add(new SoftwareItem("WinSCP", "IT & Dev Tools", "WinSCP.WinSCP"));
            list.Add(new SoftwareItem("Wireshark", "IT & Dev Tools", "WiresharkFoundation.Wireshark"));
            list.Add(new SoftwareItem("Twingate Client", "IT & Dev Tools", "Twingate.Client"));
            list.Add(new SoftwareItem("Tailscale", "IT & Dev Tools", "Tailscale.Tailscale"));
            list.Add(new SoftwareItem("AnyDesk", "IT & Dev Tools", "AnyDeskSoftwareGmbH.AnyDesk"));
            list.Add(new SoftwareItem("TeamViewer", "IT & Dev Tools", "TeamViewer.TeamViewer"));

            // Media & Design
            list.Add(new SoftwareItem("VLC Media Player", "Media & Design", "VideoLAN.VLC"));
            list.Add(new SoftwareItem("Spotify", "Media & Design", "Spotify.Spotify"));
            list.Add(new SoftwareItem("OBS Studio", "Media & Design", "OBSProject.OBSStudio"));
            list.Add(new SoftwareItem("Audacity", "Media & Design", "Audacity.Audacity"));
            list.Add(new SoftwareItem("HandBrake", "Media & Design", "HandBrake.HandBrake"));
            list.Add(new SoftwareItem("GIMP", "Media & Design", "GIMP.GIMP"));
            list.Add(new SoftwareItem("Inkscape", "Media & Design", "Inkscape.Inkscape"));
            list.Add(new SoftwareItem("K-Lite Codec Pack Mega", "Media & Design", "CodecGuide.K-LiteCodecPack.Mega"));

            // Cloud & Gaming
            list.Add(new SoftwareItem("Google Drive", "Cloud & Gaming", "Google.Drive"));
            list.Add(new SoftwareItem("Dropbox", "Cloud & Gaming", "Dropbox.Dropbox"));
            list.Add(new SoftwareItem("Steam", "Cloud & Gaming", "Valve.Steam"));
            list.Add(new SoftwareItem("Epic Games Launcher", "Cloud & Gaming", "EpicGames.EpicGamesLauncher"));
            list.Add(new SoftwareItem("GOG Galaxy", "Cloud & Gaming", "GOG.Galaxy"));
            list.Add(new SoftwareItem("CPUID HWMonitor", "Cloud & Gaming", "CPUID.HWMonitor"));
            list.Add(new SoftwareItem("CPUID CPU-Z", "Cloud & Gaming", "CPUID.CPU-Z"));
            list.Add(new SoftwareItem("TechPowerUp GPU-Z", "Cloud & Gaming", "TechPowerUp.GPU-Z"));
            list.Add(new SoftwareItem("MSI Afterburner", "Cloud & Gaming", "Guru3D.Afterburner"));

            return list;
        }

        public static bool IsProgramInstalled(SoftwareItem item) {
            if (item == null) return false;
            string pName = item.Name;
            string wId = item.WingetID;

            string[] uninstallKeys = new string[] {
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            };

            foreach (var rootKey in new RegistryKey[] { Registry.LocalMachine, Registry.CurrentUser }) {
                foreach (var sub in uninstallKeys) {
                    try {
                        using (var key = rootKey.OpenSubKey(sub)) {
                            if (key != null) {
                                foreach (var appSubName in key.GetSubKeyNames()) {
                                    using (var appKey = key.OpenSubKey(appSubName)) {
                                        string dn = appKey?.GetValue("DisplayName")?.ToString() ?? "";
                                        if (dn.IndexOf(pName, StringComparison.OrdinalIgnoreCase) >= 0) return true;
                                        if (!string.IsNullOrEmpty(wId)) {
                                            string[] parts = wId.Split('.');
                                            string tail = parts[parts.Length - 1];
                                            if (tail.Length >= 4 && dn.IndexOf(tail, StringComparison.OrdinalIgnoreCase) >= 0) return true;
                                        }
                                    }
                                }
                            }
                        }
                    } catch { }
                }
            }
            return false;
        }

        public static async Task DeployOfficeAsync(bool isAll, IProgress<BloatProgressInfo> progress, CancellationToken ct) {
            string displayName = isAll ? "Microsoft Office (x64)" : "Outlook (Classic)";
            string productID = isAll ? "O365BusinessRetail" : "OutlookRetail";
            string zipName = "o365_payload.zip";
            string cdnUrl = "https://cdn.hatsthings.com/O365/" + zipName;

            string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string extDir = Path.Combine(appData, "Programs", "Hats-Multitool", "ExtPrograms");
            string officeDir = Path.Combine(extDir, "MicrosoftOffice");
            Directory.CreateDirectory(officeDir);

            string zipPath = Path.Combine(extDir, zipName);

            progress?.Report(new BloatProgressInfo {
                Status = "Checking " + displayName + " payload...",
                Detail = "Looking for local cached payload...",
                ProgressPercentage = 10
            });

            bool existingData = Directory.Exists(Path.Combine(officeDir, "Office", "Data"));
            bool existingSetup = File.Exists(Path.Combine(officeDir, "setup.exe"));

            if (!existingData || !existingSetup) {
                if (!File.Exists(zipPath)) {
                    progress?.Report(new BloatProgressInfo {
                        Status = "Downloading " + displayName + "...",
                        Detail = "Connecting to CDN...",
                        ProgressPercentage = 15
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
                                        int pct = totalBytes > 0 ? (int)((totalRead * 70) / totalBytes) + 15 : 50;
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
            if (!File.Exists(setupExe)) {
                // Download official ODT if setup.exe is missing
                string odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18526-20146.exe";
                string odtPath = Path.Combine(officeDir, "odt.exe");
                using (var wc = new WebClient()) {
                    wc.DownloadFile(odtUrl, odtPath);
                }
                var psiOdt = new ProcessStartInfo {
                    FileName = odtPath,
                    Arguments = "/quiet /extract:\"" + officeDir + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (var proc = Process.Start(psiOdt)) {
                    proc.WaitForExit();
                }
            }

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

    // --- External Tool Execution Engine ---
    public class ExternalToolItem {
        public string Name { get; set; }
        public string Description { get; set; }
        public string Category { get; set; }
        public string ActionType { get; set; } // "Command", "Download", "InternalDialog"
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
}
