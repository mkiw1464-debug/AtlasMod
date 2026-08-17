#import <Foundation/Foundation.h>
#import <substrate.h>
#import <sys/utsname.h>

// ─── UDID / identifierForVendor Spoof ───────────────────────────
static NSUUID* spoofedUUID = nil;

static NSUUID* (*orig_identifierForVendor)(id, SEL);
static NSUUID* hook_identifierForVendor(id self, SEL _cmd) {
    if (!spoofedUUID) {
        // Generate sekali, simpan — konsisten setiap session
        NSUserDefaults* d = [NSUserDefaults standardUserDefaults];
        NSString* saved = [d stringForKey:@"atlas_uuid"];
        if (saved) {
            spoofedUUID = [[NSUUID alloc] initWithUUIDString:saved];
        } else {
            spoofedUUID = [NSUUID UUID];
            [d setObject:spoofedUUID.UUIDString forKey:@"atlas_uuid"];
            [d synchronize];
        }
    }
    return spoofedUUID;
}

// ─── Device Model Spoof ──────────────────────────────────────────
// Buat FF ingat kau guna iPhone biasa, bukan device yang flagged
static int (*orig_sysctlbyname)(const char*, void*, size_t*, void*, size_t);
static int hook_sysctlbyname(const char* name, void* oldp,
                              size_t* oldlenp, void* newp, size_t newlen) {
    int r = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    if (r == 0 && oldp) {
        if (strcmp(name, "hw.machine") == 0) {
            // Spoof ke iPhone13,2 (iPhone 12) — common model
            const char* fake = "iPhone13,2";
            strlcpy((char*)oldp, fake, *oldlenp);
        }
        if (strcmp(name, "hw.model") == 0) {
            const char* fake = "D53gAP";
            strlcpy((char*)oldp, fake, *oldlenp);
        }
    }
    return r;
}

// ─── MAC Address Spoof ───────────────────────────────────────────
// FF kadang check MAC via private API
static NSString* (*orig_wifiAddress)(id, SEL);
static NSString* hook_wifiAddress(id self, SEL _cmd) {
    return @"02:00:00:00:00:00"; // Standard "unavailable" MAC
}

void HardwareSpoof_Init() {
    // identifierForVendor
    MSHookMessageEx([UIDevice class],
        @selector(identifierForVendor),
        (IMP)hook_identifierForVendor,
        (IMP*)&orig_identifierForVendor);
    
    // sysctlbyname untuk model
    MSHookFunction((void*)sysctlbyname,
        (void*)hook_sysctlbyname,
        (void**)&orig_sysctlbyname);
    
    // WiFi address via private class
    Class netInfo = NSClassFromString(@"UIDevice");
    if (netInfo) {
        MSHookMessageEx(netInfo,
            NSSelectorFromString(@"_wifiAddress"),
            (IMP)hook_wifiAddress,
            (IMP*)&orig_wifiAddress);
    }
}
