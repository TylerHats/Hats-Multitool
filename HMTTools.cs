// HMTTools.cs - High-Performance Diagnostic & Visualization Engine - Tyler Hatfield - v1.0

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;

namespace HMT.Tools {

    // ==============================================================================
    // 1. Smooth Double-Buffered GDI+ Line Graph Control
    // ==============================================================================
    public struct GraphPoint {
        public double Value;
        public Color PointColor;
        public bool HasCustomColor;

        public GraphPoint(double value) {
            Value = value;
            PointColor = Color.Empty;
            HasCustomColor = false;
        }

        public GraphPoint(double value, Color color) {
            Value = value;
            PointColor = color;
            HasCustomColor = true;
        }
    }

    public class SmoothGraphControl : Control {
        private readonly List<GraphPoint> _points = new List<GraphPoint>();
        private readonly object _lock = new object();
        private int _maxPoints = 60;
        private string _unitLabel = "ms";
        private Color _lineColor = Color.FromArgb(88, 101, 242);
        private Color _gridColor = Color.FromArgb(47, 49, 54);
        private Color _textColor = Color.FromArgb(217, 217, 217);
        private Color _subTextColor = Color.FromArgb(160, 160, 160);
        private double _fixedMax = 0;
        private bool _showMinMaxAvg = true;
        private bool _enableSmoothing = false;
        private double _smoothWeight = 0.18;
        private double _lastSmoothedValue = double.NaN;

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

        public bool EnableSmoothing {
            get { return _enableSmoothing; }
            set { _enableSmoothing = value; Invalidate(); }
        }

        public double SmoothWeight {
            get { return _smoothWeight; }
            set { _smoothWeight = Math.Max(0.05, Math.Min(1.0, value)); }
        }

        public double CurrentValue { get; private set; }
        public double MinValue { get; private set; }
        public double MaxValue { get; private set; }
        public double AvgValue { get; private set; }

        public void AddPoint(double value) {
            AddPoint(value, Color.Empty);
        }

        public void AddPoint(double value, Color customColor) {
            double valToRecord = value;
            if (_enableSmoothing) {
                if (double.IsNaN(_lastSmoothedValue) || _points.Count == 0) {
                    _lastSmoothedValue = value;
                } else {
                    _lastSmoothedValue = (_smoothWeight * value) + ((1.0 - _smoothWeight) * _lastSmoothedValue);
                }
                valToRecord = _lastSmoothedValue;
            }

            lock (_lock) {
                if (customColor.IsEmpty) {
                    _points.Add(new GraphPoint(valToRecord));
                } else {
                    _points.Add(new GraphPoint(valToRecord, customColor));
                }

                if (_points.Count > _maxPoints) {
                    _points.RemoveAt(0);
                }

                CurrentValue = value;
                double min = double.MaxValue;
                double max = double.MinValue;
                double sum = 0;

                for (int i = 0; i < _points.Count; i++) {
                    double v = _points[i].Value;
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
                _lastSmoothedValue = double.NaN;
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

        private bool _useDynamicLatencyColors = false;

        public bool UseDynamicLatencyColors {
            get { return _useDynamicLatencyColors; }
            set { _useDynamicLatencyColors = value; Invalidate(); }
        }

        public static Color GetLatencyColor(double ms) {
            if (ms <= 25.0) {
                return Color.FromArgb(87, 242, 135); // #57F287 Pure Green
            } else if (ms <= 50.0) {
                float t = (float)((ms - 25.0) / 25.0);
                return InterpolateColor(Color.FromArgb(87, 242, 135), Color.FromArgb(254, 231, 92), t); // Green -> Yellow #FEE75C
            } else if (ms <= 75.0) {
                float t = (float)((ms - 50.0) / 25.0);
                return InterpolateColor(Color.FromArgb(254, 231, 92), Color.FromArgb(230, 126, 34), t); // Yellow -> Orange #E67E22
            } else if (ms <= 100.0) {
                float t = (float)((ms - 75.0) / 25.0);
                return InterpolateColor(Color.FromArgb(230, 126, 34), Color.FromArgb(237, 66, 69), t); // Orange -> Red #ED4245
            } else {
                return Color.FromArgb(237, 66, 69); // #ED4245 Pure Red
            }
        }

        private static Color InterpolateColor(Color c1, Color c2, float t) {
            t = Math.Max(0f, Math.Min(1f, t));
            int r = (int)(c1.R + (c2.R - c1.R) * t);
            int g = (int)(c1.G + (c2.G - c1.G) * t);
            int b = (int)(c1.B + (c2.B - c1.B) * t);
            return Color.FromArgb(r, g, b);
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
            GraphPoint[] pts;
            lock (_lock) {
                pts = _points.ToArray();
            }

            if (pts.Length > 1) {
                int totalPoints = pts.Length;
                PointF[] linePoints;
                Color[] pointColors;

                // For very high point counts (e.g. 60,000 at 1000 pps), downsample into plotW pixel columns for max 60fps performance
                if (totalPoints > plotW * 2) {
                    List<PointF> sampledPoints = new List<PointF>(plotW * 2);
                    List<Color> sampledColors = new List<Color>(plotW * 2);
                    float pointsPerPixel = (float)totalPoints / plotW;

                    for (int xCol = 0; xCol < plotW; xCol++) {
                        int startIdx = (int)(xCol * pointsPerPixel);
                        int endIdx = Math.Min(totalPoints, (int)((xCol + 1) * pointsPerPixel));
                        if (startIdx >= endIdx) continue;

                        double minVal = double.MaxValue;
                        double maxVal = double.MinValue;
                        GraphPoint lastPt = pts[endIdx - 1];

                        for (int k = startIdx; k < endIdx; k++) {
                            if (pts[k].Value < minVal) minVal = pts[k].Value;
                            if (pts[k].Value > maxVal) maxVal = pts[k].Value;
                        }

                        float xPos = leftMargin + xCol;
                        float yMax = topMargin + plotH * (1.0f - (float)Math.Max(0.0, Math.Min(scaleMax, maxVal)) / (float)scaleMax);
                        float yMin = topMargin + plotH * (1.0f - (float)Math.Max(0.0, Math.Min(scaleMax, minVal)) / (float)scaleMax);

                        Color c = _useDynamicLatencyColors ? GetLatencyColor(lastPt.Value) : (lastPt.HasCustomColor ? lastPt.PointColor : _lineColor);

                        sampledPoints.Add(new PointF(xPos, yMax));
                        sampledColors.Add(c);
                        if (Math.Abs(yMin - yMax) > 1f) {
                            sampledPoints.Add(new PointF(xPos, yMin));
                            sampledColors.Add(c);
                        }
                    }
                    linePoints = sampledPoints.ToArray();
                    pointColors = sampledColors.ToArray();
                } else {
                    linePoints = new PointF[totalPoints];
                    pointColors = new Color[totalPoints];
                    for (int i = 0; i < totalPoints; i++) {
                        float x = leftMargin + (plotW * (float)i / Math.Max(1, totalPoints - 1));
                        float normY = (float)Math.Max(0.0, Math.Min(scaleMax, pts[i].Value)) / (float)scaleMax;
                        float y = topMargin + plotH * (1.0f - normY);
                        linePoints[i] = new PointF(x, y);
                        pointColors[i] = _useDynamicLatencyColors ? GetLatencyColor(pts[i].Value) : (pts[i].HasCustomColor ? pts[i].PointColor : _lineColor);
                    }
                }

                if (linePoints.Length > 1) {
                    // Fill gradient under the curve
                    using (GraphicsPath fillPath = new GraphicsPath()) {
                        fillPath.AddLine(linePoints[0].X, topMargin + plotH, linePoints[0].X, linePoints[0].Y);
                        if (_enableSmoothing && linePoints.Length >= 3) {
                            fillPath.AddCurve(linePoints, 0.35f);
                        } else {
                            for (int i = 1; i < linePoints.Length; i++) {
                                fillPath.AddLine(linePoints[i - 1], linePoints[i]);
                            }
                        }
                        fillPath.AddLine(linePoints[linePoints.Length - 1].X, linePoints[linePoints.Length - 1].Y, linePoints[linePoints.Length - 1].X, topMargin + plotH);
                        fillPath.CloseFigure();

                        using (LinearGradientBrush lgb = new LinearGradientBrush(
                            new PointF(0, topMargin),
                            new PointF(0, topMargin + plotH),
                            Color.White, Color.Black)) {

                            if (_useDynamicLatencyColors) {
                                int stopCount = 20;
                                ColorBlend cb = new ColorBlend(stopCount);
                                for (int s = 0; s < stopCount; s++) {
                                    float pos = (float)s / (stopCount - 1);
                                    double latAtPos = scaleMax * (1.0 - pos);
                                    Color latCol = GetLatencyColor(latAtPos);
                                    int alpha = (int)(10 + (70 * (1.0f - pos)));
                                    cb.Colors[s] = Color.FromArgb(alpha, latCol);
                                    cb.Positions[s] = pos;
                                }
                                lgb.InterpolationColors = cb;
                            } else {
                                Color primary = (pointColors.Length > 0) ? pointColors[pointColors.Length - 1] : _lineColor;
                                Color fillTop = Color.FromArgb(70, primary);
                                Color fillBottom = Color.FromArgb(5, primary);
                                lgb.LinearColors = new Color[] { fillTop, fillBottom };
                            }

                            g.FillPath(lgb, fillPath);
                        }
                    }

                    // Draw line segments / spline curves and glow
                    Color primaryCol = (pointColors.Length > 0) ? pointColors[pointColors.Length - 1] : _lineColor;
                    if (_enableSmoothing && linePoints.Length >= 3 && !_useDynamicLatencyColors) {
                        using (Pen glowPen = new Pen(Color.FromArgb(45, primaryCol), 4f)) {
                            g.DrawCurve(glowPen, linePoints, 0.35f);
                        }
                        using (Pen linePen = new Pen(primaryCol, 2f)) {
                            g.DrawCurve(linePen, linePoints, 0.35f);
                        }
                    } else {
                        for (int i = 1; i < linePoints.Length; i++) {
                            Color segCol = pointColors[i];
                            using (Pen glowPen = new Pen(Color.FromArgb(45, segCol), 4f)) {
                                g.DrawLine(glowPen, linePoints[i - 1], linePoints[i]);
                            }
                            using (Pen linePen = new Pen(segCol, 2f)) {
                                g.DrawLine(linePen, linePoints[i - 1], linePoints[i]);
                            }
                        }
                    }

                    // Highlight latest point
                    PointF lastPt = linePoints[linePoints.Length - 1];
                    Color latestCol = pointColors[pointColors.Length - 1];
                    using (SolidBrush dotBrush = new SolidBrush(latestCol))
                    using (SolidBrush whiteBrush = new SolidBrush(Color.White)) {
                        g.FillEllipse(dotBrush, lastPt.X - 5, lastPt.Y - 5, 10, 10);
                        g.FillEllipse(whiteBrush, lastPt.X - 2.5f, lastPt.Y - 2.5f, 5, 5);
                    }
                }
            }

            // Top Status Badge (Current, Avg, Max, Min)
            if (_showMinMaxAvg && pts.Length > 0) {
                string statsText = string.Format(
                    "CUR: {0:F1} {4}  |  AVG: {1:F1} {4}  |  MAX: {2:F1} {4}  |  MIN: {3:F1} {4}",
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
    // Smooth Rounded & Animated Modern Progress Bar Control
    // ==============================================================================
    public class SmoothProgressBar : Control {
        private int _value = 0;
        private int _maximum = 100;
        private int _minimum = 0;
        private int _borderRadius = 5;
        private Color _progressColor = Color.FromArgb(111, 31, 222);       // #6f1fde
        private Color _progressColorEnd = Color.FromArgb(88, 101, 242);    // #5865F2
        private Color _trackColor = Color.FromArgb(32, 34, 37);           // #202225
        private Color _borderColor = Color.FromArgb(63, 65, 71);          // #3f4147
        private bool _isMarquee = false;
        private bool _showShimmer = true;
        private float _shimmerPos = -0.5f;
        private float _shimmerPixelOffset = -55f;
        private System.Windows.Forms.Timer _animTimer;
        private float _visualPercent = 0f;

        public SmoothProgressBar() {
            SetStyle(
                ControlStyles.OptimizedDoubleBuffer |
                ControlStyles.AllPaintingInWmPaint |
                ControlStyles.UserPaint |
                ControlStyles.ResizeRedraw |
                ControlStyles.SupportsTransparentBackColor,
                true
            );
            Size = new Size(300, 20);
            BackColor = Color.Transparent;

            _animTimer = new System.Windows.Forms.Timer();
            _animTimer.Interval = 25; // ~40 FPS smooth animation
            _animTimer.Tick += (s, e) => {
                bool needsRedraw = false;

                if (_isMarquee) {
                    _shimmerPos += 0.03f;
                    if (_shimmerPos > 1.4f) {
                        _shimmerPos = -0.4f;
                    }
                    needsRedraw = true;
                } else {
                    float targetPercent = (float)(_value - _minimum) / Math.Max(1, (_maximum - _minimum));
                    targetPercent = Math.Max(0f, Math.Min(1f, targetPercent));

                    if (targetPercent >= 0.999f || _value >= _maximum) {
                        if (_visualPercent < 1f) {
                            _visualPercent = 1f;
                            needsRedraw = true;
                        }
                    } else if (targetPercent <= 0.001f || _value <= _minimum) {
                        if (_visualPercent > 0f) {
                            _visualPercent = 0f;
                            needsRedraw = true;
                        }
                    } else if (Math.Abs(_visualPercent - targetPercent) > 0.005f) {
                        _visualPercent += (targetPercent - _visualPercent) * 0.25f;
                        needsRedraw = true;
                    } else {
                        _visualPercent = targetPercent;
                    }

                    if (_showShimmer && _visualPercent > 0.01f && _visualPercent < 0.999f) {
                        int fillWidth = (int)((ClientSize.Width - 1) * _visualPercent);
                        const int shimmerWidth = 55;
                        _shimmerPixelOffset += 3.5f; // Constant smooth travel speed (~140 px/sec)
                        if (_shimmerPixelOffset > fillWidth + shimmerWidth) {
                            _shimmerPixelOffset = -shimmerWidth;
                        }
                        needsRedraw = true;
                    }
                }

                if (needsRedraw) {
                    Invalidate();
                }
            };
            _animTimer.Start();
        }

        protected override void Dispose(bool disposing) {
            if (disposing && _animTimer != null) {
                _animTimer.Stop();
                _animTimer.Dispose();
                _animTimer = null;
            }
            base.Dispose(disposing);
        }

        public int Value {
            get { return _value; }
            set {
                _value = Math.Max(_minimum, Math.Min(_maximum, value));
                if (_value >= _maximum) {
                    _visualPercent = 1f;
                } else if (_value <= _minimum) {
                    _visualPercent = 0f;
                } else if (!IsHandleCreated) {
                    _visualPercent = (float)(_value - _minimum) / Math.Max(1, (_maximum - _minimum));
                }
                Invalidate();
            }
        }

        public int Minimum {
            get { return _minimum; }
            set { _minimum = value; Invalidate(); }
        }

        public int Maximum {
            get { return _maximum; }
            set { _maximum = Math.Max(_minimum + 1, value); Invalidate(); }
        }

        public int BorderRadius {
            get { return _borderRadius; }
            set { _borderRadius = Math.Max(0, value); Invalidate(); }
        }

        public Color ProgressColor {
            get { return _progressColor; }
            set { _progressColor = value; Invalidate(); }
        }

        public Color ProgressColorEnd {
            get { return _progressColorEnd; }
            set { _progressColorEnd = value; Invalidate(); }
        }

        public Color TrackColor {
            get { return _trackColor; }
            set { _trackColor = value; Invalidate(); }
        }

        public Color BorderColor {
            get { return _borderColor; }
            set { _borderColor = value; Invalidate(); }
        }

        public bool IsMarquee {
            get { return _isMarquee; }
            set { _isMarquee = value; Invalidate(); }
        }

        public bool ShowShimmer {
            get { return _showShimmer; }
            set { _showShimmer = value; Invalidate(); }
        }

        public ProgressBarStyle Style {
            get { return _isMarquee ? ProgressBarStyle.Marquee : ProgressBarStyle.Blocks; }
            set { _isMarquee = (value == ProgressBarStyle.Marquee); Invalidate(); }
        }

        public int MarqueeAnimationSpeed {
            get { return _animTimer != null ? _animTimer.Interval : 0; }
            set {
                if (_animTimer != null && value > 0) {
                    _animTimer.Interval = Math.Max(10, Math.Min(100, value));
                }
            }
        }

        protected override void OnPaint(PaintEventArgs e) {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;

            int w = ClientSize.Width;
            int h = ClientSize.Height;
            if (w < 4 || h < 4) return;

            Rectangle rect = new Rectangle(0, 0, w - 1, h - 1);
            int r = Math.Min(_borderRadius, h / 2);

            using (GraphicsPath trackPath = CreateRoundedRectanglePath(rect, r)) {
                using (SolidBrush trackBrush = new SolidBrush(_trackColor)) {
                    g.FillPath(trackBrush, trackPath);
                }

                if (_isMarquee) {
                    g.SetClip(trackPath);
                    int pulseWidth = Math.Max(60, (int)(w * 0.45f));
                    int pulseX = (int)((w + pulseWidth) * _shimmerPos) - pulseWidth;
                    Rectangle pulseRect = new Rectangle(pulseX, rect.Y, pulseWidth, rect.Height);

                    using (LinearGradientBrush pulseBrush = new LinearGradientBrush(
                        pulseRect,
                        _progressColor,
                        _progressColorEnd,
                        LinearGradientMode.Horizontal)) {
                        
                        ColorBlend cb = new ColorBlend(3);
                        cb.Colors = new Color[] {
                            Color.FromArgb(0, _progressColor.R, _progressColor.G, _progressColor.B),
                            _progressColorEnd,
                            Color.FromArgb(0, _progressColor.R, _progressColor.G, _progressColor.B)
                        };
                        cb.Positions = new float[] { 0f, 0.5f, 1f };
                        pulseBrush.InterpolationColors = cb;

                        g.FillRectangle(pulseBrush, pulseRect);
                    }
                    g.ResetClip();
                } else {
                    int fillWidth;
                    if (_visualPercent >= 0.999f || _value >= _maximum) {
                        fillWidth = rect.Width + 4;
                    } else {
                        fillWidth = (int)(rect.Width * _visualPercent);
                    }

                    if (fillWidth > 2) {
                        Rectangle fillRect = new Rectangle(rect.X, rect.Y, fillWidth, rect.Height);

                        // Strictly clip to the intersection of the track's rounded boundary AND the filled region
                        g.SetClip(trackPath);
                        if (_visualPercent < 0.999f && _value < _maximum) {
                            g.SetClip(fillRect, CombineMode.Intersect);
                        }

                        using (LinearGradientBrush fillBrush = new LinearGradientBrush(
                            rect, _progressColor, _progressColorEnd, LinearGradientMode.Horizontal)) {
                            g.FillRectangle(fillBrush, fillRect);
                        }

                        if (_showShimmer && _visualPercent < 0.999f) {
                            const int shimmerWidth = 55;
                            int shimmerX = (int)_shimmerPixelOffset;
                            Rectangle shimmerRect = new Rectangle(shimmerX, rect.Y, shimmerWidth, rect.Height);

                            using (LinearGradientBrush shimmerBrush = new LinearGradientBrush(
                                shimmerRect,
                                Color.FromArgb(0, 255, 255, 255),
                                Color.FromArgb(80, 255, 255, 255),
                                LinearGradientMode.Horizontal)) {
                                
                                ColorBlend cb = new ColorBlend(3);
                                cb.Colors = new Color[] {
                                    Color.FromArgb(0, 255, 255, 255),
                                    Color.FromArgb(80, 255, 255, 255),
                                    Color.FromArgb(0, 255, 255, 255)
                                };
                                cb.Positions = new float[] { 0f, 0.5f, 1f };
                                shimmerBrush.InterpolationColors = cb;

                                g.FillRectangle(shimmerBrush, shimmerRect);
                            }
                        }

                        g.ResetClip();
                    }
                }

                using (Pen borderPen = new Pen(_borderColor, 1f)) {
                    g.DrawPath(borderPen, trackPath);
                }
            }
        }

        private static GraphicsPath CreateRoundedRectanglePath(Rectangle rect, int radius) {
            GraphicsPath path = new GraphicsPath();
            if (radius <= 0) {
                path.AddRectangle(rect);
                return path;
            }

            int diameter = radius * 2;
            Rectangle arc = new Rectangle(rect.Location, new Size(diameter, diameter));

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
    }

    // ==============================================================================
    // Native UxTheme Dark Mode & Dark Scrollbars Helper (Windows 10 1809+ / Windows 11)
    // ==============================================================================
    public static class DarkThemeHelper {
        private static bool _initialized = false;
        private static readonly object _initLock = new object();

        [DllImport("uxtheme.dll", EntryPoint = "#135", SetLastError = true)]
        private static extern int SetPreferredAppMode(int appMode);

        [DllImport("uxtheme.dll", EntryPoint = "#133", SetLastError = true)]
        private static extern bool AllowDarkModeForWindow(IntPtr hWnd, bool allow);

        [DllImport("uxtheme.dll", ExactSpelling = true, CharSet = CharSet.Unicode)]
        public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);

        public static void InitializeAppDarkMode() {
            if (_initialized) return;
            lock (_initLock) {
                if (_initialized) return;
                try {
                    SetPreferredAppMode(2); // 2 = ForceDark
                } catch { }
                _initialized = true;
            }
        }

        public static void ApplyDarkTheme(IntPtr hWnd) {
            if (hWnd == IntPtr.Zero) return;
            InitializeAppDarkMode();
            try {
                AllowDarkModeForWindow(hWnd, true);
            } catch { }
            try {
                SetWindowTheme(hWnd, "DarkMode_Explorer", null);
            } catch { }
        }
    }

    // ==============================================================================
    // Modern Dark Tab Control (Eliminates Win9x borders and connects seamlessly to content)
    // ==============================================================================
    public class DarkTabControl : TabControl {
        private Color _tabSelectedBg = Color.FromArgb(47, 49, 54);    // #2f3136 (Active - matches TabPage)
        private Color _tabTextColor = Color.FromArgb(160, 160, 160);  // #a0a0a0
        private Color _tabSelectedTextColor = Color.White;
        private Color _accentColor = Color.FromArgb(88, 101, 242);     // #5865F2 (Discord Blurple)
        private Color _pageBg = Color.FromArgb(47, 49, 54);           // #2f3136

        private float GetDpiScale() {
            try {
                using (Graphics g = CreateGraphics()) {
                    return g.DpiX / 96f;
                }
            } catch {
                return 1.0f;
            }
        }

        public DarkTabControl() {
            SetStyle(
                ControlStyles.AllPaintingInWmPaint |
                ControlStyles.OptimizedDoubleBuffer |
                ControlStyles.ResizeRedraw |
                ControlStyles.UserPaint,
                true
            );
            DrawMode = TabDrawMode.OwnerDrawFixed;
            SizeMode = TabSizeMode.Normal;
            Multiline = true;
            Padding = new Point(16, 8);
            Font = new Font("Segoe UI", 9.5f, FontStyle.Regular);
        }

        protected override void OnHandleCreated(EventArgs e) {
            base.OnHandleCreated(e);
            try {
                DarkThemeHelper.SetWindowTheme(Handle, "", "");
            } catch {}
        }

        protected override void OnFontChanged(EventArgs e) {
            base.OnFontChanged(e);
            try {
                float dpiScale = GetDpiScale();
                Padding = new Point(Math.Max(16, (int)Math.Round(18 * dpiScale)), Math.Max(7, (int)Math.Round(9 * dpiScale)));
            } catch {}
            Invalidate();
        }

        protected override CreateParams CreateParams {
            get {
                CreateParams cp = base.CreateParams;
                cp.ExStyle &= ~0x00000200; // Remove WS_EX_CLIENTEDGE
                cp.Style &= ~0x00800000;  // Remove WS_BORDER
                cp.Style |= 0x00000200;   // TCS_MULTILINE (Eliminates white UpDown horizontal scroll arrows)
                return cp;
            }
        }

        protected override void WndProc(ref Message m) {
            if (m.Msg == 0x0085) { // WM_NCPAINT - suppress system non-client border
                m.Result = IntPtr.Zero;
                return;
            }
            if (m.Msg == 0x0014) { // WM_ERASEBKGND - prevent flicker / default background paint
                m.Result = (IntPtr)1;
                return;
            }
            base.WndProc(ref m);
        }

        public override Rectangle DisplayRectangle {
            get {
                int maxBottom = 0;
                for (int i = 0; i < TabCount; i++) {
                    Rectangle r = GetTabRect(i);
                    if (r.Bottom > maxBottom) maxBottom = r.Bottom;
                }
                int top = maxBottom > 0 ? maxBottom : (int)(34 * GetDpiScale());
                return new Rectangle(0, top, ClientRectangle.Width, Math.Max(0, ClientRectangle.Height - top));
            }
        }

        protected override void OnPaint(PaintEventArgs e) {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            // Compute maximum bottom of all tab headers
            int maxBottom = 0;
            for (int i = 0; i < TabCount; i++) {
                Rectangle r = GetTabRect(i);
                if (r.Bottom > maxBottom) maxBottom = r.Bottom;
            }
            if (maxBottom == 0) maxBottom = (int)(34 * GetDpiScale());

            // 1. Fill tab strip header background seamlessly matching parent background (#2f3136) to eliminate contrast lines
            Color headerBg = (Parent != null) ? Parent.BackColor : _pageBg;
            using (SolidBrush headerBrush = new SolidBrush(headerBg)) {
                g.FillRectangle(headerBrush, 0, 0, ClientRectangle.Width, maxBottom);
            }

            // 2. Fill tab page content area with Page Background (#2f3136)
            using (SolidBrush pageBrush = new SolidBrush(_pageBg)) {
                g.FillRectangle(pageBrush, 0, maxBottom, ClientRectangle.Width, Math.Max(0, ClientRectangle.Height - maxBottom));
            }

            if (TabCount == 0) return;

            int selectedIndex = SelectedIndex;
            Rectangle selectedRect = (selectedIndex >= 0 && selectedIndex < TabCount) ? GetTabRect(selectedIndex) : Rectangle.Empty;

            // 1. Draw inactive tabs on background/recessed rows (Bookshelf Tier 1)
            for (int i = 0; i < TabCount; i++) {
                if (i == selectedIndex) continue;
                Rectangle tr = GetTabRect(i);
                bool isInSelectedRow = (selectedRect != Rectangle.Empty && Math.Abs(tr.Y - selectedRect.Y) < 6);
                if (!isInSelectedRow) {
                    DrawTabHeader(g, i, false, false, maxBottom);
                }
            }

            // 2. Draw inactive tabs on the active row (Bookshelf Tier 2)
            for (int i = 0; i < TabCount; i++) {
                if (i == selectedIndex) continue;
                Rectangle tr = GetTabRect(i);
                bool isInSelectedRow = (selectedRect != Rectangle.Empty && Math.Abs(tr.Y - selectedRect.Y) < 6);
                if (isInSelectedRow) {
                    DrawTabHeader(g, i, false, true, maxBottom);
                }
            }

            // 3. Draw active tab on top (Commands foreground, overlaps inactive rows, seamlessly merges with content)
            if (selectedIndex >= 0 && selectedIndex < TabCount) {
                DrawTabHeader(g, selectedIndex, true, true, maxBottom);
            }
        }

        private void DrawTabHeader(Graphics g, int index, bool isSelected, bool isActiveRow, int maxBottom) {
            TabPage tab = TabPages[index];
            Rectangle tabRect = GetTabRect(index);

            // Extend leftmost and top edges to 0 so there is no 2px gray line on the left or top
            if (tabRect.Left <= 4) {
                tabRect.Width += tabRect.Left;
                tabRect.X = 0;
            }
            if (tabRect.Top <= 4) {
                tabRect.Height += tabRect.Top;
                tabRect.Y = 0;
            }

            if (isSelected) {
                // Active tab extends seamlessly down to maxBottom + 2 to overwrite the separator line
                if (tabRect.Bottom >= maxBottom - 4) {
                    tabRect.Height = Math.Max(tabRect.Height, (maxBottom - tabRect.Top) + 2);
                } else {
                    tabRect.Height += 2;
                }
            }

            Color bg;
            Color fg;

            if (isSelected) {
                bg = _tabSelectedBg;              // #2f3136 (Active page match)
                fg = _tabSelectedTextColor;       // Pure White
            } else if (isActiveRow) {
                bg = Color.FromArgb(37, 39, 43);  // #25272b (Foreground inactive row)
                fg = _tabTextColor;               // #a0a0a0
            } else {
                bg = Color.FromArgb(28, 30, 33);  // #1c1e21 (Bookshelf recessed back tier)
                fg = Color.FromArgb(140, 142, 146);
            }

            using (SolidBrush tabBrush = new SolidBrush(bg)) {
                g.FillRectangle(tabBrush, tabRect);
            }

            if (!isSelected) {
                // Subtle bookshelf tile outline
                using (Pen shelfPen = new Pen(Color.FromArgb(43, 45, 49), 1f)) {
                    g.DrawRectangle(shelfPen, tabRect.X, tabRect.Y, tabRect.Width, tabRect.Height);
                }
            } else {
                // Active Tab Top Accent Bar (Discord Purple / Blurple #5865F2)
                int accentHeight = Math.Max(2, (int)(3 * GetDpiScale()));
                using (SolidBrush accentBrush = new SolidBrush(_accentColor)) {
                    g.FillRectangle(accentBrush, tabRect.Left, tabRect.Top, tabRect.Width, accentHeight);
                }

                // Active tab side contrast borders
                using (Pen activeBorderPen = new Pen(Color.FromArgb(54, 57, 63), 1f)) {
                    g.DrawLine(activeBorderPen, tabRect.Left, tabRect.Top, tabRect.Left, tabRect.Bottom);
                    g.DrawLine(activeBorderPen, tabRect.Right - 1, tabRect.Top, tabRect.Right - 1, tabRect.Bottom);
                }
            }

            // Tab Text (centered, crisp single-line with ellipsis trimming)
            using (StringFormat sf = new StringFormat()) {
                sf.Alignment = StringAlignment.Center;
                sf.LineAlignment = StringAlignment.Center;
                sf.Trimming = StringTrimming.EllipsisCharacter;
                sf.FormatFlags = StringFormatFlags.NoWrap;
                using (Font tabFont = isSelected ? new Font(Font, FontStyle.Bold) : new Font(Font, FontStyle.Regular))
                using (SolidBrush textBrush = new SolidBrush(fg)) {
                    Rectangle textRect = new Rectangle(
                        tabRect.Left + 2,
                        tabRect.Top + (isSelected ? 2 : 0),
                        Math.Max(10, tabRect.Width - 4),
                        Math.Max(10, tabRect.Height - (isSelected ? 3 : 0))
                    );
                    g.DrawString(tab.Text, tabFont, textBrush, textRect, sf);
                }
            }
        }
    }

    // ==============================================================================
    // Modern Dark ListView (Custom OwnerDraw Header & Rows, Column Sorting & Zero Win9x Gray Borders)
    // ==============================================================================
    public class ListViewItemComparer : System.Collections.IComparer {
        private int _col;
        private SortOrder _order;

        public ListViewItemComparer(int column, SortOrder order) {
            _col = column;
            _order = order;
        }

        public int Compare(object x, object y) {
            ListViewItem itemX = x as ListViewItem;
            ListViewItem itemY = y as ListViewItem;
            if (itemX == null || itemY == null) return 0;

            string textX = _col < itemX.SubItems.Count ? itemX.SubItems[_col].Text : "";
            string textY = _col < itemY.SubItems.Count ? itemY.SubItems[_col].Text : "";

            double numX, numY;
            int returnVal;
            if (double.TryParse(textX, out numX) && double.TryParse(textY, out numY)) {
                returnVal = numX.CompareTo(numY);
            } else {
                returnVal = string.Compare(textX, textY, StringComparison.CurrentCultureIgnoreCase);
            }

            if (_order == SortOrder.Descending) {
                returnVal = -returnVal;
            }
            return returnVal;
        }
    }

    public class DarkListView : ListView {
        private Color _headerBg = Color.FromArgb(32, 34, 37);         // #202225
        private Color _headerFg = Color.FromArgb(217, 217, 217);      // #d9d9d9
        private Color _headerBorder = Color.FromArgb(47, 49, 54);     // #2f3136
        private Color _itemBg = Color.FromArgb(32, 34, 37);           // #202225
        private Color _itemSelectedBg = Color.FromArgb(54, 57, 63);   // #36393f
        private Color _itemSelectedFg = Color.White;
        private Color _itemFg = Color.FromArgb(217, 217, 217);        // #d9d9d9
        private Color _itemSubFg = Color.FromArgb(160, 160, 160);     // #a0a0a0
        private int _autoFitColumnIndex = -1;
        private bool _autoFillLastColumn = true;
        private bool _enableColumnSorting = true;
        private int _sortColumn = -1;
        private SortOrder _sortOrder = SortOrder.None;
        private DarkHeaderControl _headerSubclass;

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);

        [StructLayout(LayoutKind.Sequential)]
        private struct RECT {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        private class DarkHeaderControl : NativeWindow {
            private DarkListView _parent;
            public DarkHeaderControl(DarkListView parent) {
                _parent = parent;
            }

            protected override void WndProc(ref Message m) {
                const int WM_PAINT = 0x000F;
                const int WM_ERASEBKGND = 0x0014;

                if (m.Msg == WM_ERASEBKGND) {
                    RECT rc;
                    GetClientRect(this.Handle, out rc);
                    using (Graphics g = Graphics.FromHdc(m.WParam))
                    using (SolidBrush bgBrush = new SolidBrush(_parent._headerBg)) {
                        g.FillRectangle(bgBrush, 0, 0, rc.Right - rc.Left, rc.Bottom - rc.Top);
                    }
                    m.Result = (IntPtr)1;
                    return;
                }

                base.WndProc(ref m);

                if (m.Msg == WM_PAINT) {
                    RECT rc;
                    GetClientRect(this.Handle, out rc);
                    int totalColWidth = 0;
                    foreach (ColumnHeader col in _parent.Columns) {
                        totalColWidth += col.Width;
                    }
                    int headerWidth = rc.Right - rc.Left;
                    int headerHeight = rc.Bottom - rc.Top;
                    if (totalColWidth < headerWidth) {
                        using (Graphics g = Graphics.FromHwnd(this.Handle)) {
                            Rectangle emptyRect = new Rectangle(totalColWidth, 0, headerWidth - totalColWidth, headerHeight);
                            using (SolidBrush bgBrush = new SolidBrush(_parent._headerBg)) {
                                g.FillRectangle(bgBrush, emptyRect);
                            }
                            using (Pen borderPen = new Pen(_parent._headerBorder, 1f)) {
                                g.DrawLine(borderPen, totalColWidth, headerHeight - 1, headerWidth, headerHeight - 1);
                            }
                        }
                    }
                }
            }
        }

        public DarkListView() {
            SetStyle(
                ControlStyles.OptimizedDoubleBuffer |
                ControlStyles.AllPaintingInWmPaint |
                ControlStyles.ResizeRedraw,
                true
            );
            View = View.Details;
            FullRowSelect = true;
            GridLines = false;
            BorderStyle = BorderStyle.None;
            BackColor = _itemBg;
            ForeColor = _itemFg;
            Font = new Font("Segoe UI", 9f, FontStyle.Regular);
            OwnerDraw = true;

            DrawColumnHeader += OnDrawColumnHeader;
            DrawItem += OnDrawItem;
            DrawSubItem += OnDrawSubItem;
        }

        public bool EnableColumnSorting {
            get { return _enableColumnSorting; }
            set { _enableColumnSorting = value; }
        }

        public int SortColumn {
            get { return _sortColumn; }
        }

        public SortOrder SortOrder {
            get { return _sortOrder; }
        }

        public void SortByColumn(int column, SortOrder order) {
            if (column < 0 || column >= Columns.Count) return;
            _sortColumn = column;
            _sortOrder = order;
            ListViewItemSorter = new ListViewItemComparer(_sortColumn, _sortOrder);
            Sort();
            Invalidate();
        }

        protected override void OnColumnClick(ColumnClickEventArgs e) {
            base.OnColumnClick(e);
            if (!_enableColumnSorting) return;

            if (e.Column == _sortColumn) {
                _sortOrder = (_sortOrder == SortOrder.Ascending) ? SortOrder.Descending : SortOrder.Ascending;
            } else {
                _sortColumn = e.Column;
                _sortOrder = SortOrder.Ascending;
            }

            ListViewItemSorter = new ListViewItemComparer(_sortColumn, _sortOrder);
            Sort();
            Invalidate();
        }

        protected override CreateParams CreateParams {
            get {
                CreateParams cp = base.CreateParams;
                cp.Style &= ~0x00800000; // WS_BORDER
                cp.ExStyle &= ~0x00000200; // WS_EX_CLIENTEDGE
                return cp;
            }
        }

        protected override void OnHandleCreated(EventArgs e) {
            base.OnHandleCreated(e);
            DarkThemeHelper.ApplyDarkTheme(this.Handle);
            IntPtr hHeader = SendMessage(this.Handle, 0x101F, IntPtr.Zero, IntPtr.Zero);
            if (hHeader != IntPtr.Zero) {
                if (_headerSubclass == null) {
                    _headerSubclass = new DarkHeaderControl(this);
                }
                _headerSubclass.ReleaseHandle();
                _headerSubclass.AssignHandle(hHeader);
            }
        }

        protected override void OnHandleDestroyed(EventArgs e) {
            if (_headerSubclass != null) {
                _headerSubclass.ReleaseHandle();
            }
            base.OnHandleDestroyed(e);
        }

        protected override void WndProc(ref Message m) {
            const int WM_PAINT = 0x000F;
            const int WM_ERASEBKGND = 0x0014;

            if (m.Msg == WM_ERASEBKGND) {
                RECT rc;
                GetClientRect(this.Handle, out rc);
                using (Graphics g = Graphics.FromHdc(m.WParam))
                using (SolidBrush bgBrush = new SolidBrush(_itemBg)) {
                    g.FillRectangle(bgBrush, 0, 0, rc.Right - rc.Left, rc.Bottom - rc.Top);
                }
                m.Result = (IntPtr)1;
                return;
            }

            base.WndProc(ref m);

            if (m.Msg == WM_PAINT) {
                try {
                    int itemsBottom = 0;
                    if (Items.Count > 0) {
                        Rectangle lastItemRect = Items[Items.Count - 1].Bounds;
                        itemsBottom = lastItemRect.Bottom;
                    }
                    if (itemsBottom < ClientSize.Height && ClientSize.Width > 0 && ClientSize.Height > 0) {
                        using (Graphics g = Graphics.FromHwnd(this.Handle)) {
                            Rectangle emptyArea = new Rectangle(0, itemsBottom, ClientSize.Width, ClientSize.Height - itemsBottom);
                            using (SolidBrush bgBrush = new SolidBrush(_itemBg)) {
                                g.FillRectangle(bgBrush, emptyArea);
                            }
                        }
                    }
                } catch { }
            }
        }

        public int AutoFitColumnIndex {
            get { return _autoFitColumnIndex; }
            set { _autoFitColumnIndex = value; AutoResizeColumnsInternal(); }
        }

        public bool AutoFillLastColumn {
            get { return _autoFillLastColumn; }
            set { _autoFillLastColumn = value; AutoResizeColumnsInternal(); }
        }

        protected override void OnResize(EventArgs e) {
            base.OnResize(e);
            AutoResizeColumnsInternal();
        }

        public void AutoResizeColumnsInternal() {
            if (Columns.Count < 2 || ClientSize.Width <= 0) return;
            int fitIndex = _autoFitColumnIndex;
            if (fitIndex < 0 && _autoFillLastColumn) {
                fitIndex = Columns.Count - 1;
            }
            if (fitIndex < 0 || fitIndex >= Columns.Count) return;

            int totalOther = 0;
            for (int i = 0; i < Columns.Count; i++) {
                if (i != fitIndex) {
                    totalOther += Columns[i].Width;
                }
            }
            int fitWidth = Math.Max(40, ClientSize.Width - totalOther);
            if (Columns[fitIndex].Width != fitWidth) {
                Columns[fitIndex].Width = fitWidth;
            }
        }

        private void OnDrawColumnHeader(object sender, DrawListViewColumnHeaderEventArgs e) {
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            using (SolidBrush bgBrush = new SolidBrush(_headerBg)) {
                g.FillRectangle(bgBrush, e.Bounds);
            }

            using (Pen borderPen = new Pen(_headerBorder, 1f)) {
                g.DrawLine(borderPen, e.Bounds.Left, e.Bounds.Bottom - 1, e.Bounds.Right, e.Bounds.Bottom - 1);
                if (e.ColumnIndex < Columns.Count - 1) {
                    g.DrawLine(borderPen, e.Bounds.Right - 1, e.Bounds.Top + 4, e.Bounds.Right - 1, e.Bounds.Bottom - 4);
                }
            }

            float headerSize = (Font != null && Font.SizeInPoints > 0) ? Math.Min(9.5f, Font.SizeInPoints) : 9.0f;
            using (Font headerFont = new Font(Font.FontFamily, headerSize, FontStyle.Bold))
            using (SolidBrush textBrush = new SolidBrush(_headerFg))
            using (StringFormat sf = new StringFormat()) {
                sf.LineAlignment = StringAlignment.Center;
                Rectangle textRect = new Rectangle(e.Bounds.Left + 6, e.Bounds.Top, e.Bounds.Width - (_sortColumn == e.ColumnIndex ? 22 : 12), e.Bounds.Height);
                g.DrawString(e.Header.Text, headerFont, textBrush, textRect, sf);

                // Draw sorting indicator arrow if active
                if (_sortColumn == e.ColumnIndex && _sortOrder != SortOrder.None) {
                    int arrowSize = 6;
                    int arrowX = e.Bounds.Right - 16;
                    int arrowY = e.Bounds.Top + (e.Bounds.Height / 2) - 3;
                    PointF[] sortArrow;
                    if (_sortOrder == SortOrder.Ascending) {
                        sortArrow = new PointF[] {
                            new PointF(arrowX, arrowY + arrowSize),
                            new PointF(arrowX + arrowSize, arrowY + arrowSize),
                            new PointF(arrowX + (arrowSize / 2f), arrowY)
                        };
                    } else {
                        sortArrow = new PointF[] {
                            new PointF(arrowX, arrowY),
                            new PointF(arrowX + arrowSize, arrowY),
                            new PointF(arrowX + (arrowSize / 2f), arrowY + arrowSize)
                        };
                    }
                    using (SolidBrush arrowBrush = new SolidBrush(Color.FromArgb(88, 101, 242))) {
                        g.FillPolygon(arrowBrush, sortArrow);
                    }
                }
            }
        }

        private void OnDrawItem(object sender, DrawListViewItemEventArgs e) {
            // Handled in DrawSubItem
        }

        private void OnDrawSubItem(object sender, DrawListViewSubItemEventArgs e) {
            Graphics g = e.Graphics;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            bool isSelected = e.Item.Selected;
            Rectangle bounds = e.Bounds;

            Color bg = isSelected ? _itemSelectedBg : _itemBg;
            using (SolidBrush bgBrush = new SolidBrush(bg)) {
                g.FillRectangle(bgBrush, bounds);
            }

            if (isSelected && e.ColumnIndex == 0) {
                using (SolidBrush accentBrush = new SolidBrush(Color.FromArgb(88, 101, 242))) {
                    g.FillRectangle(accentBrush, bounds.Left, bounds.Top, 3, bounds.Height);
                }
            }

            Color fg = isSelected ? _itemSelectedFg : (e.ColumnIndex == 0 ? _itemFg : _itemSubFg);
            using (SolidBrush textBrush = new SolidBrush(fg))
            using (StringFormat sf = new StringFormat()) {
                sf.LineAlignment = StringAlignment.Center;
                sf.Trimming = StringTrimming.EllipsisCharacter;
                int padLeft = (e.ColumnIndex == 0) ? (isSelected ? 10 : 8) : 6;
                Rectangle textRect = new Rectangle(bounds.Left + padLeft, bounds.Top, bounds.Width - padLeft - 4, bounds.Height);
                g.DrawString(e.SubItem.Text, Font, textBrush, textRect, sf);
            }
        }
    }

    // ==============================================================================
    // Modern Dark ComboBox (Owner-Drawn DropDownList with Sleek Arrow & Dark Menu)
    // ==============================================================================
    public class DarkComboBox : ComboBox {
        private Color _bgColor = Color.FromArgb(32, 34, 37);          // #202225
        private Color _fgColor = Color.FromArgb(220, 221, 222);      // #dcdde0
        private Color _borderColor = Color.FromArgb(64, 68, 75);      // #40444b
        private Color _hoverColor = Color.FromArgb(88, 101, 242);     // #5865F2
        private Color _arrowColor = Color.FromArgb(217, 217, 217);    // #d9d9d9

        private float GetDpiScale() {
            try {
                using (Graphics g = CreateGraphics()) {
                    return g.DpiX / 96f;
                }
            } catch {
                return 1.0f;
            }
        }

        public DarkComboBox() {
            DrawMode = DrawMode.OwnerDrawFixed;
            DropDownStyle = ComboBoxStyle.DropDownList;
            BackColor = _bgColor;
            ForeColor = _fgColor;
            FlatStyle = FlatStyle.Flat;
            ItemHeight = (int)(22 * GetDpiScale());
        }

        protected override void OnHandleCreated(EventArgs e) {
            base.OnHandleCreated(e);
            try {
                DarkThemeHelper.SetWindowTheme(Handle, "", "");
            } catch { }
            ItemHeight = (int)(22 * GetDpiScale());
        }

        protected override void OnDrawItem(DrawItemEventArgs e) {
            if (e.Index < 0) return;
            Graphics g = e.Graphics;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

            bool isHovered = (e.State & DrawItemState.Selected) == DrawItemState.Selected;
            Color bg = isHovered ? _hoverColor : _bgColor;
            Color fg = isHovered ? Color.White : _fgColor;

            using (SolidBrush bgBrush = new SolidBrush(bg)) {
                g.FillRectangle(bgBrush, e.Bounds);
            }

            string text = Items[e.Index].ToString();
            using (SolidBrush textBrush = new SolidBrush(fg))
            using (StringFormat sf = new StringFormat()) {
                sf.LineAlignment = StringAlignment.Center;
                Rectangle textRect = new Rectangle(e.Bounds.Left + 8, e.Bounds.Top, e.Bounds.Width - 12, e.Bounds.Height);
                g.DrawString(text, Font, textBrush, textRect, sf);
            }
        }

        protected override void WndProc(ref Message m) {
            base.WndProc(ref m);
            if (m.Msg == 0x000F) { // WM_PAINT
                try {
                    using (Graphics g = Graphics.FromHwnd(this.Handle)) {
                        g.SmoothingMode = SmoothingMode.AntiAlias;

                        // 1. Completely overwrite native drop-down button area with dark #202225
                        float dpiScale = GetDpiScale();
                        int btnWidth = Math.Max(20, (int)(24 * dpiScale));
                        Rectangle btnRect = new Rectangle(Width - btnWidth, 1, btnWidth - 1, Height - 2);
                        using (SolidBrush bgBrush = new SolidBrush(_bgColor)) {
                            g.FillRectangle(bgBrush, btnRect);
                        }

                        // 2. Draw modern dark border around entire ComboBox
                        using (Pen p = new Pen(_borderColor, 1f)) {
                            g.DrawRectangle(p, 0, 0, Width - 1, Height - 1);
                        }

                        // 3. Draw single crisp down arrow in the center of the dark button area
                        int arrowWidth = Math.Max(6, (int)(8 * dpiScale));
                        int arrowHeight = Math.Max(3, (int)(4 * dpiScale));
                        float arrowX = Width - (btnWidth / 2f) - (arrowWidth / 2f);
                        float arrowY = (Height / 2f) - (arrowHeight / 2f);

                        PointF[] arrow = new PointF[] {
                            new PointF(arrowX, arrowY),
                            new PointF(arrowX + arrowWidth, arrowY),
                            new PointF(arrowX + (arrowWidth / 2f), arrowY + arrowHeight)
                        };
                        using (SolidBrush arrowBrush = new SolidBrush(_arrowColor)) {
                            g.FillPolygon(arrowBrush, arrow);
                        }
                    }
                } catch { }
            }
        }
    }

    // ==============================================================================
    // Dark TextBox (Discord Slate Dark Mode with 1px border and dark scrollbars)
    // ==============================================================================
    public class DarkTextBox : TextBox {
        private Color _borderColor = Color.FromArgb(64, 68, 75); // #40444b
        private Color _bgColor = Color.FromArgb(30, 31, 34);      // #1e1f22

        [DllImport("user32.dll")]
        private static extern IntPtr GetWindowDC(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

        public DarkTextBox() {
            BorderStyle = BorderStyle.FixedSingle;
            BackColor = _bgColor;
            ForeColor = Color.FromArgb(217, 217, 217);
        }

        protected override CreateParams CreateParams {
            get {
                CreateParams cp = base.CreateParams;
                cp.ExStyle &= ~0x00000200; // WS_EX_CLIENTEDGE (removes 3D white highlight)
                return cp;
            }
        }

        protected override void OnHandleCreated(EventArgs e) {
            base.OnHandleCreated(e);
            DarkThemeHelper.ApplyDarkTheme(this.Handle);
        }

        protected override void WndProc(ref Message m) {
            base.WndProc(ref m);
            if (m.Msg == 0x0085 || m.Msg == 0x000F) { // WM_NCPAINT or WM_PAINT
                try {
                    IntPtr hdc = GetWindowDC(this.Handle);
                    if (hdc != IntPtr.Zero) {
                        using (Graphics g = Graphics.FromHdc(hdc)) {
                            using (Pen p = new Pen(_borderColor, 1f)) {
                                g.DrawRectangle(p, 0, 0, Width - 1, Height - 1);
                            }
                        }
                        ReleaseDC(this.Handle, hdc);
                    }
                } catch { }
            }
        }
    }

    // ==============================================================================
    // Native File Downloader (Thread-Safe Streaming Background Downloader)
    // ==============================================================================
    public class FileDownloadState {
        public long BytesRead = 0;
        public long TotalBytes = 0;
        public double SpeedMbps = 0.0;
        public volatile bool IsCompleted = false;
        public volatile bool IsCancelled = false;
        public volatile string Error = null;
    }

    public class FileDownloader {
        public static FileDownloadState StartDownload(string url, string outputPath) {
            return StartDownload(url, outputPath, (object)null);
        }

        public static FileDownloadState StartDownload(string url, string outputPath, object customHeaders) {
            FileDownloadState state = new FileDownloadState();
            Thread t = new Thread(() => {
                try {
                    ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | (SecurityProtocolType)12288;
                    ServicePointManager.DefaultConnectionLimit = 64;

                    string currentUrl = url;
                    if (currentUrl.IndexOf("sourceforge.net/projects/", StringComparison.OrdinalIgnoreCase) >= 0) {
                        var sfMatch = System.Text.RegularExpressions.Regex.Match(currentUrl, @"sourceforge\.net/projects/([^/]+)/files/(.+?)(?:/download)?(?:\?.*)?$", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                        if (sfMatch.Success) {
                            currentUrl = "https://downloads.sourceforge.net/project/" + sfMatch.Groups[1].Value + "/" + sfMatch.Groups[2].Value;
                        }
                    }

                    int maxRedirects = 10;
                    HttpWebResponse response = null;

                    CookieContainer cookieJar = new CookieContainer();

                    for (int r = 0; r < maxRedirects; r++) {
                        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(currentUrl);
                        request.CookieContainer = cookieJar;
                        request.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36";
                        request.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8";
                        request.Headers.Add("Accept-Language", "en-US,en;q=0.9");
                        request.AllowAutoRedirect = false; // Manually handle redirects for reliable relative/SourceForge URI resolution
                        request.Timeout = 60000;
                        request.ReadWriteTimeout = 60000;

                        if (customHeaders is System.Collections.IDictionary dict) {
                            foreach (var key in dict.Keys) {
                                if (key != null) {
                                    string kStr = key.ToString();
                                    string vStr = dict[key] != null ? dict[key].ToString() : "";
                                    if (kStr.Equals("Referer", StringComparison.OrdinalIgnoreCase)) {
                                        request.Referer = vStr;
                                    } else if (kStr.Equals("User-Agent", StringComparison.OrdinalIgnoreCase)) {
                                        request.UserAgent = vStr;
                                    } else {
                                        request.Headers[kStr] = vStr;
                                    }
                                }
                            }
                        }

                        if (string.IsNullOrEmpty(request.Referer)) {
                            if (currentUrl.IndexOf("forensit.com", StringComparison.OrdinalIgnoreCase) >= 0) {
                                request.Referer = "https://www.forensit.com/downloads.html";
                            } else if (currentUrl.IndexOf("wagnardsoft.com", StringComparison.OrdinalIgnoreCase) >= 0) {
                                request.Referer = "https://www.wagnardsoft.com/";
                            } else if (currentUrl.IndexOf("sourceforge.net", StringComparison.OrdinalIgnoreCase) >= 0) {
                                request.Referer = "https://sourceforge.net/";
                            } else if (currentUrl.IndexOf("blender.org", StringComparison.OrdinalIgnoreCase) >= 0) {
                                request.Referer = "https://www.blender.org/download/";
                            }
                        }

                        response = (HttpWebResponse)request.GetResponse();
                        int statusCode = (int)response.StatusCode;

                        if (statusCode >= 300 && statusCode < 400) {
                            string loc = response.Headers["Location"];
                            response.Close();
                            if (string.IsNullOrEmpty(loc)) break;

                            if (!Uri.IsWellFormedUriString(loc, UriKind.Absolute)) {
                                Uri baseUri = new Uri(currentUrl);
                                currentUrl = new Uri(baseUri, loc).ToString();
                            } else {
                                currentUrl = loc;
                            }
                            continue;
                        }

                        // If SourceForge returns an intermediate 200 HTML countdown page, scrape the direct link
                        if (statusCode == 200 && response.ContentType != null && response.ContentType.IndexOf("text/html", StringComparison.OrdinalIgnoreCase) >= 0) {
                            string html;
                            using (var sr = new StreamReader(response.GetResponseStream())) {
                                html = sr.ReadToEnd();
                            }
                            response.Close();

                            var m = System.Text.RegularExpressions.Regex.Match(html, @"https://downloads\.sourceforge\.net/project/[^""' \r\n<>]+");
                            if (m.Success) {
                                currentUrl = System.Net.WebUtility.HtmlDecode(m.Value);
                                continue;
                            }
                        }

                        break;
                    }

                    if (response == null) {
                        state.Error = "Failed to connect to download server.";
                        return;
                    }

                    state.TotalBytes = response.ContentLength;
                    string dir = Path.GetDirectoryName(outputPath);
                    if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) {
                        Directory.CreateDirectory(dir);
                    }

                    using (response)
                    using (Stream responseStream = response.GetResponseStream())
                    using (FileStream fileStream = File.Create(outputPath)) {
                        byte[] buffer = new byte[262144]; // 256 KB buffer for high-throughput downloads
                        int bytesRead = 0;
                        var sw = System.Diagnostics.Stopwatch.StartNew();
                        long total = 0;

                        while ((bytesRead = responseStream.Read(buffer, 0, buffer.Length)) > 0) {
                            if (state.IsCancelled) break;
                            fileStream.Write(buffer, 0, bytesRead);
                            total += bytesRead;
                            state.BytesRead = total;
                            double sec = Math.Max(0.001, sw.Elapsed.TotalSeconds);
                            state.SpeedMbps = (total * 8.0 / 1048576.0) / sec;
                        }
                        if (!state.IsCancelled) {
                            state.IsCompleted = true;
                        }
                    }
                } catch (WebException wex) {
                    if (wex.Response is HttpWebResponse errResp) {
                        int errCode = (int)errResp.StatusCode;
                        if (errCode == 403) {
                            state.Error = "403 Forbidden (Download server is protected by bot verification).";
                        } else {
                            state.Error = "HTTP " + errCode + ": " + errResp.StatusDescription;
                        }
                    } else {
                        state.Error = wex.Message;
                    }
                } catch (Exception ex) {
                    state.Error = ex.Message;
                }
            }) { IsBackground = true };
            t.Start();
            return state;
        }
    }

    // ==============================================================================
    // Native Archive Extractor (Non-Blocking Fast Background Extraction)
    // ==============================================================================
    public class ExtractionState {
        public int EntriesExtracted = 0;
        public int TotalEntries = 0;
        public double Percent = 0.0;
        public string CurrentEntry = "";
        public volatile bool IsCompleted = false;
        public volatile bool IsCancelled = false;
        public volatile string Error = null;
    }

    public class ArchiveExtractor {
        public static ExtractionState StartExtract(string archivePath, string destinationDirectory) {
            var state = new ExtractionState();
            Thread t = new Thread(() => {
                try {
                    if (!Directory.Exists(destinationDirectory)) {
                        Directory.CreateDirectory(destinationDirectory);
                    }

                    bool extractedViaDotNet = false;
                    try {
                        Assembly compAsm = null;
                        try { compAsm = Assembly.Load("System.IO.Compression"); } catch {}

                        Type zipArchiveType = compAsm != null ? compAsm.GetType("System.IO.Compression.ZipArchive") : Type.GetType("System.IO.Compression.ZipArchive");
                        Type modeType = compAsm != null ? compAsm.GetType("System.IO.Compression.ZipArchiveMode") : Type.GetType("System.IO.Compression.ZipArchiveMode");

                        if (zipArchiveType != null && modeType != null) {
                            using (var fileStream = File.OpenRead(archivePath)) {
                                object modeRead = Enum.Parse(modeType, "Read");
                                using (var zip = (IDisposable)Activator.CreateInstance(zipArchiveType, fileStream, modeRead)) {
                                    var entriesProp = zipArchiveType.GetProperty("Entries");
                                    var entries = (System.Collections.IEnumerable)entriesProp.GetValue(zip, null);
                                    
                                    var entryList = new System.Collections.ArrayList();
                                    foreach (var e in entries) { entryList.Add(e); }
                                    state.TotalEntries = entryList.Count;
                                    
                                    int count = 0;
                                    string destRoot = Path.GetFullPath(destinationDirectory);

                                    foreach (var entry in entryList) {
                                        if (state.IsCancelled) break;
                                        var nameProp = entry.GetType().GetProperty("Name");
                                        var fullNameProp = entry.GetType().GetProperty("FullName");
                                        string name = (string)nameProp.GetValue(entry, null);
                                        string fullName = (string)fullNameProp.GetValue(entry, null);
                                        state.CurrentEntry = name;

                                        string fullDest = Path.GetFullPath(Path.Combine(destinationDirectory, fullName));
                                        if (!fullDest.StartsWith(destRoot, StringComparison.OrdinalIgnoreCase)) {
                                            continue; // Path traversal protection
                                        }

                                        if (string.IsNullOrEmpty(name)) {
                                            Directory.CreateDirectory(fullDest);
                                        } else {
                                            string parentDir = Path.GetDirectoryName(fullDest);
                                            if (!string.IsNullOrEmpty(parentDir) && !Directory.Exists(parentDir)) {
                                                Directory.CreateDirectory(parentDir);
                                            }
                                            var openMethod = entry.GetType().GetMethod("Open");
                                            using (var entryStream = (Stream)openMethod.Invoke(entry, null))
                                            using (var outStream = File.Create(fullDest)) {
                                                byte[] buf = new byte[81920];
                                                int bytes;
                                                while ((bytes = entryStream.Read(buf, 0, buf.Length)) > 0) {
                                                    outStream.Write(buf, 0, bytes);
                                                }
                                            }
                                        }

                                        count++;
                                        state.EntriesExtracted = count;
                                        state.Percent = (state.TotalEntries > 0) ? (count * 100.0 / state.TotalEntries) : 100.0;
                                    }
                                    extractedViaDotNet = true;
                                }
                            }
                        }
                    } catch {}

                    if (!extractedViaDotNet && !state.IsCancelled) {
                        // Fallback to built-in tar.exe
                        var psi = new System.Diagnostics.ProcessStartInfo {
                            FileName = "tar.exe",
                            Arguments = string.Format("-xf \"{0}\" -C \"{1}\"", archivePath, destinationDirectory),
                            CreateNoWindow = true,
                            UseShellExecute = false,
                            WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden
                        };
                        using (var p = System.Diagnostics.Process.Start(psi)) {
                            p.WaitForExit();
                        }
                    }

                    if (!state.IsCancelled) {
                        state.IsCompleted = true;
                    }
                } catch (Exception ex) {
                    state.Error = ex.Message;
                }
            }) { IsBackground = true };
            t.Start();
            return state;
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
        private CancellationTokenSource _cts;
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
        private readonly List<PingSample> _samples = new List<PingSample>();
        private readonly object _sampleLock = new object();

        public event Action<PingSample> OnPingSample;
        public event Action<PingSummary> OnSummaryUpdate;
        public event Action<PingSummary> OnCompleted;

        public bool IsRunning { get { return _isRunning; } }

        public PingSample[] DrainSamples() {
            lock (_sampleLock) {
                var arr = _samples.ToArray();
                _samples.Clear();
                return arr;
            }
        }

        public void Start(string host, int pingsPerSecond, int packetSize, int durationSeconds = 0) {
            if (_isRunning) Stop();

            try {
                int minWorker, minIOC;
                ThreadPool.GetMinThreads(out minWorker, out minIOC);
                if (minWorker < 2048) {
                    ThreadPool.SetMinThreads(2048, Math.Max(2048, minIOC));
                }
            } catch {}

            _targetHost = host ?? "1.1.1.1";
            _pingsPerSecond = Math.Max(1, Math.Min(10000, pingsPerSecond));
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
            lock (_sampleLock) { _samples.Clear(); }

            _cts = new CancellationTokenSource();
            _isRunning = true;
            _workerThread = new Thread(WorkerLoop) {
                IsBackground = true,
                Name = "HMT_HighPrecisionPingWorker"
            };
            _workerThread.Start();
        }

        public void Stop() {
            _isRunning = false;
            try { _cts?.Cancel(); } catch { }
            if (_workerThread != null && _workerThread.IsAlive) {
                _workerThread.Join(1000);
            }
        }

        private void WorkerLoop() {
            byte[] buffer = new byte[_packetSize];
            new Random().NextBytes(buffer);
            var pingOptions = new PingOptions(64, true);

            double intervalMs = 1000.0 / _pingsPerSecond;
            int sequence = 0;
            long freq = System.Diagnostics.Stopwatch.Frequency;
            long nextDispatchTicks = System.Diagnostics.Stopwatch.GetTimestamp();
            var token = _cts.Token;

            while (_isRunning && !token.IsCancellationRequested) {
                sequence++;
                int seq = sequence;

                // Dispatch truly asynchronous non-blocking ICMP ping
                Task.Run(async () => {
                    if (token.IsCancellationRequested) return;

                    var sample = new PingSample {
                        Sequence = seq,
                        Timestamp = DateTime.Now
                    };

                    try {
                        Interlocked.Increment(ref _sentCount);
                        using (var pingSender = new Ping()) {
                            var sw = System.Diagnostics.Stopwatch.StartNew();
                            var reply = await pingSender.SendPingAsync(_targetHost, 1500, buffer, pingOptions);
                            sw.Stop();

                            if (token.IsCancellationRequested) return;

                            if (reply != null && reply.Status == IPStatus.Success) {
                                sample.Success = true;
                                sample.RttMs = (reply.RoundtripTime > 0) ? reply.RoundtripTime : sw.Elapsed.TotalMilliseconds;
                                sample.Status = reply.Status;

                                lock (_sampleLock) {
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
                                    _samples.Add(sample);
                                }
                            } else {
                                sample.Success = false;
                                sample.Status = (reply != null) ? reply.Status : IPStatus.TimedOut;
                                sample.ErrorMessage = sample.Status.ToString();
                                lock (_sampleLock) {
                                    _lostCount++;
                                    sample.JitterMs = _jitter;
                                    _samples.Add(sample);
                                }
                            }
                        }
                    } catch (Exception ex) {
                        if (token.IsCancellationRequested) return;
                        sample.Success = false;
                        sample.Status = IPStatus.Unknown;
                        sample.ErrorMessage = ex.Message;
                        lock (_sampleLock) {
                            _lostCount++;
                            sample.JitterMs = _jitter;
                            _samples.Add(sample);
                        }
                    }

                    if (_isRunning && !token.IsCancellationRequested && OnPingSample != null) {
                        try { OnPingSample(sample); } catch { }
                    }
                });

                if (OnSummaryUpdate != null && sequence % Math.Max(1, _pingsPerSecond / 2) == 0) {
                    try { OnSummaryUpdate(GetSummary()); } catch { }
                }

                if (_durationSeconds > 0 && _stopwatch.Elapsed.TotalSeconds >= _durationSeconds) {
                    break;
                }

                // High precision sleep to next scheduled dispatch
                nextDispatchTicks += (long)(intervalMs * freq / 1000.0);
                long currentTicks = System.Diagnostics.Stopwatch.GetTimestamp();
                long waitTicks = nextDispatchTicks - currentTicks;

                if (waitTicks > 0) {
                    int sleepMs = (int)(waitTicks * 1000.0 / freq);
                    if (sleepMs > 3) {
                        Thread.Sleep(sleepMs - 2);
                    }
                    while (System.Diagnostics.Stopwatch.GetTimestamp() < nextDispatchTicks && _isRunning && !token.IsCancellationRequested) {
                        Thread.SpinWait(5);
                    }
                } else {
                    if (currentTicks - nextDispatchTicks > (freq / 20)) {
                        nextDispatchTicks = currentTicks;
                    }
                }
            }

            _isRunning = false;

            if (OnSummaryUpdate != null) {
                try { OnSummaryUpdate(GetSummary()); } catch { }
            }
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
        private volatile bool _targetTimeReached;
        public volatile bool IsRunning = false;
        public volatile bool IsFinished = false;
        public volatile SpeedSample CurrentSample = null;
        public volatile SpeedSample Result = null;

        public event Action<SpeedSample> OnSpeedSample;

        public void Cancel() {
            _cancelled = true;
            _targetTimeReached = true;
            IsRunning = false;
        }

        public void StartDownloadTest(string url, int streams, int minDurationSeconds = 6, int maxDurationSeconds = 14) {
            IsRunning = true;
            IsFinished = false;
            Result = null;
            CurrentSample = null;
            Thread t = new Thread(() => {
                Result = RunDownloadTest(url, streams, minDurationSeconds, maxDurationSeconds);
                IsRunning = false;
                IsFinished = true;
            }) { IsBackground = true };
            t.Start();
        }

        public void StartUploadTest(string url, int streams, int minDurationSeconds = 6, int maxDurationSeconds = 14) {
            IsRunning = true;
            IsFinished = false;
            Result = null;
            CurrentSample = null;
            Thread t = new Thread(() => {
                Result = RunUploadTest(url, streams, minDurationSeconds, maxDurationSeconds);
                IsRunning = false;
                IsFinished = true;
            }) { IsBackground = true };
            t.Start();
        }

        public SpeedSample RunDownloadTest(string url, int streams, int minDurationSeconds = 6, int maxDurationSeconds = 14) {
            _cancelled = false;
            _targetTimeReached = false;
            streams = Math.Max(1, Math.Min(32, streams));
            minDurationSeconds = Math.Max(4, Math.Min(20, minDurationSeconds));
            maxDurationSeconds = Math.Max(minDurationSeconds + 2, Math.Min(30, maxDurationSeconds));

            try {
                ServicePointManager.DefaultConnectionLimit = 128;
                ServicePointManager.Expect100Continue = false;
                ServicePointManager.UseNagleAlgorithm = false;
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | (SecurityProtocolType)3072;
            } catch { }

            long totalBytes = 0;
            long lastSampleBytes = 0;
            var sw = System.Diagnostics.Stopwatch.StartNew();
            var lastSampleTime = sw.Elapsed.TotalSeconds;

            List<double> recentMbps = new List<double>();

            Thread[] workers = new Thread[streams];
            for (int i = 0; i < streams; i++) {
                workers[i] = new Thread(() => {
                    byte[] buffer = new byte[262144]; // 256KB buffer for max wire throughput
                    while (!_cancelled && !_targetTimeReached) {
                        try {
                            string reqUrl = url.Contains("?")
                                ? url + "&r=" + Guid.NewGuid().ToString("N")
                                : url + "?bytes=25000000&r=" + Guid.NewGuid().ToString("N");

                            var req = (HttpWebRequest)WebRequest.Create(reqUrl);
                            req.Method = "GET";
                            req.Headers.Add("Origin", "https://speed.cloudflare.com");
                            req.Referer = "https://speed.cloudflare.com/";
                            req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36";
                            req.Timeout = 8000;
                            req.ReadWriteTimeout = 8000;
                            req.Proxy = null;
                            req.ServicePoint.ConnectionLimit = 128;
                            req.ServicePoint.UseNagleAlgorithm = false;

                            using (var resp = req.GetResponse())
                            using (var stream = resp.GetResponseStream()) {
                                int read;
                                while (!_cancelled && !_targetTimeReached &&
                                       (read = stream.Read(buffer, 0, buffer.Length)) > 0) {
                                    Interlocked.Add(ref totalBytes, read);
                                }
                            }
                        } catch {
                            if (_cancelled || _targetTimeReached) break;
                            Thread.Sleep(25);
                        }
                    }
                }) { IsBackground = true };
                workers[i].Start();
            }

            while (!_cancelled && !_targetTimeReached) {
                Thread.Sleep(100);
                double currentElapsed = sw.Elapsed.TotalSeconds;
                double deltaT = currentElapsed - lastSampleTime;
                long curTotal = Interlocked.Read(ref totalBytes);
                long deltaBytes = curTotal - lastSampleBytes;

                if (deltaT > 0.08) {
                    double currentMbps = (deltaBytes * 8.0) / (deltaT * 1000000.0);
                    double avgMbps = (curTotal * 8.0) / (currentElapsed * 1000000.0);

                    lastSampleBytes = curTotal;
                    lastSampleTime = currentElapsed;

                    recentMbps.Add(currentMbps);
                    if (recentMbps.Count > 10) recentMbps.RemoveAt(0);

                    var sample = new SpeedSample {
                        CurrentMbps = currentMbps,
                        AverageMbps = avgMbps,
                        TotalBytesTransferred = curTotal,
                        ElapsedSeconds = currentElapsed,
                        Phase = "Download",
                        IsFinished = false
                    };
                    CurrentSample = sample;
                    if (OnSpeedSample != null) {
                        try { OnSpeedSample(sample); } catch { }
                    }

                    // Adaptive test duration
                    if (currentElapsed >= minDurationSeconds) {
                        if (currentElapsed >= maxDurationSeconds) {
                            _targetTimeReached = true;
                            break;
                        }

                        if (recentMbps.Count >= 6) {
                            double mean = 0;
                            for (int m = 0; m < recentMbps.Count; m++) mean += recentMbps[m];
                            mean /= recentMbps.Count;

                            double variance = 0;
                            for (int m = 0; m < recentMbps.Count; m++) {
                                double diff = recentMbps[m] - mean;
                                variance += diff * diff;
                            }
                            double stdDev = Math.Sqrt(variance / recentMbps.Count);
                            double coeffOfVar = (mean > 0) ? (stdDev / mean) : 1.0;

                            if (coeffOfVar < 0.06) {
                                _targetTimeReached = true;
                                break;
                            }
                        }
                    }
                }
            }

            _targetTimeReached = true;
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
            CurrentSample = finalSample;
            if (OnSpeedSample != null) {
                try { OnSpeedSample(finalSample); } catch { }
            }
            return finalSample;
        }

        public SpeedSample RunUploadTest(string url, int streams, int minDurationSeconds = 6, int maxDurationSeconds = 14) {
            _cancelled = false;
            _targetTimeReached = false;
            streams = Math.Max(1, Math.Min(32, streams));
            minDurationSeconds = Math.Max(4, Math.Min(20, minDurationSeconds));
            maxDurationSeconds = Math.Max(minDurationSeconds + 2, Math.Min(30, maxDurationSeconds));

            try {
                ServicePointManager.DefaultConnectionLimit = 128;
                ServicePointManager.Expect100Continue = false;
                ServicePointManager.UseNagleAlgorithm = false;
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | (SecurityProtocolType)3072;
            } catch { }

            long totalBytes = 0;
            long lastSampleBytes = 0;
            var sw = System.Diagnostics.Stopwatch.StartNew();
            var lastSampleTime = sw.Elapsed.TotalSeconds;

            List<double> recentMbps = new List<double>();
            byte[] uploadChunk = new byte[262144]; // 256KB upload chunk
            new Random().NextBytes(uploadChunk);
            int postPayloadSize = 10485760; // 10MB per POST

            Thread[] workers = new Thread[streams];
            for (int i = 0; i < streams; i++) {
                workers[i] = new Thread(() => {
                    while (!_cancelled && !_targetTimeReached) {
                        try {
                            string reqUrl = url + "?r=" + Guid.NewGuid().ToString("N");
                            var req = (HttpWebRequest)WebRequest.Create(reqUrl);
                            req.Method = "POST";
                            req.ContentType = "application/octet-stream";
                            req.ContentLength = postPayloadSize;
                            req.Headers.Add("Origin", "https://speed.cloudflare.com");
                            req.Referer = "https://speed.cloudflare.com/";
                            req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36";
                            req.Timeout = 8000;
                            req.ReadWriteTimeout = 8000;
                            req.Proxy = null;
                            req.AllowWriteStreamBuffering = false;
                            req.ServicePoint.Expect100Continue = false;
                            req.ServicePoint.UseNagleAlgorithm = false;
                            req.ServicePoint.ConnectionLimit = 128;

                            using (var reqStream = req.GetRequestStream()) {
                                int written = 0;
                                while (!_cancelled && !_targetTimeReached && written < postPayloadSize) {
                                    int toWrite = Math.Min(uploadChunk.Length, postPayloadSize - written);
                                    reqStream.Write(uploadChunk, 0, toWrite);
                                    written += toWrite;
                                    Interlocked.Add(ref totalBytes, toWrite);
                                }
                            }
                            using (var resp = req.GetResponse()) { }
                        } catch {
                            if (_cancelled || _targetTimeReached) break;
                            Thread.Sleep(25);
                        }
                    }
                }) { IsBackground = true };
                workers[i].Start();
            }

            while (!_cancelled && !_targetTimeReached) {
                Thread.Sleep(100);
                double currentElapsed = sw.Elapsed.TotalSeconds;
                double deltaT = currentElapsed - lastSampleTime;
                long curTotal = Interlocked.Read(ref totalBytes);
                long deltaBytes = curTotal - lastSampleBytes;

                if (deltaT > 0.08) {
                    double currentMbps = (deltaBytes * 8.0) / (deltaT * 1000000.0);
                    double avgMbps = (curTotal * 8.0) / (currentElapsed * 1000000.0);

                    lastSampleBytes = curTotal;
                    lastSampleTime = currentElapsed;

                    recentMbps.Add(currentMbps);
                    if (recentMbps.Count > 10) recentMbps.RemoveAt(0);

                    var sample = new SpeedSample {
                        CurrentMbps = currentMbps,
                        AverageMbps = avgMbps,
                        TotalBytesTransferred = curTotal,
                        ElapsedSeconds = currentElapsed,
                        Phase = "Upload",
                        IsFinished = false
                    };
                    CurrentSample = sample;
                    if (OnSpeedSample != null) {
                        try { OnSpeedSample(sample); } catch { }
                    }

                    // Adaptive test duration
                    if (currentElapsed >= minDurationSeconds) {
                        if (currentElapsed >= maxDurationSeconds) {
                            _targetTimeReached = true;
                            break;
                        }

                        if (recentMbps.Count >= 6) {
                            double mean = 0;
                            for (int m = 0; m < recentMbps.Count; m++) mean += recentMbps[m];
                            mean /= recentMbps.Count;

                            double variance = 0;
                            for (int m = 0; m < recentMbps.Count; m++) {
                                double diff = recentMbps[m] - mean;
                                variance += diff * diff;
                            }
                            double stdDev = Math.Sqrt(variance / recentMbps.Count);
                            double coeffOfVar = (mean > 0) ? (stdDev / mean) : 1.0;

                            if (coeffOfVar < 0.06) {
                                _targetTimeReached = true;
                                break;
                            }
                        }
                    }
                }
            }

            _targetTimeReached = true;
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
            CurrentSample = finalSample;
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
        public volatile bool IsRunning = false;
        public volatile bool IsFinished = false;
        public volatile BenchmarkProgress CurrentProgress = null;
        public volatile BenchmarkResult Result = null;

        public event Action<BenchmarkProgress> OnProgress;

        public void Cancel() {
            _cancelled = true;
            IsRunning = false;
        }

        public void StartBenchmark(string directoryPath, long fileSizeMb = 250) {
            IsRunning = true;
            IsFinished = false;
            Result = null;
            CurrentProgress = null;
            Thread t = new Thread(() => {
                Result = RunBenchmark(directoryPath, fileSizeMb);
                IsRunning = false;
                IsFinished = true;
            }) { IsBackground = true };
            t.Start();
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
            CurrentProgress = new BenchmarkProgress {
                CurrentTest = test,
                ProgressPercent = pct,
                CurrentSpeedMBs = mbSec,
                CurrentIops = iops
            };
            if (OnProgress != null) {
                try { OnProgress(CurrentProgress); } catch { }
            }
        }
    }

    // ==============================================================================
    // 7. Thread-Safe Diagnostic Process Runner Engine (with Windows Pseudo Console / ConPTY)
    // ==============================================================================
    public class ProcessRunnerEngine : IDisposable {
        private System.Diagnostics.Process _process;
        private readonly List<string> _outputQueue = new List<string>();
        private readonly object _lock = new object();
        private bool _hasExited = false;
        private int _exitCode = -1;
        private string _errorMessage = null;
        private Thread _outThread;
        private Thread _errThread;
        private Thread _monitorThread;

        // ConPTY state
        private bool _isConPty = false;
        private IntPtr _hProcess = IntPtr.Zero;
        private IntPtr _hThread = IntPtr.Zero;
        private IntPtr _hPC = IntPtr.Zero;
        private IntPtr _hPipeInWrite = IntPtr.Zero;
        private IntPtr _hPipeOutRead = IntPtr.Zero;

        // P/Invoke & Native Types for ConPTY
        private const int PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = 0x00020016;
        private const uint EXTENDED_STARTUPINFO_PRESENT = 0x00080000;
        private const uint INFINITE = 0xFFFFFFFF;
        private const uint WAIT_OBJECT_0 = 0x00000000;

        [StructLayout(LayoutKind.Sequential)]
        private struct COORD {
            public short X;
            public short Y;
            public COORD(short x, short y) { X = x; Y = y; }
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct STARTUPINFOEX {
            public STARTUPINFO StartupInfo;
            public IntPtr lpAttributeList;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct STARTUPINFO {
            public int cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public int dwX;
            public int dwY;
            public int dwXSize;
            public int dwYSize;
            public int dwXCountChars;
            public int dwYCountChars;
            public int dwFillAttribute;
            public int dwFlags;
            public short wShowWindow;
            public short cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct PROCESS_INFORMATION {
            public IntPtr hProcess;
            public IntPtr hThread;
            public int dwProcessId;
            public int dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct SECURITY_ATTRIBUTES {
            public int nLength;
            public IntPtr lpSecurityDescriptor;
            public int bInheritHandle;
        }

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern int CreatePseudoConsole(COORD size, IntPtr hInput, IntPtr hOutput, uint flags, out IntPtr phPC);

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern void ClosePseudoConsole(IntPtr hPC);

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern bool CreatePipe(out IntPtr hReadPipe, out IntPtr hWritePipe, ref SECURITY_ATTRIBUTES lpPipeAttributes, int nSize);

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern bool InitializeProcThreadAttributeList(IntPtr lpAttributeList, int dwAttributeCount, int dwFlags, ref IntPtr lpSize);

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern bool UpdateProcThreadAttribute(IntPtr lpAttributeList, uint dwFlags, IntPtr Attribute, IntPtr lpValue, IntPtr cbSize, IntPtr lpPreviousValue, IntPtr lpReturnSize);

        [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
        private static extern bool DeleteProcThreadAttributeList(IntPtr lpAttributeList);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool CreateProcess(
            string lpApplicationName,
            StringBuilder lpCommandLine,
            ref SECURITY_ATTRIBUTES lpProcessAttributes,
            ref SECURITY_ATTRIBUTES lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            ref STARTUPINFOEX lpStartupInfo,
            out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetExitCodeProcess(IntPtr hProcess, out int lpExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool TerminateProcess(IntPtr hProcess, uint uExitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

        public bool IsRunning {
            get {
                lock (_lock) {
                    if (_hasExited) return false;
                    if (_isConPty) {
                        if (_hProcess == IntPtr.Zero) return false;
                        uint res = WaitForSingleObject(_hProcess, 0);
                        if (res == WAIT_OBJECT_0) {
                            _hasExited = true;
                            int ec;
                            if (GetExitCodeProcess(_hProcess, out ec)) {
                                _exitCode = ec;
                            }
                            return false;
                        }
                        return true;
                    }
                    if (_process == null) return false;
                    try {
                        return !_process.HasExited;
                    } catch {
                        return false;
                    }
                }
            }
        }

        public bool HasExited {
            get {
                lock (_lock) {
                    if (_hasExited) return true;
                    if (_isConPty) {
                        if (_hProcess == IntPtr.Zero) return true;
                        uint res = WaitForSingleObject(_hProcess, 0);
                        if (res == WAIT_OBJECT_0) {
                            _hasExited = true;
                            int ec;
                            if (GetExitCodeProcess(_hProcess, out ec)) {
                                _exitCode = ec;
                            }
                            return true;
                        }
                        return false;
                    }
                    if (_process == null) return false;
                    try {
                        if (_process.HasExited) {
                            _hasExited = true;
                            _exitCode = _process.ExitCode;
                        }
                    } catch { }
                    return _hasExited;
                }
            }
        }

        public int ExitCode {
            get {
                lock (_lock) {
                    return _exitCode;
                }
            }
        }

        public string ErrorMessage {
            get { return _errorMessage; }
        }

        public bool Start(string fileName, string arguments, bool isPowerShellScript = false) {
            Dispose();
            lock (_lock) {
                _outputQueue.Clear();
                _hasExited = false;
                _exitCode = -1;
                _errorMessage = null;
                _isConPty = false;
            }

            string resolvedFileName = fileName;
            if (!string.IsNullOrEmpty(fileName)) {
                string lower = fileName.ToLowerInvariant();
                if (lower == "sfc.exe" || lower == "sfc" || lower == "chkdsk.exe" || lower == "chkdsk" || lower == "dism.exe" || lower == "dism") {
                    string exeName = Path.GetFileName(fileName);
                    if (!exeName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)) exeName += ".exe";
                    string winDir = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
                    string sysNative = Path.Combine(winDir, "Sysnative", exeName);
                    if (Environment.Is64BitOperatingSystem && !Environment.Is64BitProcess && File.Exists(sysNative)) {
                        resolvedFileName = sysNative;
                    } else {
                        string system32 = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), exeName);
                        if (File.Exists(system32)) {
                            resolvedFileName = system32;
                        }
                    }
                }
            }

            string commandLine;
            if (isPowerShellScript) {
                commandLine = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"" + arguments + "\"";
            } else {
                commandLine = "\"" + resolvedFileName + "\" " + (arguments ?? "");
            }

            // Try Windows Pseudo Console (ConPTY) first for real-time unbuffered character-mode streaming
            bool conPtySuccess = false;
            try {
                if (Environment.OSVersion.Platform == PlatformID.Win32NT && Environment.OSVersion.Version.Major >= 10) {
                    conPtySuccess = StartConPty(commandLine);
                }
            } catch {
                conPtySuccess = false;
            }

            if (conPtySuccess) {
                return true;
            }

            // Fallback to standard System.Diagnostics.Process if ConPTY is not available
            return StartFallbackProcess(resolvedFileName, arguments, isPowerShellScript);
        }

        private bool StartConPty(string commandLine) {
            SECURITY_ATTRIBUTES sa = new SECURITY_ATTRIBUTES();
            sa.nLength = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
            sa.bInheritHandle = 0;
            sa.lpSecurityDescriptor = IntPtr.Zero;

            IntPtr hPipeInRead = IntPtr.Zero;
            IntPtr hPipeInWrite = IntPtr.Zero;
            IntPtr hPipeOutRead = IntPtr.Zero;
            IntPtr hPipeOutWrite = IntPtr.Zero;

            if (!CreatePipe(out hPipeInRead, out hPipeInWrite, ref sa, 0)) {
                return false;
            }
            if (!CreatePipe(out hPipeOutRead, out hPipeOutWrite, ref sa, 0)) {
                CloseHandle(hPipeInRead);
                CloseHandle(hPipeInWrite);
                return false;
            }

            COORD coord = new COORD(120, 30);
            IntPtr hPC = IntPtr.Zero;
            int hr = CreatePseudoConsole(coord, hPipeInRead, hPipeOutWrite, 0, out hPC);

            // Close child side pipe handles as the pseudo console now references them
            CloseHandle(hPipeInRead);
            CloseHandle(hPipeOutWrite);

            if (hr != 0 || hPC == IntPtr.Zero) {
                CloseHandle(hPipeInWrite);
                CloseHandle(hPipeOutRead);
                return false;
            }

            IntPtr lpSize = IntPtr.Zero;
            InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref lpSize);

            IntPtr lpAttributeList = Marshal.AllocHGlobal(lpSize);
            if (!InitializeProcThreadAttributeList(lpAttributeList, 1, 0, ref lpSize)) {
                Marshal.FreeHGlobal(lpAttributeList);
                ClosePseudoConsole(hPC);
                CloseHandle(hPipeInWrite);
                CloseHandle(hPipeOutRead);
                return false;
            }

            if (!UpdateProcThreadAttribute(
                    lpAttributeList,
                    0,
                    (IntPtr)PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE,
                    hPC,
                    (IntPtr)IntPtr.Size,
                    IntPtr.Zero,
                    IntPtr.Zero)) {
                DeleteProcThreadAttributeList(lpAttributeList);
                Marshal.FreeHGlobal(lpAttributeList);
                ClosePseudoConsole(hPC);
                CloseHandle(hPipeInWrite);
                CloseHandle(hPipeOutRead);
                return false;
            }

            STARTUPINFOEX siex = new STARTUPINFOEX();
            siex.StartupInfo.cb = Marshal.SizeOf(typeof(STARTUPINFOEX));
            siex.lpAttributeList = lpAttributeList;

            SECURITY_ATTRIBUTES saProc = new SECURITY_ATTRIBUTES();
            saProc.nLength = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
            SECURITY_ATTRIBUTES saThread = new SECURITY_ATTRIBUTES();
            saThread.nLength = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));

            PROCESS_INFORMATION pi = new PROCESS_INFORMATION();
            bool success = CreateProcess(
                null,
                new StringBuilder(commandLine),
                ref saProc,
                ref saThread,
                false,
                EXTENDED_STARTUPINFO_PRESENT,
                IntPtr.Zero,
                null,
                ref siex,
                out pi);

            DeleteProcThreadAttributeList(lpAttributeList);
            Marshal.FreeHGlobal(lpAttributeList);

            if (!success) {
                ClosePseudoConsole(hPC);
                CloseHandle(hPipeInWrite);
                CloseHandle(hPipeOutRead);
                return false;
            }

            lock (_lock) {
                _hProcess = pi.hProcess;
                _hThread = pi.hThread;
                _hPC = hPC;
                _hPipeInWrite = hPipeInWrite;
                _hPipeOutRead = hPipeOutRead;
                _isConPty = true;
            }

            var safeHandle = new Microsoft.Win32.SafeHandles.SafeFileHandle(hPipeOutRead, false);
            var stream = new FileStream(safeHandle, FileAccess.Read, 4096, false);

            _outThread = new Thread(() => ReadStreamWithAnsiFilter(stream, Encoding.UTF8)) {
                IsBackground = true,
                Name = "HMT_ProcRunner_ConPtyOut"
            };
            _outThread.Start();

            _monitorThread = new Thread(MonitorConPtyProcess) {
                IsBackground = true,
                Name = "HMT_ProcRunner_ConPtyMonitor"
            };
            _monitorThread.Start();

            return true;
        }

        private void MonitorConPtyProcess() {
            IntPtr hProc;
            lock (_lock) { hProc = _hProcess; }
            if (hProc == IntPtr.Zero) return;

            try {
                WaitForSingleObject(hProc, INFINITE);
                int ec = -1;
                if (GetExitCodeProcess(hProc, out ec)) {
                    lock (_lock) {
                        _exitCode = ec;
                    }
                }
            } catch { }
            finally {
                lock (_lock) {
                    _hasExited = true;
                }
                CleanupConPtyResources();
            }
        }

        private void CleanupConPtyResources() {
            lock (_lock) {
                if (_hPC != IntPtr.Zero) {
                    try { ClosePseudoConsole(_hPC); } catch { }
                    _hPC = IntPtr.Zero;
                }
                if (_hPipeInWrite != IntPtr.Zero) {
                    try { CloseHandle(_hPipeInWrite); } catch { }
                    _hPipeInWrite = IntPtr.Zero;
                }
                if (_hPipeOutRead != IntPtr.Zero) {
                    try { CloseHandle(_hPipeOutRead); } catch { }
                    _hPipeOutRead = IntPtr.Zero;
                }
                if (_hThread != IntPtr.Zero) {
                    try { CloseHandle(_hThread); } catch { }
                    _hThread = IntPtr.Zero;
                }
                if (_hProcess != IntPtr.Zero) {
                    try { CloseHandle(_hProcess); } catch { }
                    _hProcess = IntPtr.Zero;
                }
            }
        }

        private bool StartFallbackProcess(string fileName, string arguments, bool isPowerShellScript) {
            try {
                var psi = new System.Diagnostics.ProcessStartInfo();
                if (isPowerShellScript) {
                    psi.FileName = "powershell.exe";
                    psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"" + arguments + "\"";
                } else {
                    psi.FileName = fileName;
                    psi.Arguments = arguments ?? "";
                }
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                psi.RedirectStandardError = true;
                try {
                    psi.StandardOutputEncoding = Console.OutputEncoding ?? Encoding.Default;
                    psi.StandardErrorEncoding = Console.OutputEncoding ?? Encoding.Default;
                } catch {
                    psi.StandardOutputEncoding = Encoding.Default;
                    psi.StandardErrorEncoding = Encoding.Default;
                }
                psi.CreateNoWindow = true;

                _process = new System.Diagnostics.Process();
                _process.StartInfo = psi;
                _process.EnableRaisingEvents = true;

                _process.Exited += (s, e) => {
                    lock (_lock) {
                        _hasExited = true;
                        try {
                            _exitCode = _process.ExitCode;
                        } catch { }
                    }
                };

                bool started = _process.Start();
                if (started) {
                    Encoding outEnc = psi.StandardOutputEncoding ?? Encoding.Default;
                    Encoding errEnc = psi.StandardErrorEncoding ?? Encoding.Default;

                    _outThread = new Thread(() => ReadStreamWithAnsiFilter(_process.StandardOutput.BaseStream, outEnc)) {
                        IsBackground = true,
                        Name = "HMT_ProcRunner_StdOut"
                    };
                    _outThread.Start();

                    _errThread = new Thread(() => ReadStreamWithAnsiFilter(_process.StandardError.BaseStream, errEnc)) {
                        IsBackground = true,
                        Name = "HMT_ProcRunner_StdErr"
                    };
                    _errThread.Start();
                }
                return started;
            } catch (Exception ex) {
                _errorMessage = ex.Message;
                _hasExited = true;
                _exitCode = -1;
                return false;
            }
        }

        private void ReadStreamWithAnsiFilter(Stream stream, Encoding encoding) {
            if (stream == null) return;
            var sb = new StringBuilder();
            byte[] buffer = new byte[512];
            char[] chars = new char[512];
            Decoder decoder = (encoding ?? Encoding.Default).GetDecoder();
            int bytesRead;
            int ansiState = 0; // 0=normal, 1=ESC, 2=CSI, 3=OSC, 4=Charset/2byte
            bool wasOsc = false;

            try {
                using (stream) {
                    while ((bytesRead = stream.Read(buffer, 0, buffer.Length)) > 0) {
                        int charCount = decoder.GetChars(buffer, 0, bytesRead, chars, 0);
                        for (int i = 0; i < charCount; i++) {
                            char c = chars[i];

                            if (ansiState == 0) {
                                if (c == '\x1B') {
                                    ansiState = 1;
                                } else if (c == '\r' || c == '\n') {
                                    if (sb.Length > 0) {
                                        string line = sb.ToString().Trim();
                                        sb.Length = 0;
                                        if (!string.IsNullOrEmpty(line)) {
                                            lock (_lock) {
                                                _outputQueue.Add(line);
                                            }
                                        }
                                    }
                                } else if (c != '\0' && c != '\b' && c != '\a') {
                                    sb.Append(c);
                                }
                            } else if (ansiState == 1) {
                                if (c == '[') {
                                    ansiState = 2; // CSI sequence
                                } else if (c == ']') {
                                    ansiState = 3; // OSC sequence
                                    wasOsc = true;
                                } else if (c == '(' || c == ')' || c == '*' || c == '+' || c == '#' || c == '%') {
                                    ansiState = 4; // Charset / 2-byte escape
                                } else if (c == '\\' && wasOsc) {
                                    ansiState = 0; // String terminator
                                    wasOsc = false;
                                } else {
                                    ansiState = 0; // Other 2-byte escape
                                }
                            } else if (ansiState == 2) {
                                // In CSI sequence, parameters are 0x20-0x3F, command terminates on 0x40-0x7E
                                if (c >= 0x40 && c <= 0x7E) {
                                    ansiState = 0;
                                }
                            } else if (ansiState == 3) {
                                // In OSC sequence, ends on BEL (\a) or ESC
                                if (c == '\a') {
                                    ansiState = 0;
                                    wasOsc = false;
                                } else if (c == '\x1B') {
                                    ansiState = 1;
                                }
                            } else if (ansiState == 4) {
                                ansiState = 0;
                            }
                        }
                    }
                }
                if (sb.Length > 0) {
                    string line = sb.ToString().Trim();
                    if (!string.IsNullOrEmpty(line)) {
                        lock (_lock) {
                            _outputQueue.Add(line);
                        }
                    }
                }
            } catch { }
        }

        public string[] DrainOutput() {
            lock (_lock) {
                if (_outputQueue.Count == 0) return new string[0];
                string[] lines = _outputQueue.ToArray();
                _outputQueue.Clear();
                return lines;
            }
        }

        public void Kill() {
            lock (_lock) {
                if (_isConPty) {
                    if (_hProcess != IntPtr.Zero) {
                        try { TerminateProcess(_hProcess, 1); } catch { }
                    }
                    if (_hPC != IntPtr.Zero) {
                        try { ClosePseudoConsole(_hPC); } catch { }
                        _hPC = IntPtr.Zero;
                    }
                    _hasExited = true;
                } else if (_process != null) {
                    try {
                        if (!_process.HasExited) {
                            _process.Kill();
                        }
                    } catch { }
                    _hasExited = true;
                }
            }
        }

        public void Dispose() {
            Kill();
            CleanupConPtyResources();
            if (_process != null) {
                try { _process.Dispose(); } catch { }
                _process = null;
            }
        }
    }

    // ==============================================================================
    // 12. High-Speed Native Startup & Autoruns Scanner
    // ==============================================================================
    public class StartupItem {
        public string Name { get; set; }
        public string Category { get; set; }
        public string Command { get; set; }
        public string Location { get; set; }
        public string Type { get; set; } // "Registry", "File", "Task", "Winlogon", "Service"
        public string RegPath { get; set; }
        public string ApprPath { get; set; }
        public string FilePath { get; set; }
        public string TaskName { get; set; }
        public string TaskPath { get; set; }
        public string ServiceName { get; set; }
        public string Status { get; set; } // "Enabled", "Disabled"
    }

    public static class StartupScanner {
        private static string CheckStartupApproved(RegistryKey rootKey, string apprSubKey, string valName) {
            try {
                using (var key = rootKey.OpenSubKey(apprSubKey, false)) {
                    if (key != null) {
                        byte[] bytes = key.GetValue(valName) as byte[];
                        if (bytes != null && bytes.Length > 0) {
                            if (bytes[0] == 0x03 || bytes[0] == 0x01) {
                                return "Disabled";
                            }
                        }
                    }
                }
            } catch { }
            return "Enabled";
        }

        public static List<StartupItem> ScanAll() {
            var items = new List<StartupItem>();

            // 1. HKCU Run
            try {
                string runSubKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
                string apprSubKey = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run";
                using (var key = Registry.CurrentUser.OpenSubKey(runSubKey, false)) {
                    if (key != null) {
                        foreach (var name in key.GetValueNames()) {
                            string cmd = Convert.ToString(key.GetValue(name));
                            string st = CheckStartupApproved(Registry.CurrentUser, apprSubKey, name);
                            items.Add(new StartupItem {
                                Name = name,
                                Category = "Registry Run",
                                Command = cmd,
                                Location = "HKCU Run",
                                Type = "Registry",
                                RegPath = @"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
                                ApprPath = @"HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
                                Status = st
                            });
                        }
                    }
                }
            } catch { }

            // 2. HKLM Run
            try {
                string runSubKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
                string apprSubKey = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run";
                using (var key = Registry.LocalMachine.OpenSubKey(runSubKey, false)) {
                    if (key != null) {
                        foreach (var name in key.GetValueNames()) {
                            string cmd = Convert.ToString(key.GetValue(name));
                            string st = CheckStartupApproved(Registry.LocalMachine, apprSubKey, name);
                            items.Add(new StartupItem {
                                Name = name,
                                Category = "Registry Run",
                                Command = cmd,
                                Location = "HKLM Run",
                                Type = "Registry",
                                RegPath = @"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
                                ApprPath = @"HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run",
                                Status = st
                            });
                        }
                    }
                }
            } catch { }

            // 3. HKLM WOW6432Node Run
            try {
                string run32SubKey = @"Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run";
                string appr32SubKey = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32";
                using (var key = Registry.LocalMachine.OpenSubKey(run32SubKey, false)) {
                    if (key != null) {
                        foreach (var name in key.GetValueNames()) {
                            string cmd = Convert.ToString(key.GetValue(name));
                            string st = CheckStartupApproved(Registry.LocalMachine, appr32SubKey, name);
                            items.Add(new StartupItem {
                                Name = name,
                                Category = "Registry Run",
                                Command = cmd,
                                Location = "HKLM Run (32-bit)",
                                Type = "Registry",
                                RegPath = @"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
                                ApprPath = @"HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32",
                                Status = st
                            });
                        }
                    }
                }
            } catch { }

            // 4. User Startup Folder
            try {
                string userDir = Environment.GetFolderPath(Environment.SpecialFolder.Startup);
                string apprFolder = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder";
                if (!string.IsNullOrEmpty(userDir) && Directory.Exists(userDir)) {
                    foreach (var file in Directory.GetFiles(userDir)) {
                        string fn = Path.GetFileName(file);
                        bool isDis = fn.EndsWith(".disabled", StringComparison.OrdinalIgnoreCase);
                        string st = isDis ? "Disabled" : CheckStartupApproved(Registry.CurrentUser, apprFolder, fn);
                        items.Add(new StartupItem {
                            Name = fn,
                            Category = "Startup Folder",
                            Command = file,
                            Location = "User Startup Folder",
                            Type = "File",
                            FilePath = file,
                            ApprPath = @"HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
                            Status = st
                        });
                    }
                }
            } catch { }

            // 5. Common Startup Folder
            try {
                string commonDir = Environment.GetFolderPath(Environment.SpecialFolder.CommonStartup);
                string apprFolder = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder";
                if (!string.IsNullOrEmpty(commonDir) && Directory.Exists(commonDir)) {
                    foreach (var file in Directory.GetFiles(commonDir)) {
                        string fn = Path.GetFileName(file);
                        bool isDis = fn.EndsWith(".disabled", StringComparison.OrdinalIgnoreCase);
                        string st = isDis ? "Disabled" : CheckStartupApproved(Registry.LocalMachine, apprFolder, fn);
                        items.Add(new StartupItem {
                            Name = fn,
                            Category = "Startup Folder",
                            Command = file,
                            Location = "All Users Startup Folder",
                            Type = "File",
                            FilePath = file,
                            ApprPath = @"HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder",
                            Status = st
                        });
                    }
                }
            } catch { }

            // 6. Shell & Winlogon
            try {
                string wlSubKey = @"Software\Microsoft\Windows NT\CurrentVersion\Winlogon";
                using (var key = Registry.LocalMachine.OpenSubKey(wlSubKey, false)) {
                    if (key != null) {
                        string userinit = Convert.ToString(key.GetValue("Userinit"));
                        if (!string.IsNullOrEmpty(userinit)) {
                            items.Add(new StartupItem {
                                Name = "Userinit",
                                Category = "Shell / Winlogon",
                                Command = userinit,
                                Location = "HKLM Winlogon",
                                Type = "Winlogon",
                                RegPath = @"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon",
                                Status = "Enabled"
                            });
                        }
                        string shell = Convert.ToString(key.GetValue("Shell"));
                        if (!string.IsNullOrEmpty(shell) && !shell.Equals("explorer.exe", StringComparison.OrdinalIgnoreCase)) {
                            items.Add(new StartupItem {
                                Name = "Custom Shell",
                                Category = "Shell / Winlogon",
                                Command = shell,
                                Location = "HKLM Winlogon",
                                Type = "Winlogon",
                                RegPath = @"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon",
                                Status = "Enabled"
                            });
                        }
                    }
                }
            } catch { }

            // 7. Auto-start Services from Registry
            try {
                using (var servicesKey = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services", false)) {
                    if (servicesKey != null) {
                        foreach (var svcName in servicesKey.GetSubKeyNames()) {
                            try {
                                using (var svcKey = servicesKey.OpenSubKey(svcName, false)) {
                                    if (svcKey != null) {
                                        object startVal = svcKey.GetValue("Start");
                                        if (startVal != null && (int)startVal == 2) {
                                            string imagePath = Convert.ToString(svcKey.GetValue("ImagePath"));
                                            if (!string.IsNullOrEmpty(imagePath)) {
                                                if (imagePath.IndexOf("system32\\svchost.exe", StringComparison.OrdinalIgnoreCase) < 0 &&
                                                    imagePath.IndexOf("system32\\lsass.exe", StringComparison.OrdinalIgnoreCase) < 0 &&
                                                    imagePath.IndexOf("system32\\services.exe", StringComparison.OrdinalIgnoreCase) < 0) {
                                                    
                                                    string dispName = Convert.ToString(svcKey.GetValue("DisplayName"));
                                                    if (string.IsNullOrEmpty(dispName)) dispName = svcName;

                                                    items.Add(new StartupItem {
                                                        Name = dispName,
                                                        Category = "Startup Service",
                                                        Command = imagePath,
                                                        Location = "Services (" + svcName + ")",
                                                        Type = "Service",
                                                        ServiceName = svcName,
                                                        Status = "Enabled"
                                                    });
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch { }
                        }
                    }
                }
            } catch { }

            return items;
        }
    }
}
