CREATE FUNCTION @extschema@.dump_partitioned_table_definition(
    p_parent_table text,
    p_ignore_template_table boolean DEFAULT false
)
    RETURNS text
    LANGUAGE PLPGSQL STABLE
    AS $$
DECLARE
    v_create_parent_definition text;
    v_update_part_config_definition text;
    -- Columns from part_config table.
    v_parent_table text; -- NOT NULL
    v_control text; -- NOT NULL
    v_partition_type text; -- NOT NULL
    v_partition_interval text; -- NOT NULL
    v_constraint_cols TEXT[];
    v_premake integer; -- NOT NULL
    v_optimize_constraint integer; -- NOT NULL
    v_epoch text; -- NOT NULL
    v_retention text;
    v_retention_schema text;
    v_retention_keep_index boolean;
    v_retention_keep_table boolean; -- NOT NULL
    v_infinite_time_partitions boolean; -- NOT NULL
    v_datetime_string text;
    v_automatic_maintenance text; -- NOT NULL
    v_jobmon boolean; -- NOT NULL
    v_sub_partition_set_full boolean; -- NOT NULL
    v_template_table text;
    v_inherit_privileges boolean; -- DEFAULT false
    v_constraint_valid boolean; -- DEFAULT true NOT NULL
    v_ignore_default_data boolean; -- DEFAULT false NOT NULL
    v_date_trunc_interval text;
    v_maintenance_order int;
    v_retention_keep_publication boolean;
    v_parent_schemaname text;
    v_parent_tablename text;
    v_default_exists boolean;
    v_default_tablename text;
    v_sql text;
    v_notnull boolean;
BEGIN
    SELECT
        pc.parent_table,
        pc.control,
        pc.partition_type,
        pc.partition_interval,
        pc.constraint_cols,
        pc.premake,
        pc.optimize_constraint,
        pc.epoch,
        pc.retention,
        pc.retention_schema,
        pc.retention_keep_index,
        pc.retention_keep_table,
        pc.infinite_time_partitions,
        pc.datetime_string,
        pc.automatic_maintenance,
        pc.jobmon,
        pc.sub_partition_set_full,
        pc.template_table,
        pc.inherit_privileges,
        pc.constraint_valid,
        pc.ignore_default_data,
        pc.date_trunc_interval,
        pc.maintenance_order,
        pc.retention_keep_publication
    INTO
        v_parent_table,
        v_control,
        v_partition_type,
        v_partition_interval,
        v_constraint_cols,
        v_premake,
        v_optimize_constraint,
        v_epoch,
        v_retention,
        v_retention_schema,
        v_retention_keep_index,
        v_retention_keep_table,
        v_infinite_time_partitions,
        v_datetime_string,
        v_automatic_maintenance,
        v_jobmon,
        v_sub_partition_set_full,
        v_template_table,
        v_inherit_privileges,
        v_constraint_valid,
        v_ignore_default_data,
        v_date_trunc_interval,
        v_maintenance_order,
        v_retention_keep_publication
    FROM @extschema@.part_config pc
    WHERE pc.parent_table = p_parent_table;

    IF v_parent_table IS NULL THEN
        RAISE EXCEPTION 'Given parent table not found in pg_partman configuration table: %', p_parent_table;
    END IF;

    IF p_ignore_template_table THEN
        v_template_table := NULL;
    END IF;

    SELECT schemaname, tablename
    INTO v_parent_schemaname, v_parent_tablename
    FROM pg_catalog.pg_tables
    WHERE schemaname = split_part(p_parent_table, '.', 1)::name
    AND tablename = split_part(p_parent_table, '.', 2)::name;

    -- Check to see if table has a default
    v_sql := format('SELECT c.relname
            FROM pg_catalog.pg_inherits h
            JOIN pg_catalog.pg_class c ON c.oid = h.inhrelid
            JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
            WHERE h.inhparent = ''%I.%I''::regclass
            AND pg_get_expr(relpartbound, c.oid) = ''DEFAULT'''
        , v_parent_schemaname
        , v_parent_tablename);

    EXECUTE v_sql INTO v_default_tablename;
    IF v_default_tablename IS NOT NULL THEN
        v_default_exists := true;
    ELSE
        v_default_exists := false;
    END IF;

    SELECT attnotnull INTO v_notnull
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relname = v_parent_tablename::name
    AND n.nspname = v_parent_schemaname::name
    AND a.attname = v_control::name;

    v_create_parent_definition := format(
E'SELECT @extschema@.create_parent(
\tp_parent_table := %L,
\tp_control := %L,
\tp_interval := %L,
\tp_type := %L,
\tp_epoch := %L,
\tp_premake := %s,
\tp_default_table := %L,
\tp_automatic_maintenance := %L,
\tp_constraint_cols := %L,
\tp_template_table := %L,
\tp_jobmon := %L,
\tp_date_trunc_interval := %L,
\tp_control_not_null := %L
);',
            v_parent_table,
            v_control,
            v_partition_interval,
            v_partition_type,
            v_epoch,
            v_premake,
            v_default_exists,
            v_automatic_maintenance,
            v_constraint_cols,
            v_template_table,
            v_jobmon,
            v_date_trunc_interval,
            v_notnull
        );

    v_update_part_config_definition := format(
E'UPDATE @extschema@.part_config SET
\toptimize_constraint = %s,
\tretention = %L,
\tretention_schema = %L,
\tretention_keep_index = %L,
\tretention_keep_table = %L,
\tinfinite_time_partitions = %L,
\tdatetime_string = %L,
\tsub_partition_set_full = %L,
\tinherit_privileges = %L,
\tconstraint_valid = %L,
\tignore_default_data = %L,
\tmaintenance_order = %L,
\tretention_keep_publication = %L
WHERE parent_table = %L;',
        v_optimize_constraint,
        v_retention,
        v_retention_schema,
        v_retention_keep_index,
        v_retention_keep_table,
        v_infinite_time_partitions,
        v_datetime_string,
        v_sub_partition_set_full,
        v_inherit_privileges,
        v_constraint_valid,
        v_ignore_default_data,
        v_maintenance_order,
        v_retention_keep_publication,
        v_parent_table
    );

    RETURN concat_ws(E'\n',
        v_create_parent_definition,
        v_update_part_config_definition
    );
END
$$;
