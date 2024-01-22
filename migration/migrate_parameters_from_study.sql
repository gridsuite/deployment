/*
 * Run command:
 * $ psql --host=host_name --port=5432 --username=user_name --dbname=database_name --echo-errors --expanded=auto --single-transaction --command='\conninfo' --command='\encoding utf-8' --file=file.sql --log-file=migrate_parameters.log
 *
 * How to rollback in case of error?
 * There is multiples migrations done by this script (se "migrate" variable),
 *  so only rollback the migration who failed.
 * If it failed at the end of the script, check before if there wasn't non-rollback-able update/delete!
 *  If you're not sure, ask GridSuite devs or read this script in detail.
 * To rollback a single migration who failed up to around half way:
 *   $ truncate table <to_schema>.<to_table>
 *   $ update study.study set <from_old_id>=coalesce(<from_old_id>, <from_new_uuid>), <from_new_uuid>=null
 */
/* Dev notes:
 * Because json functions to extract list of elements from array or object return a setof, which isn't usable from for & foreach loops,
 *  we use tricks by casting into text and treating it and re-casting it to json array.
 */
DO
$body$
<<fn>>
DECLARE
    study_name text := quote_ident('study');
    migrate constant jsonb[] := array[
        /* Config format:
         *   - from_table (string): source table name
         *   - to_schema (string): destination database/schema (depends if multi-database/schema structure)
         *   - to_table (string): destination table name
         *   - from_old_id (string): source table old entity ID column name
         *   - from_new_uuid (string): source table new UUID column name
         *   - additional_tables (array[object]): additional tables to copy
         *       - from_table (string): source table name
         *       - to_table (string): destination table name
         */
        '{"from_table": "short_circuit_parameters", "from_old_id": "short_circuit_parameters_entity_id", "from_new_uuid": "short_circuit_parameters_uuid", "to_schema": "shortcircuit", "to_table": "analysis_parameters", "additional_tables": []}'
    ];
    params jsonb;
    additional_table jsonb;
    additional_first bool;
    path_from text;
    path_to text;
    remote_databases bool;
    insert_columns text;
    rows_affected integer;
    err_returned_sqlstate text;
    err_column_name text;
    err_constraint_name text;
    err_pg_datatype_name text;
    err_message_text text;
    err_table_name text;
    err_schema_name text;
    err_pg_exception_detail text;
    err_pg_exception_hint text;
    err_pg_exception_context text;
BEGIN
    --lock table study in exclusive mode;
    raise log 'Script starting at %', now();
    raise log 'user=%, db=%, schema=%', current_user, current_database(), current_schema();

    /* Case OPF: copy from db.study.<table> to db.<service>.<table> (easy, no problem to migrate)
     * Case localdev & Azure: copy from study.public.<table> to <service>.public.<table> (need to copy between databases...)
     *   [0A000] cross-database references are not implemented: "ref.to.remote.table"
     */
    if exists(SELECT nspname FROM pg_catalog.pg_namespace where nspname = fn.study_name) then
        raise notice 'multi schemas structure detected';
        if current_schema() != study_name then
            raise exception 'Invalid current schema "%"', current_schema() using hint='Assuming script launch at "'||study_name||'.*"', errcode='invalid_schema_name';
        end if;
        remote_databases := false;
    elsif exists(SELECT datname FROM pg_catalog.pg_database WHERE datistemplate = false and datname = fn.study_name) then
        raise notice 'separate databases structure detected';
        if current_database() != study_name then
            raise exception 'Invalid current database "%"', current_database() using hint='Assuming script launch at "'||study_name||'.*.*"', errcode='invalid_database_definition';
        end if;
        remote_databases := true;
        create extension if not exists postgres_fdw;
    else
        raise exception 'Can''t detect type of database' using
            hint='Is it the good database?',
            errcode='invalid_database_definition',
            detail='Can''t find schema nor database "study" from current session, use to determine the database structure.';
    end if;

    foreach params in array migrate loop
        raise debug 'migration data = %', params;
        /*Note: quote_indent() ⇔ %I ≠ quote_literal() ⇔ %L */
        begin

            if remote_databases then
                execute format('create server if not exists %s foreign data wrapper postgres_fdw options (dbname %L)', concat('lnk_', params->>'to_schema'), params->>'to_schema');
                execute format('create user mapping if not exists for %s server %s options (user %L)', current_user, concat('lnk_', params->>'to_schema'), current_user);
            else
                study_name := concat(study_name, '.', study_name); --study server use same name for schema and table name
            end if;


            additional_first := true;
            foreach additional_table in array array_prepend(format('{"from_table": %s, "to_table": %s}', params->'from_table', params->'to_table'),
                                                            array_remove(string_to_array(replace(replace(trim(both '[]' from (params->'additional_tables')::text), '}, {', '}\n{'), '},{', '}\n{'), '\n', ''), null)
                                                           )::jsonb[] loop
                raise debug 'debug additional table = %', additional_table;

                if remote_databases then
                    -- rename for potential conflict with foreign table name
                    execute format('alter table %I rename to %I', additional_table->>'to_table', concat(additional_table->>'to_table', '_old'));

                    execute format('import foreign schema %I limit to (%I) from server %s into %I', 'public', additional_table->>'to_table', concat('lnk_', params->>'to_schema'), 'public');
                    path_from := concat(quote_ident('public'), '.', quote_ident(additional_table->>'from_table'));
                    path_to := concat('public.', quote_ident(additional_table->>'to_table'));
                    execute format('select string_agg(attname, '','') from pg_attribute where attnum >=1 and attrelid = (select ft.ftrelid' ||
                                   ' from pg_foreign_table ft left join pg_foreign_server fs on ft.ftserver=fs.oid left join pg_foreign_data_wrapper fdw on fs.srvfdw = fdw.oid left join pg_roles on pg_roles.oid=fdw.fdwowner' ||
                                   ' where pg_roles.rolname=current_user and fdw.fdwname=%L and fs.srvname=%L limit 1)', 'postgres_fdw', concat('lnk_', additional_table->>'to_schema')) --and ftoptions like '%tablename=...%'
                    into insert_columns; --[...] ; there isn't oid cast for foreign tables
                    raise notice 'insert_columns=%', insert_columns;
                    if insert_columns is null then --the create&import commands don't raise an exception if something isn't right...
                        raise exception 'A silent problem seem to happen during the connection to the remote database' using errcode = 'fdw_error', hint='Check if the server is created and the table imported';
                    end if;
                else
                    path_from := concat(study_name, '.', quote_ident(additional_table->>'from_table'));
                    path_to := concat(quote_ident(params->>'to_schema'), '.', quote_ident(additional_table->>'to_table'));
                    execute format('select string_agg(attname, '','') from pg_attribute where attrelid = %L::regclass and attnum >=1', path_to)
                    into insert_columns; --columns order may be different between src & dst tables
                end if;
                raise debug 'table locations: study=% src="%" dst="%"', study_name, path_from, path_to;

                raise notice 'copy data from % to %', path_from, path_to;
                execute format('insert into %s(%s) select %s from %s', path_to, insert_columns, insert_columns, path_from); --... on conflict do nothing/update
                get current diagnostics rows_affected = row_count;
                raise info 'Copied % items from % to %', rows_affected, path_from, path_to;

                if additional_first then
                    additional_first := false;
                    execute format('update %s set %I=%I, %I=null', study_name, params->>'from_new_uuid', params->>'from_old_id', params->>'from_old_id');
                    get current diagnostics rows_affected = row_count;
                    raise info 'Moved % IDs in % from % to %', rows_affected, study_name, params->>'from_old_id', params->>'from_new_uuid';
                end if;

                if remote_databases then
                    execute format('drop foreign table if exists %I.%I cascade', params->>'to_schema', additional_table->>'to_table');
                    execute format('alter table %I rename to %I', concat(additional_table->>'to_table', '_old'), additional_table->>'to_table'); --restore original name
                end if;
            end loop;

            /*execute format('truncate table %s', path_from);
            raise info 'Emptied old table %', path_from;*/

            if remote_databases then
                /*use "drop ... if exist ...", so not need "if remote_databases then ..."*/
                --execute format('drop foreign table if exists %I.%I' cascade, 'public', params[i]->>'to_schema');
                --execute format('drop user mapping if exists for current_user server %s', 'lnk_'||params[i]->>'to_schema');
                execute format('drop server if exists %s cascade', concat('lnk_', params->>'to_schema'));
            end if;

        exception when others then --we don't block the script but alert the admin
            get stacked diagnostics
                err_returned_sqlstate = returned_sqlstate,
                err_column_name = column_name,
                err_constraint_name = constraint_name,
                err_pg_datatype_name = pg_datatype_name,
                err_message_text = message_text,
                err_table_name = table_name,
                err_schema_name = schema_name,
                err_pg_exception_detail = pg_exception_detail,
                err_pg_exception_hint = pg_exception_hint,
                err_pg_exception_context = pg_exception_context;
            raise warning using
                message = err_message_text,
                detail = err_pg_exception_detail,
                errcode = err_returned_sqlstate,
                column = err_column_name,
                constraint = err_constraint_name,
                datatype = err_pg_datatype_name,
                hint = err_pg_exception_hint,
                schema = err_schema_name,
                table = err_table_name;
            raise debug E'--- Call Stack ---\n%', err_pg_exception_context;
        end;
    end loop;
    raise log 'Script finish at %', now();
END;
--anonymous function, so return void
$body$
LANGUAGE plpgsql;
