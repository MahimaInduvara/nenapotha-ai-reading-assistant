from __future__ import annotations

import sys
from pathlib import Path

import pythoncom
import pywintypes
from win32com.client import dynamic


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: finalize_thesis_word.py INPUT.docx OUTPUT.pdf")

    docx_path = Path(sys.argv[1]).resolve()
    pdf_path = Path(sys.argv[2]).resolve()
    pdf_path.parent.mkdir(parents=True, exist_ok=True)

    pythoncom.CoInitialize()
    word = None
    document = None
    try:
        clsid = pywintypes.IID("{000209FF-0000-0000-C000-000000000046}")
        dispatch = pythoncom.CoCreateInstance(
            clsid,
            None,
            pythoncom.CLSCTX_LOCAL_SERVER,
            pythoncom.IID_IDispatch,
        )
        word = dynamic.Dispatch(dispatch)
        word.Visible = False
        word.DisplayAlerts = 0
        word.Options.UpdateFieldsAtPrint = True

        document = word.Documents.Open(str(docx_path), False, False)
        document.Fields.Update()
        for index in range(1, document.TablesOfContents.Count + 1):
            document.TablesOfContents.Item(index).Update()
        story = document.StoryRanges.Item(1)
        while story is not None:
            story.Fields.Update()
            story = story.NextStoryRange
        document.Repaginate()
        document.Save()
        document.ExportAsFixedFormat(str(pdf_path), 17)
        print(f"DOCX={docx_path}")
        print(f"PDF={pdf_path}")
        print(f"PAGES={document.ComputeStatistics(2)}")
    finally:
        if document is not None:
            document.Close(False)
        if word is not None:
            word.Quit()
        pythoncom.CoUninitialize()


if __name__ == "__main__":
    main()
