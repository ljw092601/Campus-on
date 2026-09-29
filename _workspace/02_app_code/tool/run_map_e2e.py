"""Run the real map E2E on an already-booted Android emulator.

Uses env.json locally (never prints its contents). --firestore enables read-only
production content. Logs go to the OS temp directory unless --log is supplied.
The test's GPS checkpoints drive native Android permission and emulator fixes.
"""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', default='emulator-5554')
    parser.add_argument('--flutter', default=shutil.which('flutter') or
                        str(Path.home() / 'flutter/bin/flutter.bat'))
    parser.add_argument('--adb', default=shutil.which('adb') or str(
        Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'))
    parser.add_argument('--firestore', action='store_true')
    parser.add_argument('--log', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    mode = 'firestore' if args.firestore else 'mock'
    log_path = args.log or Path(tempfile.gettempdir()) / f'campus-map-e2e-{mode}.log'
    command = [args.flutter, 'test', '-d', args.device,
               'integration_test/map_state_e2e_test.dart',
               '--dart-define-from-file=env.json', '--no-pub']
    for flag in ('USE_FIRESTORE', 'USE_FIRESTORE_CALENDAR', 'USE_FIRESTORE_DINING'):
        command.append(f'--dart-define={flag}={str(args.firestore).lower()}')

    def adb(*arguments):
        subprocess.run([args.adb, '-s', args.device, *arguments],
                       check=True, capture_output=True, timeout=20)

    print(f'Running {mode} map E2E; log: {log_path}', flush=True)
    env = dict(os.environ, ANDROID_SERIAL=args.device)
    with log_path.open('w', encoding='utf-8') as log:
        process = subprocess.Popen(command, cwd=root, env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, encoding='utf-8', errors='replace')
        seen = set()
        for line in process.stdout:
            log.write(line)
            log.flush()
            if any(word in line for word in ('E2E_', 'Error:', 'failed', 'passed!',
                                             'Running Gradle task', 'Built ', 'Installing')):
                print(line.rstrip(), flush=True)
            if 'E2E_GPS_PERMISSION' in line and 'permission' not in seen:
                seen.add('permission')
                for permission in ('ACCESS_COARSE_LOCATION', 'ACCESS_FINE_LOCATION'):
                    adb('shell', 'pm', 'grant', 'io.github.ljw092601.campuson',
                        f'android.permission.{permission}')
            match = re.search(r'E2E_GPS_FIX_(\d)', line)
            if match and match[1] not in seen:
                index = int(match[1])
                seen.add(match[1])
                for _ in range(3):
                    adb('emu', 'geo', 'fix', str(128.968 + index * .001),
                        str(35.115 + index * .001))
                    time.sleep(.6)
        code = process.wait()
    print(f'E2E exit code: {code}', flush=True)
    return code


if __name__ == '__main__':
    raise SystemExit(main())
