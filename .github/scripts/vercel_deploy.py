#!/usr/bin/env python3
"""Déploie un dossier statique (build/web Flutter) sur Vercel via l'API REST.

Évite le CLI (v60 casse --token) : utilise VERCEL_TOKEN directement,
qui est accepté par l'API. Sortie : `url=<preview>` dans GITHUB_OUTPUT.

Env requis : VERCEL_TOKEN, VERCEL_ORG_ID (teamId), VERCEL_PROJECT_ID.
Arg 1 : dossier à déployer (défaut: build/web).
"""

import hashlib
import json
import os
import sys
import time
import urllib.request

API = "https://api.vercel.com"


def api(method, path, body=None, raw=None, headers=None):
    token = os.environ["VERCEL_TOKEN"]
    team = os.environ["VERCEL_ORG_ID"]
    sep = "&" if "?" in path else "?"
    url = f"{API}{path}{sep}teamId={team}"
    data = None
    h = {"Authorization": f"Bearer {token}"}
    if raw is not None:
        data = raw
        h["Content-Type"] = "application/octet-stream"
    elif body is not None:
        data = json.dumps(body).encode()
        h["Content-Type"] = "application/json"
    if headers:
        h.update(headers)
    req = urllib.request.Request(url, data=data, headers=h, method=method)
    with urllib.request.urlopen(req, timeout=120) as r:
        content = r.read()
        try:
            return json.loads(content)
        except ValueError:
            return content


def collect(root):
    out = []
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn == ".vercelignored":
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, root).replace(os.sep, "/")
            # Ignore fichiers cachés (.vercel, .gitignore, .DS_Store...).
            if any(part.startswith(".") for part in rel.split("/")):
                continue
            with open(full, "rb") as f:
                data = f.read()
            out.append((rel, data, hashlib.sha1(data).hexdigest()))
    return out


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    project = os.environ["VERCEL_PROJECT_ID"]
    files = collect(root)
    print(f"{len(files)} fichiers, "
          f"{sum(len(d) for _, d, _ in files) // 1024} Ko")

    # 1) Upload de tous les fichiers (l'endpoint de déduplication /v2/files
    #    en JSON est instable : on uploade directement, build/web est petit).
    #    Retry avec backoff : les runners CI se prennent parfois des 403
    #    transitoires (rate-limit/WAF).
    for rel, data, sha in files:
        for attempt in range(5):
            try:
                api("POST", "/v2/files", raw=data, headers={
                    "x-vercel-digest": sha,
                    "x-vercel-size": str(len(data)),
                })
                break
            except Exception as e:
                print(f"retry {attempt + 1}/5 {rel} ({len(data) // 1024} Ko): {e}")
                if attempt == 4:
                    raise
                time.sleep(2 * (attempt + 1))
    print("upload OK")
    dep = api("POST", "/v13/deployments", body={
        "name": "sportflix",
        "project": project,
        "version": 2,
        "files": [{"file": rel, "sha": sha} for rel, _, sha in files],
    })
    dep_id, url = dep["id"], dep["url"]
    print(f"deployment {dep_id} -> https://{url}")

    # 3) Attend READY (statique : quelques secondes).
    for _ in range(60):
        time.sleep(5)
        st = api("GET", f"/v13/deployments/{dep_id}")
        state = st.get("readyState")
        print(f"état: {state}")
        if state == "READY":
            break
        if state == "ERROR":
            print(json.dumps(st)[:2000])
            sys.exit(1)

    final = f"https://{url}"
    print(f"Preview: {final}")
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a") as f:
            f.write(f"url={final}\n")


if __name__ == "__main__":
    main()
