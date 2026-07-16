#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

typedef id (*MRObjectCreateFunc)(void);
typedef id (*MRObjectWithStringFunc)(CFStringRef);
typedef CFArrayRef (*MRCopyArrayWithObjectFunc)(id);
typedef CFStringRef (*MRCopyStringWithObjectFunc)(id);
typedef int32_t (*MRInt32WithObjectFunc)(id);
typedef uint32_t (*MRUInt32WithObjectFunc)(id);
typedef double (*MRDoubleWithObjectFunc)(id);
typedef Boolean (*MRBoolWithObjectFunc)(id);

static BOOL shouldPrintObjectDescriptions = NO;
static BOOL shouldProbeOutputContexts = NO;
static BOOL shouldProbeOutputDevices = NO;

static void *requireSymbol(void *handle, const char *name) {
    void *symbol = dlsym(handle, name);
    if (symbol == NULL) {
        fprintf(stderr, "mr-route-probe: missing required MediaRemote symbol %s\n", name);
        exit(2);
    }
    return symbol;
}

static void printStringValue(NSString *label, CFStringRef value) {
    if (value == NULL) {
        printf("%s: <nil>\n", label.UTF8String);
        return;
    }

    printf("%s: %s\n", label.UTF8String, [(__bridge NSString *)value UTF8String]);
}

static void printOptionalStringGetter(void *handle, const char *symbolName, id object, NSString *label) {
    MRCopyStringWithObjectFunc getter = (MRCopyStringWithObjectFunc)dlsym(handle, symbolName);
    if (getter == NULL) {
        printf("%s: missing symbol %s\n", label.UTF8String, symbolName);
        return;
    }

    CFStringRef value = getter(object);
    printStringValue(label, value);
}

static void describeOutputDevice(void *handle, id device, NSUInteger index, NSString *prefix) {
    NSString *base = [NSString stringWithFormat:@"%@ outputDevice[%lu]", prefix, (unsigned long)index];
    printf("%s: <%s>\n", base.UTF8String, object_getClassName(device));

    if (shouldPrintObjectDescriptions) {
        printf("%s description: %s\n", base.UTF8String, [[device description] UTF8String]);
    }

    printOptionalStringGetter(handle, "MRAVOutputDeviceGetName", device, [base stringByAppendingString:@" name"]);
    printOptionalStringGetter(handle, "MRAVOutputDeviceGetUniqueIdentifier", device, [base stringByAppendingString:@" uid"]);
    printOptionalStringGetter(handle, "MRAVOutputDeviceGetModelID", device, [base stringByAppendingString:@" modelID"]);

    MRInt32WithObjectFunc getType = (MRInt32WithObjectFunc)dlsym(handle, "MRAVOutputDeviceGetType");
    if (getType != NULL) {
        printf("%s type: %d\n", base.UTF8String, getType(device));
    }

    MRInt32WithObjectFunc getSubtype = (MRInt32WithObjectFunc)dlsym(handle, "MRAVOutputDeviceGetSubtype");
    if (getSubtype != NULL) {
        printf("%s subtype: %d\n", base.UTF8String, getSubtype(device));
    }

    MRDoubleWithObjectFunc getBatteryLevel = (MRDoubleWithObjectFunc)dlsym(handle, "MRAVOutputDeviceGetBatteryLevel");
    if (getBatteryLevel != NULL) {
        printf("%s batteryLevel: %.3f\n", base.UTF8String, getBatteryLevel(device));
    }

    struct {
        const char *symbol;
        const char *label;
    } boolGetters[] = {
        { "MRAVOutputDeviceIsLocalDevice", "isLocal" },
        { "MRAVOutputDeviceIsGroupLeader", "isGroupLeader" },
        { "MRAVOutputDeviceIsGroupable", "isGroupable" },
        { "MRAVOutputDeviceIsRemoteControllable", "isRemoteControllable" },
        { "MRAVOutputDeviceIsVolumeControlAvailable", "isVolumeControlAvailable" },
        { "MRAVOutputDeviceSupportsExternalScreen", "supportsExternalScreen" },
        { "MRAVOutputDeviceSupportsHAP", "supportsHAP" },
        { "MRAVOutputDeviceSupportsHeadTrackedSpatialAudio", "supportsHeadTrackedSpatialAudio" },
        { "MRAVOutputDeviceSupportsRapport", "supportsRapport" },
    };

    for (size_t i = 0; i < sizeof(boolGetters) / sizeof(boolGetters[0]); i++) {
        MRBoolWithObjectFunc getter = (MRBoolWithObjectFunc)dlsym(handle, boolGetters[i].symbol);
        if (getter != NULL) {
            printf("%s %s: %s\n", base.UTF8String, boolGetters[i].label, getter(device) ? "true" : "false");
        }
    }
}

static void describeOutputDevices(void *handle, CFArrayRef devices, NSString *prefix) {
    if (devices == NULL) {
        printf("%s output devices: <nil>\n", prefix.UTF8String);
        return;
    }

    NSUInteger count = CFArrayGetCount(devices);
    printf("%s output devices: %lu item(s)\n", prefix.UTF8String, (unsigned long)count);

    for (NSUInteger index = 0; index < count; index++) {
        id device = CFArrayGetValueAtIndex(devices, index);
        if (device == nil) {
            printf("%s outputDevice[%lu]: <nil>\n", prefix.UTF8String, (unsigned long)index);
            continue;
        }

        describeOutputDevice(handle, device, index, prefix);
    }
}

static void describeEndpoint(void *handle, id endpoint, NSString *label) {
    if (endpoint == nil) {
        printf("%s endpoint: <nil>\n", label.UTF8String);
        return;
    }

    printf("%s endpoint: <%s>\n", label.UTF8String, object_getClassName(endpoint));
    if (shouldPrintObjectDescriptions) {
        printf("%s endpoint description: %s\n", label.UTF8String, [[endpoint description] UTF8String]);
    }
    printOptionalStringGetter(handle, "MRAVEndpointGetLocalizedName", endpoint, [label stringByAppendingString:@" localizedName"]);
    printOptionalStringGetter(handle, "MRAVEndpointGetUniqueIdentifier", endpoint, [label stringByAppendingString:@" uid"]);

    if (shouldProbeOutputDevices) {
        MRCopyArrayWithObjectFunc copyOutputDevices = (MRCopyArrayWithObjectFunc)dlsym(handle, "MRAVEndpointCopyOutputDevices");
        if (copyOutputDevices != NULL) {
            CFArrayRef devices = copyOutputDevices(endpoint);
            describeOutputDevices(handle, devices, label);
            if (devices != NULL) {
                CFRelease(devices);
            }
        }
    } else {
        printf("%s output devices: skipped; pass --output-devices to copy endpoint output devices\n", label.UTF8String);
    }
}

static void describeOutputContext(void *handle, id context, NSString *label) {
    if (context == nil) {
        printf("%s output context: <nil>\n", label.UTF8String);
        return;
    }

    printf("%s output context: <%s>\n", label.UTF8String, object_getClassName(context));
    if (shouldPrintObjectDescriptions) {
        printf("%s output context description: %s\n", label.UTF8String, [[context description] UTF8String]);
    }
    printOptionalStringGetter(handle, "MRAVOutputContextGetUniqueIdentifier", context, [label stringByAppendingString:@" uid"]);

    MRUInt32WithObjectFunc getType = (MRUInt32WithObjectFunc)dlsym(handle, "MRAVOutputContextGetType");
    if (getType != NULL) {
        printf("%s type: %u\n", label.UTF8String, getType(context));
    }

    MRCopyArrayWithObjectFunc copyOutputDevices = (MRCopyArrayWithObjectFunc)dlsym(handle, "MRAVOutputContextCopyOutputDevices");
    if (copyOutputDevices != NULL) {
        CFArrayRef devices = copyOutputDevices(context);
        describeOutputDevices(handle, devices, label);
        if (devices != NULL) {
            CFRelease(devices);
        }
    }
}

int main(void) {
    @autoreleasepool {
        setvbuf(stdout, NULL, _IOLBF, 0);
        setvbuf(stderr, NULL, _IOLBF, 0);

        NSArray<NSString *> *arguments = [[NSProcessInfo processInfo] arguments];
        shouldPrintObjectDescriptions = [arguments containsObject:@"--describe"];
        shouldProbeOutputContexts = [arguments containsObject:@"--contexts"];
        shouldProbeOutputDevices = [arguments containsObject:@"--output-devices"];

        void *handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote", RTLD_NOW);
        if (handle == NULL) {
            fprintf(stderr, "mr-route-probe: could not load MediaRemote.framework: %s\n", dlerror());
            return 1;
        }

        printf("MediaRemote read-only route/output-device probe\n");

        MRObjectWithStringFunc getLocalEndpoint = (MRObjectWithStringFunc)requireSymbol(handle, "MRAVEndpointGetLocalEndpoint");
        id localEndpoint = getLocalEndpoint(NULL);
        describeEndpoint(handle, localEndpoint, @"Local endpoint");

        if (shouldProbeOutputContexts) {
            MRObjectCreateFunc getSharedSystemAudioContext = (MRObjectCreateFunc)dlsym(handle, "MRAVOutputContextGetSharedSystemAudioContext");
            if (getSharedSystemAudioContext != NULL) {
                describeOutputContext(handle, getSharedSystemAudioContext(), @"Shared system audio context");
            }

            MRObjectCreateFunc getSharedSystemScreenContext = (MRObjectCreateFunc)dlsym(handle, "MRAVOutputContextGetSharedSystemScreenContext");
            if (getSharedSystemScreenContext != NULL) {
                describeOutputContext(handle, getSharedSystemScreenContext(), @"Shared system screen context");
            }
        } else {
            printf("Output context probe: skipped; pass --contexts to query shared output contexts\n");
        }

        return 0;
    }
}
