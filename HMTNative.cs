using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using Microsoft.Win32;

namespace HMT {
    public static class NativeMethods {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("dwmapi.dll")]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        public static void CleanupAndExit(string appDir = null, string irmTarget = null, bool cleanupExe = false) {
            PerformBackgroundCleanupAndExit(appDir, irmTarget, cleanupExe);
        }

        public static void PerformBackgroundCleanupAndExit(string appDir = null, string irmTarget = null, bool cleanupExe = false) {
            try {
                foreach (System.Windows.Forms.Form form in System.Windows.Forms.Application.OpenForms) {
                    try { form.Hide(); } catch { }
                }
                System.Windows.Forms.Application.DoEvents();
            } catch { }

            if (cleanupExe || !string.IsNullOrEmpty(irmTarget)) {
                try {
                    string hmtLocalDir = string.IsNullOrEmpty(appDir)
                        ? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "HMT")
                        : appDir;
                    string exePath = !string.IsNullOrEmpty(irmTarget)
                        ? irmTarget
                        : Process.GetCurrentProcess().MainModule.FileName;

                    if (Directory.Exists(hmtLocalDir)) {
                        try {
                            string extPrograms = Path.Combine(hmtLocalDir, "ExtPrograms");
                            if (Directory.Exists(extPrograms)) {
                                Directory.Delete(extPrograms, true);
                            }
                        } catch { }
                    }

                    int currentPid = Process.GetCurrentProcess().Id;
                    string escapedExe = (exePath ?? "").Replace("'", "''");
                    string psCleanup = string.Format(
                        "Wait-Process -Id {0} -Timeout 5 -ErrorAction SilentlyContinue; Remove-Item -LiteralPath '{1}' -Force -ErrorAction SilentlyContinue",
                        currentPid, escapedExe);

                    var psi = new ProcessStartInfo {
                        FileName = "powershell.exe",
                        Arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -Command \"" + psCleanup + "\"",
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    Process.Start(psi);
                } catch { }
            }

            try {
                System.Windows.Forms.Application.Exit();
            } catch { }
        }
    }

    public static class DriveInterop {
        public enum STORAGE_BUS_TYPE {
            BusTypeUnknown = 0x00,
            BusTypeScsi = 0x01,
            BusTypeAta = 0x03,
            BusTypeUsb = 0x07,
            BusTypeRAID = 0x08,
            BusTypeSata = 0x0B,
            BusTypeVirtual = 0x0E,
            BusTypeNvme = 0x11
        }

        public class DriveInfoResult {
            public int DriveIndex { get; set; }
            public string DevicePath { get; set; }
            public string VendorId { get; set; }
            public string ProductId { get; set; }
            public string ProductRevision { get; set; }
            public string SerialNumber { get; set; }
            public STORAGE_BUS_TYPE BusType { get; set; }
            public string BusTypeName { get; set; }
            public bool IsRemovable { get; set; }
            public bool IsSSD { get; set; }
            public string CapacityText { get; set; }
            public bool Success { get; set; }
            public string ErrorMessage { get; set; }
        }

        public static DriveInfoResult QueryPhysicalDriveInfo(int driveIndex) {
            var result = new DriveInfoResult {
                DriveIndex = driveIndex,
                DevicePath = "Disk " + driveIndex,
                VendorId = string.Empty,
                ProductId = string.Empty,
                ProductRevision = string.Empty,
                SerialNumber = string.Empty,
                BusType = STORAGE_BUS_TYPE.BusTypeUnknown,
                BusTypeName = "NVMe/SATA",
                IsSSD = true,
                CapacityText = "~512 GB",
                Success = false
            };

            try {
                using (var enumKey = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\disk\Enum", false)) {
                    if (enumKey != null) {
                        string pnpId = enumKey.GetValue(driveIndex.ToString()) as string;
                        if (!string.IsNullOrEmpty(pnpId)) {
                            var mVen = Regex.Match(pnpId, @"Ven_([^&\\]+)", RegexOptions.IgnoreCase);
                            var mProd = Regex.Match(pnpId, @"Prod_([^&\\]+)", RegexOptions.IgnoreCase);
                            if (mVen.Success) result.VendorId = mVen.Groups[1].Value.Replace('_', ' ').Trim();
                            if (mProd.Success) result.ProductId = mProd.Groups[1].Value.Replace('_', ' ').Trim();

                            if (pnpId.IndexOf("NVME", StringComparison.OrdinalIgnoreCase) >= 0 ||
                                result.ProductId.IndexOf("NVMe", StringComparison.OrdinalIgnoreCase) >= 0) {
                                result.BusType = STORAGE_BUS_TYPE.BusTypeNvme;
                                result.BusTypeName = "NVMe";
                                result.IsSSD = true;
                            } else if (pnpId.IndexOf("USBSTOR", StringComparison.OrdinalIgnoreCase) >= 0) {
                                result.BusType = STORAGE_BUS_TYPE.BusTypeUsb;
                                result.BusTypeName = "USB";
                                result.IsRemovable = true;
                            } else {
                                result.BusType = STORAGE_BUS_TYPE.BusTypeSata;
                                result.BusTypeName = "SATA/AHCI";
                                result.IsSSD = result.ProductId.IndexOf("HDD", StringComparison.OrdinalIgnoreCase) < 0;
                            }

                            if (string.IsNullOrEmpty(result.ProductId)) {
                                result.ProductId = "System Storage Drive";
                            }
                            result.Success = true;
                        }
                    }
                }

                var fixedDrives = new System.Collections.Generic.List<DriveInfo>();
                foreach (var d in DriveInfo.GetDrives()) {
                    try {
                        if (d.IsReady && (d.DriveType == DriveType.Fixed || d.DriveType == DriveType.Removable)) {
                            fixedDrives.Add(d);
                        }
                    } catch { }
                }

                if (driveIndex < fixedDrives.Count) {
                    double gb = fixedDrives[driveIndex].TotalSize / 1073741824.0;
                    result.CapacityText = gb >= 1000 ? string.Format("{0:F1} TB", gb / 1024.0) : string.Format("{0:F0} GB", gb);
                    if (!result.Success) {
                        string label = string.IsNullOrEmpty(fixedDrives[driveIndex].VolumeLabel) ? "Local Disk" : fixedDrives[driveIndex].VolumeLabel;
                        result.ProductId = string.Format("{0} ({1})", label, fixedDrives[driveIndex].Name.TrimEnd('\\'));
                        result.Success = true;
                    }
                }
            } catch (Exception ex) {
                result.ErrorMessage = ex.Message;
            }

            return result;
        }
    }
}
