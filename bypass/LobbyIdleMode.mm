#import <Foundation/Foundation.h>

// PENTING: Antiban paling kritikal
// Cheat MESTI dalam sleep mode semasa lobby
// Aktif HANYA bila in-game

typedef enum {
    GameState_Unknown = 0,
    GameState_Lobby   = 1,
    GameState_Loading = 2,
    GameState_InGame  = 3,
    GameState_Ended   = 4
} FFGameState;

static FFGameState g_CurrentState = GameState_Unknown;
static BOOL g_CheatActive = NO;

// Detect game state via memory
static FFGameState detectGameState(uintptr_t base) {
    // OB54 game state offset
    int state = *(int*)(base + 0x13C4A200);
    
    switch(state) {
        case 0: return GameState_Lobby;
        case 1: return GameState_Loading;
        case 2: return GameState_InGame;
        case 3: return GameState_Ended;
        default: return GameState_Unknown;
    }
}

void LobbyIdle_Tick(uintptr_t base) {
    FFGameState newState = detectGameState(base);
    
    if (newState == g_CurrentState) return;
    
    g_CurrentState = newState;
    
    switch (newState) {
        case GameState_Lobby:
        case GameState_Loading:
            // SLEEP — zero cheat activity
            g_CheatActive = NO;
            NSLog(@"[Atlas] Lobby mode — cheat sleeping");
            break;
            
        case GameState_InGame:
            // Delay 3 saat lepas masuk game — bagi anticheat settle
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3.0*NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    g_CheatActive = YES;
                    NSLog(@"[Atlas] In-game — cheat active");
            });
            break;
            
        case GameState_Ended:
            g_CheatActive = NO;
            break;
            
        default: break;
    }
}

BOOL LobbyIdle_IsActive() {
    return g_CheatActive;
}
