#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach.h>

// Wipe dylib name dari image list
// Garena scan _dyld_get_image_name untuk detect inject

static const char* (*orig_dyld_get_image_name)(uint32_t);
static const char* hook_dyld_get_image_name(uint32_t idx) {
    const char* name = orig_dyld_get_image_name(idx);
    if (!name) return name;
    
    // Sembunyikan AtlasMod dari image list
    if (strstr(name, "AtlasMod") ||
        strstr(name, "atlas") ||
        strstr(name, "substrate") ||
        strstr(name, "CydiaSubstrate")) {
        return "/usr/lib/system/libsystem_c.dylib"; // redirect ke lib biasa
    }
    return name;
}

// Override image count — buang count untuk hidden libs
static uint32_t (*orig_dyld_image_count)(void);
static uint32_t hook_dyld_image_count(void) {
    uint32_t real = orig_dyld_image_count();
    // Tolak hidden image count
    uint32_t hidden = 0;
    for (uint32_t i = 0; i < real; i++) {
        const char* n = orig_dyld_get_image_name(i);
        if (n && (strstr(n,"AtlasMod") || strstr(n,"substrate")))
            hidden++;
    }
    return real - hidden;
}

// Wipe dylib header dari memory scan
static void wipeDylibTrace(const char* targetLib) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strstr(_dyld_get_image_name(i), targetLib)) {
            // Get header
            const struct mach_header_64* hdr =
                (const struct mach_header_64*)_dyld_get_image_header(i);
            
            // Overwrite magic bytes — buat scanner fail identify
            vm_protect(mach_task_self(), (vm_address_t)hdr,
                sizeof(uint32_t), false,
                VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
            
            // Tukar magic ke invalid value
            uint32_t fake_magic = 0xDEADC0DE;
            memcpy((void*)hdr, &fake_magic, sizeof(uint32_t));
            
            vm_protect(mach_task_self(), (vm_address_t)hdr,
                sizeof(uint32_t), false,
                VM_PROT_READ | VM_PROT_EXECUTE);
            break;
        }
    }
}

void MemoryWiper_Init() {
    // Hook dyld functions
    MSHookFunction((void*)_dyld_get_image_name,
        (void*)hook_dyld_get_image_name,
        (void**)&orig_dyld_get_image_name);
    
    MSHookFunction((void*)_dyld_image_count,
        (void*)hook_dyld_image_count,
        (void**)&orig_dyld_image_count);
    
    // Wipe trace selepas 1 saat (bagi inject settle dulu)
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.0*NSEC_PER_SEC)),
        dispatch_get_global_queue(0,0), ^{
            wipeDylibTrace("AtlasMod");
            wipeDylibTrace("CydiaSubstrate");
            wipeDylibTrace("MobileSubstrate");
    });
}
