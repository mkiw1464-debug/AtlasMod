#import <Foundation/Foundation.h>
#import <substrate.h>
#import <CFNetwork/CFNetwork.h>

// Block list lengkap — semua FF/Garena AC endpoint OB54
static NSSet* g_blockedHosts = nil;

static void initBlockList() {
    g_blockedHosts = [NSSet setWithArray:@[
        // Garena AC telemetry
        @"telemetry.freefiremobile.com",
        @"anti.freefiremobile.com",
        @"report.freefiremobile.com",
        @"accheck.garena.com",
        @"security.garena.com",
        @"detect.garena.com",
        @"monitor.garena.com",
        @"log.garena.com",
        @"analytics.garena.com",
        // FF specific
        @"ac.freefire.com",
        @"cheatdetect.ff.garena.com",
        @"clientlog.freefiremobile.com",
        @"crash.freefiremobile.com",
        // Akamai endpoints FF guna
        @"garena.akamai.net",
    ]];
}

static BOOL isBlocked(NSString* host) {
    for (NSString* blocked in g_blockedHosts) {
        if ([host containsString:blocked]) return YES;
    }
    return NO;
}

// Hook NSURLSession
static id (*orig_dataTask)(id,SEL,NSURLRequest*,id);
static id hook_dataTask(id self, SEL _cmd, NSURLRequest* req, id completion) {
    if (isBlocked(req.URL.host)) {
        // Return fake 200 OK
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                NSHTTPURLResponse* r = [[NSHTTPURLResponse alloc]
                    initWithURL:req.URL statusCode:200
                    HTTPVersion:@"HTTP/1.1" headerFields:@{}];
                ((void(^)(NSData*,NSURLResponse*,NSError*))completion)
                    ([NSData data], r, nil);
            }
        });
        return nil;
    }
    return orig_dataTask(self,_cmd,req,completion);
}

// Hook CFNetwork level — lebih low level dari NSURLSession
static CFReadStreamRef (*orig_CFReadStream)(CFAllocatorRef, CFURLRef);
static CFReadStreamRef hook_CFReadStream(CFAllocatorRef alloc, CFURLRef url) {
    NSString* host = (__bridge NSString*)CFURLCopyHostName(url);
    if (isBlocked(host)) return NULL;
    return orig_CFReadStream(alloc, url);
}

void NetworkGuard_Init() {
    initBlockList();
    
    // NSURLSession hook
    Class sessionClass = NSClassFromString(@"NSURLSession");
    MSHookMessageEx(sessionClass,
        @selector(dataTaskWithRequest:completionHandler:),
        (IMP)hook_dataTask, (IMP*)&orig_dataTask);
    
    // CFNetwork low-level hook
    MSHookFunction(
        (void*)CFReadStreamCreateForHTTPRequest,
        (void*)hook_CFReadStream,
        (void**)&orig_CFReadStream);
}
