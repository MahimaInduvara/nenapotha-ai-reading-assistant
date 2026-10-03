import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "generate_stage6_evaluation_report.py"
SPEC = importlib.util.spec_from_file_location("stage6_generator", MODULE_PATH)
stage6 = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(stage6)


class Stage6EvaluationGeneratorTest(unittest.TestCase):
    def test_wilson_interval_contains_observed_accuracy(self):
        low, high = stage6.wilson_interval(10619, 11984)
        observed = 10619 / 11984
        self.assertLess(low, observed)
        self.assertGreater(high, observed)
        self.assertAlmostEqual(low, 0.8803, places=4)
        self.assertAlmostEqual(high, 0.8917, places=4)

    def test_summarizes_deidentified_pilot_records(self):
        summary = stage6.summarize_pilot(
            [
                {
                    "expectedLetter": "A",
                    "predictedLabel": "A",
                    "isCorrect": True,
                    "confidence": 0.9,
                    "inferenceMilliseconds": 80,
                },
                {
                    "expectedLetter": "A",
                    "predictedLabel": "B",
                    "isCorrect": False,
                    "confidence": 0.6,
                    "inferenceMilliseconds": 100,
                },
            ]
        )
        self.assertEqual(summary["totalAttempts"], 2)
        self.assertEqual(summary["correctAttempts"], 1)
        self.assertEqual(summary["accuracy"], 0.5)
        self.assertEqual(summary["meanInferenceMilliseconds"], 90.0)
        self.assertEqual(summary["confusionCounts"]["A"], {"A": 1, "B": 1})

    def test_rejects_exports_with_personal_or_image_data(self):
        payload = {
            "schemaVersion": "readbuddy-trace-evaluation-v1",
            "privacy": {
                "containsStudentIdentifier": True,
                "containsRawTraceImage": False,
            },
            "records": [],
        }
        with self.assertRaises(ValueError):
            stage6.validate_pilot_export(payload)


if __name__ == "__main__":
    unittest.main()
