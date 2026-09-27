# -*- coding: utf-8 -*-
"""Runs the Apps Script regression suite in Chrome.

  python tool/admin_sheets/test/run_in_chrome.py [--chrome <path>]

Apps Script has no test runner, and this machine has no Node, so the suite runs
in the JavaScript engine that is already here. The .gs files are concatenated
the way Apps Script concatenates a project, the Sheets API is faked
(sheet_fakes.js), and the assertions run twice: against the current code, and
against a reconstruction of the code as it was before the two BLOCKERs were
fixed — so the suite is known to catch them rather than merely agreeing with
whatever is there now.

Exit code 0 when the current code passes every case and the pre-fix code fails
the cases that guard the BLOCKERs.
"""
import argparse
import base64
import json
import os
import socket
import struct
import subprocess
import sys
import tempfile
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SHEETS = os.path.dirname(HERE)

# Apps Script concatenates the project's files into one scope; Config must come
# first because the others read its constants at call time.
GS_FILES = ['Config.gs', 'Validation.gs', 'Setup.gs', 'Sync.gs', 'Firestore.gs']

HARNESS = r"""
(() => {
  const results = [];
  const check = (name) => {
    const failures = [];
    const t = {
      ok: (cond, msg) => { if (!cond) failures.push(msg || 'expected truthy'); },
      equal: (a, b, msg) => {
        if (a !== b) failures.push((msg || '') + ': ' + JSON.stringify(a) + ' !== ' + JSON.stringify(b));
      },
      deepEqual: (a, b, msg) => {
        if (JSON.stringify(a) !== JSON.stringify(b)) {
          failures.push((msg || '') + ': ' + JSON.stringify(a) + ' !== ' + JSON.stringify(b));
        }
      },
    };
    return { t, failures };
  };
  for (const c of SUITE) {
    const { t, failures } = check(c.name);
    let error = null;
    try { c.run(t); } catch (e) { error = String(e && e.message ? e.message : e); }
    results.push({ name: c.name, failures, error });
  }
  return results;
})()
"""


class CDP:
    def __init__(self, port):
        tabs = json.load(urllib.request.urlopen(f'http://127.0.0.1:{port}/json'))
        page = [t for t in tabs if t['type'] == 'page'][0]
        host, path = page['webSocketDebuggerUrl'].replace('ws://', '').split('/', 1)
        h, p = host.split(':')
        self.s = socket.create_connection((h, int(p)))
        self.s.settimeout(60)
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.send((f'GET /{path} HTTP/1.1\r\nHost: {host}\r\nUpgrade: websocket\r\n'
                     f'Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\n'
                     f'Sec-WebSocket-Version: 13\r\n\r\n').encode())
        buf = b''
        while b'\r\n\r\n' not in buf:
            buf += self.s.recv(1)
        self.id = 0
        self.buf = b''

    def _recvn(self, n):
        while len(self.buf) < n:
            d = self.s.recv(1 << 16)
            if not d:
                raise EOFError
            self.buf += d
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def _frame(self):
        b1, b2 = self._recvn(2)
        ln = b2 & 0x7f
        if ln == 126:
            ln = struct.unpack('>H', self._recvn(2))[0]
        elif ln == 127:
            ln = struct.unpack('>Q', self._recvn(8))[0]
        return b1 & 0x0f, self._recvn(ln)

    def send(self, method, params=None):
        self.id += 1
        payload = json.dumps({'id': self.id, 'method': method,
                              'params': params or {}}).encode()
        hdr = bytearray([0x81])
        n = len(payload)
        mask = os.urandom(4)
        if n < 126:
            hdr.append(0x80 | n)
        elif n < 65536:
            hdr.append(0x80 | 126)
            hdr += struct.pack('>H', n)
        else:
            hdr.append(0x80 | 127)
            hdr += struct.pack('>Q', n)
        hdr += mask
        hdr += bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        self.s.send(bytes(hdr))
        while True:
            op, data = self._frame()
            if op not in (0, 1, 2):
                continue
            msg = json.loads(data)
            if msg.get('id') == self.id:
                if 'error' in msg:
                    raise RuntimeError(msg['error'])
                return msg['result']

    def js(self, expr):
        r = self.send('Runtime.evaluate',
                      {'expression': expr, 'returnByValue': True,
                       'awaitPromise': True})
        if 'exceptionDetails' in r:
            d = r['exceptionDetails']
            raise RuntimeError(d.get('exception', {}).get('description') or d.get('text'))
        return r.get('result', {}).get('value')


def read(*parts):
    with open(os.path.join(*parts), encoding='utf-8') as f:
        return f.read()


def run(chrome, port=9351):
    profile = tempfile.mkdtemp(prefix='gs_test_')
    proc = subprocess.Popen(
        [chrome, f'--remote-debugging-port={port}', f'--user-data-dir={profile}',
         '--no-first-run', '--no-default-browser-check', '--headless=new',
         'about:blank'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(60):
            time.sleep(0.5)
            try:
                cdp = CDP(port)
                break
            except Exception:
                continue
        else:
            raise SystemExit('could not reach Chrome on the debugging port')

        sources = '\n'.join(read(SHEETS, f) for f in GS_FILES)
        fakes = read(HERE, 'sheet_fakes.js')
        suite = read(HERE, 'academic_sheet_test.js')

        def load(pre_fix):
            cdp.send('Runtime.evaluate', {'expression': 'location.reload()'})
            time.sleep(0.4)
            cdp.js(fakes)
            cdp.js(sources)
            cdp.js(suite)
            if pre_fix:
                cdp.js('installPreFix()')
            return cdp.js(HARNESS)

        current = load(pre_fix=False)
        prefix = load(pre_fix=True)
    finally:
        proc.terminate()

    failed = [r for r in current if r['failures'] or r['error']]
    print(f'== current code: {len(current) - len(failed)}/{len(current)} passed')
    for r in failed:
        print(f'  FAIL {r["name"]}')
        for f in r['failures']:
            print(f'       {f}')
        if r['error']:
            print(f'       threw: {r["error"]}')

    caught = [r['name'] for r in prefix if r['failures'] or r['error']]
    print(f'== pre-fix code: {len(caught)}/{len(prefix)} cases fail, as they should')
    for n in caught:
        print(f'  caught {n}')

    ok = not failed and len(caught) >= 2
    print('RESULT:', 'ok' if ok else 'PROBLEM')
    if not caught:
        print('  the suite does not fail against the pre-fix code — it guards nothing')
    return 0 if ok else 1


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--chrome',
                    default=r'C:\Program Files\Google\Chrome\Application\chrome.exe')
    a = ap.parse_args()
    if not os.path.exists(a.chrome):
        print('Chrome not found at', a.chrome,
              '- pass --chrome <path>. The suite needs a JavaScript engine; '
              'this project has no Node.')
        sys.exit(2)
    sys.exit(run(a.chrome))
