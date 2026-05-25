#!/usr/bin/env python3
"""Static wiring checks for the Lò Thiêng Godot project."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PATH_PATTERN = re.compile(r"res://[^\"')\n]+")
EVENTBUS_SIGNAL_PATTERN = re.compile(r"^signal\s+(\w+)")
SKILL_EFFECT_PATTERN = re.compile(r'^effect\s*=\s*"([^"]+)"')
TRES_FIELD_PATTERN = re.compile(r"^(\w+)\s*=")
AUTOLOAD_NAMES = (
    "GameManager",
    "EventBus",
    "SaveSystem",
    "AudioManager",
    "InventorySystem",
    "SceneManager",
    "DayCycle",
    "DebtSystem",
)
VALID_SKILL_EFFECTS = {
    "DAMAGE",
    "DAMAGE_STATUS",
    "BUFF_DEF",
    "BUFF_ALL_STATS",
    "DAMAGE_HEAL",
    "DAMAGE_TWICE",
    "DAMAGE_SKIP_TURN",
    "SHIELD_ONE_HIT",
    "DEBUFF_ATK",
    "PASSIVE_NO_DURABILITY",
    "DAMAGE_IGNORE_DEF",
}
DEBT_REQUIRED_FIELDS = [
    "id",
    "amount_gold",
    "trigger_day",
    "deadline_day",
    "penalty_gold",
    "agent_id",
    "agent_name",
]
KNOWN_DEBT_CHECKPOINTS = {
    "c1_mat_bang": {
        "amount_gold": "3000",
        "trigger_day": "1",
        "deadline_day": "4",
        "penalty_gold": "300",
    },
    "c4_no_goc": {
        "amount_gold": "65000",
        "trigger_day": "29",
        "deadline_day": "52",
        "penalty_gold": "6500",
    },
}
KNOWN_MATERIAL_IDS = [
    "sat_tho",
    "dong_vun",
    "da_thu",
    "bac_vun",
    "go_linh",
    "pha_le",
    "quang_than",
    "mithril",
    "vas_rong",
    "cat_than",
    "tro_thieng",
    "tinh_the_lo",
]


@dataclass(frozen=True)
class Finding:
    source: Path
    line_number: int
    message: str

    def format(self) -> str:
        return f"{self.source.as_posix()}:{self.line_number} → {self.message}"


def _relative(path: Path) -> Path:
    return path.resolve().relative_to(ROOT)


def _iter_files(suffixes: tuple[str, ...]) -> list[Path]:
    ignored_dirs = {".git", ".godot", ".import", "__pycache__"}
    result: list[Path] = []

    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if any(part in ignored_dirs for part in path.relative_to(ROOT).parts):
            continue
        if path.suffix in suffixes:
            result.append(path)

    return sorted(result)


def _read_lines(path: Path) -> list[str]:
    try:
        return path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace").splitlines()


def _res_path_exists(res_path: str) -> bool:
    if res_path.endswith((".uid", ".import")):
        return True
    return (ROOT / res_path.removeprefix("res://")).exists()


def check_res_paths(files: list[Path]) -> tuple[int, list[Finding]]:
    checked = 0
    failures: list[Finding] = []

    for path in files:
        source = _relative(path)
        for line_number, line in enumerate(_read_lines(path), start=1):
            if line.strip().startswith(("#", ";")):
                continue
            for match in PATH_PATTERN.finditer(line):
                res_path = match.group(0)
                if res_path.endswith((".uid", ".import")):
                    continue
                checked += 1
                if not _res_path_exists(res_path):
                    failures.append(Finding(source, line_number, res_path))

    return checked, failures


def _declared_eventbus_signals() -> set[str]:
    eventbus_path = ROOT / "scripts/autoload/EventBus.gd"
    signals: set[str] = set()

    if not eventbus_path.exists():
        return signals

    for line in _read_lines(eventbus_path):
        match = EVENTBUS_SIGNAL_PATTERN.match(line)
        if match:
            signals.add(match.group(1))

    return signals


def check_eventbus_signals(gd_files: list[Path]) -> tuple[int, list[Finding]]:
    declared = _declared_eventbus_signals()
    usages = [
        re.compile(r'EventBus\.emit_signal\("(\w+)"'),
        re.compile(r"EventBus\.(\w+)\.emit\("),
        re.compile(r'EventBus\.connect\("(\w+)"'),
        re.compile(r"EventBus\.(\w+)\.connect\("),
    ]
    checked = 0
    failures: list[Finding] = []

    for path in gd_files:
        source = _relative(path)
        for line_number, line in enumerate(_read_lines(path), start=1):
            for pattern in usages:
                for match in pattern.finditer(line):
                    signal_name = match.group(1)
                    checked += 1
                    if signal_name not in declared:
                        failures.append(
                            Finding(
                                source,
                                line_number,
                                f"EventBus.{signal_name} (not declared)",
                            )
                        )

    return checked, failures


def _project_autoloads() -> list[str]:
    project_path = ROOT / "project.godot"
    autoloads: list[str] = []
    in_autoload_section = False

    if not project_path.exists():
        return autoloads

    for raw_line in _read_lines(project_path):
        line = raw_line.strip()
        if line == "[autoload]":
            in_autoload_section = True
            continue
        if line.startswith("[") and line.endswith("]"):
            in_autoload_section = False
            continue
        if not in_autoload_section or not line or line.startswith(";"):
            continue

        match = re.match(r'(\w+)="\*res://[^"]+"', line)
        if match:
            autoloads.append(match.group(1))

    return autoloads


def check_autoload_names(gd_files: list[Path]) -> tuple[list[str], list[Finding]]:
    declared = set(_project_autoloads())
    known_names = "|".join(re.escape(name) for name in AUTOLOAD_NAMES)
    usage_pattern = re.compile(rf"(^|[=(]\s*)({known_names})\b")
    warnings: list[Finding] = []

    for path in gd_files:
        source = _relative(path)
        for line_number, line in enumerate(_read_lines(path), start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            for match in usage_pattern.finditer(line):
                autoload_name = match.group(2)
                if autoload_name not in declared:
                    warnings.append(
                        Finding(
                            source,
                            line_number,
                            f"{autoload_name} used but not declared in project.godot",
                        )
                    )

    return sorted(declared), warnings


def check_scene_script_paths(tscn_files: list[Path]) -> tuple[int, list[Finding]]:
    script_path_pattern = re.compile(r'path="(res://[^"]+\.gd)"')
    checked = 0
    failures: list[Finding] = []

    for path in tscn_files:
        source = _relative(path)
        for line_number, line in enumerate(_read_lines(path), start=1):
            for match in script_path_pattern.finditer(line):
                res_path = match.group(1)
                if not (res_path.startswith("res://scripts/") or '"Script"' in line):
                    continue
                checked += 1
                if not _res_path_exists(res_path):
                    failures.append(Finding(source, line_number, res_path))

    return checked, failures


def check_skill_effect_strings(root: Path) -> tuple[int, list[Finding]]:
    skills_dir = root / "resources" / "skills"
    failures: list[Finding] = []

    if not skills_dir.exists():
        return 0, failures

    skill_files = sorted(skills_dir.glob("*.tres"))
    for path in skill_files:
        source = _relative(path)
        for line_number, line in enumerate(_read_lines(path), start=1):
            match = SKILL_EFFECT_PATTERN.match(line)
            if not match:
                continue
            effect = match.group(1)
            if effect not in VALID_SKILL_EFFECTS:
                failures.append(
                    Finding(
                        source,
                        line_number,
                        f'effect "{effect}" not in VALID_EFFECTS',
                    )
                )

    return len(skill_files), failures


def check_debt_checkpoints(root: Path) -> tuple[int, list[Finding]]:
    debt_dir = root / "resources" / "debt"
    failures: list[Finding] = []

    if not debt_dir.exists():
        return 0, failures

    debt_files = sorted(debt_dir.glob("*.tres"))
    for path in debt_files:
        source = _relative(path)
        lines = _read_lines(path)
        declared_fields: set[str] = set()

        for line in lines:
            match = TRES_FIELD_PATTERN.match(line)
            if match:
                declared_fields.add(match.group(1))

        for field in DEBT_REQUIRED_FIELDS:
            if field not in declared_fields:
                failures.append(Finding(source, 1, f"missing field: {field}"))

        known_values = KNOWN_DEBT_CHECKPOINTS.get(path.stem, {})
        for field, expected_value in known_values.items():
            expected_line = f"{field} = {expected_value}"
            if not any(line.strip() == expected_line for line in lines):
                failures.append(Finding(source, 1, f"{field}: expected {expected_value}"))

    return len(debt_files), failures


def check_material_allowed_elements(root: Path) -> tuple[int, list[Finding]]:
    target = root / "scripts" / "forge" / "forge_book_ui.gd"
    if not target.exists():
        return 0, [Finding(Path("scripts/forge/forge_book_ui.gd"), 0, "forge_book_ui.gd not found")]

    failures: list[Finding] = []
    lines = _read_lines(target)
    text = "\n".join(lines)
    source = _relative(target)

    if "var material_data" not in text:
        return len(KNOWN_MATERIAL_IDS), [Finding(source, 1, "material_data not found")]

    for mat_id in KNOWN_MATERIAL_IDS:
        mat_line = 1
        for line_number, line in enumerate(lines, start=1):
            if f'"{mat_id}"' in line:
                mat_line = line_number
                break

        match = re.search(rf'"{re.escape(mat_id)}".{{0,300}}?allowed_elements', text, re.DOTALL)
        if match is None:
            failures.append(
                Finding(
                    source,
                    mat_line,
                    f'"{mat_id}" missing allowed_elements',
                )
            )

    return len(KNOWN_MATERIAL_IDS), failures


def _print_findings(kind: str, findings: list[Finding]) -> None:
    for finding in findings:
        print(f"  {kind}: {finding.format()}")


def main() -> int:
    gd_files = _iter_files((".gd",))
    tscn_files = _iter_files((".tscn",))
    scanned_files = gd_files + tscn_files

    print("=== Lò Thiêng Static Check ===")

    print("[CHECK 1] res:// path resolution")
    path_count, path_failures = check_res_paths(scanned_files)
    print(f"  PASS: {path_count} paths checked")
    _print_findings("FAIL", path_failures)
    print()

    print("[CHECK 2] EventBus signal consistency")
    signal_count, signal_failures = check_eventbus_signals(gd_files)
    print(f"  PASS: {signal_count} usages matched")
    _print_findings("FAIL", signal_failures)
    print()

    print("[CHECK 3] Autoload names")
    autoloads, autoload_warnings = check_autoload_names(gd_files)
    print(f"  PASS: autoloads found: {', '.join(autoloads) if autoloads else '(none)'}")
    _print_findings("WARN", autoload_warnings)
    print()

    print("[CHECK 4] Scene script paths")
    scene_script_count, scene_script_failures = check_scene_script_paths(tscn_files)
    if scene_script_failures:
        print(f"  FAIL: {scene_script_count} scene script paths checked")
    else:
        print(f"  PASS: {scene_script_count} scene script paths checked")
    _print_findings("FAIL", scene_script_failures)
    print()

    print("[CHECK 5] SkillData effect strings")
    skill_count, skill_failures = check_skill_effect_strings(ROOT)
    print(f"  PASS: {skill_count} skill files checked")
    _print_findings("FAIL", skill_failures)
    print()

    print("[CHECK 6] Debt checkpoint fields")
    debt_count, debt_failures = check_debt_checkpoints(ROOT)
    print(f"  PASS: {debt_count} checkpoint files checked")
    _print_findings("FAIL", debt_failures)
    print()

    print("[CHECK 7] forge_book_ui material allowed_elements")
    mat_count, mat_failures = check_material_allowed_elements(ROOT)
    print(f"  PASS: {mat_count} materials checked")
    _print_findings("FAIL", mat_failures)
    print()

    fail_count = len(path_failures) + len(signal_failures) + len(scene_script_failures) + len(skill_failures) + len(debt_failures) + len(mat_failures)
    warn_count = len(autoload_warnings)
    print(f"=== KẾT QUẢ: {fail_count} FAIL, {warn_count} WARN ===")

    return 1 if fail_count else 0


if __name__ == "__main__":
    sys.exit(main())
