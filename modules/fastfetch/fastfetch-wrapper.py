#!/usr/bin/env python3
# Wrapper around fastfetch that resizes section banners to fit the widest
# data row.  The banners in fastfetch-config.jsonc are static strings like
# "┌──...── NAME ──...──┐"; fastfetch has no built-in way to size them to
# match runtime content.
#
# Strategy (two runs):
#   1. Measurement run: `--logo none --pipe true` — gives plain-text, sequential
#      output with no ANSI codes and no cursor-positioning trickery.  Easy to
#      parse via captured pipe; max visible width across data rows is the
#      target banner size.
#   2. Real run: pass-through invocation that keeps the logo + colors.  Runs
#      under `pty.fork()` so the child gets a proper controlling-TTY PTY (not
#      just a slave fd as stdout).  Required on macOS where fastfetch's
#      terminal-mode output (`--pipe false`) opens `/dev/tty` directly; a
#      controlling-TTY PTY makes the child's `/dev/tty` resolve to our slave,
#      so we capture all of fastfetch's output regardless of which fd it
#      writes to.
#
# If the measurement run fails (Darwin module gap, slow probe, transient
# error), the wrapper falls through to the real run un-rewritten — the user
# still sees fastfetch's default output rather than an empty terminal.
#
# Env vars:
#   FASTFETCH_BIN     — path to the real fastfetch binary (default: "fastfetch")
#   FASTFETCH_CONFIG  — explicit config path; if unset, fastfetch auto-loads
#                       its default (~/.config/fastfetch/config.jsonc). The
#                       wrapper deliberately does NOT pass --config when this
#                       env is unset because fastfetch refuses to merge an
#                       auto-loaded default + an explicit --config ("only one
#                       config file can be loaded").
#
# All other CLI args are passed through to fastfetch.

import fcntl
import os
import pty
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import termios
import time

# Force UTF-8 stdout regardless of locale — macOS without LANG=…UTF-8 falls
# back to ASCII and would otherwise mojibake every Nerd Font glyph.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ANSI = re.compile(r"\x1b\[[0-9;]*m")

# Banner regex — finds an occurrence anywhere in the line.  Fastfetch overlays
# the info column on the logo via cursor-positioning escapes (`\x1b[71C` etc.);
# those are outside this regex's window, so `re.sub` rewrites only the banner.
BANNER_RE = re.compile(
    r"((?:\x1b\[[0-9;]*m)*)"  # 1: ANSI prefix
    r"([┌├└])"  # 2: left corner
    r"(─+)"  # 3: left dashes
    r"(?: "
    r"((?:\x1b\[[0-9;]*m|[^─\x1b])+?)"  # 4: name w/ inline ANSI (multi-color titles)
    r" "
    r"(─+))?"  # 5: right dashes
    r"([┐┤┘])"  # 6: right corner
)

PLAIN_BANNER_RE = re.compile(r"^\s*[┌├└]─.*[┐┤┘]\s*$")

PTY_TIMEOUT = 30  # seconds


def visible_len(s):
    return len(ANSI.sub("", s))


def _term_size():
    """(rows, cols) for the pty winsize.  Mirror the user's real terminal when
    available so fastfetch picks a sensible line-wrap point; fall back to a
    wide default when stdout is piped/redirected."""
    try:
        cols, rows = shutil.get_terminal_size((200, 50))
    except OSError:
        cols, rows = 200, 50
    return rows, cols


def run_piped(cmd):
    """Captured-pipe run.  Used only for the measurement pass — that pass
    forces `--pipe true` which always writes plain text to stdout, so a pipe
    works fine on every platform."""
    try:
        r = subprocess.run(
            cmd,
            capture_output=True,
            stdin=subprocess.DEVNULL,
            encoding="utf-8",
            errors="replace",
            timeout=PTY_TIMEOUT,
        )
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "fastfetch wrapper: measurement subprocess timed out\n"
    except Exception as e:  # noqa: BLE001
        return -1, "", f"fastfetch wrapper: measurement subprocess failed: {e}\n"


def run_with_controlling_pty(cmd):
    """Run `cmd` under a controlling-TTY PTY via `pty.fork()`.  Child stdin/
    stdout/stderr are all wired to the slave; opening `/dev/tty` inside the
    child also resolves to the slave.  Parent reads everything via the
    returned master fd.

    Returns `(returncode, stdout_text, stderr_text)`.  stderr is always empty
    because pty.fork merges stderr into the same pty as stdout — fastfetch's
    diagnostic output (if any) ends up in stdout."""
    rows, cols = _term_size()
    try:
        pid, master_fd = pty.fork()
    except OSError as e:
        return -1, "", f"fastfetch wrapper: pty.fork failed: {e}\n"

    if pid == 0:
        # Child — slave is fd 0/1/2 + controlling tty.
        try:
            fcntl.ioctl(
                0,
                termios.TIOCSWINSZ,
                struct.pack("HHHH", rows, cols, 0, 0),
            )
        except OSError:
            pass
        try:
            os.execvp(cmd[0], cmd)
        except OSError:
            os._exit(127)

    # Parent
    chunks = []
    deadline = time.monotonic() + PTY_TIMEOUT
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                os.waitpid(pid, 0)
            except ChildProcessError:
                pass
            try:
                os.close(master_fd)
            except OSError:
                pass
            return -1, "", "fastfetch wrapper: real run timed out\n"

        ready, _, _ = select.select([master_fd], [], [], min(remaining, 0.5))
        if ready:
            try:
                data = os.read(master_fd, 65536)
            except OSError:
                # EIO is the normal end-of-file signal on a pty master when
                # the slave is closed (which happens when the child exits).
                break
            if not data:
                break
            chunks.append(data)
            continue

        # Nothing to read yet — check whether child has exited.
        try:
            done_pid, status = os.waitpid(pid, os.WNOHANG)
        except ChildProcessError:
            done_pid, status = pid, 0
        if done_pid:
            # Drain any output still buffered in the master.
            while True:
                r, _, _ = select.select([master_fd], [], [], 0.05)
                if not r:
                    break
                try:
                    data = os.read(master_fd, 65536)
                except OSError:
                    break
                if not data:
                    break
                chunks.append(data)
            try:
                os.close(master_fd)
            except OSError:
                pass
            rc = os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1
            return rc, b"".join(chunks).decode("utf-8", errors="replace"), ""

    # select returned ready + read returned EOF — child should be exiting.
    try:
        _, status = os.waitpid(pid, 0)
        rc = os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1
    except ChildProcessError:
        rc = 0
    try:
        os.close(master_fd)
    except OSError:
        pass
    return rc, b"".join(chunks).decode("utf-8", errors="replace"), ""


def _debug(msg):
    if os.environ.get("FASTFETCH_WRAPPER_DEBUG"):
        sys.stderr.write(f"[wrapper] {msg}\n")


def main():
    bin_path = os.environ.get("FASTFETCH_BIN", "fastfetch")
    config = os.environ.get("FASTFETCH_CONFIG")
    base_args = (["--config", config] if config else []) + sys.argv[1:]
    _debug(f"bin={bin_path} config={config!r} extra_args={sys.argv[1:]!r}")
    _debug(f"platform={sys.platform} python={sys.version.split()[0]}")

    # 1. Measurement run — plain text, no logo.  Failures here are non-fatal.
    target_width = 0
    measure_cmd = [bin_path] + base_args + ["--logo", "none", "--pipe", "true"]
    _debug(f"measure cmd: {measure_cmd}")
    rc, stdout, stderr = run_piped(measure_cmd)
    _debug(f"measure rc={rc} stdout_len={len(stdout)} stderr_len={len(stderr)}")
    if stderr:
        _debug(f"measure stderr: {stderr.strip()!r}")
    if rc == 0 and stdout:
        plain_lines = stdout.splitlines()
        data_widths = [
            len(line)
            for line in plain_lines
            if line.strip() and not PLAIN_BANNER_RE.match(line)
        ]
        if data_widths:
            target_width = max(data_widths)
    _debug(f"target_width={target_width}")

    # 2. Real run — colors + logo under a controlling-TTY PTY.
    real_cmd = [bin_path] + base_args + ["--pipe", "false"]
    _debug(f"real cmd: {real_cmd}")
    rc, stdout, stderr = run_with_controlling_pty(real_cmd)
    _debug(f"real rc={rc} stdout_len={len(stdout)}")
    if stderr:
        _debug(f"real stderr: {stderr.strip()!r}")
    if rc != 0 and stderr:
        sys.stderr.write(stderr)
    # Print whatever stdout we captured even if fastfetch exited non-zero —
    # on macOS, fastfetch 2.63.1 SIGABRTs mid-output for some module
    # combinations and ~1.5 KB of partial output is still better than a
    # blank terminal.  PTY's line-buffered nature means that partial output
    # actually reaches us; the same crash via captured pipe yields zero
    # bytes because stdio doesn't flush before abort().

    if target_width > 0 and stdout:

        def replace_banner(m):
            ansi_l, cl, _, name, _, cr = m.groups()
            inner = target_width - 2  # subtract two corners
            if inner < 0:
                return m.group(0)
            if name is None:
                return ansi_l + cl + "─" * inner + cr
            nv = visible_len(name)
            total_dashes = max(0, inner - 2 - nv)  # 2 spaces around name
            left = total_dashes // 2
            right = total_dashes - left
            return ansi_l + cl + "─" * left + " " + name + " " + "─" * right + cr

        stdout = BANNER_RE.sub(replace_banner, stdout)

    sys.stdout.write(stdout)
    return rc if rc > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
