#pragma once
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>

#define FF_PACKAGE @"com.dts.freefireth"

// Offsets OB54 — update via IDA each patch
#define OFF_BONE_BASE     0x12A4F8C0
#define OFF_VIEWMATRIX    0x13B2C010
#define OFF_PLAYERLIST    0x12F3A200
#define OFF_LOCALPLAYER   0x12F3A100
#define OFF_AIMSYSTEM     0x129E4400
#define OFF_BULLETTP      0x12A11200
#define OFF_ANTIRECORD    0x13AA2310

typedef struct {
    float x, y, z;
} Vec3;

typedef struct {
    float m[4][4];
} Matrix4x4;

extern bool g_AimbotHead;
extern bool g_AimbotBody;
extern bool g_AimbotNeck;
extern bool g_AimbotLeg;
extern float g_AimFOV;
extern bool g_ESPLine;
extern bool g_ESPBox;
extern bool g_ESPSkeleton;
extern bool g_AimSilent;
extern bool g_AimKill;
extern bool g_StreamProof;
extern bool g_MenuVisible;
