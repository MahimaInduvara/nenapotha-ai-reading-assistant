from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


def _font(size: int):
    candidates = [
        Path("C:/Windows/Fonts/arial.ttf"),
        Path("C:/Windows/Fonts/calibri.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: make_screenshot_contact_sheet.py INPUT_DIR OUTPUT.png")

    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    paths = sorted(source.glob("*.png"))
    if not paths:
        raise SystemExit(f"No PNG screenshots found in {source}")

    columns = 4
    panel_width = 200
    panel_height = 400
    label_height = 36
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * panel_width, rows * panel_height), "#E9EEF8")
    draw = ImageDraw.Draw(sheet)
    label_font = _font(12)

    for index, path in enumerate(paths):
        image = Image.open(path).convert("RGB")
        image.thumbnail((panel_width - 24, panel_height - label_height - 24), Image.Resampling.LANCZOS)
        image = ImageOps.expand(image, border=2, fill="#334155")
        column = index % columns
        row = index // columns
        x = column * panel_width + (panel_width - image.width) // 2
        y = row * panel_height + 8
        sheet.paste(image, (x, y))
        label = path.stem.replace("_", " ")
        draw.text(
            (column * panel_width + panel_width // 2, row * panel_height + panel_height - 24),
            label,
            fill="#0F172A",
            font=label_font,
            anchor="mm",
        )

    target.parent.mkdir(parents=True, exist_ok=True)
    if target.suffix.lower() in {".jpg", ".jpeg"}:
        sheet.save(target, quality=72, optimize=True)
    else:
        sheet.save(target, optimize=True)


if __name__ == "__main__":
    main()
