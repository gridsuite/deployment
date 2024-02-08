/*
 * Run command:
 * multi-database case : $ psql --expanded --echo-errors --single-transaction --command='\conninfo' --command='\encoding utf-8' --file=migrate_parameters_from_study.sql --log-file=migrate_parameters.log "host=host_name user=user_name dbname=study port=5432 options=-csearch_path=public"
 * multi-schema case : $ psql --expanded --echo-errors --single-transaction --command='\conninfo' --command='\encoding utf-8' --file=migrate_parameters_from_study.sql --log-file=migrate_parameters.log "host=host_name user=user_name dbname=database_name port=5432 options=-csearch_path=study"
 *
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
         *   - from_column (string): source table column name to copy
         *   - to_column (string): destination table column name to update
         *   - src_id_column (string): source table column name to match with destination table
         *   - dest_id_column (string): destination table column name to match with source table
         */
        '{"from_table": "study", "to_schema": "loadflow", "to_table": "load_flow_parameters", "from_column": "load_flow_provider", "to_column": "provider", "src_id_column" : "load_flow_parameters_uuid", "dest_id_column" : "id"}'
        --TODO other providers
    ];
    params jsonb;
    path_from text;
    path_to text;
    remote_databases bool;
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
    raise log 'Script % starting at %', 'v1.7', now();
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
            end if;


            raise debug 'debug table input = %', params;

            if remote_databases then
                -- rename for potential conflict with foreign table name
                execute format('alter table if exists %I rename to %I', params->>'to_table', concat(params->>'to_table', '_old'));
                execute format('import foreign schema %I limit to (%I) from server %s into %I', 'public', params->>'to_table', concat('lnk_', params->>'to_schema'), 'public');
                path_from := concat(quote_ident('public'), '.', quote_ident(concat(params->>'from_table')));
                path_to := concat('public.', quote_ident(params->>'to_table'));
            else
                path_from := concat(study_name, '.', quote_ident(params->>'from_table'));
                path_to := concat(quote_ident(params->>'to_schema'), '.', quote_ident(params->>'to_table'));
            end if;
            raise debug 'table locations: study=% src="%" dst="%"', study_name, path_from, path_to;
            raise notice 'copy data from % to %', path_from, path_to;
            execute format('update %s set %s = %s from %s where public.study.load_flow_parameters_uuid = public.load_flow_parameters.id',
							path_to, params->>'to_column', concat(path_from, '.', params->>'from_column'), path_from, concat(path_from, '.', params->>'src_id_column'), concat(path_to, '.', 'dest_id_column')); --... on conflict do nothing/update
            get current diagnostics rows_affected = row_count;
            raise info 'Copied % items from % to %', rows_affected, path_from, path_to;

            if remote_databases then
                execute format('drop foreign table if exists public.%I cascade', params->>'to_table');
                execute format('alter table if exists %I rename to %I', concat(params->>'to_table', '_old'), params->>'to_table'); --restore original name
            end if;

            if remote_databases then
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
