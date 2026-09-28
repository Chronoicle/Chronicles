/*
 * Gear-Up NPC (500010), owner request 2026-09-28: staff only (GM accounts), players get a line and nothing else.
 *
 *  1. Bags: 4x Imbued Silkweave Bag.
 *  2. <your class> gear: one option per spec, gives the same best-in-slot set as tools/fill_character (item level 985,
 *     legendaries 1000, 20% Leech / Avoidance / Speed via tertiary bonuses, a prismatic socket on armor and jewelry).
 *     The sets come from world.gear_npc_items, written by `fill_character.py export` (sql/custom/gear_npc_items.sql).
 *  3. Max professions: learn a profession at its Legion maximum with every recipe.
 */
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "AccountMgr.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include "Bag.h"
#include "Item.h"
#include "Player.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "WorldSession.h"
#include <sstream>

enum GearUpNpc
{
    ITEM_IMBUED_SILKWEAVE_BAG = 142075,
    BAG_COUNT                 = 4,

    ACTION_MAIN               = 1,
    ACTION_BAGS               = 2,
    ACTION_GEAR_MENU          = 3,
    ACTION_PROFESSION_MENU    = 4,
    ACTION_GEAR_SPEC          = 1000,   // + ChrSpecialization ID
    ACTION_PROFESSION         = 2000,   // + index in Professions
};

struct GearUpProfession
{
    uint32 SkillId;
    uint32 LegionRankSpell;             // SPELL_EFFECT_LEARN_SKILL, step 10 (Legion)
    bool Primary;
    char const* Name;
};

static GearUpProfession const Professions[] =
{
    { 171, 201697, true,  "Alchemy" },
    { 164, 201699, true,  "Blacksmithing" },
    { 333, 201698, true,  "Enchanting" },
    { 202, 201700, true,  "Engineering" },
    { 182, 201702, true,  "Herbalism" },
    { 773, 201703, true,  "Inscription" },
    { 755, 201704, true,  "Jewelcrafting" },
    { 165, 201705, true,  "Leatherworking" },
    { 186, 201706, true,  "Mining" },
    { 393, 201707, true,  "Skinning" },
    { 197, 201708, true,  "Tailoring" },
    { 185, 201710, false, "Cooking" },
    { 129, 201701, false, "First Aid" },
    { 356, 210829, false, "Fishing" },
};

static void ShowMain(Player* player, Creature* creature)
{
    player->PlayerTalkClass->ClearMenus();
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, "Bags: 4x Imbued Silkweave Bag", GOSSIP_SENDER_MAIN, ACTION_BAGS);
    std::string gear = "Best-in-slot gear";
    if (ChrClassesEntry const* cls = sChrClassesStore.LookupEntry(player->getClass()))
        gear = std::string(cls->Name->Str[DEFAULT_LOCALE]) + " gear (item level 985)";
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Trainer, gear, GOSSIP_SENDER_MAIN, ACTION_GEAR_MENU);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Trainer, "Max professions", GOSSIP_SENDER_MAIN, ACTION_PROFESSION_MENU);
    player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
}

static void ShowGear(Player* player, Creature* creature)
{
    player->PlayerTalkClass->ClearMenus();
    for (uint32 i = 0; i < MAX_SPECIALIZATIONS; ++i)
        if (ChrSpecializationEntry const* spec = sDB2Manager.GetChrSpecializationByIndex(player->getClass(), i))
            player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, std::string(spec->Name->Str[DEFAULT_LOCALE]) + ": full set",
                GOSSIP_SENDER_MAIN, ACTION_GEAR_SPEC + spec->ID);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "<< Back", GOSSIP_SENDER_MAIN, ACTION_MAIN);
    player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
}

static void ShowProfessions(Player* player, Creature* creature)
{
    player->PlayerTalkClass->ClearMenus();
    for (uint32 i = 0; i < sizeof(Professions) / sizeof(Professions[0]); ++i)
    {
        GearUpProfession const& p = Professions[i];
        std::string text = p.Name;
        if (player->HasSkill(p.SkillId))
            text += " (known, set to max)";
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::Trainer, text, GOSSIP_SENDER_MAIN, ACTION_PROFESSION + i);
    }
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "<< Back", GOSSIP_SENDER_MAIN, ACTION_MAIN);
    player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
}

static uint32 FreeBagSlots(Player* player)
{
    uint32 slots = 0;
    for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
        if (Bag* bag = player->GetBagByPos(i))
            slots += bag->GetFreeSlots();
    uint8 inventoryEnd = INVENTORY_SLOT_ITEM_START + player->GetInventorySlotCount();
    for (uint8 i = INVENTORY_SLOT_ITEM_START; i < inventoryEnd; ++i)
        if (!player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
            ++slots;
    return slots;
}

static bool StoreItem(Player* player, uint32 itemId, uint32 count, std::vector<uint32> const& bonuses)
{
    ItemPosCountVec dest;
    if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, itemId, count) != EQUIP_ERR_OK)
        return false;

    if (Item* item = player->StoreNewItem(dest, itemId, true, Item::GenerateItemRandomPropertyId(itemId, player->GetLootSpecID()), GuidSet(), bonuses))
    {
        player->SendNewItem(item, count, true, false);
        return true;
    }
    return false;
}

static void GiveBags(Player* player)
{
    uint32 given = 0;
    for (; given < BAG_COUNT; ++given)
        if (!StoreItem(player, ITEM_IMBUED_SILKWEAVE_BAG, 1, {}))
            break;

    if (given < BAG_COUNT)
        ChatHandler(player->GetSession()).PSendSysMessage("Gear-Up: only %u of %u bags fit, free some space.", given, uint32(BAG_COUNT));
}

static void GiveGear(Player* player, uint32 specId)
{
    ChatHandler chat(player->GetSession());
    QueryResult result = WorldDatabase.PQuery("SELECT item, bonus FROM gear_npc_items WHERE spec = %u", specId);
    if (!result)
    {
        chat.SendSysMessage("Gear-Up: no gear set for this spec (run fill_character.py export and apply gear_npc_items.sql).");
        return;
    }

    std::vector<std::pair<uint32, std::vector<uint32>>> items;
    do
    {
        Field* fields = result->Fetch();
        std::vector<uint32> bonuses;
        std::istringstream tokens(fields[1].GetString());
        uint32 bonus;
        while (tokens >> bonus)
            bonuses.push_back(bonus);
        items.emplace_back(fields[0].GetUInt32(), bonuses);
    } while (result->NextRow());

    if (FreeBagSlots(player) < items.size())
    {
        chat.PSendSysMessage("Gear-Up: you need %u free bag slots (take the bags first).", uint32(items.size()));
        return;
    }

    uint32 given = 0;
    for (auto const& itr : items)
        if (StoreItem(player, itr.first, 1, itr.second))
            ++given;
    chat.PSendSysMessage("Gear-Up: %u of %u items are in your bags.", given, uint32(items.size()));
}

static void LearnProfession(Player* player, GearUpProfession const& p)
{
    ChatHandler chat(player->GetSession());
    if (p.Primary && !player->HasSkill(p.SkillId) && player->GetFreePrimaryProfessionPoints() == 0)
    {
        chat.PSendSysMessage("Gear-Up: you already have two main professions; unlearn one to learn %s.", p.Name);
        return;
    }

    if (!player->HasSkill(p.SkillId) || player->GetSkillStep(p.SkillId) < 10)
        player->CastSpell(player, p.LegionRankSpell, true);   // EffectLearnSkill: the skill at the Legion step

    // every recipe of the profession (same as .learn all_recipes)
    uint32 classMask = player->getClassMask();
    for (uint32 j = 0; j < sSkillLineAbilityStore.GetNumRows(); ++j)
    {
        SkillLineAbilityEntry const* ability = sSkillLineAbilityStore.LookupEntry(j);
        if (!ability || ability->SkillLine != p.SkillId || ability->SupercedesSpell || ability->RaceMask)
            continue;
        if (ability->ClassMask && !(ability->ClassMask & classMask))
            continue;
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(ability->Spell);
        if (!spellInfo || !SpellMgr::IsSpellValid(spellInfo, player, false))
            continue;
        player->learnSpell(ability->Spell, false);
    }

    if (!player->HasSkill(p.SkillId))
    {
        chat.PSendSysMessage("Gear-Up: could not learn %s.", p.Name);
        return;
    }

    uint16 maxValue = player->GetPureMaxSkillValue(p.SkillId);
    player->SetSkill(p.SkillId, player->GetSkillStep(p.SkillId), maxValue, maxValue);
    chat.PSendSysMessage("Gear-Up: %s %u/%u with every recipe.", p.Name, uint32(maxValue), uint32(maxValue));
}

class npc_gear_up : public CreatureScript
{
public:
    npc_gear_up() : CreatureScript("npc_gear_up") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!AccountMgr::IsModeratorAccount(player->GetSession()->GetSecurity()))
        {
            player->PlayerTalkClass->ClearMenus();
            player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            ChatHandler(player->GetSession()).SendSysMessage("This service is for the staff only.");
            return true;
        }

        ShowMain(player, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (!AccountMgr::IsModeratorAccount(player->GetSession()->GetSecurity()))
        {
            player->CLOSE_GOSSIP_MENU();
            return true;
        }

        switch (action)
        {
            case ACTION_MAIN:            ShowMain(player, creature); return true;
            case ACTION_GEAR_MENU:       ShowGear(player, creature); return true;
            case ACTION_PROFESSION_MENU: ShowProfessions(player, creature); return true;
            case ACTION_BAGS:
                GiveBags(player);
                ShowMain(player, creature);
                return true;
            default:
                break;
        }

        if (action >= ACTION_PROFESSION)
        {
            uint32 index = action - ACTION_PROFESSION;
            if (index < sizeof(Professions) / sizeof(Professions[0]))
                LearnProfession(player, Professions[index]);
            ShowProfessions(player, creature);
            return true;
        }

        if (action >= ACTION_GEAR_SPEC)
        {
            ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(action - ACTION_GEAR_SPEC);
            if (spec && spec->ClassID == player->getClass())
                GiveGear(player, spec->ID);
            player->CLOSE_GOSSIP_MENU();
            return true;
        }

        player->CLOSE_GOSSIP_MENU();
        return true;
    }
};

void AddSC_gear_up_npc()
{
    new npc_gear_up();
}
