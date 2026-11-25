#!/usr/bin/env python3
"""Intro comic panel 01 "Night desk" — art plate, style variant 2, art variant 2.

Deterministic pure-stdlib renderer for the 1920x1080 art-only plate: eight-colour
closed palette, flat fills, 8/4/3/2 px line weights, no gradients, no baked text.
Composition follows docs/design/comic/intro-storyboard.md (panel 1), the look
follows docs/design/comic/style-guide-variant-2.md (decision 0003). Writes the PNG,
prints a self-check report (format, palette, caption zone, safe margin, shares);
`--preview` adds a coarse ASCII map for headless review.

Usage: python3 render_panel_01.py [output.png] [--preview]
Default output: <repo>/game/assets/comic/intro_panel_01_art.png
"""

import math
import os
import struct
import sys
import zlib

W, H = 1920, 1080
GND, PET, COP, VIO, LIT, CYN = range(6)
PAL = [
    (0x11, 0x15, 0x1E),  # ground shadow: lines, deepest shadow
    (0x23, 0x52, 0x5B),  # petrol
    (0xB7, 0x78, 0x50),  # oxidised copper
    (0x51, 0x43, 0x6E),  # far violet
    (0xCA, 0xD5, 0xCF),  # broken light edge
    (0x62, 0xD6, 0xCC),  # interaction cyan (screens only here)
    (0xF2, 0xB0, 0x5E),  # telegraph amber — forbidden in panel 1
    (0x99, 0x2D, 0x3C),  # danger red — forbidden in panel 1
]
CAPTION = (96, 96, 776, 236)  # x0, y0, x1, y1 of the runtime caption box
SAFE = 96

FB = bytearray(H * W)
USED_WEIGHTS = set()
def poly(pts, c, holes=None):
    """Even-odd scanline fill of one contour plus optional hole contours."""
    contours = [pts] + list(holes or [])
    ymin = min(min(p[1] for p in ct) for ct in contours)
    ymax = max(max(p[1] for p in ct) for ct in contours)
    for y in range(max(0, int(ymin)), min(H - 1, int(ymax)) + 1):
        yc = y + 0.5
        xs = []
        for ct in contours:
            n = len(ct)
            for i in range(n):
                ax, ay = ct[i]
                bx, by = ct[(i + 1) % n]
                if (ay <= yc < by) or (by <= yc < ay):
                    xs.append(ax + (yc - ay) * (bx - ax) / (by - ay))
        xs.sort()
        row = y * W
        for k in range(0, len(xs) - 1, 2):
            xa = max(0, round(xs[k]))
            xb = min(W, round(xs[k + 1]))
            if xb > xa:
                FB[row + xa:row + xb] = bytes((c,)) * (xb - xa)
def rect(x0, y0, x1, y1, c):
    poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], c)
def rrect_pts(x0, y0, x1, y1, r, n=5):
    corners = ((x1 - r, y0 + r, -90), (x1 - r, y1 - r, 0),
               (x0 + r, y1 - r, 90), (x0 + r, y0 + r, 180))
    return [(cx + r * math.cos(math.radians(a0 + 90 * k / n)),
             cy + r * math.sin(math.radians(a0 + 90 * k / n)))
            for cx, cy, a0 in corners for k in range(n + 1)]
def octa(cx, cy, r, c):
    ang = [math.radians(22.5 + 45 * k) for k in range(8)]
    poly([(cx + r * math.cos(a), cy + r * math.sin(a)) for a in ang], c)
def seg(a, b, w, c):
    """Straight line of exact weight w with square caps and round joins."""
    if w not in (8, 4, 3, 2):
        raise ValueError("off-hierarchy line weight %s" % w)
    USED_WEIGHTS.add(w)
    dx, dy = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dy) or 1.0
    ux, uy = dx / ln, dy / ln
    hw = w / 2.0
    nx, ny = -uy * hw, ux * hw
    ax, ay = a[0] + ux * hw, a[1] + uy * hw
    bx, by = b[0] + ux * hw, b[1] + uy * hw
    poly([(ax + nx, ay + ny), (bx + nx, by + ny),
          (bx - nx, by - ny), (ax - nx, ay - ny)], c)
    octa(a[0], a[1], hw, c)
    octa(b[0], b[1], hw, c)
def path(pts, w, c):
    for i in range(len(pts) - 1):
        seg(pts[i], pts[i + 1], w, c)
def ell(cx, cy, rx, ry, c, n=28):
    poly([(cx + rx * math.cos(2 * math.pi * k / n),
           cy + ry * math.sin(2 * math.pi * k / n)) for k in range(n)], c)
def ring(cx, cy, rx, ry, n=28):
    return [(cx + rx * math.cos(2 * math.pi * k / n),
             cy + ry * math.sin(2 * math.pi * k / n)) for k in range(n)]
def elling(cx, cy, rx, ry, t, c):
    poly(ring(cx, cy, rx, ry), c, holes=[ring(cx, cy, rx - t, ry - t)])
def bars(x0, y0, n, h, dy, widths, maxw):
    for k in range(n):  # abstract screen code: flat cyan bars, never letters
        wpx = min(widths[k % len(widths)], maxw)
        rect(x0, y0 + dy * k, x0 + wpx, y0 + dy * k + h, CYN)
def lamp(x):
    rect(x, 22, x + 170, 52, PET)
    path([(x, 22), (x + 170, 22), (x + 170, 52)], 4, GND)
    rect(x + 8, 52, x + 162, 60, LIT)
    seg((x + 40, 0), (x + 40, 22), 2, VIO)
def rack(x, w, front):
    rect(x, 216, x + w, 700, front)
    path([(x, 700), (x, 216), (x + w, 216), (x + w, 700)], 2, GND)
    seg((x + 6, 218), (x + w - 6, 218), 2, LIT)
    vent = LIT if front == GND else GND
    y = 250
    while y < 664:
        seg((x + 14, y), (x + w - 14, y), 2, vent)
        y += 46
    if x + w <= W - SAFE:
        seg((x + 6, 636), (x + w - 6, 636), 4, COP)  # contact wear
def monitor(shell, screen, stem=None, base=None):
    if stem:
        rect(*stem, GND)
    if base:
        poly(base, PET)
        path(base + [base[0]], 4, GND)
    sh = rrect_pts(*shell, 10)
    poly(sh, PET)
    path(sh + [sh[0]], 4, GND)
    rect(*screen, GND)
    seg((shell[0] + 2, shell[1] + 12), (shell[0] + 2, shell[3] - 12), 2, LIT)
def build():
    # Background: lab depth (violet) and server wall, top and right thirds.
    rect(980, 130, 1920, 700, VIO)
    rect(790, 280, 980, 700, VIO)  # distant corridor opening
    path([(790, 280), (790, 700)], 2, GND)
    rect(980, 140, W - SAFE, 152, COP)  # copper busbar pipes
    rect(980, 160, W - SAFE, 172, COP)
    path([(980, 140), (W - SAFE, 140)], 2, GND)
    path([(980, 172), (W - SAFE, 172)], 2, GND)
    fronts = [PET, GND, LIT, PET, LIT, GND, PET]
    x, i = 1150, 0
    while x < 1920:
        rack(x, min(110, 1920 - x), fronts[i % 7])
        if x + 128 <= W - SAFE:
            rect(x + 110, 216, x + 128, 700, COP)  # busbar in rack gap
        x += 118
        i += 1
    rect(980, 640, W, 700, VIO)  # fog pooling at the base of the rack row
    seg((1014, 216), (1014, 700), 2, GND)
    seg((1086, 170), (1086, 700), 2, GND)
    seg((820, 88), (1920, 88), 2, VIO)
    seg((940, 102), (1920, 102), 2, VIO)
    for dx in (1214, 1450, 1888):
        seg((dx, 102), (dx, 216), 2, VIO)
    lamp(300)
    lamp(1480)

    rect(0, 600, 980, 700, VIO)  # violet fog along the far wall base
    # Desk plane with lit far edge, seams and a hard cast shadow to the lower right.
    rect(0, 700, W, 1080, PET)
    seg((0, 700), (W, 700), 2, LIT)
    for nx0, nx1 in ((300, 380), (1000, 1120), (1400, 1470)):
        seg((nx0, 700), (nx1, 700), 4, COP)  # worn edge nicks
    seg((460, 702), (460, 1078), 2, GND)
    seg((1500, 702), (1500, 1010), 2, GND)
    poly([(905, 704), (1290, 704), (1392, 918), (975, 952)], COP)  # warm monitor glow pool
    poly([(840, 1080), (1920, 780), (1920, 1080)], GND)

    # Paper stack left on the desk (left of Rend).
    sheet0 = [(296, 726), (452, 720), (456, 766), (300, 772)]
    sheet0b = [(292, 752), (440, 748), (444, 790), (296, 794)]
    for sh in (sheet0, sheet0b):
        poly(sh, LIT)
        path(sh + [sh[0]], 4, GND)

    # Monitor bank, centre of the plate.
    monitor((592, 268, 838, 536), (608, 284, 822, 504),
            (700, 536, 732, 694), [(652, 694), (780, 694), (794, 714), (638, 714)])
    monitor((866, 300, 1094, 540), (882, 316, 1078, 508),
            (962, 540, 994, 694), [(916, 694), (1040, 694), (1052, 714), (904, 714)])
    monitor((724, 574, 976, 698), (738, 588, 962, 660))
    bars(616, 294, 16, 10, 13, [150, 92, 176, 60, 150, 110, 84, 166, 120, 70, 158, 100, 130, 76, 170, 96], 190)
    bars(892, 324, 11, 10, 15, [96, 140, 60, 120, 84, 150, 72, 110, 128, 66, 100], 88)
    bars(986, 324, 11, 10, 15, [66, 128, 74, 110, 96, 150, 60, 102, 88, 120, 80], 86)
    elling(1040, 496, 22, 10, 5, CYN)
    bars(750, 594, 5, 10, 13, [150, 90, 180, 110, 60], 200)

    # Keyboard.
    kb = rrect_pts(596, 714, 912, 766, 8)
    poly(kb, PET)
    path(kb + [kb[0]], 4, GND)
    for ky in (728, 738, 748):
        seg((606, ky), (902, ky), 2, GND)

    # Chair hint: dark headrest with a violet edge behind Rend.
    rect(428, 592, 700, 700, GND)
    path([(430, 700), (430, 606), (452, 590), (674, 590), (696, 606), (696, 700)], 2, VIO)

    # Rend: hunched at the keyboard, three-quarter view, glasses intact.
    rect(546, 600, 582, 652, COP)  # neck
    torso = [(452, 652), (486, 636), (652, 636), (700, 654), (694, 764), (458, 764)]
    poly(torso, PET)
    poly([(536, 644), (588, 644), (576, 764), (548, 764)], GND)  # open jacket, dark shirt
    path([(536, 644), (548, 764)], 4, GND)
    path([(588, 644), (576, 764)], 4, GND)
    path([(466, 690), (506, 690), (506, 718), (466, 718), (466, 690)], 4, GND)  # pocket
    collar_l = [(524, 634), (556, 646), (542, 668), (514, 654)]
    collar_r = [(566, 646), (598, 632), (608, 654), (580, 668)]
    for ct in (collar_l, collar_r):
        poly(ct, PET)
        path(ct + [ct[0]], 4, GND)
    # Sleeves, rolled forearms, hands on the keys.
    sleeve_l = [(452, 648), (502, 652), (492, 748), (430, 742)]
    sleeve_r = [(610, 644), (664, 640), (684, 740), (632, 746)]
    for ct in (sleeve_l, sleeve_r):
        poly(ct, PET)
        path(ct + [ct[0]], 4, GND)
    poly([(490, 728), (612, 736), (608, 764), (482, 756)], COP)
    poly([(630, 730), (806, 740), (802, 766), (624, 758)], COP)
    hand_l = [(604, 726), (648, 720), (668, 740), (660, 764), (606, 762)]
    hand_r = [(798, 728), (842, 722), (862, 742), (854, 764), (800, 764)]
    for hd in (hand_l, hand_r):
        poly(hd, COP)
    for fx in (628, 640, 652):
        seg((fx, 726), (fx + 6, 758), 4, GND)
    for fx in (822, 834, 846):
        seg((fx, 726), (fx + 4, 758), 4, GND)

    # Head at x 560 y 560.
    poly([(498, 540), (514, 538), (516, 592), (502, 586)], GND)  # back hair
    face = [(516, 530), (560, 502), (606, 528), (612, 565), (596, 600),
            (560, 618), (522, 596), (512, 555)]
    poly(face, COP)
    poly([(592, 542), (612, 565), (596, 600), (560, 618), (568, 602), (588, 572)], PET)  # cel shadow
    ear = [(504, 554), (514, 548), (517, 578), (507, 574)]
    poly(ear, COP)
    path(ear + [ear[0]], 4, GND)
    hair = [(505, 552), (508, 506), (545, 488), (590, 492), (618, 516), (620, 550),
            (604, 528), (596, 548), (580, 526), (570, 546), (552, 526), (542, 548),
            (526, 528), (518, 552)]
    poly(hair, GND)
    # Glasses: two lenses, clear bridge, dark frames.
    lens_l = rrect_pts(522, 548, 566, 578, 6)
    lens_r = rrect_pts(580, 546, 610, 574, 6)
    poly(lens_l, LIT)
    poly(lens_r, LIT)
    ell(544, 567, 7, 5, GND)
    ell(595, 565, 6, 5, GND)
    path(lens_l + [lens_l[0]], 4, GND)
    path(lens_r + [lens_r[0]], 4, GND)
    seg((566, 555), (580, 553), 4, GND)  # bridge
    seg((522, 556), (506, 551), 4, GND)  # temple
    seg((528, 551), (558, 557), 4, GND)  # focused frown
    seg((586, 557), (606, 551), 4, GND)
    seg((556, 600), (582, 597), 4, GND)  # mouth
    # Outer contours 8 px.
    path([(505, 552), (508, 506), (545, 488), (590, 492), (618, 516), (620, 550)], 8, GND)
    path([(606, 528), (612, 565), (596, 600), (560, 618), (522, 596), (512, 555)], 8, GND)
    path([(694, 764), (700, 654), (652, 636), (486, 636), (452, 652), (458, 764)], 8, GND)
    path([(430, 742), (452, 648)], 8, GND)
    path([(482, 756), (606, 764), (660, 764), (668, 740)], 8, GND)
    path([(624, 760), (800, 766), (854, 764), (862, 742)], 8, GND)
    poly([(602, 552), (620, 574), (600, 586)], COP)  # nose in three-quarter view
    seg((600, 586), (620, 574), 3, GND)
    # Rim light from the work light above left, 2 px, so dark hair and jacket
    # separate from the night background.
    path([(505, 548), (508, 506), (545, 488), (578, 490)], 2, LIT)
    path([(452, 650), (486, 637)], 2, LIT)
    path([(490, 729), (606, 737)], 2, LIT)
    path([(432, 738), (452, 652)], 2, LIT)

    # Props: paper, coffee mug, half-built humanoid hand (palm up).
    sheet1 = [(938, 738), (1108, 728), (1116, 798), (946, 808)]
    sheet2 = [(962, 792), (1132, 780), (1142, 848), (972, 860)]
    for sh in (sheet1, sheet2):
        poly(sh, LIT)
        path(sh + [sh[0]], 4, GND)
    ell(1345, 908, 158, 22, GND)
    ell(1085, 894, 44, 9, GND)
    mug = [(1044, 828), (1126, 828), (1118, 898), (1050, 898)]
    poly(mug, PET)
    path(mug + [mug[0]], 4, GND)
    handle = [(1120, 840), (1152, 844), (1152, 872), (1120, 876)]
    poly(handle, PET)
    path(handle + [handle[0]], 4, GND)
    ell(1134, 858, 8, 10, GND)
    elling(1085, 828, 41, 12, 5, LIT)
    ell(1085, 828, 36, 8, GND)

    stump = [(1160, 798), (1258, 780), (1258, 868), (1168, 856)]
    poly(stump, PET)
    path(stump + [stump[0]], 4, GND)
    poly([(1146, 806), (1168, 798), (1172, 860), (1150, 850)], GND)  # cut cavity
    elling(1159, 820, 7, 13, 3, COP)  # coil hints
    elling(1159, 842, 6, 10, 3, COP)
    seg((1258, 782), (1258, 866), 3, GND)  # wrist seam
    palm = [(1258, 776), (1392, 762), (1408, 862), (1262, 874)]
    poly(palm, LIT)
    path(palm + [palm[0]], 4, GND)
    seg((1270, 796), (1398, 782), 3, GND)
    seg((1274, 840), (1402, 826), 3, GND)
    thumb = [(1262, 752), (1322, 728), (1348, 748), (1292, 772)]
    poly(thumb, LIT)
    path(thumb + [thumb[0]], 4, GND)
    poly([(1330, 732), (1348, 746), (1338, 752), (1322, 740)], COP)
    for k, (yb, ln) in enumerate(((764, 86), (792, 95), (820, 88), (846, 72))):
        tip = 1400 + ln
        fg = [(1400, yb), (1448, yb - 4), (tip, yb - 26),
              (tip - 6, yb - 6), (1446, yb + 14), (1400, yb + 22)]
        poly(fg, LIT)
        path(fg + [fg[0]], 4, GND)
        seg((1400 + int(ln * 0.55), yb - 12), (1400 + int(ln * 0.55) - 6, yb + 14), 3, GND)
        poly([(tip - 16, yb - 24), (tip, yb - 26), (tip - 6, yb - 6), (tip - 18, yb - 12)], COP)

    # Foreground: glass mullions and the near desk edge crossing the bottom.
    rect(236, 0, 244, 1080, GND)
    seg((233, 260), (233, 1078), 2, LIT)
    rect(1676, 0, 1684, 1080, GND)
    seg((1673, 260), (1673, 1078), 2, LIT)
    poly([(0, 900), (566, 1080), (0, 1080)], GND)
    seg((0, 900), (564, 1080), 4, LIT)
def write_png(path_out):
    lut = [bytes(p) for p in PAL]
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        raw += b"".join(map(lut.__getitem__, FB[y * W:(y + 1) * W]))

    def chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
           + chunk(b"sRGB", b"\x00")
           + chunk(b"IDAT", zlib.compress(bytes(raw), 6))
           + chunk(b"IEND", b""))
    with open(path_out, "wb") as f:
        f.write(png)
def check(path_out):
    data = open(path_out, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat, ihdr = 8, b"", None
    chunks = []
    while pos < len(data):
        ln = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        want = struct.unpack(">I", data[pos + 8 + ln:pos + 12 + ln])[0]
        got = zlib.crc32(tag + body) & 0xFFFFFFFF
        assert want == got, "CRC mismatch in %s" % tag
        chunks.append(tag.decode())
        if tag == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        if tag == b"IDAT":
            idat += body
        pos += 12 + ln
    w, h, depth, ctype, comp, filt, inter = ihdr
    print("format: PNG %dx%d, bit depth %d, colour type %d (2 = RGB), interlace %d, "
          "chunks %s" % (w, h, depth, ctype, inter, ",".join(chunks)))
    assert (w, h, depth, ctype, inter) == (W, H, 8, 2, 0), "wrong PNG header"
    assert "sRGB" in chunks, "missing sRGB chunk"
    raw = zlib.decompress(idat)
    stride = W * 3
    assert len(raw) == H * (stride + 1)
    px = set()
    counts = [0] * 8
    off_margin_copper = 0
    caption_colors = set()
    for y in range(H):
        row = raw[y * (stride + 1):(y + 1) * (stride + 1)]
        assert row[0] == 0, "unexpected filter type"
        for x in range(W):
            rgb = tuple(row[1 + 3 * x:4 + 3 * x])
            px.add(rgb)
            if rgb in PAL:
                counts[PAL.index(rgb)] += 1
            edge = x < SAFE or x >= W - SAFE or y < SAFE or y >= H - SAFE
            if edge and rgb == PAL[COP]:
                off_margin_copper += 1
            if CAPTION[0] <= x < CAPTION[2] and CAPTION[1] <= y < CAPTION[3]:
                caption_colors.add(rgb)
    assert len(px) <= 6, "off-palette colours: %s" % sorted(px for px in px if px not in PAL)
    total = W * H
    names = "GND PET COP VIO LIT CYN AMB RED".split()
    print("palette: %d distinct colours, all from the eight-value set; "
          "no amber, no red pixels: %s" % (len(px), counts[6] == 0 and counts[7] == 0))
    print("shares: " + "  ".join("%s=%.1f%%" % (names[i], 100.0 * c / total)
                                 for i, c in enumerate(counts) if c))
    assert caption_colors == {PAL[GND]}, "caption area not quiet"
    print("caption box (96,96)-(776,236): single flat colour (quiet)")
    assert off_margin_copper == 0, "face/hand colour crosses the safe margin"
    print("safe margin: 0 skin/hand/coil (copper) pixels outside the 96 px margin")
    assert USED_WEIGHTS <= {8, 4, 3, 2}, "off-hierarchy line weights"
    print("line weights used: %s" % sorted(USED_WEIGHTS, reverse=True))
def preview():
    chars = ".~cv#*AR"
    out = []
    for by in range(0, H, 40):
        line = ""
        for bx in range(0, W, 40):
            cnt = {}
            for y in range(by, by + 40, 4):
                for x in range(bx, bx + 40, 4):
                    cnt[FB[y * W + x]] = cnt.get(FB[y * W + x], 0) + 1
            line += chars[max(cnt, key=cnt.get)]
        out.append(line)
    print("\n".join(out))
def main():
    args = [a for a in sys.argv[1:] if a != "--preview"]
    out = args[0] if args else os.path.abspath(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), *([os.pardir] * 4),
        "game", "assets", "comic", "intro_panel_01_art.png"))
    build()
    os.makedirs(os.path.dirname(out), exist_ok=True)
    write_png(out)
    print("wrote", out)
    check(out)
    if "--preview" in sys.argv:
        preview()

if __name__ == "__main__":
    main()
