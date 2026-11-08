#!/usr/bin/python3 -I
"""Root-installed, sudo-only bridge into Relay's delegated system cgroup.

Install this file as relay-cpu-group; see cpu-limits.md. Never run a copy
writable by the invoking user as root. This helper does not execute user
commands or accept unit names, arbitrary files, or configuration paths.
"""

import math
import os
from pathlib import Path
import select
import subprocess
import sys

CGROUP = Path("/sys/fs/cgroup")
SLICE = "relaywork.slice"


def systemctl(*args):
    return subprocess.check_output(
        ["systemctl", *args], text=True, env={"PATH": os.defpath + ":/run/current-system/sw/bin"}
    ).strip()


def caller_uid():
    if os.geteuid() != 0 or "SUDO_UID" not in os.environ:
        raise ValueError("run this installed helper through sudo")
    uid = int(os.environ["SUDO_UID"])
    if uid <= 0:
        raise ValueError("the invoking user must not be root")
    return uid


def unit_path(unit):
    value = systemctl("show", "--value", "--property=ControlGroup", unit)
    if not value.startswith("/") or value == "/":
        raise ValueError(f"{unit} has no active cgroup")
    path = (CGROUP / value.lstrip("/")).resolve(strict=True)
    if not path.is_relative_to(CGROUP):
        raise ValueError("invalid systemd cgroup path")
    return path


def worker_path(uid):
    # Fixed system service, never a path chosen by an unprivileged caller.
    path = CGROUP / SLICE / f"relay-workers@{uid}.service"
    if path.stat().st_uid != uid:
        raise ValueError("Relay worker service must delegate its cgroup to the invoking user")
    return path


def checked_destination(root, destination):
    path = Path(destination).resolve(strict=True)
    if path == root or not path.is_relative_to(root):
        raise ValueError("destination must be a child of the delegated Relay worker cgroup")
    # cgroupfs cannot contain symlinks or ordinary user-created files. Checking
    # the mount/device also excludes a substituted path on another filesystem.
    if path.stat().st_dev != CGROUP.stat().st_dev:
        raise ValueError("destination is not on the system cgroup filesystem")
    if not (path / "cgroup.procs").is_file():
        raise ValueError("destination is not a cgroup")
    return path


def process_identity(pid):
    if pid <= 1:
        raise ValueError("invalid process ID")
    status = Path(f"/proc/{pid}/status").read_text()
    uids = next(line.split()[1:] for line in status.splitlines() if line.startswith("Uid:"))
    stat = Path(f"/proc/{pid}/stat").read_text()
    return tuple(map(int, uids)), stat[stat.rfind(")") + 1 :].split()[19]


def attach(root, destination, pid, uid):
    path = checked_destination(root, destination)
    # The caller can only move its own unprivileged processes. Check identity
    # again immediately before writing, and reject an exited pidfd. Normal
    # callers are blocked before exec (or stopped for PTY attachment).
    pidfd = os.pidfd_open(pid)
    try:
        poll = select.poll()
        poll.register(pidfd, select.POLLIN)
        identity = process_identity(pid)
        if identity[0] != (uid, uid, uid, uid):
            raise ValueError("cannot attach a process owned by another user")
        fd = os.open(path / "cgroup.procs", os.O_WRONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
        try:
            if process_identity(pid) != identity or poll.poll(0):
                raise ValueError("process identity changed during attachment")
            os.write(fd, str(pid).encode())
        finally:
            os.close(fd)
    finally:
        os.close(pidfd)


def main(args):
    uid = caller_uid()
    if len(args) == 2 and args[0] == "prepare":
        cores = float(args[1])
        if not math.isfinite(cores) or not 0 < cores <= (os.cpu_count() or 1):
            raise ValueError("CPU budget must be positive and no larger than the host CPU count")
        # Check placement before changing anything. Starting/restarting Nix is
        # deliberately an administrator operation, never an editor side effect.
        shared = unit_path(SLICE)
        if not unit_path("nix-daemon.service").is_relative_to(shared):
            raise ValueError(
                "nix-daemon.service must be configured with Slice=relaywork.slice and restarted"
            )
        systemctl("start", f"relay-workers@{uid}.service")
        root = worker_path(uid)
        if unit_path(f"relay-workers@{uid}.service") != root:
            raise ValueError("Relay worker service must be inside relaywork.slice")
        systemctl("set-property", "--runtime", SLICE, f"CPUQuota={cores * 100:g}%")
        print(root)
    elif len(args) == 3 and args[0] == "attach":
        attach(worker_path(uid), args[1], int(args[2]), uid)
    else:
        raise ValueError("usage: relay-cpu-group prepare CORES | attach CGROUP PID")


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (OSError, ValueError, StopIteration, subprocess.CalledProcessError) as error:
        print(f"relay-cpu-group: {error}", file=sys.stderr)
        sys.exit(1)
