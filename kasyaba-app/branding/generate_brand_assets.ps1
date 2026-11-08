# Kasyaba brand asset generator (Windows/GDI+, no unsafe)
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class Brand {
  private static byte[] GetBytes(Bitmap bmp, out int stride, out int w, out int h) {
    w = bmp.Width; h = bmp.Height;
    BitmapData d = bmp.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    stride = d.Stride;
    byte[] px = new byte[stride * h];
    Marshal.Copy(d.Scan0, px, 0, px.Length);
    bmp.UnlockBits(d);
    return px;
  }

  public static int[] Measure(Bitmap bmp, int whiteTol) {
    int w, h, stride;
    byte[] px = GetBytes(bmp, out stride, out w, out h);
    int[] rowContent = new int[h];
    int[] colContent = new int[w];
    for (int y=0; y<h; y++) {
      int rowStart = y*stride;
      for (int x=0; x<w; x++) {
        int i = rowStart + x*4;
        int b=px[i], g=px[i+1], r=px[i+2];
        int dist = Math.Max(255-r, Math.Max(255-g, 255-b));
        if (dist > whiteTol) { rowContent[y]++; colContent[x]++; }
      }
    }
    List<int> bands = new List<int>();
    int bandStart = -1;
    for (int y=0; y<h; y++) {
      bool on = rowContent[y] > w*0.004f;
      if (on && bandStart < 0) bandStart = y;
      if (!on && bandStart >= 0) { bands.Add(bandStart); bands.Add(y); bandStart = -1; }
    }
    if (bandStart >= 0) { bands.Add(bandStart); bands.Add(h); }
    int top = bands[0], bottom;
    if (bands.Count >= 4) bottom = bands[bands.Count-2]; else bottom = bands[bands.Count-1];
    int left=w, right=0;
    for (int x=0; x<w; x++) if (colContent[x] > 0) { left = x; break; }
    for (int x=w-1; x>=0; x--) if (colContent[x] > 0) { right = x; break; }
    return new int[]{left, top, right-left+1, bottom-top};
  }

  public static Bitmap KeyWhite(Bitmap src, int hardTol) {
    Bitmap bmp = (Bitmap)src.Clone();
    int w, h, stride;
    byte[] px = GetBytes(bmp, out stride, out w, out h);
    int softHi = hardTol + 6;
    for (int y=0; y<h; y++) {
      int rowStart = y*stride;
      for (int x=0; x<w; x++) {
        int i = rowStart + x*4;
        int b=px[i], g=px[i+1], r=px[i+2];
        int dist = Math.Max(255-r, Math.Max(255-g, 255-b));
        if (dist < hardTol) px[i+3] = 0;
        else if (dist < softHi) {
          int a = px[i+3] * (dist - hardTol) / (softHi - hardTol);
          px[i+3] = (byte)a;
        }
      }
    }
    BitmapData d = bmp.LockBits(new Rectangle(0,0,w,h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    Marshal.Copy(px, 0, d.Scan0, px.Length);
    bmp.UnlockBits(d);
    return bmp;
  }

  public static Bitmap CenterCompose(Bitmap art, int canvas, float artRatio, Color bg) {
    Bitmap outB = new Bitmap(canvas, canvas, PixelFormat.Format32bppArgb);
    using (Graphics g = Graphics.FromImage(outB)) {
      g.SmoothingMode = SmoothingMode.AntiAlias;
      g.InterpolationMode = InterpolationMode.HighQualityBicubic;
      if (!bg.IsEmpty) { using (SolidBrush br = new SolidBrush(bg)) g.FillRectangle(br, 0, 0, canvas, canvas); }
      int size = (int)(canvas * artRatio);
      DrawScaled(g, art, new Rectangle((canvas-size)/2, (canvas-size)/2, size, size));
    }
    return outB;
  }

  public static void DrawScaled(Graphics g, Image src, Rectangle dst) {
    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
    g.DrawImage(src, dst, 0, 0, src.Width, src.Height, GraphicsUnit.Pixel);
  }

  public static Bitmap SquarePad(Bitmap art, float padRatio) {
    int longest = Math.Max(art.Width, art.Height);
    int side = longest + (int)(longest*padRatio);
    Bitmap outB = new Bitmap(side, side, PixelFormat.Format32bppArgb);
    using (Graphics g = Graphics.FromImage(outB)) {
      g.SmoothingMode = SmoothingMode.AntiAlias; g.InterpolationMode = InterpolationMode.HighQualityBicubic;
      g.DrawImage(art, (side-art.Width)/2, (side-art.Height)/2, art.Width, art.Height);
    }
    return outB;
  }

  public static Bitmap Resize(Bitmap src, int w, int h) {
    Bitmap outB = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    using (Graphics g = Graphics.FromImage(outB)) { DrawScaled(g, src, new Rectangle(0,0,w,h)); }
    return outB;
  }

  public static void SavePng(Bitmap b, string path) { b.Save(path, ImageFormat.Png); }
}
"@

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Output "root=$root"
$srcPath = Join-Path $root 'logo.jpg'
$src = New-Object System.Drawing.Bitmap($srcPath)
Write-Output ("source: {0}x{1}" -f $src.Width, $src.Height)

# 1) artwork bounding box (drops the bottom wordmark band)
$box = [Brand]::Measure($src, 24)
Write-Output ("bbox: left={0} top={1} w={2} h={3}" -f $box[0],$box[1],$box[2],$box[3])
$pad = [int]($box[2] * 0.03)
$cx = [Math]::Max(0, $box[0] - $pad)
$cw = [Math]::Min($src.Width - $cx, $box[2] + $pad*2)
$cy = [Math]::Max(0, $box[1] - $pad)
$ch = [Math]::Min($src.Height - $cy, $box[3] + $pad*2)
$rect = New-Object System.Drawing.Rectangle($cx, $cy, $cw, $ch)
$art = $src.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$src.Dispose()

# 2) chroma-key near-white -> transparent (hard cut + soft edge ramp)
$mark = [Brand]::KeyWhite($art, 14)
[Brand]::SavePng($mark, (Join-Path $root 'icon_mark.png'))
Write-Output ("mark: {0}x{1}" -f $mark.Width, $mark.Height)

# 3) square-pad
$sq = [Brand]::SquarePad($mark, 0.06)

# 4) adaptive foreground (mark at 62%, safe-zone sized)
$fg = [Brand]::CenterCompose($sq, 1024, 0.62, [System.Drawing.Color]::Empty)
[Brand]::SavePng($fg, (Join-Path $root 'icon_foreground.png'))

# 5) legacy tile (image_path, minSdk 24 devices): navy + mark at 74%
$navy = [System.Drawing.Color]::FromArgb(255, 0x0A, 0x12, 0x20)
$tile = [Brand]::CenterCompose($sq, 1024, 0.74, $navy)
[Brand]::SavePng($tile, (Join-Path $root 'icon_navy_legacy.png'))

# 6) Play 512 listing icon + in-app mark asset (PNG conversions of the navy composition)
$play = [Brand]::Resize($tile, 512, 512)
[Brand]::SavePng($play, (Join-Path $root 'play_icon_512.png'))
$assetDir = Join-Path (Split-Path -Parent $root) 'assets\images\brand'
New-Item -ItemType Directory -Force $assetDir | Out-Null
$inapp = [Brand]::Resize($mark, 512, 512)
[Brand]::SavePng($inapp, (Join-Path $assetDir 'kasyaba_mark.png'))
Write-Output "done"
