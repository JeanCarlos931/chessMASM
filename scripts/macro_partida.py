#!/usr/bin/env python3
"""
Macro: Actualiza /workspace/data/partida.json con estado, turno y FEN, y espera a que el turno sea 'b'.

Uso:
  python3 /workspace/scripts/macro_partida.py "<FEN>" \
    [--path /workspace/data/partida.json] [--timeout 0] [--interval 0.5]

Ejemplo:
  python3 /workspace/scripts/macro_partida.py \
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

Comportamiento:
  1) Escribe en el JSON: {"estado":"recibida", "turn":"w", "fen":"<FEN>"}
  2) Hace polling hasta que el archivo tenga "turn":"b" o expire el timeout.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
import time
from typing import Any, Dict


DEFAULT_JSON_PATH = "/workspace/data/partida.json"


def ensure_parent_directory_exists(file_path: str) -> None:
    parent_dir = os.path.dirname(os.path.abspath(file_path))
    if parent_dir and not os.path.exists(parent_dir):
        os.makedirs(parent_dir, exist_ok=True)


def atomic_write_json(file_path: str, data: Dict[str, Any]) -> None:
    """Escribe JSON de forma atómica para evitar lecturas parciales."""
    ensure_parent_directory_exists(file_path)
    directory = os.path.dirname(os.path.abspath(file_path))
    fd, temp_path = tempfile.mkstemp(prefix=".tmp_partida_", dir=directory)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as temp_file:
            json.dump(data, temp_file, ensure_ascii=False, separators=(",", ":"))
            temp_file.flush()
            os.fsync(temp_file.fileno())
        os.replace(temp_path, file_path)
    finally:
        if os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError:
                pass


def load_json(file_path: str) -> Dict[str, Any]:
    if not os.path.exists(file_path):
        return {}
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def wait_for_turn_black(file_path: str, interval_seconds: float, timeout_seconds: float) -> None:
    start_time = time.monotonic()
    while True:
        data = load_json(file_path)
        current_turn = data.get("turn")
        if current_turn == "b":
            print("Detectado turn='b'.")
            return
        if timeout_seconds > 0 and (time.monotonic() - start_time) >= timeout_seconds:
            print("Timeout esperando turn='b'.", file=sys.stderr)
            sys.exit(1)
        time.sleep(interval_seconds)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Actualiza partida.json y espera a turn='b'.")
    parser.add_argument(
        "fen",
        type=str,
        help="FEN completo después de mover la pieza.",
    )
    parser.add_argument(
        "--path",
        default=DEFAULT_JSON_PATH,
        help=f"Ruta al JSON (por defecto: {DEFAULT_JSON_PATH}).",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=0.0,
        help="Tiempo máximo en segundos para esperar turn='b' (0 = sin límite).",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=0.5,
        help="Intervalo de polling en segundos.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    # 1) Escribir estado inicial con FEN y turno w
    current = load_json(args.path)
    current["estado"] = "recibida"
    current["turn"] = "w"
    current["fen"] = args.fen
    atomic_write_json(args.path, current)
    print(f"Actualizado '{args.path}' con turn='w' y FEN.")

    # 2) Esperar a que el turno pase a 'b'
    wait_for_turn_black(args.path, interval_seconds=args.interval, timeout_seconds=args.timeout)


if __name__ == "__main__":
    main()

