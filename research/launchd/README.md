# launchctl Raw Research

Matching stable documentation: [`docs/frameworks/launchd/README.md`](../../docs/frameworks/launchd/README.md).

## Current Runtime State

```text
System Integrity Protection status: enabled.
```

The service examined in this pass is the current user's Aqua LaunchAgent:

```zsh
job="gui/$(id -u)/com.apple.wallpaper.agent"
launchctl print "$job"
```

With SIP enabled, fully-qualified `kickstart -kp` failed with exit code 150:

```text
Could not kickstart service "com.apple.wallpaper.agent": 150: Operation not permitted while System Integrity Protection is engaged
```

Direct same-user `kill -TERM` succeeded: PID `632` became `9524`, `runs`
increased from `1` to `2`, and launchd reported `last terminating signal =
Terminated: 15`.

## Target Parsing Reproduction

```zsh
launchctl kickstart -p "gui/$(id -u)/com.apple.wallpaper.agent"
launchctl kickstart -p com.apple.wallpaper.agent
```

The first prints the active PID and exits zero. The second exits 64 with:

```text
Unrecognized target specifier, did you mean gui/<uid>/com.apple.wallpaper.agent
```

## Static Capture

```zsh
nm -u /bin/launchctl | rg 'launch_msg2|xpc_pipe_interface_routine|csr_check|sandbox_check|task_for_pid'
codesign -d --entitlements :- /bin/launchctl
strings -a /bin/launchctl | rg -n -C 2 'Not privileged to configure|Not entitled to configure|Disable SIP|kickstart|service-target'
```

The binary imports `__launch_msg2`, `__xpc_pipe_interface_routine`,
`__csr_check`, `__sandbox_check`, and `__task_for_pid`. Its signed entitlement
set includes private service-configuration and service-attach privileges.
