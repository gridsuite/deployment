-- Delete script filter elements from directory database
DELETE FROM directory.element
WHERE id IN (SELECT id FROM actions.script_contingency_list);
