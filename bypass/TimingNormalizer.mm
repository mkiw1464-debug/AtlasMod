#import <Foundation/Foundation.h>
#import <substrate.h>

// FF anticheat detect aimbot via input timing
// Aimbot = perfect frame-perfect input = flagged
// Kita inject human-like random delay

static NSTimeInterval randomHumanDelay() {
    // Human reaction: 80ms - 250ms dengan gaussian distribution
    float base = 0.08f;
    float range = 0.17f;
    
    // Box-Muller untuk gaussian
    float u1 = (float)arc4random() / UINT32_MAX;
    float u2 = (float)arc4random() / UINT32_MAX;
    float gauss = sqrtf(-2.0f * logf(u1)) * cosf(2.0f * M_PI * u2);
    
    float delay = base + (gauss * 0.04f);
    delay = MAX(0.05f, MIN(delay, 0.30f)); // clamp 50ms-300ms
    return delay;
}

// Hook aim function untuk inject delay
// Timing anomaly detector bypass
static BOOL g_lastAimFrame = NO;
static NSTimeInterval g_lastAimTime = 0;

BOOL TimingNorm_ShouldAim() {
    // Kalau aim terlalu consistent — slow down
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval delta = now - g_lastAimTime;
    
    if (g_lastAimFrame && delta < 0.016f) {
        // Terlalu cepat — skip frame ini
        return NO;
    }
    
    // Inject random micro-miss (2% chance)
    // Buat nampak macam manusia miss sikit
    if ((arc4random() % 100) < 2) {
        return NO;
    }
    
    g_lastAimTime = now;
    g_lastAimFrame = YES;
    return YES;
}

// Normalize aim speed — bukan snap terus
Vec3 TimingNorm_SmoothAim(Vec3 current, Vec3 target, float factor) {
    // Lerp dengan human-like speed
    float speed = 0.15f + ((float)(arc4random() % 10) / 100.0f);
    Vec3 result;
    result.x = current.x + (target.x - current.x) * speed * factor;
    result.y = current.y + (target.y - current.y) * speed * factor;
    result.z = current.z + (target.z - current.z) * speed * factor;
    return result;
}
