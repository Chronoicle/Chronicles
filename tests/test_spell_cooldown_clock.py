"""Run the real cooldown save method with fake clocks/DB; requires g++."""
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / 'src/server/game/Entities/Player/Player.cpp').read_text()
def method(name):
    start = source.index('void Player::' + name + '(')
    end = source.index('\n}\n', start) + 3
    return source[start:end]

save = method('_SaveSpellCooldowns')
load = method('_LoadSpellCooldowns')
history = method('SendSpellHistoryData')
assert 'double curTime = getPreciseTime();' in history
# Compile the actual load deadline expression alongside the actual save method.
load_expr = load.split('AddSpellCooldown(spell_id, item_id, ', 1)[1].split(';', 1)[0][:-1]
program = r'''
#include <cassert>
#include <cmath>
#include <cstdint>
#include <ctime>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using uint32 = uint32_t;
using uint64 = uint64_t;
double steadyNow = 100000.25;
time_t wallNow = 1790460000;
double getPreciseTime() { return steadyNow; }
namespace GameTime { time_t GetGameTime() { return wallNow; } }
constexpr double infinityCooldownDelayCheck = 1296000;
constexpr int CHAR_DEL_CHAR_SPELL_COOLDOWN = 1;
struct CharacterDatabasePreparedStatement { void setUInt64(int, uint64) {} };
struct Database {
    CharacterDatabasePreparedStatement stmt;
    auto GetPreparedStatement(int) { return &stmt; }
} CharacterDatabase;
struct Transaction {
    std::vector<std::string> sql;
    Transaction* operator->() { return this; }
    void Append(CharacterDatabasePreparedStatement*) {}
    void Append(char const* s) { sql.emplace_back(s); }
};
using CharacterDatabaseTransaction = Transaction;
struct Cooldown { double end; uint32 itemid; };
using SpellCooldowns = std::map<uint32, Cooldown>;
struct Player {
    SpellCooldowns m_spellCooldowns;
    uint64 GetGUIDLow() { return 1; }
    void _SaveSpellCooldowns(CharacterDatabaseTransaction&);
};
'''
program += save
program += '\ndouble loadDeadline(time_t db_time, time_t curTime) { return ' + load_expr + '; }\n'
program += r'''
int main() {
    Player p;
    p.m_spellCooldowns = {{642, {steadyNow + 240, 0}}, {1, {steadyNow - 1, 0}},
                          {2, {steadyNow + 2592000, 0}}, {3, {steadyNow + .2, 0}}};
    Transaction t;
    p._SaveSpellCooldowns(t);
    assert(p.m_spellCooldowns.count(642) == 1); // autosave must not erase Divine Shield
    assert(p.m_spellCooldowns.count(1) == 0); // expired spell removed
    assert(p.m_spellCooldowns.count(2) == 1); // on-hold spell retained, not persisted
    assert(t.sql.size() == 1);
    assert(t.sql[0].find("(1,642,0,1790460240)") != std::string::npos);
    assert(t.sql[0].find("(1,3,0,1790460001)") != std::string::npos);
    assert(t.sql[0].find("(1,2,") == std::string::npos);
    steadyNow = 42; // restart changes monotonic epoch; 60 seconds elapsed offline
    assert(loadDeadline(1790460240, 1790460060) == 222);
    p.m_spellCooldowns[642].end = 222;
    wallNow = 1790460060;
    Transaction again;
    p._SaveSpellCooldowns(again);
    assert(p.m_spellCooldowns.count(642) == 1);
    assert(again.sql[0].find("(1,642,0,1790460240)") != std::string::npos);
}
'''
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp)
    (path / 'check.cpp').write_text(program)
    subprocess.run(['g++', '-std=c++20', str(path / 'check.cpp'), '-o', str(path / 'check')], check=True)
    subprocess.run([str(path / 'check')], check=True)
print('PASS: autosave retention, expiration, on-hold exclusion, fractional expiry, restart/load round trip')
