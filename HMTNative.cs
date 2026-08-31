// C# Methods Pre-Comp File - Tyler Hatfield - v2.0

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

// Global namespace class to match existing [DpiHelper] calls
public class DpiHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}

namespace HMT {
    // HMT namespace class to match existing [HMT.NativeMethods] calls
    public static class NativeMethods {
        public static GraphicsPath CreateRoundedRectanglePath(Rectangle rect, int cornerRadius) {
            GraphicsPath path = new GraphicsPath();
            int diameter = cornerRadius * 2;
            if (diameter > rect.Width) diameter = rect.Width;
            if (diameter > rect.Height) diameter = rect.Height;
            if (diameter <= 0) {
                path.AddRectangle(rect);
                return path;
            }
            Size size = new Size(diameter, diameter);
            Rectangle arc = new Rectangle(rect.Location, size);

            path.AddArc(arc, 180, 90);
            arc.X = rect.Right - diameter;
            path.AddArc(arc, 270, 90);
            arc.Y = rect.Bottom - diameter;
            path.AddArc(arc, 0, 90);
            arc.X = rect.Left;
            path.AddArc(arc, 90, 90);
            path.CloseFigure();
            return path;
        }

        public static void SetRoundedCorners(System.Windows.Forms.Control control, int radius) {
            if (control == null || control.Width <= 0 || control.Height <= 0) return;
            using (var path = CreateRoundedRectanglePath(new Rectangle(0, 0, control.Width, control.Height), radius)) {
                control.Region = new Region(path);
            }
        }

        // --- Console & Window Visibility ---
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        // --- Window Messaging (Icons & UI Elements) ---
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern Int32 SendMessage(IntPtr hWnd, int msg, int wParam, string lParam);

        // --- DWM & Theming (Dark Mode) ---
        [DllImport("uxtheme.dll", ExactSpelling=true, CharSet=CharSet.Unicode)]
        public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);

        [DllImport("dwmapi.dll")]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        // --- Taskbar Management ---
        [DllImport("shell32.dll", SetLastError = true)]
        public static extern int SetCurrentProcessExplicitAppUserModelID([MarshalAs(UnmanagedType.LPWStr)] string AppID);
    }

    // --- Low-Level Drive & Storage Interop ---
    public static class DriveInterop {
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr CreateFile(
            string lpFileName,
            uint dwDesiredAccess,
            uint dwShareMode,
            IntPtr lpSecurityAttributes,
            uint dwCreationDisposition,
            uint dwFlagsAndAttributes,
            IntPtr hTemplateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool DeviceIoControl(
            IntPtr hDevice,
            uint dwIoControlCode,
            IntPtr lpInBuffer,
            uint nInBufferSize,
            IntPtr lpOutBuffer,
            uint nOutBufferSize,
            out uint lpBytesReturned,
            IntPtr lpOverlapped);

        public const uint GENERIC_READ = 0x80000000;
        public const uint GENERIC_WRITE = 0x40000000;
        public const uint FILE_SHARE_READ = 0x00000001;
        public const uint FILE_SHARE_WRITE = 0x00000002;
        public const uint OPEN_EXISTING = 3;
        public const uint FILE_ATTRIBUTE_NORMAL = 0x00000080;

        public const uint IOCTL_STORAGE_QUERY_PROPERTY = 0x002D1400;

        public enum STORAGE_PROPERTY_ID {
            StorageDeviceProperty = 0,
            StorageAdapterProperty = 1,
            StorageDeviceIdProperty = 2,
            StorageDeviceUniqueIdProperty = 3,
            StorageDeviceWriteCacheProperty = 4,
            StorageMiniportProperty = 5,
            StorageAccessAlignmentProperty = 6,
            StorageDeviceSeekPenaltyProperty = 7,
            StorageDeviceTrimProperty = 8
        }

        public enum STORAGE_QUERY_TYPE {
            PropertyStandardQuery = 0,
            PropertyExistsQuery = 1,
            PropertyMaskQuery = 2,
            PropertyQueryMaxDefined = 3
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct STORAGE_PROPERTY_QUERY {
            public STORAGE_PROPERTY_ID PropertyId;
            public STORAGE_QUERY_TYPE QueryType;
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 1)]
            public byte[] AdditionalParameters;
        }

        public enum STORAGE_BUS_TYPE {
            BusTypeUnknown = 0x00,
            BusTypeScsi = 0x01,
            BusTypeAtapi = 0x02,
            BusTypeAta = 0x03,
            BusType1394 = 0x04,
            BusTypeSsa = 0x05,
            BusTypeFibre = 0x06,
            BusTypeUsb = 0x07,
            BusTypeRAID = 0x08,
            BusTypeiScsi = 0x09,
            BusTypeSas = 0x0A,
            BusTypeSata = 0x0B,
            BusTypeSd = 0x0C,
            BusTypeMmc = 0x0D,
            BusTypeVirtual = 0x0E,
            BusTypeFileBackedVirtual = 0x0F,
            BusTypeSpaces = 0x10,
            BusTypeNvme = 0x11,
            BusTypeSCM = 0x12,
            BusTypeUfs = 0x13,
            BusTypeMax = 0x14,
            BusTypeMaxReserved = 0x7F
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
            public bool Success { get; set; }
            public string ErrorMessage { get; set; }
        }

        public static DriveInfoResult QueryPhysicalDriveInfo(int driveIndex) {
            var result = new DriveInfoResult {
                DriveIndex = driveIndex,
                DevicePath = string.Format(@"\\.\PhysicalDrive{0}", driveIndex),
                VendorId = string.Empty,
                ProductId = string.Empty,
                ProductRevision = string.Empty,
                SerialNumber = string.Empty,
                BusType = STORAGE_BUS_TYPE.BusTypeUnknown,
                BusTypeName = "Unknown",
                IsSSD = false,
                Success = false
            };

            IntPtr hDrive = CreateFile(
                result.DevicePath,
                0,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                IntPtr.Zero,
                OPEN_EXISTING,
                0,
                IntPtr.Zero
            );

            if (hDrive == IntPtr.Zero || hDrive == (IntPtr)(-1)) {
                result.ErrorMessage = "Unable to open device handle (error: " + Marshal.GetLastWin32Error() + ")";
                return result;
            }

            try {
                STORAGE_PROPERTY_QUERY query = new STORAGE_PROPERTY_QUERY {
                    PropertyId = STORAGE_PROPERTY_ID.StorageDeviceProperty,
                    QueryType = STORAGE_QUERY_TYPE.PropertyStandardQuery,
                    AdditionalParameters = new byte[1]
                };

                uint querySize = (uint)Marshal.SizeOf(query);
                IntPtr pQuery = Marshal.AllocHGlobal((int)querySize);
                Marshal.StructureToPtr(query, pQuery, false);

                uint outBufferSize = 2048;
                IntPtr pOutBuffer = Marshal.AllocHGlobal((int)outBufferSize);

                uint bytesReturned = 0;
                bool success = DeviceIoControl(
                    hDrive,
                    IOCTL_STORAGE_QUERY_PROPERTY,
                    pQuery,
                    querySize,
                    pOutBuffer,
                    outBufferSize,
                    out bytesReturned,
                    IntPtr.Zero
                );

                if (success && bytesReturned > 0) {
                    byte[] buffer = new byte[bytesReturned];
                    Marshal.Copy(pOutBuffer, buffer, 0, (int)bytesReturned);

                    int busTypeVal = (int)buffer[28];
                    result.BusType = (STORAGE_BUS_TYPE)busTypeVal;
                    result.BusTypeName = result.BusType.ToString().Replace("BusType", "");
                    result.IsRemovable = (buffer[4] != 0);

                    int vendorOffset = BitConverter.ToInt32(buffer, 8);
                    int productOffset = BitConverter.ToInt32(buffer, 12);
                    int revisionOffset = BitConverter.ToInt32(buffer, 16);
                    int serialOffset = BitConverter.ToInt32(buffer, 20);

                    if (vendorOffset > 0 && vendorOffset < buffer.Length)
                        result.VendorId = ReadNullTerminatedAscii(buffer, vendorOffset).Trim();
                    if (productOffset > 0 && productOffset < buffer.Length)
                        result.ProductId = ReadNullTerminatedAscii(buffer, productOffset).Trim();
                    if (revisionOffset > 0 && revisionOffset < buffer.Length)
                        result.ProductRevision = ReadNullTerminatedAscii(buffer, revisionOffset).Trim();
                    if (serialOffset > 0 && serialOffset < buffer.Length)
                        result.SerialNumber = ReadNullTerminatedAscii(buffer, serialOffset).Trim();

                    result.Success = true;
                }

                Marshal.FreeHGlobal(pQuery);
                Marshal.FreeHGlobal(pOutBuffer);

                STORAGE_PROPERTY_QUERY seekQuery = new STORAGE_PROPERTY_QUERY {
                    PropertyId = STORAGE_PROPERTY_ID.StorageDeviceSeekPenaltyProperty,
                    QueryType = STORAGE_QUERY_TYPE.PropertyStandardQuery,
                    AdditionalParameters = new byte[1]
                };

                uint seekQuerySize = (uint)Marshal.SizeOf(seekQuery);
                IntPtr pSeekQuery = Marshal.AllocHGlobal((int)seekQuerySize);
                Marshal.StructureToPtr(seekQuery, pSeekQuery, false);

                uint seekOutSize = 16;
                IntPtr pSeekOut = Marshal.AllocHGlobal((int)seekOutSize);

                uint seekBytesReturned = 0;
                bool seekSuccess = DeviceIoControl(
                    hDrive,
                    IOCTL_STORAGE_QUERY_PROPERTY,
                    pSeekQuery,
                    seekQuerySize,
                    pSeekOut,
                    seekOutSize,
                    out seekBytesReturned,
                    IntPtr.Zero
                );

                if (seekSuccess && seekBytesReturned >= 5) {
                    byte[] seekBuf = new byte[seekBytesReturned];
                    Marshal.Copy(pSeekOut, seekBuf, 0, (int)seekBytesReturned);
                    bool incursSeekPenalty = (seekBuf[4] != 0);
                    result.IsSSD = !incursSeekPenalty;
                } else if (result.BusType == STORAGE_BUS_TYPE.BusTypeNvme) {
                    result.IsSSD = true;
                }

                Marshal.FreeHGlobal(pSeekQuery);
                Marshal.FreeHGlobal(pSeekOut);

            } catch (Exception ex) {
                result.ErrorMessage = ex.Message;
            } finally {
                CloseHandle(hDrive);
            }

            return result;
        }

        private static string ReadNullTerminatedAscii(byte[] data, int startIndex) {
            int end = startIndex;
            while (end < data.Length && data[end] != 0) {
                end++;
            }
            if (end <= startIndex) return string.Empty;
            return System.Text.Encoding.ASCII.GetString(data, startIndex, end - startIndex);
        }
    }

    // --- Per-Pixel Alpha WinForms Helper ---
    public class PerPixelAlphaForm : System.Windows.Forms.Form {
        [DllImport("user32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern bool UpdateLayeredWindow(IntPtr hwnd, IntPtr hdcDst, ref Point pptDst, ref Size psize, IntPtr hdcSrc, ref Point pprSrc, int crKey, ref BLENDFUNCTION pblend, int dwFlags);
        
        [DllImport("user32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern IntPtr GetDC(IntPtr hWnd);
        [DllImport("user32.dll", ExactSpelling = true)]
        public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
        [DllImport("gdi32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
        [DllImport("gdi32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern bool DeleteDC(IntPtr hdc);
        [DllImport("gdi32.dll", ExactSpelling = true)]
        public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
        [DllImport("gdi32.dll", ExactSpelling = true, SetLastError = true)]
        public static extern bool DeleteObject(IntPtr hObject);

        public struct Point { public int x, y; public Point(int x, int y) { this.x = x; this.y = y; } }
        public new struct Size { public int cx, cy; public Size(int cx, int cy) { this.cx = cx; this.cy = cy; } }
        public struct BLENDFUNCTION {
            public byte BlendOp;
            public byte BlendFlags;
            public byte SourceConstantAlpha;
            public byte AlphaFormat;
        }

        public const int WS_EX_LAYERED = 0x80000;
        public const int ULW_ALPHA = 2;
        public const byte AC_SRC_OVER = 0;
        public const byte AC_SRC_ALPHA = 1;

        protected override System.Windows.Forms.CreateParams CreateParams {
            get {
                System.Windows.Forms.CreateParams cp = base.CreateParams;
                cp.ExStyle |= WS_EX_LAYERED;
                return cp;
            }
        }

        public void SetImage(System.Drawing.Bitmap bitmap) {
            if (bitmap.PixelFormat != System.Drawing.Imaging.PixelFormat.Format32bppArgb) {
                throw new ApplicationException("The bitmap must be 32bpp with alpha-channel.");
            }
            IntPtr screenDc = GetDC(IntPtr.Zero);
            IntPtr memDc = CreateCompatibleDC(screenDc);
            IntPtr hBitmap = IntPtr.Zero;
            IntPtr oldBitmap = IntPtr.Zero;

            try {
                hBitmap = bitmap.GetHbitmap(System.Drawing.Color.FromArgb(0));
                oldBitmap = SelectObject(memDc, hBitmap);

                Size size = new Size(bitmap.Width, bitmap.Height);
                Point pointSource = new Point(0, 0);
                Point topPos = new Point(Left, Top);
                BLENDFUNCTION blend = new BLENDFUNCTION();
                blend.BlendOp = AC_SRC_OVER;
                blend.BlendFlags = 0;
                blend.SourceConstantAlpha = 255;
                blend.AlphaFormat = AC_SRC_ALPHA;

                UpdateLayeredWindow(Handle, screenDc, ref topPos, ref size, memDc, ref pointSource, 0, ref blend, ULW_ALPHA);
            } finally {
                ReleaseDC(IntPtr.Zero, screenDc);
                if (hBitmap != IntPtr.Zero) {
                    SelectObject(memDc, oldBitmap);
                    DeleteObject(hBitmap);
                }
                DeleteDC(memDc);
            }
        }
    }
}