-- Party bots (#65, Claude): .partybot commands (staff). Undo: undo_partybot_commands.sql
DELETE FROM world.command WHERE name IN ('partybot', 'partybot add', 'partybot remove', 'partybot list');
INSERT INTO world.command (name, security, help) VALUES
('partybot', 2, 'Syntax: .partybot add|remove|list\n\nParty bots: characters of another account that join your group.'),
('partybot add', 2, 'Syntax: .partybot add $character\n\nA character of another (offline) account logs in as a party bot and joins your group.'),
('partybot remove', 2, 'Syntax: .partybot remove [$character]\n\nDismiss one of your party bots, or all of them.'),
('partybot list', 2, 'Syntax: .partybot list\n\nYour party bots.');
DELETE FROM world.command WHERE name = 'partybot create';
INSERT INTO world.command (name, security, help) VALUES
('partybot create', 2, 'Syntax: .partybot create $class $spec | all\n\nA party bot character on a free partybot account, your faction. all = one per spec that has none yet.');
UPDATE world.command SET help = 'Syntax: .partybot add $name|tank|healer|dps|$spec|$class\n\nA party bot joins your group.' WHERE name = 'partybot add';
