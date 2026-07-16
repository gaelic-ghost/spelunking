#ifndef CSpelunkingNotify_h
#define CSpelunkingNotify_h

#include <dispatch/dispatch.h>
#include <stdint.h>

typedef void (*SPKNotifyCallback)(int token, void *context);

uint32_t SPKNotifyRegisterDispatch(
    const char *name,
    int *outToken,
    dispatch_queue_t queue,
    SPKNotifyCallback callback,
    void *context
);

uint32_t SPKNotifyCancel(int token);
uint32_t SPKNotifyStatusOK(void);

#endif
