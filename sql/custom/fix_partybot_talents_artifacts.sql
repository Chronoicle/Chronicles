-- Party bots (#65, owner 2026-09-28): talents (world.partybot_talents, from sql/custom/partybot_spells.sql) and full
-- artifacts (every trait, fourth ranks, Concordance of the Legionfall 20) are given at a bot's first login.
-- Apply right before the restart that installs the build: every existing bot runs its first-login setup again at its
-- next login (level, spec, talents, gear set, artifact). Undo: nothing to undo (setup = 1 after that login).
UPDATE characters.partybot_characters SET setup = 0;
