// HMTTools.cs - High-Performance Diagnostic & Visualization Engine - Tyler Hatfield - v1.0

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

namespace HMT.Tools {

    // ==============================================================================
    // 1. Smooth Double-Buffered GDI+ Line Graph Control
    // ==============================================================================
    public class SmoothGraphControl : Control {
        private readonly List<double> _points = new List<double>();
        private readonly object _lock = new object();
        private int _maxPoints = 60;
        private string _unitLabel = "ms";
        private Color _lineColor = Color.FromArgb(88, 101, 242);
        private Color _gridColor = Color.FromArgb(47, 49, 54);
        private Color _textColor = Color.FromArgb(217, 217, 217);
        private Color _subTextColor = Color.FromArgb(160, 160, 160);
        private double _fixedMax = 0;
        private bool _showMinMaxAvg = true;

        public SmoothGraphControl() {
            SetStyle(
                ControlStyles.OptimizedDoubleBuffer |
                ControlStyles.AllPaintingInWmPaint |
                ControlStyles.UserPaint |
                ControlStyles.ResizeRedraw,
                true
            );
            BackColor = Color.FromArgb(30, 31, 34);
            Font = new Font("Segoe UI", 9f, FontStyle.Regular, GraphicsUnit.Point);
        }

        public int MaxPoints {
            get { return _maxPoints; }
            set { _maxPoints = Math.Max(10, value); Invalidate(); }
        }

        public string UnitLabel {
            get { return _unitLabel; }
            set { _unitLabel = value ?? ""; Invalidate(); }
        }

        public Color LineColor {
            get { return _lineColor; }
            set { _lineColor = value; Invalidate(); }
        }

        public double FixedMax {
            get { return _fixedMax; }
            set { _fixedMax = Math.Max(0, value); Invalidate(); }
        }

        public bool ShowMinMaxAvg {
            get { return _showMinMaxAvg; }
            set { _showMinMaxAvg = value; Invalidate(); }
        }

        public double CurrentValue { get; private set; }
        public double MinValue { get; private set; }
        public double MaxValue { get; private set; }
        public double AvgValue { get; private set; }

        public void AddPoint(double value) {
            lock (_lock) {
                _points.Add(value);
                if (_points.Count > _maxPoints) {
                    _points.RemoveAt(0);
                }

                CurrentValue = value;
                double min = double.MaxValue;
                double max = double.MinValue;
                double sum = 0;

                for (int i = 0; i < _points.Count; i++) {
                    double v = _points[i];
                    if (v < min) min = v;
                    if (v > max) max = v;
                    sum += v;
                }

                MinValue = (_points.Count > 0) ? min : 0;
                MaxValue = (_points.Count > 0) ? max : 0;
                AvgValue = (_points.Count > 0) ? (sum / _points.Count) : 0;
            }

            if (IsHandleCreated) {
                if (InvokeRequired) {
                    BeginInvoke(new Action(Invalidate));
                } else {
                    Invalidate();
                }
            }
        }

        public void Clear() {
            lock (_lock) {
                _points.Clear();
                CurrentValue = 0;
                MinValue = 0;
                MaxValue = 0;
                AvgValue = 0;
            }
            if (IsHandleCreated) {
                if (InvokeRequired) {
                    BeginInvoke(new Action(Invalidate));
                } else {
                    Invalidate();
                }
            }
        }

        protected override void OnPaint(PaintEventArgs e) {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            int w = Width;
            int h = Height;
            if (w < 10 || h < 10) return;

            // Background fill
            using (var brush = new SolidBrush(BackColor)) {
                g.FillRectangle(brush, 0, 0, w, h);
            }

            // Margins
            int topMargin = 22;
            int bottomMargin = 22;
            int leftMargin = 45;
            int rightMargin = 15;

            int plotW = w - leftMargin - rightMargin;
            int plotH = h - topMargin - bottomMargin;
            if (plotW < 10 || plotH < 10) return;

            // Compute Y Scale
            double scaleMax = _fixedMax;
            if (scaleMax <= 0) {
                scaleMax = Math.Max(1.0, MaxValue * 1.15);
            }

            // Draw horizontal gridlines & Y axis labels
            using (var gridPen = new Pen(_gridColor, 1f) { DashStyle = DashStyle.Dash })
            using (var labelBrush = new SolidBrush(_subTextColor)) {
                int gridLines = 4;
                for (int i = 0; i <= gridLines; i++) {
                    float y = topMargin + (plotH * (float)i / gridLines);
                    g.DrawLine(gridPen, leftMargin, y, leftMargin + plotW, y);

                    double val = scaleMax * (1.0 - ((double)i / gridLines));
                    string lbl = (val >= 100) ? val.ToString("F0") : (val >= 10 ? val.ToString("F1") : val.ToString("F2"));
                    g.DrawString(lbl, Font, labelBrush, 4, y - 7);
                }
            }

            // Draw Border around plot area
            using (var borderPen = new Pen(_gridColor, 1f)) {
                g.DrawRectangle(borderPen, leftMargin, topMargin, plotW, plotH);
            }

            // Draw Data Line & Gradient Area Fill
            double[] pts;
            lock (_lock) {
                pts = _points.ToArray();
            }

            if (pts.Length > 1) {
                PointF[] linePoints = new PointF[pts.Length];
                for (int i = 0; i < pts.Length; i++) {
                    float x = leftMargin + (plotW * (float)i / (_maxPoints - 1));
                    float normY = (float)Math.Max(0.0, Math.Min(scaleMax, pts[i])) / (float)scaleMax;
                    float y = topMargin + plotH * (1.0f - normY);
                    linePoints[i] = new PointF(x, y);
                }

                // Fill gradient under the curve
                using (GraphicsPath fillPath = new GraphicsPath()) {
                    fillPath.AddLine(linePoints[0].X, topMargin + plotH, linePoints[0].X, linePoints[0].Y);
                    for (int i = 1; i < linePoints.Length; i++) {
                        fillPath.AddLine(linePoints[i - 1], linePoints[i]);
                    }
                    fillPath.AddLine(linePoints[linePoints.Length - 1].X, linePoints[linePoints.Length - 1].Y, linePoints[linePoints.Length - 1].X, topMargin + plotH);
                    fillPath.CloseFigure();

                    Color fillTop = Color.FromArgb(70, _lineColor);
                    Color fillBottom = Color.FromArgb(5, _lineColor);
                    using (LinearGradientBrush lgb = new LinearGradientBrush(
                        new PointF(0, topMargin),
                        new PointF(0, topMargin + plotH),
                        fillTop, fillBottom)) {
                        g.FillPath(lgb, fillPath);
                    }
                }

                // Draw line glow and main stroke
                using (Pen glowPen = new Pen(Color.FromArgb(50, _lineColor), 4f)) {
                    g.DrawLines(glowPen, linePoints);
                }
                using (Pen linePen = new Pen(_lineColor, 2f)) {
                    g.DrawLines(linePen, linePoints);
                }

                // Highlight latest point
                PointF lastPt = linePoints[linePoints.Length - 1];
                using (SolidBrush dotBrush = new SolidBrush(_lineColor))
                using (SolidBrush whiteBrush = new SolidBrush(Color.White)) {
                    g.FillEllipse(dotBrush, lastPt.X - 5, lastPt.Y - 5, 10, 10);
                    g.FillEllipse(whiteBrush, lastPt.X - 2.5f, lastPt.Y - 2.5f, 5, 5);
                }
            }

            // Top Status Badge (Current, Avg, Max, Min)
            if (_showMinMaxAvg && pts.Length > 0) {
                string statsText = string.Format(
                    "CUR: {0:F1} {4}   |   AVG: {1:F1} {4}   |   MAX: {2:F1} {4}   |   MIN: {3:F1} {4}",
                    CurrentValue, AvgValue, MaxValue, MinValue, _unitLabel
                );

                using (Font boldFont = new Font(Font.FontFamily, 9f, FontStyle.Bold))
                using (SolidBrush textBrush = new SolidBrush(_textColor)) {
                    SizeF size = g.MeasureString(statsText, boldFont);
                    g.DrawString(statsText, boldFont, textBrush, w - size.Width - 15, 4);
                }
            }
        }
    }

    // ==============================================================================
    // 2. High-Precision Asynchronous Ping Engine
    // ==============================================================================
    public class PingSample {
        public int Sequence { get; set; }
        public bool Success { get; set; }
        public double RttMs { get; set; }
        public IPStatus Status { get; set; }
        public string ErrorMessage { get; set; }
        public double JitterMs { get; set; }
        public DateTime Timestamp { get; set; }
    }

    public class PingSummary {
        public string Host { get; set; }
        public int TotalSent { get; set; }
        public int TotalReceived { get; set; }
        public int TotalLost { get; set; }
        public double LossPercent { get; set; }
        public double MinRttMs { get; set; }
        public double MaxRttMs { get; set; }
        public double AvgRttMs { get; set; }
        public double CurrentJitterMs { get; set; }
        public TimeSpan Elapsed { get; set; }
    }

    public class HighPrecisionPingEngine {
        private Thread _workerThread;
        private volatile bool _isRunning;
        private string _targetHost = "1.1.1.1";
        private int _pingsPerSecond = 5;
        private int _packetSize = 32;
        private int _durationSeconds = 0; // 0 = infinite

        private int _sentCount;
        private int _recvCount;
        private int _lostCount;
        private double _minRtt = double.MaxValue;
        private double _maxRtt = 0;
        private double _sumRtt = 0;
        private double _lastRtt = -1;
        private double _jitter = 0;
        private System.Diagnostics.Stopwatch _stopwatch;

        public event Action<PingSample> OnPingSample;
        public event Action<PingSummary> OnSummaryUpdate;
        public event Action<PingSummary> OnCompleted;

        public bool IsRunning { get { return _isRunning; } }

        public void Start(string host, int pingsPerSecond, int packetSize, int durationSeconds = 0) {
            if (_isRunning) Stop();

            _targetHost = host ?? "1.1.1.1";
            _pingsPerSecond = Math.Max(1, Math.Min(200, pingsPerSecond));
            _packetSize = Math.Max(1, Math.Min(65500, packetSize));
            _durationSeconds = Math.Max(0, durationSeconds);

            _sentCount = 0;
            _recvCount = 0;
            _lostCount = 0;
            _minRtt = double.MaxValue;
            _maxRtt = 0;
            _sumRtt = 0;
            _lastRtt = -1;
            _jitter = 0;
            _stopwatch = System.Diagnostics.Stopwatch.StartNew();

            _isRunning = true;
            _workerThread = new Thread(WorkerLoop) {
                IsBackground = true,
                Name = "HMT_HighPrecisionPingWorker"
            };
            _workerThread.Start();
        }

        public void Stop() {
            _isRunning = false;
            if (_workerThread != null && _workerThread.IsAlive) {
                _workerThread.Join(500);
            }
        }

        private void WorkerLoop() {
            byte[] buffer = new byte[_packetSize];
            new Random().NextBytes(buffer);
            var pingSender = new Ping();
            var pingOptions = new PingOptions(64, true);

            int intervalMs = Math.Max(5, (int)(1000.0 / _pingsPerSecond));
            int sequence = 0;

            while (_isRunning) {
                var loopStart = System.Diagnostics.Stopwatch.GetTimestamp();
                sequence++;
                _sentCount++;

                var sample = new PingSample {
                    Sequence = sequence,
                    Timestamp = DateTime.Now
                };

                try {
                    var sw = System.Diagnostics.Stopwatch.StartNew();
                    var reply = pingSender.Send(_targetHost, 1500, buffer, pingOptions);
                    sw.Stop();

                    if (reply != null && reply.Status == IPStatus.Success) {
                        sample.Success = true;
                        sample.RttMs = (reply.RoundtripTime > 0) ? reply.RoundtripTime : sw.Elapsed.TotalMilliseconds;
                        sample.Status = reply.Status;

                        _recvCount++;
                        if (sample.RttMs < _minRtt) _minRtt = sample.RttMs;
                        if (sample.RttMs > _maxRtt) _maxRtt = sample.RttMs;
                        _sumRtt += sample.RttMs;

                        // RFC 3550 Jitter Calculation
                        if (_lastRtt >= 0) {
                            double d = Math.Abs(sample.RttMs - _lastRtt);
                            _jitter += (d - _jitter) / 16.0;
                        }
                        _lastRtt = sample.RttMs;
                        sample.JitterMs = _jitter;
                    } else {
                        sample.Success = false;
                        sample.Status = (reply != null) ? reply.Status : IPStatus.TimedOut;
                        sample.ErrorMessage = sample.Status.ToString();
                        _lostCount++;
                    }
                } catch (Exception ex) {
                    sample.Success = false;
                    sample.Status = IPStatus.Unknown;
                    sample.ErrorMessage = ex.Message;
                    _lostCount++;
                }

                sample.JitterMs = _jitter;
                if (OnPingSample != null) {
                    try { OnPingSample(sample); } catch { }
                }

                if (OnSummaryUpdate != null && sequence % Math.Max(1, _pingsPerSecond / 2) == 0) {
                    try { OnSummaryUpdate(GetSummary()); } catch { }
                }

                if (_durationSeconds > 0 && _stopwatch.Elapsed.TotalSeconds >= _durationSeconds) {
                    break;
                }

                // High precision sleep
                var elapsedMs = (System.Diagnostics.Stopwatch.GetTimestamp() - loopStart) * 1000.0 / System.Diagnostics.Stopwatch.Frequency;
                int sleepTime = Math.Max(0, (int)(intervalMs - elapsedMs));
                if (sleepTime > 0) {
                    Thread.Sleep(sleepTime);
                }
            }

            _isRunning = false;
            if (OnCompleted != null) {
                try { OnCompleted(GetSummary()); } catch { }
            }
        }

        public PingSummary GetSummary() {
            double lossPct = (_sentCount > 0) ? ((double)_lostCount / _sentCount * 100.0) : 0;
            double avg = (_recvCount > 0) ? (_sumRtt / _recvCount) : 0;
            return new PingSummary {
                Host = _targetHost,
                TotalSent = _sentCount,
                TotalReceived = _recvCount,
                TotalLost = _lostCount,
                LossPercent = lossPct,
                MinRttMs = (_minRtt == double.MaxValue) ? 0 : _minRtt,
                MaxRttMs = _maxRtt,
                AvgRttMs = avg,
                CurrentJitterMs = _jitter,
                Elapsed = (_stopwatch != null) ? _stopwatch.Elapsed : TimeSpan.Zero
            };
        }
    }

    // ==============================================================================
    // 3. Fast Multi-Stream HTTP Speed Test Engine
    // ==============================================================================
    public class SpeedSample {
        public double CurrentMbps { get; set; }
        public double AverageMbps { get; set; }
        public long TotalBytesTransferred { get; set; }
        public double ElapsedSeconds { get; set; }
        public string Phase { get; set; }
        public bool IsFinished { get; set; }
    }

    public class FastSpeedTestEngine {
        private volatile bool _cancelled;

        public event Action<SpeedSample> OnSpeedSample;

        public void Cancel() {
            _cancelled = true;
        }

        public SpeedSample RunDownloadTest(string url, int streams, int durationSeconds) {
            _cancelled = false;
            streams = Math.Max(1, Math.Min(16, streams));
            durationSeconds = Math.Max(2, Math.Min(30, durationSeconds));

            long totalBytes = 0;
            long lastSampleBytes = 0;
            var sw = System.Diagnostics.Stopwatch.StartNew();
            var lastSampleTime = sw.Elapsed.TotalSeconds;

            Thread[] workers = new Thread[streams];
            for (int i = 0; i < streams; i++) {
                workers[i] = new Thread(() => {
                    byte[] buffer = new byte[65536];
                    while (!_cancelled && sw.Elapsed.TotalSeconds < durationSeconds) {
                        try {
                            string reqUrl = url + "?r=" + Guid.NewGuid().ToString("N");
                            var req = (HttpWebRequest)WebRequest.Create(reqUrl);
                            req.Method = "GET";
                            req.Timeout = 5000;
                            req.ReadWriteTimeout = 5000;
                            req.UserAgent = "HMT-SpeedTest/2.0";

                            using (var resp = req.GetResponse())
                            using (var stream = resp.GetResponseStream()) {
                                int read;
                                while (!_cancelled && sw.Elapsed.TotalSeconds < durationSeconds &&
                                       (read = stream.Read(buffer, 0, buffer.Length)) > 0) {
                                    Interlocked.Add(ref totalBytes, read);
                                }
                            }
                        } catch {
                            if (_cancelled) break;
                            Thread.Sleep(50);
                        }
                    }
                }) { IsBackground = true };
                workers[i].Start();
            }

            while (!_cancelled && sw.Elapsed.TotalSeconds < durationSeconds) {
                Thread.Sleep(100);
                double currentElapsed = sw.Elapsed.TotalSeconds;
                double deltaT = currentElapsed - lastSampleTime;
                long curTotal = Interlocked.Read(ref totalBytes);
                long deltaBytes = curTotal - lastSampleBytes;

                if (deltaT > 0.05) {
                    double currentMbps = (deltaBytes * 8.0) / (deltaT * 1000000.0);
                    double avgMbps = (curTotal * 8.0) / (currentElapsed * 1000000.0);

                    lastSampleBytes = curTotal;
                    lastSampleTime = currentElapsed;

                    var sample = new SpeedSample {
                        CurrentMbps = currentMbps,
                        AverageMbps = avgMbps,
                        TotalBytesTransferred = curTotal,
                        ElapsedSeconds = currentElapsed,
                        Phase = "Download",
                        IsFinished = false
                    };
                    if (OnSpeedSample != null) {
                        try { OnSpeedSample(sample); } catch { }
                    }
                }
            }

            _cancelled = true;
            for (int i = 0; i < streams; i++) {
                workers[i].Join(300);
            }
            sw.Stop();

            double finalAvg = (totalBytes * 8.0) / (Math.Max(0.1, sw.Elapsed.TotalSeconds) * 1000000.0);
            var finalSample = new SpeedSample {
                CurrentMbps = finalAvg,
                AverageMbps = finalAvg,
                TotalBytesTransferred = totalBytes,
                ElapsedSeconds = sw.Elapsed.TotalSeconds,
                Phase = "Download",
                IsFinished = true
            };
            if (OnSpeedSample != null) {
                try { OnSpeedSample(finalSample); } catch { }
            }
            return finalSample;
        }

        public SpeedSample RunUploadTest(string url, int streams, int durationSeconds) {
            _cancelled = false;
            streams = Math.Max(1, Math.Min(16, streams));
            durationSeconds = Math.Max(2, Math.Min(30, durationSeconds));

            long totalBytes = 0;
            long lastSampleBytes = 0;
            var sw = System.Diagnostics.Stopwatch.StartNew();
            var lastSampleTime = sw.Elapsed.TotalSeconds;

            byte[] uploadPayload = new byte[1048576]; // 1MB payload
            new Random().NextBytes(uploadPayload);

            Thread[] workers = new Thread[streams];
            for (int i = 0; i < streams; i++) {
                workers[i] = new Thread(() => {
                    while (!_cancelled && sw.Elapsed.TotalSeconds < durationSeconds) {
                        try {
                            string reqUrl = url + "?r=" + Guid.NewGuid().ToString("N");
                            var req = (HttpWebRequest)WebRequest.Create(reqUrl);
                            req.Method = "POST";
                            req.ContentType = "application/octet-stream";
                            req.ContentLength = uploadPayload.Length;
                            req.Timeout = 5000;
                            req.ReadWriteTimeout = 5000;
                            req.UserAgent = "HMT-SpeedTest/2.0";

                            using (var reqStream = req.GetRequestStream()) {
                                int offset = 0;
                                int chunkSize = 32768;
                                while (!_cancelled && sw.Elapsed.TotalSeconds < durationSeconds && offset < uploadPayload.Length) {
                                    int count = Math.Min(chunkSize, uploadPayload.Length - offset);
                                    reqStream.Write(uploadPayload, offset, count);
                                    offset += count;
                                    Interlocked.Add(ref totalBytes, count);
                                }
                            }
                            using (var resp = req.GetResponse()) { }
                        } catch {
                            if (_cancelled) break;
                            Thread.Sleep(50);
                        }
                    }
                }) { IsBackground = true };
                workers[i].Start();
            }

            while (!_cancelled && sw.Elapsed.TotalSeconds < durationSeconds) {
                Thread.Sleep(100);
                double currentElapsed = sw.Elapsed.TotalSeconds;
                double deltaT = currentElapsed - lastSampleTime;
                long curTotal = Interlocked.Read(ref totalBytes);
                long deltaBytes = curTotal - lastSampleBytes;

                if (deltaT > 0.05) {
                    double currentMbps = (deltaBytes * 8.0) / (deltaT * 1000000.0);
                    double avgMbps = (curTotal * 8.0) / (currentElapsed * 1000000.0);

                    lastSampleBytes = curTotal;
                    lastSampleTime = currentElapsed;

                    var sample = new SpeedSample {
                        CurrentMbps = currentMbps,
                        AverageMbps = avgMbps,
                        TotalBytesTransferred = curTotal,
                        ElapsedSeconds = currentElapsed,
                        Phase = "Upload",
                        IsFinished = false
                    };
                    if (OnSpeedSample != null) {
                        try { OnSpeedSample(sample); } catch { }
                    }
                }
            }

            _cancelled = true;
            for (int i = 0; i < streams; i++) {
                workers[i].Join(300);
            }
            sw.Stop();

            double finalAvg = (totalBytes * 8.0) / (Math.Max(0.1, sw.Elapsed.TotalSeconds) * 1000000.0);
            var finalSample = new SpeedSample {
                CurrentMbps = finalAvg,
                AverageMbps = finalAvg,
                TotalBytesTransferred = totalBytes,
                ElapsedSeconds = sw.Elapsed.TotalSeconds,
                Phase = "Upload",
                IsFinished = true
            };
            if (OnSpeedSample != null) {
                try { OnSpeedSample(finalSample); } catch { }
            }
            return finalSample;
        }
    }

    // ==============================================================================
    // 4. Disk Benchmark Performance Engine (Sequential & Random 4K)
    // ==============================================================================
    public class BenchmarkProgress {
        public string CurrentTest { get; set; }
        public double ProgressPercent { get; set; }
        public double CurrentSpeedMBs { get; set; }
        public double CurrentIops { get; set; }
    }

    public class BenchmarkResult {
        public string TargetPath { get; set; }
        public long FileSizeBytes { get; set; }
        public double SeqReadMBs { get; set; }
        public double SeqWriteMBs { get; set; }
        public double Rand4KReadMBs { get; set; }
        public double Rand4KReadIops { get; set; }
        public double Rand4KWriteMBs { get; set; }
        public double Rand4KWriteIops { get; set; }
        public bool Success { get; set; }
        public string ErrorMessage { get; set; }
    }

    public class DiskBenchmarkEngine {
        private volatile bool _cancelled;

        public event Action<BenchmarkProgress> OnProgress;

        public void Cancel() {
            _cancelled = true;
        }

        public BenchmarkResult RunBenchmark(string directoryPath, long fileSizeMb = 250) {
            _cancelled = false;
            var result = new BenchmarkResult {
                TargetPath = directoryPath,
                FileSizeBytes = fileSizeMb * 1024 * 1024,
                Success = false
            };

            string testFilePath = Path.Combine(directoryPath, ".hmt_bench_" + Guid.NewGuid().ToString("N") + ".tmp");
            byte[] block128k = new byte[131072]; // 128 KB
            byte[] block4k = new byte[4096];     // 4 KB
            new Random().NextBytes(block128k);
            new Random().NextBytes(block4k);

            try {
                // --- 1. Sequential Write Test ---
                ReportProgress("Sequential Write (128 KB)", 0, 0, 0);
                long bytesWritten = 0;
                var sw = System.Diagnostics.Stopwatch.StartNew();

                using (var fs = new FileStream(testFilePath, FileMode.Create, FileAccess.Write, FileShare.None, 131072, FileOptions.WriteThrough)) {
                    while (!_cancelled && bytesWritten < result.FileSizeBytes) {
                        int toWrite = (int)Math.Min(block128k.Length, result.FileSizeBytes - bytesWritten);
                        fs.Write(block128k, 0, toWrite);
                        bytesWritten += toWrite;

                        double sec = sw.Elapsed.TotalSeconds;
                        if (sec > 0.05) {
                            double curMBs = (bytesWritten / (1024.0 * 1024.0)) / sec;
                            double pct = (double)bytesWritten / result.FileSizeBytes * 25.0;
                            ReportProgress("Sequential Write (128 KB)", pct, curMBs, 0);
                        }
                    }
                    fs.Flush();
                }
                sw.Stop();
                result.SeqWriteMBs = (result.FileSizeBytes / (1024.0 * 1024.0)) / Math.Max(0.001, sw.Elapsed.TotalSeconds);
                if (_cancelled) return result;

                // --- 2. Sequential Read Test ---
                ReportProgress("Sequential Read (128 KB)", 25, 0, 0);
                long bytesRead = 0;
                sw.Restart();

                using (var fs = new FileStream(testFilePath, FileMode.Open, FileAccess.Read, FileShare.None, 131072, FileOptions.None)) {
                    byte[] readBuffer = new byte[131072];
                    int r;
                    while (!_cancelled && (r = fs.Read(readBuffer, 0, readBuffer.Length)) > 0) {
                        bytesRead += r;
                        double sec = sw.Elapsed.TotalSeconds;
                        if (sec > 0.05) {
                            double curMBs = (bytesRead / (1024.0 * 1024.0)) / sec;
                            double pct = 25.0 + ((double)bytesRead / result.FileSizeBytes * 25.0);
                            ReportProgress("Sequential Read (128 KB)", pct, curMBs, 0);
                        }
                    }
                }
                sw.Stop();
                result.SeqReadMBs = (result.FileSizeBytes / (1024.0 * 1024.0)) / Math.Max(0.001, sw.Elapsed.TotalSeconds);
                if (_cancelled) return result;

                // --- 3. Random 4K Read Test ---
                ReportProgress("Random 4K Read", 50, 0, 0);
                int randomOps = (int)Math.Min(10000, (result.FileSizeBytes / 4096));
                long maxOffset = result.FileSizeBytes - 4096;
                Random rnd = new Random();
                sw.Restart();

                using (var fs = new FileStream(testFilePath, FileMode.Open, FileAccess.Read, FileShare.None, 4096, FileOptions.None)) {
                    byte[] r4kBuf = new byte[4096];
                    for (int i = 0; i < randomOps && !_cancelled; i++) {
                        long offset = (long)(rnd.NextDouble() * maxOffset) & ~4095;
                        fs.Seek(offset, SeekOrigin.Begin);
                        fs.Read(r4kBuf, 0, 4096);

                        if (i % 200 == 0) {
                            double sec = sw.Elapsed.TotalSeconds;
                            if (sec > 0.05) {
                                double iops = i / sec;
                                double mbSec = (i * 4096.0 / (1024.0 * 1024.0)) / sec;
                                double pct = 50.0 + ((double)i / randomOps * 25.0);
                                ReportProgress("Random 4K Read", pct, mbSec, iops);
                            }
                        }
                    }
                }
                sw.Stop();
                result.Rand4KReadIops = randomOps / Math.Max(0.001, sw.Elapsed.TotalSeconds);
                result.Rand4KReadMBs = (randomOps * 4096.0 / (1024.0 * 1024.0)) / Math.Max(0.001, sw.Elapsed.TotalSeconds);
                if (_cancelled) return result;

                // --- 4. Random 4K Write Test ---
                ReportProgress("Random 4K Write", 75, 0, 0);
                sw.Restart();

                using (var fs = new FileStream(testFilePath, FileMode.Open, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough)) {
                    for (int i = 0; i < randomOps && !_cancelled; i++) {
                        long offset = (long)(rnd.NextDouble() * maxOffset) & ~4095;
                        fs.Seek(offset, SeekOrigin.Begin);
                        fs.Write(block4k, 0, 4096);

                        if (i % 200 == 0) {
                            double sec = sw.Elapsed.TotalSeconds;
                            if (sec > 0.05) {
                                double iops = i / sec;
                                double mbSec = (i * 4096.0 / (1024.0 * 1024.0)) / sec;
                                double pct = 75.0 + ((double)i / randomOps * 25.0);
                                ReportProgress("Random 4K Write", pct, mbSec, iops);
                            }
                        }
                    }
                    fs.Flush();
                }
                sw.Stop();
                result.Rand4KWriteIops = randomOps / Math.Max(0.001, sw.Elapsed.TotalSeconds);
                result.Rand4KWriteMBs = (randomOps * 4096.0 / (1024.0 * 1024.0)) / Math.Max(0.001, sw.Elapsed.TotalSeconds);

                result.Success = true;
                ReportProgress("Benchmark Complete", 100, result.SeqReadMBs, 0);

            } catch (Exception ex) {
                result.ErrorMessage = ex.Message;
                result.Success = false;
            } finally {
                if (File.Exists(testFilePath)) {
                    try { File.Delete(testFilePath); } catch { }
                }
            }

            return result;
        }

        private void ReportProgress(string test, double pct, double mbSec, double iops) {
            if (OnProgress != null) {
                try {
                    OnProgress(new BenchmarkProgress {
                        CurrentTest = test,
                        ProgressPercent = pct,
                        CurrentSpeedMBs = mbSec,
                        CurrentIops = iops
                    });
                } catch { }
            }
        }
    }
}
