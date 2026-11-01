"""Compile ECU-scoped actuator metadata from the recovered native runtime tables."""

import json
from pathlib import Path

ROOT = Path("assets/research/recovered-native")
TABLES = ROOT / "runtime-tables"
OUTPUT_JSON = Path("assets/data/recovered_actuators.json")
OUTPUT_DART = Path("lib/diagnostics/recovered_actuators.dart")
START = "// BEGIN GENERATED ACTUATOR CATALOG"
END = "// END GENERATED ACTUATOR CATALOG"
MAX_DURATION_SECONDS = 60


def read_localized_texts():
    texts = {}
    for line in (ROOT / "localized-texts.ndjson").read_text().splitlines():
        record = json.loads(line)
        if record.get("method") == "q":
            texts[record["id"]] = record["text"]
    return texts


def read_table(directory, name, ecu):
    path = directory / f"{name}.json"
    if not path.is_file():
        raise ValueError(f"Missing {path}")
    data = json.loads(path.read_text())
    if data.get("ecu_key") != ecu or data.get("table") != name:
        raise ValueError(f"Unexpected table identity in {path}")
    return data["rows"]


def parse_integer(value, location):
    try:
        return int(value)
    except ValueError as error:
        raise ValueError(f"Invalid integer at {location}: {value!r}") from error


def parse_bytes(value, location):
    if value == "":
        return []
    try:
        result = [int(part.strip(), 16) for part in value.split(",")]
    except ValueError as error:
        raise ValueError(f"Invalid byte list at {location}: {value!r}") from error
    if any(byte < 0 or byte > 255 for byte in result):
        raise ValueError(f"Byte out of range at {location}")
    return result


def label(texts, text_id):
    return texts.get(text_id, f"Unknown native text #{text_id}")


def action_name(value):
    return {
        "Start": "start",
        "Run": "run",
        "On": "on",
        "Off": "off",
        "End": "end",
    }.get(value, "none")


def unsupported_reason(position, commands):
    actions = {command["action"] for command in commands}
    activation = next(
        (command for command in commands if command["action"] == "on"), None
    ) or next((command for command in commands if command["action"] == "run"), None)
    stop = next((command for command in commands if command["action"] == "off"), None)
    if activation is None:
        return "No On or Run command is present."
    if stop is None:
        return "No Off command is present for mandatory cleanup."
    if activation["durationSeconds"] < 0 or activation["durationSeconds"] > MAX_DURATION_SECONDS:
        return "Activation duration is outside the recovered 0–60 second bound."
    for command in commands:
        if command["action"] not in {"start", "run", "on", "off", "end"}:
            continue
        request = command["request"]
        if not request or request[0] not in (0x10, 0x2F):
            return f"{command['actionLabel']} request uses an unsupported service."
        response_prefix = command["responsePrefix"]
        if response_prefix and response_prefix[0] != request[0] + 0x40:
            return f"{command['actionLabel']} response prefix has an unproven service match."
    return None


def compile_catalog():
    texts = read_localized_texts()
    catalog = {}
    for actuator_path in sorted(TABLES.glob("*/ACTUATOR.json")):
        ecu = actuator_path.parent.name
        actuator_rows = read_table(actuator_path.parent, "ACTUATOR", ecu)
        position_rows = read_table(actuator_path.parent, "ACTUATORPOS", ecu)
        command_rows = read_table(actuator_path.parent, "ACTUATORCMD", ecu)

        actuators = {}
        for row_index, raw in enumerate(actuator_rows):
            fields = raw.split(";")
            if len(fields) != 2:
                raise ValueError(f"Malformed {ecu}/ACTUATOR row {row_index}: {raw}")
            actuator_id = parse_integer(fields[0], f"{ecu}/ACTUATOR[{row_index}].id")
            text_id = parse_integer(fields[1], f"{ecu}/ACTUATOR[{row_index}].text")
            if actuator_id in actuators:
                raise ValueError(f"Duplicate actuator {ecu}/{actuator_id}")
            actuators[actuator_id] = {
                "id": actuator_id,
                "nameTextId": text_id,
                "name": label(texts, text_id),
                "positions": [],
            }

        positions = {}
        for row_index, raw in enumerate(position_rows):
            fields = raw.split(";")
            if len(fields) != 7:
                raise ValueError(f"Malformed {ecu}/ACTUATORPOS row {row_index}: {raw}")
            values = [
                parse_integer(value, f"{ecu}/ACTUATORPOS[{row_index}].{index}")
                for index, value in enumerate(fields)
            ]
            position_id, actuator_id, title_id, instruction_id, ignored_id, completion_instruction_id, completion_id = values
            if position_id in positions:
                raise ValueError(f"Duplicate position {ecu}/{position_id}")
            if actuator_id not in actuators:
                # Match the native loader: positions without a parent are omitted.
                continue
            position = {
                "id": position_id,
                "actuatorId": actuator_id,
                "titleTextId": title_id,
                "title": label(texts, title_id),
                "instructionTextId": instruction_id,
                "instruction": label(texts, instruction_id),
                "ignoredColumn4": ignored_id,
                "completionInstructionTextId": completion_instruction_id,
                "completionInstructionTextId": completion_instruction_id,
                "completionTextId": completion_id,
                "completion": label(texts, completion_id),
                "commands": [],
                "unsupportedReason": None,
            }
            positions[position_id] = position
            actuators[actuator_id]["positions"].append(position)

        command_ids = set()
        for row_index, raw in enumerate(command_rows):
            fields = raw.split(";")
            if len(fields) != 6:
                raise ValueError(f"Malformed {ecu}/ACTUATORCMD row {row_index}: {raw}")
            row_id = parse_integer(fields[0], f"{ecu}/ACTUATORCMD[{row_index}].id")
            position_id = parse_integer(fields[1], f"{ecu}/ACTUATORCMD[{row_index}].position")
            if row_id in command_ids:
                raise ValueError(f"Duplicate command row {ecu}/{row_id}")
            command_ids.add(row_id)
            if position_id not in positions:
                # Match the native loader: commands without a matched position are omitted.
                continue
            command = {
                "rowId": row_id,
                "positionId": position_id,
                "action": action_name(fields[2]),
                "actionLabel": fields[2],
                "request": parse_bytes(fields[3], f"{ecu}/ACTUATORCMD[{row_index}].request"),
                "responsePrefix": parse_bytes(fields[4], f"{ecu}/ACTUATORCMD[{row_index}].responsePrefix"),
                "durationSeconds": parse_integer(fields[5] or "0", f"{ecu}/ACTUATORCMD[{row_index}].duration"),
                "raw": raw,
            }
            positions[position_id]["commands"].append(command)

        for position in positions.values():
            position["unsupportedReason"] = unsupported_reason(position, position["commands"])
        catalog[ecu] = list(actuators.values())
    return catalog


def dart_quote(value):
    return json.dumps(value, ensure_ascii=True).replace("$", r"\$")


def dart_ints(values):
    return "<int>[" + ", ".join(str(value) for value in values) + "]"


def render_dart_block(catalog):
    lines = ["const recoveredActuatorsByEcu = <String, List<RecoveredActuatorDefinition>>{"]
    for ecu, actuators in catalog.items():
        lines.append(f"  {dart_quote(ecu)}: <RecoveredActuatorDefinition>[")
        for actuator in actuators:
            lines.append("    RecoveredActuatorDefinition(")
            lines.append(f"      id: {actuator['id']}, nameTextId: {actuator['nameTextId']},")
            lines.append(f"      name: {dart_quote(actuator['name'])},")
            lines.append("      positions: <RecoveredActuatorPosition>[")
            for position in actuator["positions"]:
                lines.append("        RecoveredActuatorPosition(")
                lines.append(
                    f"          id: {position['id']}, actuatorId: {position['actuatorId']},"
                )
                lines.append(
                    f"          titleTextId: {position['titleTextId']}, title: {dart_quote(position['title'])},"
                )
                lines.append(
                    f"          instructionTextId: {position['instructionTextId']}, instruction: {dart_quote(position['instruction'])},"
                )
                lines.append(
                    f"          ignoredColumn4: {position['ignoredColumn4']}, completionInstructionTextId: {position['completionInstructionTextId']}, completionTextId: {position['completionTextId']}, completion: {dart_quote(position['completion'])},"
                )
                lines.append("          commands: <RecoveredActuatorCommand>[")
                for command in position["commands"]:
                    lines.append("            RecoveredActuatorCommand(")
                    lines.append(
                        f"              rowId: {command['rowId']}, positionId: {command['positionId']},"
                    )
                    lines.append(
                        f"              action: RecoveredActuatorAction.{command['action']}, actionLabel: {dart_quote(command['actionLabel'])},"
                    )
                    lines.append(
                        f"              request: {dart_ints(command['request'])}, responsePrefix: {dart_ints(command['responsePrefix'])},"
                    )
                    lines.append(
                        f"              durationSeconds: {command['durationSeconds']}, raw: {dart_quote(command['raw'])},"
                    )
                    lines.append("            ),")
                lines.append("          ],")
                reason = position["unsupportedReason"]
                lines.append(
                    f"          unsupportedReason: {dart_quote(reason) if reason is not None else 'null'},"
                )
                lines.append("        ),")
            lines.extend(["      ],", "    ),"])
        lines.extend(["  ],"])
    lines.append("};")
    return "\n".join(lines)


def main():
    catalog = compile_catalog()
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    dart = OUTPUT_DART.read_text()
    if dart.count(START) != 1 or dart.count(END) != 1:
        raise ValueError("Generated Dart markers are missing or duplicated")
    before, rest = dart.split(START, 1)
    _, after = rest.split(END, 1)
    OUTPUT_DART.write_text(before + START + "\n" + render_dart_block(catalog) + "\n" + END + after)
    total_actuators = sum(len(items) for items in catalog.values())
    total_positions = sum(len(actuator["positions"]) for items in catalog.values() for actuator in items)
    supported = sum(
        position["unsupportedReason"] is None
        for items in catalog.values()
        for actuator in items
        for position in actuator["positions"]
    )
    print(
        f"Generated {total_actuators} actuators and {total_positions} positions "
        f"across {len(catalog)} ECUs ({supported} with a bounded On/Run + Off sequence)."
    )


if __name__ == "__main__":
    main()
