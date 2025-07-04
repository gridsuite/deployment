-- Delete script filter elements from directory database
DELETE FROM directory.element
WHERE id IN (SELECT id FROM filters.script_filter);