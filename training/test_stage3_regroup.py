from __future__ import annotations

import csv
import tempfile
import unittest
from pathlib import Path

from stage3_cnn_pipeline import (
    create_regrouped_manifest_from_provided_splits,
    load_and_verify_manifest,
)


class Stage3RegroupTest(unittest.TestCase):
    def test_contaminated_publisher_splits_are_deduplicated_and_regrouped(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = root / "dataset"
            for source_split in ("train", "valid", "test"):
                for class_id in range(1, 6):
                    folder = dataset / source_split / str(class_id)
                    folder.mkdir(parents=True)
                    for item in range(4):
                        (folder / f"{item}.png").write_bytes(
                            f"{source_split}:{class_id}:{item}".encode()
                        )

            (dataset / "test" / "1" / "same_class_duplicate.png").write_bytes(
                (dataset / "train" / "1" / "1.png").read_bytes()
            )
            (dataset / "test" / "2" / "cross_class_conflict.png").write_bytes(
                (dataset / "train" / "1" / "0.png").read_bytes()
            )

            manifest = root / "regrouped.csv"
            summary = create_regrouped_manifest_from_provided_splits(
                dataset,
                manifest,
                seed=42,
                allow_subset=True,
                quarantine_conflicts=True,
            )
            self.assertEqual(summary["originalPathCount"], 62)
            self.assertEqual(summary["sampleCount"], 59)
            self.assertEqual(summary["excludedPathCount"], 3)
            self.assertEqual(summary["crossClassConflictHashCount"], 1)
            self.assertGreaterEqual(summary["publisherCrossSplitLeakageHashCount"], 1)

            rows = load_and_verify_manifest(dataset, manifest)
            self.assertEqual(len(rows), len({row.sha256 for row in rows}))
            self.assertEqual(sorted({row.class_id for row in rows}), [1, 2, 3, 4, 5])
            self.assertEqual({row.split for row in rows}, {"train", "validation", "test"})
            with manifest.with_suffix(".exclusions.csv").open(
                newline="", encoding="utf-8"
            ) as stream:
                reasons = {row["reason"] for row in csv.DictReader(stream)}
            self.assertIn("identical-bytes-cross-class-label-conflict", reasons)
            self.assertIn("identical-bytes-duplicate-path-deduplication", reasons)


if __name__ == "__main__":
    unittest.main()
