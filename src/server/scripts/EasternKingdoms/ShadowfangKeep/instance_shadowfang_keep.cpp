#include "shadowfang_keep.h"

DoorData const doorData[] =
{
    {GO_COURTYARD_DOOR, DATA_ASHBURY,   DOOR_TYPE_PASSAGE,  BOUNDARY_NONE},
    {GO_SORCERER_DOOR,  DATA_VALDEN,    DOOR_TYPE_PASSAGE,  BOUNDARY_NONE},
    {GO_ARUGAL_DOOR,    DATA_VALDEN,    DOOR_TYPE_PASSAGE,  BOUNDARY_NONE},
    {GO_ARUGAL_DOOR,    DATA_GODFREY,   DOOR_TYPE_ROOM,     BOUNDARY_NONE},
};

class instance_shadowfang_keep : public InstanceMapScript
{
    public:
        instance_shadowfang_keep() : InstanceMapScript("instance_shadowfang_keep", 33) { }

        InstanceScript* GetInstanceScript(InstanceMap* pMap) const
        {
            return new instance_shadowfang_keep_InstanceMapScript(pMap);
        }

        struct instance_shadowfang_keep_InstanceMapScript : public InstanceScript
        {
            instance_shadowfang_keep_InstanceMapScript(InstanceMap* map) : InstanceScript(map)
            {
                SetHeaders(DataHeader);
                SetBossNumber(EncounterCount);
                LoadDoorData(doorData);
                uiAshburyGUID.Clear();
                uiSilverlaineGUID.Clear();
                uiSpringvaleGUID.Clear();
                uiValdenGUID.Clear();
                uiGodfreyGUID.Clear();
                teamInInstance = 0;
                godfreyIntroDone = false;
                progressApplied = false;
                triggerTimer = 1000;
            };

            void OnPlayerEnter(Player* player) override
            {
                if (!teamInInstance)
                    teamInInstance = player->GetTeam();
                if (!progressApplied)
                {
                    progressApplied = true;
                    ApplyProgress();
                }
            }

            static bool IsAllianceEntry(uint32 entry) { return entry == NPC_IVAR || entry == NPC_GUARD_ALLY; }
            bool IsAlliance() const { return teamInInstance == ALLIANCE; }
            bool IsOwnFaction(uint32 entry) const { return IsAllianceEntry(entry) == IsAlliance(); }

            void ShowStop(uint32 stop, bool show)
            {
                if (show)
                    shownStops.insert(stop);
                else
                    shownStops.erase(stop);

                for (ObjectGuid const& guid : stopMembers[stop])
                    if (Creature* creature = instance->GetCreature(guid))
                        creature->SetPhaseMask(show && IsOwnFaction(creature->GetEntry()) ? 1 : SfkStopMask(stop), true);
            }

            // the stop of a defeated boss (CPP spawns it on the kill; here also after a reload)
            static int32 BossStop(uint32 boss)
            {
                switch (boss)
                {
                    case DATA_ASHBURY:      return STOP_ASHBURY;
                    case DATA_SILVERLAINE:  return STOP_SILVERLAINE;
                    case DATA_SPRINGVALE:   return STOP_SPRINGVALE;
                    case DATA_VALDEN:       return STOP_WALDEN;
                }
                return -1;
            }

            // Horde: the Springvale/Walden troop shows while exactly one of the two is dead
            void UpdateHordeTroop()
            {
                if (IsAlliance())
                    return;
                bool one = (GetBossState(DATA_SPRINGVALE) == DONE) != (GetBossState(DATA_VALDEN) == DONE);
                ShowStop(STOP_SPRINGVALE_WALDEN_H, one && !godfreyIntroDone);
            }

            void ApplyProgress()
            {
                if (GetBossState(DATA_ASHBURY) != DONE)
                    ShowStop(STOP_ENTRANCE, true);

                // latest defeated boss of Ashbury, Silverlaine, Springvale, Walden
                for (int32 boss = DATA_VALDEN; boss >= DATA_ASHBURY; --boss)
                    if (GetBossState(boss) == DONE)
                    {
                        ShowStop(BossStop(boss), true);
                        break;
                    }

                if (GetBossState(DATA_VALDEN) == DONE)
                    ShowStop(STOP_GODFREY_DEAD, true);
                UpdateHordeTroop();
            }

            void OnCreatureCreate(Creature* creature)
            {
                if (!teamInInstance)
                {
                    Map::PlayerList const &players = instance->GetPlayers();
                    if (!players.isEmpty())
                        if (Player* player = players.begin()->getSource())
                            teamInInstance = player->GetTeam();
                }
                if (teamInInstance && !progressApplied)
                {
                    progressApplied = true;
                    ApplyProgress();
                }

                // #179: creature of an escort stop (DB phaseMask = stop mask): remember it, show it if its stop is up and it is of the player's faction
                for (uint32 stop = 0; stop < STOP_COUNT; ++stop)
                    if (creature->GetPhaseMask() == SfkStopMask(stop))
                    {
                        if (std::find(stopMembers[stop].begin(), stopMembers[stop].end(), creature->GetGUID()) == stopMembers[stop].end())
                            stopMembers[stop].push_back(creature->GetGUID());
                        if (shownStops.count(stop) && IsOwnFaction(creature->GetEntry()))
                            creature->SetPhaseMask(1, true);
                        break;
                    }

                switch(creature->GetEntry())
                {
                    case NPC_ASHBURY:
                        uiAshburyGUID = creature->GetGUID();
                        break;
                    case NPC_SILVERLAINE:
                        uiSilverlaineGUID = creature->GetGUID();
                        break;
                    case NPC_SPRINGVALE:
                        uiSpringvaleGUID = creature->GetGUID();
                        break;
                    case NPC_VALDEN:
                        uiValdenGUID = creature->GetGUID();
                        break;
                    case NPC_GODFREY:
                        uiGodfreyGUID = creature->GetGUID();
                        break;
                }
            }

            void OnGameObjectCreate(GameObject* go)
            {
                switch(go->GetEntry())
                {
                    case GO_COURTYARD_DOOR:
                    case GO_SORCERER_DOOR:
                    case GO_ARUGAL_DOOR:
                        AddDoor(go, true);
                        break;
                }
            }

            bool SetBossState(uint32 type, EncounterState state)
            {
                if (!InstanceScript::SetBossState(type, state))
                    return false;

                // #179: each boss kill replaces the previous escort stop by the next one (Horde and Alliance members of the stop: only the player's faction shows)
                if (state == DONE && teamInInstance && type != DATA_GODFREY)
                {
                    for (uint32 stop : { STOP_ENTRANCE, STOP_ASHBURY, STOP_SILVERLAINE, STOP_SPRINGVALE, STOP_OUTSIDE })
                        if (shownStops.count(stop))
                            ShowStop(stop, false);

                    if (BossStop(type) >= 0)
                        ShowStop(BossStop(type), true);
                    if (type == DATA_VALDEN)
                        ShowStop(STOP_GODFREY_DEAD, true);
                    UpdateHordeTroop();
                }
                return true;
            }

            // #179: CPP uses areatriggers (at_sfk_outside_troups, at_sfk_godfrey_intro); no trigger ids here, so a player coming close does it
            void Update(uint32 diff) override
            {
                if (!teamInInstance || godfreyIntroDone)
                    return;

                if (triggerTimer > diff)
                {
                    triggerTimer -= diff;
                    return;
                }
                triggerTimer = 1000;

                Map::PlayerList const& players = instance->GetPlayers();
                for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                {
                    Player* player = itr->getSource();
                    if (!player || !player->IsAlive())
                        continue;

                    // Alliance: after Springvale a troop waits outside
                    if (IsAlliance() && GetBossState(DATA_SPRINGVALE) == DONE && GetBossState(DATA_VALDEN) != DONE && !shownStops.count(STOP_OUTSIDE)
                        && player->GetDistance(-234.0f, 2218.0f, 106.0f) < 40.0f)
                        ShowStop(STOP_OUTSIDE, true);

                    // after Walden: near Godfrey's stairs the Walden troop is replaced by Ivar / Belmont upstairs
                    if (!godfreyIntroDone && GetBossState(DATA_VALDEN) == DONE && player->GetDistance(-165.0f, 2180.0f, 152.0f) < 30.0f)
                    {
                        godfreyIntroDone = true;
                        ShowStop(STOP_WALDEN, false);
                        UpdateHordeTroop();
                        ShowStop(STOP_GODFREY_INTRO, true);
                    }
                }
            }

            uint32 GetData(uint32 type) const override
            {
                if (type == DATA_TEAM)
                    return teamInInstance;

                return 0;
            }

            ObjectGuid GetGuidData(uint32 data) const
            {
                switch (data)
                {
                    case DATA_ASHBURY: return uiAshburyGUID;
                    case DATA_SILVERLAINE: return uiSilverlaineGUID;
                    case DATA_SPRINGVALE: return uiSpringvaleGUID;
                    case DATA_VALDEN: return uiValdenGUID;
                    case DATA_GODFREY: return uiGodfreyGUID;
                }
                return ObjectGuid::Empty;
            }

        private:
            ObjectGuid uiAshburyGUID;
            ObjectGuid uiSilverlaineGUID;
            ObjectGuid uiSpringvaleGUID;
            ObjectGuid uiValdenGUID;
            ObjectGuid uiGodfreyGUID;
            uint32 teamInInstance;
            std::map<uint32, std::vector<ObjectGuid>> stopMembers;
            std::set<uint32> shownStops;
            bool godfreyIntroDone;
            bool progressApplied;
            uint32 triggerTimer;
        };

};


void AddSC_instance_shadowfang_keep()
{
    new instance_shadowfang_keep();
}