#import "AntiDetect.h"
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <dlfcn.h>

// Hook memory integrity check
static void patchMemoryCheck(uintptr_t base) {
    // NOP FF's integrity scanner region
    // OB54 scanner sits at base+0x03F2A100
    uintptr_t scanAddr = base + 0x03F2A100;
    uint32_t nop = 0xD503201F; // ARM64 NOP
    
    vm_protect(mach_task_self(), scanAddr, sizeof(nop),
               false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    memcpy((void*)scanAddr, &nop, sizeof(nop));
    vm_protect(mach_task_self(), scanAddr, sizeof(nop),
               false, VM_PROT_READ | VM_PROT_EXECUTE);
}

// Spoof process name agar tak detected
static void spoofProcessInfo() {
    // Override argv[0] string in memory
    // Ini buat tools scan nampak nama lain
    const char* fakeName = "UnityPlayer";
    extern char **environ;
    
    // Shadow proc name
    int mib[3] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    size_t size = 0;
    sysctl(mib, 3, NULL, &size, NULL, 0);
}

// Bypass ptrace anti-debug
typedef int (*ptrace_t)(int, pid_t, caddr_t, int);
static ptrace_t orig_ptrace;

static int fake_ptrace(int req, pid_t pid, caddr_t addr, int data) {
    if (req == 31) return 0; // PT_DENY_ATTACH → return clean
    return orig_ptrace(req, pid, addr, data);
}

void AntiDetect_Init(uintptr_t base) {
    patchMemoryCheck(base);
    spoofProcessInfo();
    
    // Hook ptrace
    MSHookFunction((void*)dlsym(RTLD_DEFAULT, "ptrace"),
                   (void*)fake_ptrace, (void**)&orig_ptrace);
}
