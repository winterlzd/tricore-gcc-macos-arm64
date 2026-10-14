#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess

parser = argparse.ArgumentParser(description='Copy a macOS TriCore toolchain and bundle non-system host dylibs.')
parser.add_argument('toolchain', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
SOURCE = args.toolchain.resolve()
DEST = args.output.resolve()
if not (SOURCE / 'bin/tricore-elf-gcc').is_file():
    raise SystemExit('Input does not contain bin/tricore-elf-gcc')
SYSTEM_PREFIXES = ('/usr/lib/', '/System/Library/')
MAGICS = {b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe', b'\xfe\xed\xfa\xcf',
          b'\xfe\xed\xfa\xce', b'\xca\xfe\xba\xbe', b'\xbe\xba\xfe\xca'}

def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT)

def macho_files(root):
    for path in root.rglob('*'):
        if path.is_file():
            with path.open('rb') as stream:
                if stream.read(4) in MAGICS:
                    yield path

def dependencies(path):
    return [line.strip().split(' (')[0]
            for line in run('otool', '-L', str(path)).splitlines()[1:]]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

if DEST.exists():
    raise SystemExit(f'Staging directory already exists: {DEST}')
DEST.parent.mkdir(parents=True, exist_ok=True)
shutil.copytree(SOURCE, DEST)
hosts = list(macho_files(DEST))
external = {}
queue = hosts[:]
seen = set()
while queue:
    path = queue.pop(0)
    if path in seen:
        continue
    seen.add(path)
    for dep in dependencies(path):
        if dep.startswith(SYSTEM_PREFIXES):
            continue
        if dep.startswith('@loader_path/'):
            resolved = (path.parent / dep.removeprefix('@loader_path/')).resolve()
            if not resolved.is_relative_to(DEST) or not resolved.is_file():
                raise RuntimeError(f'Invalid existing bundled dependency: {dep}')
            continue
        if not dep.startswith('/'):
            raise RuntimeError(f'Unexpected dependency {dep} in {path}')
        original = Path(dep)
        if original == path:
            continue
        if not original.is_file():
            raise RuntimeError(f'Missing dependency: {dep}')
        external[dep] = original
        queue.append(original)

runtime = DEST / 'lib' / 'host'
runtime.mkdir(parents=True, exist_ok=True)
names = [p.name for p in external.values()]
if len(set(names)) != len(names):
    raise RuntimeError('Duplicate library basenames')
libraries = []
for original in external.values():
    target = runtime / original.name
    shutil.copy2(original, target)
    libraries.append(target)

changed = []
for path in hosts + libraries:
    deps = dependencies(path)
    args = ['install_name_tool']
    if path in libraries:
        args.extend(['-id', '@loader_path/' + path.name])
    for dep in deps:
        if dep in external:
            # A dylib's own LC_ID_DYLIB is handled by -id.
            if path in libraries and Path(dep).name == path.name:
                continue
            relative = os.path.relpath(runtime / Path(dep).name, path.parent)
            args.extend(['-change', dep, '@loader_path/' + relative])
    if len(args) > 1:
        args.append(str(path))
        run(*args)
        run('codesign', '--force', '--sign', '-', str(path))
        run('codesign', '--verify', '--strict', str(path))
        changed.append(str(path.relative_to(DEST)))

audited = []
minimum_versions = {}
for path in macho_files(DEST):
    deps = dependencies(path)
    for dep in deps:
        if dep.startswith(SYSTEM_PREFIXES):
            continue
        if not dep.startswith('@loader_path/'):
            raise RuntimeError(f'Nonportable dependency: {path}: {dep}')
        resolved = (path.parent / dep.removeprefix('@loader_path/')).resolve()
        if not resolved.is_relative_to(DEST.resolve()) or not resolved.is_file():
            raise RuntimeError(f'Invalid bundled dependency: {dep}')
    build = run('otool', '-l', str(path)).splitlines()
    versions = [line.strip() for line in build
                if line.strip().startswith(('minos ', 'version '))]
    minimum_versions[str(path.relative_to(DEST))] = versions
    audited.append({'path': str(path.relative_to(DEST)), 'sha256': sha(path),
                    'dependencies': deps})

licenses = DEST / 'share' / 'licenses' / 'host-libraries'
licenses.mkdir(parents=True, exist_ok=True)
for dep, original in external.items():
    package = original.resolve().parent.parent
    package_name = original.resolve().parent.parent.parent.name
    license_dir = licenses / package_name
    license_dir.mkdir(exist_ok=True)
    for candidate in package.iterdir():
        if candidate.is_file() and (candidate.name.upper().startswith(
                ('COPYING', 'LICENSE', 'AUTHORS', 'NOTICE'))):
            shutil.copy2(candidate, license_dir / candidate.name)

previous_manifest = DEST / 'PORTABLE-MANIFEST.json'
previous = json.loads(previous_manifest.read_text()) if previous_manifest.exists() else {}
manifest = {
    'format': 1, 'host': 'macOS arm64', 'gcc_version': '13.4.1',
    'target': 'tricore-elf', 'changed_host_tools': changed or previous.get('changed_host_tools', []),
    'bundled_sources': [{'original': str(p), 'real_path': str(p.resolve()),
                         'original_sha256': sha(p)} for p in external.values()] or previous.get('bundled_sources', []),
    'minimum_macos_load_commands': minimum_versions,
    'macho_files': audited,
}
(DEST / 'PORTABLE-MANIFEST.json').write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
print(json.dumps({'staging': str(DEST), 'bundled_libraries': names,
                  'changed_files': changed, 'macho_count': len(audited),
                  'minimum_versions': {k: v for k, v in minimum_versions.items()
                                       if k in changed}}, indent=2))
