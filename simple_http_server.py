#!/usr/bin/env python3
"""
Simple HTTP Server - Exercise 4
Serves a simple HTML page on port 8080
"""

import http.server
import socketserver
from datetime import datetime

PORT = 8080

HTML_PAGE = """<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple Python HTTP Server</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', Tahoma, sans-serif;
            background: linear-gradient(135deg, #1a1a2e, #16213e, #0f3460);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #eee;
        }
        .container {
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 16px;
            padding: 40px 60px;
            text-align: center;
            max-width: 600px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { font-size: 2rem; margin-bottom: 10px; color: #e94560; }
        .subtitle { color: #a8b2d8; margin-bottom: 30px; font-size: 0.9rem; }
        .badge {
            display: inline-block;
            background: rgba(233, 69, 96, 0.2);
            color: #e94560;
            border: 1px solid #e94560;
            border-radius: 20px;
            padding: 4px 16px;
            font-size: 0.85rem;
            margin-bottom: 30px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-top: 20px;
        }
        .info-card {
            background: rgba(255,255,255,0.05);
            border-radius: 10px;
            padding: 16px;
            border: 1px solid rgba(255,255,255,0.08);
        }
        .info-card .label { font-size: 0.75rem; color: #8892b0; margin-bottom: 6px; }
        .info-card .value { font-size: 1.1rem; font-weight: bold; color: #ccd6f6; }
        footer { margin-top: 30px; font-size: 0.8rem; color: #556; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐍 Python HTTP Server</h1>
        <p class="subtitle">تمرین چهارم - شبکه</p>
        <span class="badge">✔ Server is Running</span>

        <div class="info-grid">
            <div class="info-card">
                <div class="label">PORT</div>
                <div class="value">8080</div>
            </div>
            <div class="info-card">
                <div class="label">PROTOCOL</div>
                <div class="value">HTTP/1.1</div>
            </div>
            <div class="info-card">
                <div class="label">SERVER</div>
                <div class="value">Python 3</div>
            </div>
            <div class="info-card">
                <div class="label">STATUS</div>
                <div class="value" style="color:#50fa7b;">Active</div>
            </div>
        </div>

        <footer>Simple HTTP Server &mdash; http.server module &mdash; Python Standard Library</footer>
    </div>
</body>
</html>"""


class CustomHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(HTML_PAGE.encode("utf-8"))))
        self.end_headers()
        self.wfile.write(HTML_PAGE.encode("utf-8"))

    def log_message(self, format, *args):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {self.address_string()} - {format % args}")


if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        httpd.allow_reuse_address = True
        print(f"[*] Simple HTTP Server started on port {PORT}")
        print(f"[*] Open http://localhost:{PORT} in your browser")
        print(f"[*] Press Ctrl+C to stop\n")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[*] Server stopped.")
