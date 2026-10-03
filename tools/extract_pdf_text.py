from __future__ import annotations

import sys
from pathlib import Path

from pypdf import PdfReader


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: extract_pdf_text.py INPUT.pdf OUTPUT.txt")

    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    reader = PdfReader(source)
    pages = []
    for index, page in enumerate(reader.pages, start=1):
        pages.append(f"\n--- PAGE {index} ---\n")
        pages.append(page.extract_text() or "")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("\n".join(pages), encoding="utf-8")


if __name__ == "__main__":
    main()
