# Messages Storage

## Scope

This page documents the local Messages `chat.db` schema observed on macOS 26.5.2. It is schema-only research. No message rows, text, handles, attachment filenames, row counts, or account values were captured.

## Evidence

Raw capture:

- `research/Messages/storage/chatdb-schema-macos-26.5.2.txt`

Capture method:

- `sqlite3 "$HOME/Library/Messages/chat.db" ".tables"`
- `pragma_table_info` for every table
- `sqlite_schema` entries for table, index, trigger, and view definitions

## Core Tables

| Table | Role |
| --- | --- |
| `message` | Main message records: content fields, delivery/read/send state, reactions/replies/threading, CloudKit sync, scheduling, satellite/off-grid flags, indexing, and alerting state. |
| `chat` | Conversation records: style/state, service/account identity, group identifiers, display name, archive/filter/recovery/delete state, CloudKit sync, and pending review/blackhole flags. |
| `handle` | Participant/address identity records: canonical and uncanonicalized IDs, service/country, and person-centric identifiers. |
| `attachment` | Attachment records: transfer state, file path field, UTI/MIME metadata, sticker fields, attribution, CloudKit sync, communication-safety sensitivity, and preview generation state. |
| `chat_handle_join` | Conversation-to-handle membership. |
| `chat_message_join` | Conversation-to-message membership plus cached message date and index state. |
| `message_attachment_join` | Message-to-attachment membership. |
| `chat_recoverable_message_join` and `recoverable_message_part` | Recently deleted or recoverable message lifecycle. |

## Message Columns

High-signal `message` columns from the raw schema:

- identity/content: `guid`, `text`, `subject`, `attributedBody`, `payload_data`, `message_summary_info`
- service/account: `service`, `account`, `account_guid`, `country`, `destination_caller_id`
- participant joins: `handle_id`, `other_handle`, `cache_roomnames`
- delivery/read/send state: `error`, `date`, `date_read`, `date_delivered`, `is_delivered`, `is_finished`, `is_read`, `is_sent`, `is_from_me`
- message classification: `type`, `item_type`, `is_empty`, `is_system_message`, `is_service_message`, `is_audio_message`, `is_spam`
- attachment/cache: `cache_has_attachments`, `is_played`, `date_played`, `was_data_detected`, `was_deduplicated`
- group/reaction/reply: `group_title`, `group_action_type`, `associated_message_guid`, `associated_message_type`, `associated_message_range_location`, `associated_message_range_length`, `associated_message_emoji`, `reply_to_guid`, `thread_originator_guid`, `thread_originator_part`
- balloon/plugin/expressive send: `balloon_bundle_id`, `expressive_send_style_id`, `time_expressive_send_played`
- CloudKit/sync: `ck_sync_state`, `ck_record_id`, `ck_record_change_tag`, `ck_chat_id`, `syndication_ranges`, `synced_syndication_ranges`
- edit/delete/recover lifecycle: `date_retracted`, `date_edited`, `date_recovered`, `is_archive`
- safety/off-grid/satellite: `was_detonated`, `is_stewie`, `is_sos`, `is_critical`, `bia_reference_id`, `is_pending_satellite_send`, `sent_or_received_off_grid`
- scheduling/notification/indexing: `schedule_type`, `schedule_state`, `was_delivered_quietly`, `did_notify_recipient`, `is_time_sensitive`, `index_state`

Inference: the `message` table is not just transcript text. It is the local state machine for delivery, read status, reactions, edit/retraction, scheduled send, satellite/off-grid operation, CloudKit sync, indexing, and notification behavior.

## Chat Columns

High-signal `chat` columns:

- identity/state: `guid`, `style`, `state`, `chat_identifier`, `room_name`, `group_id`, `original_group_id`
- account/service: `account_id`, `account_login`, `service_name`, `last_addressed_handle`, `last_addressed_sim_id`
- UI/lifecycle: `display_name`, `is_archived`, `is_filtered`, `is_blackholed`, `is_pending_review`, `is_recovered`
- sync/delete: `server_change_token`, `ck_sync_state`, `cloudkit_record_id`, `is_deleting_incoming_messages`
- syndication/read: `last_read_message_timestamp`, `syndication_date`, `syndication_type`
- opaque state: `properties`

Inference: `chat` stores enough state to support filtering, archive/recovery, CloudKit sync, group identity migration, pending review, and deletion workflows.

## Attachments And Handles

`attachment` includes:

- identifiers and transfer metadata: `guid`, `created_date`, `start_date`, `transfer_state`, `transfer_name`, `total_bytes`
- file/type metadata: `filename`, `uti`, `mime_type`
- sticker/attribution/safety: `is_sticker`, `sticker_user_info`, `attribution_info`, `is_commsafety_sensitive`
- CloudKit/preview: `ck_sync_state`, `ck_server_change_token_blob`, `ck_record_id`, `preview_generation_state`

`handle` includes:

- `id`
- `country`
- `service`
- `uncanonicalized_id`
- `person_centric_id`

No handle values were captured.

## Queued Work Tables

`message_processing_task` includes:

- `guid`
- `task_flags`
- `reasons`

`persistent_tasks` includes:

- `guid`
- `flag_group`
- `flag`
- `flag_priority`
- `lane`
- `reason`
- `reason_priority`
- `user_info`
- `retry_count`

Indexes on `persistent_tasks` sort by lane, flag group, priority, reason priority, and retry count. Inference: Messages persists background work in prioritized lanes, but this pass does not decode the integer flag/reason domains.

## Index And Trigger Notes

Important observed indexes:

- unread/read views: `message_idx_unread_finished_not_from_me_newest_first`, `message_idx_is_read`, `message_idx_isRead_isFromMe_itemType`
- send failure: `message_idx_failed`, `message_idx_is_sent_is_from_me_error`
- scheduling: `message_idx_composite_scheduled_message`, `message_idx_is_scheduled_message`, `message_idx_schedule_state`
- satellite/off-grid and alerting: `message_idx_is_pending_satellite_message`, `message_idx_is_time_sensitive`
- indexing lifecycle: `message_idx_pending_indexing_messages`, `message_idx_invalid_index_state`, `message_idx_indexed_messages_guid`
- delivery edge case: `message_idx_undelivered_one_to_one_imessage`
- sync: `message_idx_ck_sync_state_service`, `attachment_idx_ck_sync_state`, `chat_idx_ck_sync_state`
- chat filters: `chat_idx_is_archived`, `chat_idx_is_filtered`, `chat_idx_is_archived_is_filtered`

Important observed triggers:

- attachment deletion calls attachment-path cleanup helpers and records CloudKit deleted attachments.
- chat deletion removes join rows, updates sync-deleted chat tables, and deletes chat background data.
- chat/message join changes update `message.cache_roomnames`, delete orphaned messages, maintain chat-service rows, and propagate index metrics.
- message deletion records deleted messages, records CloudKit deleted message IDs, deletes orphaned handles, calls plugin cleanup when `balloon_bundle_id` is present, and updates associated-message state.
- message date changes propagate into `chat_message_join.message_date`.
- message attachment joins update `message.cache_has_attachments` and delete orphaned attachments.

Inference: `chat.db` uses SQLite triggers as part of the local lifecycle machinery, not only as passive storage. Deletion, CloudKit sync bookkeeping, cached room names, orphan cleanup, plugin cleanup, and indexing metrics are enforced in-schema.

## Open Questions

- What enum domains map to `message.item_type`, `associated_message_type`, `message_action_type`, `schedule_type`, `schedule_state`, `ck_sync_state`, and `index_state`?
- What bit domains map to `message_processing_task.task_flags` and `persistent_tasks.flag` / `reason` / `lane`?
- Which triggers are called directly by SQLite custom functions inside IMDPersistence?
- Which schema elements are stable across macOS 26.5.2 and the macOS 27 SDK-era implementation?
