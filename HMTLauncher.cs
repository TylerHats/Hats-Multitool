using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Threading;

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

            try {
                return Assembly.Load("System.Management.Automation");
            } catch { }

            try {
                #pragma warning disable 0618
                return Assembly.LoadWithPartialName("System.Management.Automation");
                #pragma warning restore 0618
            } catch { }

            string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
            string[] searchPaths = new string[] {
                Path.Combine(winDir, "Microsoft.NET", "assembly", "GAC_MSIL", "System.Management.Automation", "v4.0_3.0.0.0__31bf3856ad364e35", "System.Management.Automation.dll"),
                Path.Combine(winDir, "assembly", "GAC_MSIL", "System.Management.Automation", "1.0.0.0__31bf3856ad364e35", "System.Management.Automation.dll"),
                Path.Combine(winDir, "System32", "WindowsPowerShell", "v1.0", "System.Management.Automation.dll"),
                Path.Combine(winDir, "SysNative", "WindowsPowerShell", "v1.0", "System.Management.Automation.dll"),
                Path.Combine(winDir, "SysWOW64", "WindowsPowerShell", "v1.0", "System.Management.Automation.dll")
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

                // 1. Create InitialSessionState with Bypass ExecutionPolicy and STA Threading
                Type issType = sma.GetType("System.Management.Automation.Runspaces.InitialSessionState");
                object iss = null;
                if (issType != null) {
                    MethodInfo createDefault = issType.GetMethod("CreateDefault", Type.EmptyTypes);
                    if (createDefault != null) {
                        iss = createDefault.Invoke(null, null);
                    }
                }

                if (iss != null) {
                    // Set ExecutionPolicy = Bypass
                    try {
                        Type epType = sma.GetType("Microsoft.PowerShell.ExecutionPolicy");
                        if (epType != null) {
                            PropertyInfo epProp = issType.GetProperty("ExecutionPolicy");
                            if (epProp != null) {
                                object bypassVal = Enum.Parse(epType, "Bypass");
                                epProp.SetValue(iss, bypassVal, null);
                            }
                        }
                    } catch { }

                    // Set ApartmentState = STA
                    try {
                        PropertyInfo aptProp = issType.GetProperty("ApartmentState");
                        if (aptProp != null) {
                            aptProp.SetValue(iss, ApartmentState.STA, null);
                        }
                    } catch { }

                    // Set ThreadOptions = UseCurrentThread
                    try {
                        Type toType = sma.GetType("System.Management.Automation.Runspaces.PSThreadOptions");
                        if (toType != null) {
                            PropertyInfo toProp = issType.GetProperty("ThreadOptions");
                            if (toProp != null) {
                                object useCurrentThreadVal = Enum.Parse(toType, "UseCurrentThread");
                                toProp.SetValue(iss, useCurrentThreadVal, null);
                            }
                        }
                    } catch { }

                    // Set LanguageMode = FullLanguage
                    try {
                        Type lmType = sma.GetType("System.Management.Automation.PSLanguageMode");
                        if (lmType != null) {
                            PropertyInfo lmProp = issType.GetProperty("LanguageMode");
                            if (lmProp != null) {
                                object fullLangVal = Enum.Parse(lmType, "FullLanguage");
                                lmProp.SetValue(iss, fullLangVal, null);
                            }
                        }
                    } catch { }
                }

                // 2. Create Runspace with InitialSessionState
                Type rfType = sma.GetType("System.Management.Automation.Runspaces.RunspaceFactory");
                object runspace = null;
                if (rfType != null) {
                    if (iss != null) {
                        MethodInfo createRunspaceMethod = rfType.GetMethod("CreateRunspace", new Type[] { issType });
                        if (createRunspaceMethod != null) {
                            runspace = createRunspaceMethod.Invoke(null, new object[] { iss });
                        }
                    }
                    if (runspace == null) {
                        MethodInfo createRunspaceMethod = rfType.GetMethod("CreateRunspace", Type.EmptyTypes);
                        if (createRunspaceMethod != null) {
                            runspace = createRunspaceMethod.Invoke(null, null);
                        }
                    }
                }

                if (runspace == null) return false;

                MethodInfo openMethod = runspace.GetType().GetMethod("Open", Type.EmptyTypes);
                if (openMethod != null) {
                    openMethod.Invoke(runspace, null);
                }

                // 3. Create PowerShell instance
                Type psType = sma.GetType("System.Management.Automation.PowerShell");
                if (psType == null) return false;

                MethodInfo createMethod = psType.GetMethod("Create", Type.EmptyTypes);
                if (createMethod == null) return false;

                object ps = createMethod.Invoke(null, null);
                if (ps == null) return false;

                PropertyInfo runspaceProp = psType.GetProperty("Runspace");
                if (runspaceProp != null) {
                    runspaceProp.SetValue(ps, runspace, null);
                }

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

                try {
                    invokeMethod.Invoke(ps, null);
                } catch (TargetInvocationException tie) {
                    if (tie.InnerException != null && tie.InnerException.GetType().Name == "ScriptHalted") {
                        return true;
                    }
                    if (isDebug) {
                        Console.WriteLine("PowerShell runtime notice: " + tie.InnerException);
                    }
                }
                return true;
            } catch (Exception ex) {
                if (isDebug) {
                    Console.WriteLine("In-process SMA error: " + ex);
                }
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

                // Execute 100% in-process inside Hats-Multitool.exe
                RunPowerShellInProcess(appDir, coreScript, forwardArgs, isDebug, currentAssembly.Location);
                return 0;
            } catch (Exception) {
                return 3;
            }
        }
    }
}
