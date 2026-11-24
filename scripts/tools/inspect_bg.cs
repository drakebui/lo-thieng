using System;
using System.Drawing;
using System.Drawing.Imaging;

class InspectBg {
    static void Main() {
        Bitmap bmp = new Bitmap("assets/pixel/backgrounds/workshop_hub_bg_640x360.png");
        Console.WriteLine($"Image size: {bmp.Width}x{bmp.Height}");
        // In 640x360:
        // Left door: around x=80-120, y=140-270
        // Anvil: around x=200-280, y=170-240
        // Bed: around x=440-520, y=150-230
        bmp.Dispose();
    }
}
