-- Step 1: Delete script filter elements from directory database
DELETE FROM directory.element
WHERE id IN (SELECT id FROM filters.script_filter);

-- Step 2: Drop the filters.script_filter table
DROP TABLE filters.script_filter;
