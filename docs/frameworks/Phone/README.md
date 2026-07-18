# Phone

Read-only research into supported and private local Phone and calling surfaces on macOS. The current baseline maps public call APIs, `Phone.app`, call-history structure without row data, telephony private frameworks, agents, notifications, hooks, and XPC ownership.

## Status

Baseline established on macOS 26.5.2 (25F84) against the macOS 27.0 SDK. Generated interfaces, comparison against another OS build, and controlled call-event proof remain open.

## Start Here

1. Read the [supported and private boundary](surfaces.md) before choosing an integration or experiment.
2. Use the [comprehensive baseline](baseline.md) for the environment, evidence checklist, initial findings, and open questions.
3. Follow the topic index below for focused conclusions.
4. Consult the [raw-evidence index](../../../research/Phone/README.md) only when reproducing or auditing a capture.

No command in this index initiates a call or reads call-history rows. Some documented experiments inspect private frameworks, app metadata, daemon configuration, or database schema and can require Full Disk Access, TCC permission, entitlements, or OS-specific private-framework availability.

## Topic Index

- [Surfaces](surfaces.md): supported call APIs, URL schemes, manifests, and the public/private boundary.
- [Storage](storage.md): call-history schema, relationships, lifecycle metadata, and privacy limits.
- [Types](types.md): supported and private type families.
- [Symbols](symbols.md): SDK and live symbol evidence.
- [Agents](agents.md): apps, agents, daemons, plugins, and service ownership.
- [Runtime](runtime.md): Objective-C metadata and dyld-cache observations.
- [Hooks](hooks.md): intent, listener, query, callback, and interception surfaces.
- [Notifications](notifications.md): candidate names, delivery mechanisms, and observer evidence.
- [XPC ownership](xpc-ownership.md): launchd services, entitlements, clients, and authority boundaries.
- [Experiments](experiments.md): completed, blocked, and proposed research steps.

## Cross-Target Context

Phone and Messages share several communication-service boundaries. Use the [combined status map](../messages-phone-status.md) when a finding crosses both targets.
