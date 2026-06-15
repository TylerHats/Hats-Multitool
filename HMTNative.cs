// C# Methods Pre-Comp File - Tyler Hatfield - v1.1

using System;
using System.Runtime.InteropServices;

// Global namespace class to match existing [DpiHelper] calls
public class DpiHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}

namespace HMT {
    // HMT namespace class to match existing [HMT.NativeMethods] calls
    public static class NativeMethods {

        // --- Console & Window Visibility ---
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        // --- Window Messaging (Icons & UI Elements) ---
        
        // Signature 1: For passing icon handles (lParam as IntPtr)
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        // Signature 2: For passing strings (lParam as string - used for Cue Banners/Placeholders)
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
}