using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Reflection;
using System.Windows.Forms;
using HMT.Forms;

namespace HMT {
    public static class Program {
        [STAThread]
        public static int Main(string[] args) {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Configure Standard Reliable TLS 1.2 / TLS 1.3 / High Performance Networking
            try {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | (SecurityProtocolType)12288;
                ServicePointManager.DefaultConnectionLimit = 128;
                ServicePointManager.Expect100Continue = false;
                ServicePointManager.UseNagleAlgorithm = false;
            } catch { }

            // Check for cleanup-on-exit flag
            bool cleanupOnExit = false;
            if (args != null && args.Length > 0) {
                foreach (var arg in args) {
                    if (string.Equals(arg, "--cleanup-on-exit", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(arg, "--temp-run", StringComparison.OrdinalIgnoreCase)) {
                        cleanupOnExit = true;
                        break;
                    }
                }
            }

            string version = "6.3.6";
            try {
                var asm = Assembly.GetExecutingAssembly();
                var ver = asm.GetName().Version;
                if (ver != null && ver.Major > 0) {
                    version = string.Format("{0}.{1}.{2}", ver.Major, ver.Minor, ver.Build);
                }

                using (var stream = asm.GetManifestResourceStream("AppManifest.json")) {
                    if (stream != null) {
                        using (var reader = new StreamReader(stream)) {
                            string json = reader.ReadToEnd();
                            var match = System.Text.RegularExpressions.Regex.Match(json, @"""version""\s*:\s*""([^""]+)""");
                            if (match.Success) {
                                version = match.Groups[1].Value;
                            }
                        }
                    }
                }

                string manifestPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "AppManifest.json");
                if (File.Exists(manifestPath)) {
                    string json = File.ReadAllText(manifestPath);
                    var match = System.Text.RegularExpressions.Regex.Match(json, @"""version""\s*:\s*""([^""]+)""");
                    if (match.Success) {
                        version = match.Groups[1].Value;
                    }
                }
            } catch { }

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

            NativeMethods.PerformBackgroundCleanupAndExit(cleanupExe: cleanupOnExit);
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
