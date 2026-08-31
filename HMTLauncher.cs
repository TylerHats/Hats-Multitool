using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;

namespace HMT {
    public static class Launcher {
        [STAThread]
        public static int Main(string[] args) {
            string extractDir = null;
            try {
                int pid = Process.GetCurrentProcess().Id;
                extractDir = Path.Combine(Path.GetTempPath(), "HMT_" + pid.ToString());
                if (Directory.Exists(extractDir)) {
                    try { Directory.Delete(extractDir, true); } catch { }
                }
                Directory.CreateDirectory(extractDir);

                Assembly currentAssembly = Assembly.GetExecutingAssembly();
                using (Stream stream = currentAssembly.GetManifestResourceStream("payload.zip")) {
                    if (stream == null) {
                        return 1;
                    }
                    using (ZipArchive archive = new ZipArchive(stream, ZipArchiveMode.Read)) {
                        archive.ExtractToDirectory(extractDir);
                    }
                }

                string coreScript = Path.Combine(extractDir, "Core.ps1");
                if (!File.Exists(coreScript)) {
                    return 2;
                }

                string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                string sysNative = Path.Combine(winDir, "SysNative", "WindowsPowerShell", "v1.0", "powershell.exe");
                string system32 = Path.Combine(winDir, "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
                string psExe = File.Exists(sysNative) ? sysNative : (File.Exists(system32) ? system32 : "powershell.exe");

                string forwardArgs = "";
                if (args != null && args.Length > 0) {
                    for (int i = 0; i < args.Length; i++) {
                        string arg = args[i];
                        if (arg.Contains(" ") || arg.Contains("\t")) {
                            forwardArgs += " \"" + arg.Replace("\"", "\\\"") + "\"";
                        } else {
                            forwardArgs += " " + arg;
                        }
                    }
                }

                var psi = new ProcessStartInfo {
                    FileName = psExe,
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + coreScript + "\"" + forwardArgs,
                    WorkingDirectory = extractDir,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden
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
            } finally {
                if (extractDir != null && Directory.Exists(extractDir)) {
                    try {
                        Directory.Delete(extractDir, true);
                    } catch { }
                }
            }
        }
    }
}
