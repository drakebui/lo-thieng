using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class NamMasterGenerator
{
    // =========================================================================
    // 32-BIT HOẢ TÂM MASTER PALETTE (Sea of Stars / Eastward style)
    // =========================================================================
    public static readonly Color MagentaBg     = Color.FromArgb(255, 0, 255);      // Pure #FF00FF chroma-key
    public static readonly Color InkOutline    = Color.FromArgb(18, 12, 16);       // Deep plum-ink outline

    // Tabby Cat Fur (Warm orange / golden ginger with rich stripes)
    public static readonly Color FurDark       = Color.FromArgb(56, 26, 18);       // Deep shadow & stripe core
    public static readonly Color FurStripe     = Color.FromArgb(88, 44, 26);       // Warm chestnut tabby stripe
    public static readonly Color FurStripeMid  = Color.FromArgb(128, 64, 34);      // Stripe edge blend
    public static readonly Color FurBase       = Color.FromArgb(212, 118, 42);     // Vibrant orange tabby base
    public static readonly Color FurMid        = Color.FromArgb(238, 150, 62);     // Honey orange midtone
    public static readonly Color FurLit        = Color.FromArgb(252, 186, 96);     // Golden highlight
    public static readonly Color FurCream      = Color.FromArgb(252, 240, 218);    // Soft white/cream muzzle & paws
    public static readonly Color FurCreamShad  = Color.FromArgb(220, 196, 168);    // Shaded cream
    public static readonly Color EarPink       = Color.FromArgb(236, 156, 150);    // Inner ear delicate pink
    public static readonly Color NosePink      = Color.FromArgb(212, 102, 106);    // Feline nose leather
    public static readonly Color ToePadPink    = Color.FromArgb(224, 136, 138);    // Toe beans soft pads

    // Glowing Amber Feline Eyes
    public static readonly Color EyeRim        = Color.FromArgb(42, 20, 16);
    public static readonly Color EyeAmberDark  = Color.FromArgb(168, 64, 18);
    public static readonly Color EyeAmberMid   = Color.FromArgb(238, 142, 36);
    public static readonly Color EyeGoldLit    = Color.FromArgb(254, 226, 108);
    public static readonly Color EyePupil      = Color.FromArgb(20, 10, 16);
    public static readonly Color EyeSparkle    = Color.FromArgb(255, 255, 255);

    // Red Neckerchief (Khăn rằn đỏ — Vietnamese plaid scarf)
    public static readonly Color ScarfOutline  = Color.FromArgb(36, 12, 14);
    public static readonly Color ScarfDark     = Color.FromArgb(88, 22, 26);       // Dark crimson shadow
    public static readonly Color ScarfBase     = Color.FromArgb(168, 38, 34);      // Rich artisan red
    public static readonly Color ScarfLit      = Color.FromArgb(218, 68, 56);      // Warm scarlet
    public static readonly Color ScarfCheck    = Color.FromArgb(248, 224, 220);    // Cream check threads

    // Indigo Blue Work Shirt (Áo thợ xanh chàm)
    public static readonly Color ShirtOutline  = Color.FromArgb(16, 18, 28);
    public static readonly Color ShirtDark     = Color.FromArgb(24, 30, 48);       // Deep slate navy shadow
    public static readonly Color ShirtBase     = Color.FromArgb(38, 52, 82);       // Indigo blue cloth
    public static readonly Color ShirtMid      = Color.FromArgb(56, 76, 118);      // Midtone indigo
    public static readonly Color ShirtLit      = Color.FromArgb(84, 110, 160);     // Indigo cloth highlight
    public static readonly Color ShirtCuff     = Color.FromArgb(118, 146, 196);    // Rolled sleeve cuff rim

    // Dark Brown Leather Blacksmith Apron (Tạp dề da bò nâu sậm)
    public static readonly Color LeatherOut    = Color.FromArgb(26, 14, 10);
    public static readonly Color LeatherDark   = Color.FromArgb(52, 28, 18);       // Crease shadow
    public static readonly Color LeatherBase   = Color.FromArgb(88, 50, 28);       // Rich cowhide leather
    public static readonly Color LeatherMid    = Color.FromArgb(126, 74, 42);      // Worn leather surface
    public static readonly Color LeatherLit    = Color.FromArgb(162, 104, 60);     // Leather surface sheen
    public static readonly Color BeltLeather   = Color.FromArgb(40, 22, 14);       // Thick waist belt
    public static readonly Color BrassDark     = Color.FromArgb(144, 104, 32);     // Tarnished brass
    public static readonly Color BrassLit      = Color.FromArgb(244, 208, 76);     // Gleaming brass buckle / rivets

    // DARK BLUE / INDIGO TROUSERS (Quần thợ màu xanh chàm) — NON-NEGOTIABLE VISIBLE IN ALL DIRECTIONS!
    public static readonly Color PantOutline   = Color.FromArgb(14, 16, 26);
    public static readonly Color PantDark      = Color.FromArgb(20, 26, 42);       // Deep indigo fold
    public static readonly Color PantBase      = Color.FromArgb(32, 46, 74);       // Rich dark blue indigo
    public static readonly Color PantMid       = Color.FromArgb(48, 68, 108);      // Vivid indigo blue
    public static readonly Color PantLit       = Color.FromArgb(76, 102, 154);     // Trouser fold highlight
    public static readonly Color PantCuff      = Color.FromArgb(104, 134, 188);    // Knee cuff edge

    // Smithing Tools
    public static readonly Color SteelDark     = Color.FromArgb(38, 40, 48);
    public static readonly Color SteelMid      = Color.FromArgb(70, 72, 84);
    public static readonly Color SteelLit      = Color.FromArgb(144, 146, 158);
    public static readonly Color WoodHandle    = Color.FromArgb(114, 66, 36);

    // Helpers
    public static void SetPx(Bitmap b, int x, int y, Color c)
    {
        if (x >= 0 && x < b.Width && y >= 0 && y < b.Height)
            b.SetPixel(x, y, c);
    }

    public static void FillRect(Bitmap b, int x, int y, int w, int h, Color c)
    {
        for (int py = y; py < y + h; py++)
            for (int px = x; px < x + w; px++)
                SetPx(b, px, py, c);
    }

    public static void FillDisk(Bitmap b, int cx, int cy, int r, Color c)
    {
        for (int dy = -r; dy <= r; dy++)
        {
            int dxMax = (int)Math.Sqrt(Math.Max(0, r * r - dy * dy));
            for (int dx = -dxMax; dx <= dxMax; dx++)
                SetPx(b, cx + dx, cy + dy, c);
        }
    }

    public static void FillOval(Bitmap b, int cx, int cy, int rx, int ry, Color c)
    {
        for (int dy = -ry; dy <= ry; dy++)
        {
            int dxMax = (int)Math.Round(Math.Sqrt(Math.Max(0, (1.0 - (double)(dy * dy) / (ry * ry))) * rx * rx));
            for (int dx = -dxMax; dx <= dxMax; dx++)
                SetPx(b, cx + dx, cy + dy, c);
        }
    }

    public static Bitmap SealOutlineOnMagenta(Bitmap src)
    {
        Bitmap dst = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < src.Height; y++)
        {
            for (int x = 0; x < src.Width; x++)
            {
                Color c = src.GetPixel(x, y);
                if (c.R == 255 && c.G == 0 && c.B == 255)
                {
                    bool neighborChar = false;
                    for (int dy = -1; dy <= 1; dy++)
                    {
                        for (int dx = -1; dx <= 1; dx++)
                        {
                            if (dx == 0 && dy == 0) continue;
                            int nx = x + dx, ny = y + dy;
                            if (nx >= 0 && nx < src.Width && ny >= 0 && ny < src.Height)
                            {
                                Color nc = src.GetPixel(nx, ny);
                                if (!(nc.R == 255 && nc.G == 0 && nc.B == 255))
                                {
                                    neighborChar = true;
                                    break;
                                }
                            }
                        }
                        if (neighborChar) break;
                    }
                    dst.SetPixel(x, y, neighborChar ? InkOutline : MagentaBg);
                }
                else
                {
                    dst.SetPixel(x, y, c);
                }
            }
        }
        return dst;
    }

    public static Bitmap ScaleNearest(Bitmap src, int targetW, int targetH)
    {
        Bitmap dst = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(dst))
        {
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            g.SmoothingMode = SmoothingMode.None;
            g.DrawImage(src, 0, 0, targetW, targetH);
        }
        return dst;
    }

    // Natural curved cat paw with 3 plump toe beans and soft sole contact
    public static void DrawCatPawSide(Bitmap b, int frontX, int baseY, bool isPlantLeg)
    {
        Color cBase = isPlantLeg ? FurBase : FurDark;
        Color cLit  = isPlantLeg ? FurLit  : FurStripe;
        Color cBean = isPlantLeg ? FurCream: FurCreamShad;

        // Soft curved sole contact line (rounded ends, no harsh corner box)
        FillRect(b, frontX - 12, baseY, 12, 1, InkOutline);
        FillRect(b, frontX - 13, baseY - 1, 14, 1, FurDark);

        // Main paw arch
        FillOval(b, frontX - 7, baseY - 3, 7, 3, cBase);
        FillOval(b, frontX - 6, baseY - 4, 6, 2, cLit);

        // 3 Plump rounded toe beans with soft cream highlights:
        FillOval(b, frontX - 2, baseY - 2, 2, 2, cBean);
        FillOval(b, frontX - 6, baseY - 2, 2, 2, cBean);
        FillOval(b, frontX - 10, baseY - 2, 2, 2, cBean);

        // Warm toe separations:
        SetPx(b, frontX - 4, baseY - 2, FurDark);
        SetPx(b, frontX - 8, baseY - 2, FurDark);

        // Soft pink toe pads peeking underneath
        SetPx(b, frontX - 6, baseY - 1, ToePadPink);
        SetPx(b, frontX - 2, baseY - 1, ToePadPink);
    }

    public static void DrawCatPawFront(Bitmap b, int centerX, int baseY)
    {
        // Curved sole contact line
        FillRect(b, centerX - 6, baseY, 13, 1, InkOutline);
        FillRect(b, centerX - 7, baseY - 1, 15, 1, FurDark);

        // Rounded paw dome
        FillOval(b, centerX, baseY - 3, 7, 3, FurBase);
        FillOval(b, centerX, baseY - 4, 6, 2, FurLit);

        // 3 Plump rounded front toe beans:
        FillOval(b, centerX - 4, baseY - 2, 2, 2, FurCream);
        FillOval(b, centerX,     baseY - 2, 2, 2, FurCream);
        FillOval(b, centerX + 4, baseY - 2, 2, 2, FurCream);

        // Creases between toes:
        SetPx(b, centerX - 2, baseY - 2, FurDark);
        SetPx(b, centerX + 2, baseY - 2, FurDark);

        // Soft pink pads underneath:
        SetPx(b, centerX - 4, baseY - 1, ToePadPink);
        SetPx(b, centerX,     baseY - 1, ToePadPink);
        SetPx(b, centerX + 4, baseY - 1, ToePadPink);
    }

    // =========================================================================
    // 1. SIDE VIEW (Facing Right) — Walk-Ready Stance
    // =========================================================================
    public static Bitmap GenerateSideView(int w = 128, int h = 128)
    {
        Bitmap b = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(b)) { g.Clear(MagentaBg); }

        // --- A. FLUFFY TABBY TAIL ---
        int steps = 40;
        PointF p0 = new PointF(44, 80);
        PointF p1 = new PointF(18, 92);
        PointF p2 = new PointF(14, 60);
        PointF p3 = new PointF(30, 46);

        for (int i = 0; i <= steps; i++)
        {
            double t = (double)i / steps;
            double u = 1.0 - t;
            double cx = u * u * u * p0.X + 3 * u * u * t * p1.X + 3 * u * t * t * p2.X + t * t * t * p3.X;
            double cy = u * u * u * p0.Y + 3 * u * u * t * p1.Y + 3 * u * t * t * p2.Y + t * t * t * p3.Y;

            int r = (i >= steps - 6) ? (steps - i + 2) : 5;
            Color cTail = (i >= steps - 7) ? FurCream : ((i / 4) % 2 == 1 ? FurStripe : FurBase);
            FillDisk(b, (int)Math.Round(cx), (int)Math.Round(cy), r, cTail);
            FillDisk(b, (int)Math.Round(cx), (int)Math.Round(cy) - 1, Math.Max(1, r - 2), (i >= steps - 7) ? FurCream : FurMid);
        }

        // --- B. FAR (LEFT) LEG (Trailing behind) ---
        FillOval(b, 50, 83, 6, 8, PantDark);
        FillRect(b, 46, 89, 8, 3, PantDark);
        for (int s = 0; s <= 8; s++)
        {
            int sx = 48 - s / 3;
            int sy = 92 + s;
            FillRect(b, sx - 2, sy, 5, 1, FurDark);
        }
        FillDisk(b, 45, 101, 3, FurDark);
        for (int s = 0; s <= 12; s++)
        {
            int sx = 45 + (s * 8) / 12;
            int sy = 103 + s;
            FillRect(b, sx - 2, sy, 5, 1, FurDark);
        }
        DrawCatPawSide(b, 54, 115, false);

        // --- C. NEAR (RIGHT) INDIGO TROUSERS — CRITICAL REQUIREMENT ---
        FillOval(b, 59, 81, 11, 10, PantBase);
        FillOval(b, 61, 82, 10, 9, PantMid);
        FillOval(b, 63, 81, 8, 7, PantLit);
        for (int y = 76; y <= 91; y++)
        {
            SetPx(b, 53, y, PantDark);
            SetPx(b, 54, y, PantBase);
        }
        // Baggy trouser leg extending BELOW the apron hem (ends at y = 84)
        FillRect(b, 55, 84, 16, 10, PantBase);
        FillRect(b, 57, 85, 13, 8, PantMid);
        for (int y = 85; y <= 92; y++)
        {
            SetPx(b, 65, y, PantLit);
            SetPx(b, 66, y, PantLit);
        }
        // Rolled knee cuff (y: 94..96) — DISTINCT, SHARP BLUE CUFF!
        FillRect(b, 54, 94, 18, 3, PantDark);
        FillRect(b, 55, 94, 16, 2, PantCuff);
        FillRect(b, 56, 94, 14, 1, Color.FromArgb(146, 176, 228));

        // --- D. NEAR (RIGHT) DIGITIGRADE CAT LEG & SOFT PAW ---
        // 1. Muscular upper shin (knee 64, 97 -> hock 56, 105):
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(64 - 8 * t);
            int cy = 97 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx + 2, cy, FurLit);
            SetPx(b, cx + 3, cy, FurLit);
            SetPx(b, cx - 3, cy, FurDark);
        }
        FillRect(b, 58, 100, 6, 2, FurStripe);

        // 2. Backward-angled Hock Joint (Heel):
        FillDisk(b, 55, 105, 3, FurBase);
        FillOval(b, 54, 105, 2, 2, FurDark);

        // 3. Sturdy pastern flowing smoothly down to paw (hock 56, 106 -> paw 72, 114):
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(56 + 14 * t);
            int cy = 106 + s;
            FillRect(b, cx - 4, cy, 8, 1, FurBase);
            SetPx(b, cx + 2, cy, FurLit);
            SetPx(b, cx + 3, cy, FurLit);
            SetPx(b, cx - 4, cy, FurDark);
        }
        // Smooth bridge from pastern top into paw dome:
        FillRect(b, 67, 111, 4, 3, FurBase);
        FillRect(b, 68, 110, 3, 2, FurLit);

        // 4. Soft Rounded Cat Paw:
        DrawCatPawSide(b, 78, 115, true);

        // --- E. TORSO & INDIGO BLUE WORK SHIRT ---
        FillOval(b, 60, 63, 13, 12, ShirtBase);
        FillOval(b, 61, 62, 11, 10, ShirtMid);
        for (int y = 52; y <= 74; y++)
        {
            SetPx(b, 48, y, ShirtDark);
            SetPx(b, 49, y, ShirtBase);
        }

        // --- F. DARK BROWN LEATHER BLACKSMITH APRON ---
        FillOval(b, 66, 67, 10, 11, LeatherBase);
        FillOval(b, 68, 66, 8, 9, LeatherMid);
        FillOval(b, 70, 65, 6, 7, LeatherLit);
        FillRect(b, 58, 69, 16, 15, LeatherBase);
        FillRect(b, 61, 71, 12, 11, LeatherMid);
        FillRect(b, 56, 84, 18, 2, LeatherDark);
        for (int x = 58; x <= 72; x += 3)
            SetPx(b, x, 83, LeatherLit);

        for (int i = 0; i < 9; i++)
        {
            SetPx(b, 57 + i, 50 + i * 2, LeatherDark);
            SetPx(b, 58 + i, 50 + i * 2, LeatherMid);
        }

        FillRect(b, 51, 71, 23, 4, BeltLeather);
        FillRect(b, 53, 72, 20, 2, LeatherDark);
        FillRect(b, 67, 70, 4, 6, BrassLit);
        FillRect(b, 68, 71, 2, 4, BrassDark);

        FillRect(b, 58, 66, 9, 5, SteelDark);
        FillRect(b, 59, 67, 7, 3, SteelMid);
        FillRect(b, 60, 67, 5, 1, SteelLit);
        for (int i = 0; i < 14; i++)
        {
            SetPx(b, 57 - i / 2, 71 + i, WoodHandle);
            SetPx(b, 58 - i / 2, 71 + i, LeatherDark);
        }

        // --- G. RIGHT ARM (Walk-Ready Stance) ---
        FillOval(b, 62, 59, 6, 7, ShirtBase);
        FillOval(b, 63, 59, 5, 6, ShirtMid);
        FillOval(b, 64, 66, 6, 2, ShirtCuff);
        for (int s = 0; s <= 8; s++)
        {
            int ax = 65 + s / 2;
            int ay = 68 + s;
            FillRect(b, ax - 2, ay, 5, 1, FurBase);
            SetPx(b, ax + 2, ay, FurLit);
            SetPx(b, ax - 2, ay, FurDark);
        }
        FillRect(b, 67, 72, 4, 1, FurStripe);
        FillDisk(b, 71, 78, 3, FurBase);
        FillOval(b, 72, 78, 2, 2, FurCream);
        SetPx(b, 72, 79, ToePadPink);

        // --- H. RED NECKERCHIEF (Khăn Rằn Đỏ) ---
        FillOval(b, 64, 48, 12, 5, ScarfBase);
        FillOval(b, 65, 47, 10, 4, ScarfLit);
        for (int x = 53; x <= 74; x += 3)
            for (int y = 45; y <= 51; y++)
                if ((x + y) % 2 == 0) SetPx(b, x, y, ScarfDark);
        for (int x = 54; x <= 73; x += 4)
            SetPx(b, x, 47, ScarfCheck);
        FillOval(b, 53, 50, 4, 3, ScarfBase);
        FillOval(b, 52, 52, 3, 4, ScarfLit);

        // --- I. CAT HEAD & SIDE PROFILE ---
        FillOval(b, 62, 33, 14, 11, FurBase);
        FillOval(b, 63, 32, 12, 9, FurMid);
        FillOval(b, 64, 31, 10, 7, FurLit);
        FillOval(b, 52, 36, 4, 4, FurBase);
        FillOval(b, 50, 37, 3, 3, FurMid);

        FillRect(b, 57, 24, 3, 6, FurStripe);
        FillRect(b, 62, 25, 3, 5, FurStripe);
        FillRect(b, 54, 30, 5, 2, FurStripe);
        FillRect(b, 53, 34, 6, 2, FurStripe);

        for (int s = 0; s <= 10; s++)
        {
            double t = (double)s / 10.0;
            int ex0 = (int)Math.Round(59 + 7 * t);
            int ex1 = (int)Math.Round(69 - 3 * t);
            int ey  = 24 - s;
            FillRect(b, ex0, ey, Math.Max(1, ex1 - ex0 + 1), 1, FurBase);
        }
        SetPx(b, 66, 14, FurDark);
        FillOval(b, 64, 21, 3, 4, EarPink);
        FillRect(b, 64, 22, 2, 2, FurCream);

        FillOval(b, 53, 20, 4, 6, FurDark);
        FillOval(b, 54, 21, 2, 4, EarPink);

        FillOval(b, 72, 36, 5, 4, FurCream);
        FillOval(b, 74, 37, 4, 3, FurCream);
        FillRect(b, 76, 34, 2, 2, NosePink);
        SetPx(b, 74, 37, FurDark);
        SetPx(b, 75, 38, FurDark);
        SetPx(b, 73, 39, FurDark);

        FillOval(b, 69, 32, 4, 3, EyeRim);
        FillOval(b, 70, 32, 3, 2, EyeAmberMid);
        SetPx(b, 71, 31, EyeGoldLit);
        FillRect(b, 70, 31, 1, 3, EyePupil);
        SetPx(b, 69, 31, EyeSparkle);

        return SealOutlineOnMagenta(b);
    }

    // =========================================================================
    // 2. FRONT VIEW — Upright Stance
    // =========================================================================
    public static Bitmap GenerateFrontView(int w = 128, int h = 128)
    {
        Bitmap b = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(b)) { g.Clear(MagentaBg); }

        int steps = 35;
        PointF p0 = new PointF(68, 84);
        PointF p1 = new PointF(86, 90);
        PointF p2 = new PointF(96, 68);
        PointF p3 = new PointF(88, 48);

        for (int i = 0; i <= steps; i++)
        {
            double t = (double)i / steps;
            double u = 1.0 - t;
            double cx = u * u * u * p0.X + 3 * u * u * t * p1.X + 3 * u * t * t * p2.X + t * t * t * p3.X;
            double cy = u * u * u * p0.Y + 3 * u * u * t * p1.Y + 3 * u * t * t * p2.Y + t * t * t * p3.Y;

            int r = (i >= steps - 5) ? (steps - i + 2) : 5;
            Color cTail = (i >= steps - 6) ? FurCream : ((i / 4) % 2 == 1 ? FurStripe : FurBase);
            FillDisk(b, (int)Math.Round(cx), (int)Math.Round(cy), r, cTail);
            FillDisk(b, (int)Math.Round(cx) - 1, (int)Math.Round(cy) - 1, Math.Max(1, r - 2), (i >= steps - 6) ? FurCream : FurMid);
        }

        // Trousers
        FillOval(b, 64, 83, 17, 10, PantBase);
        FillOval(b, 64, 83, 15, 8, PantMid);

        FillOval(b, 53, 89, 7, 7, PantBase);
        FillOval(b, 53, 89, 5, 5, PantMid);
        FillRect(b, 47, 88, 12, 6, PantBase);
        FillRect(b, 46, 94, 14, 3, PantDark);
        FillRect(b, 47, 94, 12, 2, PantCuff);
        FillRect(b, 48, 94, 10, 1, Color.FromArgb(146, 176, 228));

        FillOval(b, 75, 89, 7, 7, PantBase);
        FillOval(b, 75, 89, 5, 5, PantMid);
        FillRect(b, 69, 88, 12, 6, PantBase);
        FillRect(b, 68, 94, 14, 3, PantDark);
        FillRect(b, 69, 94, 12, 2, PantCuff);
        FillRect(b, 70, 94, 10, 1, Color.FromArgb(146, 176, 228));

        for (int y = 83; y <= 93; y++)
        {
            SetPx(b, 63, y, PantDark);
            SetPx(b, 64, y, PantDark);
        }

        // Left Leg:
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(53 - 3 * t);
            int cy = 96 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx + 2, cy, FurLit);
            SetPx(b, cx - 3, cy, FurDark);
        }
        FillRect(b, 49, 100, 5, 2, FurStripe);
        FillDisk(b, 50, 105, 3, FurBase);
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(50 + 2 * t);
            int cy = 106 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx + 2, cy, FurLit);
        }
        DrawCatPawFront(b, 52, 115);

        // Right Leg:
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(75 + 3 * t);
            int cy = 96 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx - 2, cy, FurLit);
            SetPx(b, cx + 3, cy, FurDark);
        }
        FillRect(b, 74, 100, 5, 2, FurStripe);
        FillDisk(b, 78, 105, 3, FurBase);
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(78 - 2 * t);
            int cy = 106 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx - 2, cy, FurLit);
        }
        DrawCatPawFront(b, 76, 115);

        // Torso & Shirt
        FillOval(b, 64, 62, 19, 11, ShirtBase);
        FillOval(b, 64, 61, 17, 9, ShirtMid);
        FillOval(b, 44, 61, 6, 8, ShirtBase);
        FillOval(b, 84, 61, 6, 8, ShirtBase);
        FillOval(b, 44, 67, 6, 2, ShirtCuff);
        FillOval(b, 84, 67, 6, 2, ShirtCuff);

        FillOval(b, 43, 73, 4, 6, FurBase);
        FillOval(b, 85, 73, 4, 6, FurBase);
        FillDisk(b, 43, 78, 3, FurCream);
        FillDisk(b, 85, 78, 3, FurCream);

        // Apron
        FillRect(b, 54, 56, 20, 27, LeatherBase);
        FillRect(b, 56, 58, 16, 23, LeatherMid);
        FillOval(b, 64, 64, 8, 8, LeatherLit);
        FillRect(b, 52, 82, 24, 2, LeatherDark);
        for (int x = 54; x <= 74; x += 3)
            SetPx(b, x, 82, LeatherLit);

        FillRect(b, 55, 49, 3, 7, LeatherDark);
        FillRect(b, 70, 49, 3, 7, LeatherDark);

        FillRect(b, 49, 71, 30, 4, BeltLeather);
        FillRect(b, 51, 72, 26, 2, LeatherDark);
        FillRect(b, 62, 70, 5, 6, BrassLit);
        FillRect(b, 63, 71, 3, 4, BrassDark);

        FillRect(b, 48, 67, 8, 5, SteelDark);
        FillRect(b, 49, 68, 6, 3, SteelMid);
        FillRect(b, 50, 68, 4, 1, SteelLit);
        FillRect(b, 47, 72, 2, 10, WoodHandle);

        FillRect(b, 77, 68, 4, 12, SteelDark);
        FillRect(b, 78, 69, 2, 10, SteelMid);

        // Scarf
        FillOval(b, 64, 47, 16, 6, ScarfBase);
        FillOval(b, 64, 46, 14, 5, ScarfLit);
        for (int x = 49; x <= 79; x += 3)
            for (int y = 43; y <= 51; y++)
                if ((x + y) % 2 == 0) SetPx(b, x, y, ScarfDark);
        for (int x = 51; x <= 77; x += 4)
            SetPx(b, x, 47, ScarfCheck);

        // Head
        FillOval(b, 64, 32, 17, 12, FurBase);
        FillOval(b, 64, 31, 15, 10, FurMid);
        FillOval(b, 64, 29, 12, 7, FurLit);

        FillOval(b, 47, 35, 5, 5, FurBase);
        FillOval(b, 81, 35, 5, 5, FurBase);
        FillOval(b, 48, 36, 4, 4, FurCream);
        FillOval(b, 80, 36, 4, 4, FurCream);

        for (int s = 0; s <= 11; s++)
        {
            double t = (double)s / 11.0;
            int ex0 = (int)Math.Round(50 + 2 * t);
            int ex1 = (int)Math.Round(60 - 8 * t);
            int ey  = 24 - s;
            FillRect(b, ex0, ey, Math.Max(1, ex1 - ex0 + 1), 1, FurBase);
        }
        SetPx(b, 52, 13, FurDark);
        FillOval(b, 54, 20, 3, 5, EarPink);
        FillRect(b, 54, 21, 2, 2, FurCream);

        for (int s = 0; s <= 11; s++)
        {
            double t = (double)s / 11.0;
            int ex0 = (int)Math.Round(68 + 8 * t);
            int ex1 = (int)Math.Round(78 - 2 * t);
            int ey  = 24 - s;
            FillRect(b, ex0, ey, Math.Max(1, ex1 - ex0 + 1), 1, FurBase);
        }
        SetPx(b, 76, 13, FurDark);
        FillOval(b, 74, 20, 3, 5, EarPink);
        FillRect(b, 72, 21, 2, 2, FurCream);

        FillRect(b, 63, 22, 2, 6, FurStripe);
        FillRect(b, 59, 24, 2, 5, FurStripe);
        FillRect(b, 67, 24, 2, 5, FurStripe);
        FillRect(b, 49, 32, 4, 2, FurStripe);
        FillRect(b, 75, 32, 4, 2, FurStripe);
        FillRect(b, 50, 36, 4, 2, FurStripe);
        FillRect(b, 74, 36, 4, 2, FurStripe);

        FillOval(b, 64, 37, 7, 4, FurCream);
        FillOval(b, 60, 37, 4, 3, FurCream);
        FillOval(b, 68, 37, 4, 3, FurCream);
        FillOval(b, 64, 35, 2, 2, NosePink);
        SetPx(b, 64, 37, FurDark);
        SetPx(b, 62, 38, FurDark);
        SetPx(b, 66, 38, FurDark);

        FillOval(b, 56, 31, 4, 3, EyeRim);
        FillOval(b, 56, 31, 3, 2, EyeAmberMid);
        SetPx(b, 55, 30, EyeGoldLit);
        FillRect(b, 56, 30, 1, 3, EyePupil);
        SetPx(b, 55, 30, EyeSparkle);

        FillOval(b, 72, 31, 4, 3, EyeRim);
        FillOval(b, 72, 31, 3, 2, EyeAmberMid);
        SetPx(b, 73, 30, EyeGoldLit);
        FillRect(b, 72, 30, 1, 3, EyePupil);
        SetPx(b, 71, 30, EyeSparkle);

        return SealOutlineOnMagenta(b);
    }

    // =========================================================================
    // 3. BACK VIEW — Upright Stance
    // =========================================================================
    public static Bitmap GenerateBackView(int w = 128, int h = 128)
    {
        Bitmap b = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(b)) { g.Clear(MagentaBg); }

        int steps = 35;
        PointF p0 = new PointF(64, 82);
        PointF p1 = new PointF(86, 88);
        PointF p2 = new PointF(96, 68);
        PointF p3 = new PointF(88, 48);

        for (int i = 0; i <= steps; i++)
        {
            double t = (double)i / steps;
            double u = 1.0 - t;
            double cx = u * u * u * p0.X + 3 * u * u * t * p1.X + 3 * u * t * t * p2.X + t * t * t * p3.X;
            double cy = u * u * u * p0.Y + 3 * u * u * t * p1.Y + 3 * u * t * t * p2.Y + t * t * t * p3.Y;

            int r = (i >= steps - 5) ? (steps - i + 2) : 5;
            Color cTail = (i >= steps - 6) ? FurCream : ((i / 4) % 2 == 1 ? FurStripe : FurBase);
            FillDisk(b, (int)Math.Round(cx), (int)Math.Round(cy), r, cTail);
            FillDisk(b, (int)Math.Round(cx) - 1, (int)Math.Round(cy) - 1, Math.Max(1, r - 2), (i >= steps - 6) ? FurCream : FurMid);
        }

        // Trousers
        FillOval(b, 64, 82, 18, 11, PantBase);
        FillOval(b, 64, 82, 16, 9, PantMid);
        FillOval(b, 64, 82, 5, 4, PantDark);
        FillRect(b, 63, 75, 2, 19, PantDark);

        FillOval(b, 53, 89, 7, 7, PantBase);
        FillOval(b, 53, 89, 5, 5, PantMid);
        FillRect(b, 46, 94, 14, 3, PantDark);
        FillRect(b, 47, 94, 12, 2, PantCuff);
        FillRect(b, 48, 94, 10, 1, Color.FromArgb(146, 176, 228));

        FillOval(b, 75, 89, 7, 7, PantBase);
        FillOval(b, 75, 89, 5, 5, PantMid);
        FillRect(b, 68, 94, 14, 3, PantDark);
        FillRect(b, 69, 94, 12, 2, PantCuff);
        FillRect(b, 70, 94, 10, 1, Color.FromArgb(146, 176, 228));

        // Legs:
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(53 - 3 * t);
            int cy = 96 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx, cy, FurDark);
        }
        FillRect(b, 49, 100, 5, 2, FurStripe);
        FillDisk(b, 50, 105, 3, FurDark);
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(50 + 2 * t);
            int cy = 106 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
        }
        DrawCatPawFront(b, 52, 115);

        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(75 + 3 * t);
            int cy = 96 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
            SetPx(b, cx, cy, FurDark);
        }
        FillRect(b, 74, 100, 5, 2, FurStripe);
        FillDisk(b, 78, 105, 3, FurDark);
        for (int s = 0; s <= 8; s++)
        {
            double t = (double)s / 8.0;
            int cx = (int)Math.Round(78 - 2 * t);
            int cy = 106 + s;
            FillRect(b, cx - 3, cy, 7, 1, FurBase);
        }
        DrawCatPawFront(b, 76, 115);

        // Torso & Shirt
        FillOval(b, 64, 62, 19, 12, ShirtBase);
        FillOval(b, 64, 61, 17, 10, ShirtMid);
        FillOval(b, 44, 61, 6, 8, ShirtBase);
        FillOval(b, 84, 61, 6, 8, ShirtBase);
        FillOval(b, 44, 67, 6, 2, ShirtCuff);
        FillOval(b, 84, 67, 6, 2, ShirtCuff);
        FillOval(b, 43, 74, 4, 6, FurBase);
        FillOval(b, 85, 74, 4, 6, FurBase);

        // X-back harness
        for (int i = 0; i <= 18; i++)
        {
            double t = (double)i / 18.0;
            int sx = (int)Math.Round(54 + 18 * t);
            int sy = 48 + i * 24 / 18;
            FillRect(b, sx - 1, sy, 3, 1, LeatherDark);
            SetPx(b, sx, sy, LeatherMid);
        }
        for (int i = 0; i <= 18; i++)
        {
            double t = (double)i / 18.0;
            int sx = (int)Math.Round(74 - 18 * t);
            int sy = 48 + i * 24 / 18;
            FillRect(b, sx - 1, sy, 3, 1, LeatherDark);
            SetPx(b, sx, sy, LeatherMid);
        }
        FillDisk(b, 64, 60, 3, BrassLit);
        SetPx(b, 64, 60, BrassDark);

        FillRect(b, 49, 71, 30, 4, BeltLeather);
        FillRect(b, 51, 72, 26, 2, LeatherDark);

        FillRect(b, 47, 67, 7, 5, SteelDark);
        FillRect(b, 46, 72, 2, 10, WoodHandle);
        FillRect(b, 75, 70, 7, 6, LeatherDark);

        // Scarf Back with Plaid Pattern
        FillOval(b, 64, 46, 14, 5, ScarfBase);
        for (int x = 52; x <= 76; x += 3)
            for (int y = 44; y <= 49; y++)
                if ((x + y) % 2 == 0) SetPx(b, x, y, ScarfDark);
        for (int x = 53; x <= 75; x += 4)
            SetPx(b, x, 46, ScarfCheck);

        FillDisk(b, 64, 48, 3, ScarfDark);
        FillDisk(b, 64, 48, 1, ScarfLit);
        FillOval(b, 61, 53, 3, 5, ScarfBase);
        FillOval(b, 66, 54, 3, 6, ScarfLit);

        // Back of Head with natural curved skull stripes
        FillOval(b, 64, 32, 17, 12, FurBase);
        FillOval(b, 64, 31, 15, 10, FurMid);

        // Natural curved tabby stripes tapering down:
        // Center stripe
        FillRect(b, 63, 23, 2, 10, FurStripe);
        // Left curving stripe
        for (int s = 0; s <= 8; s++)
        {
            int sx = 58 + s / 4;
            int sy = 25 + s;
            FillRect(b, sx, sy, 2, 1, FurStripe);
        }
        // Right curving stripe
        for (int s = 0; s <= 8; s++)
        {
            int sx = 68 - s / 4;
            int sy = 25 + s;
            FillRect(b, sx, sy, 2, 1, FurStripe);
        }
        // Outer temple stripes:
        FillRect(b, 52, 29, 3, 6, FurStripe);
        FillRect(b, 73, 29, 3, 6, FurStripe);

        // Back of Triangular Ears:
        for (int s = 0; s <= 11; s++)
        {
            double t = (double)s / 11.0;
            int ex0 = (int)Math.Round(50 + 2 * t);
            int ex1 = (int)Math.Round(60 - 8 * t);
            int ey  = 24 - s;
            FillRect(b, ex0, ey, Math.Max(1, ex1 - ex0 + 1), 1, FurBase);
        }
        FillOval(b, 53, 20, 3, 6, FurStripe);
        SetPx(b, 52, 13, FurDark);

        for (int s = 0; s <= 11; s++)
        {
            double t = (double)s / 11.0;
            int ex0 = (int)Math.Round(68 + 8 * t);
            int ex1 = (int)Math.Round(78 - 2 * t);
            int ey  = 24 - s;
            FillRect(b, ex0, ey, Math.Max(1, ex1 - ex0 + 1), 1, FurBase);
        }
        FillOval(b, 75, 20, 3, 6, FurStripe);
        SetPx(b, 76, 13, FurDark);

        return SealOutlineOnMagenta(b);
    }

    public static void GenerateAll(string outputDir, string artifactDir)
    {
        Directory.CreateDirectory(outputDir);
        if (!string.IsNullOrEmpty(artifactDir))
            Directory.CreateDirectory(artifactDir);

        Console.WriteLine("Generating 100% fresh master pixel art poses for Nấm...");

        // 1. Side View
        using (Bitmap side128 = GenerateSideView(128, 128))
        using (Bitmap side1024 = ScaleNearest(side128, 1024, 1024))
        {
            string p1024 = Path.Combine(outputDir, "nam_side_master.png");
            string p128  = Path.Combine(outputDir, "nam_side_128.png");
            string pJpg  = Path.Combine(outputDir, "nam_side.jpg");
            side1024.Save(p1024, ImageFormat.Png);
            side128.Save(p128, ImageFormat.Png);
            side1024.Save(pJpg, ImageFormat.Jpeg);

            if (!string.IsNullOrEmpty(artifactDir))
            {
                side128.Save(Path.Combine(artifactDir, "preview_nam_side_128.png"), ImageFormat.Png);
                side1024.Save(Path.Combine(artifactDir, "preview_nam_side_1024.png"), ImageFormat.Png);
            }
            Console.WriteLine("Generated Side View: " + p1024);
        }

        // 2. Front View
        using (Bitmap front128 = GenerateFrontView(128, 128))
        using (Bitmap front1024 = ScaleNearest(front128, 1024, 1024))
        {
            string p1024 = Path.Combine(outputDir, "nam_front_master.png");
            string p128  = Path.Combine(outputDir, "nam_front_128.png");
            string pJpg  = Path.Combine(outputDir, "nam_front.jpg");
            front1024.Save(p1024, ImageFormat.Png);
            front128.Save(p128, ImageFormat.Png);
            front1024.Save(pJpg, ImageFormat.Jpeg);

            if (!string.IsNullOrEmpty(artifactDir))
            {
                front128.Save(Path.Combine(artifactDir, "preview_nam_front_128.png"), ImageFormat.Png);
                front1024.Save(Path.Combine(artifactDir, "preview_nam_front_1024.png"), ImageFormat.Png);
            }
            Console.WriteLine("Generated Front View: " + p1024);
        }

        // 3. Back View
        using (Bitmap back128 = GenerateBackView(128, 128))
        using (Bitmap back1024 = ScaleNearest(back128, 1024, 1024))
        {
            string p1024 = Path.Combine(outputDir, "nam_back_master.png");
            string p128  = Path.Combine(outputDir, "nam_back_128.png");
            string pJpg  = Path.Combine(outputDir, "nam_back.jpg");
            back1024.Save(p1024, ImageFormat.Png);
            back128.Save(p128, ImageFormat.Png);
            back1024.Save(pJpg, ImageFormat.Jpeg);

            if (!string.IsNullOrEmpty(artifactDir))
            {
                back128.Save(Path.Combine(artifactDir, "preview_nam_back_128.png"), ImageFormat.Png);
                back1024.Save(Path.Combine(artifactDir, "preview_nam_back_1024.png"), ImageFormat.Png);
            }
            Console.WriteLine("Generated Back View: " + p1024);
        }

        Console.WriteLine("All 3 master poses generated successfully!");
    }
}
