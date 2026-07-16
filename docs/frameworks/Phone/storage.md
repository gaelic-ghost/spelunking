# Phone Storage

## Scope

This page documents the local Phone/CallHistory Core Data SQLite schema observed on macOS 26.5.2. It is schema-only research. No call rows, phone numbers, contact names, timestamps, durations, voicemail metadata, row counts, or transaction contents were captured.

## Evidence

Raw capture:

- `research/Phone/storage/callhistory-schema-macos-26.5.2.txt`

Capture method:

- `plutil -p "$HOME/Library/Application Support/CallHistoryDB/com.apple.callhistory.databaseInfo.plist"`
- `sqlite3 "$HOME/Library/Application Support/CallHistoryDB/CallHistory.storedata" ".tables"`
- `pragma_table_info` for every table
- `sqlite_schema` entries for table, index, trigger, and view definitions

`com.apple.callhistory.databaseInfo.plist` reports `DatabaseVersionPerm` as `43`.

## Core Tables

| Table | Role |
| --- | --- |
| `ZCALLRECORD` | Main call/recents record entity. |
| `ZHANDLE` | Remote participant handle entity with raw and normalized values. |
| `Z_2REMOTEPARTICIPANTHANDLES` | Many-to-many join between call records and remote participant handles. |
| `ZEMERGENCYMEDIAITEM` | Emergency media item entity linked to calls. |
| `ZCALLDBPROPERTIES` | Call timer and database property entity. |
| `Z_METADATA`, `Z_MODELCACHE`, `Z_PRIMARYKEY` | Core Data store metadata and primary-key bookkeeping. |

## Call Record Columns

High-signal `ZCALLRECORD` columns:

- Core Data bookkeeping: `Z_PK`, `Z_ENT`, `Z_OPT`
- boolean/state flags: `ZANSWERED`, `ZORIGINATED`, `ZREAD`, `ZFACE_TIME_DATA`, `ZHASMESSAGE`, `ZWASEMERGENCYCALL`, `ZUSEDEMERGENCYVIDEOSTREAMING`
- call classification: `ZCALLTYPE`, `ZCALL_CATEGORY`, `ZDISCONNECTED_CAUSE`, `ZINITIATOR`, `ZORIGINATINGUITYPE`, `ZSCREENSHARINGTYPE`
- caller identity/status: `ZHANDLE_TYPE`, `ZNUMBER_AVAILABILITY`, `ZVERIFICATIONSTATUS`, `ZCOMMUNICATIONTRUSTSCORE`
- filtering/junk: `ZFILTERED_OUT_REASON`, `ZJUNKCONFIDENCE`, `ZJUNKIDENTIFICATIONCATEGORY`, `ZBLOCKEDBYEXTENSION`, `ZBLOCKEDBYEXTENSIONNAME`
- timing: `ZDATE`, `ZDURATION`
- display/location/provider: `ZADDRESS`, `ZLOCATION`, `ZNAME`, `ZSERVICE_PROVIDER`, `ZISO_COUNTRY_CODE`
- stable identifiers: `ZUNIQUE_ID`, `ZCONVERSATIONID`, `ZPARTICIPANTGROUPUUID`, `ZLOCALPARTICIPANTUUID`, `ZOUTGOINGLOCALPARTICIPANTUUID`, `ZREMINDERUUID`
- media/UI: `ZIMAGEURL`, `ZORIGINATINGDEVICENAME`, `ZNEEDEDSCANNOUNCEMENT`

Inference: `ZCALLRECORD` stores both historical recents and enough service/UI state to support FaceTime/telephony recents, missed/read state, voicemail/message adjacency, junk/verification/trust scoring, emergency media, reminders, participant grouping, continuity/origin device, and screen sharing.

## Handles And Joins

`ZHANDLE` includes:

- `ZTYPE`
- `ZNORMALIZEDVALUE`
- `ZVALUE`

No handle values were captured.

`Z_2REMOTEPARTICIPANTHANDLES` joins:

- `Z_2REMOTEPARTICIPANTCALLS`
- `Z_4REMOTEPARTICIPANTHANDLES`

Inference: Phone normalizes remote participants into handle rows and links them through a Core Data join table, rather than embedding all participant identity directly in each call record.

## Emergency Media And Properties

`ZEMERGENCYMEDIAITEM` includes:

- `ZEMERGENCYMEDIATYPE`
- `ZUPLOADEDFORCALL`
- `ZASSETID`

`ZCALLDBPROPERTIES` includes timer fields:

- `ZTIMER_ALL`
- `ZTIMER_INCOMING`
- `ZTIMER_LAST`
- `ZTIMER_LIFETIME`
- `ZTIMER_OUTGOING`

Inference: emergency media and call timers are first-class persisted entities, not just transient app state.

## Index Notes

Observed `ZCALLRECORD` indexes:

- `Z_CallRecord_UNIQUE_unique_id` on `ZUNIQUE_ID`
- date indexes on `ZDATE`
- participant indexes on `ZLOCALPARTICIPANTUUID` and `ZOUTGOINGLOCALPARTICIPANTUUID`
- `ZCALLRECORD_ZINITIATOR_INDEX` on `ZINITIATOR`

Observed `ZHANDLE` indexes:

- `Z_Handle_byNormalizedValueIndex`
- `Z_Handle_byValueIndex`
- `Z_Handle_normalizedValue`
- `Z_Handle_value`

Observed join/media indexes:

- `Z_2REMOTEPARTICIPANTHANDLES_Z_4REMOTEPARTICIPANTHANDLES_INDEX`
- `ZEMERGENCYMEDIAITEM_ZUPLOADEDFORCALL_INDEX`

Inference: the recents store is optimized for date-ordered call lookup, stable unique IDs, participant-local UUID queries, initiator filtering, and handle lookup by raw or normalized value.

## Open Questions

- What enum domains map to `ZCALLTYPE`, `ZCALL_CATEGORY`, `ZDISCONNECTED_CAUSE`, `ZINITIATOR`, `ZORIGINATINGUITYPE`, `ZSCREENSHARINGTYPE`, `ZVERIFICATIONSTATUS`, and `ZHANDLE_TYPE`?
- Which TelephonyUtilities or PhoneAppIntents types map directly onto `ZCALLRECORD` fields?
- Which fields are Phone-only versus shared with FaceTime and LiveCommunicationKit?
- How does `CallHistoryTransactions/transactions.log` map onto this Core Data store without reading personal transaction contents?
