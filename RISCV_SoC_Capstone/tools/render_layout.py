#!/usr/bin/env python3
"""Render a zoomed view of a sky130 GDS showing only the lower layers (no power grid on top).
usage: python3 tools/render_layout.py <gds> <out.png> [cx_um cy_um half_um]
Default window: 80 um square around the router marker at (560.5, 601.1)."""
import sys
import klayout.db as db
import klayout.lay as lay

gds, out = sys.argv[1], sys.argv[2]
cx, cy, half = (float(a) for a in sys.argv[3:6]) if len(sys.argv) >= 6 else (560.5, 601.1, 40.0)
# sky130 layer/datatype -> (name, ARGB colour)
LAYERS = {(65, 20): ("diff", 0x2e8b57), (66, 20): ("poly", 0xcc3333), (67, 20): ("li1", 0xe69f00),
          (68, 20): ("met1", 0x3b6fd4), (69, 20): ("met2", 0xb84fd1), (70, 20): ("met3", 0x00a0a0)}
view = lay.LayoutView()
view.load_layout(gds, True)
view.max_hier()
view.add_missing_layers()
it = view.begin_layers()
while not it.at_end():
    lp = it.current()
    key = (lp.source_layer, lp.source_datatype)
    lp.visible = key in LAYERS
    if key in LAYERS:
        c = LAYERS[key][1]
        lp.fill_color = c; lp.frame_color = c
        lp.dither_pattern = 0 if key[0] in (65, 66, 67) else 1
    view.set_layer_properties(it, lp)
    it.next()
view.set_config("background-color", "#ffffff")
view.zoom_box(db.DBox(cx - half, cy - half, cx + half, cy + half))
view.save_image(out, 1400, 1400)
print("wrote", out, "window um:", cx - half, cy - half, cx + half, cy + half)
