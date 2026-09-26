-- Refs #21: remove the dangling link to nonexistent SmartAI event 2.
UPDATE smart_scripts SET link = 0 WHERE entryorguid = 102788 AND source_type = 0 AND id = 1 AND link = 2;
