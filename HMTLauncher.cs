using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace HMT {
    public static class Launcher {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AllocConsole();

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetConsoleTitle(string lpConsoleTitle);

        private static bool IsAdministrator() {
            try {
                using (WindowsIdentity identity = WindowsIdentity.GetCurrent()) {
                    WindowsPrincipal principal = new WindowsPrincipal(identity);
                    return principal.IsInRole(WindowsBuiltInRole.Administrator);
                }
            } catch {
                return false;
            }
        }

        private static string FormatArguments(string[] args) {
            if (args == null || args.Length == 0) return "";
            string forwardArgs = "";
            for (int i = 0; i < args.Length; i++) {
                string arg = args[i];
                if (arg.Contains(" ") || arg.Contains("\t")) {
                    forwardArgs += " \"" + arg.Replace("\"", "\\\"") + "\"";
                } else {
                    forwardArgs += " " + arg;
                }
            }
            return forwardArgs;
        }

        private static Assembly LoadPowerShellAssembly() {
            try {
                return Assembly.Load("System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35");
            } catch { }

            string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            string[] searchPaths = new string[] {
                Path.Combine(winDir, "Microsoft.NET", "assembly", "GAC_MSIL", "System.Management.Automation", "v4.0_3.0.0.0__31bf3856ad364e35", "System.Management.Automation.dll"),
                Path.Combine(winDir, "System32", "WindowsPowerShell", "v1.0", "System.Management.Automation.dll"),
                Path.Combine(winDir, "SysNative", "WindowsPowerShell", "v1.0", "System.Management.Automation.dll")
            };

            foreach (string path in searchPaths) {
                if (File.Exists(path)) {
                    try {
                        return Assembly.LoadFrom(path);
                    } catch { }
                }
            }
            return null;
        }

        private static bool RunPowerShellInProcess(string appDir, string coreScript, string forwardArgs, bool isDebug, string launcherPath) {
            Assembly sma = LoadPowerShellAssembly();
            if (sma == null) return false;

            try {
                if (isDebug) {
                    try {
                        AllocConsole();
                        SetConsoleTitle("Hat's Multitool (Debug Console)");
                    } catch { }
                }

                Type psType = sma.GetType("System.Management.Automation.PowerShell");
                if (psType == null) return false;

                MethodInfo createMethod = psType.GetMethod("Create", Type.EmptyTypes);
                if (createMethod == null) return false;

                object ps = createMethod.Invoke(null, null);
                if (ps == null) return false;

                MethodInfo addScript = psType.GetMethod("AddScript", new Type[] { typeof(string) });
                if (addScript == null) return false;

                string escapedLauncher = launcherPath.Replace("'", "''");
                string escapedAppDir = appDir.Replace("'", "''");
                string escapedCore = coreScript.Replace("'", "''");

                string bootstrap = string.Format(
                    "$env:HMT_LAUNCHER_EXE = '{0}'; $global:HMT_LAUNCHER_EXE = '{0}'; $global:HMTAppDir = '{1}'; Set-Location -LiteralPath '{1}'; & '{2}' {3}",
                    escapedLauncher,
                    escapedAppDir,
                    escapedCore,
                    forwardArgs
                );

                addScript.Invoke(ps, new object[] { bootstrap });

                MethodInfo invokeMethod = psType.GetMethod("Invoke", Type.EmptyTypes);
                if (invokeMethod == null) return false;

                invokeMethod.Invoke(ps, null);
                return true;
            } catch (Exception ex) {
                Console.WriteLine("In-process runspace exception: " + ex);
                return false;
            }
        }

        [STAThread]
        public static int Main(string[] args) {
            bool isDebug = false;
            if (args != null) {
                foreach (var arg in args) {
                    if (string.Equals(arg, "-debug", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(arg, "/debug", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(arg, "--debug", StringComparison.OrdinalIgnoreCase)) {
                        isDebug = true;
                        break;
                    }
                }
            }

            // Ensure process is running with administrative privileges
            if (!IsAdministrator()) {
                try {
                    string exePath = Process.GetCurrentProcess().MainModule.FileName;
                    var psiAdmin = new ProcessStartInfo {
                        FileName = exePath,
                        Arguments = FormatArguments(args).Trim(),
                        UseShellExecute = true,
                        Verb = "runas"
                    };
                    Process.Start(psiAdmin);
                    return 0;
                } catch {
                    // User dismissed or rejected UAC prompt
                    return 1;
                }
            }

            try {
                string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
                string appDir = Path.Combine(localAppData, "Programs", "Hats-Multitool", "app");
                if (Directory.Exists(appDir)) {
                    try { Directory.Delete(appDir, true); } catch { }
                }
                Directory.CreateDirectory(appDir);

                Assembly currentAssembly = Assembly.GetExecutingAssembly();
                using (Stream stream = currentAssembly.GetManifestResourceStream("payload.zip")) {
                    if (stream == null) {
                        return 1;
                    }
                    using (ZipArchive archive = new ZipArchive(stream, ZipArchiveMode.Read)) {
                        archive.ExtractToDirectory(appDir);
                    }
                }

                string coreScript = Path.Combine(appDir, "Core.ps1");
                if (!File.Exists(coreScript)) {
                    return 2;
                }

                string forwardArgs = FormatArguments(args);

                // Attempt in-process PowerShell execution first
                if (RunPowerShellInProcess(appDir, coreScript, forwardArgs, isDebug, currentAssembly.Location)) {
                    return 0;
                }

                // Fallback to out-of-process if SMA is unavailable
                string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                string sysNative = Path.Combine(winDir, "SysNative", "WindowsPowerShell", "v1.0", "powershell.exe");
                string system32 = Path.Combine(winDir, "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
                string psExe = File.Exists(sysNative) ? sysNative : (File.Exists(system32) ? system32 : "powershell.exe");

                var psi = new ProcessStartInfo {
                    FileName = psExe,
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + coreScript + "\"" + forwardArgs,
                    WorkingDirectory = appDir,
                    UseShellExecute = false,
                    CreateNoWindow = !isDebug,
                    WindowStyle = isDebug ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden
                };

                try {
                    psi.EnvironmentVariables["HMT_LAUNCHER_EXE"] = currentAssembly.Location;
                } catch { }

                using (Process proc = Process.Start(psi)) {
                    proc.WaitForExit();
                    return proc.ExitCode;
                }
            } catch (Exception) {
                return 3;
            }
        }
    }
}
