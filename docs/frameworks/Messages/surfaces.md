# Messages App Surfaces

## Scope

This page documents app-level integration and execution surfaces exposed by the macOS Messages app bundle on macOS 26.5.2. It covers URL schemes, AppleScript, app extensions, notification content extensions, storage management, signing identity, and entitlement boundaries.

These are observed surfaces. They are not all supported third-party integration contracts.

## Evidence

Raw captures:

- `research/Messages/surfaces/bundle-surfaces-macos-26.5.2.txt`
- `research/Messages/surfaces/entitlements-macos-26.5.2.plist.txt`
- `research/Messages/surfaces/messages-sdef-macos-26.5.2.xml`
- `research/Messages/surfaces/signing-summary-macos-26.5.2.txt`

## App Entry Points

Main app:

- path: `/System/Applications/Messages.app`
- bundle identifier: `com.apple.MobileSMS`
- executable: `Messages`
- principal class: `SMSApplication`
- Apple Events: `AppleEventSupported` is `true`
- AppleScript: `NSAppleScriptEnabled` is `true`; `OSAScriptingDefinition` is `Messages`
- scene model: app declares a `UIApplicationSceneManifest`
- shortcut item: type `com.apple.mobilesms.newmessage`
- activity types: `com.apple.Messages`, `com.apple.Messages.StateRestoration`

Inference: Messages is a UIKit/iOSSupport-style system app with a Cocoa scripting bridge and app-specific scene restoration/shortcut surfaces.

## URL Schemes

Verified URL schemes from the app manifest:

| Scheme | Manifest name | Notes |
| --- | --- | --- |
| `sms` | SMS URL | Apple default for scheme. Public/user-visible compose-style surface. |
| `sms-private` | SMS Private URL | Marked private in the manifest. Treat as Apple-only unless later behavior evidence proves otherwise. |
| `itms-messages` | Message Store URL | Store/deep-link surface. |
| `itms-messagess` | Message Store URL | Store/deep-link surface; spelling is as observed. |
| `imessage` | IMSG | Apple default for scheme. |
| `iChat` | iChat URL | Apple default for scheme; legacy compatibility surface. |
| `Messages` | Messages URL | Apple default for scheme. |
| `im` | CPIM | Apple default for scheme. |

Open question: which URL forms only open visible UI, which prefill compose state, and which require Apple-signed or private entitlement context.

## AppleScript Surface

Verified scripting dictionary:

- raw: `research/Messages/surfaces/messages-sdef-macos-26.5.2.xml`
- commands: `send`, `login`, `logout`
- app elements: read-only `participants`, `accounts`, `fileTransfers`, `chats`
- service types: `SMS`, `iMessage`, `RCS`
- file-transfer directions: `incoming`, `outgoing`
- file-transfer states: `preparing`, `waiting`, `transferring`, `finalizing`, `finished`, `failed`
- account states: `disconnecting`, `connected`, `connecting`, `disconnected`

Scripting bridge Cocoa bindings:

- application: `SMSApplication`
- command handler: `CKScriptCommand`
- participant: `IMHandle`
- account: `IMAccount`
- chat: `IMChat`
- file transfer: `IMFileTransfer`

Important boundary: AppleScript exposes a local user-controlled automation surface. It does not expose raw `chat.db`, message-history search, private account state mutation beyond login/logout, arbitrary message mutation, or server-side iMessage operation.

## App Extensions And Plugins

| Bundle ID | Bundle | Extension point or role | Principal / handler |
| --- | --- | --- | --- |
| `com.apple.MobileSMS.MessagesActionExtension` | `MessagesActionExtension.appex` | Messages app action extension bundle; no public extension point was visible in the captured lines. | observed bundle metadata only |
| `com.apple.messages.AssistantExtension` | `Messages Assistant Extension.appex` | `com.apple.intents-service` | `SOAssistantIntentHandler` |
| `com.apple.messages.ReplyExtension` | `Messages Reply Extension.appex` | `com.apple.share-services` | `NSSharingContainerViewController`; context class `MessagesPlugInComposeBackToSender` |
| `com.apple.messages.ShareExtension` | `Messages Share Extension.appex` | `com.apple.share-services` | `NSSharingContainerViewController`; context class `MessagesPlugInComposeService` |
| `com.apple.messages.StorageManagementExtension` | `Messages Storage Management Extension.appex` | `com.apple.storagemanagement` | `MessagesStorageManagementExtension` |
| `com.apple.MobileSMS.MessagesPluginNotificationExtension` | `MessagesPluginNotificationExtension.appex` | `com.apple.usernotifications.content-extension` | `CKCustomPluginNotificationViewController` |
| `com.apple.MessagesAppKitBridge` | `MessagesAppKitBridge.bundle` | AppKit bridge bundle | `CKAppKitBridge` |
| `com.apple.iChatDockTilePlugIn` | `iChatDockTile.docktileplugin` | Dock tile plugin | `iChatDockTilePlugIn` |

## Intent Support

The Messages Assistant extension supports these Siri/Intents intents:

- `INEditMessageIntent`
- `INSearchForMessagesIntent`
- `INSendMessageIntent`
- `INPlayMessageSoundIntent`
- `INSetMessageAttributeIntent`
- `INUnsendMessagesIntent`

Inference: Apple ships private/system Messages intent handling beyond the public Messages framework extension surface. The presence of these intent handlers does not make equivalent third-party access available.

## Share And Reply Extensions

The Reply and Share extensions both use the `com.apple.share-services` extension point and support:

- files, max count 10
- images, max count 10
- movies, max count 1
- text
- web URLs, max count 99

Difference:

- Reply extension context class: `MessagesPlugInComposeBackToSender`
- Share extension context class: `MessagesPlugInComposeService`

Inference: the share surfaces are compose-oriented bridges into Messages, not direct transcript access.

## Notification Content Extension

`MessagesPluginNotificationExtension.appex` declares:

- extension point: `com.apple.usernotifications.content-extension`
- category: `com.apple.messages.notification.customplugin.category`
- principal class: `CKCustomPluginNotificationViewController`

Inference: Messages has a custom notification rendering path for plugin-style message notifications. This is a user-notification content surface, not a general message store API.

## Entitlement Boundaries

High-signal entitlement themes from the app and extension captures:

- main app: Messages storage, IMDPersistence database access, IDS/Madrid messaging, APS, user notifications, TCC access, collaboration/social layer, communication safety, and Apple service mach lookups
- Assistant extension: private Intents extension privilege, IMDPersistence database/data-detection access, IDS messaging, contacts, Screen Time, and account access
- Reply/Share extensions: CloudKit/CloudDocs sharing, SocialLayer collaboration, shared recipients, IDS, contacts, communication safety, managed settings, and network access
- Storage Management extension: `com.apple.private.imcore.imdpersistence.database-access`, `com.apple.private.security.storage.Messages`, and read-only access to `/Library/Messages/`
- Notification extension: message-payload provider host, user-notification content extension, media/address book/photos/microphone/camera-related TCC allowances

Inference: the useful private surfaces are protected by Apple-only entitlements and app-extension contexts. Any local tooling that inspects them should treat those privileges as evidence about Apple architecture, not as reusable integration permissions.

## Open Questions

- Which `sms:`, `imessage:`, `Messages:`, and `im:` URL forms prefill visible compose state versus merely launch or route to existing UI?
- What runtime class implements `MessagesActionExtension`, and what host invokes it?
- Which Intents are user-invocable on macOS versus Siri/private/system-only?
- What payload shape does `com.apple.messages.notification.customplugin.category` receive?
- Which AppleScript operations require explicit Automation consent, foreground app state, or an existing participant/chat object?
