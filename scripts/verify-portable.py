#!/usr/bin/env python3
"""Run the verifier shipped with the selected toolchain."""
from pathlib import Path
import runpy
import sys
if len(sys.argv) < 2:
    raise SystemExit('Usage: verify-portable.py TOOLCHAIN [--report FILE] [--deny-path PATH]')
verifier = Path(sys.argv[1]).resolve() / 'verify-portable.py'
runpy.run_path(str(verifier), run_name='__main__')
