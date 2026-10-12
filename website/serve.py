#!/usr/bin/env python3
"""Serves website/public/ the way Cloudflare Pages does: /guides/foo serves
guides/foo.html, /guides/ serves guides/index.html, misses get 404.html.

    python3 website/serve.py [port]     # default 8787
"""
import http.server
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "public"


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def send_head(self):
        path = self.path.split("?")[0].split("#")[0]
        rel = path.lstrip("/")
        target = ROOT / rel
        if path.endswith(".html"):
            self.send_response(308)
            self.send_header("Location", path[:-5] + ("/" if path.endswith("/index.html") else ""))
            self.end_headers()
            return None
        if not target.is_file():
            if (ROOT / (rel + ".html")).is_file():
                self.path = "/" + rel + ".html"
            elif (target / "index.html").is_file():
                if not path.endswith("/"):
                    self.send_response(308)
                    self.send_header("Location", path + "/")
                    self.end_headers()
                    return None
                self.path = path + "index.html"
            else:
                body = (ROOT / "404.html").read_bytes()
                self.send_response(404)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return None
        return super().send_head()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8787
    print(f"serving {ROOT} at http://localhost:{port}")
    http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
