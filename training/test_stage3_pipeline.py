from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from stage3_cnn_pipeline import create_split_manifest, load_and_verify_manifest


class Stage3SplitManifestTest(unittest.TestCase):
    def _dataset(self, root: Path, classes: int = 5, samples: int = 5) -> Path:
        dataset = root / "dataset"
        for class_id in range(1, classes + 1):
            folder = dataset / str(class_id)
            folder.mkdir(parents=True)
            for item in range(samples):
                (folder / f"sample_{item}.png").write_bytes(
                    f"class={class_id};sample={item}".encode()
                )
        return dataset

    def test_manifest_is_deterministic_and_validates_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = self._dataset(root)
            first = root / "first.csv"
            second = root / "second.csv"
            create_split_manifest(dataset, first, seed=42, allow_subset=True)
            create_split_manifest(dataset, second, seed=42, allow_subset=True)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            validated = load_and_verify_manifest(dataset, first)
            self.assertEqual(len(validated), 25)
            self.assertEqual(
                sorted({row.class_id for row in validated}), [1, 2, 3, 4, 5]
            )

    def test_identical_files_stay_in_one_split(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = self._dataset(root)
            duplicate = dataset / "1" / "duplicate.png"
            duplicate.write_bytes((dataset / "1" / "sample_0.png").read_bytes())
            manifest = root / "split.csv"
            create_split_manifest(dataset, manifest, seed=42, allow_subset=True)
            rows = load_and_verify_manifest(dataset, manifest)
            duplicate_hash = next(
                row.sha256
                for row in rows
                if row.relative_path.endswith("duplicate.png")
            )
            splits = {row.split for row in rows if row.sha256 == duplicate_hash}
            self.assertEqual(len(splits), 1)

    def test_cross_class_identical_files_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = self._dataset(root)
            (dataset / "2" / "conflict.png").write_bytes(
                (dataset / "1" / "sample_0.png").read_bytes()
            )
            with self.assertRaises(ValueError):
                create_split_manifest(
                    dataset, root / "split.csv", seed=42, allow_subset=True
                )

    def test_changed_file_is_rejected_when_manifest_is_reused(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dataset = self._dataset(root)
            manifest = root / "split.csv"
            create_split_manifest(dataset, manifest, seed=42, allow_subset=True)
            (dataset / "1" / "sample_0.png").write_bytes(b"changed")
            with self.assertRaises(ValueError):
                load_and_verify_manifest(dataset, manifest)


if __name__ == "__main__":
    unittest.main()
