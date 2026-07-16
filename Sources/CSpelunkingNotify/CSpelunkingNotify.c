#include "CSpelunkingNotify.h"

#include <notify.h>

uint32_t SPKNotifyRegisterDispatch(
    const char *name,
    int *outToken,
    dispatch_queue_t queue,
    SPKNotifyCallback callback,
    void *context
) {
    return notify_register_dispatch(name, outToken, queue, ^(int token) {
        callback(token, context);
    });
}

uint32_t SPKNotifyCancel(int token) {
    return notify_cancel(token);
}

uint32_t SPKNotifyStatusOK(void) {
    return NOTIFY_STATUS_OK;
}
