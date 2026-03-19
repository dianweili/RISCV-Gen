#!/usr/bin/env python3
"""Parse VCD files and render readable waveform PNG images using PIL."""

import re, os
from PIL import Image, ImageDraw, ImageFont

# ── fonts ─────────────────────────────────────────────────────────────────────
def load_font(size):
    for p in [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/truetype/freefont/FreeMono.ttf",
    ]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def load_bold(size):
    for p in [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
    ]:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return load_font(size)

F14  = load_font(14)
F12  = load_font(12)
F10  = load_font(10)
FB16 = load_bold(16)
FB14 = load_bold(14)

# ── colours ───────────────────────────────────────────────────────────────────
BG        = (18, 20, 30)
PANEL     = (28, 30, 45)
BORDER    = (55, 60, 85)
GRID      = (40, 44, 62)
CLK_C     = (0,  210, 255)
HI_C      = (50, 220, 110)
LO_C      = (40, 170,  80)
BUS_C     = (255, 195,  50)
BUS_BG    = (50,  40,   0)
X_C       = (160,  60,  60)
TITLE_C   = (255, 230, 100)
LABEL_C   = (170, 205, 255)
TIME_C    = (120, 120, 160)
PASS_C    = (0,   220,  80)
FAIL_C    = (255,  60,  60)

# ── VCD parser ────────────────────────────────────────────────────────────────
def parse_vcd(path, want_names):
    """Return (changes, name2width).
    changes   : {name: [(time, value_str)]}
    name2width: {name: bit_width}
    """
    id2name  = {}   # symbol -> name
    name2width = {} # name   -> bit width   ← keyed by NAME, not symbol
    changes  = {}
    cur_time = 0
    with open(path, 'r', errors='replace') as f:
        text = f.read()
    for m in re.finditer(r'\$var\s+\S+\s+(\d+)\s+(\S+)\s+(\S+)', text):
        width, sym, name = int(m.group(1)), m.group(2), m.group(3)
        if name in want_names and sym not in id2name:
            id2name[sym]    = name
            name2width[name] = width          # fixed: store by name
    for name in want_names:
        changes[name] = []
    for line in text.split('\n'):
        line = line.strip()
        if not line:
            continue
        if line.startswith('#'):
            try: cur_time = int(line[1:])
            except ValueError: pass
            continue
        if line.startswith(('b','B')):
            parts = line.split()
            if len(parts) == 2:
                val_str, sym = parts[0][1:], parts[1]
                if sym in id2name:
                    changes[id2name[sym]].append((cur_time, val_str))
            continue
        if len(line) >= 2 and line[0] in '01xXzZ':
            sym = line[1:]
            if sym in id2name:
                changes[id2name[sym]].append((cur_time, line[0]))
    return changes, name2width

def bits_to_int(s):
    s = s.lower().replace('x','0').replace('z','0')
    try: return int(s, 2)
    except ValueError: return None

def sample_at(evts, t):
    val = 'x'
    for et, ev in evts:
        if et <= t: val = ev
        else: break
    return val

# ── layout constants ──────────────────────────────────────────────────────────
IMG_W      = 1600
LABEL_W    = 170
RIGHT_PAD  = 20
WAVE_W     = IMG_W - LABEL_W - RIGHT_PAD   # 1410
TRACE_H    = 52
TRACE_PAD  = 10
TITLE_H    = 36
HEADER_H   = 24   # time axis row
TOP_PAD    = 14

def wave_x(i, n):
    """pixel x for sample index i out of n."""
    return LABEL_W + int(i * WAVE_W / n)

def draw_text_centered(draw, text, cx, cy, font, fill):
    try:
        w = draw.textlength(text, font=font)
    except AttributeError:
        w = len(text) * 7
    draw.text((cx - w/2, cy - 7), text, font=font, fill=fill)

# ── renderer ──────────────────────────────────────────────────────────────────
def render(title, vcd_path, signals, n_samples=60, out_path=None):
    want = set(signals)
    changes, name2width = parse_vcd(vcd_path, want)

    # Gather time range
    all_t = []
    for name in signals:
        for t,_ in changes.get(name, []):
            all_t.append(t)
    if not all_t:
        print(f"  [skip] {title}: no data"); return

    t_min, t_max = min(all_t), max(all_t)
    if t_max == t_min: t_max = t_min + 1

    # Sample times (evenly spaced)
    N = n_samples
    stimes = [t_min + (t_max - t_min) * i // max(N-1,1) for i in range(N)]

    # Pre-compute samples
    sampled = {}
    for name in signals:
        evts = sorted(changes.get(name,[]))
        sampled[name] = [sample_at(evts, st) for st in stimes]

    n_sig = len(signals)
    img_h = TOP_PAD + TITLE_H + HEADER_H + n_sig*(TRACE_H+TRACE_PAD) + TOP_PAD
    img   = Image.new('RGB', (IMG_W, img_h), BG)
    draw  = ImageDraw.Draw(img)

    # Title bar
    draw.rectangle([(0,0),(IMG_W, TOP_PAD+TITLE_H)], fill=(25,25,40))
    draw.text((12, TOP_PAD+4), title, font=FB16, fill=TITLE_C)

    # Time axis
    ty = TOP_PAD + TITLE_H + 2
    draw.rectangle([(0,ty),(IMG_W, ty+HEADER_H)], fill=(22,22,38))
    for i in range(0, N, max(1, N//10)):
        px = wave_x(i, N)
        t_val = stimes[i]
        label = f"{t_val//1000}ns" if t_val >= 1000 else f"{t_val}ps"
        draw.line([(px, ty), (px, ty+HEADER_H)], fill=BORDER)
        draw.text((px+3, ty+4), label, font=F10, fill=TIME_C)

    # Vertical grid lines
    base_y = TOP_PAD + TITLE_H + HEADER_H
    grid_h = n_sig * (TRACE_H + TRACE_PAD)
    for i in range(0, N, max(1, N//20)):
        px = wave_x(i, N)
        draw.line([(px, base_y), (px, base_y+grid_h)], fill=GRID)

    # Separator between label panel and wave area
    draw.line([(LABEL_W-1, base_y), (LABEL_W-1, base_y+grid_h)], fill=BORDER, width=1)

    # Each signal trace
    for si, name in enumerate(signals):
        y0   = base_y + si * (TRACE_H + TRACE_PAD) + TRACE_PAD//2
        y1   = y0 + TRACE_H
        ymid = (y0+y1)//2
        ytop = y0 + 4
        ybot = y1 - 4

        # Label panel
        draw.rectangle([(0, y0),(LABEL_W-2, y1)], fill=PANEL)
        # right-align label
        try:
            lw = draw.textlength(name, font=F14)
        except AttributeError:
            lw = len(name)*8
        draw.text((LABEL_W - lw - 8, ymid-8), name, font=F14, fill=LABEL_C)

        # Trace background
        draw.rectangle([(LABEL_W, y0),(IMG_W-RIGHT_PAD, y1)], fill=(20,21,32))

        width  = name2width.get(name, 1)
        is_bus = width > 1
        svals  = sampled[name]

        if is_bus:
            # First pass: draw fills and borders
            for i in range(N):
                x0 = wave_x(i, N)
                x1 = wave_x(i+1, N)
                val = svals[i]
                iv  = bits_to_int(val) if 'x' not in val.lower() else None
                col = BUS_C if iv is not None else X_C
                bg  = BUS_BG if iv is not None else (40,10,10)
                draw.rectangle([(x0+1, ytop+1),(x1-1, ybot-1)], fill=bg)
                draw.line([(x0, ytop),(x1, ytop)], fill=col, width=2)
                draw.line([(x0, ybot),(x1, ybot)], fill=col, width=2)
                if i == 0 or svals[i-1] != val:
                    draw.line([(x0, ytop),(x0, ybot)], fill=col, width=2)
            # Second pass: draw value labels at the start of each run
            i = 0
            while i < N:
                val = svals[i]
                # find run end
                j = i + 1
                while j < N and svals[j] == val:
                    j += 1
                # compute run pixel span
                rx0 = wave_x(i, N)
                rx1 = wave_x(j, N)
                iv  = bits_to_int(val) if 'x' not in val.lower() else None
                if iv is not None:
                    if width >= 32:   txt = f"0x{iv:08X}"
                    elif width >= 16: txt = f"0x{iv:04X}"
                    elif width >= 8:  txt = f"0x{iv:02X}"
                    else:             txt = f"{iv}"
                    try:    tw = draw.textlength(txt, font=F12)
                    except: tw = len(txt)*7
                    run_w = rx1 - rx0 - 8
                    if tw <= run_w:
                        col = BUS_C
                        draw.text((rx0 + (run_w-tw)//2 + 4, ymid-7),
                                  txt, font=F12, fill=col)
                i = j
        else:
            # 1-bit: iterate over each sample
            for i in range(N):
                x0  = wave_x(i, N)
                x1  = wave_x(i+1, N)
                val = svals[i]
                hi  = val == '1'
                if name == 'clk':
                    col = CLK_C
                elif name == 'test_pass':
                    col = PASS_C if hi else HI_C
                elif name == 'test_fail':
                    col = FAIL_C if hi else LO_C
                else:
                    col = HI_C if hi else LO_C
                py = ytop if hi else ybot
                draw.line([(x0, py),(x1, py)], fill=col, width=3)
                if i > 0 and svals[i-1] != val:
                    prev_py = ytop if svals[i-1] == '1' else ybot
                    draw.line([(x0, prev_py),(x0, py)], fill=col, width=2)

        # Trace border
        draw.rectangle([(LABEL_W, y0),(IMG_W-RIGHT_PAD, y1)],
                        outline=BORDER, width=1)

    if out_path:
        img.save(out_path)
        print(f"  saved → {out_path}")

# ── per-file configs ──────────────────────────────────────────────────────────
CONFIGS = [
    dict(vcd="/project/RISCV-Gen/alu.vcd",
         title="ALU Unit Test — Waveform",
         signals=["a","b","op","result"],
         n_samples=40,
         out="waveform_alu.png"),
    dict(vcd="/project/RISCV-Gen/regfile.vcd",
         title="Register File Test — Waveform",
         signals=["clk","wen","rs1_addr","rs2_addr","rd_addr","rd_data","rs1_data","rs2_data"],
         n_samples=48,
         out="waveform_regfile.png"),
    dict(vcd="/project/RISCV-Gen/arith_test.vcd",
         title="Arithmetic Instructions Pipeline — Waveform",
         signals=["clk","rst_n","if_pc","if_inst","ex_alu_result","wb_data","test_pass","test_fail"],
         n_samples=56,
         out="waveform_arith.png"),
    dict(vcd="/project/RISCV-Gen/branch_test.vcd",
         title="Branch Instructions Pipeline — Waveform",
         signals=["clk","rst_n","if_pc","ex_branch_taken","if_id_flush","pc_stall","test_pass","test_fail"],
         n_samples=56,
         out="waveform_branch.png"),
    dict(vcd="/project/RISCV-Gen/load_store_test.vcd",
         title="Load/Store Instructions Pipeline — Waveform",
         signals=["clk","rst_n","if_pc","dmem_addr","dmem_wdata","dmem_rdata","dmem_wen_byte","test_pass","test_fail"],
         n_samples=56,
         out="waveform_load_store.png"),
    dict(vcd="/project/RISCV-Gen/hazard_test.vcd",
         title="Hazard Detection & Forwarding — Waveform",
         signals=["clk","rst_n","if_pc","pc_stall","id_ex_stall","fwd_a","fwd_b","test_pass","test_fail"],
         n_samples=56,
         out="waveform_hazard.png"),
    dict(vcd="/project/RISCV-Gen/boot_test.vcd",
         title="Boot / Reset Test — Waveform",
         signals=["clk","rst_n","if_pc","if_inst","test_pass","test_fail"],
         n_samples=50,
         out="waveform_boot.png"),
]

if __name__ == "__main__":
    out_dir = "/project/RISCV-Gen/docs/screenshots"
    os.makedirs(out_dir, exist_ok=True)
    for cfg in CONFIGS:
        print(f"Processing: {cfg['title']}")
        render(
            title=cfg["title"],
            vcd_path=cfg["vcd"],
            signals=cfg["signals"],
            n_samples=cfg["n_samples"],
            out_path=os.path.join(out_dir, cfg["out"]),
        )
    print("\nDone.")
