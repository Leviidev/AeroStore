import fs from "node:fs";
import path from "node:path";
import zlib from "node:zlib";

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & (-(c & 1)));
  }
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const t = Buffer.from(type, "ascii");
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}

function writePngRGBA({ width, height, rgba }) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0;
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const compressed = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([
    signature,
    chunk("IHDR", ihdr),
    chunk("IDAT", compressed),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

function clamp01(x) {
  return x < 0 ? 0 : x > 1 ? 1 : x;
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function mixColor(c1, c2, t) {
  return [
    lerp(c1[0], c2[0], t),
    lerp(c1[1], c2[1], t),
    lerp(c1[2], c2[2], t),
    lerp(c1[3], c2[3], t),
  ];
}

function srgbToByte(x) {
  return Math.round(clamp01(x) * 255);
}

function skyColor(u, v) {
  const top = [0.04, 0.52, 0.98, 1.0];
  const mid = [0.18, 0.70, 1.0, 1.0];
  const bottom = [0.42, 0.86, 0.98, 1.0];
  const t = clamp01(v * 1.05);
  if (t < 0.55) return mixColor(top, mid, t / 0.55);
  return mixColor(mid, bottom, (t - 0.55) / 0.45);
}

function pointInTri(px, py, ax, ay, bx, by, cx, cy) {
  const v0x = cx - ax;
  const v0y = cy - ay;
  const v1x = bx - ax;
  const v1y = by - ay;
  const v2x = px - ax;
  const v2y = py - ay;
  const dot00 = v0x * v0x + v0y * v0y;
  const dot01 = v0x * v1x + v0y * v1y;
  const dot02 = v0x * v2x + v0y * v2y;
  const dot11 = v1x * v1x + v1y * v1y;
  const dot12 = v1x * v2x + v1y * v2y;
  const inv = 1 / (dot00 * dot11 - dot01 * dot01);
  const u = (dot11 * dot02 - dot01 * dot12) * inv;
  const v = (dot00 * dot12 - dot01 * dot02) * inv;
  return u >= 0 && v >= 0 && u + v <= 1;
}

function drawIcon(size) {
  const w = size;
  const h = size;
  const buf = Buffer.alloc(w * h * 4);

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const u = x / (w - 1);
      const v = y / (h - 1);
      const c = skyColor(u, v);
      const idx = (y * w + x) * 4;
      buf[idx] = srgbToByte(c[0]);
      buf[idx + 1] = srgbToByte(c[1]);
      buf[idx + 2] = srgbToByte(c[2]);
      buf[idx + 3] = 255;
    }
  }

  const ax = w * 0.50;
  const ay = h * 0.20;
  const blx = w * 0.22;
  const bly = h * 0.80;
  const brx = w * 0.78;
  const bry = h * 0.80;
  const barY0 = h * 0.58;
  const barY1 = h * 0.67;
  const barX0 = w * 0.31;
  const barX1 = w * 0.69;

  const wingAx = w * 0.54;
  const wingAy = h * 0.34;
  const wingBx = w * 0.86;
  const wingBy = h * 0.46;
  const wingCx = w * 0.80;
  const wingCy = h * 0.54;

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const px = x + 0.5;
      const py = y + 0.5;
      let a = 0;
      if (pointInTri(px, py, ax, ay, blx, bly, brx, bry)) a = 1;
      if (py >= barY0 && py <= barY1 && px >= barX0 && px <= barX1) a = 1;
      if (pointInTri(px, py, wingAx, wingAy, wingBx, wingBy, wingCx, wingCy)) a = 1;
      if (a <= 0) continue;
      const idx = (y * w + x) * 4;
      buf[idx] = 255;
      buf[idx + 1] = 255;
      buf[idx + 2] = 255;
      buf[idx + 3] = 255;
    }
  }

  return { width: w, height: h, rgba: buf };
}

function main() {
  const repoRoot = process.cwd();
  const appIconDir = path.join(
    repoRoot,
    "AltStore",
    "Resources",
    "Icons.xcassets",
    "AppIcon.appiconset"
  );

  const sizes = [
    20, 29, 40, 50, 57, 58, 60, 72, 76, 80, 87, 100, 114, 120, 144, 152, 167, 180, 1024,
  ];

  for (const s of sizes) {
    const outPath = path.join(appIconDir, `${s}.png`);
    fs.writeFileSync(outPath, writePngRGBA(drawIcon(s)));
  }

  const classicAppPath = path.join(
    repoRoot,
    "AltStore",
    "Resources",
    "Icons.xcassets",
    "Classic",
    "App.imageset",
    "App.png"
  );
  if (fs.existsSync(classicAppPath)) {
    fs.writeFileSync(classicAppPath, writePngRGBA(drawIcon(512)));
  }

  console.log("Generated AeroStore app icon PNGs.");
}

main();
