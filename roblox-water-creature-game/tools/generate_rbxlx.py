#!/usr/bin/env python3
"""Regenerates WaterCreatureGame.rbxlx from the src/ tree.

Usage: python3 tools/generate_rbxlx.py

Mirrors default.project.json's layout:
  src/ReplicatedStorage       -> ReplicatedStorage
  src/ServerScriptService     -> ServerScriptService
  src/StarterPlayer/StarterPlayerScripts -> StarterPlayer.StarterPlayerScripts

File-name suffix decides the instance class (Rojo's own convention):
  *.server.lua -> Script
  *.client.lua -> LocalScript
  *.lua         -> ModuleScript
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "WaterCreatureGame.rbxlx")

_referent_counter = [0]


def next_referent():
    _referent_counter[0] += 1
    return f"RBX{_referent_counter[0]}"


def script_class_and_name(filename):
    if filename.endswith(".server.lua"):
        return "Script", filename[: -len(".server.lua")]
    if filename.endswith(".client.lua"):
        return "LocalScript", filename[: -len(".client.lua")]
    if filename.endswith(".lua"):
        return "ModuleScript", filename[: -len(".lua")]
    return None, None


def render_folder_children(dir_path, indent):
    pad = "\t" * indent
    parts = []
    for entry in sorted(os.listdir(dir_path)):
        full = os.path.join(dir_path, entry)
        if os.path.isdir(full):
            parts.append(f'{pad}<Item class="Folder" referent="{next_referent()}">')
            parts.append(f'{pad}\t<Properties>')
            parts.append(f'{pad}\t\t<string name="Name">{entry}</string>')
            parts.append(f'{pad}\t</Properties>')
            parts.append(render_folder_children(full, indent + 1))
            parts.append(f'{pad}</Item>')
        else:
            cls, name = script_class_and_name(entry)
            if cls is None:
                continue
            with open(full, "r", encoding="utf-8") as f:
                source = f.read()
            parts.append(f'{pad}<Item class="{cls}" referent="{next_referent()}">')
            parts.append(f'{pad}\t<Properties>')
            parts.append(f'{pad}\t\t<string name="Name">{name}</string>')
            parts.append(f'{pad}\t\t<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>')
            parts.append(f'{pad}\t</Properties>')
            parts.append(f'{pad}</Item>')
    return "\n".join(parts)


def main():
    lines = []
    lines.append('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
    lines.append("\t<External>null</External>")
    lines.append("\t<External>null</External>")

    lines.append(f'\t<Item class="Workspace" referent="{next_referent()}">')
    lines.append('\t\t<Properties>')
    lines.append('\t\t\t<string name="Name">Workspace</string>')
    lines.append('\t\t</Properties>')
    lines.append('\t</Item>')

    replicated_storage_src = os.path.join(SRC, "ReplicatedStorage")
    lines.append(f'\t<Item class="ReplicatedStorage" referent="{next_referent()}">')
    lines.append('\t\t<Properties>')
    lines.append('\t\t\t<string name="Name">ReplicatedStorage</string>')
    lines.append('\t\t</Properties>')
    lines.append(render_folder_children(replicated_storage_src, 2))
    lines.append('\t</Item>')

    server_script_service_src = os.path.join(SRC, "ServerScriptService")
    lines.append(f'\t<Item class="ServerScriptService" referent="{next_referent()}">')
    lines.append('\t\t<Properties>')
    lines.append('\t\t\t<string name="Name">ServerScriptService</string>')
    lines.append('\t\t</Properties>')
    lines.append(render_folder_children(server_script_service_src, 2))
    lines.append('\t</Item>')

    starter_player_scripts_src = os.path.join(SRC, "StarterPlayer", "StarterPlayerScripts")
    lines.append(f'\t<Item class="StarterPlayer" referent="{next_referent()}">')
    lines.append('\t\t<Properties>')
    lines.append('\t\t\t<string name="Name">StarterPlayer</string>')
    lines.append('\t\t</Properties>')
    lines.append(f'\t\t<Item class="StarterPlayerScripts" referent="{next_referent()}">')
    lines.append('\t\t\t<Properties>')
    lines.append('\t\t\t\t<string name="Name">StarterPlayerScripts</string>')
    lines.append('\t\t\t</Properties>')
    lines.append(render_folder_children(starter_player_scripts_src, 3))
    lines.append('\t\t</Item>')
    lines.append('\t</Item>')

    lines.append("</roblox>")

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
