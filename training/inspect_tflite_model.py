#!/usr/bin/env python3
"""Inspect a TensorFlow Lite FlatBuffer without requiring TensorFlow.

Install the lightweight schema package first:
    python -m pip install tflite==2.18.0
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


TYPE_NAMES = {
    0: "FLOAT32",
    1: "FLOAT16",
    2: "INT32",
    3: "UINT8",
    4: "INT64",
    6: "BOOL",
    7: "INT16",
    9: "INT8",
}


def _decode(value: bytes | None) -> str | None:
    return value.decode("utf-8") if value else None


def inspect(model_path: Path) -> dict:
    try:
        import tflite
    except ImportError as exc:
        raise SystemExit(
            "Missing dependency. Run: python -m pip install tflite==2.18.0"
        ) from exc

    data = model_path.read_bytes()
    model = tflite.Model.GetRootAsModel(data, 0)
    subgraph = model.Subgraphs(0)
    operator_codes = []
    for index in range(model.OperatorCodesLength()):
        code = model.OperatorCodes(index)
        builtin = code.BuiltinCode()
        operator_codes.append(
            tflite.opcode2name(builtin)
            if hasattr(tflite, "opcode2name")
            else str(builtin)
        )

    tensors = []
    for index in range(subgraph.TensorsLength()):
        tensor = subgraph.Tensors(index)
        buffer = model.Buffers(tensor.Buffer())
        tensors.append(
            {
                "index": index,
                "name": _decode(tensor.Name()),
                "shape": [tensor.Shape(i) for i in range(tensor.ShapeLength())],
                "type": TYPE_NAMES.get(tensor.Type(), str(tensor.Type())),
                "buffer_bytes": buffer.DataLength(),
            }
        )

    operators = []
    for index in range(subgraph.OperatorsLength()):
        operator = subgraph.Operators(index)
        operators.append(
            {
                "index": index,
                "opcode": operator_codes[operator.OpcodeIndex()],
                "inputs": [
                    operator.Inputs(i) for i in range(operator.InputsLength())
                ],
                "outputs": [
                    operator.Outputs(i) for i in range(operator.OutputsLength())
                ],
            }
        )

    return {
        "artifact": str(model_path.as_posix()),
        "sha256": hashlib.sha256(data).hexdigest().upper(),
        "size_bytes": len(data),
        "flatbuffer_version": model.Version(),
        "description": _decode(model.Description()),
        "inputs": [subgraph.Inputs(i) for i in range(subgraph.InputsLength())],
        "outputs": [subgraph.Outputs(i) for i in range(subgraph.OutputsLength())],
        "operator_count": subgraph.OperatorsLength(),
        "tensor_count": subgraph.TensorsLength(),
        "operators": operators,
        "tensors": tensors,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = inspect(args.model)
    rendered = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
