from __future__ import annotations

import sys
from pathlib import Path

import fitz


def main() -> None:
    if len(sys.argv) < 4:
        raise SystemExit("Usage: render_pdf_spotcheck.py INPUT.pdf OUTPUT_DIR PAGE...")

    source = Path(sys.argv[1])
    output = Path(sys.argv[2])
    pages = [int(value) for value in sys.argv[3:]]
    output.mkdir(parents=True, exist_ok=True)

    document = fitz.open(source)
    for page_number in pages:
        page = document.load_page(page_number - 1)
        pixmap = page.get_pixmap(matrix=fitz.Matrix(1.35, 1.35), alpha=False)
        target = output / f"page_{page_number:03d}.png"
        pixmap.save(target)
        print(target)


if __name__ == "__main__":
    main()
