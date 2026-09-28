/*
 * Party bots (owner request 2026-09-28, #65), phase 1: a character of another (offline) account logs in without a
 * client, joins its leader's group, follows the leader across maps and helps with auto attacks.
 * Spells per spec (tank / healer / damage rotations) come in the next phases.
 *
 * Built on the idea of normalzero/LegionPlayerBot (PlayerBotSession): a WorldSession without a socket whose login,
 * teleports and loading screens the server acknowledges itself.
 */
#ifndef PARTYBOT_H
#define PARTYBOT_H

#include "WorldSession.h"
#include "UnitAI.h"

struct ChrSpecializationEntry;

class PartyBotSession : public WorldSession
{
public:
    PartyBotSession(uint32 accountId, std::string&& accountName, ObjectGuid botGuid, ObjectGuid leaderGuid);

    bool IsBotSession() const override { return true; }
    bool BotCanBeRemoved() const override { return _done; }
    bool Update(uint32 diff, Map* map = nullptr) override;

    ObjectGuid GetBotGuid() const { return _botGuid; }
    ObjectGuid GetLeaderGuid() const { return _leaderGuid; }
    void Dismiss();                     // leave the group and log out
    bool IsDismissed() const { return _dismissed; }

private:
    void Setup(Player* bot);
    void FirstLoginSetup(Player* bot, uint32 specId);
    void AckTeleports(Player* bot);

    ObjectGuid _botGuid;
    ObjectGuid _leaderGuid;
    bool _loginStarted = false;
    bool _setupDone = false;
    bool _dismissed = false;
    bool _done = false;
    uint32 _leaderGoneTimer = 0;
};

class PartyBotAI : public PlayerAI
{
public:
    PartyBotAI(Player* bot, ObjectGuid leaderGuid, uint8 slot) : PlayerAI(bot), _leaderGuid(leaderGuid), _slot(slot) { }

    void UpdateAI(uint32 diff) override;

private:
    void FollowLeader(Player* leader);

    ObjectGuid _leaderGuid;
    uint8 _slot;                        // position around the leader
    uint32 _checkTimer = 0;
};

class TC_GAME_API PartyBotMgr
{
public:
    static PartyBotMgr* instance();

    // returns an error text, empty on success
    std::string AddBot(Player* leader, std::string name);
    // name, "tank" / "healer" / "dps", a spec ("holy") or a class ("paladin"): a free bot of the leader's faction
    std::string AddBotByRole(Player* leader, std::string const& what);
    // a new bot character for this spec on the next free partybot account, on the creator's faction
    std::string CreateBot(Player* creator, uint32 specId, std::string& name);
    static ChrSpecializationEntry const* FindSpec(std::string const& className, std::string const& specName);
    std::string RemoveBot(Player* leader, std::string const& name);   // empty name = all of the leader's bots
    std::vector<std::shared_ptr<PartyBotSession>> GetBots(ObjectGuid leaderGuid);
    uint8 CountBots(ObjectGuid leaderGuid);

    static uint32 const MaxBotsPerLeader = 4;

private:
    void Cleanup();

    std::mutex _lock;
    std::vector<std::weak_ptr<PartyBotSession>> _bots;
    std::set<uint32> _usedAccounts;     // bot accounts given a character this run (the character save is asynchronous)
};

#define sPartyBotMgr PartyBotMgr::instance()

#endif
