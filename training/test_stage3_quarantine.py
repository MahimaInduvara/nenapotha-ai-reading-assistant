from __future__ import annotations

import csv
import tempfile
import unittest
from pathlib import Path

from stage3_cnn_pipeline import (
    create_provided_split_manifest,
    load_and_verify_manifest,
)


class Stage3QuarantineTest(unittest.TestCase):
    def test_quarantine_excludes_every_path_for_leaking_hash(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = root / "dataset"
            for split in ("train", "valid", "test"):
                for class_id in range(1, 6):
                    folder = dataset / split / str(class_id)
                    folder.mkdir(parents=True)
                    for item in range(3):
                        (folder / f"{item}.png").write_bytes(
                            f"{split}:{class_id}:{item}".encode()
                        )
            (dataset / "test" / "1" / "duplicate.png").write_bytes(
                (dataset / "train" / "1" / "0.png").read_bytes()
            )

            manifest = root / "manifest.csv"
            summary = create_provided_split_manifest(
                dataset,
                manifest,
                seed=42,
                allow_subset=True,
                quarantine_conflicts=True,
            )
            self.assertEqual(summary["originalSampleCount"], 46)
            self.assertEqual(summary["sampleCount"], 44)
            self.assertEqual(summary["excludedPathCount"], 2)
            self.assertEqual(summary["excludedUniqueHashCount"], 1)
            self.assertEqual(summary["crossSplitLeakageHashCount"], 1)
            rows = load_and_verify_manifest(dataset, manifest)
            excluded_hashes = set()
            with manifest.with_suffix(".exclusions.csv").open(
                newline="", encoding="utf-8"
            ) as stream:
                excluded_hashes = {row["sha256"] for row in csv.DictReader(stream)}
            self.assertTrue(excluded_hashes)
            self.assertFalse(any(row.sha256 in excluded_hashes for row in rows))


if __name__ == "__main__":
    unittest.main()
