using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using HMT.Engines;
using HMT.Tools;

namespace HMT.Forms {
    // --- Dark Theme Palette ---
    public static class DarkTheme {
        public static readonly Color Background = ColorTranslator.FromHtml("#2f3136");
        public static readonly Color HeaderBackground = ColorTranslator.FromHtml("#202225");
        public static readonly Color Surface = ColorTranslator.FromHtml("#3a3c43");
        public static readonly Color TextMain = ColorTranslator.FromHtml("#d9d9d9");
        public static readonly Color TextMuted = ColorTranslator.FromHtml("#a0a0a0");
        public static readonly Color AccentSuccess = ColorTranslator.FromHtml("#57F287");
        public static readonly Color AccentPrimary = ColorTranslator.FromHtml("#5865F2");
        public static readonly Color AccentPurple = ColorTranslator.FromHtml("#6f1fde");
        public static readonly Color AccentWarning = ColorTranslator.FromHtml("#faa61a");
        public static readonly Color AccentDanger = ColorTranslator.FromHtml("#ed4245");

        public static Font GetDefaultFont(float size = 9f, FontStyle style = FontStyle.Regular) {
            try {
                return new Font("Segoe UI", size, style);
            } catch {
                return new Font(FontFamily.GenericSansSerif, size, style);
            }
        }

        public static void ApplyDarkTitleBar(Form form) {
            try {
                int darkMode = 1;
                NativeMethods.DwmSetWindowAttribute(form.Handle, 20, ref darkMode, sizeof(int));
                NativeMethods.DwmSetWindowAttribute(form.Handle, 19, ref darkMode, sizeof(int));
            } catch { }
        }

        public static void StyleButton(Button btn, Color? foreColor = null) {
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 1;
            btn.FlatAppearance.BorderColor = ColorTranslator.FromHtml("#4f545c");
            btn.ForeColor = foreColor ?? TextMain;
            btn.BackColor = Surface;
            btn.Cursor = Cursors.Hand;
            btn.Font = GetDefaultFont(9.5f, FontStyle.Regular);
        }

        public static Icon AppIcon {
            get {
                try {
                    return Icon.ExtractAssociatedIcon(Process.GetCurrentProcess().MainModule.FileName);
                } catch {
                    return null;
                }
            }
        }
    }

    // --- Splash Screen Form ---
    public class SplashScreenForm : Form {
        private PictureBox picBox;

        public SplashScreenForm() {
            this.FormBorderStyle = FormBorderStyle.None;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.ShowInTaskbar = false;
            this.TopMost = true;
            this.BackColor = DarkTheme.HeaderBackground;
            this.ClientSize = new Size(420, 220);

            picBox = new PictureBox {
                Dock = DockStyle.Fill,
                SizeMode = PictureBoxSizeMode.CenterImage,
                BackColor = DarkTheme.HeaderBackground
            };

            try {
                string localApp = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "Hats-Multitool");
                string splashFile = Path.Combine(localApp, "Splash.png");
                if (File.Exists(splashFile)) {
                    picBox.Image = Image.FromFile(splashFile);
                }
            } catch { }

            this.Controls.Add(picBox);
        }
    }

    // --- Main Menu Form ---
    public class MainMenuForm : Form {
        private Panel headerPanel;
        private PictureBox headerIconBox;
        private Label headerTitle;
        private Label headerSubtitle;
        private Button btnSetup;
        private Button btnTools;
        private Button btnAbout;
        private Button btnExit;
        public string NextAction { get; set; } = "Exit";

        public MainMenuForm(string currentVersion = "6.1.0") {
            this.Text = "Hat's Multitool";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(320, 360);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            // Header Section
            headerPanel = new Panel {
                Location = new Point(0, 0),
                Size = new Size(320, 90),
                BackColor = DarkTheme.HeaderBackground
            };

            headerIconBox = new PictureBox {
                Size = new Size(46, 46),
                Location = new Point(20, 22),
                SizeMode = PictureBoxSizeMode.StretchImage
            };
            if (DarkTheme.AppIcon != null) {
                headerIconBox.Image = DarkTheme.AppIcon.ToBitmap();
            }

            headerTitle = new Label {
                Text = "Hat's Multitool",
                Font = DarkTheme.GetDefaultFont(16f, FontStyle.Bold),
                ForeColor = DarkTheme.TextMain,
                Location = new Point(74, 22),
                Size = new Size(235, 24)
            };

            headerSubtitle = new Label {
                Text = string.Format("v{0} | System Setup & Utilities", currentVersion),
                Font = DarkTheme.GetDefaultFont(10f),
                ForeColor = DarkTheme.TextMuted,
                Location = new Point(74, 48),
                Size = new Size(235, 20)
            };

            headerPanel.Controls.Add(headerIconBox);
            headerPanel.Controls.Add(headerTitle);
            headerPanel.Controls.Add(headerSubtitle);
            this.Controls.Add(headerPanel);

            // Action Buttons
            int y = 110;
            btnSetup = new Button {
                Location = new Point(40, y),
                Size = new Size(240, 42),
                Text = "PC Setup and Config"
            };
            DarkTheme.StyleButton(btnSetup);
            btnSetup.Click += (s, e) => {
                this.NextAction = "Setup";
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnSetup);

            y += 58;
            btnTools = new Button {
                Location = new Point(40, y),
                Size = new Size(240, 42),
                Text = "Tools & Troubleshooting"
            };
            DarkTheme.StyleButton(btnTools);
            btnTools.Click += (s, e) => {
                this.NextAction = "Tools";
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnTools);

            y += 58;
            btnAbout = new Button {
                Location = new Point(40, y),
                Size = new Size(115, 42),
                Text = "About"
            };
            DarkTheme.StyleButton(btnAbout);
            btnAbout.Click += (s, e) => {
                using (var about = new AboutForm(currentVersion)) {
                    about.ShowDialog(this);
                }
            };
            this.Controls.Add(btnAbout);

            btnExit = new Button {
                Location = new Point(165, y),
                Size = new Size(115, 42),
                Text = "Exit"
            };
            DarkTheme.StyleButton(btnExit);
            btnExit.Click += (s, e) => {
                this.NextAction = "Exit";
                this.Close();
            };
            this.Controls.Add(btnExit);

            this.Load += (s, e) => {
                DarkTheme.ApplyDarkTitleBar(this);
            };
        }
    }

    // --- About Dialog Form ---
    public class AboutForm : Form {
        public AboutForm(string version = "6.1.0") {
            this.Text = "About Hat's Multitool";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(320, 380);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.ShowInTaskbar = false;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            var iconBox = new PictureBox {
                Size = new Size(90, 90),
                Location = new Point(115, 20),
                SizeMode = PictureBoxSizeMode.StretchImage
            };
            if (DarkTheme.AppIcon != null) {
                iconBox.Image = DarkTheme.AppIcon.ToBitmap();
            }
            this.Controls.Add(iconBox);

            int y = 125;
            var lblTitle = new Label {
                Text = "Hat's Multitool",
                Font = DarkTheme.GetDefaultFont(20f, FontStyle.Bold),
                ForeColor = DarkTheme.TextMain,
                Size = new Size(320, 30),
                Location = new Point(0, y),
                TextAlign = ContentAlignment.MiddleCenter
            };
            this.Controls.Add(lblTitle);

            y += 35;
            var lblVersion = new Label {
                Text = "v" + version,
                Font = DarkTheme.GetDefaultFont(11f),
                ForeColor = DarkTheme.TextMuted,
                Size = new Size(320, 25),
                Location = new Point(0, y),
                TextAlign = ContentAlignment.MiddleCenter
            };
            this.Controls.Add(lblVersion);

            y += 30;
            var lblAuthor = new Label {
                Text = string.Format("Created by Tyler Hatfield\n© {0} Hat's Things LLC\nReleased under the GPLv3 License", DateTime.Now.Year),
                Font = DarkTheme.GetDefaultFont(9.5f),
                ForeColor = DarkTheme.TextMain,
                Size = new Size(320, 60),
                Location = new Point(0, y),
                TextAlign = ContentAlignment.MiddleCenter
            };
            this.Controls.Add(lblAuthor);

            y += 65;
            var linkGithub = new LinkLabel {
                Text = "View Source on GitHub",
                LinkColor = DarkTheme.AccentPrimary,
                ActiveLinkColor = ColorTranslator.FromHtml("#7289DA"),
                Size = new Size(320, 25),
                Location = new Point(0, y),
                TextAlign = ContentAlignment.MiddleCenter
            };
            linkGithub.LinkClicked += (s, e) => {
                try { Process.Start("https://github.com/TylerHats/Hats-Multitool/"); } catch { }
            };
            this.Controls.Add(linkGithub);

            y += 35;
            var btnClose = new Button {
                Text = "Close",
                Size = new Size(100, 38),
                Location = new Point(110, y)
            };
            DarkTheme.StyleButton(btnClose);
            btnClose.Click += (s, e) => this.Close();
            this.Controls.Add(btnClose);

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Setup Module Selection Form ---
    public class SetupSelectorForm : Form {
        private CheckedListBox clbModules;
        private Button btnSelectAll;
        private Button btnOk;
        private Button btnSkip;
        public List<string> SelectedModules { get; private set; } = new List<string>();

        public SetupSelectorForm() {
            this.Text = "Hat's Multitool - Setup Modules";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(320, 420);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            var lbl = new Label {
                Text = "Please Select Modules:",
                ForeColor = DarkTheme.TextMain,
                Location = new Point(20, 15),
                AutoSize = true,
                Font = DarkTheme.GetDefaultFont(10.5f, FontStyle.Bold)
            };
            this.Controls.Add(lbl);

            clbModules = new CheckedListBox {
                Location = new Point(20, 45),
                Size = new Size(280, 200),
                BackColor = DarkTheme.Background,
                ForeColor = DarkTheme.TextMain,
                BorderStyle = BorderStyle.None,
                CheckOnClick = true,
                Font = DarkTheme.GetDefaultFont(10f)
            };

            string[] moduleNames = new string[] {
                "Time Zone",
                "Local Accounts",
                "System Properties",
                "Setup Options",
                "Bloat Cleanup",
                "Programs"
            };

            foreach (var m in moduleNames) {
                clbModules.Items.Add(m, false);
            }
            this.Controls.Add(clbModules);

            btnSelectAll = new Button {
                Text = "Select All",
                Location = new Point(102, 260),
                Size = new Size(115, 38)
            };
            DarkTheme.StyleButton(btnSelectAll);
            btnSelectAll.Click += (s, e) => {
                bool allChecked = clbModules.CheckedIndices.Count == clbModules.Items.Count;
                for (int i = 0; i < clbModules.Items.Count; i++) {
                    clbModules.SetItemChecked(i, !allChecked);
                }
                btnSelectAll.Text = allChecked ? "Select All" : "Deselect All";
            };
            this.Controls.Add(btnSelectAll);

            btnOk = new Button {
                Text = "OK",
                Location = new Point(45, 315),
                Size = new Size(105, 40)
            };
            DarkTheme.StyleButton(btnOk, DarkTheme.AccentSuccess);
            btnOk.Click += (s, e) => {
                SelectedModules.Clear();
                foreach (var item in clbModules.CheckedItems) {
                    SelectedModules.Add(item.ToString());
                }
                if (SelectedModules.Count > 0) {
                    this.DialogResult = DialogResult.OK;
                } else {
                    this.DialogResult = DialogResult.Cancel;
                }
                this.Close();
            };
            this.Controls.Add(btnOk);

            btnSkip = new Button {
                Text = "Skip",
                Location = new Point(170, 315),
                Size = new Size(105, 40)
            };
            DarkTheme.StyleButton(btnSkip);
            btnSkip.Click += (s, e) => {
                this.DialogResult = DialogResult.Cancel;
                this.Close();
            };
            this.Controls.Add(btnSkip);

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Time Zone Form ---
    public class TimeZoneForm : Form {
        private ComboBox cbTimeZone;
        private Button btnOk;

        public TimeZoneForm(string stepTitle = "Time Zone") {
            this.Text = stepTitle;
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(400, 160);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            var lbl = new Label {
                Text = "Select your time zone:",
                ForeColor = DarkTheme.TextMain,
                Location = new Point(20, 15),
                AutoSize = true
            };
            this.Controls.Add(lbl);

            cbTimeZone = new ComboBox {
                Location = new Point(20, 45),
                Size = new Size(360, 26),
                DropDownStyle = ComboBoxStyle.DropDownList,
                FlatStyle = FlatStyle.Flat,
                BackColor = DarkTheme.Surface,
                ForeColor = DarkTheme.TextMain
            };

            var timeZones = TimeZoneEngine.GetAvailableTimeZones();
            foreach (var tz in timeZones) {
                cbTimeZone.Items.Add(tz);
            }
            cbTimeZone.SelectedItem = TimeZoneEngine.GetCurrentTimeZoneId();
            this.Controls.Add(cbTimeZone);

            btnOk = new Button {
                Text = "OK",
                Location = new Point(300, 95),
                Size = new Size(80, 34)
            };
            DarkTheme.StyleButton(btnOk, DarkTheme.AccentSuccess);
            btnOk.Click += (s, e) => {
                string selTz = cbTimeZone.SelectedItem?.ToString();
                if (!string.IsNullOrEmpty(selTz)) {
                    TimeZoneEngine.SetTimeZone(selTz);
                    TimeZoneEngine.ConfigureNtpAndSync();
                }
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnOk);
            this.AcceptButton = btnOk;

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Local Accounts Form ---
    public class LocalAccountsForm : Form {
        private DarkTextBox txtUsername;
        private DarkTextBox txtPassword;
        private DarkTextBox txtConfirm;
        private Button btnShowPw;
        private CheckBox chkUpdatePw;
        private CheckBox chkMakeAdmin;
        private Button btnOk;
        private Button btnSkip;

        public LocalAccountsForm(string stepTitle = "Local Accounts") {
            this.Text = stepTitle;
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(320, 340);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            int y = 12;
            var lblDesc = new Label {
                Text = "Enter account information:",
                ForeColor = DarkTheme.TextMain,
                Location = new Point(15, y),
                AutoSize = true
            };
            this.Controls.Add(lblDesc);

            int minPw = AccountEngine.GetMinimumPasswordLength();
            y += 22;
            var lblPolicy = new Label {
                Text = minPw > 0 ? string.Format("Local Policy: Min Password Length is {0} chars.", minPw) : "Local Policy: No password required.",
                ForeColor = minPw > 0 ? DarkTheme.AccentWarning : DarkTheme.TextMuted,
                Location = new Point(15, y),
                AutoSize = true
            };
            this.Controls.Add(lblPolicy);

            y += 30;
            txtUsername = new DarkTextBox {
                Location = new Point(18, y),
                Width = 280
            };
            txtUsername.Text = "";
            NativeMethods.SendMessage(txtUsername.Handle, 0x1501, 0, "Username");
            this.Controls.Add(txtUsername);

            y += 38;
            txtPassword = new DarkTextBox {
                Location = new Point(18, y),
                Width = 230,
                UseSystemPasswordChar = true
            };
            NativeMethods.SendMessage(txtPassword.Handle, 0x1501, 0, "Password");
            this.Controls.Add(txtPassword);

            btnShowPw = new Button {
                Location = new Point(252, y),
                Size = new Size(46, 24),
                Text = "👁"
            };
            DarkTheme.StyleButton(btnShowPw);
            btnShowPw.MouseDown += (s, e) => {
                txtPassword.UseSystemPasswordChar = false;
                txtConfirm.UseSystemPasswordChar = false;
            };
            btnShowPw.MouseUp += (s, e) => {
                txtPassword.UseSystemPasswordChar = true;
                txtConfirm.UseSystemPasswordChar = true;
            };
            this.Controls.Add(btnShowPw);

            y += 38;
            txtConfirm = new DarkTextBox {
                Location = new Point(18, y),
                Width = 280,
                UseSystemPasswordChar = true
            };
            NativeMethods.SendMessage(txtConfirm.Handle, 0x1501, 0, "Confirm Password");
            this.Controls.Add(txtConfirm);

            y += 35;
            chkUpdatePw = new CheckBox {
                Location = new Point(20, y),
                Text = "Update Password",
                ForeColor = DarkTheme.TextMain,
                AutoSize = true
            };
            this.Controls.Add(chkUpdatePw);

            y += 28;
            chkMakeAdmin = new CheckBox {
                Location = new Point(20, y),
                Text = "Make Local Admin",
                ForeColor = DarkTheme.TextMain,
                AutoSize = true
            };
            this.Controls.Add(chkMakeAdmin);

            y += 40;
            btnOk = new Button {
                Location = new Point(165, y),
                Size = new Size(95, 38),
                Text = "OK",
                Enabled = false
            };
            DarkTheme.StyleButton(btnOk, DarkTheme.AccentSuccess);
            btnOk.Click += (s, e) => {
                string err;
                bool ok = AccountEngine.CreateOrUpdateUser(txtUsername.Text.Trim(), txtPassword.Text, chkUpdatePw.Checked, chkMakeAdmin.Checked, out err);
                if (ok) {
                    txtUsername.Clear();
                    txtPassword.Clear();
                    txtConfirm.Clear();
                    chkUpdatePw.Checked = false;
                    chkMakeAdmin.Checked = false;
                    btnSkip.Text = "Close";
                } else {
                    MessageBox.Show(err, "Account Configuration", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            };
            this.Controls.Add(btnOk);

            btnSkip = new Button {
                Location = new Point(60, y),
                Size = new Size(95, 38),
                Text = "Skip"
            };
            DarkTheme.StyleButton(btnSkip);
            btnSkip.Click += (s, e) => {
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnSkip);

            EventHandler validate = (s, e) => {
                bool uFilled = !string.IsNullOrWhiteSpace(txtUsername.Text);
                bool pwMatch = txtPassword.Text == txtConfirm.Text;
                btnOk.Enabled = uFilled && pwMatch;
            };

            txtUsername.TextChanged += validate;
            txtPassword.TextChanged += validate;
            txtConfirm.TextChanged += validate;

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- System Properties Form ---
    public class SystemPropertiesForm : Form {
        private DarkTextBox txtComputerName;
        private CheckBox chkDomain;
        private CheckBox chkEntra;
        private DarkTextBox txtDomainName;
        private CheckBox chkEdition;
        private DarkTextBox txtProductKey;
        private Button btnOk;
        private Button btnSkip;

        public SystemPropertiesForm(string stepTitle = "System Properties") {
            this.Text = stepTitle;
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(320, 360);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            bool isPro = SystemPropertiesEngine.IsWindowsPro();
            string curDomain;
            bool isJoined = SystemPropertiesEngine.IsDomainJoined(out curDomain);
            string serial = SystemPropertiesEngine.GetSerialNumber();

            int y = 10;
            var lblPrompt = new Label {
                Text = string.Format("Enter new device name:\n(Currently: {0})", Environment.MachineName),
                ForeColor = DarkTheme.TextMain,
                Location = new Point(15, y),
                AutoSize = true
            };
            this.Controls.Add(lblPrompt);

            y += 38;
            var lblSerial = new Label {
                Text = "Serial Number: " + serial,
                ForeColor = DarkTheme.TextMuted,
                Location = new Point(15, y),
                AutoSize = true,
                Cursor = Cursors.Hand
            };
            lblSerial.Click += (s, e) => {
                try {
                    Clipboard.SetText(serial);
                    var tip = new ToolTip();
                    tip.Show("Copied!", lblSerial, 0, -20, 1200);
                } catch { }
            };
            this.Controls.Add(lblSerial);

            y += 28;
            txtComputerName = new DarkTextBox {
                Location = new Point(18, y),
                Width = 280,
                MaxLength = 15
            };
            NativeMethods.SendMessage(txtComputerName.Handle, 0x1501, 1, "Computer Name");
            this.Controls.Add(txtComputerName);

            y += 35;
            chkDomain = new CheckBox {
                Location = new Point(20, y),
                Text = "Join to Domain",
                ForeColor = DarkTheme.TextMain,
                AutoSize = true,
                Enabled = isPro && !isJoined,
                Checked = isJoined
            };
            this.Controls.Add(chkDomain);

            y += 28;
            chkEntra = new CheckBox {
                Location = new Point(20, y),
                Text = "Join to EntraID",
                ForeColor = DarkTheme.TextMain,
                AutoSize = true,
                Enabled = isPro && !isJoined
            };
            this.Controls.Add(chkEntra);

            y += 30;
            txtDomainName = new DarkTextBox {
                Location = new Point(18, y),
                Width = 280,
                Enabled = false,
                Text = isJoined ? curDomain : (!isPro ? "Edition: Home" : "")
            };
            NativeMethods.SendMessage(txtDomainName.Handle, 0x1501, 1, "Domain Name");
            this.Controls.Add(txtDomainName);

            y += 35;
            chkEdition = new CheckBox {
                Location = new Point(20, y),
                Text = "Set Edition to Pro",
                ForeColor = DarkTheme.TextMain,
                AutoSize = true,
                Enabled = !isPro
            };
            this.Controls.Add(chkEdition);

            y += 28;
            txtProductKey = new DarkTextBox {
                Location = new Point(18, y),
                Width = 280,
                Enabled = false
            };
            NativeMethods.SendMessage(txtProductKey.Handle, 0x1501, 1, "VK7JG-NPHTM-C97JM-9MPGT-3V66T");
            this.Controls.Add(txtProductKey);

            y += 40;
            btnOk = new Button {
                Location = new Point(165, y),
                Size = new Size(95, 38),
                Text = "OK",
                Enabled = false
            };
            DarkTheme.StyleButton(btnOk, DarkTheme.AccentSuccess);
            this.Controls.Add(btnOk);

            btnSkip = new Button {
                Location = new Point(60, y),
                Size = new Size(95, 38),
                Text = "Skip"
            };
            DarkTheme.StyleButton(btnSkip);
            btnSkip.Click += (s, e) => {
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnSkip);

            chkDomain.CheckedChanged += (s, e) => {
                if (chkDomain.Checked) {
                    txtDomainName.Enabled = true;
                    chkEntra.Checked = false;
                } else {
                    txtDomainName.Enabled = false;
                }
            };

            chkEntra.CheckedChanged += (s, e) => {
                if (chkEntra.Checked) {
                    chkDomain.Checked = false;
                    txtDomainName.Enabled = false;
                }
            };

            chkEdition.CheckedChanged += (s, e) => {
                txtProductKey.Enabled = chkEdition.Checked;
            };

            EventHandler validate = (s, e) => {
                bool validName = SystemPropertiesEngine.TestComputerName(txtComputerName.Text.Trim());
                bool validDomain = chkDomain.Checked && !string.IsNullOrWhiteSpace(txtDomainName.Text);
                bool entra = chkEntra.Checked;
                bool edition = chkEdition.Checked;
                btnOk.Enabled = validName || validDomain || entra || edition;
            };

            txtComputerName.TextChanged += validate;
            txtDomainName.TextChanged += validate;
            chkDomain.CheckedChanged += validate;
            chkEntra.CheckedChanged += validate;
            chkEdition.CheckedChanged += validate;

            btnOk.Click += (s, e) => {
                btnOk.Enabled = false;
                btnOk.Text = "Processing...";
                string err;

                if (!string.IsNullOrWhiteSpace(txtComputerName.Text)) {
                    SystemPropertiesEngine.RenameComputer(txtComputerName.Text.Trim(), out err);
                }
                if (chkEdition.Checked) {
                    SystemPropertiesEngine.UpgradeToPro(txtProductKey.Text.Trim(), out err);
                }

                this.DialogResult = DialogResult.OK;
                this.Close();
            };

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Setup Options Form ---
    public class SetupOptionsForm : Form {
        private ListView lvOptions;
        private Button btnOk;

        public SetupOptionsForm(string stepTitle = "Setup Options") {
            this.Text = stepTitle;
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(640, 380);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            var lbl = new Label {
                Text = "Select setup options:",
                ForeColor = DarkTheme.TextMain,
                Location = new Point(20, 12),
                AutoSize = true
            };
            this.Controls.Add(lbl);

            lvOptions = new ListView {
                Location = new Point(20, 38),
                Size = new Size(600, 260),
                View = View.Details,
                CheckBoxes = true,
                FullRowSelect = true,
                HeaderStyle = ColumnHeaderStyle.None,
                BackColor = DarkTheme.Surface,
                ForeColor = DarkTheme.TextMain,
                BorderStyle = BorderStyle.FixedSingle
            };
            lvOptions.Columns.Add("Option", 580);

            var options = new Tuple<string, string>[] {
                Tuple.Create("NumLock - Default On for Login and New User Sessions", "numlock"),
                Tuple.Create("Disable Windows Default Printer Management", "defprint"),
                Tuple.Create("Restore Classic Windows 11 Right-Click Context Menu", "classicmenu"),
                Tuple.Create("Prevent Automatic Windows Hello PIN Setup on First Login", "hellopin"),
                Tuple.Create("Disable Device Power Saving (USB Suspend, PCIe ASPM, & NIC Power Save)", "devicepower"),
                Tuple.Create("Disable Windows Fast Startup (Forces True Kernel Shutdown)", "disablefaststartup"),
                Tuple.Create("Enable Hibernation & Add Hibernation to Start Power Menu", "enablehibernation"),
                Tuple.Create("Disable Sticky Keys & Toggle Keys Shortcut Prompts", "disablestickykeys")
            };

            foreach (var opt in options) {
                var item = new ListViewItem(opt.Item1);
                item.Tag = opt.Item2;
                lvOptions.Items.Add(item);
            }
            this.Controls.Add(lvOptions);

            btnOk = new Button {
                Text = "OK",
                Location = new Point(270, 320),
                Size = new Size(100, 38)
            };
            DarkTheme.StyleButton(btnOk, DarkTheme.AccentSuccess);
            btnOk.Click += (s, e) => {
                btnOk.Enabled = false;
                foreach (ListViewItem item in lvOptions.CheckedItems) {
                    string tag = item.Tag?.ToString();
                    if (!string.IsNullOrEmpty(tag)) {
                        SetupOptionsEngine.ApplyOption(tag);
                    }
                }
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnOk);
            this.AcceptButton = btnOk;

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Bloat Cleanup Form ---
    public class BloatCleanupForm : Form {
        private Label lblStatus;
        private Label lblDetail;
        private SmoothProgressBar progressBar;

        public BloatCleanupForm(string stepTitle = "Bloat Cleanup") {
            this.Text = stepTitle;
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(480, 160);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            lblStatus = new Label {
                Text = "Preparing Bloat Cleanup...",
                ForeColor = DarkTheme.TextMain,
                Location = new Point(20, 18),
                Size = new Size(440, 22),
                Font = DarkTheme.GetDefaultFont(10f, FontStyle.Bold)
            };
            this.Controls.Add(lblStatus);

            lblDetail = new Label {
                Text = "Scanning installed AppX packages...",
                ForeColor = DarkTheme.TextMuted,
                Location = new Point(20, 42),
                Size = new Size(440, 20)
            };
            this.Controls.Add(lblDetail);

            progressBar = new SmoothProgressBar {
                Location = new Point(20, 70),
                Size = new Size(440, 20),
                BorderRadius = 5,
                ProgressColor = DarkTheme.AccentPurple,
                ProgressColorEnd = DarkTheme.AccentPrimary,
                ShowShimmer = true
            };
            this.Controls.Add(progressBar);

            this.Shown += async (s, e) => {
                var progress = new Progress<BloatProgressInfo>(info => {
                    lblStatus.Text = info.Status;
                    lblDetail.Text = info.Detail;
                    progressBar.Value = info.ProgressPercentage;
                });

                await BloatCleanupEngine.ExecuteBloatCleanupAsync(progress);
                await Task.Delay(400);
                this.DialogResult = DialogResult.OK;
                this.Close();
            };

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Programs Form ---
    public class ProgramsForm : Form {
        private ListView lvPrograms;
        private CheckBox chkAutoExit;
        private Button btnInstall;
        private Button btnSkip;
        private Label lblMsStatus;
        private Label lblMsDetail;
        private SmoothProgressBar msProgressBar;
        private CancellationTokenSource cts = new CancellationTokenSource();

        public ProgramsForm(string stepTitle = "Programs") {
            this.Text = stepTitle;
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(720, 520);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            var lbl = new Label {
                Text = "Select Software to Install:",
                ForeColor = DarkTheme.TextMain,
                Location = new Point(20, 12),
                AutoSize = true,
                Font = DarkTheme.GetDefaultFont(10.5f, FontStyle.Bold)
            };
            this.Controls.Add(lbl);

            lvPrograms = new ListView {
                Location = new Point(20, 40),
                Size = new Size(680, 360),
                View = View.Details,
                CheckBoxes = true,
                FullRowSelect = true,
                BackColor = DarkTheme.Surface,
                ForeColor = DarkTheme.TextMain,
                BorderStyle = BorderStyle.FixedSingle
            };
            lvPrograms.Columns.Add("Software", 260);
            lvPrograms.Columns.Add("Category", 160);
            lvPrograms.Columns.Add("Type / Source", 140);
            lvPrograms.Columns.Add("Status", 100);

            var catalog = ProgramInstallerEngine.GetCatalog();
            foreach (var item in catalog) {
                var lvi = new ListViewItem(item.Name);
                lvi.SubItems.Add(item.Category);
                lvi.SubItems.Add(item.Type == "Winget" ? "WinGet" : "Microsoft CTR");
                bool installed = ProgramInstallerEngine.IsProgramInstalled(item);
                lvi.SubItems.Add(installed ? "Installed" : "Available");
                if (installed) {
                    lvi.ForeColor = DarkTheme.TextMuted;
                }
                lvi.Tag = item;
                lvPrograms.Items.Add(lvi);
            }
            this.Controls.Add(lvPrograms);

            lblMsStatus = new Label {
                Location = new Point(20, 410),
                Size = new Size(680, 20),
                ForeColor = DarkTheme.TextMain,
                Visible = false
            };
            this.Controls.Add(lblMsStatus);

            lblMsDetail = new Label {
                Location = new Point(20, 432),
                Size = new Size(680, 20),
                ForeColor = DarkTheme.TextMuted,
                Visible = false
            };
            this.Controls.Add(lblMsDetail);

            msProgressBar = new SmoothProgressBar {
                Location = new Point(20, 456),
                Size = new Size(680, 16),
                Visible = false,
                BorderRadius = 4,
                ProgressColor = DarkTheme.AccentPurple,
                ProgressColorEnd = DarkTheme.AccentPrimary
            };
            this.Controls.Add(msProgressBar);

            chkAutoExit = new CheckBox {
                Location = new Point(20, 480),
                Text = "Auto-exit when complete",
                ForeColor = DarkTheme.TextMain,
                AutoSize = true
            };
            this.Controls.Add(chkAutoExit);

            btnInstall = new Button {
                Text = "Install Selected",
                Location = new Point(460, 475),
                Size = new Size(130, 36)
            };
            DarkTheme.StyleButton(btnInstall, DarkTheme.AccentSuccess);
            btnInstall.Click += async (s, e) => {
                btnInstall.Enabled = false;
                btnSkip.Enabled = false;

                var selected = new List<SoftwareItem>();
                foreach (ListViewItem item in lvPrograms.CheckedItems) {
                    if (item.Tag is SoftwareItem si) {
                        selected.Add(si);
                    }
                }

                foreach (var prog in selected) {
                    if (prog.Type == "MSOffice" || prog.Type == "MSOutlook") {
                        lblMsStatus.Visible = true;
                        lblMsDetail.Visible = true;
                        msProgressBar.Visible = true;

                        var progress = new Progress<BloatProgressInfo>(info => {
                            lblMsStatus.Text = info.Status;
                            lblMsDetail.Text = info.Detail;
                            msProgressBar.Value = info.ProgressPercentage;
                        });

                        await ProgramInstallerEngine.DeployOfficeAsync(prog.Type == "MSOffice", progress, cts.Token);
                    } else if (prog.Type == "Winget") {
                        lblMsStatus.Visible = true;
                        lblMsDetail.Visible = true;
                        msProgressBar.Visible = true;
                        msProgressBar.Value = 50;

                        var progress = new Progress<string>(msg => {
                            lblMsStatus.Text = "Installing " + prog.Name;
                            lblMsDetail.Text = msg;
                        });

                        await ProgramInstallerEngine.InstallWingetPackageAsync(prog.WingetID, progress, cts.Token);
                    }
                }

                lblMsStatus.Text = "Installation Complete!";
                lblMsDetail.Text = "All selected software packages have been processed.";
                msProgressBar.Value = 100;
                btnSkip.Text = "Close";
                btnSkip.Enabled = true;

                if (chkAutoExit.Checked) {
                    Application.Exit();
                }
            };
            this.Controls.Add(btnInstall);

            btnSkip = new Button {
                Text = "Skip",
                Location = new Point(600, 475),
                Size = new Size(100, 36)
            };
            DarkTheme.StyleButton(btnSkip);
            btnSkip.Click += (s, e) => {
                this.DialogResult = DialogResult.OK;
                this.Close();
            };
            this.Controls.Add(btnSkip);

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Tools & Troubleshooting Form ---
    public class ToolsForm : Form {
        private DarkTabControl tabControl;
        private Button btnLaunch;
        private Button btnClose;

        public ToolsForm() {
            this.Text = "Hat's Multitool - Tools & Troubleshooting";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(780, 560);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            tabControl = new DarkTabControl {
                Location = new Point(20, 15),
                Size = new Size(740, 470)
            };

            // 1. System Repair Tab
            var tabRepair = new TabPage("System Repair") { BackColor = DarkTheme.Background };
            var lvRepair = CreateToolListView();
            AddToolItem(lvRepair, "DISM Repair", "Launches DISM image health restore with live progress.", "cmd", "dism.exe /Online /Cleanup-Image /RestoreHealth");
            AddToolItem(lvRepair, "SFC Repair", "Executes System File Checker (sfc /scannow).", "cmd", "sfc.exe /scannow");
            AddToolItem(lvRepair, "Check Disk (Read Only)", "Runs Check Disk (chkdsk C:) in read-only mode.", "cmd", "chkdsk.exe C:");
            AddToolItem(lvRepair, ".NET 3.5 (Includes v2 and v3)", "Installs .NET Framework 3.5/2.0/3.0 via DISM.", "cmd", "dism.exe /online /enable-feature /featurename:NetFX3 /All");
            AddToolItem(lvRepair, "Windows Update Reset", "Stops update services, clears SoftwareDistribution, and resets components.", "custom", "winupdate_reset");
            AddToolItem(lvRepair, "Reset HOSTS File to Default", "Resets Windows HOSTS file back to clean Microsoft default.", "custom", "hosts_reset");
            tabRepair.Controls.Add(lvRepair);
            tabControl.TabPages.Add(tabRepair);

            // 2. Disk & Storage Tab
            var tabDisk = new TabPage("Disk & Storage") { BackColor = DarkTheme.Background };
            var lvDisk = CreateToolListView();
            AddToolItem(lvDisk, "Windows Disk Cleanup", "Launches the native Windows Disk Cleanup utility.", "cmd", "cleanmgr.exe");
            AddToolItem(lvDisk, "SMART Info & Benchmarking", "Hardware health summary, wearout gauge, and built-in benchmark.", "custom", "smart_bench");
            AddToolItem(lvDisk, "BitLocker Management", "Inspect status, manage recovery keys, and unlock drives.", "custom", "bitlocker");
            AddToolItem(lvDisk, "Startup & Autoruns Manager", "Inspect, enable, disable, or remove startup applications.", "custom", "startup_manager");
            tabDisk.Controls.Add(lvDisk);
            tabControl.TabPages.Add(tabDisk);

            // 3. Network & Connectivity Tab
            var tabNet = new TabPage("Network & Connectivity") { BackColor = DarkTheme.Background };
            var lvNet = CreateToolListView();
            AddToolItem(lvNet, "Internet Speed Test", "Real-time speed test measuring Ping, Jitter, Download, and Upload.", "custom", "speed_test");
            AddToolItem(lvNet, "Packet Loss & Latency Test", "High-precision latency & packet loss tester with real-time graph.", "custom", "latency_test");
            AddToolItem(lvNet, "TCP Port & Connection Checker", "Tests IP/hostname reachability and open TCP ports.", "custom", "tcp_checker");
            AddToolItem(lvNet, "Flush DNS & Reset IP", "Releases/renews IP, flushes DNS cache, and clears ARP entries.", "cmd", "cmd.exe /c ipconfig /flushdns & ipconfig /renew");
            tabNet.Controls.Add(lvNet);
            tabControl.TabPages.Add(tabNet);

            // 4. Viewers & Utilities Tab
            var tabViewers = new TabPage("Viewers & Utilities") { BackColor = DarkTheme.Background };
            var lvViewers = CreateToolListView();
            AddToolItem(lvViewers, "Generate Battery Report", "Generates HTML battery health report.", "cmd", "powercfg.exe /batteryreport /output \"%USERPROFILE%\\Desktop\\battery-report.html\"");
            AddToolItem(lvViewers, "Reliability Monitor", "Opens Windows Reliability Monitor timeline.", "cmd", "perfmon.exe /rel");
            AddToolItem(lvViewers, "Restart Windows Explorer", "Kills and restarts explorer.exe.", "cmd", "taskkill.exe /f /im explorer.exe & start explorer.exe");
            tabViewers.Controls.Add(lvViewers);
            tabControl.TabPages.Add(tabViewers);

            this.Controls.Add(tabControl);

            btnLaunch = new Button {
                Text = "Launch Selected",
                Location = new Point(500, 500),
                Size = new Size(135, 38)
            };
            DarkTheme.StyleButton(btnLaunch, DarkTheme.AccentPrimary);
            btnLaunch.Click += (s, e) => LaunchCurrentTool();
            this.Controls.Add(btnLaunch);

            btnClose = new Button {
                Text = "Close",
                Location = new Point(645, 500),
                Size = new Size(115, 38)
            };
            DarkTheme.StyleButton(btnClose);
            btnClose.Click += (s, e) => this.Close();
            this.Controls.Add(btnClose);

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }

        private DarkListView CreateToolListView() {
            var lv = new DarkListView {
                Dock = DockStyle.Fill,
                View = View.Details,
                FullRowSelect = true,
                AutoFillLastColumn = true
            };
            lv.Columns.Add("Tool", 220);
            lv.Columns.Add("Description", 500);
            lv.DoubleClick += (s, e) => LaunchCurrentTool();
            return lv;
        }

        private void AddToolItem(DarkListView lv, string name, string desc, string actionType, string command) {
            var item = new ListViewItem(name);
            item.SubItems.Add(desc);
            item.Tag = Tuple.Create(actionType, command);
            lv.Items.Add(item);
        }

        private void LaunchCurrentTool() {
            var tab = tabControl.SelectedTab;
            if (tab?.Controls.Count > 0 && tab.Controls[0] is DarkListView lv) {
                if (lv.SelectedItems.Count > 0) {
                    var tuple = lv.SelectedItems[0].Tag as Tuple<string, string>;
                    if (tuple != null) {
                        string type = tuple.Item1;
                        string cmd = tuple.Item2;

                        if (type == "cmd") {
                            try {
                                Process.Start(new ProcessStartInfo {
                                    FileName = "cmd.exe",
                                    Arguments = "/k " + cmd,
                                    UseShellExecute = true
                                });
                            } catch { }
                        } else if (type == "custom") {
                            LaunchCustomTool(cmd);
                        }
                    }
                }
            }
        }

        private void LaunchCustomTool(string id) {
            switch (id) {
                case "speed_test":
                    using (var frm = new SpeedTestForm()) { frm.ShowDialog(this); }
                    break;
                case "startup_manager":
                    using (var frm = new StartupManagerForm()) { frm.ShowDialog(this); }
                    break;
                case "tcp_checker":
                    using (var frm = new TcpCheckerForm()) { frm.ShowDialog(this); }
                    break;
                case "hosts_reset":
                    try {
                        string hostsPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "drivers", "etc", "hosts");
                        string backup = hostsPath + ".bak";
                        if (File.Exists(hostsPath)) {
                            File.Copy(hostsPath, backup, true);
                            File.WriteAllText(hostsPath, "# Copyright (c) 1993-2009 Microsoft Corp.\n127.0.0.1       localhost\n::1             localhost\n");
                            MessageBox.Show("HOSTS file reset to default. Backup created at " + backup, "HOSTS Reset", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    } catch (Exception ex) {
                        MessageBox.Show("Failed to reset HOSTS file: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                    break;
            }
        }
    }

    // --- Built-in Speed Test Form ---
    public class SpeedTestForm : Form {
        private FastSpeedTestEngine engine;
        private Label lblPing;
        private Label lblJitter;
        private Label lblDownload;
        private Label lblUpload;
        private SmoothGraphControl graphControl;
        private Button btnStart;

        public SpeedTestForm() {
            this.Text = "Internet Speed Test (Cloudflare Anycast)";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(540, 420);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            int y = 15;
            lblPing = new Label { Text = "Ping: -- ms", Location = new Point(20, y), Size = new Size(120, 22), ForeColor = DarkTheme.TextMain, Font = DarkTheme.GetDefaultFont(10f, FontStyle.Bold) };
            lblJitter = new Label { Text = "Jitter: -- ms", Location = new Point(150, y), Size = new Size(120, 22), ForeColor = DarkTheme.TextMain, Font = DarkTheme.GetDefaultFont(10f, FontStyle.Bold) };
            lblDownload = new Label { Text = "Download: -- Mbps", Location = new Point(280, y), Size = new Size(120, 22), ForeColor = DarkTheme.AccentSuccess, Font = DarkTheme.GetDefaultFont(10f, FontStyle.Bold) };
            lblUpload = new Label { Text = "Upload: -- Mbps", Location = new Point(410, y), Size = new Size(120, 22), ForeColor = DarkTheme.AccentPrimary, Font = DarkTheme.GetDefaultFont(10f, FontStyle.Bold) };

            this.Controls.Add(lblPing);
            this.Controls.Add(lblJitter);
            this.Controls.Add(lblDownload);
            this.Controls.Add(lblUpload);

            graphControl = new SmoothGraphControl {
                Location = new Point(20, 45),
                Size = new Size(500, 310)
            };
            this.Controls.Add(graphControl);

            btnStart = new Button {
                Text = "Start Test",
                Location = new Point(210, 368),
                Size = new Size(120, 38)
            };
            DarkTheme.StyleButton(btnStart, DarkTheme.AccentSuccess);
            btnStart.Click += async (s, e) => {
                btnStart.Enabled = false;
                engine = new FastSpeedTestEngine();

                engine.OnSpeedSample += (sample) => {
                    this.BeginInvoke((Action)(() => {
                        if (sample.Phase == "Download") {
                            lblDownload.Text = string.Format("Download: {0:F1} Mbps", sample.CurrentMbps);
                            graphControl.AddPoint((float)sample.CurrentMbps);
                        } else if (sample.Phase == "Upload") {
                            lblUpload.Text = string.Format("Upload: {0:F1} Mbps", sample.CurrentMbps);
                            graphControl.AddPoint((float)sample.CurrentMbps);
                        }
                    }));
                };

                await Task.Run(() => {
                    engine.RunDownloadTest("https://speed.cloudflare.com/__down?bytes=25000000", 6);
                    engine.RunUploadTest("https://speed.cloudflare.com/__up", 4);
                });

                btnStart.Enabled = true;
            };
            this.Controls.Add(btnStart);

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }

    // --- Startup Manager Form ---
    public class StartupManagerForm : Form {
        private DarkListView lvStartup;
        private ComboBox cbFilter;
        private DarkTextBox txtSearch;
        private Button btnToggle;
        private Button btnDelete;
        private List<StartupItem> allEntries = new List<StartupItem>();

        public StartupManagerForm() {
            this.Text = "Startup & Autoruns Manager";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(760, 480);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            cbFilter = new ComboBox {
                Location = new Point(20, 15),
                Size = new Size(160, 24),
                DropDownStyle = ComboBoxStyle.DropDownList,
                BackColor = DarkTheme.Surface,
                ForeColor = DarkTheme.TextMain,
                FlatStyle = FlatStyle.Flat
            };
            cbFilter.Items.AddRange(new object[] { "All Categories", "HKLM Run", "HKCU Run", "Startup Folders", "Services" });
            cbFilter.SelectedIndex = 0;
            cbFilter.SelectedIndexChanged += (s, e) => FilterEntries();
            this.Controls.Add(cbFilter);

            txtSearch = new DarkTextBox {
                Location = new Point(190, 15),
                Width = 220
            };
            NativeMethods.SendMessage(txtSearch.Handle, 0x1501, 0, "Search startup items...");
            txtSearch.TextChanged += (s, e) => FilterEntries();
            this.Controls.Add(txtSearch);

            lvStartup = new DarkListView {
                Location = new Point(20, 48),
                Size = new Size(720, 370),
                View = View.Details,
                FullRowSelect = true,
                AutoFillLastColumn = true
            };
            lvStartup.Columns.Add("Name", 180);
            lvStartup.Columns.Add("Status", 80);
            lvStartup.Columns.Add("Location", 140);
            lvStartup.Columns.Add("Command / Path", 300);
            this.Controls.Add(lvStartup);

            btnToggle = new Button {
                Text = "Enable / Disable",
                Location = new Point(480, 428),
                Size = new Size(130, 36)
            };
            DarkTheme.StyleButton(btnToggle);
            btnToggle.Click += (s, e) => {
                if (lvStartup.SelectedItems.Count > 0 && lvStartup.SelectedItems[0].Tag is StartupItem) {
                    RefreshEntries();
                }
            };
            this.Controls.Add(btnToggle);

            btnDelete = new Button {
                Text = "Delete",
                Location = new Point(620, 428),
                Size = new Size(120, 36)
            };
            DarkTheme.StyleButton(btnDelete, DarkTheme.AccentDanger);
            this.Controls.Add(btnDelete);

            this.Shown += (s, e) => RefreshEntries();
            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }

        private void RefreshEntries() {
            allEntries = StartupScanner.ScanAll();
            FilterEntries();
        }

        private void FilterEntries() {
            lvStartup.Items.Clear();
            string search = txtSearch.Text.Trim().ToLowerInvariant();
            string filter = cbFilter.SelectedItem?.ToString() ?? "All Categories";

            foreach (var entry in allEntries) {
                if (!string.IsNullOrEmpty(search) && !entry.Name.ToLowerInvariant().Contains(search) && !entry.Command.ToLowerInvariant().Contains(search)) {
                    continue;
                }
                if (filter != "All Categories" && !entry.Location.Contains(filter)) {
                    continue;
                }

                var item = new ListViewItem(entry.Name);
                item.SubItems.Add(entry.Status);
                item.SubItems.Add(entry.Location);
                item.SubItems.Add(entry.Command);
                if (entry.Status == "Disabled") {
                    item.ForeColor = DarkTheme.TextMuted;
                }
                item.Tag = entry;
            }
        }
    }

    // --- TCP Port & Connection Checker Form ---
    public class TcpCheckerForm : Form {
        private DarkTextBox txtHost;
        private DarkTextBox txtPort;
        private Button btnTest;
        private Label lblResult;

        public TcpCheckerForm() {
            this.Text = "TCP Port & Connection Checker";
            this.BackColor = DarkTheme.Background;
            this.ClientSize = new Size(380, 200);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.Icon = DarkTheme.AppIcon;
            this.Font = DarkTheme.GetDefaultFont();

            var lblHost = new Label { Text = "Host / IP Address:", Location = new Point(20, 15), AutoSize = true, ForeColor = DarkTheme.TextMain };
            txtHost = new DarkTextBox { Location = new Point(20, 38), Width = 220, Text = "1.1.1.1" };

            var lblPort = new Label { Text = "Port:", Location = new Point(255, 15), AutoSize = true, ForeColor = DarkTheme.TextMain };
            txtPort = new DarkTextBox { Location = new Point(255, 38), Width = 100, Text = "443" };

            this.Controls.Add(lblHost);
            this.Controls.Add(txtHost);
            this.Controls.Add(lblPort);
            this.Controls.Add(txtPort);

            btnTest = new Button {
                Text = "Test Connection",
                Location = new Point(20, 80),
                Size = new Size(130, 36)
            };
            DarkTheme.StyleButton(btnTest, DarkTheme.AccentPrimary);
            this.Controls.Add(btnTest);

            lblResult = new Label {
                Location = new Point(20, 130),
                Size = new Size(340, 50),
                ForeColor = DarkTheme.TextMain,
                Font = DarkTheme.GetDefaultFont(10f, FontStyle.Bold)
            };
            this.Controls.Add(lblResult);

            btnTest.Click += async (s, e) => {
                btnTest.Enabled = false;
                lblResult.Text = "Connecting...";
                lblResult.ForeColor = DarkTheme.TextMain;

                string host = txtHost.Text.Trim();
                int port;
                if (!int.TryParse(txtPort.Text.Trim(), out port)) {
                    lblResult.Text = "Invalid Port number.";
                    lblResult.ForeColor = DarkTheme.AccentDanger;
                    btnTest.Enabled = true;
                    return;
                }

                await Task.Run(() => {
                    var sw = Stopwatch.StartNew();
                    try {
                        using (var tcp = new System.Net.Sockets.TcpClient()) {
                            var ar = tcp.BeginConnect(host, port, null, null);
                            bool ok = ar.AsyncWaitHandle.WaitOne(TimeSpan.FromSeconds(3));
                            sw.Stop();
                            if (ok && tcp.Connected) {
                                this.BeginInvoke((Action)(() => {
                                    lblResult.Text = string.Format("SUCCESS: Connected to {0}:{1} in {2}ms", host, port, sw.ElapsedMilliseconds);
                                    lblResult.ForeColor = DarkTheme.AccentSuccess;
                                }));
                            } else {
                                this.BeginInvoke((Action)(() => {
                                    lblResult.Text = string.Format("FAILED: Connection to {0}:{1} timed out.", host, port);
                                    lblResult.ForeColor = DarkTheme.AccentDanger;
                                }));
                            }
                        }
                    } catch (Exception ex) {
                        this.BeginInvoke((Action)(() => {
                            lblResult.Text = "FAILED: " + ex.Message;
                            lblResult.ForeColor = DarkTheme.AccentDanger;
                        }));
                    }
                });

                btnTest.Enabled = true;
            };

            this.Load += (s, e) => DarkTheme.ApplyDarkTitleBar(this);
        }
    }
}
