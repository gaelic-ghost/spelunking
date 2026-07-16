#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static NSArray<NSString *> *defaultClassNames(void) {
    return @[
        @"MRNowPlayingClient",
        @"MRNowPlayingClientRequests",
        @"MRNowPlayingOriginClient",
        @"MRNowPlayingOriginClientManager",
        @"MRNowPlayingPlayerClient",
        @"MRNowPlayingPlayerClientRequests",
        @"MRNowPlayingController",
        @"MRNowPlayingControllerConfiguration",
        @"MRNowPlayingPlayerResponse",
        @"MRNowPlayingState",
        @"MRPlaybackQueueRequest",
        @"MRPlaybackQueue",
        @"MRPlaybackQueueClient",
        @"MRPlayerPath",
        @"MRPlayer",
        @"MROrigin",
        @"MRClient",
        @"MRXPCConnection"
    ];
}

static NSString *safeString(const char *value) {
    return value == NULL ? @"<null>" : [NSString stringWithUTF8String:value];
}

static void printProtocols(Class cls) {
    unsigned int count = 0;
    Protocol *__unsafe_unretained *protocols = class_copyProtocolList(cls, &count);

    if (count == 0) {
        printf("  protocols: none\n");
    } else {
        printf("  protocols:\n");
        for (unsigned int index = 0; index < count; index++) {
            printf("    %s\n", protocol_getName(protocols[index]));
        }
    }

    free(protocols);
}

static void printProperties(Class cls) {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &count);

    if (count == 0) {
        printf("  properties: none\n");
    } else {
        printf("  properties:\n");
        for (unsigned int index = 0; index < count; index++) {
            printf(
                "    @property %s %s\n",
                property_getAttributes(properties[index]),
                property_getName(properties[index])
            );
        }
    }

    free(properties);
}

static void printIvars(Class cls) {
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(cls, &count);

    if (count == 0) {
        printf("  ivars: none\n");
    } else {
        printf("  ivars:\n");
        for (unsigned int index = 0; index < count; index++) {
            printf(
                "    %s %s offset=%td\n",
                safeString(ivar_getTypeEncoding(ivars[index])).UTF8String,
                ivar_getName(ivars[index]),
                ivar_getOffset(ivars[index])
            );
        }
    }

    free(ivars);
}

static void printMethods(Class cls, BOOL classMethods) {
    Class target = classMethods ? object_getClass((id)cls) : cls;
    unsigned int count = 0;
    Method *methods = class_copyMethodList(target, &count);

    if (count == 0) {
        printf("  %s methods: none\n", classMethods ? "class" : "instance");
    } else {
        printf("  %s methods:\n", classMethods ? "class" : "instance");
        for (unsigned int index = 0; index < count; index++) {
            SEL selector = method_getName(methods[index]);
            const char *encoding = method_getTypeEncoding(methods[index]);
            printf("    %c[%s %s] %s\n", classMethods ? '+' : '-', class_getName(cls), sel_getName(selector), safeString(encoding).UTF8String);
        }
    }

    free(methods);
}

static void printClassInterface(NSString *className) {
    Class cls = NSClassFromString(className);

    if (cls == Nil) {
        printf("\n## %s\n", className.UTF8String);
        printf("  unavailable\n");
        return;
    }

    Class superclass = class_getSuperclass(cls);
    printf("\n## %s : %s\n", class_getName(cls), superclass != Nil ? class_getName(superclass) : "<root>");
    printProtocols(cls);
    printProperties(cls);
    printIvars(cls);
    printMethods(cls, YES);
    printMethods(cls, NO);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        void *handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote", RTLD_NOW);
        if (handle == NULL) {
            fprintf(stderr, "mr-interface-probe: could not load MediaRemote.framework: %s\n", dlerror());
            return 1;
        }

        NSMutableArray<NSString *> *classNames = [NSMutableArray array];
        for (int index = 1; index < argc; index++) {
            [classNames addObject:[NSString stringWithUTF8String:argv[index]]];
        }

        if (classNames.count == 0) {
            [classNames addObjectsFromArray:defaultClassNames()];
        }

        printf("# MediaRemote Objective-C Runtime Interfaces\n");
        printf("\nclasses: %lu\n", (unsigned long)classNames.count);

        for (NSString *className in classNames) {
            printClassInterface(className);
        }

        dlclose(handle);
        return 0;
    }
}
