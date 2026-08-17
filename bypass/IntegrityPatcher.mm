#import <Foundation/Foundation.h>
#import <mach/mach.h>

// Patch SEMUA integrity check function dalam FF binary OB54
// Setiap function return 1 (valid/clean)

typedef struct {
    uintptr_t offset;
    const char* name;
} PatchTarget;

// OB54 integrity check offsets — update tiap patch guna IDA
static const PatchTarget PATCHES[] = {
    {0x03F2A100, "MemoryIntegrityCheck"},
    {0x04A33200, "SignatureVerify"},
    {0x03B11400, "DylibScanCheck"},
    {0x04C22100, "AntiDebugCheck"},
    {0x03D44500, "RootCheck"},
    {0x04E55600, "TweakDetector"},
    {0x03F66700, "HookDetector"},
    {0x04122800, "TimingCheck"},
    {0x03C77900, "EnvironmentCheck"},
};

static void patchToReturnTrue(uintptr_t addr) {
    // ARM64: mov x0, #1 ; ret
    uint32_t patch[] = {
        0xD2800020, // mov x0, #1
        0xD65F03C0  // ret
    };
    
    kern_return_t kr = vm_protect(
        mach_task_self(), addr, sizeof(patch),
        false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    
    if (kr != KERN_SUCCESS) {
        // Try dengan mach_vm_protect
        mach_vm_protect(mach_task_self(), addr,
            sizeof(patch), false,
            VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    }
    
    memcpy((void*)addr, patch, sizeof(patch));
    sys_icache_invalidate((void*)addr, sizeof(patch));
    
    vm_protect(mach_task_self(), addr, sizeof(patch),
        false, VM_PROT_READ | VM_PROT_EXECUTE);
}

void IntegrityPatcher_Init(uintptr_t base) {
    int count = sizeof(PATCHES) / sizeof(PatchTarget);
    for (int i = 0; i < count; i++) {
        uintptr_t addr = base + PATCHES[i].offset;
        patchToReturnTrue(addr);
        NSLog(@"[Atlas] Patched: %s @ 0x%lx", PATCHES[i].name, addr);
    }
}
