from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from stage3_cnn_pipeline import (
    create_provided_split_manifest,
    load_and_verify_manifest,
)


class Stage3ProvidedSplitTest(unittest.TestCase):
    def _dataset(self, root: Path) -> Path:
        dataset = root / "dataset"
        for split in ("train", "valid", "test"):
            for class_id in range(1, 6):
                folder = dataset / split / str(class_id)
                folder.mkdir(parents=True)
                for item in range(3):
                    (folder / f"{item}.png").write_bytes(
                        f"{split}:{class_id}:{item}".encode()
                    )
        return dataset

    def test_publisher_splits_are_preserved(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = self._dataset(root)
            manifest = root / "manifest.csv"
            summary = create_provided_split_manifest(
                dataset, manifest, seed=42, allow_subset=True
            )
            self.assertEqual(
                summary["splitStrategy"], "publisher-provided-train-valid-test"
            )
            self.assertEqual(
                summary["splitCounts"],
                {"train": 15, "validation": 15, "test": 15},
            )
            rows = load_and_verify_manifest(dataset, manifest)
            self.assertTrue(
                all(
                    row.relative_path.startswith(("train/", "valid/", "test/"))
                    for row in rows
                )
            )

    def test_cross_split_duplicate_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = self._dataset(root)
            (dataset / "test" / "1" / "duplicate.png").write_bytes(
                (dataset / "train" / "1" / "0.png").read_bytes()
            )
            with self.assertRaises(ValueError):
                create_provided_split_manifest(
                    dataset, root / "manifest.csv", seed=42, allow_subset=True
                )


if __name__ == "__main__":
    unittest.main()
