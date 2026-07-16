# Messages And Phone Research Status

## Scope

This page tracks the current state of the local-only Messages and Phone research goal across both targets. It is a navigation and audit aid: use the target-specific pages for full details, raw command context, and evidence interpretation.

The status below separates verified evidence from inference and from remaining work. It does not declare the overall reverse-engineering goal complete.

## Current Environment

| Field | Messages | Phone |
| --- | --- | --- |
| Active OS | macOS 26.5.2 build 25F84 | macOS 26.5.2 build 25F84 |
| SDK comparison | macOS 27.0 SDK and iPhoneOS 27.0 SDK | macOS 27.0 SDK and iPhoneOS 27.0 SDK |
| Primary app | `/System/Applications/Messages.app` | `/System/Applications/Phone.app` |
| Bundle identifier | `com.apple.MobileSMS` | `com.apple.mobilephone` |
| Main target docs | [Messages README](Messages/README.md) | [Phone README](Phone/README.md) |
| Raw evidence index | [Messages research README](../../research/Messages/README.md) | [Phone research README](../../research/Phone/README.md) |

## Coverage Matrix

| Requirement area | Messages status | Phone status | Evidence |
| --- | --- | --- | --- |
| Supported public surfaces | Documented | Documented | [Messages README](Messages/README.md), [Messages surfaces](Messages/surfaces.md), [Phone README](Phone/README.md), [Phone surfaces](Phone/surfaces.md) |
| Private local surfaces | Documented | Documented | [Messages README](Messages/README.md), [Phone README](Phone/README.md) |
| App manifests, URL schemes, scripting, extensions, intents | Documented from app bundles and bounded root URL probes | Documented from app bundles, `sdef` failure, and bounded root URL probes | [Messages surfaces](Messages/surfaces.md), [Phone surfaces](Phone/surfaces.md), raw `research/*/surfaces/` files |
| Storage schema | `chat.db` schema, relationships, indexes, triggers, and lifecycle notes documented without row data | `CallHistory.storedata` schema, indexes, Core Data relationship boundary, and lifecycle notes documented without row data | [Messages storage](Messages/storage.md), [Phone storage](Phone/storage.md), raw `research/*/storage/` files |
| Agents, services, and XPC ownership | LaunchAgents, XPC services, app extensions, plugin edges, runtime activation edges, entitlement correlations, and allowlist boundaries documented | LaunchAgents, XPC/extension services, entitlement-backed service edges, runtime activation edges, mach-service/protocol correlations, and intent-handler privileges documented | [Messages agents](Messages/agents.md), [Messages XPC ownership](Messages/xpc-ownership.md), [Phone agents](Phone/agents.md), [Phone XPC ownership](Phone/xpc-ownership.md) |
| Hooks and private XPC protocols | Focused daemon, automation, query, listener, and notification hook map documented | Focused TelephonyUtilities, CallHistory, conversation, private CallKit host/vendor, voicemail, and notification hook map documented | [Messages hooks](Messages/hooks.md), [Phone hooks](Phone/hooks.md), raw hook inventory JSON files |
| Types and runtime metadata | High-signal Objective-C class/protocol families documented from runtime captures | High-signal Objective-C class/protocol families and Swift-only SDK families documented from runtime captures and `.tbd` symbols | [Messages types](Messages/types.md), [Phone types](Phone/types.md), raw `research/*/runtime/objc-runtime-*.json` files |
| Symbols and generated-interface boundary | SDK `.tbd`, dyld export probe, and dyld-cache/interface-tooling boundary documented; full generated interfaces still pending | SDK `.tbd`, dyld export probe, and dyld-cache/interface-tooling boundary documented; full generated interfaces still pending | [Messages symbols](Messages/symbols.md), [Phone symbols](Phone/symbols.md), raw `research/*/runtime/dyld-cache-interface-boundary-*.txt` files |
| Notifications | Launchd/notify triggers, SDK notification symbols, runtime string constants, and bounded observer baselines documented | Launchd/notify triggers, SDK notification symbols, runtime string constants, CTTelephonyCenter/Darwin naming, and bounded observer baselines documented | [Messages notifications](Messages/notifications.md), [Phone notifications](Phone/notifications.md), raw `research/*/notifications/` files |
| Runtime app-open behavior | Bounded app-open logs interpreted | Bounded app-open logs interpreted | [Messages runtime](Messages/runtime.md), [Phone runtime](Phone/runtime.md) |
| Privacy boundary | Documented; schema/log/runtime work avoids row data, message content, handles, recipients, attachment names, and counts | Documented; schema/log/runtime work avoids call rows, phone numbers, contacts, voicemail metadata, call content, and unredacted device identifiers | [Messages experiments](Messages/experiments.md), [Phone experiments](Phone/experiments.md), raw research READMEs |
| OS comparison | Not complete | Not complete | Open evidence inventory item in each target README |

## Verified Observations

### Messages

- The supported Messages paths are user-visible and app-owned: Messages extensions, Shared with You/collaboration metadata, App Intents for app actions, MessageUI composer flows, and limited macOS Apple Events.
- `Messages.app` exposes AppleScript, root URL scheme routing, multiple app extensions/plugins, broad private entitlements, and XPC service dependencies.
- `chat.db` documentation covers tables, columns, join tables, foreign keys, indexes, triggers, sync/deletion tables, persistent-task tables, and trigger-lifecycle behavior without inspecting personal rows.
- Runtime metadata shows a split between app/model classes, daemon/persistence classes, explicit automation hooks, daemon protocols, query protocols, listener routes, and notification context classes.
- Launchd and XPC evidence supports a privileged `IMDPersistenceAgent` database-broker model with Apple-signed allowed clients rather than a general third-party IPC endpoint.

### Phone

- The supported Phone/call paths are user-visible or app-owned: `tel:`/FaceTime-style URL routing, public CallKit, LiveCommunicationKit, and App Intents.
- `Phone.app` does not expose an AppleScript dictionary on this machine; `sdef` returned error `-192`.
- Call history documentation covers the Core Data SQLite store tables, indexes, absence of SQLite-enforced foreign keys/triggers, handle joins, emergency media, properties, and transaction-log boundary without inspecting personal rows.
- Runtime metadata shows a split between `CH*`/`CallDB*` persisted recents, `TU*` live call and conversation services, private `CX*` host/vendor internals, CallsXPC/CallsPersistence Swift families, and Phone App Intents entities.
- Launchd and XPC evidence supports a `callservicesd` broker model backed by CallHistory, CommCenter, FaceTime, voicemail, IDS, and intent-handler services.

## Inference Boundaries

- Private Objective-C runtime metadata proves class names, protocol names, selector names, and property names. It does not prove reachability, entitlements, call order, argument payload schemas, or side effects.
- SDK `.tbd` and demangled Swift symbols prove exported names and high-level type families. They are not full generated interfaces and do not provide implementation behavior.
- Bounded root URL probes prove routing into visible app open-URL paths. They do not prove payload-bearing compose, dial, voicemail, or hidden action behavior.
- Bounded observer baselines prove no observed posts during the captured app-open windows. They do not prove notification absence in other flows.
- Storage schema captures prove database shape and relationships. They do not prove semantic meanings for every integer flag, task payload, message state, call status, or blob field.

## Remaining Work

### Read-Only

- Extract live dyld shared cache images or find another metadata path capable of producing full generated private interfaces for IM, MessagesKit, TelephonyUtilities, CallHistory, CallsXPC, CallsPersistence, and PhoneAppIntents surfaces.
- Compare at least one additional macOS build against the macOS 26.5.2 captures to separate stable structure from release-specific structure.
- Decode high-signal integer and blob fields without reading personal rows, especially Messages task/state fields and Phone call status/category fields.
- Classify more notification constants through controlled read-only observers or narrow log predicates.
- Prove private XPC protocol family dispatch with generated interfaces, endpoint metadata, or traffic traces where mach-service/name correlation is still indirect.

### Controlled Visible Or Mutating

These remain explicitly separate from the read-only baseline and need controlled test data or explicit approval before use:

- payload-bearing Messages URL tests with non-sensitive test recipients
- Messages AppleScript `send` in a controlled test chat
- controlled attachment send and scheduled-message behavior
- payload-bearing Phone URL tests that do not place real calls
- controlled call, voicemail, or call-record UI paths

## Recommended Next Slices

1. Generated-interface lane: locate and test a dyld-cache extraction or metadata path, then persist generated interface artifacts under `research/<Target>/runtime/` and summarize stable findings in `symbols.md` and `types.md`.
2. XPC ownership lane: build a read-only mach-service and entitlement correlation table for each private protocol family, starting from `IMDPersistenceAgent`, `imagent`, `callservicesd`, CallHistory services, and CallKit host classes.
3. Notification lane: run controlled observer/log windows against non-sensitive UI actions and update notification docs with positive/negative evidence.
4. Storage semantics lane: decode schema-level flags and enum-like fields from symbols and generated interfaces before considering any row-level test fixture.
