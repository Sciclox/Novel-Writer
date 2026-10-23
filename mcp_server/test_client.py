#!/usr/bin/env python3
"""
Test client to verify Novel-Writer MCP Server JSON-RPC communication
"""

import sys
import os
import json
import subprocess
from typing import Any, Dict

# Forzar UTF-8 en Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

def main():
    server_script = os.path.join(os.path.dirname(__file__), "server.py")
    db_path = r"C:\Users\Lenovo\OneDrive\Documentos\novel_writer.db"

    env = os.environ.copy()
    env["NOVEL_WRITER_DB"] = db_path

    print(f"Iniciando proceso MCP Server: {server_script} ...")
    proc = subprocess.Popen(
        [sys.executable, server_script],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        env=env,
        bufsize=1
    )

    msg_id = 1

    def send_recv(req: Dict[str, Any]) -> Dict[str, Any]:
        line = json.dumps(req, ensure_ascii=False)
        proc.stdin.write(line + "\n")
        proc.stdin.flush()
        res_line = proc.stdout.readline()
        if not res_line:
            err = proc.stderr.read()
            raise RuntimeError(f"Servidor terminó inesperadamente. Stderr: {err}")
        return json.loads(res_line)

    try:
        # 1. Test initialize
        print("\n1. Probando handshake 'initialize'...")
        init_res = send_recv({
            "jsonrpc": "2.0",
            "id": msg_id,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test-client", "version": "1.0.0"}
            }
        })
        msg_id += 1
        assert "result" in init_res, f"Fallo en initialize: {init_res}"
        server_name = init_res["result"]["serverInfo"]["name"]
        print(f"[OK] Inicializado exitosamente con servidor: {server_name}")

        # 2. Test tools/list
        print("\n2. Probando 'tools/list'...")
        tools_res = send_recv({
            "jsonrpc": "2.0",
            "id": msg_id,
            "method": "tools/list",
            "params": {}
        })
        msg_id += 1
        tools = tools_res["result"]["tools"]
        print(f"[OK] {len(tools)} herramientas descubiertas:")
        for t in tools:
            print(f"   - {t['name']}: {t['description'][:60]}...")
        assert len(tools) == 11, f"Se esperaban 11 herramientas, se obtuvieron {len(tools)}"

        # 3. Test nw_list_projects
        print("\n3. Probando 'nw_list_projects'...")
        proj_res = send_recv({
            "jsonrpc": "2.0",
            "id": msg_id,
            "method": "tools/call",
            "params": {
                "name": "nw_list_projects",
                "arguments": {}
            }
        })
        msg_id += 1
        proj_data = json.loads(proj_res["result"]["content"][0]["text"])
        for p in proj_data["proyectos"]:
            print(f"   Project {p['id']}: {p['titulo']}")

        web_novel = next((p for p in proj_data["proyectos"] if p["id"] == 18), None)
        if not web_novel:
            web_novel = next((p for p in proj_data["proyectos"] if "Décimo" in p["titulo"]), None)
        assert web_novel is not None, "El proyecto de la novela web debe existir"
        proj_id = web_novel["id"]
        print(f"[OK] Novela Web identificada: ID {proj_id} - '{web_novel['titulo']}' ({web_novel['capitulos']} capítulos)")

        # 4. Test nw_list_chapters
        print(f"\n4. Probando 'nw_list_chapters' para proyecto ID {proj_id}...")
        caps_res = send_recv({
            "jsonrpc": "2.0",
            "id": msg_id,
            "method": "tools/call",
            "params": {
                "name": "nw_list_chapters",
                "arguments": {"proyecto_id": proj_id}
            }
        })
        msg_id += 1
        caps_data = json.loads(caps_res["result"]["content"][0]["text"])
        caps = caps_data["capitulos"]
        print(f"[OK] {len(caps)} capítulos obtenidos. Primer capítulo: '{caps[0]['titulo']}'")
        first_cap_id = caps[0]["id"]

        # 5. Test nw_get_chapter_coherence
        print(f"\n5. Probando 'nw_get_chapter_coherence' para capítulo ID {first_cap_id}...")
        coh_res = send_recv({
            "jsonrpc": "2.0",
            "id": msg_id,
            "method": "tools/call",
            "params": {
                "name": "nw_get_chapter_coherence",
                "arguments": {"capitulo_id": first_cap_id}
            }
        })
        msg_id += 1
        coh_data = json.loads(coh_res["result"]["content"][0]["text"])
        prompt = coh_data.get("ai_context_prompt", "")
        print(f"[OK] Ficha de coherencia generada (longitud: {len(prompt)} caracteres)")
        assert "Long Ze" in prompt, "El prompt debe incluir a Long Ze"
        assert "Asura" in prompt or "Pabellón" in prompt, "El prompt debe contener el contexto de la escena"

        # 6. Test nw_query_lore
        print(f"\n6. Probando 'nw_query_lore' para facciones y artefactos...")
        lore_res = send_recv({
            "jsonrpc": "2.0",
            "id": msg_id,
            "method": "tools/call",
            "params": {
                "name": "nw_query_lore",
                "arguments": {"proyecto_id": proj_id, "tipo": "todos"}
            }
        })
        msg_id += 1
        lore_data = json.loads(lore_res["result"]["content"][0]["text"])
        print(f"[OK] Nodos en el Grafo: {lore_data['total_nodos']}, Aristas: {lore_data['total_aristas']}")
        assert lore_data["total_nodos"] >= 6, "Deben existir al menos 6 nodos en el lore"

        print("\n========================================================")
        print("¡TODAS LAS PRUEBAS DEL SERVIDOR MCP PASARON EXITOSAMENTE!")
        print("========================================================")

    finally:
        proc.terminate()
        proc.wait(timeout=2)

if __name__ == "__main__":
    main()
