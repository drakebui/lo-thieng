<#
.SYNOPSIS
    Lò Thiêng 32-Bit Pixel Art & Movable Sprite-Sheet Pipeline (Model-Agnostic CLI)
.DESCRIPTION
    Deterministic C#-accelerated pipeline for converting raw/AI images into 32-bit Hoả Tâm Pixel Art:
    - Enforces the 96-color Hoả Tâm Master Palette (no pure #000000 outlines, warm firelight & wood ramps).
    - Removes #FF00FF magenta chroma-key or uniform corner backgrounds with fringe suppression.
    - Generates 4x4 (256x256, 64x64/cell) movable character sprite sheets (Row 0: idle, Row 1: walk, Row 2: attack, Row 3: hurt)
      with locked foot baselines so characters can walk in WorkshopHub, ShopScene, and ExplorationScene, and fight in CombatScene.
    - Converts existing 4x8 grid sheets (e.g. sprite sheet_Nấm.png) into 64x64/cell 32-bit pixel art sheets.
    - Pixelizes 16:9 room/combat backgrounds into crisp 640x360 (exact 3x integer scale to 1920x1080).
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("sheetFromSingle", "sheetFromGrid", "player4Dir", "background", "validate", "demoBatch")]
    [string]$Mode = "demoBatch",

    [Parameter(Mandatory=$false)]
    [string]$FrontPath = "",

    [Parameter(Mandatory=$false)]
    [string]$BackPath = "",

    [Parameter(Mandatory=$false)]
    [string]$SideSheetPath = "",

    [Parameter(Mandatory=$false)]
    [string]$WalkDownStrip = "",

    [Parameter(Mandatory=$false)]
    [string]$WalkUpStrip = "",

    [Parameter(Mandatory=$false)]
    [string]$WalkRightStrip = "",

    [Parameter(Mandatory=$false)]
    [string]$InputPath = "",

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",

    [Parameter(Mandatory=$false)]
    [int]$CellSize = 64,

    [Parameter(Mandatory=$false)]
    [int]$TargetW = 640,

    [Parameter(Mandatory=$false)]
    [int]$TargetH = 360,

    [Parameter(Mandatory=$false)]
    [int]$FacingSign = 1 # +1 if facing right (Player/NPC walk default), -1 if facing left (Combat enemy default)
)

Add-Type -AssemblyName System.Drawing

$csharpPipeline = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class HoaTam32Bit
{
    // 96-color Hoả Tâm 32-Bit Master Palette
    public static readonly Color[] Palette = new Color[]
    {
        // 0..7: Deep plum-ink outline & warm shadow ramp (NO pure #000000)
        Color.FromArgb(18, 12, 16), Color.FromArgb(28, 18, 20), Color.FromArgb(38, 24, 24), Color.FromArgb(50, 32, 28),
        Color.FromArgb(64, 40, 32), Color.FromArgb(78, 48, 36), Color.FromArgb(94, 58, 42), Color.FromArgb(110, 68, 48),
        // 8..19: Warm Timber, Oak & Parchment ramp
        Color.FromArgb(68, 38, 22), Color.FromArgb(86, 48, 28), Color.FromArgb(104, 60, 34), Color.FromArgb(122, 72, 40),
        Color.FromArgb(140, 86, 48), Color.FromArgb(158, 100, 56), Color.FromArgb(176, 116, 66), Color.FromArgb(194, 134, 78),
        Color.FromArgb(212, 154, 94), Color.FromArgb(226, 176, 118), Color.FromArgb(238, 202, 150), Color.FromArgb(250, 232, 198),
        // 20..31: Forge Fire, Ember, Amber & Molten Gold ramp
        Color.FromArgb(76, 18, 16), Color.FromArgb(104, 26, 20), Color.FromArgb(134, 36, 24), Color.FromArgb(164, 48, 28),
        Color.FromArgb(192, 64, 32), Color.FromArgb(216, 86, 36), Color.FromArgb(234, 112, 40), Color.FromArgb(244, 140, 46),
        Color.FromArgb(250, 168, 56), Color.FromArgb(252, 198, 72), Color.FromArgb(254, 224, 112), Color.FromArgb(255, 246, 180),
        // 32..43: Stone Masonry, Iron, Anvil Steel & Ash ramp
        Color.FromArgb(32, 32, 40), Color.FromArgb(44, 44, 52), Color.FromArgb(58, 56, 66), Color.FromArgb(72, 70, 80),
        Color.FromArgb(88, 84, 94), Color.FromArgb(104, 100, 108), Color.FromArgb(122, 118, 124), Color.FromArgb(142, 136, 140),
        Color.FromArgb(164, 158, 158), Color.FromArgb(186, 180, 176), Color.FromArgb(208, 204, 198), Color.FromArgb(232, 228, 220),
        // 44..53: Indigo Quilt, Slate, Evening Shadow & Cool Daylight
        Color.FromArgb(22, 26, 44), Color.FromArgb(32, 40, 64), Color.FromArgb(44, 56, 86), Color.FromArgb(58, 74, 108),
        Color.FromArgb(74, 94, 132), Color.FromArgb(94, 118, 156), Color.FromArgb(118, 144, 180), Color.FromArgb(146, 172, 204),
        Color.FromArgb(178, 202, 226), Color.FromArgb(214, 230, 244),
        // 54..63: Crimson Rug, Terracotta, Leather & Brick Red
        Color.FromArgb(68, 22, 24), Color.FromArgb(92, 30, 30), Color.FromArgb(116, 40, 38), Color.FromArgb(140, 52, 46),
        Color.FromArgb(164, 66, 56), Color.FromArgb(186, 84, 68), Color.FromArgb(204, 104, 82), Color.FromArgb(220, 128, 102),
        Color.FromArgb(234, 156, 128), Color.FromArgb(244, 188, 162),
        // 64..73: Plum, Twilight Purple & Royal Silk
        Color.FromArgb(34, 20, 40), Color.FromArgb(48, 30, 56), Color.FromArgb(64, 42, 72), Color.FromArgb(82, 54, 90),
        Color.FromArgb(102, 68, 108), Color.FromArgb(124, 86, 128), Color.FromArgb(148, 108, 148), Color.FromArgb(174, 134, 170),
        Color.FromArgb(200, 166, 194), Color.FromArgb(226, 202, 218),
        // 74..83: Foliage, Moss, Bamboo & Grassland Greens
        Color.FromArgb(24, 40, 28), Color.FromArgb(36, 58, 38), Color.FromArgb(50, 76, 46), Color.FromArgb(66, 96, 54),
        Color.FromArgb(86, 118, 64), Color.FromArgb(108, 142, 74), Color.FromArgb(132, 166, 86), Color.FromArgb(158, 190, 102),
        Color.FromArgb(186, 212, 124), Color.FromArgb(214, 232, 156),
        // 84..95: Brass, Ochre, Olive Khaki & Fur Neutrals
        Color.FromArgb(54, 46, 34), Color.FromArgb(72, 62, 46), Color.FromArgb(92, 80, 58), Color.FromArgb(112, 98, 72),
        Color.FromArgb(134, 118, 86), Color.FromArgb(156, 138, 102), Color.FromArgb(178, 160, 120), Color.FromArgb(200, 182, 140),
        Color.FromArgb(148, 112, 36), Color.FromArgb(180, 140, 46), Color.FromArgb(212, 172, 60), Color.FromArgb(240, 206, 84)
    };

    private static readonly int[,] Bayer2 = new int[,] { { -3, 1 }, { 3, -1 } };

    public static Color NearestPalette(int r, int g, int b)
    {
        int bestIdx = 0;
        double bestDist = double.MaxValue;
        for (int i = 0; i < Palette.Length; i++)
        {
            Color p = Palette[i];
            double dr = r - p.R, dg = g - p.G, db = b - p.B;
            double rmean = (r + p.R) * 0.5;
            double dist = ((2.0 + rmean / 256.0) * dr * dr) + (4.0 * dg * dg) + ((2.0 + (255.0 - rmean) / 256.0) * db * db);
            if (dist < bestDist) { bestDist = dist; bestIdx = i; }
        }
        return Palette[bestIdx];
    }

    private static bool IsMagentaKey(Color c)
    {
        return (c.R > 160 && c.B > 150 && c.G < 118 && (c.R - c.G) > 65 && (c.B - c.G) > 55);
    }

    public static Bitmap CleanAlphaAndChroma(Bitmap src)
    {
        int w = src.Width, h = src.Height;
        Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        bool[,] visited = new bool[w, h];
        bool[,] isBg = new bool[w, h];
        Queue<Point> q = new Queue<Point>();

        Color corner = src.GetPixel(1, 1);
        bool cornerIsMagenta = IsMagentaKey(corner);
        bool cornerIsOpaqueUniform = (!cornerIsMagenta && corner.A > 240);

        Action<int, int> enq = (x, y) => {
            if (x < 0 || x >= w || y < 0 || y >= h || visited[x, y]) return;
            Color c = src.GetPixel(x, y);
            bool match = (c.A < 165) || IsMagentaKey(c);
            if (!match && cornerIsOpaqueUniform)
            {
                int diff = Math.Abs(c.R - corner.R) + Math.Abs(c.G - corner.G) + Math.Abs(c.B - corner.B);
                if (diff <= 28) match = true;
            }
            if (match)
            {
                visited[x, y] = true;
                isBg[x, y] = true;
                q.Enqueue(new Point(x, y));
            }
        };

        for (int x = 0; x < w; x++) { enq(x, 0); enq(x, h - 1); }
        for (int y = 0; y < h; y++) { enq(0, y); enq(w - 1, y); }

        while (q.Count > 0)
        {
            Point pt = q.Dequeue();
            enq(pt.X + 1, pt.Y); enq(pt.X - 1, pt.Y);
            enq(pt.X, pt.Y + 1); enq(pt.X, pt.Y - 1);
        }

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                Color c = src.GetPixel(x, y);
                if (isBg[x, y] || c.A < 175 || IsMagentaKey(c))
                {
                    dst.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                }
                else
                {
                    // Suppress 2px magenta spill around chroma edges
                    bool nearBg = false;
                    for (int dy = -2; dy <= 2 && !nearBg; dy++)
                        for (int dx = -2; dx <= 2 && !nearBg; dx++)
                        {
                            int nx = x + dx, ny = y + dy;
                            if (nx >= 0 && nx < w && ny >= 0 && ny < h && isBg[nx, ny]) nearBg = true;
                        }
                    if (nearBg && c.R > 120 && c.B > 110 && c.G < 95 && (c.R + c.B) > c.G * 2 + 80)
                        dst.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                    else
                        dst.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
                }
            }
        }
        return dst;
    }

    public static Rectangle FindBounds(Bitmap bmp, int x0, int y0, int w, int h)
    {
        int minX = x0 + w, minY = y0 + h, maxX = x0 - 1, maxY = y0 - 1;
        for (int y = y0; y < y0 + h; y++)
            for (int x = x0; x < x0 + w; x++)
                if (bmp.GetPixel(x, y).A >= 175)
                {
                    if (x < minX) minX = x; if (y < minY) minY = y;
                    if (x > maxX) maxX = x; if (y > maxY) maxY = y;
                }
        if (maxX < minX || maxY < minY) return Rectangle.Empty;
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }

    public static Bitmap SealOutline(Bitmap src)
    {
        int w = src.Width, h = src.Height;
        Color outline = Palette[0];
        Bitmap dst = (Bitmap)src.Clone();
        // Flood-fill exterior transparent pixels from frame borders so internal pinholes are NEVER outlined
        bool[,] ext = new bool[w, h];
        Queue<Point> q = new Queue<Point>();
        Action<int, int> enq = (x, y) => {
            if (x < 0 || x >= w || y < 0 || y >= h || ext[x, y]) return;
            if (src.GetPixel(x, y).A == 0) { ext[x, y] = true; q.Enqueue(new Point(x, y)); }
        };
        for (int x = 0; x < w; x++) { enq(x, 0); enq(x, h - 1); }
        for (int y = 0; y < h; y++) { enq(0, y); enq(w - 1, y); }
        while (q.Count > 0)
        {
            Point p = q.Dequeue();
            enq(p.X + 1, p.Y); enq(p.X - 1, p.Y); enq(p.X, p.Y + 1); enq(p.X, p.Y - 1);
        }

        int[] dx = { -1, 1, 0, 0 };
        int[] dy = { 0, 0, -1, 1 };
        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                if (!ext[x, y]) continue;
                for (int k = 0; k < 4; k++)
                {
                    int nx = x + dx[k], ny = y + dy[k];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h && src.GetPixel(nx, ny).A > 0)
                    {
                        dst.SetPixel(x, y, outline);
                        break;
                    }
                }
            }
        }
        return dst;
    }

    // Downscale a single cropped region to targetW x targetH WITHOUT outline yet (so skeletal animator can deform cleanly before sealing outline)
    public static Bitmap PixelizeCore(Bitmap src, Rectangle crop, int targetW, int targetH, int padTop, int padBottom, int padSides)
    {
        Bitmap dst = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb);
        if (crop.IsEmpty) return dst;

        int innerW = Math.Max(4, targetW - padSides * 2);
        int innerH = Math.Max(4, targetH - padTop - padBottom);
        double scale = Math.Min((double)innerW / crop.Width, (double)innerH / crop.Height);
        int drawW = Math.Max(1, (int)Math.Round(crop.Width * scale));
        int drawH = Math.Max(1, (int)Math.Round(crop.Height * scale));
        int ox = (targetW - drawW) / 2;
        int oy = targetH - padBottom - drawH;

        for (int ty = 0; ty < drawH; ty++)
        {
            for (int tx = 0; tx < drawW; tx++)
            {
                int sx0 = Math.Max(crop.X, (int)Math.Floor(crop.X + tx / scale));
                int sy0 = Math.Max(crop.Y, (int)Math.Floor(crop.Y + ty / scale));
                int sx1 = Math.Min(crop.Right - 1, Math.Max(sx0, (int)Math.Ceiling(crop.X + (tx + 1) / scale) - 1));
                int sy1 = Math.Min(crop.Bottom - 1, Math.Max(sy0, (int)Math.Ceiling(crop.Y + (ty + 1) / scale) - 1));

                double rSum = 0, gSum = 0, bSum = 0;
                int total = 0, opaque = 0;
                for (int sy = sy0; sy <= sy1; sy++)
                    for (int sx = sx0; sx <= sx1; sx++)
                    {
                        Color c = src.GetPixel(sx, sy);
                        total++;
                        if (c.A >= 175)
                        {
                            // Strip original outer dark outline pixels so we don't double-outline after skeletal motion
                            if (c.R < 32 && c.G < 26 && c.B < 30) continue;
                            rSum += c.R; gSum += c.G; bSum += c.B;
                            opaque++;
                        }
                    }
                if (total > 0 && opaque * 2 >= total)
                {
                    Color q = NearestPalette((int)(rSum / opaque), (int)(gSum / opaque), (int)(bSum / opaque));
                    dst.SetPixel(ox + tx, oy + ty, q);
                }
            }
        }
        return dst;
    }

    // ─── DETERMINISTIC 4x4 MOVABLE SPRITE SHEET SYNTHESIZER ───
    // Row 0: idle (4 frames)
    // Row 1: walk (4 frames — true split-leg stride + torso bob + upper swing so characters walk smoothly in Workshop/Shop/Exploration)
    // Row 2: attack (4 frames — windup -> lunge thrust -> impact -> recover)
    // Row 3: hurt (4 frames — knockback + flash -> stagger -> recover)
    public static void BuildMovableSheetFromSingle(string inputPath, string outputPath, int cellSize, int facingSign)
    {
        using (Bitmap raw = new Bitmap(inputPath))
        using (Bitmap cleaned = CleanAlphaAndChroma(raw))
        {
            Rectangle bounds = FindBounds(cleaned, 0, 0, cleaned.Width, cleaned.Height);
            // Leave 4px margin on sides/top for walk/attack lunges, 2px at bottom for locked foot baseline
            using (Bitmap core = PixelizeCore(cleaned, bounds, cellSize, cellSize, 4, 2, 5))
            using (Bitmap sheet = new Bitmap(cellSize * 4, cellSize * 4, PixelFormat.Format32bppArgb))
            using (Graphics g = Graphics.FromImage(sheet))
            {
                g.Clear(Color.Transparent);
                Rectangle cBounds = FindBounds(core, 0, 0, cellSize, cellSize);
                if (cBounds.IsEmpty) cBounds = new Rectangle(8, 8, cellSize - 16, cellSize - 10);

                for (int row = 0; row < 4; row++)
                {
                    for (int col = 0; col < 4; col++)
                    {
                        using (Bitmap deformed = DeformFrame(core, cBounds, row, col, facingSign))
                        using (Bitmap outlined = SealOutline(deformed))
                        {
                            g.DrawImageUnscaled(outlined, col * cellSize, row * cellSize);
                        }
                    }
                }
                Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
                sheet.Save(outputPath, ImageFormat.Png);
            }
        }
    }

    private static Bitmap DeformFrame(Bitmap core, Rectangle b, int row, int col, int dir)
    {
        int w = core.Width, h = core.Height;
        Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        int midX = b.X + b.Width / 2;
        int headY = b.Y + (int)(b.Height * 0.34);
        int hipY  = b.Y + (int)(b.Height * 0.68);
        int footY = b.Bottom - 1;

        // Inverse mapping: for every destination pixel (nx, ny), sample from source (sx, sy) -> ZERO internal gaps or seam lines!
        for (int ny = 1; ny < h - 1; ny++)
        {
            for (int nx = 1; nx < w - 1; nx++)
            {
                double dx = 0.0, dy = 0.0;
                bool isLeftHalf = (nx < midX);
                bool isFrontHalf = (dir > 0) ? (nx >= midX) : (nx < midX);
                // Smooth vertical normalized weight: 0.0 at feet -> 1.0 at head
                double upperWeight = Math.Max(0.0, Math.Min(1.0, (double)(footY - ny) / Math.Max(1, b.Height)));
                double legWeight   = (ny >= hipY) ? Math.Max(0.0, Math.Min(1.0, (double)(ny - hipY) / Math.Max(1, footY - hipY))) : 0.0;

                if (row == 0) // IDLE (4f smooth breathing & subtle head/tail sway, feet locked)
                {
                    if (col == 1)
                    {
                        dy = (ny < hipY) ? -1.0 : 0.0;
                    }
                    else if (col == 2)
                    {
                        dy = (ny < hipY) ? -1.0 : 0.0;
                        if (ny < headY) dx = dir * 1.0;
                    }
                    else if (col == 3)
                    {
                        if (!isFrontHalf && ny < hipY) dx = -dir * 1.0;
                    }
                }
                else if (row == 1) // WALK (4f stride + torso bounce + lean, smooth blend across midline for robes/skirts)
                {
                    double stride = Math.Max(2.0, b.Width / 15.0);
                    double sideBlend = Math.Max(-1.0, Math.Min(1.0, (nx - midX) / 3.0));
                    if (col == 0)
                    {
                        dy = -1.0 * upperWeight;
                        dx = sideBlend * stride * legWeight;
                        if (sideBlend < -0.3 && ny >= hipY) dy -= 1.0 * legWeight;
                    }
                    else if (col == 1)
                    {
                        dx = dir * 1.0 * upperWeight;
                        dy = 0.0;
                    }
                    else if (col == 2)
                    {
                        dy = -1.0 * upperWeight;
                        dx = -sideBlend * stride * legWeight;
                        if (sideBlend > 0.3 && ny >= hipY) dy -= 1.0 * legWeight;
                    }
                    else // col == 3
                    {
                        dx = -sideBlend * 0.6 * legWeight;
                        dy = 0.0;
                    }
                }
                else if (row == 2) // ATTACK (4f windup -> strike lunge -> impact -> recover)
                {
                    double lunge = Math.Max(3.0, b.Width / 10.0);
                    if (col == 0) // Windup pull-back
                    {
                        dx = -dir * (1.0 + 1.5 * upperWeight);
                        dy = (ny < headY) ? -1.0 : 0.0;
                    }
                    else if (col == 1) // Strike lunge forward
                    {
                        dx = dir * (lunge * 0.6 + lunge * 0.5 * upperWeight);
                        dy = (ny < hipY) ? 1.0 : 0.0;
                    }
                    else if (col == 2) // Follow-through
                    {
                        dx = dir * (lunge * 0.4 + lunge * 0.3 * upperWeight);
                    }
                }
                else if (row == 3) // HURT (4f knockback + flash -> stagger -> recover)
                {
                    double knock = Math.Max(2.0, b.Width / 12.0);
                    if (col == 0)
                    {
                        dx = -dir * (knock + 1.0 * upperWeight);
                        dy = (ny < hipY) ? -1.0 : 0.0;
                    }
                    else if (col == 1)
                    {
                        dx = -dir * (knock + 1.0);
                        dy = (ny < hipY) ? 1.0 : 0.0;
                    }
                    else if (col == 2)
                    {
                        dx = -dir * 1.0;
                        dy = (ny < hipY) ? 1.0 : 0.0;
                    }
                }

                int sx = (int)Math.Round(nx - dx);
                int sy = (int)Math.Round(ny - dy);
                if (sx >= 0 && sx < w && sy >= 0 && sy < h)
                {
                    Color c = core.GetPixel(sx, sy);
                    if (c.A > 0)
                    {
                        if (row == 3 && col == 0)
                        {
                            c = NearestPalette(Math.Min(255, c.R + 75), Math.Min(255, c.G + 55), Math.Min(255, c.B + 35));
                        }
                        dst.SetPixel(nx, ny, c);
                    }
                }
            }
        }
        return dst;
    }

    // Helper: draw clean closed eyelids over amber eye pixels during idle blink frames
    private static void ApplyEyeBlink(Bitmap dst, int eyeMinY, int eyeMaxY)
    {
        for (int y = Math.Max(0, eyeMinY); y <= Math.Min(dst.Height - 1, eyeMaxY); y++)
            for (int x = 1; x < dst.Width - 1; x++)
            {
                Color c = dst.GetPixel(x, y);
                if (c.A > 0 && c.R > 185 && c.G > 95 && c.G < 195 && c.B < 95)
                {
                    dst.SetPixel(x, y, Palette[6]);
                }
            }
    }

    // Measure anatomical torso/head centerline X using upper head-shoulder band (10%..44% height),
    // ignoring asymmetric tail extension on the lower body so rotation/flip_h never shifts the body!
    public static double MeasureTorsoCenterX(Bitmap bmp, Rectangle crop)
    {
        if (crop.IsEmpty) return bmp.Width * 0.5;
        int y0 = Math.Max(crop.Y, crop.Y + (int)Math.Round(crop.Height * 0.10));
        int y1 = Math.Min(crop.Bottom - 1, crop.Y + (int)Math.Round(crop.Height * 0.44));
        double sumX = 0;
        long count = 0;
        for (int y = y0; y <= y1; y++)
        {
            int rowMin = int.MaxValue, rowMax = int.MinValue;
            for (int x = crop.X; x < crop.Right; x++)
            {
                if (bmp.GetPixel(x, y).A >= 175)
                {
                    if (x < rowMin) rowMin = x;
                    if (x > rowMax) rowMax = x;
                }
            }
            if (rowMin <= rowMax)
            {
                sumX += (rowMin + rowMax) * 0.5;
                count++;
            }
        }
        if (count == 0) return crop.X + crop.Width * 0.5;
        return sumX / count;
    }

    // Clamp rigid horizontal shift so no opaque pixel ever clips cell borders (leaves >= 2px for 1px outline)
    private static int ClampSafeShiftX(Rectangle b, int cellW, int desiredDx)
    {
        int minAllowed = 2 - b.Left;
        int maxAllowed = (cellW - 3) - (b.Right - 1);
        if (minAllowed > maxAllowed) return 0;
        return Math.Max(minAllowed, Math.Min(maxAllowed, desiredDx));
    }

    public static Bitmap DeformVertical16Frame(Bitmap core, Rectangle b, int torsoX, int mode, int col, bool isBack)
    {
        int w = core.Width, h = core.Height;
        Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        if (b.IsEmpty) return dst;

        int neckY  = b.Y + (int)Math.Round(b.Height * 0.40);
        int ankleY = b.Bottom - Math.Max(6, (int)Math.Round(b.Height * 0.14));
        int legHalfSpan = 10; // Paws lie within +-10px of torsoX; tail outside this span moves smoothly without leg-splitting

        if (mode == 0) // IDLE (16 frames: calm vertical breathing, zero horizontal skew, paws locked at y=60)
        {
            int phase8 = col % 8;
            int breatheDy = (phase8 >= 2 && phase8 <= 4) ? -1 : 0;
            int tailDy = (phase8 >= 4 && phase8 <= 6) ? -1 : 0;

            for (int ny = 0; ny < h; ny++)
            {
                for (int nx = 0; nx < w; nx++)
                {
                    bool isTail = Math.Abs(nx - torsoX) > legHalfSpan && ny >= neckY;
                    int dy = 0;
                    if (isTail) dy = tailDy;
                    else if (ny < ankleY - 3) dy = breatheDy;
                    else dy = 0; // Lower pants & paws anchored strictly at baseline!

                    int sy = ny - dy;
                    if (sy >= 0 && sy < h)
                    {
                        Color c = core.GetPixel(nx, sy);
                        if (c.A > 0) dst.SetPixel(nx, ny, c);
                    }
                }
            }

            if (!isBack && col == 7)
            {
                ApplyEyeBlink(dst, b.Y + (int)(b.Height * 0.18), b.Y + (int)(b.Height * 0.34));
            }
            return dst;
        }

        // WALK (mode == 1) & RUN (mode == 2):
        // Zero horizontal shear/sway on head & torso; clean alternating paw lift below apron hem.
        // Contact frames at col == 4 and col == 12 match BaseCharacter.gd footstep hooks!
        bool isRun = (mode == 2);
        int liftAmount = isRun ? -2 : -1;
        bool liftLeft  = (col >= 0 && col <= 2) || (col == 15);
        bool liftRight = (col >= 8 && col <= 10) || (col == 7);
        int bodyBob    = ((col >= 1 && col <= 2) || (col >= 9 && col <= 10)) ? -1 : 0;
        int tailBob    = ((col >= 2 && col <= 5) || (col >= 10 && col <= 13)) ? -1 : 0;

        for (int ny = 0; ny < h; ny++)
        {
            for (int nx = 0; nx < w; nx++)
            {
                int dy = 0;
                int distFromCenter = nx - torsoX;
                bool isTail = Math.Abs(distFromCenter) > legHalfSpan && ny >= neckY;

                if (isTail)
                {
                    dy = tailBob;
                }
                else if (ny < ankleY)
                {
                    dy = bodyBob;
                }
                else
                {
                    if (distFromCenter < -1 && liftLeft) dy = liftAmount;
                    else if (distFromCenter > 1 && liftRight) dy = liftAmount;
                    else dy = 0; // Planted paw stays locked on ground baseline y=60
                }

                int sy = ny - dy;
                if (sy >= 0 && sy < h)
                {
                    Color c = core.GetPixel(nx, sy);
                    if (c.A > 0) dst.SetPixel(nx, ny, c);
                }
            }
        }
        return dst;
    }

    public static Bitmap DeformSide16Frame(Bitmap core, Rectangle b, int torsoX, int mode, int col)
    {
        int w = core.Width, h = core.Height;
        Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        if (b.IsEmpty) return dst;

        int neckY  = b.Y + (int)Math.Round(b.Height * 0.40);
        int ankleY = b.Bottom - Math.Max(7, (int)Math.Round(b.Height * 0.15));
        int tailBoundaryX = torsoX - 8; // Pixels left of (torsoX - 8) belong to the rear tail, never legs!

        if (mode == 0) // IDLE (16 frames: vertical breathing, zero shear, paws locked at y=60)
        {
            int phase8 = col % 8;
            int breatheDy = (phase8 >= 2 && phase8 <= 4) ? -1 : 0;
            int tailDy = (phase8 >= 3 && phase8 <= 6) ? -1 : 0;

            for (int ny = 0; ny < h; ny++)
            {
                for (int nx = 0; nx < w; nx++)
                {
                    bool isTail = (nx < tailBoundaryX) && (ny >= neckY);
                    int dy = 0;
                    if (isTail) dy = tailDy;
                    else if (ny < ankleY - 3) dy = breatheDy;
                    else dy = 0;

                    int sy = ny - dy;
                    if (sy >= 0 && sy < h)
                    {
                        Color c = core.GetPixel(nx, sy);
                        if (c.A > 0) dst.SetPixel(nx, ny, c);
                    }
                }
            }

            if (col == 7)
            {
                ApplyEyeBlink(dst, b.Y + (int)(b.Height * 0.18), b.Y + (int)(b.Height * 0.34));
            }
            return dst;
        }

        if (mode == 3) // HURT (8 frames: pure rigid-body recoil + hit flash, never drops below y=60!)
        {
            int[] kx = { -2, -3, -3, -2, -2, -1, -1, 0 };
            int[] ky = {  0, -1, -1,  0,  0,  0,  0, 0 };
            int idx = Math.Min(7, col);
            int dx = ClampSafeShiftX(b, w, kx[idx]);
            int dy = ky[idx];

            for (int ny = 0; ny < h; ny++)
            {
                for (int nx = 0; nx < w; nx++)
                {
                    int sx = nx - dx;
                    int sy = ny - dy;
                    if (sx >= 0 && sx < w && sy >= 0 && sy < h)
                    {
                        Color c = core.GetPixel(sx, sy);
                        if (c.A > 0)
                        {
                            if (idx == 0 || idx == 1)
                            {
                                int boost = (idx == 0) ? 70 : 32;
                                c = NearestPalette(Math.Min(255, c.R + boost), Math.Min(255, c.G + boost - 15), Math.Min(255, c.B + boost - 30));
                            }
                            dst.SetPixel(nx, ny, c);
                        }
                    }
                }
            }
            return dst;
        }

        if (mode == 4) // SPECIAL / ATTACK (8 frames: pure rigid-body windup & strike lunge, zero skew, locked ground!)
        {
            int[] ax = { -1, -2, -1, 2, 4, 3, 1, 0 };
            int[] ay = {  0,  0, -1, -1, 0, 0, 0, 0 };
            int idx = Math.Min(7, col);
            int dx = ClampSafeShiftX(b, w, ax[idx]);
            int dy = ay[idx];

            for (int ny = 0; ny < h; ny++)
            {
                for (int nx = 0; nx < w; nx++)
                {
                    int sx = nx - dx;
                    int sy = ny - dy;
                    if (sx >= 0 && sx < w && sy >= 0 && sy < h)
                    {
                        Color c = core.GetPixel(sx, sy);
                        if (c.A > 0) dst.SetPixel(nx, ny, c);
                    }
                }
            }
            return dst;
        }

        // WALK (mode == 1) & RUN (mode == 2):
        // Rigid upright head & torso (dx == 0 -> ZERO parallelogram skew!), alternating front/back paw lift below ankleY.
        bool isRun = (mode == 2);
        int liftAmount = isRun ? -2 : -1;
        int pawStepX   = isRun ? 1 : 0;
        bool phaseA    = (col >= 0 && col <= 2) || (col == 15); // Front paw lifts, rear paw planted
        bool phaseB    = (col >= 8 && col <= 10) || (col == 7); // Rear paw lifts, front paw planted
        int bodyBob    = ((col >= 1 && col <= 2) || (col >= 9 && col <= 10)) ? -1 : 0;
        int tailBob    = ((col >= 2 && col <= 5) || (col >= 10 && col <= 13)) ? -1 : 0;

        for (int ny = 0; ny < h; ny++)
        {
            for (int nx = 0; nx < w; nx++)
            {
                int dx = 0;
                int dy = 0;
                bool isTail = (nx < tailBoundaryX) && (ny >= neckY);

                if (isTail)
                {
                    dy = tailBob;
                }
                else if (ny < ankleY)
                {
                    dy = bodyBob;
                }
                else
                {
                    bool isFrontPaw = (nx >= torsoX);
                    if (phaseA)
                    {
                        if (isFrontPaw) { dy = liftAmount; dx = pawStepX; }
                        else { dy = 0; }
                    }
                    else if (phaseB)
                    {
                        if (!isFrontPaw) { dy = liftAmount; dx = -pawStepX; }
                        else { dy = 0; }
                    }
                }

                int sx = nx - dx;
                int sy = ny - dy;
                if (sx >= 0 && sx < w && sy >= 0 && sy < h)
                {
                    Color c = core.GetPixel(sx, sy);
                    if (c.A > 0) dst.SetPixel(nx, ny, c);
                }
            }
        }
        return dst;
    }

    // Scales and quantizes Nấm's full character with unified height across all 4 directions,
    // anatomical torso X centered at x=32, crisp detail preservation, and foot baseline locked at y=60.
    public static Bitmap PixelizeNamCore(Bitmap src, Rectangle crop, int cellSize, int viewType, out int outTorsoX)
    {
        Bitmap rawCore = new Bitmap(cellSize, cellSize, PixelFormat.Format32bppArgb);
        outTorsoX = cellSize / 2;
        if (crop.IsEmpty) return rawCore;

        // Unified vertical metric: padTop = 6, padBottom = 4 -> character core height = 54px (y = 6..59).
        // With SealOutline adding 1px plum outline, top of ears sits at y = 5 and foot baseline sits strictly at y = 60!
        int padTop = 6, padBottom = 4, minSideMargin = 3;
        int targetH = Math.Max(4, cellSize - padTop - padBottom);
        int maxAllowedW = Math.Max(4, cellSize - minSideMargin * 2);

        double scale = (double)targetH / crop.Height;
        if (crop.Width * scale > maxAllowedW)
        {
            scale = (double)maxAllowedW / crop.Width;
        }

        int drawW = Math.Max(1, (int)Math.Round(crop.Width * scale));
        int drawH = Math.Max(1, (int)Math.Round(crop.Height * scale));

        double torsoSrcX = MeasureTorsoCenterX(src, crop);
        double relTorsoX = (torsoSrcX - crop.X) * scale;
        int ox = (int)Math.Round(cellSize * 0.5 - relTorsoX);
        ox = Math.Max(minSideMargin, Math.Min(cellSize - minSideMargin - drawW, ox));
        outTorsoX = Math.Max(8, Math.Min(cellSize - 8, ox + (int)Math.Round(relTorsoX)));

        int oy = cellSize - padBottom - drawH; // oy + drawH == 60 -> lowest core pixel at y=59, outline at y=60

        for (int ty = 0; ty < drawH; ty++)
        {
            int syCenter = Math.Min(crop.Bottom - 1, Math.Max(crop.Y, (int)Math.Round(crop.Y + (ty + 0.5) / scale)));
            int sy0 = Math.Max(crop.Y, (int)Math.Floor(crop.Y + ty / scale));
            int sy1 = Math.Min(crop.Bottom - 1, Math.Max(sy0, (int)Math.Ceiling(crop.Y + (ty + 1) / scale) - 1));

            for (int tx = 0; tx < drawW; tx++)
            {
                int sxCenter = Math.Min(crop.Right - 1, Math.Max(crop.X, (int)Math.Round(crop.X + (tx + 0.5) / scale)));
                int sx0 = Math.Max(crop.X, (int)Math.Floor(crop.X + tx / scale));
                int sx1 = Math.Min(crop.Right - 1, Math.Max(sx0, (int)Math.Ceiling(crop.X + (tx + 1) / scale) - 1));

                double rSum = 0, gSum = 0, bSum = 0;
                int total = 0, opaque = 0;
                for (int sy = sy0; sy <= sy1; sy++)
                {
                    for (int sx = sx0; sx <= sx1; sx++)
                    {
                        Color c = src.GetPixel(sx, sy);
                        total++;
                        if (c.A >= 175)
                        {
                            rSum += c.R; gSum += c.G; bSum += c.B;
                            opaque++;
                        }
                    }
                }
                if (total > 0 && opaque * 2 >= total)
                {
                    Color cCenter = src.GetPixel(sxCenter, syCenter);
                    int rAvg = (int)(rSum / opaque);
                    int gAvg = (int)(gSum / opaque);
                    int bAvg = (int)(bSum / opaque);
                    // Smooth box average eliminates Moiré checkerboard from high-res AI pixel grids,
                    // while preserving bright amber eye highlights when present at the sample center.
                    bool isAmberEyeHighlight = (cCenter.A >= 175 && cCenter.R > 185 && cCenter.G > 90 && cCenter.B < 75 && (cCenter.R - cCenter.B) > 120);
                    double cw = isAmberEyeHighlight ? 0.65 : 0.15;
                    int r = (cCenter.A >= 175) ? (int)Math.Round(cCenter.R * cw + rAvg * (1.0 - cw)) : rAvg;
                    int g = (cCenter.A >= 175) ? (int)Math.Round(cCenter.G * cw + gAvg * (1.0 - cw)) : gAvg;
                    int b = (cCenter.A >= 175) ? (int)Math.Round(cCenter.B * cw + bAvg * (1.0 - cw)) : bAvg;
                    Color q = NearestPalette(r, g, b);
                    rawCore.SetPixel(ox + tx, oy + ty, q);
                }
            }
        }
        return rawCore;
    }

    // Scales a single frame with an explicit shared scale so all 4 walk frames keep identical head/body proportions
    // while preserving natural vertical bobbing between Passing (taller) and Contact (slightly lower) poses!
    public static Bitmap PixelizeNamCoreWithScale(Bitmap src, Rectangle crop, int cellSize, double sharedScale, out int outTorsoX)
    {
        Bitmap rawCore = new Bitmap(cellSize, cellSize, PixelFormat.Format32bppArgb);
        outTorsoX = cellSize / 2;
        if (crop.IsEmpty || sharedScale <= 0) return rawCore;

        int padBottom = 4, minSideMargin = 3;
        int drawW = Math.Max(1, (int)Math.Round(crop.Width * sharedScale));
        int drawH = Math.Max(1, (int)Math.Round(crop.Height * sharedScale));

        double torsoSrcX = MeasureTorsoCenterX(src, crop);
        double relTorsoX = (torsoSrcX - crop.X) * sharedScale;
        int ox = (int)Math.Round(cellSize * 0.5 - relTorsoX);
        ox = Math.Max(minSideMargin, Math.Min(cellSize - minSideMargin - drawW, ox));
        outTorsoX = Math.Max(8, Math.Min(cellSize - 8, ox + (int)Math.Round(relTorsoX)));

        int oy = Math.Max(2, cellSize - padBottom - drawH); // Foot baseline strictly locked at y=59 (+1px outline = y=60)

        for (int ty = 0; ty < drawH; ty++)
        {
            if (oy + ty >= cellSize - 1) continue;
            int syCenter = Math.Min(crop.Bottom - 1, Math.Max(crop.Y, (int)Math.Round(crop.Y + (ty + 0.5) / sharedScale)));
            int sy0 = Math.Max(crop.Y, (int)Math.Floor(crop.Y + ty / sharedScale));
            int sy1 = Math.Min(crop.Bottom - 1, Math.Max(sy0, (int)Math.Ceiling(crop.Y + (ty + 1) / sharedScale) - 1));

            for (int tx = 0; tx < drawW; tx++)
            {
                if (ox + tx < 1 || ox + tx >= cellSize - 1) continue;
                int sxCenter = Math.Min(crop.Right - 1, Math.Max(crop.X, (int)Math.Round(crop.X + (tx + 0.5) / sharedScale)));
                int sx0 = Math.Max(crop.X, (int)Math.Floor(crop.X + tx / sharedScale));
                int sx1 = Math.Min(crop.Right - 1, Math.Max(sx0, (int)Math.Ceiling(crop.X + (tx + 1) / sharedScale) - 1));

                double rSum = 0, gSum = 0, bSum = 0;
                int total = 0, opaque = 0;
                for (int sy = sy0; sy <= sy1; sy++)
                {
                    for (int sx = sx0; sx <= sx1; sx++)
                    {
                        Color c = src.GetPixel(sx, sy);
                        total++;
                        if (c.A >= 175)
                        {
                            rSum += c.R; gSum += c.G; bSum += c.B;
                            opaque++;
                        }
                    }
                }
                if (total > 0 && opaque * 2 >= total)
                {
                    Color cCenter = src.GetPixel(sxCenter, syCenter);
                    int rAvg = (int)(rSum / opaque);
                    int gAvg = (int)(gSum / opaque);
                    int bAvg = (int)(bSum / opaque);
                    bool isAmberEyeHighlight = (cCenter.A >= 175 && cCenter.R > 185 && cCenter.G > 90 && cCenter.B < 75 && (cCenter.R - cCenter.B) > 120);
                    double cw = isAmberEyeHighlight ? 0.65 : 0.15;
                    int r = (cCenter.A >= 175) ? (int)Math.Round(cCenter.R * cw + rAvg * (1.0 - cw)) : rAvg;
                    int g = (cCenter.A >= 175) ? (int)Math.Round(cCenter.G * cw + gAvg * (1.0 - cw)) : gAvg;
                    int b = (cCenter.A >= 175) ? (int)Math.Round(cCenter.B * cw + bAvg * (1.0 - cw)) : bAvg;
                    Color q = NearestPalette(r, g, b);
                    rawCore.SetPixel(ox + tx, oy + ty, q);
                }
            }
        }
        return rawCore;
    }

    // Extract 4 independent character sprites from a 1x4 horizontal walk strip using 8-connected components
    // so adjacent tails/hands NEVER bleed across frame bounding boxes.
    public static Bitmap[] Extract4StripFrames(Bitmap cleanStrip)
    {
        int w = cleanStrip.Width, h = cleanStrip.Height;
        int[,] labels = new int[w, h];
        List<Rectangle> compBoxes = new List<Rectangle>();
        List<int> compAreas = new List<int>();
        List<int> compIds = new List<int>();
        int nextId = 1;
        Queue<Point> q = new Queue<Point>();

        for (int y = 0; y < h; y++)
        {
            for (int x = 0; x < w; x++)
            {
                if (labels[x, y] != 0 || cleanStrip.GetPixel(x, y).A < 175) continue;
                int id = nextId++;
                int minX = x, maxX = x, minY = y, maxY = y, area = 0;
                labels[x, y] = id;
                q.Enqueue(new Point(x, y));
                while (q.Count > 0)
                {
                    Point p = q.Dequeue();
                    area++;
                    if (p.X < minX) minX = p.X;
                    if (p.X > maxX) maxX = p.X;
                    if (p.Y < minY) minY = p.Y;
                    if (p.Y > maxY) maxY = p.Y;
                    for (int dy = -1; dy <= 1; dy++)
                    {
                        int ny = p.Y + dy;
                        if (ny < 0 || ny >= h) continue;
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            if (dx == 0 && dy == 0) continue;
                            int nx = p.X + dx;
                            if (nx < 0 || nx >= w || labels[nx, ny] != 0) continue;
                            if (cleanStrip.GetPixel(nx, ny).A >= 175)
                            {
                                labels[nx, ny] = id;
                                q.Enqueue(new Point(nx, ny));
                            }
                        }
                    }
                }
                if (area >= 400)
                {
                    compIds.Add(id);
                    compAreas.Add(area);
                    compBoxes.Add(new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1));
                }
            }
        }

        // Keep top 4 largest components, then sort left-to-right by center X
        if (compIds.Count >= 4)
        {
            List<int> idxOrder = new List<int>();
            for (int i = 0; i < compIds.Count; i++) idxOrder.Add(i);
            idxOrder.Sort((a, b) => compAreas[b].CompareTo(compAreas[a]));
            idxOrder = idxOrder.GetRange(0, 4);
            idxOrder.Sort((a, b) => (compBoxes[a].X + compBoxes[a].Width / 2).CompareTo(compBoxes[b].X + compBoxes[b].Width / 2));

            Bitmap[] frames = new Bitmap[4];
            for (int k = 0; k < 4; k++)
            {
                int ci = idxOrder[k];
                int cid = compIds[ci];
                Rectangle box = compBoxes[ci];
                Bitmap f = new Bitmap(box.Width, box.Height, PixelFormat.Format32bppArgb);
                for (int yy = 0; yy < box.Height; yy++)
                    for (int xx = 0; xx < box.Width; xx++)
                        if (labels[box.X + xx, box.Y + yy] == cid)
                            f.SetPixel(xx, yy, cleanStrip.GetPixel(box.X + xx, box.Y + yy));
                frames[k] = f;
            }
            return frames;
        }

        // Safe fallback: 4 equal vertical slices
        Bitmap[] fallback = new Bitmap[4];
        int cw = w / 4;
        for (int k = 0; k < 4; k++)
        {
            Rectangle slice = new Rectangle(k * cw, 0, (k == 3) ? (w - k * cw) : cw, h);
            fallback[k] = cleanStrip.Clone(slice, PixelFormat.Format32bppArgb);
        }
        return fallback;
    }

    private static Bitmap[] PixelizeStrip4(string stripPath, int cellSize, out int[] torsoXs, out Rectangle[] coreBounds)
    {
        torsoXs = new int[4];
        coreBounds = new Rectangle[4];
        using (Bitmap raw = new Bitmap(stripPath))
        using (Bitmap clean = CleanAlphaAndChroma(raw))
        {
            Bitmap[] parts = Extract4StripFrames(clean);
            try
            {
                Rectangle[] srcBounds = new Rectangle[4];
                int maxH = 1, maxW = 1;
                for (int i = 0; i < 4; i++)
                {
                    srcBounds[i] = FindBounds(parts[i], 0, 0, parts[i].Width, parts[i].Height);
                    if (srcBounds[i].Height > maxH) maxH = srcBounds[i].Height;
                    if (srcBounds[i].Width  > maxW) maxW = srcBounds[i].Width;
                }
                int targetH = Math.Max(4, cellSize - 10);
                int maxAllowedW = Math.Max(4, cellSize - 6);
                double sharedScale = (double)targetH / maxH;
                if (maxW * sharedScale > maxAllowedW)
                    sharedScale = (double)maxAllowedW / maxW;

                Bitmap[] cores = new Bitmap[4];
                for (int i = 0; i < 4; i++)
                {
                    int tx;
                    cores[i] = PixelizeNamCoreWithScale(parts[i], srcBounds[i], cellSize, sharedScale, out tx);
                    torsoXs[i] = tx;
                    coreBounds[i] = FindBounds(cores[i], 0, 0, cellSize, cellSize);
                }
                return cores;
            }
            finally
            {
                for (int i = 0; i < parts.Length; i++) if (parts[i] != null) parts[i].Dispose();
            }
        }
    }

    // Build complete 16-col x 14-row (1024x896, 64x64/cell) 4-Directional Sheet using TRUE hand-drawn 4-frame walk strips!
    public static void BuildPlayer4DirFromStrips(string walkDownStrip, string walkUpStrip, string walkRightStrip, string outputPath, int cellSize)
    {
        int[] txDown, txUp, txRight;
        Rectangle[] cbDown, cbUp, cbRight;
        Bitmap[] fDown  = PixelizeStrip4(walkDownStrip,  cellSize, out txDown,  out cbDown);
        Bitmap[] fUp    = PixelizeStrip4(walkUpStrip,    cellSize, out txUp,    out cbUp);
        Bitmap[] fRight = PixelizeStrip4(walkRightStrip, cellSize, out txRight, out cbRight);

        try
        {
            // Frame 1 (Passing Neutral) is the clean standing pose for each direction -> 100% consistent proportions & angle!
            Bitmap idleDownCore  = fDown[1];
            Bitmap idleUpCore    = fUp[1];
            Bitmap idleRightCore = fRight[1];

            // Pre-outline the 4 true walk frames for each direction
            Bitmap[] outDown  = new Bitmap[4];
            Bitmap[] outUp    = new Bitmap[4];
            Bitmap[] outRight = new Bitmap[4];
            Bitmap[] outLeft  = new Bitmap[4];
            for (int i = 0; i < 4; i++)
            {
                outDown[i]  = SealOutline(fDown[i]);
                outUp[i]    = SealOutline(fUp[i]);
                outRight[i] = SealOutline(fRight[i]);
                outLeft[i]  = FlipHorizontalAroundCenter(outRight[i]);
            }

            try
            {
                using (Bitmap sheet = new Bitmap(cellSize * 16, cellSize * 14, PixelFormat.Format32bppArgb))
                using (Graphics g = Graphics.FromImage(sheet))
                {
                    g.Clear(Color.Transparent);

                    // Rows 0..3: IDLE (16 frames @ 12 FPS = 1.33s calm breathing & subtle eye blink, paws strictly locked at y=60)
                    for (int col = 0; col < 16; col++)
                    {
                        using (Bitmap dDef = DeformVertical16Frame(idleDownCore, cbDown[1], txDown[1], 0, col, false))
                        using (Bitmap dOut = SealOutline(dDef))
                            g.DrawImageUnscaled(dOut, col * cellSize, 0 * cellSize);

                        using (Bitmap uDef = DeformVertical16Frame(idleUpCore, cbUp[1], txUp[1], 0, col, true))
                        using (Bitmap uOut = SealOutline(uDef))
                            g.DrawImageUnscaled(uOut, col * cellSize, 1 * cellSize);

                        using (Bitmap rDef = DeformSide16Frame(idleRightCore, cbRight[1], txRight[1], 0, col))
                        using (Bitmap rOut = SealOutline(rDef))
                        {
                            g.DrawImageUnscaled(rOut, col * cellSize, 2 * cellSize);
                            using (Bitmap lOut = FlipHorizontalAroundCenter(rOut))
                                g.DrawImageUnscaled(lOut, col * cellSize, 3 * cellSize);
                        }
                    }

                    // Rows 4..7: WALK (16 frames @ 24 FPS = 0.67s per full 2-step cycle; contact frames align with col==4 & col==12 footstep SFX!)
                    int[] walkMap = { 3, 3, 3, 3, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2 };
                    // Rows 8..11: RUN (16 frames @ 28 FPS = 2 full 2-step cycles per loop; crisp brisk stride)
                    int[] runMap  = { 2, 2, 3, 3, 0, 0, 1, 1, 2, 2, 3, 3, 0, 0, 1, 1 };

                    for (int col = 0; col < 16; col++)
                    {
                        int wi = walkMap[col];
                        g.DrawImageUnscaled(outDown[wi],  col * cellSize, 4 * cellSize);
                        g.DrawImageUnscaled(outUp[wi],    col * cellSize, 5 * cellSize);
                        g.DrawImageUnscaled(outRight[wi], col * cellSize, 6 * cellSize);
                        g.DrawImageUnscaled(outLeft[wi],  col * cellSize, 7 * cellSize);

                        int ri = runMap[col];
                        g.DrawImageUnscaled(outDown[ri],  col * cellSize, 8  * cellSize);
                        g.DrawImageUnscaled(outUp[ri],    col * cellSize, 9  * cellSize);
                        g.DrawImageUnscaled(outRight[ri], col * cellSize, 10 * cellSize);
                        g.DrawImageUnscaled(outLeft[ri],  col * cellSize, 11 * cellSize);
                    }

                    // Row 12: HURT (8 frames: clean rigid recoil + hit flash from neutral side stance)
                    // Row 13: SPECIAL / ATTACK (8 frames: windup from neutral -> dynamic strike lunge using Contact B pose -> recover)
                    for (int col = 0; col < 8; col++)
                    {
                        using (Bitmap hDef = DeformSide16Frame(idleRightCore, cbRight[1], txRight[1], 3, col))
                        using (Bitmap hOut = SealOutline(hDef))
                            g.DrawImageUnscaled(hOut, col * cellSize, 12 * cellSize);

                        Bitmap atkBase = (col >= 3 && col <= 5) ? fRight[2] : idleRightCore;
                        Rectangle atkB = (col >= 3 && col <= 5) ? cbRight[2] : cbRight[1];
                        int atkTx      = (col >= 3 && col <= 5) ? txRight[2] : txRight[1];
                        using (Bitmap aDef = DeformSide16Frame(atkBase, atkB, atkTx, 4, col))
                        using (Bitmap aOut = SealOutline(aDef))
                            g.DrawImageUnscaled(aOut, col * cellSize, 13 * cellSize);
                    }

                    Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
                    sheet.Save(outputPath, ImageFormat.Png);
                }
            }
            finally
            {
                for (int i = 0; i < 4; i++)
                {
                    if (outDown[i]  != null) outDown[i].Dispose();
                    if (outUp[i]    != null) outUp[i].Dispose();
                    if (outRight[i] != null) outRight[i].Dispose();
                    if (outLeft[i]  != null) outLeft[i].Dispose();
                }
            }
        }
        finally
        {
            for (int i = 0; i < 4; i++)
            {
                if (fDown[i]  != null) fDown[i].Dispose();
                if (fUp[i]    != null) fUp[i].Dispose();
                if (fRight[i] != null) fRight[i].Dispose();
            }
        }
    }

    public static Bitmap FlipHorizontalAroundCenter(Bitmap src)
    {
        int w = src.Width, h = src.Height;
        Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        // Mirror around x = w/2 (32) to match Godot AnimatedSprite2D.flip_h exact pixel behavior
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                dst.SetPixel(w - 1 - x, y, src.GetPixel(x, y));
        return dst;
    }

    // Build complete 16-col x 14-row (1024x896, 64x64/cell) 4-Directional High-FPS Player Sprite Sheet
    public static void BuildPlayer4DirSheet(string frontPath, string backPath, string sidePath, string outputPath, int cellSize)
    {
        using (Bitmap rawFront = new Bitmap(frontPath))
        using (Bitmap cleanFront = CleanAlphaAndChroma(rawFront))
        using (Bitmap rawBack = new Bitmap(backPath))
        using (Bitmap cleanBack = CleanAlphaAndChroma(rawBack))
        using (Bitmap rawSide = new Bitmap(sidePath))
        using (Bitmap cleanSide = CleanAlphaAndChroma(rawSide))
        {
            Rectangle bFront = FindBounds(cleanFront, 0, 0, cleanFront.Width, cleanFront.Height);
            Rectangle bBack  = FindBounds(cleanBack,  0, 0, cleanBack.Width,  cleanBack.Height);
            Rectangle bSide  = FindBounds(cleanSide,  0, 0, cleanSide.Width,  cleanSide.Height);

            int torsoFrontX, torsoBackX, torsoSideX;
            using (Bitmap coreFront = PixelizeNamCore(cleanFront, bFront, cellSize, 0, out torsoFrontX))
            using (Bitmap coreBack  = PixelizeNamCore(cleanBack,  bBack,  cellSize, 1, out torsoBackX))
            using (Bitmap coreSide  = PixelizeNamCore(cleanSide,  bSide,  cellSize, 2, out torsoSideX))
            {
                Rectangle cbFront = FindBounds(coreFront, 0, 0, cellSize, cellSize);
                Rectangle cbBack  = FindBounds(coreBack,  0, 0, cellSize, cellSize);
                Rectangle cbSide  = FindBounds(coreSide,  0, 0, cellSize, cellSize);

                using (Bitmap sheet = new Bitmap(cellSize * 16, cellSize * 14, PixelFormat.Format32bppArgb))
                using (Graphics g = Graphics.FromImage(sheet))
                {
                    g.Clear(Color.Transparent);

                    int[] downRows  = { 0, 4, 8 };
                    int[] upRows    = { 1, 5, 9 };
                    int[] rightRows = { 2, 6, 10 };
                    int[] leftRows  = { 3, 7, 11 };

                    for (int m = 0; m < 3; m++)
                    {
                        for (int col = 0; col < 16; col++)
                        {
                            using (Bitmap dDef = DeformVertical16Frame(coreFront, cbFront, torsoFrontX, m, col, false))
                            using (Bitmap dOut = SealOutline(dDef))
                                g.DrawImageUnscaled(dOut, col * cellSize, downRows[m] * cellSize);

                            using (Bitmap uDef = DeformVertical16Frame(coreBack, cbBack, torsoBackX, m, col, true))
                            using (Bitmap uOut = SealOutline(uDef))
                                g.DrawImageUnscaled(uOut, col * cellSize, upRows[m] * cellSize);

                            using (Bitmap rDef = DeformSide16Frame(coreSide, cbSide, torsoSideX, m, col))
                            using (Bitmap rOut = SealOutline(rDef))
                            {
                                g.DrawImageUnscaled(rOut, col * cellSize, rightRows[m] * cellSize);
                                using (Bitmap lOut = FlipHorizontalAroundCenter(rOut))
                                    g.DrawImageUnscaled(lOut, col * cellSize, leftRows[m] * cellSize);
                            }
                        }
                    }

                    // Row 12: hurt (8 frames) & Row 13: special/attack (8 frames)
                    for (int col = 0; col < 8; col++)
                    {
                        using (Bitmap hDef = DeformSide16Frame(coreSide, cbSide, torsoSideX, 3, col))
                        using (Bitmap hOut = SealOutline(hDef))
                            g.DrawImageUnscaled(hOut, col * cellSize, 12 * cellSize);

                        using (Bitmap aDef = DeformSide16Frame(coreSide, cbSide, torsoSideX, 4, col))
                        using (Bitmap aOut = SealOutline(aDef))
                            g.DrawImageUnscaled(aOut, col * cellSize, 13 * cellSize);
                    }

                    Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
                    sheet.Save(outputPath, ImageFormat.Png);
                }
            }
        }
    }
    public static void ConvertGridSheet(string inputPath, string outputPath, int cols, int rows, int cellSize)
    {
        using (Bitmap src = new Bitmap(inputPath))
        {
            int cw = src.Width / cols, ch = src.Height / rows;
            int relMinX = cw, relMinY = ch, relMaxX = 0, relMaxY = 0;
            bool[,] hasFrame = new bool[cols, rows];

            for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                {
                    Rectangle b = FindBounds(src, c * cw, r * ch, cw, ch);
                    if (!b.IsEmpty && b.Width > 20 && b.Height > 20)
                    {
                        hasFrame[c, r] = true;
                        relMinX = Math.Min(relMinX, b.X - c * cw);
                        relMinY = Math.Min(relMinY, b.Y - r * ch);
                        relMaxX = Math.Max(relMaxX, b.Right - 1 - c * cw);
                        relMaxY = Math.Max(relMaxY, b.Bottom - 1 - r * ch);
                    }
                }

            int cropW = relMaxX - relMinX + 1;
            int cropH = relMaxY - relMinY + 1;

            using (Bitmap outSheet = new Bitmap(cols * cellSize, rows * cellSize, PixelFormat.Format32bppArgb))
            using (Graphics g = Graphics.FromImage(outSheet))
            {
                g.Clear(Color.Transparent);
                for (int r = 0; r < rows; r++)
                    for (int c = 0; c < cols; c++)
                    {
                        if (!hasFrame[c, r]) continue;
                        Rectangle cellCrop = new Rectangle(c * cw + relMinX, r * ch + relMinY, cropW, cropH);
                        using (Bitmap core = PixelizeCore(src, cellCrop, cellSize, cellSize, 3, 2, 3))
                        using (Bitmap outlined = SealOutline(core))
                        {
                            g.DrawImageUnscaled(outlined, c * cellSize, r * cellSize);
                        }
                    }
                Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
                outSheet.Save(outputPath, ImageFormat.Png);
            }
        }
    }

    public static void PixelizeBackgroundToFile(string inputPath, string outputPath, int targetW, int targetH)
    {
        using (Bitmap src = new Bitmap(inputPath))
        using (Bitmap dst = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb))
        {
            double scaleX = (double)src.Width / targetW;
            double scaleY = (double)src.Height / targetH;
            for (int ty = 0; ty < targetH; ty++)
            {
                int syC = Math.Min(src.Height - 1, Math.Max(0, (int)Math.Round((ty + 0.5) * scaleY)));
                int sy0 = Math.Max(0, (int)Math.Floor(ty * scaleY));
                int sy1 = Math.Min(src.Height - 1, (int)Math.Floor((ty + 1) * scaleY));
                for (int tx = 0; tx < targetW; tx++)
                {
                    int sxC = Math.Min(src.Width - 1, Math.Max(0, (int)Math.Round((tx + 0.5) * scaleX)));
                    int sx0 = Math.Max(0, (int)Math.Floor(tx * scaleX));
                    int sx1 = Math.Min(src.Width - 1, (int)Math.Floor((tx + 1) * scaleX));
                    Color cC = src.GetPixel(sxC, syC);
                    double rS = 0, gS = 0, bS = 0; int cnt = 0;
                    for (int sy = sy0; sy <= sy1; sy++)
                        for (int sx = sx0; sx <= sx1; sx++)
                        {
                            Color c = src.GetPixel(sx, sy);
                            rS += c.R; gS += c.G; bS += c.B; cnt++;
                        }
                    double d = Bayer2[tx & 1, ty & 1] * 0.7;
                    int ri = Math.Min(255, Math.Max(0, (int)Math.Round(cC.R * 0.65 + (rS / cnt) * 0.35 + d)));
                    int gi = Math.Min(255, Math.Max(0, (int)Math.Round(cC.G * 0.65 + (gS / cnt) * 0.35 + d)));
                    int bi = Math.Min(255, Math.Max(0, (int)Math.Round(cC.B * 0.65 + (bS / cnt) * 0.35 + d)));
                    dst.SetPixel(tx, ty, NearestPalette(ri, gi, bi));
                }
            }
            Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
            dst.Save(outputPath, ImageFormat.Png);
        }
    }

    public static Bitmap ScaleNearest(Bitmap src, int factor)
    {
        Bitmap dst = new Bitmap(src.Width * factor, src.Height * factor, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst))
        {
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.Half;
            g.DrawImage(src, 0, 0, dst.Width, dst.Height);
        }
        return dst;
    }

    public static string ValidateAsset(string path, int expectedW, int expectedH, bool requireTransparency)
    {
        if (!File.Exists(path)) return "FAIL: File not found: " + path;
        using (Bitmap bmp = new Bitmap(path))
        {
            if (expectedW > 0 && bmp.Width != expectedW)
                return string.Format("FAIL: Width {0} != expected {1} ({2})", bmp.Width, expectedW, Path.GetFileName(path));
            if (expectedH > 0 && bmp.Height != expectedH)
                return string.Format("FAIL: Height {0} != expected {1} ({2})", bmp.Height, expectedH, Path.GetFileName(path));

            int transparentPixels = 0, magentaSpill = 0;
            for (int y = 0; y < bmp.Height; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    Color c = bmp.GetPixel(x, y);
                    if (c.A == 0) transparentPixels++;
                    else if (IsMagentaKey(c)) magentaSpill++;
                }

            if (requireTransparency && transparentPixels == 0)
                return "FAIL: No transparent background pixels in " + Path.GetFileName(path);
            if (magentaSpill > 0)
                return string.Format("FAIL: {0} magenta chroma-key spill pixels remaining in {1}", magentaSpill, Path.GetFileName(path));

            return string.Format("PASS: {0} ({1}x{2}, transparent={3}px, 0 magenta spill)", Path.GetFileName(path), bmp.Width, bmp.Height, transparentPixels);
        }
    }
}
"@

Add-Type -TypeDefinition $csharpPipeline -ReferencedAssemblies System.Drawing

switch ($Mode) {
    "sheetFromSingle" {
        [HoaTam32Bit]::BuildMovableSheetFromSingle($InputPath, $OutputPath, $CellSize, $FacingSign)
        Write-Host ([HoaTam32Bit]::ValidateAsset($OutputPath, $CellSize * 4, $CellSize * 4, $true))
    }
    "sheetFromGrid" {
        [HoaTam32Bit]::ConvertGridSheet($InputPath, $OutputPath, 4, 8, $CellSize)
        Write-Host ([HoaTam32Bit]::ValidateAsset($OutputPath, $CellSize * 4, $CellSize * 8, $true))
    }
    "player4Dir" {
        if (-not $OutputPath) { $OutputPath = "assets\pixel\sprites\player\nam_4dir_sheet_64.png" }
        if (-not $WalkDownStrip -and (Test-Path "assets\pixel\sprites\player\raw\nam_walk_down_strip.png"))   { $WalkDownStrip  = "assets\pixel\sprites\player\raw\nam_walk_down_strip.png" }
        if (-not $WalkUpStrip -and (Test-Path "assets\pixel\sprites\player\raw\nam_walk_up_strip.png"))       { $WalkUpStrip    = "assets\pixel\sprites\player\raw\nam_walk_up_strip.png" }
        if (-not $WalkRightStrip -and (Test-Path "assets\pixel\sprites\player\raw\nam_walk_right_strip.png")) { $WalkRightStrip = "assets\pixel\sprites\player\raw\nam_walk_right_strip.png" }

        if ($WalkDownStrip -and $WalkUpStrip -and $WalkRightStrip) {
            [HoaTam32Bit]::BuildPlayer4DirFromStrips($WalkDownStrip, $WalkUpStrip, $WalkRightStrip, $OutputPath, $CellSize)
        } else {
            if (-not $FrontPath) {
                $FrontPath = if (Test-Path "assets\pixel\sprites\player\raw\nam_front_master.png") { "assets\pixel\sprites\player\raw\nam_front_master.png" } else { "assets\pixel\sprites\player\raw\nam_front.jpg" }
            }
            if (-not $BackPath) {
                $BackPath = if (Test-Path "assets\pixel\sprites\player\raw\nam_back_master.png") { "assets\pixel\sprites\player\raw\nam_back_master.png" } else { "assets\pixel\sprites\player\raw\nam_back.jpg" }
            }
            if (-not $SideSheetPath) {
                $SideSheetPath = if (Test-Path "assets\pixel\sprites\player\raw\nam_side_master.png") { "assets\pixel\sprites\player\raw\nam_side_master.png" } else { "assets\pixel\sprites\player\raw\nam_side.jpg" }
            }
            [HoaTam32Bit]::BuildPlayer4DirSheet($FrontPath, $BackPath, $SideSheetPath, $OutputPath, $CellSize)
        }
        Write-Host ([HoaTam32Bit]::ValidateAsset($OutputPath, $CellSize * 16, $CellSize * 14, $true))
    }
    "background" {
        [HoaTam32Bit]::PixelizeBackgroundToFile($InputPath, $OutputPath, $TargetW, $TargetH)
        Write-Host ([HoaTam32Bit]::ValidateAsset($OutputPath, $TargetW, $TargetH, $false))
    }
    "validate" {
        $tw = if ($PSBoundParameters.ContainsKey('TargetW')) { $TargetW } else { 0 }
        $th = if ($PSBoundParameters.ContainsKey('TargetH')) { $TargetH } else { 0 }
        Write-Host ([HoaTam32Bit]::ValidateAsset($InputPath, $tw, $th, $true))
    }
    "demoBatch" {
        $repo = "c:\Users\builo\.gemini\antigravity\scratch\lo-thieng"
        $artDir = "C:\Users\builo\.gemini\antigravity\brain\780396ec-6162-4c0c-8a5a-08118d006093"

        # 1. Nam 64x64 32-bit 4x8 sheet (256x512)
        $namIn = "$repo\assets\sprites\players\sprite sheet_Nấm.png"
        $namOut = "$repo\assets\pixel\sprites\player\nam_sheet_64.png"
        [HoaTam32Bit]::ConvertGridSheet($namIn, $namOut, 4, 8, 64)
        Write-Host ([HoaTam32Bit]::ValidateAsset($namOut, 256, 512, $true))

        # 2. Soi Dong Co 64x64 32-bit 4x4 movable sheet (idle, walk, attack, hurt)
        $wolfIn = "$artDir\raw_soi_dong_co_t1_v3_1795432620459.jpg"
        $wolfOut = "$repo\assets\pixel\sprites\enemies\soi_dong_co_t1_sheet_64.png"
        [HoaTam32Bit]::BuildMovableSheetFromSingle($wolfIn, $wolfOut, 64, -1)
        Write-Host ([HoaTam32Bit]::ValidateAsset($wolfOut, 256, 256, $true))

        # 3. Co Long Gio 64x64 32-bit 4x4 movable sheet (walks in V1 and enters Shop as Commission Giver!)
        $clgIn = (Get-ChildItem "$repo\assets\sprites\characters" -Filter "*Gi*.png" | Select-Object -First 1).FullName
        $clgOut = "$repo\assets\pixel\sprites\npcs\co_long_gio_sheet_64.png"
        [HoaTam32Bit]::BuildMovableSheetFromSingle($clgIn, $clgOut, 64, -1)
        Write-Host ([HoaTam32Bit]::ValidateAsset($clgOut, 256, 256, $true))

        # 4. Ba Hac Nguyet 64x64 32-bit 4x4 movable sheet
        $bhnIn = (Get-ChildItem "$repo\assets\sprites\characters" -Filter "*1.png" | Select-Object -First 1).FullName
        $bhnOut = "$repo\assets\pixel\sprites\npcs\ba_hac_nguyet_sheet_64.png"
        [HoaTam32Bit]::BuildMovableSheetFromSingle($bhnIn, $bhnOut, 64, -1)
        Write-Host ([HoaTam32Bit]::ValidateAsset($bhnOut, 256, 256, $true))

        # 5. Render verification board showing Nam (idle + walk), Soi Dong Co (idle + walk + attack + hurt), Co Long Gio (walk)
        $board = New-Object System.Drawing.Bitmap(540, 280, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($board)
        $g.Clear([HoaTam32Bit]::Palette[2])

        $namBmp = [System.Drawing.Bitmap]::FromFile($namOut)
        $wolfBmp = [System.Drawing.Bitmap]::FromFile($wolfOut)
        $clgBmp = [System.Drawing.Bitmap]::FromFile($clgOut)

        # Left column: Nam 64x64 Row 0 (idle), Row 1 (walk), Row 5 (run), Row 6 (hurt)
        $g.DrawImage($namBmp, (New-Object System.Drawing.Rectangle(8, 8, 256, 64)), (New-Object System.Drawing.Rectangle(0, 0, 256, 64)), [System.Drawing.GraphicsUnit]::Pixel)
        $g.DrawImage($namBmp, (New-Object System.Drawing.Rectangle(8, 76, 256, 64)), (New-Object System.Drawing.Rectangle(0, 64, 256, 64)), [System.Drawing.GraphicsUnit]::Pixel)
        $g.DrawImage($namBmp, (New-Object System.Drawing.Rectangle(8, 144, 256, 64)), (New-Object System.Drawing.Rectangle(0, 320, 256, 64)), [System.Drawing.GraphicsUnit]::Pixel)
        $g.DrawImage($clgBmp, (New-Object System.Drawing.Rectangle(8, 212, 256, 64)), (New-Object System.Drawing.Rectangle(0, 64, 256, 64)), [System.Drawing.GraphicsUnit]::Pixel)

        # Right column: Soi Dong Co 64x64 all 4 rows (Row 0 idle, Row 1 walk, Row 2 attack, Row 3 hurt)
        $g.DrawImage($wolfBmp, (New-Object System.Drawing.Rectangle(276, 8, 256, 256)), (New-Object System.Drawing.Rectangle(0, 0, 256, 256)), [System.Drawing.GraphicsUnit]::Pixel)
        $g.Dispose()

        $board2x = [HoaTam32Bit]::ScaleNearest($board, 2)
        $board2x.Save("$artDir\preview_4_32bit_movement_sheets.png", [System.Drawing.Imaging.ImageFormat]::Png)
        $namBmp.Dispose(); $wolfBmp.Dispose(); $clgBmp.Dispose(); $board.Dispose(); $board2x.Dispose()
        Write-Host "Saved preview_4_32bit_movement_sheets.png"
    }
}
