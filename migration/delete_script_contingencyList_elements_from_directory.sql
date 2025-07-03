-- Step 1: Delete script filter elements from directory database
DELETE FROM directory.element
WHERE id IN (SELECT id FROM actions.script_contingency_list);

-- Step 2: Drop the actions.script_contingency_list table
DROP TABLE actions.script_contingency_list;
