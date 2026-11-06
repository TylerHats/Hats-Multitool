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

    // --- Network Connectivity & Diagnostics Helper ---
    public static class NetworkConnectivityHelper {
        private static readonly string[] ConnectivityProbeUrls = new string[] {
            "http://www.msftconnecttest.com/connecttest.txt",
            "https://raw.githubusercontent.com/TylerHats/Hats-Multitool/main/HatsMultitoolVersion.txt",
            "https://hatsthings.com/MultitoolFiles/HatsMultitoolVersion.txt"
        };

        public static bool HasActiveNetworkAdapter(out string adapterError) {
            adapterError = null;
            try {
                if (!NetworkInterface.GetIsNetworkAvailable()) {
                    adapterError = "No active network connection detected. Please connect an Ethernet cable or join a Wi-Fi network and try again.";
                    return false;
                }

                var interfaces = NetworkInterface.GetAllNetworkInterfaces();
                bool foundUp = false;
                foreach (var ni in interfaces) {
                    if (ni.OperationalStatus == OperationalStatus.Up &&
                        ni.NetworkInterfaceType != NetworkInterfaceType.Loopback &&
                        ni.NetworkInterfaceType != NetworkInterfaceType.Tunnel) {
                        foundUp = true;
                        break;
                    }
                }

                if (!foundUp) {
                    adapterError = "All network adapters are currently disconnected. Please verify your Ethernet or Wi-Fi connection.";
                    return false;
                }
                return true;
            } catch {
                return true;
            }
        }

        public static async Task<Tuple<bool, string>> CheckInternetAccessAsync(int timeoutMs = 4000) {
            string adapterErr;
            if (!HasActiveNetworkAdapter(out adapterErr)) {
                return Tuple.Create(false, adapterErr);
            }

            Exception lastException = null;
            foreach (var probeUrl in ConnectivityProbeUrls) {
                try {
                    using (var cts = new CancellationTokenSource(timeoutMs))
                    using (var client = new HttpClient()) {
                        client.Timeout = TimeSpan.FromMilliseconds(timeoutMs);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) HatsMultitool");
                        using (var req = new HttpRequestMessage(HttpMethod.Get, probeUrl))
                        using (var resp = await client.SendAsync(req, HttpCompletionOption.ResponseHeadersRead, cts.Token)) {
                            if ((int)resp.StatusCode >= 200 && (int)resp.StatusCode < 500) {
                                return Tuple.Create(true, string.Empty);
                            }
                        }
                    }
                } catch (Exception ex) {
                    lastException = ex;
                }
            }

            // Fallback ICMP ping test to 1.1.1.1 / 8.8.8.8 to distinguish DNS failure vs total offline
            try {
                using (var ping = new Ping()) {
                    var reply = await ping.SendPingAsync("1.1.1.1", 2000);
                    if (reply != null && reply.Status == IPStatus.Success) {
                        if (lastException != null) {
                            return Tuple.Create(false, "Network is connected to the internet, but DNS resolution or HTTPS traffic is failing: " + FormatNetworkException(lastException));
                        }
                        return Tuple.Create(true, string.Empty);
                    }
                }
            } catch { }

            string detail = lastException != null
                ? FormatNetworkException(lastException)
                : "Unable to reach external internet servers. Please check your gateway, firewall, or proxy settings.";
            return Tuple.Create(false, "No internet access detected. " + detail);
        }

        public static string FormatNetworkException(Exception ex, string contextTarget = null) {
            if (ex == null) return "Unknown network error.";

            string adapterErr;
            if (!HasActiveNetworkAdapter(out adapterErr)) {
                return adapterErr;
            }

            string targetPrefix = string.IsNullOrEmpty(contextTarget) ? "" : ("[" + contextTarget + "] ");

            // Unwrap AggregateException
            while (ex is AggregateException && ex.InnerException != null) {
                ex = ex.InnerException;
            }

            if (ex is TaskCanceledException || ex is OperationCanceledException || ex is System.TimeoutException) {
                return targetPrefix + "The connection timed out while waiting for the remote server to respond.";
            }

            // Walk inner exceptions for SocketException / WebException
            Exception cur = ex;
            SocketException sockEx = null;
            WebException webEx = null;
            while (cur != null) {
                if (sockEx == null && cur is SocketException) sockEx = (SocketException)cur;
                if (webEx == null && cur is WebException) webEx = (WebException)cur;
                cur = cur.InnerException;
            }

            if (sockEx != null) {
                switch (sockEx.SocketErrorCode) {
                    case SocketError.HostNotFound:
                    case SocketError.NoData:
                    case SocketError.TryAgain:
                        return targetPrefix + "DNS resolution failed (could not resolve hostname). Please check your DNS server settings.";
                    case SocketError.TimedOut:
                        return targetPrefix + "Network connection timed out while contacting the remote host.";
                    case SocketError.ConnectionRefused:
                        return targetPrefix + "The remote server actively refused the connection.";
                    case SocketError.ConnectionReset:
                    case SocketError.ConnectionAborted:
                        return targetPrefix + "The network connection was unexpectedly reset or aborted by the remote host or firewall.";
                    case SocketError.NetworkUnreachable:
                    case SocketError.HostUnreachable:
                    case SocketError.NetworkDown:
                        return targetPrefix + "The network or remote host is unreachable. Verify your default gateway and internet routing.";
                }
            }

            if (webEx != null) {
                switch (webEx.Status) {
                    case WebExceptionStatus.NameResolutionFailure:
                        return targetPrefix + "DNS lookup failed: the remote hostname could not be resolved.";
                    case WebExceptionStatus.Timeout:
                        return targetPrefix + "The network request timed out.";
                    case WebExceptionStatus.ConnectFailure:
                        return targetPrefix + "Unable to establish a TCP connection to the remote server.";
                    case WebExceptionStatus.TrustFailure:
                    case WebExceptionStatus.SecureChannelFailure:
                        return targetPrefix + "SSL/TLS security handshake failed. Verify that the system clock is accurate and HTTPS inspection is not blocking traffic.";
                    case WebExceptionStatus.ProtocolError:
                        var httpResp = webEx.Response as HttpWebResponse;
                        if (httpResp != null) {
                            return string.Format("{0}Remote server returned HTTP {1} ({2}).", targetPrefix, (int)httpResp.StatusCode, httpResp.StatusDescription);
                        }
                        break;
                }
            }

            // Inspect combined exception messages
            var sb = new StringBuilder();
            cur = ex;
            while (cur != null) {
                if (!string.IsNullOrWhiteSpace(cur.Message)) {
                    if (sb.Length > 0) sb.Append(" -> ");
                    sb.Append(cur.Message.Trim());
                }
                cur = cur.InnerException;
            }
            string combined = sb.ToString();

            if (combined.IndexOf("remote name could not be resolved", StringComparison.OrdinalIgnoreCase) >= 0 ||
                combined.IndexOf("No such host is known", StringComparison.OrdinalIgnoreCase) >= 0) {
                return targetPrefix + "DNS lookup failed: unable to resolve remote server hostname.";
            }
            if (combined.IndexOf("SSL", StringComparison.OrdinalIgnoreCase) >= 0 ||
                combined.IndexOf("TLS", StringComparison.OrdinalIgnoreCase) >= 0 ||
                combined.IndexOf("secure channel", StringComparison.OrdinalIgnoreCase) >= 0 ||
                combined.IndexOf("certificate", StringComparison.OrdinalIgnoreCase) >= 0) {
                return targetPrefix + "SSL/TLS secure connection failed. Check system date/time or network firewall settings.";
            }
            var mStatus = Regex.Match(combined, @"\b([45]\d\d)\b");
            if (mStatus.Success) {
                string code = mStatus.Groups[1].Value;
                if (code == "404") return targetPrefix + "Remote file or manifest was not found on the server (HTTP 404).";
                if (code == "403") return targetPrefix + "Access to the remote resource was denied (HTTP 403 Forbidden).";
                if (code == "429") return targetPrefix + "Too many requests to the remote server (HTTP 429 Rate Limited).";
                if (code.StartsWith("5")) return targetPrefix + "Remote server encountered an internal error (HTTP " + code + ").";
            }

            return targetPrefix + (string.IsNullOrEmpty(combined) ? ex.Message : combined);
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

        private static readonly Dictionary<string, string> IanaToWindowsMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
            { "America/New_York", "Eastern Standard Time" },
            { "America/Detroit", "Eastern Standard Time" },
            { "America/Kentucky/Louisville", "Eastern Standard Time" },
            { "America/Kentucky/Monticello", "Eastern Standard Time" },
            { "America/Indiana/Indianapolis", "Eastern Standard Time" },
            { "America/Indiana/Vincennes", "Eastern Standard Time" },
            { "America/Indiana/Winamac", "Eastern Standard Time" },
            { "America/Indiana/Marengo", "Eastern Standard Time" },
            { "America/Indiana/Petersburg", "Eastern Standard Time" },
            { "America/Indiana/Vevay", "Eastern Standard Time" },
            { "America/Toronto", "Eastern Standard Time" },
            { "America/Montreal", "Eastern Standard Time" },
            { "America/Chicago", "Central Standard Time" },
            { "America/Indiana/Knox", "Central Standard Time" },
            { "America/Indiana/Tell_City", "Central Standard Time" },
            { "America/Menominee", "Central Standard Time" },
            { "America/North_Dakota/Center", "Central Standard Time" },
            { "America/North_Dakota/New_Salem", "Central Standard Time" },
            { "America/North_Dakota/Beulah", "Central Standard Time" },
            { "America/Winnipeg", "Central Standard Time" },
            { "America/Denver", "Mountain Standard Time" },
            { "America/Boise", "Mountain Standard Time" },
            { "America/Edmonton", "Mountain Standard Time" },
            { "America/Phoenix", "US Mountain Standard Time" },
            { "America/Los_Angeles", "Pacific Standard Time" },
            { "America/Vancouver", "Pacific Standard Time" },
            { "America/Tijuana", "Pacific Standard Time" },
            { "America/Anchorage", "Alaskan Standard Time" },
            { "America/Juneau", "Alaskan Standard Time" },
            { "America/Sitka", "Alaskan Standard Time" },
            { "America/Metlakatla", "Alaskan Standard Time" },
            { "America/Nome", "Alaskan Standard Time" },
            { "America/Yakutat", "Alaskan Standard Time" },
            { "America/Honolulu", "Hawaiian Standard Time" },
            { "Europe/London", "GMT Standard Time" },
            { "Europe/Dublin", "GMT Standard Time" },
            { "Europe/Paris", "W. Europe Standard Time" },
            { "Europe/Berlin", "W. Europe Standard Time" },
            { "Europe/Rome", "W. Europe Standard Time" },
            { "Europe/Madrid", "W. Europe Standard Time" },
            { "Europe/Amsterdam", "W. Europe Standard Time" },
            { "Europe/Brussels", "W. Europe Standard Time" }
        };

        public static string GetCurrentTimeZoneId() {
            try {
                return TimeZoneInfo.Local.Id;
            } catch {
                return "Eastern Standard Time";
            }
        }

        public static async Task<string> DetectTimeZoneFromIpAsync(CancellationToken ct = default(CancellationToken)) {
            try {
                using (var client = new HttpClient()) {
                    client.Timeout = TimeSpan.FromSeconds(2.5);
                    client.DefaultRequestHeaders.Add("User-Agent", "HMT-Client");
                    string json = await client.GetStringAsync("http://ip-api.com/json/?fields=timezone");
                    var match = Regex.Match(json, @"""timezone""\s*:\s*""([^""]+)""");
                    if (match.Success) {
                        string iana = match.Groups[1].Value.Trim();
                        string winId;
                        if (IanaToWindowsMap.TryGetValue(iana, out winId)) {
                            return winId;
                        }
                        foreach (var tz in TimeZoneInfo.GetSystemTimeZones()) {
                            if (tz.Id.Equals(iana, StringComparison.OrdinalIgnoreCase)) {
                                return tz.Id;
                            }
                        }
                    }
                }
            } catch { }
            return null;
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

        public static void GetLocalUsersAndAdmins(out HashSet<string> existingUsers, out HashSet<string> adminUsers) {
            existingUsers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            adminUsers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            try {
                var psiUsers = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = "user",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true
                };
                using (var proc = Process.Start(psiUsers)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit(3000);
                    bool inBody = false;
                    var lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (var rawLine in lines) {
                        string line = rawLine.Trim();
                        if (line.StartsWith("---")) {
                            inBody = true;
                            continue;
                        }
                        if (!inBody) continue;
                        if (line.StartsWith("The command completed", StringComparison.OrdinalIgnoreCase)) break;

                        // net.exe user prints in 25-character columns
                        var parts = Regex.Split(rawLine, @"\s{2,}");
                        foreach (var p in parts) {
                            string u = p.Trim();
                            if (!string.IsNullOrEmpty(u)) {
                                existingUsers.Add(u);
                            }
                        }
                    }
                }
            } catch { }

            try {
                var psiAdmins = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = "localgroup Administrators",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true
                };
                using (var proc = Process.Start(psiAdmins)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit(3000);
                    bool inBody = false;
                    var lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (var rawLine in lines) {
                        string line = rawLine.Trim();
                        if (line.StartsWith("---")) {
                            inBody = true;
                            continue;
                        }
                        if (!inBody) continue;
                        if (line.StartsWith("The command completed", StringComparison.OrdinalIgnoreCase)) break;

                        adminUsers.Add(line);
                        int slashIdx = line.LastIndexOf('\\');
                        if (slashIdx >= 0 && slashIdx + 1 < line.Length) {
                            string shortName = line.Substring(slashIdx + 1).Trim();
                            if (!string.IsNullOrEmpty(shortName)) {
                                adminUsers.Add(shortName);
                                existingUsers.Add(shortName);
                            }
                        }
                    }
                }
            } catch { }
        }

        public static void QuerySingleUserAccountStatus(string username, out bool exists, out bool isAdmin) {
            exists = false;
            isAdmin = false;
            if (string.IsNullOrWhiteSpace(username)) return;

            try {
                var psi = new ProcessStartInfo {
                    FileName = "net.exe",
                    Arguments = string.Format("user \"{0}\"", username.Trim()),
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (var proc = Process.Start(psi)) {
                    string output = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit(3000);
                    if (proc.ExitCode == 0 && !string.IsNullOrEmpty(output)) {
                        exists = true;
                        if (Regex.IsMatch(output, @"\*\s*Administrators\b", RegexOptions.IgnoreCase)) {
                            isAdmin = true;
                        }
                    }
                }
            } catch { }
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

        public static bool ModifyUser(string username, string password, bool updatePassword, bool isAutoLogin, bool addToAdmin, bool removeFromAdmin, bool isDontExpire, out string errorMessage) {
            errorMessage = "";
            try {
                if (updatePassword) {
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
                }

                if (addToAdmin) {
                    var psiAdmin = new ProcessStartInfo {
                        FileName = "net.exe",
                        Arguments = string.Format("localgroup Administrators \"{0}\" /add", username),
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    };
                    using (var procAdmin = Process.Start(psiAdmin)) {
                        procAdmin.WaitForExit();
                        if (procAdmin.ExitCode != 0 && !updatePassword) {
                            errorMessage = ExtractProcessError(procAdmin);
                            return false;
                        }
                    }
                } else if (removeFromAdmin) {
                    var psiRemoveAdmin = new ProcessStartInfo {
                        FileName = "net.exe",
                        Arguments = string.Format("localgroup Administrators \"{0}\" /delete", username),
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    };
                    using (var procRemoveAdmin = Process.Start(psiRemoveAdmin)) {
                        procRemoveAdmin.WaitForExit();
                        if (procRemoveAdmin.ExitCode != 0 && !updatePassword) {
                            errorMessage = ExtractProcessError(procRemoveAdmin);
                            return false;
                        }
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

                Logger.Log("Successfully modified user: " + username, "Success");
                return true;
            } catch (Exception ex) {
                errorMessage = ex.Message;
                Logger.Log("Account modification failed: " + ex.Message, "Error");
                return false;
            }
        }

        public static bool UpdateUserPassword(string username, string password, bool isAutoLogin, bool isAdmin, bool isDontExpire, out string errorMessage) {
            return ModifyUser(username, password, true, isAutoLogin, isAdmin, false, isDontExpire, out errorMessage);
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
                using (var key = Registry.LocalMachine.OpenSubKey(@"HARDWARE\DESCRIPTION\System\BIOS", false)) {
                    if (key != null) {
                        string sysSerial = (key.GetValue("SystemSerialNumber") as string)?.Trim();
                        if (!string.IsNullOrEmpty(sysSerial) &&
                            !sysSerial.Equals("System Serial Number", StringComparison.OrdinalIgnoreCase) &&
                            !sysSerial.Equals("To be filled by O.E.M.", StringComparison.OrdinalIgnoreCase) &&
                            !sysSerial.Equals("Default string", StringComparison.OrdinalIgnoreCase)) {
                            return sysSerial;
                        }
                        string boardSerial = (key.GetValue("BaseBoardSerialNumber") as string)?.Trim();
                        if (!string.IsNullOrEmpty(boardSerial) &&
                            !boardSerial.Equals("To be filled by O.E.M.", StringComparison.OrdinalIgnoreCase) &&
                            !boardSerial.Equals("Default string", StringComparison.OrdinalIgnoreCase)) {
                            return boardSerial;
                        }
                    }
                }
            } catch { }

            try {
                using (var searcher = new ManagementObjectSearcher("SELECT SerialNumber FROM Win32_SystemEnclosure")) {
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
                using (var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", false)) {
                    if (key != null) {
                        string editionId = key.GetValue("EditionID") as string;
                        string productName = key.GetValue("ProductName") as string;
                        if (!string.IsNullOrEmpty(productName)) {
                            return productName.Trim();
                        }
                        if (!string.IsNullOrEmpty(editionId)) {
                            return "Windows " + editionId.Trim();
                        }
                    }
                }
            } catch { }
            return "Windows";
        }

        public static bool IsDomainJoined(out string domainName) {
            domainName = string.Empty;
            try {
                string ipDomain = IPGlobalProperties.GetIPGlobalProperties().DomainName;
                if (!string.IsNullOrWhiteSpace(ipDomain)) {
                    domainName = ipDomain.Trim();
                    return true;
                }
            } catch { }

            try {
                using (var key = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters", false)) {
                    if (key != null) {
                        string regDomain = (key.GetValue("Domain") as string)?.Trim();
                        if (!string.IsNullOrEmpty(regDomain)) {
                            domainName = regDomain;
                            return true;
                        }
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
            } catch (Exception ex) {
                Logger.Log("Failed to rename computer: " + ex.Message, "Error");
                return false;
            }
        }

        public static bool JoinDomain(string domainName) {
            string err;
            return JoinDomain(domainName, out err);
        }

        public static bool JoinDomain(string domainName, out string errorMessage) {
            errorMessage = string.Empty;
            try {
                string psCommand = string.Format(
                    "$ErrorActionPreference = 'Stop'; " +
                    "try {{ " +
                    "    Write-Host 'Attempting to join domain: {0}...' -ForegroundColor Cyan; " +
                    "    Add-Computer -DomainName '{0}' -Credential (Get-Credential) -Restart:$false -Verbose; " +
                    "    Write-Host 'Successfully joined domain {0}!' -ForegroundColor Green; " +
                    "    Start-Sleep -Seconds 2; " +
                    "    exit 0; " +
                    "}} catch {{ " +
                    "    Write-Host ('Domain join failed: ' + $_.Exception.Message) -ForegroundColor Red; " +
                    "    Write-Host 'Press any key to continue...'; " +
                    "    [Console]::ReadKey() | Out-Null; " +
                    "    exit 1; " +
                    "}}", domainName);

                var psi = new ProcessStartInfo {
                    FileName = "powershell.exe",
                    Arguments = "-NoProfile -Command \"" + psCommand + "\"",
                    UseShellExecute = true
                };
                using (var proc = Process.Start(psi)) {
                    if (proc != null) {
                        proc.WaitForExit();
                        bool success = (proc.ExitCode == 0);
                        if (success) {
                            Logger.Log("Joined domain successfully: " + domainName, "Success");
                        } else {
                            errorMessage = "Domain join was cancelled or failed.";
                            Logger.Log("Domain join failed or cancelled for: " + domainName, "Warning");
                        }
                        return success;
                    }
                }
            } catch (Exception ex) {
                errorMessage = ex.Message;
                Logger.Log("Failed to join domain: " + ex.Message, "Error");
                return false;
            }
            return false;
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
                // In Windows 10 and 11, InitialKeyboardIndicators must be set to 2147483650 (0x80000002).
                // Setting 2147483650 on .DEFAULT configures NumLock ON for both the logon screen and newly initialized user profiles.
                using (var key = Registry.Users.CreateSubKey(@".DEFAULT\Control Panel\Keyboard")) {
                    if (key != null) key.SetValue("InitialKeyboardIndicators", "2147483650", RegistryValueKind.String);
                }

                using (var key = Registry.CurrentUser.CreateSubKey(@"Control Panel\Keyboard")) {
                    if (key != null) key.SetValue("InitialKeyboardIndicators", "2147483650", RegistryValueKind.String);
                }

                Logger.Log("Configured NumLock on boot and default profile indicators (2147483650).", "Success");
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

                // Explicitly enable the Hibernate option in the Windows Start / Power menu
                try {
                    using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
                        if (key != null) key.SetValue("ShowHibernateOption", 1, RegistryValueKind.DWord);
                    }
                } catch { }
                try {
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
                        if (key != null) key.SetValue("ShowHibernateOption", 1, RegistryValueKind.DWord);
                    }
                } catch { }
                try {
                    using (var key = Registry.LocalMachine.CreateSubKey(@"SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
                        if (key != null) key.SetValue("ShowHibernateOption", 1, RegistryValueKind.DWord);
                    }
                } catch { }
                try {
                    using (var key = Registry.CurrentUser.CreateSubKey(@"Software\Policies\Microsoft\Windows\Explorer")) {
                        if (key != null) key.SetValue("ShowHibernateOption", 1, RegistryValueKind.DWord);
                    }
                } catch { }
                try {
                    using (var key = Registry.LocalMachine.CreateSubKey(@"SYSTEM\CurrentControlSet\Control\Power")) {
                        if (key != null) key.SetValue("HibernateEnabled", 1, RegistryValueKind.DWord);
                    }
                } catch { }

                Logger.Log("Enabled Windows Hibernation and added Hibernate to Power menu.", "Success");
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
                        Arguments = "-NoProfile -NonInteractive -Command \"" + psBatchScript + "\"",
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
                            using (var svcKey = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\" + s, true)) {
                                if (svcKey != null) {
                                    svcKey.SetValue("Start", 4, RegistryValueKind.DWord);
                                }
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
        public string DetectKeywords { get; set; }
        public string DirectUrl { get; set; }
        public string SilentArgs { get; set; }

        public SoftwareItem(string name, string category, string wingetId, string type = "Winget", string detectKeywords = "", string directUrl = "", string silentArgs = "") {
            Name = name;
            Category = category;
            WingetID = wingetId;
            Type = string.IsNullOrEmpty(type) ? "Winget" : type;
            DetectKeywords = detectKeywords ?? "";
            DirectUrl = directUrl ?? "";
            SilentArgs = silentArgs ?? "";
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
        private static Dictionary<string, List<SoftwareItem>> _cachedCatalog = null;
        private static readonly object _catalogLock = new object();
        private const string PrimaryManifestUrl = "https://raw.githubusercontent.com/TylerHats/Hats-Multitool/main/SoftwareCatalog.json";
        private const string FallbackManifestUrl = "https://hatsthings.com/MultitoolFiles/SoftwareCatalog.json";

        public static async Task PrepareWinGetAsync(IProgress<string> statusProgress = null) {
            await Task.Run(() => {
                try {
                    statusProgress?.Report("Prepping WinGet package manager...");
                    var psi = new ProcessStartInfo {
                        FileName = "winget.exe",
                        Arguments = "source update --disable-interactivity",
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    };
                    using (var proc = Process.Start(psi)) {
                        if (proc != null) {
                            proc.WaitForExit(10000);
                            if (!proc.HasExited) {
                                try { proc.Kill(); } catch { }
                            }
                        }
                    }
                } catch (Exception ex) {
                    Logger.Log("WinGet prep warning: " + ex.Message, "Warning");
                }
            });
        }

        public static async Task<Dictionary<string, List<SoftwareItem>>> FetchSoftwareCatalogAsync(IProgress<string> statusProgress = null, bool forceRefresh = false) {
            if (!forceRefresh) {
                lock (_catalogLock) {
                    if (_cachedCatalog != null && _cachedCatalog.Count > 0) {
                        return _cachedCatalog;
                    }
                }
            }

            var netCheck = await NetworkConnectivityHelper.CheckInternetAccessAsync();
            if (!netCheck.Item1) {
                throw new InvalidOperationException(netCheck.Item2);
            }

            string json = null;
            Exception lastException = null;
            bool gotHttp404Only = false;
            const int maxAttempts = 3;

            for (int attempt = 1; attempt <= maxAttempts; attempt++) {
                if (attempt == 1) {
                    statusProgress?.Report("Obtaining software catalog manifest...");
                } else {
                    statusProgress?.Report(string.Format("Network error obtaining software manifest. Retrying (attempt {0}/{1})...", attempt, maxAttempts));
                    await Task.Delay(1200 * (attempt - 1));
                }

                // 1. Try primary GitHub repository manifest
                try {
                    using (var cts = new CancellationTokenSource(6000))
                    using (var client = new HttpClient()) {
                        client.Timeout = TimeSpan.FromSeconds(6);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) HatsMultitool");
                        using (var resp = await client.GetAsync(PrimaryManifestUrl, cts.Token)) {
                            if (resp.StatusCode == HttpStatusCode.NotFound) {
                                gotHttp404Only = true;
                            }
                            resp.EnsureSuccessStatusCode();
                            json = await resp.Content.ReadAsStringAsync();
                        }
                    }
                } catch (Exception ex) {
                    lastException = ex;
                    Logger.Log(string.Format("SoftwareCatalog primary fetch attempt {0}/{1} failed: {2}", attempt, maxAttempts, ex.Message), "Warning");
                }

                // 2. Try web server fallback manifest
                if (string.IsNullOrEmpty(json)) {
                    try {
                        using (var cts = new CancellationTokenSource(5000))
                        using (var client = new HttpClient()) {
                            client.Timeout = TimeSpan.FromSeconds(5);
                            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) HatsMultitool");
                            using (var resp = await client.GetAsync(FallbackManifestUrl, cts.Token)) {
                                if (resp.StatusCode == HttpStatusCode.NotFound) {
                                    gotHttp404Only = true;
                                }
                                resp.EnsureSuccessStatusCode();
                                json = await resp.Content.ReadAsStringAsync();
                            }
                        }
                    } catch (Exception ex) {
                        lastException = ex;
                        Logger.Log(string.Format("SoftwareCatalog fallback fetch attempt {0}/{1} failed: {2}", attempt, maxAttempts, ex.Message), "Warning");
                    }
                }

                if (!string.IsNullOrEmpty(json)) {
                    break;
                }
            }

            // Local repository file fallback if internet is up and remote returned 404 before initial deployment
            if (string.IsNullOrEmpty(json) && gotHttp404Only) {
                try {
                    string localCandidates = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SoftwareCatalog.json");
                    if (File.Exists(localCandidates)) {
                        json = File.ReadAllText(localCandidates, Encoding.UTF8);
                    } else if (File.Exists("SoftwareCatalog.json")) {
                        json = File.ReadAllText("SoftwareCatalog.json", Encoding.UTF8);
                    }
                } catch { }
            }

            if (string.IsNullOrEmpty(json)) {
                string reason = lastException != null
                    ? NetworkConnectivityHelper.FormatNetworkException(lastException, "SoftwareCatalog.json")
                    : "The remote software manifest returned an empty response.";
                throw new InvalidOperationException("Failed to download the Software Catalog manifest after " + maxAttempts + " attempts.\n\n" + reason);
            }

            statusProgress?.Report("Parsing software catalog manifest...");
            var parsed = ParseSoftwareCatalogJson(json);
            if (parsed == null || parsed.Count == 0) {
                throw new InvalidOperationException("The downloaded Software Catalog manifest could not be parsed or contained no valid entries.");
            }

            lock (_catalogLock) {
                _cachedCatalog = parsed;
            }
            return parsed;
        }

        public static Dictionary<string, List<SoftwareItem>> ParseSoftwareCatalogJson(string json) {
            var categorized = new Dictionary<string, List<SoftwareItem>>();
            if (string.IsNullOrWhiteSpace(json)) return categorized;

            try {
                var objectMatches = Regex.Matches(json, @"\{([^{}]+)\}");
                foreach (Match om in objectMatches) {
                    string block = om.Groups[1].Value;
                    var mName = Regex.Match(block, @"""name""\s*:\s*""((?:\\.|[^""\\])*)""");
                    if (!mName.Success) continue;

                    string name = UnquoteJsonValue(mName.Groups[1].Value);
                    if (string.IsNullOrEmpty(name)) continue;

                    var mCat = Regex.Match(block, @"""category""\s*:\s*""((?:\\.|[^""\\])*)""");
                    var mWinget = Regex.Match(block, @"""wingetId""\s*:\s*""((?:\\.|[^""\\])*)""");
                    var mType = Regex.Match(block, @"""type""\s*:\s*""((?:\\.|[^""\\])*)""");
                    var mDetect = Regex.Match(block, @"""detect""\s*:\s*""((?:\\.|[^""\\])*)""");
                    var mUrl = Regex.Match(block, @"""url""\s*:\s*""((?:\\.|[^""\\])*)""");
                    var mSilent = Regex.Match(block, @"""silentArgs""\s*:\s*""((?:\\.|[^""\\])*)""");

                    string category = mCat.Success ? UnquoteJsonValue(mCat.Groups[1].Value) : "General";
                    if (string.IsNullOrEmpty(category)) category = "General";
                    string wingetId = mWinget.Success ? UnquoteJsonValue(mWinget.Groups[1].Value) : "";
                    string type = mType.Success ? UnquoteJsonValue(mType.Groups[1].Value) : "Winget";
                    string detect = mDetect.Success ? UnquoteJsonValue(mDetect.Groups[1].Value) : "";
                    string url = mUrl.Success ? UnquoteJsonValue(mUrl.Groups[1].Value) : "";
                    string silentArgs = mSilent.Success ? UnquoteJsonValue(mSilent.Groups[1].Value) : "";

                    List<SoftwareItem> list;
                    if (!categorized.TryGetValue(category, out list)) {
                        list = new List<SoftwareItem>();
                        categorized[category] = list;
                    }
                    list.Add(new SoftwareItem(name, category, wingetId, type, detect, url, silentArgs));
                }
            } catch (Exception ex) {
                Logger.Log("Error parsing SoftwareCatalog.json: " + ex.Message, "Error");
            }

            return categorized;
        }

        private static string UnquoteJsonValue(string raw) {
            if (string.IsNullOrEmpty(raw)) return string.Empty;
            return raw.Replace("\\\"", "\"").Replace("\\\\", "\\").Trim();
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
                                                    if (!string.IsNullOrEmpty(dn)) set.Add(dn.Trim());
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

            // Special path check for Google Drive for Desktop if not yet in Uninstall or to confirm presence
            if (string.Equals(item.WingetID, "Google.Drive", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(item.Name, "Google Drive", StringComparison.OrdinalIgnoreCase)) {
                foreach (var dn in installedSet) {
                    if (dn.IndexOf("Google Drive", StringComparison.OrdinalIgnoreCase) >= 0) {
                        return true;
                    }
                }
                try {
                    string gdriveDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Google", "Drive File Stream");
                    if (Directory.Exists(gdriveDir) && Directory.GetFiles(gdriveDir, "GoogleDriveFS.exe", SearchOption.AllDirectories).Length > 0) {
                        return true;
                    }
                } catch { }
                return false;
            }

            string keywordsRaw = !string.IsNullOrWhiteSpace(item.DetectKeywords) ? item.DetectKeywords : item.Name;
            if (string.IsNullOrWhiteSpace(keywordsRaw)) return false;

            string[] keywords = keywordsRaw.Split(new char[] { '|' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var rawKw in keywords) {
                string kw = rawKw.Trim();
                if (string.IsNullOrEmpty(kw)) continue;

                string pattern = @"(^|[^A-Za-z0-9])" + Regex.Escape(kw) + @"($|[^A-Za-z0-9])";
                foreach (var dn in installedSet) {
                    if (Regex.IsMatch(dn, pattern, RegexOptions.IgnoreCase)) {
                        return true;
                    }
                }
            }

            return false;
        }

        public static InstallerPackageInfo GetWingetInstallerInfo(SoftwareItem item, CancellationToken ct) {
            var info = new InstallerPackageInfo();
            if (item == null) return info;

            // Use manifest-supplied direct URL and/or silent args when present
            if (!string.IsNullOrEmpty(item.SilentArgs)) {
                info.SilentArgs = Environment.ExpandEnvironmentVariables(item.SilentArgs);
            }
            if (!string.IsNullOrEmpty(item.DirectUrl)) {
                info.InstallerUrl = item.DirectUrl;
                if (string.IsNullOrEmpty(info.SilentArgs)) {
                    info.SilentArgs = info.InstallerUrl.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) ? "/qn /norestart" : "/S";
                }
                return info;
            }

            string wingetId = item.WingetID;
            if (string.IsNullOrEmpty(wingetId)) return info;

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
                // 1. Resolve package URL and silent args from manifest or WinGet
                var info = await Task.Run(() => GetWingetInstallerInfo(item, ct));
                ct.ThrowIfCancellationRequested();

                if (!string.IsNullOrEmpty(info.InstallerUrl)) {
                    // 2. In-house HTTP download with speed tracking
                    string ext = ".exe";
                    if (info.InstallerUrl.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) || (info.InstallerType != null && info.InstallerType.IndexOf("msi", StringComparison.OrdinalIgnoreCase) >= 0)) {
                        ext = ".msi";
                    }
                    string tempFile = Path.Combine(Path.GetTempPath(), "hmt_installer_" + Guid.NewGuid().ToString("N").Substring(0, 8) + ext);

                    bool downloaded = false;
                    for (int attempt = 1; attempt <= 3; attempt++) {
                        ct.ThrowIfCancellationRequested();
                        if (attempt > 1) {
                            progress?.Report(new ProgramProgressInfo {
                                StatusText = phase,
                                DetailText = string.Format("Connection interrupted. Retrying download (attempt {0}/3)...", attempt),
                                ProgressPercentage = 10
                            });
                            try { File.Delete(tempFile); } catch { }
                            try { await Task.Delay(2000, ct); } catch (OperationCanceledException) { throw; }
                        }

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
                            downloaded = true;
                            break;
                        } catch (OperationCanceledException) {
                            try { File.Delete(tempFile); } catch { }
                            throw;
                        } catch (Exception ex) {
                            Logger.Log(string.Format("Direct download attempt {0}/3 failed for {1}: {2}", attempt, item.Name, ex.Message), "Warning");
                            try { File.Delete(tempFile); } catch { }
                        }
                    }

                    if (downloaded && File.Exists(tempFile)) {
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
                            try {
                                while (!proc.HasExited) {
                                    if (ct.IsCancellationRequested) {
                                        break;
                                    }
                                    try {
                                        await Task.Delay(200, ct);
                                    } catch (OperationCanceledException) {
                                        break;
                                    }
                                }
                            } finally {
                                if (ct.IsCancellationRequested && !proc.HasExited) {
                                    try { proc.Kill(); } catch { }
                                }
                            }
                            if (ct.IsCancellationRequested) {
                                try { File.Delete(tempFile); } catch { }
                                return false;
                            }
                        }

                        try { File.Delete(tempFile); } catch { }

                        progress?.Report(new ProgramProgressInfo {
                            StatusText = "Finished: " + item.Name,
                            DetailText = "",
                            ProgressPercentage = 100
                        });
                        return true;
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
                    bool downloadedOffice = false;
                    for (int oAttempt = 1; oAttempt <= 3; oAttempt++) {
                        ct.ThrowIfCancellationRequested();
                        if (oAttempt > 1) {
                            progress?.Report(new BloatProgressInfo {
                                Status = "CDN connection interrupted...",
                                Detail = string.Format("Retrying {0} download (attempt {1}/3)...", displayName, oAttempt),
                                ProgressPercentage = 5
                            });
                            try { if (File.Exists(zipPath)) File.Delete(zipPath); } catch { }
                            for (int w = 0; w < 16; w++) {
                                try { string p = zipPath + ".part" + w; if (File.Exists(p)) File.Delete(p); } catch { }
                            }
                            try { await Task.Delay(2500, ct); } catch (OperationCanceledException) { throw; }
                        }

                        progress?.Report(new BloatProgressInfo {
                            Status = "Starting " + displayName + " download...",
                            Detail = "Connecting to CDN...",
                            ProgressPercentage = 5
                        });

                        try {
                            try {
                                ServicePointManager.DefaultConnectionLimit = 64;
                                ServicePointManager.UseNagleAlgorithm = false;
                                ServicePointManager.Expect100Continue = false;
                                var sp = ServicePointManager.FindServicePoint(new Uri(cdnUrl));
                                sp.ConnectionLimit = 64;
                                sp.UseNagleAlgorithm = false;
                                sp.Expect100Continue = false;
                            } catch { }

                            using (var handler = new HttpClientHandler {
                                AutomaticDecompression = DecompressionMethods.None,
                                MaxConnectionsPerServer = 64
                            })
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
                                                using (var fs = new FileStream(partPath, FileMode.Create, FileAccess.Write, FileShare.None, 1048576, true)) {
                                                    byte[] buf = new byte[262144];
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

                                    using (var outputFs = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None, 2097152, true)) {
                                        byte[] mergeBuf = new byte[2097152];
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

                            if (File.Exists(zipPath) && new FileInfo(zipPath).Length > 1024 * 1024) {
                                downloadedOffice = true;
                                break;
                            }
                        } catch (OperationCanceledException) {
                            try { if (File.Exists(zipPath)) File.Delete(zipPath); } catch { }
                            for (int w = 0; w < 16; w++) {
                                try { string p = zipPath + ".part" + w; if (File.Exists(p)) File.Delete(p); } catch { }
                            }
                            throw;
                        } catch (Exception ex) {
                            Logger.Log(string.Format("Office download attempt {0}/3 failed: {1}", oAttempt, ex.Message), "Warning");
                            try { if (File.Exists(zipPath)) File.Delete(zipPath); } catch { }
                            for (int w = 0; w < 16; w++) {
                                try { string p = zipPath + ".part" + w; if (File.Exists(p)) File.Delete(p); } catch { }
                            }
                        }
                    }

                    if (!downloadedOffice) {
                        throw new InvalidOperationException("Failed to download Office package from CDN after 3 attempts. Please check internet connectivity.");
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
                    using (var fs = File.OpenRead(zipPath))
                    using (var archive = new ZipArchive(fs, ZipArchiveMode.Read)) {
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
                                using (var entryStream = entry.Open())
                                using (var outStream = new FileStream(destinationPath, FileMode.Create, FileAccess.Write, FileShare.None)) {
                                    entryStream.CopyTo(outStream);
                                }
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
                CreateNoWindow = true,
                UseShellExecute = false
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
        private static List<ExternalToolItem> _cachedCatalog = null;
        private static readonly object _lock = new object();
        private const string PrimaryManifestUrl = "https://raw.githubusercontent.com/TylerHats/Hats-Multitool/main/ExternalTools.json";
        private const string FallbackManifestUrl = "https://hatsthings.com/MultitoolFiles/ExternalTools.json";

        public static async Task<List<ExternalToolItem>> FetchRemoteToolsCatalogAsync(IProgress<string> statusProgress = null, bool forceRefresh = false) {
            if (!forceRefresh) {
                lock (_lock) {
                    if (_cachedCatalog != null && _cachedCatalog.Count > 0) {
                        return _cachedCatalog;
                    }
                }
            }

            var netCheck = await NetworkConnectivityHelper.CheckInternetAccessAsync();
            if (!netCheck.Item1) {
                throw new InvalidOperationException(netCheck.Item2);
            }

            string json = null;
            Exception lastException = null;
            const int maxAttempts = 3;

            for (int attempt = 1; attempt <= maxAttempts; attempt++) {
                if (attempt == 1) {
                    statusProgress?.Report("Obtaining online tools manifest...");
                } else {
                    statusProgress?.Report(string.Format("Network error obtaining tools manifest. Retrying (attempt {0}/{1})...", attempt, maxAttempts));
                    await Task.Delay(1200 * (attempt - 1));
                }

                // 1. Try raw GitHub repository
                try {
                    using (var cts = new CancellationTokenSource(5500))
                    using (var client = new HttpClient()) {
                        client.Timeout = TimeSpan.FromSeconds(5.5);
                        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) HatsMultitool");
                        using (var resp = await client.GetAsync(PrimaryManifestUrl, cts.Token)) {
                            resp.EnsureSuccessStatusCode();
                            json = await resp.Content.ReadAsStringAsync();
                        }
                    }
                } catch (Exception ex) {
                    lastException = ex;
                    Logger.Log(string.Format("ExternalTools primary fetch attempt {0}/{1} failed: {2}", attempt, maxAttempts, ex.Message), "Warning");
                }

                // 2. Try web server fallback
                if (string.IsNullOrEmpty(json)) {
                    try {
                        using (var cts = new CancellationTokenSource(4500))
                        using (var client = new HttpClient()) {
                            client.Timeout = TimeSpan.FromSeconds(4.5);
                            client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) HatsMultitool");
                            using (var resp = await client.GetAsync(FallbackManifestUrl, cts.Token)) {
                                resp.EnsureSuccessStatusCode();
                                json = await resp.Content.ReadAsStringAsync();
                            }
                        }
                    } catch (Exception ex) {
                        lastException = ex;
                        Logger.Log(string.Format("ExternalTools fallback fetch attempt {0}/{1} failed: {2}", attempt, maxAttempts, ex.Message), "Warning");
                    }
                }

                if (!string.IsNullOrEmpty(json)) {
                    break;
                }
            }

            if (string.IsNullOrEmpty(json)) {
                string reason = lastException != null
                    ? NetworkConnectivityHelper.FormatNetworkException(lastException, "ExternalTools.json")
                    : "The remote tools manifest returned an empty response.";
                throw new InvalidOperationException("Failed to download the Online Tools manifest after " + maxAttempts + " attempts.\n\n" + reason);
            }

            statusProgress?.Report("Parsing online tools manifest...");
            var tools = ParseCatalogJson(json);
            if (tools != null && tools.Count > 0) {
                lock (_lock) {
                    _cachedCatalog = tools;
                    foreach (var t in tools) {
                        _cache[t.Name] = new ResolvedToolInfo {
                            ToolName = t.Name,
                            DownloadUrl = t.DownloadUrl,
                            ExeInsideArchive = t.ExeInsideArchive,
                            Version = ""
                        };
                    }
                }
                return tools;
            }

            throw new InvalidOperationException("The downloaded Online Tools manifest could not be parsed or contained no valid tool entries.");
        }

        public static List<ExternalToolItem> ParseCatalogJson(string json) {
            var result = new List<ExternalToolItem>();
            if (string.IsNullOrEmpty(json)) return result;

            try {
                var objectMatches = Regex.Matches(json, @"\{([^{}]+)\}");
                foreach (Match om in objectMatches) {
                    string block = om.Groups[1].Value;
                    var mName = Regex.Match(block, @"""name""\s*:\s*""([^""]+)""");
                    if (!mName.Success) continue;

                    string name = mName.Groups[1].Value;
                    var mDesc = Regex.Match(block, @"""description""\s*:\s*""([^""]+)""");
                    var mCat = Regex.Match(block, @"""category""\s*:\s*""([^""]+)""");
                    var mUrl = Regex.Match(block, @"""url""\s*:\s*""([^""]+)""");
                    var mExe = Regex.Match(block, @"""exe""\s*:\s*""([^""]*)""");

                    string desc = mDesc.Success ? mDesc.Groups[1].Value : "";
                    string cat = mCat.Success ? mCat.Groups[1].Value : "Viewers & Utilities";
                    string url = mUrl.Success ? mUrl.Groups[1].Value : "";
                    string exe = mExe.Success ? mExe.Groups[1].Value : "";

                    result.Add(new ExternalToolItem(name, desc, cat, "Download", "", "", url, exe));
                }
            } catch { }

            return result;
        }

        public static async Task<ResolvedToolInfo> ResolveToolAsync(string toolName, string currentUrl, string currentExe) {
            if (string.IsNullOrEmpty(toolName)) {
                return new ResolvedToolInfo { ToolName = toolName, DownloadUrl = currentUrl, ExeInsideArchive = currentExe };
            }

            // 1. Check in-memory cache
            lock (_lock) {
                if (_cache.TryGetValue(toolName, out var cached) && cached != null && !string.IsNullOrEmpty(cached.DownloadUrl)) {
                    return cached;
                }
            }

            // 2. Fetch catalog if not loaded
            try {
                await FetchRemoteToolsCatalogAsync();
            } catch { }

            lock (_lock) {
                if (_cache.TryGetValue(toolName, out var manifestInfo) && manifestInfo != null && !string.IsNullOrEmpty(manifestInfo.DownloadUrl)) {
                    return manifestInfo;
                }
            }

            // 3. Fallback
            var fallback = new ResolvedToolInfo {
                ToolName = toolName,
                DownloadUrl = currentUrl,
                ExeInsideArchive = currentExe
            };
            lock (_lock) { _cache[toolName] = fallback; }
            return fallback;
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
                new ExternalToolItem("DISM Repair", "Launches DISM image health restore in a dedicated console window.", "System Repair", "Command", "dism.exe", "/Online /Cleanup-Image /RestoreHealth"),
                new ExternalToolItem("SFC Repair", "Executes System File Checker (sfc /scannow) in a dedicated console window.", "System Repair", "Command", "sfc.exe", "/scannow"),
                new ExternalToolItem("Check Disk (Read Only)", "Runs Check Disk (chkdsk C:) in read-only mode in a dedicated console window.", "System Repair", "Command", "chkdsk.exe", "C:"),
                new ExternalToolItem(".NET 3.5 (Includes v2 and v3)", "Installs .NET Framework 3.5/2.0/3.0 via DISM in a dedicated console window.", "System Repair", "Command", "dism.exe", "/Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart"),
                new ExternalToolItem("Windows Update Reset", "Stops update services, clears SoftwareDistribution & catroot2 caches, and resets components.", "System Repair", "InternalDialog", "winupdate_reset"),
                new ExternalToolItem("Reset HOSTS File to Default", "Resets Windows HOSTS file back to clean Microsoft default (creates a backup .bak).", "System Repair", "Special", "hosts_reset"),
                new ExternalToolItem("Reset Settings Page Visibility", "Clears SettingsPageVisibility registry policy to unhide blocked Windows Settings pages.", "System Repair", "Special", "settings_visibility")
            };
        }

        public static List<ExternalToolItem> GetDiskTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("Windows Disk Cleanup", "Launches the native Windows Disk Cleanup utility.", "Disk & Storage", "Gui", "cleanmgr.exe", ""),
                new ExternalToolItem("SMART Info & Benchmarking", "Hardware health summary, wearout gauge, temperature, and built-in direct sequential & 4K random speed benchmark.", "Disk & Storage", "InternalDialog", "storage_health"),
                new ExternalToolItem("BitLocker Management", "Inspect status, enable/disable encryption, manage recovery keys, and unlock locked drives.", "Disk & Storage", "InternalDialog", "bitlocker_manager")
            };
        }

        public static List<ExternalToolItem> GetNetworkTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("Internet Speed Test", "Native, real-time speed test against Cloudflare Anycast measuring Ping, Jitter, Download, and Upload.", "Network & Connectivity", "InternalDialog", "speed_test"),
                new ExternalToolItem("Packet Loss & Latency Test", "High-precision async latency & packet loss tester with real-time jitter, loss metrics, and smooth GDI+ graph.", "Network & Connectivity", "InternalDialog", "packet_loss"),
                new ExternalToolItem("TCP Port & Connection Checker", "Tests IP/hostname reachability and open TCP ports with response time.", "Network & Connectivity", "InternalDialog", "tcp_checker"),
                new ExternalToolItem("Flush DNS & Reset IP", "Releases/renews IP, flushes DNS client cache, and clears ARP entries.", "Network & Connectivity", "Special", "flush_dns")
            };
        }

        public static List<ExternalToolItem> GetViewerTools() {
            return new List<ExternalToolItem> {
                new ExternalToolItem("Generate Battery Report", "Generates and opens a detailed HTML report of laptop battery health and cycle history.", "Viewers & Utilities", "Special", "battery_report"),
                new ExternalToolItem("Startup & Autoruns Manager", "Inspect, enable, disable, or remove startup applications and registry autorun entries.", "Viewers & Utilities", "InternalDialog", "startup_manager"),
                new ExternalToolItem("Reliability Monitor", "Opens Windows Reliability Monitor timeline to view crash and software install history.", "Viewers & Utilities", "Gui", "perfmon.exe", "/rel"),
                new ExternalToolItem("Read OEM OS Key", "Reads OEM Windows product key embedded in BIOS/ACPI MSDM table.", "Viewers & Utilities", "InternalDialog", "oem_key"),
                new ExternalToolItem("Enable Safe Boot (w/Network)", "Configures BCD to boot into Safe Mode with networking enabled.", "Viewers & Utilities", "Special", "safeboot_net"),
                new ExternalToolItem("Disable Safe Boot (Normal Boot)", "Removes Safe Boot configuration from BCD and restores normal Windows startup.", "Viewers & Utilities", "Special", "safeboot_disable"),
                new ExternalToolItem("Restart Windows Explorer", "Forcefully kills and restarts explorer.exe to resolve frozen taskbars or stuck folders.", "Viewers & Utilities", "Special", "restart_explorer"),
                new ExternalToolItem("Ninja Removal Script", "Launches the NinjaOne Agent removal script.", "Viewers & Utilities", "Special", "ninja_removal")
            };
        }

        public static string ReadOemProductKey() {
            try {
                using (var searcher = new ManagementObjectSearcher("SELECT OA3xOriginalProductKey FROM SoftwareLicensingService")) {
                    foreach (ManagementObject obj in searcher.Get()) {
                        object val = obj["OA3xOriginalProductKey"];
                        if (val != null) {
                            string key = val.ToString().Trim();
                            if (Regex.IsMatch(key, @"^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$")) {
                                return key;
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                Logger.Log("Failed to query OEM Product Key via WMI: " + ex.Message, "Warning");
            }
            return "No OEM Product Key found in BIOS / ACPI MSDM table.";
        }
    }
}
