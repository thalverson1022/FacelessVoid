"""Validate unchanged historical sources or an exact reviewed successor."""
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
def validate_source(path, expected, raw=None):
    actual = hashlib.sha256((ROOT/path).read_bytes() if raw is None else raw).hexdigest()
    if actual == expected:
        return 'unchanged'
    approvals = json.loads((ROOT/'tools/p6/approved_source_successors.json').read_text(encoding='utf-8'))
    entry = approvals.get(path, {})
    assert (expected, actual) == (entry.get('original'), entry.get('successor')), f'Unreviewed source drift: {path}'
    release = json.loads((ROOT/entry['release']).read_text(encoding='utf-8'))
    assert release['balance_authority'] == entry['authority']
    assert release['source_sha256'][path] == actual
    evidence = json.loads((ROOT/entry['evidence']).read_text(encoding='utf-8'))
    assert evidence['original_sha256'] == expected and evidence['current_sha256'] == actual
    return entry['authority']
