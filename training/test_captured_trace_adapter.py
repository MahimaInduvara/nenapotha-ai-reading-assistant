import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

import adapt_captured_traces as adapter


class CapturedTraceAdapterTest(unittest.TestCase):
    def test_collect_captured_keeps_only_verified_model_classes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            model_input = root / "model_input" / "base_u0d85"
            model_input.mkdir(parents=True)
            for index in range(20):
                Image.new("L", (64, 64), 0).save(model_input / f"sample_{index}.png")
            lines = []
            for index in range(20):
                lines.append(
                    {
                        "sampleId": f"mapped_{index}",
                        "label": "අ",
                        "kind": "base",
                        "writerId": "writer_01",
                        "currentModelClassId": 1,
                        "modelInputPath": f"model_input/base_u0d85/sample_{index}.png",
                    }
                )
            lines.append(
                {
                    "sampleId": "unmapped",
                    "label": "ා",
                    "kind": "pillam",
                    "writerId": "writer_01",
                    "currentModelClassId": None,
                    "modelInputPath": "model_input/pillam/missing.png",
                }
            )
            (root / "manifest.jsonl").write_text(
                "\n".join(json.dumps(item, ensure_ascii=False) for item in lines),
                encoding="utf-8",
            )

            paths, labels, audit = adapter.collect_captured(root)

            self.assertEqual(len(paths), 20)
            self.assertEqual(set(labels), {0})
            self.assertEqual(audit["totalManifestSamples"], 21)
            self.assertEqual(len(audit["ignoredSamples"]), 1)
            self.assertEqual(audit["writerCount"], 1)

    def test_generated_invalid_samples_are_nonempty_64_pixel_images(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            generated = adapter.generate_invalid(
                root,
                seed=42,
                counts={"train": 4, "valid": 2, "test": 2},
            )
            self.assertEqual(len(generated["train"]), 4)
            for path in generated["train"]:
                image = Image.open(path)
                self.assertEqual(image.size, (64, 64))
                self.assertGreater(image.getextrema()[1], 0)


if __name__ == "__main__":
    unittest.main()
