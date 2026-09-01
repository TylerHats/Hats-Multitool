using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using HMT.Engines;
using HMT.Forms;

namespace HMT {
    public static class Program {
        [DllImport("user32.dll")]
        private static extern bool SetProcessDPIAware();

        [DllImport("shcore.dll")]
        private static extern int SetProcessDpiAwareness(int awareness);

        [STAThread]
        public static int Main(string[] args) {
            // Enable Visual Styles & Modern DPI Awareness
            try {
                SetProcessDpiAwareness(2); // Per-Monitor High-DPI Aware
            } catch {
                try { SetProcessDPIAware(); } catch { }
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Configure Standard Reliable TLS 1.2 / TLS 1.1 / TLS
            try {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
                ServicePointManager.DefaultConnectionLimit = 64;
                ServicePointManager.Expect100Continue = false;
            } catch { }

            // Ensure Single Instance / Admin Elevation is active
            if (!NativeMethods.IsAdministrator()) {
                try {
                    string exePath = Process.GetCurrentProcess().MainModule.FileName;
                    var psi = new ProcessStartInfo {
                        FileName = exePath,
                        UseShellExecute = true,
                        Verb = "runas"
                    };
                    Process.Start(psi);
                    return 0;
                } catch {
                    return 1;
                }
            }

            string version = "6.1.0";
            try {
                string manifestPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "AppManifest.json");
                if (File.Exists(manifestPath)) {
                    string json = File.ReadAllText(manifestPath);
                    var match = System.Text.RegularExpressions.Regex.Match(json, @"""version""\s*:\s*""([^""]+)""");
                    if (match.Success) {
                        version = match.Groups[1].Value;
                    }
                }
            } catch { }

            // Check for updates asynchronously in background
            Task.Run(async () => {
                try {
                    Version remoteVer = await UpdateEngine.CheckRemoteVersionAsync();
                    Version localVer;
                    if (remoteVer != null && Version.TryParse(version, out localVer)) {
                        if (remoteVer > localVer) {
                            Logger.Log(string.Format("New version available: v{0} (Current: v{1})", remoteVer, localVer), "Info");
                        }
                    }
                } catch { }
            });

            // Main Application Loop
            while (true) {
                try {
                    using (var mainMenu = new MainMenuForm(version)) {
                        var result = mainMenu.ShowDialog();
                        if (result != DialogResult.OK) {
                            break;
                        }

                        if (mainMenu.NextAction == "Setup") {
                            RunSetupWorkflow();
                        } else if (mainMenu.NextAction == "Tools") {
                            using (var toolsMenu = new ToolsForm()) {
                                toolsMenu.ShowDialog();
                            }
                        } else {
                            break;
                        }
                    }
                } catch (Exception ex) {
                    MessageBox.Show("An unexpected error occurred in Hat's Multitool:\n\n" + ex.Message + "\n\n" + ex.StackTrace, "Hat's Multitool Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    break;
                }
            }

            NativeMethods.PerformBackgroundCleanupAndExit();
            return 0;
        }

        private static void RunSetupWorkflow() {
            using (var selector = new SetupSelectorForm()) {
                if (selector.ShowDialog() != DialogResult.OK || selector.SelectedModules.Count == 0) {
                    return;
                }

                var steps = selector.SelectedModules;
                int totalSteps = steps.Count;

                for (int i = 0; i < steps.Count; i++) {
                    string stepName = steps[i];
                    string stepTitle = totalSteps > 1 ? string.Format("{0} ({1}/{2})", stepName, i + 1, totalSteps) : stepName;

                    try {
                        switch (stepName) {
                            case "Time Zone":
                                using (var tz = new TimeZoneForm(stepTitle)) {
                                    tz.ShowDialog();
                                }
                                break;
                            case "Local Accounts":
                                using (var acc = new LocalAccountsForm(stepTitle)) {
                                    acc.ShowDialog();
                                }
                                break;
                            case "System Properties":
                                using (var sp = new SystemPropertiesForm(stepTitle)) {
                                    sp.ShowDialog();
                                }
                                break;
                            case "Setup Options":
                                using (var so = new SetupOptionsForm(stepTitle)) {
                                    so.ShowDialog();
                                }
                                break;
                            case "Bloat Cleanup":
                                using (var bc = new BloatCleanupForm(stepTitle)) {
                                    bc.ShowDialog();
                                }
                                break;
                            case "Programs":
                                using (var prog = new ProgramsForm(stepTitle)) {
                                    prog.ShowDialog();
                                }
                                break;
                        }
                    } catch (Exception ex) {
                        MessageBox.Show(string.Format("Error running module '{0}':\n\n{1}", stepName, ex.Message), "Module Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }
    }
}
