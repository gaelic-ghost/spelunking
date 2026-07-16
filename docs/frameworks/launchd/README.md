# launchctl Control Boundary

## Scope

This private, local-only note records how the Apple-supplied `launchctl`
client addresses and controls the current user's `WallpaperAgent` service. It
does not claim a public API or SIP-enabled result.

## Environment

| Field | Value |
| --- | --- |
| Active OS | macOS 26.5.2 (25F84) |
| SIP during observations | disabled and enabled (retested 2026-07-16) |
| Client | `/bin/launchctl` (`com.apple.xpc.launchctl`) |
| Target | `gui/<uid>/com.apple.wallpaper.agent` |

## Verified Observations

`launchctl` does not address a job by label alone. Its documented service
target grammar is `<domain-target>/<service-id>`. For the Aqua login session,
the WallpaperAgent target is:

```zsh
gui/$(id -u)/com.apple.wallpaper.agent
```

The bare label `com.apple.wallpaper.agent` exits with status 64 and reports an
unrecognised target specifier. This is an argument-format failure before a
request is successfully directed to the service domain.

The following restart succeeded in the SIP-disabled environment:

```zsh
launchctl kickstart -kp "gui/$(id -u)/com.apple.wallpaper.agent"
```

`-k` terminates an existing service instance and `-p` prints the resulting PID.
The live launchd record showed `last terminating signal = Terminated: 15` and
an increased run count. The non-killing form, `launchctl kickstart -p`,
returned the existing PID unchanged. With SIP enabled, the same fully-qualified
command fails with exit code 150: `Operation not permitted while System
Integrity Protection is engaged`.

The manual also exposes a signal-specific service command:

```zsh
launchctl kill SIGTERM "gui/$(id -u)/com.apple.wallpaper.agent"
```

This command is documented but has not been separately executed in this pass;
the `kickstart -k` result already demonstrated launchd's clean termination and
respawn path.

## Transport and Privilege Model

Static imports show that `/bin/launchctl` calls private libxpc/liblaunch client
entry points, including `__launch_msg2` and `__xpc_pipe_interface_routine`.
It is therefore a launchd control-plane client, not simply a wrapper around
the POSIX `kill(2)` syscall.

The Apple-signed executable has private launchd entitlements including
`com.apple.private.xpc.service-configure` and
`com.apple.private.xpc.service-attach`. It also imports `__csr_check`, which
indicates that at least some subcommands consult System Integrity Protection
state. Its strings distinguish configuration failures (`Not privileged to
configure service`, `Not entitled to configure service`) from target lookup
and kickstart failures.

This makes two boundaries distinct:

1. Direct `kill -TERM <pid>` is a kernel signal-delivery request. Its usual
   authorization rule is process credentials: a process may normally signal a
   process owned by the same user. `WallpaperAgent` is Apple-owned code, but
   it runs as the logged-in user in that user's GUI launchd domain.
2. `launchctl kickstart`, `bootout`, `enable`, and related commands ask
   launchd to perform service-management operations. Launchd evaluates the
   named bootstrap domain, the service definition, client credentials, and
   operation-specific policy. Some configuration or unloading operations can
   encounter SIP and entitlement checks even when same-user signalling would
   be permitted.

Consequently, a bare-label failure does not demonstrate a SIP boundary. The
SIP-enabled retest resolves the managed-restart question: launchd denies
`kickstart -k` for this system-owned LaunchAgent. In contrast, direct
same-user `SIGTERM` is accepted by the kernel and launchd respawns the job;
PID `632` became `9524`, run count increased from `1` to `2`, and launchd
recorded `Terminated: 15`.

## Evidence Commands

Run from the repository root:

```zsh
csrutil status
man launchctl | col -b | rg -n -C 3 'kickstart|kill \\[|service-target|domain-target'
nm -u /bin/launchctl | rg 'launch_msg2|xpc_pipe_interface_routine|csr_check|sandbox_check|task_for_pid'
codesign -d --entitlements :- /bin/launchctl
launchctl print "gui/$(id -u)/com.apple.wallpaper.agent"
```

## Open Questions

- Which `launchctl` subcommands directly use `__launch_msg2` versus a
  different XPC helper, and what exact request dictionaries do they send?
- Does `launchctl kill SIGTERM` follow precisely the same launchd bookkeeping
  path as `kickstart -k` for this job?
