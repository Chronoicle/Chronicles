#include "PartyBot.h"
#include "AccountMgr.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "MotionMaster.h"
#include "MovementPackets.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "World.h"
#include "Chat.h"
#include "GlobalFunctional.h"
#include "CharacterPackets.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include <boost/algorithm/string/predicate.hpp>
#include <sstream>

// ---------------------------------------------------------------- session

PartyBotSession::PartyBotSession(uint32 accountId, std::string&& accountName, ObjectGuid botGuid, ObjectGuid leaderGuid) :
    WorldSession(accountId, std::move(accountName), nullptr, SEC_PLAYER, CURRENT_EXPANSION, 0, "Win", LOCALE_enUS, 0, false,
        AT_AUTH_FLAG_NONE, std::unordered_map<uint8, int64>()),
    _botGuid(botGuid), _leaderGuid(leaderGuid)
{
}

bool PartyBotSession::Update(uint32 diff, Map* map)
{
    // once the bot is on a map, the map updates its session (World::UpdateSessions skips it), so the bot steps run in
    // both: on the map for a bot in the world, in the world update while it is loading or between maps
    bool result = WorldSession::Update(diff, map);

    Player* bot = GetPlayer();
    if (!_loginStarted)
    {
        _loginStarted = true;
        LoginAsBot(_botGuid);
        return result;
    }

    if (!bot)
    {
        if (!PlayerLoading())
            _done = true;               // logged out (or the login failed): the world removes the session
        return result;
    }

    AckTeleports(bot);

    if (!bot->IsInWorld())
        return result;

    FinishBotLogin();

    if (!_setupDone && !_dismissed)
        Setup(bot);

    // the leader logged out: wait a moment (reconnects, loading screens), then go too
    if (!_dismissed)
    {
        if (ObjectAccessor::FindPlayer(_leaderGuid))
            _leaderGoneTimer = 0;
        else if ((_leaderGoneTimer += diff) > 60 * IN_MILLISECONDS)
            Dismiss();
    }

    return result;
}

void PartyBotSession::AckTeleports(Player* bot)
{
    if (bot->IsBeingTeleportedFar())
        HandleWorldPortAck();
    else if (bot->IsBeingTeleportedNear())
    {
        WorldPacket data(CMSG_MOVE_TELEPORT_ACK);
        WorldPackets::Movement::MoveTeleportAck ack(std::move(data));
        ack.MoverGUID = bot->GetGUID();
        ack.ClientMoveTime = int32(getMSTime());
        HandleMoveTeleportAck(ack);
    }
}

// .partybot create made this character: level 110, its spec and its gear set (world.gear_npc_items) at the first login
void PartyBotSession::FirstLoginSetup(Player* bot, uint32 specId)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(specId);
    if (!spec || spec->ClassID != bot->getClass())
        return;

    if (bot->getLevel() < 110)
        bot->GiveLevel(110);
    if (bot->GetSpecializationId() != specId)
        bot->ActivateTalentGroup(spec);

    // starting gear out, the spec's set in
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);

    if (QueryResult result = WorldDatabase.PQuery("SELECT item, bonus FROM gear_npc_items WHERE spec = %u ORDER BY slot = 'artifact' DESC, slot", specId))
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 itemId = fields[0].GetUInt32();
            std::vector<uint32> bonuses;
            std::istringstream tokens(fields[1].GetString());
            uint32 bonus;
            while (tokens >> bonus)
                bonuses.push_back(bonus);

            uint16 dest;
            if (bot->CanEquipNewItem(NULL_SLOT, dest, itemId, false) == EQUIP_ERR_OK)
                bot->EquipNewItem(dest, itemId, true, 0, bonuses);
        } while (result->NextRow());
    }

    bot->SetFullHealth();
    CharacterDatabase.PExecute("UPDATE partybot_characters SET setup = 1 WHERE guid = %u", bot->GetGUIDLow());
    bot->SaveToDB();
}

void PartyBotSession::Setup(Player* bot)
{
    _setupDone = true;

    if (QueryResult result = CharacterDatabase.PQuery("SELECT spec FROM partybot_characters WHERE guid = %u AND setup = 0", bot->GetGUIDLow()))
        FirstLoginSetup(bot, (*result)[0].GetUInt32());

    Player* leader = ObjectAccessor::FindPlayer(_leaderGuid);
    if (!leader)
    {
        Dismiss();
        return;
    }

    Group* group = leader->GetGroup();
    if (!group)
    {
        group = new Group;
        if (!group->Create(leader))
        {
            delete group;
            Dismiss();
            return;
        }
        sGroupMgr->AddGroup(group);
    }

    if (!group->IsMember(bot->GetGUID()))
    {
        if (group->IsFull() || !group->AddMember(bot))
        {
            ChatHandler(leader->GetSession()).PSendSysMessage("Party bot %s: your group is full.", bot->GetName());
            Dismiss();
            return;
        }
    }

    uint8 slot = sPartyBotMgr->CountBots(_leaderGuid);
    bot->SetAI(new PartyBotAI(bot, _leaderGuid, slot));
    bot->IsAIEnabled = true;

    if (bot->GetMapId() != leader->GetMapId() || !bot->IsWithinDistInMap(leader, 30.0f))
        bot->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());

    ChatHandler(leader->GetSession()).PSendSysMessage("Party bot %s joined your group.", bot->GetName());
}

void PartyBotSession::Dismiss()
{
    if (_dismissed)
        return;
    _dismissed = true;

    if (Player* bot = GetPlayer())
    {
        if (bot->IsAIEnabled)
        {
            bot->IsAIEnabled = false;
            UnitAI* ai = bot->GetAI();
            bot->SetAI(nullptr);
            delete ai;
        }
        if (Group* group = bot->GetGroup())
            group->RemoveMember(bot->GetGUID());
    }

    LogoutRequest(time(nullptr) - 20);  // WorldSession::Update logs out on the next tick (saves the character)
}

// ---------------------------------------------------------------- AI

void PartyBotAI::FollowLeader(Player* leader)
{
    if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() == FOLLOW_MOTION_TYPE)
        return;

    // spread out behind the leader: slots 0..3 at 2.5 yd, left/right behind
    static float const angles[] = { float(M_PI) * 0.75f, float(M_PI) * 1.25f, float(M_PI) * 0.6f, float(M_PI) * 1.4f };
    me->GetMotionMaster()->MoveFollow(leader, 2.5f, angles[_slot % 4]);
}

void PartyBotAI::UpdateAI(uint32 diff)
{
    if (_checkTimer > diff)
    {
        _checkTimer -= diff;
        return;
    }
    _checkTimer = 500;

    Player* leader = ObjectAccessor::FindPlayer(_leaderGuid);
    if (!leader || !leader->IsInWorld() || me->IsBeingTeleported())
        return;

    // dead: come back when the leader is alive and out of combat
    if (me->isDead())
    {
        if (leader->IsAlive() && !leader->isInCombat())
        {
            me->ResurrectPlayer(0.5f);
            me->SpawnCorpseBones();
            me->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());
        }
        return;
    }

    // other map or far away (portals, summons, the leader's hearthstone): teleport to the leader
    if (me->GetMapId() != leader->GetMapId() || !me->IsWithinDistInMap(leader, 100.0f))
    {
        if (!leader->IsBeingTeleported() && !leader->isInFlight())
            me->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());
        return;
    }

    // help the leader: attack what the leader attacks
    Unit* target = leader->getVictim();
    if (target && target->IsAlive() && me->IsValidAttackTarget(target) && me->IsWithinDistInMap(target, 60.0f))
    {
        if (me->getVictim() != target)
        {
            me->Attack(target, true);
            me->GetMotionMaster()->MoveChase(target);
        }
        return;
    }

    if (me->getVictim())
        me->AttackStop();

    FollowLeader(leader);
}

// ---------------------------------------------------------------- manager

PartyBotMgr* PartyBotMgr::instance()
{
    static PartyBotMgr instance;
    return &instance;
}

void PartyBotMgr::Cleanup()
{
    _bots.erase(std::remove_if(_bots.begin(), _bots.end(), [](std::weak_ptr<PartyBotSession> const& bot)
    {
        std::shared_ptr<PartyBotSession> session = bot.lock();
        return !session || session->IsDismissed();
    }), _bots.end());
}

std::vector<std::shared_ptr<PartyBotSession>> PartyBotMgr::GetBots(ObjectGuid leaderGuid)
{
    std::lock_guard<std::mutex> guard(_lock);
    Cleanup();
    std::vector<std::shared_ptr<PartyBotSession>> result;
    for (auto const& bot : _bots)
        if (std::shared_ptr<PartyBotSession> session = bot.lock())
            if (session->GetLeaderGuid() == leaderGuid)
                result.push_back(session);
    return result;
}

uint8 PartyBotMgr::CountBots(ObjectGuid leaderGuid)
{
    return uint8(GetBots(leaderGuid).size());
}

std::string PartyBotMgr::AddBot(Player* leader, std::string name)
{
    if (!normalizePlayerName(name))
        return "Unknown character name.";

    ObjectGuid guid = ObjectMgr::GetPlayerGUIDByName(name);
    if (guid.IsEmpty())
        return "No character named " + name + ".";
    if (ObjectAccessor::FindPlayer(guid))
        return name + " is already online.";

    uint32 accountId = ObjectMgr::GetPlayerAccountIdByGUID(guid);
    if (!accountId)
        return "No account for " + name + ".";
    if (accountId == leader->GetSession()->GetAccountId())
        return name + " is on your own account; party bots need a character of another account.";
    if (sWorld->FindSession(accountId))
        return "The account of " + name + " is in use (logged in, or already a bot).";

    if (CountBots(leader->GetGUID()) >= MaxBotsPerLeader)
        return "You already have the maximum of party bots.";
    if (Group* group = leader->GetGroup())
        if (group->IsFull())
            return "Your group is full.";

    std::string accountName;
    if (!AccountMgr::GetName(accountId, accountName))
        return "No account for " + name + ".";

    std::shared_ptr<PartyBotSession> session = std::make_shared<PartyBotSession>(accountId, std::move(accountName), guid, leader->GetGUID());
    {
        std::lock_guard<std::mutex> guard(_lock);
        _bots.push_back(session);
    }
    sWorld->AddSession(session);
    TC_LOG_INFO("server.partybot", "Party bot %s (account %u) for %s", name.c_str(), accountId, leader->GetName());
    return "";
}

std::string PartyBotMgr::RemoveBot(Player* leader, std::string const& name)
{
    uint32 removed = 0;
    for (std::shared_ptr<PartyBotSession> const& session : GetBots(leader->GetGUID()))
    {
        Player* bot = session->GetPlayer();
        if (!name.empty() && (!bot || !boost::iequals(std::string(bot->GetName()), name)))
            continue;
        session->Dismiss();
        ++removed;
    }

    if (!removed)
        return name.empty() ? "You have no party bots." : "No party bot named " + name + ".";
    return "";
}

// ---------------------------------------------------------------- bot characters

ChrSpecializationEntry const* PartyBotMgr::FindSpec(std::string const& className, std::string const& specName)
{
    for (uint32 cls = 1; cls < MAX_CLASSES; ++cls)
    {
        ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(cls);
        if (!classEntry || !boost::iequals(std::string(classEntry->Name->Str[DEFAULT_LOCALE]), className))
            continue;
        for (uint32 i = 0; i < MAX_SPECIALIZATIONS; ++i)
            if (ChrSpecializationEntry const* spec = sDB2Manager.GetChrSpecializationByIndex(cls, i))
                if (boost::iequals(std::string(spec->Name->Str[DEFAULT_LOCALE]), specName))
                    return spec;
    }
    return nullptr;
}

// a race of the creator's faction that can be this class
static uint8 BotRace(uint8 cls, bool alliance)
{
    if (alliance)
    {
        switch (cls)
        {
            case CLASS_SHAMAN:       return RACE_DRAENEI;
            case CLASS_DRUID:
            case CLASS_DEMON_HUNTER: return RACE_NIGHTELF;
            default:                 return RACE_HUMAN;
        }
    }
    switch (cls)
    {
        case CLASS_PALADIN:
        case CLASS_PRIEST:
        case CLASS_DEMON_HUNTER: return RACE_BLOODELF;
        case CLASS_DRUID:        return RACE_TAUREN;
        default:                 return RACE_ORC;
    }
}

static std::string BotName(ChrSpecializationEntry const* spec)
{
    // letters of spec + class, e.g. Holypaladin; letters a..z at the end when the name is taken
    std::string base;
    std::string raw = std::string(spec->Name->Str[DEFAULT_LOCALE]) + sChrClassesStore.AssertEntry(spec->ClassID)->Name->Str[DEFAULT_LOCALE];
    for (char c : raw)
        if (isalpha(c))
            base += char(base.empty() ? toupper(c) : tolower(c));
    if (base.size() > 11)
        base.resize(11);

    std::string name = base;
    for (char suffix = 'a'; suffix <= 'z'; ++suffix)
    {
        if (ObjectMgr::GetPlayerGUIDByName(name).IsEmpty() && sWorld->CheckCharacterName(name))
            return name;
        name = base + suffix;
    }
    return "";
}

std::string PartyBotMgr::CreateBot(Player* creator, uint32 specId, std::string& name)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(specId);
    if (!spec || !spec->ClassID || spec->ClassID >= MAX_CLASSES)
        return "Unknown specialization.";

    // a partybot account without characters
    uint32 accountId = 0;
    if (QueryResult accounts = LoginDatabase.Query("SELECT id FROM account WHERE username LIKE 'PARTYBOT%@BOT' ORDER BY id"))
    {
        do
        {
            uint32 id = (*accounts)[0].GetUInt32();
            if (!_usedAccounts.count(id) && !CharacterDatabase.PQuery("SELECT 1 FROM characters WHERE account = %u LIMIT 1", id))
            {
                accountId = id;
                break;
            }
        } while (accounts->NextRow());
    }
    if (!accountId)
        return "No free partybot account left (partybotN@bot).";

    name = BotName(spec);
    if (name.empty())
        return "Could not find a free name.";

    std::string accountName;
    AccountMgr::GetName(accountId, accountName);
    PartyBotSession session(accountId, std::move(accountName), ObjectGuid::Empty, ObjectGuid::Empty);

    WorldPackets::Character::CharacterCreateInfo info;
    info.Race = BotRace(spec->ClassID, creator->GetTeam() == ALLIANCE);
    info.Class = spec->ClassID;
    info.Sex = urand(0, 1) ? GENDER_MALE : GENDER_FEMALE;
    info.Name = name;
    info.CustomDisplay.fill(0);

    Player newChar(&session);
    newChar.GetMotionMaster()->Initialize();
    if (!newChar.Create(sObjectMgr->GetGenerator<HighGuid::Player>()->Generate(), &info))
    {
        newChar.CleanupsBeforeDelete();
        return "The character could not be created.";
    }

    _usedAccounts.insert(accountId);
    newChar.setCinematic(1);
    newChar.SaveToDB(true);
    sWorld->AddCharacterInfo(newChar.GetGUID(), accountId, name, newChar.getGender(), newChar.getRace(), newChar.getClass(), newChar.getLevel());
    sWorld->UpdateCharacterAccount(newChar.GetGUID(), accountId);
    CharacterDatabase.PExecute("REPLACE INTO partybot_characters (guid, account, spec, setup) VALUES (%u, %u, %u, 0)", newChar.GetGUIDLow(), accountId, specId);
    newChar.GetAchievementMgr()->ClearMap();
    newChar.CleanupsBeforeDelete();

    TC_LOG_INFO("server.partybot", "Party bot character %s (spec %u, account %u) created by %s", name.c_str(), specId, accountId, creator->GetName());
    return "";
}

std::string PartyBotMgr::AddBotByRole(Player* leader, std::string const& what)
{
    // a character name first
    std::string name = what;
    if (normalizePlayerName(name) && !ObjectMgr::GetPlayerGUIDByName(name).IsEmpty())
        return AddBot(leader, name);

    int32 role = -1;
    if (boost::iequals(what, "tank"))
        role = 0;
    else if (boost::iequals(what, "healer") || boost::iequals(what, "heal"))
        role = 1;
    else if (boost::iequals(what, "dps") || boost::iequals(what, "damage"))
        role = 2;

    QueryResult result = CharacterDatabase.Query("SELECT p.guid, p.spec, c.name, c.race FROM partybot_characters p JOIN characters c ON c.guid = p.guid ORDER BY p.guid");
    if (!result)
        return "There are no bot characters yet (.partybot create <class> <spec>).";

    bool alliance = leader->GetTeam() == ALLIANCE;
    do
    {
        Field* fields = result->Fetch();
        ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(fields[1].GetUInt32());
        if (!spec || (Player::TeamForRace(fields[3].GetUInt8()) == ALLIANCE) != alliance)
            continue;

        bool match = role >= 0 ? spec->Role == role
            : boost::iequals(std::string(spec->Name->Str[DEFAULT_LOCALE]), what)
            || boost::iequals(std::string(sChrClassesStore.AssertEntry(spec->ClassID)->Name->Str[DEFAULT_LOCALE]), what);
        if (!match)
            continue;

        std::string botName = fields[2].GetString();
        ObjectGuid guid = ObjectMgr::GetPlayerGUIDByName(botName);
        if (guid.IsEmpty() || ObjectAccessor::FindPlayer(guid))
            continue;
        if (sWorld->FindSession(ObjectMgr::GetPlayerAccountIdByGUID(guid)))
            continue;
        return AddBot(leader, botName);
    } while (result->NextRow());

    return "No free bot for '" + what + "' on your faction (.partybot create <class> <spec>).";
}
