#ifndef DEF_SHADOWFANG_KEEP_H
#define DEF_SHADOWFANG_KEEP_H

#define DataHeader "SK"

uint32 const EncounterCount = 5;

enum eData
{
    DATA_ASHBURY        = 0,
    DATA_SILVERLAINE    = 1,
    DATA_SPRINGVALE     = 2,
    DATA_VALDEN         = 3,
    DATA_GODFREY        = 4,
    DATA_EVENT_NPC      = 5,
    DATA_GUARDS         = 6,
    DATA_GUARDS2        = 7,
    DATA_TEAM           = 8,
};

// #179: escort stops (TrinityCore/CPP spawn groups 412-432, Alliance and Horde variants of a stop share one tag). The DB rows of a stop carry
// creature.phaseMask = SfkStopMask(stop) (hidden from everyone, 16-bit safe); the instance script sets it to 1 for the members that belong to the
// player's faction (Alliance: Packleader Ivar 47006 / Bloodfang Berserker 47027; Horde: Belmont 47293, Cromush 47294, Veteran Trooper 47030,
// Blightspreader 47031) when the stop is due.
inline uint32 SfkStopMask(uint32 stop) { return 1u << (4 + stop); }

enum SfkStops
{
    STOP_ENTRANCE       = 0, // CPP 412 / 413, until Baron Ashbury dies
    STOP_ASHBURY        = 1, // 421 / 422
    STOP_SILVERLAINE    = 2, // 423 / 424
    STOP_SPRINGVALE     = 3, // 425 / 429
    STOP_OUTSIDE        = 4, // 426 (Alliance, after Springvale, near the courtyard exit)
    STOP_WALDEN         = 5, // 427 / 430
    STOP_GODFREY_DEAD   = 6, // 419 / 420 (after Walden)
    STOP_GODFREY_INTRO  = 7, // 431 / 432 (Ivar / Belmont upstairs, replaces the Walden stop when you come close)
    STOP_SPRINGVALE_WALDEN_H = 8, // 428 Horde troop while only one of Springvale / Walden is dead
    STOP_COUNT          = 9
};

enum NPCs
{
    NPC_BELMONT             = 47293,
    NPC_GUARD_HORDE1        = 47030,
    NPC_GUARD_HORDE2        = 47031,
    NPC_GUARD_ALLY          = 47027,
    NPC_IVAR                = 47006,
    NPC_CROMUSH             = 47294,
    NPC_ASHBURY             = 46962,
    NPC_SILVERLAINE         = 3887,
    NPC_LUPINE_SPECTRE      = 50923,
    NPC_SPRINGVALE          = 4278,
    NPC_VALDEN              = 46963,
    NPC_GODFREY             = 46964,

    // Holyday
    NPC_APOTHECARY_HUMMEL   = 36296,
    NPC_APOTHECARY_FRYE     = 36272,
    NPC_APOTHECARY_BAXTER   = 36565,

    GO_COURTYARD_DOOR       = 18895,
    GO_SORCERER_DOOR        = 18972,  
    GO_ARUGAL_DOOR          = 18971,
};

#endif