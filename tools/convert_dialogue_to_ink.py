#!/usr/bin/env python3
"""Convert Dialogue Manager .dialogue files to Ink .ink format."""

import json
import os
import re
import subprocess
import sys
from pathlib import Path


def parse_action_runner_call(line: str) -> str | None:
    """Parse 'do ActionRunner.run({...})' and map to Ink external function."""
    m = re.search(r'do ActionRunner\.run\((\{.*\})\)\s*$', line)
    if not m:
        return None
    try:
        action = json.loads(m.group(1))
    except json.JSONDecodeError:
        return None

    action_type = action.get("type", "")
    match action_type:
        case "set_flag":
            return f'~ set_flag("{action["key"]}", {json.dumps(action["value"])})'
        case "set_metric":
            return f'~ set_metric("{action["key"]}", {action["value"]})'
        case "change_metric":
            return f'~ change_metric("{action["key"]}", {action["amount"]})'
        case "advance_time":
            time_units = action.get("time_units", action.get("amount", 1))
            return f'~ advance_time({time_units})'
        case "advance_minutes":
            minutes = action.get("minutes", 0)
            return f'~ advance_minutes({minutes})'
        case "sleep_until_next_day":
            return '~ sleep_until_next_day()'
        case "add_item":
            amount = action.get("amount", 1)
            return f'~ add_item("{action["item_id"]}", {amount})'
        case "remove_item":
            amount = action.get("amount", 1)
            return f'~ remove_item("{action["item_id"]}", {amount})'
        case "equip_item":
            return f'~ equip_item("{action["item_id"]}")'
        case "unequip_item":
            return f'~ unequip_item("{action["item_id"]}")'
        case "move":
            target = action.get("target_place", action.get("target_place_id", ""))
            return f'~ move("{target}")'
        case "log":
            return f'~ log("{action.get("message", "")}")'
        case "add_condition":
            duration = action.get("duration", -1)
            stack = action.get("stack", 1)
            return f'~ add_condition("{action["condition_id"]}", {duration}, {stack})'
        case "remove_condition":
            return f'~ remove_condition("{action["condition_id"]}")'
        case "change_doom":
            return f'~ change_doom({action["amount"]})'
        case "block_place":
            reason = action.get("reason", "")
            return f'~ block_place("{action["place_id"]}", "{reason}")'
        case "unblock_place":
            return f'~ unblock_place("{action["place_id"]}")'
        case "trigger_game_over":
            reason = action.get("reason", "")
            got = action.get("game_over_type", action.get("type", "normal"))
            return f'~ trigger_game_over("{reason}", "{got}")'
        case "open_ui":
            return f'~ open_ui("{action["ui_name"]}")'
        case "random_loot":
            return f'~ random_loot("{action["table_id"]}")'
        case "trigger_mandatory":
            return f'~ trigger_mandatory("{action["trigger_on"]}")'
        case "dialogue":
            return f'~ start_dialogue("{action["dialogue_id"]}")'
        case _:
            return f'// TODO: unsupported ActionRunner action: {action_type}'


def parse_flags_mutation(line: str) -> str | None:
    """Parse 'do Flags.xxx += value', 'do Flags.xxx -= value', 'do Flags.xxx = value', or 'set Flags.xxx = value'."""
    # do Flags.xxx = value
    m = re.match(r'do\s+Flags\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$', line)
    if m:
        key = m.group(1)
        value = m.group(2).strip()
        if value.lower() == "true":
            return f'~ set_flag("{key}", true)'
        if value.lower() == "false":
            return f'~ set_flag("{key}", false)'
        if re.match(r'^-?\d+$', value):
            return f'~ set_flag("{key}", {value})'
        return f'~ set_flag("{key}", "{value}")'
    # do Flags.xxx += value
    m = re.match(r'do\s+Flags\.([A-Za-z_][A-Za-z0-9_]*)\s*\+\=\s*(.+)$', line)
    if m:
        key = m.group(1)
        value = m.group(2).strip()
        if re.match(r'^\d+$', value):
            return f'~ change_metric("{key}", {value})'
        return f'~ change_metric("{key}", {value})'
    # do Flags.xxx -= value
    m = re.match(r'do\s+Flags\.([A-Za-z_][A-Za-z0-9_]*)\s*\-\=\s*(.+)$', line)
    if m:
        key = m.group(1)
        value = m.group(2).strip()
        if re.match(r'^\d+$', value):
            return f'~ change_metric("{key}", -{value})'
        return f'~ change_metric("{key}", -{value})'
    # set Flags.xxx = value
    m = re.match(r'set\s+Flags\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$', line)
    if m:
        key = m.group(1)
        value = m.group(2).strip()
        if value.lower() == "true":
            return f'~ set_flag("{key}", true)'
        if value.lower() == "false":
            return f'~ set_flag("{key}", false)'
        if re.match(r'^-?\d+$', value):
            return f'~ set_flag("{key}", {value})'
        return f'~ set_flag("{key}", "{value}")'
    return None


def convert_line(line: str, in_choice_body: bool) -> list[str]:
    """Convert a single .dialogue line to Ink. Returns list of output lines."""
    original = line
    stripped = line.strip()

    if not stripped:
        return [""]

    # Comments: keep as-is but use // for Ink
    if stripped.startswith("#") and not stripped.startswith("#["):
        return ["// " + stripped[1:].strip()]

    # Extract inline tags FIRST so structural parsing isn't confused by
    # colons or brackets inside tags (e.g. [ID:pro_01] at end of line).
    text, tags = extract_inline_tags(stripped)

    # Title declaration
    if text.startswith("~ "):
        title = text[2:].strip()
        result = f"=== {title} ==="
        if tags:
            result += " " + " ".join(tags)
        return [result]

    # END knot placeholder
    if text == "=> END":
        return ["-> END"]

    # Divert
    if text.startswith("=> "):
        target = text[3:].strip()
        return [f"-> {target}"]

    # Random divert (part of a group, handled at higher level)
    if text.startswith("% => "):
        return [f"-> {text[4:].strip()}"]  # Will be wrapped by caller

    # do ActionRunner.run(...)
    if text.startswith("do ActionRunner.run("):
        converted = parse_action_runner_call(text)
        if converted:
            return [converted]
        return [f"// TODO: manual convert: {original.strip()}"]

    # do OtherAutoload.method(...)
    if text.startswith("do "):
        return [f"// TODO: manual convert: {original.strip()}"]

    # do Nickname.set_nickname(...)
    m = re.match(r'do\s+Nickname\.set_nickname\("([^"]+)",\s*"([^"]+)"\)', text)
    if m:
        return [f'~ set_nickname("{m.group(1)}", "{m.group(2)}")']

    # do AudioManager.play_sfx(...)
    m = re.match(r'do\s+AudioManager\.play_sfx\("([^"]+)"\)', text)
    if m:
        return [f'~ play_sfx("{m.group(1)}")']

    # do LocationManager.move_to(...)
    m = re.match(r'do\s+LocationManager\.move_to\((.+)\)', text)
    if m:
        return [f'~ move({m.group(1)})']

    # set Flags.xxx = value / do Flags.xxx += value / do Flags.xxx -= value
    if text.startswith("set Flags.") or re.match(r'^do\s+Flags\.[A-Za-z_]', text):
        converted = parse_flags_mutation(text)
        if converted:
            return [converted]
        return [f"// TODO: manual convert: {original.strip()}"]

    # if / elif / else (Dialogue Manager conditionals)
    if re.match(r'^(if|elif|else)\s*', text):
        return [f"// TODO: manual convert conditional: {original.strip()}"]

    # Player choice (Dialogue Manager uses '-' or '*')
    if text.startswith("-") or text.startswith("*"):
        # Choice line
        choice_text = text[1:].strip()
        # Remove surrounding quotes if present
        if (choice_text.startswith('"') and choice_text.endswith('"')) or \
           (choice_text.startswith("'") and choice_text.endswith("'")):
            choice_text = choice_text[1:-1]
        # Extract conditional [if ...] at end
        condition = ""
        cond_match = re.search(r'\s*\[if\s+(.+?)\]\s*$', choice_text)
        if cond_match:
            condition = cond_match.group(1)
            choice_text = choice_text[:cond_match.start()].strip()
            # Strip Flags. / MetricStore. prefixes (dots are Ink list separators)
            condition = re.sub(r'\b(Flags|MetricStore)\.', '', condition)
        ink_line = ""
        if condition:
            ink_line += f"* {{ {condition} }} "
        else:
            ink_line += "* "
        # Ink weave choices don't need [brackets] around the text;
        # omitting them avoids parser issues with ']' inside the text.
        ink_line += choice_text
        if tags:
            ink_line += " " + " ".join(tags)
        return [ink_line]

    # Character line: "Name: text"
    char_match = re.match(r'^([^:]+):\s*(.*)$', text)
    if char_match:
        speaker = char_match.group(1).strip()
        char_text = char_match.group(2).strip()
        if char_text.startswith('"') and char_text.endswith('"'):
            char_text = char_text[1:-1]
        ink_line = char_text
        if tags:
            ink_line += " " + " ".join(tags)
        ink_line += f' # speaker={speaker}'
        return [ink_line]

    # Plain narration line
    ink_line = text
    if tags:
        ink_line += " " + " ".join(tags)
    return [ink_line]


def extract_inline_tags(text: str) -> tuple[str, list[str]]:
    """Extract [tag] patterns from text and convert to Ink #tags."""
    tags = []

    # [wait=N] -> drop (typing handles pacing)
    text = re.sub(r'\s*\[wait=[\d.]+\]', '', text)

    # [ID:xxx] -> # id=xxx
    def id_repl(m):
        tags.append(f"# id={m.group(1)}")
        return ""
    text = re.sub(r'\s*\[ID:([^\]]+)\]', id_repl, text)

    # [scgc appearance filename] -> # scgc=appearance_filename
    def scg_repl(m):
        scg_id = m.group(1)
        appearance = m.group(2)
        filename = m.group(3)
        tags.append(f"# {scg_id}={appearance}_{filename}")
        return ""
    text = re.sub(r'\s*\[(scgc|scgl|scgr)\s+(\S+)\s+(\S+)\]', scg_repl, text)

    # [i]...[/i] -> keep as-is (BBCode)
    # [b]...[/b] -> keep as-is
    # Other [xxx] -> keep as-is unless handled above

    text = text.strip()
    return text, tags


EXTERNAL_DECLARATIONS = """EXTERNAL set_flag(key, value)
EXTERNAL set_metric(key, value)
EXTERNAL change_metric(key, amount)
EXTERNAL advance_time(time_units)
EXTERNAL advance_minutes(minutes)
EXTERNAL sleep_until_next_day()
EXTERNAL add_item(item_id, amount)
EXTERNAL remove_item(item_id, amount)
EXTERNAL equip_item(item_id)
EXTERNAL unequip_item(item_id)
EXTERNAL move(target_place)
EXTERNAL log(message)
EXTERNAL add_condition(condition_id, duration, stack)
EXTERNAL remove_condition(condition_id)
EXTERNAL change_doom(amount)
EXTERNAL block_place(place_id, reason)
EXTERNAL unblock_place(place_id)
EXTERNAL trigger_game_over(reason, game_over_type)
EXTERNAL open_ui(ui_name)
EXTERNAL random_loot(table_id)
EXTERNAL trigger_mandatory(trigger_on)
EXTERNAL start_dialogue(dialogue_id)
EXTERNAL set_nickname(character_name, nickname)
EXTERNAL play_sfx(sound_name)

"""


def convert_file(dialogue_path: Path) -> str:
    """Convert a .dialogue file to Ink source."""
    with open(dialogue_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    output: list[str] = []
    first_title: str | None = None
    titles: set[str] = set()
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        leading_ws = line[:len(line) - len(line.lstrip())]

        # Track titles (for entry point and VAR name collision avoidance)
        if stripped.startswith("~ "):
            title_name = stripped[2:].strip()
            titles.add(title_name)
            if first_title is None:
                first_title = title_name

        # Handle consecutive random diverts (% =>)
        if stripped.startswith("% => "):
            random_targets = []
            while i < len(lines) and lines[i].strip().startswith("% => "):
                random_targets.append(lines[i].strip()[4:].strip())
                i += 1
            inner = " | ".join([f"-> {t}" for t in random_targets])
            output.append(leading_ws + f"{{~ {inner} }}")
            continue

        # Handle if/elif/else blocks: output as comments with TODO
        if re.match(r'^if\s', stripped):
            # Comment out the entire block
            output.append(leading_ws + f"// TODO: convert conditional block starting: {stripped}")
            indent_level = len(line) - len(line.lstrip())
            output.append(leading_ws + f"// {stripped}")
            i += 1
            while i < len(lines):
                next_line = lines[i]
                if not next_line.strip():
                    output.append("")
                    i += 1
                    continue
                next_indent = len(next_line) - len(next_line.lstrip())
                # Heuristic: if next line is less or equal indent and is a new knot/choice/etc, block ends
                if next_indent <= indent_level and re.match(r'^(~ |=> |% => |if |elif |else\s*:|\s*#)', next_line.strip()):
                    break
                output.append(f"// {next_line.rstrip()}")
                i += 1
            continue

        converted = convert_line(line, False)
        for cl in converted:
            output.append(leading_ws + cl)
        i += 1

    # Insert top-level entry point before first title
    entry_idx = 0
    if first_title and first_title != "start":
        # Find where to insert: before the first === line
        for idx, line in enumerate(output):
            if line.strip().startswith("=== "):
                output.insert(idx, f"-> {first_title}")
                output.insert(idx, "")
                entry_idx = idx
                break
    elif first_title == "start":
        for idx, line in enumerate(output):
            if line.strip().startswith("=== start ==="):
                output.insert(idx, "-> start")
                output.insert(idx, "")
                entry_idx = idx
                break

    # Collect Flags./MetricStore. variable names referenced in conditions
    # and emit Ink VAR declarations so the story compiles even when the
    # game hasn't synced the values yet.
    var_names: set[str] = set()
    for ln in lines:
        for m in re.finditer(r'\b(Flags|MetricStore)\.([A-Za-z_][A-Za-z0-9_]*)', ln):
            var_names.add(m.group(2))
    # VAR names cannot collide with knot names in Ink
    var_names -= titles
    if var_names:
        var_decls = [""] + [f"VAR {v} = 0" for v in sorted(var_names)] + [""]
        # Insert right after the entry-point arrow (which is at entry_idx + 1)
        insert_at = entry_idx + 2 if entry_idx > 0 else 1
        for decl in reversed(var_decls):
            output.insert(insert_at, decl)

    # Prepend EXTERNAL declarations
    output.insert(0, EXTERNAL_DECLARATIONS.rstrip())

    # Clean up trailing whitespace and normalize
    result = "\n".join(output)
    result = re.sub(r'\n{3,}', '\n\n', result)
    return result + "\n"


def compile_ink(ink_path: Path) -> bool:
    """Compile .ink to .ink.json using inklecate."""
    project_dir = Path(__file__).parent.parent / "project" / "guild-master"
    inklecate = project_dir / "tools" / "inklecate" / "inklecate.exe"
    if not inklecate.exists():
        print(f"ERROR: inklecate not found at {inklecate}")
        return False

    json_path = ink_path.with_suffix(".ink.json")
    cmd = [str(inklecate), "-o", str(json_path), str(ink_path)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", check=True)
        print(f"  Compiled: {json_path.name}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  COMPILE ERROR: {json_path.name}")
        print(e.stdout)
        print(e.stderr)
        return False


def main():
    project_dir = Path(__file__).parent.parent / "project" / "guild-master"
    dialogue_files = list(project_dir.rglob("*.dialogue"))

    print(f"Found {len(dialogue_files)} .dialogue files to convert")

    for dialogue_path in dialogue_files:
        ink_path = dialogue_path.with_suffix(".ink")
        ink_source = convert_file(dialogue_path)

        with open(ink_path, "w", encoding="utf-8") as f:
            f.write(ink_source)

        print(f"Converted: {dialogue_path.relative_to(project_dir)} -> {ink_path.name}")

        # Compile
        compile_ink(ink_path)

    print("Done.")


if __name__ == "__main__":
    main()
