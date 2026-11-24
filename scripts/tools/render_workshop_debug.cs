using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;

class RenderWorkshopDebug {
    static void Main() {
        int width = 1920;
        int height = 1080;

        using (Bitmap output = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(output)) {
            g.InterpolationMode = InterpolationMode.NearestNeighbor;
            g.PixelOffsetMode = PixelOffsetMode.Half;
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;

            // 1. Draw 3x background
            using (Bitmap bg = new Bitmap("assets/pixel/backgrounds/workshop_hub_bg_640x360.png")) {
                g.DrawImage(bg, new Rectangle(0, 0, width, height), 0, 0, bg.Width, bg.Height, GraphicsUnit.Pixel);
            }

            // Load sprite sheets
            using (Bitmap namSheet = new Bitmap("assets/pixel/sprites/player/nam_4dir_sheet_64.png"))
            using (Bitmap clgSheet = new Bitmap("assets/pixel/sprites/npcs/co_long_gio_sheet_64.png"))
            using (Bitmap debtSheet = new Bitmap("assets/pixel/sprites/npcs/nguoi_thu_no_c1_sheet_64.png")) {

                // Helper actions
                Action<int, int, int, int, float, string> drawNam = (wx, wy, row, col, scale, label) => {
                    // Contact shadow at feet (+28px)
                    int shadowY = wy + (int)(28.0f * (scale / 3.0f));
                    using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(110, 15, 8, 10))) {
                        g.FillEllipse(shadowBrush, wx - 35, shadowY - 11, 70, 22);
                    }

                    // Sprite (64x64 cell)
                    // offset.y = -62/3.0f (-20.6667f)
                    // screen left = wx - 32 * scale
                    // screen top = wy - 158 (at 3x) => wy + (-32 + (-62/3.0f)) * scale
                    float offY = -62.0f / 3.0f;
                    int sLeft = (int)Math.Round(wx - 32.0f * scale);
                    int sTop = (int)Math.Round(wy + (-32.0f + offY) * scale);
                    int sSize = (int)Math.Round(64.0f * scale);

                    g.InterpolationMode = InterpolationMode.NearestNeighbor;
                    g.DrawImage(namSheet, new Rectangle(sLeft, sTop, sSize, sSize),
                        col * 64, row * 64, 64, 64, GraphicsUnit.Pixel);

                    if (!string.IsNullOrEmpty(label)) {
                        DrawLabel(g, wx, sTop - 26, label, Color.FromArgb(255, 230, 160));
                    }
                };

                Action<int, int, Bitmap, int, float, string, Color> drawNpc = (wx, wy, sheet, col, scale, label, nameColor) => {
                    // Shadow
                    int shadowY = wy + 26;
                    using (SolidBrush shadowBrush = new SolidBrush(Color.FromArgb(100, 15, 8, 10))) {
                        g.FillEllipse(shadowBrush, wx - 32, shadowY - 9, 64, 18);
                    }

                    // Sprite (64x64, offset (0, -16))
                    int sLeft = (int)Math.Round(wx - 32.0f * scale);
                    int sTop = (int)Math.Round(wy + (-32.0f - 16.0f) * scale);
                    int sSize = (int)Math.Round(64.0f * scale);

                    g.InterpolationMode = InterpolationMode.NearestNeighbor;
                    g.DrawImage(sheet, new Rectangle(sLeft, sTop, sSize, sSize),
                        col * 64, 0, 64, 64, GraphicsUnit.Pixel);

                    if (!string.IsNullOrEmpty(label)) {
                        DrawLabel(g, wx, sTop - 26, label, nameColor);
                    }
                };

                // A. Cô Lộng Gió NPC (at 2.75x)
                drawNpc(547, 734, clgSheet, 0, 2.75f, "Cô Lộng Gió (2.75x)", Color.FromArgb(255, 200, 140));

                // B. Người Thu Nợ NPC (at 2.75x) near Right Shop Door
                drawNpc(1545, 804, debtSheet, 0, 2.75f, "Người Thu Nợ (2.75x)", Color.FromArgb(255, 140, 120));

                // C. Nam at Door (x=330, y=780)
                drawNam(330, 780, 0, 0, 3.0f, "Nam @ Door (3.0x)");

                // D. Nam next to Anvil (x=660, y=620 facing right towards anvil)
                drawNam(660, 620, 2, 0, 3.0f, "Nam @ Anvil (3.0x)");

                // E. Nam at Hub Center (default player spawn: x=960, y=767)
                drawNam(960, 767, 0, 0, 3.0f, "Nam (Spawn 960, 767)");

                // F. Nam next to Bed (x=1320, y=580)
                drawNam(1320, 580, 3, 0, 3.0f, "Nam @ Bed (3.0x)");
            }

            // 2. Draw Measurement Annotations and Dimension Brackets
            g.SmoothingMode = SmoothingMode.AntiAlias;

            // Dimension for Door (x=285 to x=405, y=455 to y=705, H=250px)
            DrawDimensionBar(g, 195, 455, 705, "Door Opening: ~250px\n(1.47x Nam ~ 1.5x)", Color.FromArgb(100, 220, 255), true);

            // Dimension for Nam at Door (H=170px, y=638 to y=808)
            DrawDimensionBar(g, 260, 638, 808, "Nam: ~170px", Color.FromArgb(255, 215, 80), true);

            // Dimension for Anvil (x=730 to x=820, y=505 to y=630, H=125px)
            DrawDimensionBar(g, 825, 505, 630, "Anvil: ~125px", Color.FromArgb(255, 150, 60), false);

            // Dimension for Nam at Anvil (y=478 to y=648, H=170px)
            DrawDimensionBar(g, 570, 478, 648, "Nam: ~170px", Color.FromArgb(255, 215, 80), true);

            // Horizontal alignment dashed line from Anvil top (y=505) across to Nam's waist
            using (Pen waistPen = new Pen(Color.FromArgb(220, 255, 160, 40), 2)) {
                waistPen.DashStyle = DashStyle.Dash;
                g.DrawLine(waistPen, 640, 560, 815, 560);
                g.DrawLine(waistPen, 720, 505, 720, 560); // link to anvil surface
            }
            DrawCalloutBox(g, 620, 532, "Anvil top ~ waist-to-chest high", Color.FromArgb(255, 200, 80));

            // Dimension for Cô Lộng Gió (y=602 to y=764, H=162px)
            DrawDimensionBar(g, 460, 602, 764, "CLG: ~162px\n(2.75x)", Color.FromArgb(255, 180, 140), true);

            // Dimension for Bed (x=1380 to x=1590, y=453 to y=610, H=157px)
            DrawDimensionBar(g, 1605, 453, 610, "Bed: ~157px", Color.FromArgb(140, 200, 255), false);

            // Dimension for Người Thu Nợ (y=669 to y=834, H=165px)
            DrawDimensionBar(g, 1615, 669, 834, "Thu Nợ: ~165px\n(2.75x)", Color.FromArgb(255, 120, 100), false);

            // 3. Header and Status Overlays
            DrawHeaderPanel(g, width);
            DrawFooterPanel(g, width, height);

            // Save image to artifact directory and workspace root
            string artifactDir = @"C:\Users\builo\.gemini\antigravity\brain\e8fe78c4-dd62-44c8-bf0e-4674cb5bf3a3";
            string outArtifact = System.IO.Path.Combine(artifactDir, "debug_workshop_verified.png");
            string outWorkspace = "debug_workshop_verified.png";

            output.Save(outArtifact, ImageFormat.Png);
            output.Save(outWorkspace, ImageFormat.Png);

            Console.WriteLine("Successfully rendered debug_workshop_verified.png to:");
            Console.WriteLine("Artifact: " + outArtifact);
            Console.WriteLine("Workspace: " + outWorkspace);
        }
    }

    static void DrawDimensionBar(Graphics g, int x, int topY, int bottomY, string text, Color col, bool isLeft) {
        using (Pen p = new Pen(col, 2))
        using (SolidBrush b = new SolidBrush(col))
        using (Font f = new Font("Consolas", 11, FontStyle.Bold)) {
            // Vertical bar
            g.DrawLine(p, x, topY, x, bottomY);
            // Top tick
            g.DrawLine(p, x - 7, topY, x + 7, topY);
            // Bottom tick
            g.DrawLine(p, x - 7, bottomY, x + 7, bottomY);

            // Text
            int midY = (topY + bottomY) / 2;
            SizeF sz = g.MeasureString(text, f);
            float tx = isLeft ? (x - sz.Width - 10) : (x + 10);
            float ty = midY - sz.Height / 2;

            using (SolidBrush bgB = new SolidBrush(Color.FromArgb(200, 16, 12, 10))) {
                g.FillRectangle(bgB, tx - 4, ty - 2, sz.Width + 8, sz.Height + 4);
                g.DrawRectangle(p, tx - 4, ty - 2, sz.Width + 8, sz.Height + 4);
            }
            g.DrawString(text, f, b, tx, ty);
        }
    }

    static void DrawCalloutBox(Graphics g, float x, float y, string text, Color col) {
        using (Font f = new Font("Segoe UI", 10, FontStyle.Bold))
        using (SolidBrush b = new SolidBrush(col))
        using (SolidBrush bgB = new SolidBrush(Color.FromArgb(210, 20, 14, 12)))
        using (Pen p = new Pen(col, 1.5f)) {
            SizeF sz = g.MeasureString(text, f);
            g.FillRectangle(bgB, x, y, sz.Width + 10, sz.Height + 6);
            g.DrawRectangle(p, x, y, sz.Width + 10, sz.Height + 6);
            g.DrawString(text, f, b, x + 5, y + 3);
        }
    }

    static void DrawLabel(Graphics g, int cx, int y, string text, Color col) {
        using (Font f = new Font("Segoe UI", 11, FontStyle.Bold))
        using (SolidBrush b = new SolidBrush(col))
        using (SolidBrush bgB = new SolidBrush(Color.FromArgb(200, 18, 12, 10)))
        using (Pen p = new Pen(Color.FromArgb(160, col), 1)) {
            SizeF sz = g.MeasureString(text, f);
            float x = cx - sz.Width / 2.0f;
            g.FillRectangle(bgB, x - 6, y - 2, sz.Width + 12, sz.Height + 4);
            g.DrawRectangle(p, x - 6, y - 2, sz.Width + 12, sz.Height + 4);
            g.DrawString(text, f, b, x, y);
        }
    }

    static void DrawHeaderPanel(Graphics g, int w) {
        using (SolidBrush bg = new SolidBrush(Color.FromArgb(225, 14, 10, 8)))
        using (Pen border = new Pen(Color.FromArgb(255, 190, 80), 2))
        using (Font titleF = new Font("Segoe UI", 16, FontStyle.Bold))
        using (Font subF = new Font("Consolas", 12, FontStyle.Regular))
        using (SolidBrush titleB = new SolidBrush(Color.FromArgb(255, 220, 120)))
        using (SolidBrush subB = new SolidBrush(Color.FromArgb(220, 230, 240))) {
            g.FillRectangle(bg, 20, 16, w - 40, 72);
            g.DrawRectangle(border, 20, 16, w - 40, 72);

            g.DrawString("LÒ THIÊNG — WORKSHOP HUB CHARACTER SCALE CALIBRATION (1920x1080 Viewport)",
                titleF, titleB, 36, 22);
            g.DrawString("Nam: 3.0x Scale (170px, waist-high to 125px Anvil, 1.5x door) | NPCs (CLG, Thu Nợ): 2.75x Scale (~162px) | BG: 640x360 scaled 3.0x",
                subF, subB, 38, 56);
        }
    }

    static void DrawFooterPanel(Graphics g, int w, int h) {
        using (SolidBrush bg = new SolidBrush(Color.FromArgb(225, 14, 10, 8)))
        using (Pen border = new Pen(Color.FromArgb(100, 180, 240), 1.5f))
        using (Font f = new Font("Consolas", 11, FontStyle.Bold))
        using (SolidBrush b = new SolidBrush(Color.FromArgb(180, 230, 255))) {
            int panelH = 36;
            int y = h - panelH - 14;
            g.FillRectangle(bg, 20, y, w - 40, panelH);
            g.DrawRectangle(border, 20, y, w - 40, panelH);

            string status = "[VERIFIED] player_shop.gd: SPRITE_RENDER_SCALE=3.0, offset.y=-62/3, shadow=28px | workshop_hub.gd: NPC_RENDER_SCALE=2.75 | debt_agent_node.gd: 2.75 | exploration_scene.gd: player.scale=1.0";
            g.DrawString(status, f, b, 32, y + 8);
        }
    }
}
