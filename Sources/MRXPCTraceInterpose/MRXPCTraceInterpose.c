#include <dispatch/dispatch.h>
#include <stdint.h>
#include <stdio.h>
#include <xpc/xpc.h>

typedef void (^xpc_reply_handler_t)(xpc_object_t);

static void log_mediaremote_message(const char *surface, xpc_object_t message) {
    if (message == NULL || xpc_get_type(message) != XPC_TYPE_DICTIONARY) {
        return;
    }

    uint64_t message_type = xpc_dictionary_get_uint64(message, "MRXPC_MESSAGE_ID_KEY");
    if (message_type == 0) {
        return;
    }

    uint64_t domain = (message_type >> 48) & 0xffff;
    uint64_t ordinal = message_type & 0xffffffffffff;

    fprintf(
        stderr,
        "MRXPC interpose: %s messageType=0x%016llX domain=0x%llX ordinal=0x%llX\n",
        surface,
        (unsigned long long)message_type,
        (unsigned long long)domain,
        (unsigned long long)ordinal
    );
    fflush(stderr);
}

void traced_xpc_connection_send_message(xpc_connection_t connection, xpc_object_t message);
void traced_xpc_connection_send_message_with_reply(
    xpc_connection_t connection,
    xpc_object_t message,
    dispatch_queue_t replyq,
    xpc_reply_handler_t handler
);
xpc_object_t traced_xpc_connection_send_message_with_reply_sync(xpc_connection_t connection, xpc_object_t message);

void traced_xpc_connection_send_message(xpc_connection_t connection, xpc_object_t message) {
    log_mediaremote_message("xpc_connection_send_message", message);
    xpc_connection_send_message(connection, message);
}

void traced_xpc_connection_send_message_with_reply(
    xpc_connection_t connection,
    xpc_object_t message,
    dispatch_queue_t replyq,
    xpc_reply_handler_t handler
) {
    log_mediaremote_message("xpc_connection_send_message_with_reply", message);
    xpc_connection_send_message_with_reply(connection, message, replyq, handler);
}

xpc_object_t traced_xpc_connection_send_message_with_reply_sync(xpc_connection_t connection, xpc_object_t message) {
    log_mediaremote_message("xpc_connection_send_message_with_reply_sync", message);
    return xpc_connection_send_message_with_reply_sync(connection, message);
}

__attribute__((used)) static struct {
    const void *replacement;
    const void *replacee;
} interposers[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)traced_xpc_connection_send_message, (const void *)xpc_connection_send_message },
    { (const void *)traced_xpc_connection_send_message_with_reply, (const void *)xpc_connection_send_message_with_reply },
    { (const void *)traced_xpc_connection_send_message_with_reply_sync, (const void *)xpc_connection_send_message_with_reply_sync },
};
