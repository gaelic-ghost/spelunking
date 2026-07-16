#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>

typedef void (*MRMediaRemoteGetOriginFunc)(dispatch_queue_t, void (^)(BOOL, id));
typedef void (*MRMediaRemoteGetObjectsForOriginFunc)(id, dispatch_queue_t, void (^)(NSArray *));
typedef CFStringRef (*MRNowPlayingPlayerPathCopyStringRepresentationFunc)(id);
typedef id (*MRPlaybackQueueRequestCreateFunc)(void);
typedef void (*MRPlaybackQueueRequestSetBoolFunc)(id, bool);
typedef void (*MRPlaybackQueueRequestSetStringFunc)(id, CFStringRef);
typedef CFStringRef (*MRPlaybackQueueRequestCopyDescriptionFunc)(id);
typedef CFStringRef (*MRPlaybackQueueCopyReadableDescriptionFunc)(id);
typedef NSArray *(*MRPlaybackQueueCopyContentItemsFunc)(id);

static id sendObject(id receiver, SEL selector) {
    id (*send)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
    return send(receiver, selector);
}

static id sendObjectWithObject(id receiver, SEL selector, id argument) {
    id (*send)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;
    return send(receiver, selector, argument);
}

static void sendVoidWithObject(id receiver, SEL selector, id argument) {
    void (*send)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
    send(receiver, selector, argument);
}

static void sendVoidWithTwoObjects(id receiver, SEL selector, id firstArgument, id secondArgument) {
    void (*send)(id, SEL, id, id) = (void (*)(id, SEL, id, id))objc_msgSend;
    send(receiver, selector, firstArgument, secondArgument);
}

static void printSelector(id object, NSString *selectorName, NSString *label) {
    SEL selector = NSSelectorFromString(selectorName);

    if (![object respondsToSelector:selector]) {
        printf("%s.%s: selector unavailable\n", label.UTF8String, selectorName.UTF8String);
        return;
    }

    id result = sendObject(object, selector);
    if (result == nil) {
        printf("%s.%s: <nil>\n", label.UTF8String, selectorName.UTF8String);
        return;
    }

    printf("%s.%s: %s\n", label.UTF8String, selectorName.UTF8String, [[result description] UTF8String]);
}

static void printMethodEncoding(id object, NSString *selectorName, NSString *label) {
    SEL selector = NSSelectorFromString(selectorName);
    Method method = class_getInstanceMethod([object class], selector);

    if (method == NULL) {
        printf("%s.%s encoding: unavailable\n", label.UTF8String, selectorName.UTF8String);
        return;
    }

    const char *encoding = method_getTypeEncoding(method);
    printf("%s.%s encoding: %s\n", label.UTF8String, selectorName.UTF8String, encoding != NULL ? encoding : "<null>");
}

static void printRequestMethodEncodings(id object, NSString *label) {
    NSArray<NSString *> *selectors = @[
        @"debugDescription",
        @"playerPath",
        @"supportedCommands",
        @"playbackQueue",
        @"playerProperties",
        @"updatePlaybackQueueIfUninitialized:",
        @"updatePlaybackStateIfUninitialized:",
        @"updateSupportedCommandsIfUninitialized:",
        @"enqueuePlaybackQueueRequest:completion:",
        @"handleSupportedCommandsRequestWithCompletion:",
        @"handlePlaybackStateRequestWithCompletion:",
        @"handlePlayerPropertiesRequestWithCompletion:",
        @"restoreNowPlayingClientState",
        @"subscriptionController"
    ];

    for (NSString *selectorName in selectors) {
        printMethodEncoding(object, selectorName, label);
    }
}

static void requestObjectWithCompletion(id object, NSString *selectorName, NSString *label) {
    SEL selector = NSSelectorFromString(selectorName);

    if (![object respondsToSelector:selector]) {
        printf("%s.%s request: selector unavailable\n", label.UTF8String, selectorName.UTF8String);
        return;
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL called = NO;

    id completion = ^(id result, id error) {
        called = YES;

        if (error != nil) {
            printf("%s.%s completion error: %s\n", label.UTF8String, selectorName.UTF8String, [[error description] UTF8String]);
        }

        if (result == nil) {
            printf("%s.%s completion result: <nil>\n", label.UTF8String, selectorName.UTF8String);
        } else {
            printf(
                "%s.%s completion result: <%s> %s\n",
                label.UTF8String,
                selectorName.UTF8String,
                object_getClassName(result),
                [[result description] UTF8String]
            );
        }

        dispatch_semaphore_signal(semaphore);
    };

    printf("%s.%s request: invoking\n", label.UTF8String, selectorName.UTF8String);
    sendVoidWithObject(object, selector, completion);

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0) {
        printf("%s.%s request: timed out waiting for completion (called=%s)\n", label.UTF8String, selectorName.UTF8String, called ? "true" : "false");
    }
}

static void enqueuePlaybackQueueRequest(
    id requestWrapper,
    id playerPath,
    void *handle,
    NSString *label
) {
    MRPlaybackQueueRequestCreateFunc createDefault = (MRPlaybackQueueRequestCreateFunc)dlsym(handle, "MRPlaybackQueueRequestCreateDefault");
    MRPlaybackQueueRequestSetBoolFunc setIncludeMetadata = (MRPlaybackQueueRequestSetBoolFunc)dlsym(handle, "MRPlaybackQueueRequestSetIncludeMetadata");
    MRPlaybackQueueRequestSetBoolFunc setIncludeInfo = (MRPlaybackQueueRequestSetBoolFunc)dlsym(handle, "MRPlaybackQueueRequestSetIncludeInfo");
    MRPlaybackQueueRequestSetBoolFunc setIncludeLyrics = (MRPlaybackQueueRequestSetBoolFunc)dlsym(handle, "MRPlaybackQueueRequestSetIncludeLyrics");
    MRPlaybackQueueRequestSetBoolFunc setIncludeSections = (MRPlaybackQueueRequestSetBoolFunc)dlsym(handle, "MRPlaybackQueueRequestSetIncludeSections");
    MRPlaybackQueueRequestSetStringFunc setRequestID = (MRPlaybackQueueRequestSetStringFunc)dlsym(handle, "MRPlaybackQueueRequestSetRequestID");
    MRPlaybackQueueRequestSetStringFunc setLabel = (MRPlaybackQueueRequestSetStringFunc)dlsym(handle, "MRPlaybackQueueRequestSetLabel");
    MRPlaybackQueueRequestCopyDescriptionFunc copyRequestDescription = (MRPlaybackQueueRequestCopyDescriptionFunc)dlsym(handle, "MRPlaybackQueueRequestCopyDescription");
    MRPlaybackQueueCopyReadableDescriptionFunc copyQueueDescription = (MRPlaybackQueueCopyReadableDescriptionFunc)dlsym(handle, "MRPlaybackQueueCopyReadableDescription");
    MRPlaybackQueueCopyContentItemsFunc copyContentItems = (MRPlaybackQueueCopyContentItemsFunc)dlsym(handle, "MRPlaybackQueueCopyContentItems");

    if (createDefault == NULL) {
        printf("%s.enqueuePlaybackQueueRequest: missing MRPlaybackQueueRequestCreateDefault\n", label.UTF8String);
        return;
    }

    SEL enqueueSelector = NSSelectorFromString(@"enqueuePlaybackQueueRequest:completion:");
    if (![requestWrapper respondsToSelector:enqueueSelector]) {
        printf("%s.enqueuePlaybackQueueRequest: selector unavailable\n", label.UTF8String);
        return;
    }

    id request = createDefault();
    if (request == nil) {
        printf("%s.enqueuePlaybackQueueRequest: MRPlaybackQueueRequestCreateDefault returned nil\n", label.UTF8String);
        return;
    }

    if ([request respondsToSelector:NSSelectorFromString(@"setPlayerPath:")]) {
        sendVoidWithObject(request, NSSelectorFromString(@"setPlayerPath:"), playerPath);
    }

    if (setRequestID != NULL) {
        setRequestID(request, CFSTR("spelunking.internal-probe.default"));
    }
    if (setLabel != NULL) {
        setLabel(request, CFSTR("Spelunking internal probe"));
    }
    if (setIncludeMetadata != NULL) {
        setIncludeMetadata(request, true);
    }
    if (setIncludeInfo != NULL) {
        setIncludeInfo(request, true);
    }
    if (setIncludeLyrics != NULL) {
        setIncludeLyrics(request, false);
    }
    if (setIncludeSections != NULL) {
        setIncludeSections(request, false);
    }

    if (copyRequestDescription != NULL) {
        CFStringRef requestDescription = copyRequestDescription(request);
        printf("%s.enqueuePlaybackQueueRequest request: %s\n", label.UTF8String, requestDescription != NULL ? [(__bridge NSString *)requestDescription UTF8String] : [[request description] UTF8String]);
        if (requestDescription != NULL) {
            CFRelease(requestDescription);
        }
    } else {
        printf("%s.enqueuePlaybackQueueRequest request: %s\n", label.UTF8String, [[request description] UTF8String]);
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL called = NO;

    id completion = ^(id queue, id error) {
        called = YES;

        if (error != nil) {
            printf("%s.enqueuePlaybackQueueRequest completion error: %s\n", label.UTF8String, [[error description] UTF8String]);
        }

        if (queue == nil) {
            printf("%s.enqueuePlaybackQueueRequest completion queue: <nil>\n", label.UTF8String);
        } else {
            printf("%s.enqueuePlaybackQueueRequest completion queue: <%s> %s\n", label.UTF8String, object_getClassName(queue), [[queue description] UTF8String]);

            if (copyQueueDescription != NULL) {
                CFStringRef queueDescription = copyQueueDescription(queue);
                printf("%s.enqueuePlaybackQueueRequest readable queue: %s\n", label.UTF8String, queueDescription != NULL ? [(__bridge NSString *)queueDescription UTF8String] : "<nil>");
                if (queueDescription != NULL) {
                    CFRelease(queueDescription);
                }
            }

            if (copyContentItems != NULL) {
                NSArray *items = copyContentItems(queue);
                printf("%s.enqueuePlaybackQueueRequest content items: %lu item(s)\n", label.UTF8String, (unsigned long)items.count);
            }
        }

        dispatch_semaphore_signal(semaphore);
    };

    printf("%s.enqueuePlaybackQueueRequest: invoking\n", label.UTF8String);
    sendVoidWithTwoObjects(requestWrapper, enqueueSelector, request, completion);

    if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0) {
        printf("%s.enqueuePlaybackQueueRequest: timed out waiting for completion (called=%s)\n", label.UTF8String, called ? "true" : "false");
    }

    printSelector(requestWrapper, @"playbackQueue", label);
}

static void inspectWrapper(NSString *className, id playerPath, void *handle) {
    Class wrapperClass = NSClassFromString(className);
    if (wrapperClass == Nil) {
        printf("%s: class unavailable\n", className.UTF8String);
        return;
    }

    SEL initializer = NSSelectorFromString(@"initWithPlayerPath:");
    id allocated = sendObject((id)wrapperClass, @selector(alloc));
    id wrapper = sendObjectWithObject(allocated, initializer, playerPath);

    if (wrapper == nil) {
        printf("%s: initWithPlayerPath returned nil\n", className.UTF8String);
        return;
    }

    printf("%s: %s\n", className.UTF8String, [[wrapper description] UTF8String]);

    printSelector(wrapper, @"debugDescription", className);
    printSelector(wrapper, @"playerPath", className);
    printSelector(wrapper, @"clientCallbacks", className);
    printSelector(wrapper, @"supportedCommands", className);
    printSelector(wrapper, @"playbackQueue", className);
    printSelector(wrapper, @"playerProperties", className);
    printRequestMethodEncodings(wrapper, className);

    if ([className isEqualToString:@"MRNowPlayingPlayerClientRequests"]) {
        requestObjectWithCompletion(wrapper, @"handleSupportedCommandsRequestWithCompletion:", className);
        printSelector(wrapper, @"supportedCommands", className);
        requestObjectWithCompletion(wrapper, @"handlePlayerPropertiesRequestWithCompletion:", className);
        printSelector(wrapper, @"playerProperties", className);
        enqueuePlaybackQueueRequest(wrapper, playerPath, handle, className);
    }
}

int main(void) {
    @autoreleasepool {
        void *handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote", RTLD_NOW);
        if (handle == NULL) {
            fprintf(stderr, "mr-internal-probe: could not load MediaRemote.framework: %s\n", dlerror());
            return 1;
        }

        MRMediaRemoteGetOriginFunc getActiveOrigin = (MRMediaRemoteGetOriginFunc)dlsym(handle, "MRMediaRemoteGetActiveOrigin");
        MRMediaRemoteGetObjectsForOriginFunc getActivePlayerPaths = (MRMediaRemoteGetObjectsForOriginFunc)dlsym(handle, "MRMediaRemoteGetActivePlayerPathsForOrigin");
        MRNowPlayingPlayerPathCopyStringRepresentationFunc copyPathString = (MRNowPlayingPlayerPathCopyStringRepresentationFunc)dlsym(handle, "MRNowPlayingPlayerPathCopyStringRepresentation");

        if (getActiveOrigin == NULL || getActivePlayerPaths == NULL || copyPathString == NULL) {
            fprintf(stderr, "mr-internal-probe: missing required MediaRemote symbols for active player-path inspection\n");
            return 1;
        }

        dispatch_queue_t queue = dispatch_queue_create("com.galewilliams.spelunking.mediaremote.internal-probe", DISPATCH_QUEUE_SERIAL);
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block id activeOrigin = nil;

        getActiveOrigin(queue, ^(BOOL success, id origin) {
            printf("Active origin success=%s object=%s\n", success ? "true" : "false", [[origin description] UTF8String]);
            activeOrigin = origin;
            dispatch_semaphore_signal(semaphore);
        });

        if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0 || activeOrigin == nil) {
            fprintf(stderr, "mr-internal-probe: timed out waiting for active origin\n");
            return 2;
        }

        dispatch_semaphore_t pathsSemaphore = dispatch_semaphore_create(0);
        __block NSArray *playerPaths = nil;

        getActivePlayerPaths(activeOrigin, queue, ^(NSArray *paths) {
            playerPaths = paths;
            dispatch_semaphore_signal(pathsSemaphore);
        });

        if (dispatch_semaphore_wait(pathsSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) != 0) {
            fprintf(stderr, "mr-internal-probe: timed out waiting for active player paths\n");
            return 3;
        }

        printf("Active player paths: %lu item(s)\n", (unsigned long)playerPaths.count);

        for (id playerPath in playerPaths) {
            CFStringRef pathString = copyPathString(playerPath);
            printf("Player path: %s\n", pathString != NULL ? [(__bridge NSString *)pathString UTF8String] : [[playerPath description] UTF8String]);
            if (pathString != NULL) {
                CFRelease(pathString);
            }

            inspectWrapper(@"MRNowPlayingPlayerClient", playerPath, handle);
            inspectWrapper(@"MRNowPlayingPlayerClientRequests", playerPath, handle);
        }

        return 0;
    }
}
