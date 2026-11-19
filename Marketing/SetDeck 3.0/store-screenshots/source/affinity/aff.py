#!/usr/bin/env python3
"""Minimal MCP stdio client for the Affinity desktop extension. Usage: mcp.py list | mcp.py call <tool> '<json args>' [more tool/args pairs]
Prints each result. Image content is saved to --out DIR (default: alongside) and its path printed."""
import json, subprocess, sys, os, base64, time, select
EXT = os.path.expanduser("~/Library/Application Support/Claude/Claude Extensions/ant.dir.gh.canva.affinity")
OUT = os.environ.get("AFF_OUT", os.path.dirname(os.path.abspath(__file__)))
TIMEOUT = float(os.environ.get("AFF_TIMEOUT", "900"))
p = subprocess.Popen(["node", EXT + "/server/index.js"], env={**os.environ, "SSE_URL": "http://localhost:6767/sse"}, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
_id = 0
def send(method, params=None, notify=False):
    global _id
    msg = {"jsonrpc": "2.0", "method": method}
    if params is not None: msg["params"] = params
    if not notify:
        _id += 1; msg["id"] = _id
    p.stdin.write(json.dumps(msg) + "\n"); p.stdin.flush()
    if notify: return None
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        r, _, _ = select.select([p.stdout], [], [], 1.0)
        if not r:
            if p.poll() is not None: raise SystemExit("server exited: " + p.stderr.read()[-2000:])
            continue
        line = p.stdout.readline()
        if not line: continue
        try: m = json.loads(line)
        except Exception: continue
        if m.get("id") == _id: return m
    raise SystemExit("timeout waiting for " + method)
init = send("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "claude-code", "version": "1.0"}})
send("notifications/initialized", notify=True)
def show(res, label):
    if "error" in res: print(f"[{label}] ERROR", json.dumps(res["error"])[:3000]); return
    r = res["result"]; n = 0
    for c in r.get("content", []):
        if c.get("type") == "text": print(f"[{label}]", c["text"])
        elif c.get("type") == "image":
            n += 1; ext = (c.get("mimeType") or "image/png").split("/")[-1]
            path = os.path.join(OUT, f"{label}-{int(time.time())}-{n}.{ext}")
            open(path, "wb").write(base64.b64decode(c["data"])); print(f"[{label}] image saved: {path}")
        else: print(f"[{label}]", json.dumps(c)[:1500])
    if r.get("isError"): print(f"[{label}] (isError)")
a = sys.argv[1:]
if not a or a[0] == "info":
    print(json.dumps(init.get("result", {}), indent=1)[:6000])
elif a[0] == "list":
    tools = send("tools/list")["result"]["tools"]
    full = len(a) > 1 and a[1] == "full"
    for t in tools:
        if full: print(json.dumps(t)); 
        else: print("-", t["name"], "::", (t.get("description") or "").split("\n")[0][:170], "| args:", ",".join((t.get("inputSchema", {}).get("properties") or {}).keys()))
elif a[0] == "schema":
    tools = {t["name"]: t for t in send("tools/list")["result"]["tools"]}
    for name in a[1:]: print(json.dumps(tools.get(name, {"missing": name}), indent=1))
elif a[0] == "resources":
    print(json.dumps(send("resources/list"), indent=1)[:6000])
elif a[0] == "prompts":
    print(json.dumps(send("prompts/list"), indent=1)[:6000])
elif a[0] == "call":
    rest = a[1:]
    for i in range(0, len(rest), 2):
        name = rest[i]; raw = rest[i+1] if i+1 < len(rest) else ""; raw = open(raw[1:]).read() if raw.startswith("@") else raw; args = json.loads(raw) if raw.strip() else {}
        show(send("tools/call", {"name": name, "arguments": args}), name)
p.stdin.close()
try: p.wait(timeout=5)
except Exception: p.kill()
