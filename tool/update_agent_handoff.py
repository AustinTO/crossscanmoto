#!/usr/bin/env python3
"""Refresh the repository snapshot in the durable agent handoff."""

from datetime import datetime, timezone
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HANDOFF = ROOT / 'AGENT_HANDOFF.md'
START = '<!-- REPOSITORY_SNAPSHOT:START -->'
END = '<!-- REPOSITORY_SNAPSHOT:END -->'


def git(*arguments):
    return subprocess.check_output(
        ['git', *arguments], cwd=ROOT, text=True,
    ).strip()


def main():
    content = HANDOFF.read_text()
    snapshot = '\n'.join([
        START,
        '## Repository snapshot',
        '',
        f"Captured {datetime.now(timezone.utc).isoformat(timespec='seconds')}.",
        f"HEAD: `{git('rev-parse', 'HEAD')}`.",
        f"Branch: `{git('branch', '--show-current')}`.",
        '',
        '```text',
        git('status', '--short') or '(clean)',
        '```',
        '',
        'Refresh with `python tool/update_agent_handoff.py` after a checkpoint.',
        'This is a captured state; rerun git status before changing files.',
        END,
    ])
    if START in content and END in content:
        before, rest = content.split(START, 1)
        _, after = rest.split(END, 1)
        content = before + snapshot + after
    else:
        heading = '## User objective and operating constraints'
        content = content.replace(heading, snapshot + '\n\n' + heading, 1)
    HANDOFF.write_text(content)
    print('Updated AGENT_HANDOFF.md repository snapshot')


if __name__ == '__main__':
    main()
