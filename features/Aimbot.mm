#import "Aimbot.h"
#import "../AtlasMod.h"

bool g_AimbotHead = false;
bool g_AimbotBody = false;
bool g_AimbotNeck = false;
bool g_AimbotLeg  = false;
float g_AimFOV    = 150.0f;
bool g_AimSilent  = false;
bool g_AimKill    = false;

static uintptr_t getBase() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strcmp(_dyld_get_image_name(i), FF_PACKAGE.UTF8String) == 0)
            return (uintptr_t)_dyld_get_image_header(i);
    }
    return 0;
}

static Vec3 getBonePosition(uintptr_t player, int boneID) {
    uintptr_t bonePtr = *(uintptr_t*)(player + 0x138);
    Vec3 pos;
    memcpy(&pos, (void*)(bonePtr + boneID * 0x30), sizeof(Vec3));
    return pos;
}

static CGPoint worldToScreen(Vec3 worldPos, Matrix4x4 vp) {
    float clipX = worldPos.x * vp.m[0][0] + worldPos.y * vp.m[1][0] +
                  worldPos.z * vp.m[2][0] + vp.m[3][0];
    float clipY = worldPos.x * vp.m[0][1] + worldPos.y * vp.m[1][1] +
                  worldPos.z * vp.m[2][1] + vp.m[3][1];
    float clipW = worldPos.x * vp.m[0][3] + worldPos.y * vp.m[1][3] +
                  worldPos.z * vp.m[2][3] + vp.m[3][3];
    if (clipW <= 0) return CGPointZero;
    
    CGSize screen = UIScreen.mainScreen.bounds.size;
    return CGPointMake(
        (1.0f + clipX / clipW) * screen.width  * 0.5f,
        (1.0f - clipY / clipW) * screen.height * 0.5f
    );
}

void Aimbot_Tick(uintptr_t localPlayer, uintptr_t* enemies,
                 int enemyCount, Matrix4x4 vp) {
    if (!g_AimbotHead && !g_AimbotBody &&
        !g_AimbotNeck && !g_AimbotLeg) return;
    
    CGSize screen = UIScreen.mainScreen.bounds.size;
    CGPoint center = CGPointMake(screen.width/2, screen.height/2);
    
    uintptr_t bestTarget = 0;
    float bestDist = g_AimFOV;
    Vec3 bestBone = {0,0,0};
    
    // Bone IDs FF OB54
    int boneID = 4;  // head default
    if (g_AimbotNeck) boneID = 3;
    if (g_AimbotBody) boneID = 1;
    if (g_AimbotLeg)  boneID = 7;
    
    for (int i = 0; i < enemyCount; i++) {
        if (!enemies[i]) continue;
        Vec3 bone = getBonePosition(enemies[i], boneID);
        CGPoint screenPt = worldToScreen(bone, vp);
        if (CGPointEqualToPoint(screenPt, CGPointZero)) continue;
        
        float dx = screenPt.x - center.x;
        float dy = screenPt.y - center.y;
        float dist = sqrtf(dx*dx + dy*dy);
        
        if (dist < bestDist) {
            bestDist = dist;
            bestTarget = enemies[i];
            bestBone = bone;
        }
    }
    
    if (!bestTarget) return;
    
    if (g_AimSilent) {
        // Silent aim — patch bullet trajectory tanpa move crosshair
        uintptr_t base = getBase();
        uintptr_t bulletSys = *(uintptr_t*)(base + OFF_BULLETTP);
        // Write target bone coords ke bullet aim vector
        memcpy((void*)(bulletSys + 0x48), &bestBone, sizeof(Vec3));
    } else {
        // Normal aimbot — move aim offset
        uintptr_t base = getBase();
        uintptr_t aimSys = *(uintptr_t*)(base + OFF_AIMSYSTEM);
        float aimH = atan2f(bestBone.z - 0, bestBone.x);
        float aimV = atan2f(bestBone.y, sqrtf(bestBone.x*bestBone.x + bestBone.z*bestBone.z));
        memcpy((void*)(aimSys + 0x10), &aimH, 4);
        memcpy((void*)(aimSys + 0x14), &aimV, 4);
    }
    
    if (g_AimKill) {
        // Force max damage multiplier
        float maxDmg = 9999.0f;
        uintptr_t base = getBase();
        memcpy((void*)(base + 0x12B44200), &maxDmg, 4);
    }
}
