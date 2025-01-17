CREATE FUNCTION @extschema@.show_partition_info(
    p_child_table text
    , p_partition_interval text DEFAULT NULL
    , p_parent_table text DEFAULT NULL
    , OUT child_start_time timestamptz
    , OUT child_end_time timestamptz
    , OUT child_start_id bigint
    , OUT child_end_id bigint
    , OUT suffix text
)
    RETURNS record
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE

v_child_schema          text;
v_child_tablename       text;
v_control               text;
v_control_type          text;
v_time_encoder          text;
v_time_decoder          text;
v_epoch                 text;
v_exact_control_type    text;
v_parent_table          text;
v_partstrat             char;
v_partition_interval    text;
v_start_string          text;

BEGIN
/*
 * Show the data boundaries for a given child table as well as the suffix that will be used.
 * Passing the parent table argument slightly improves performance by avoiding a catalog lookup.
 * Passing an interval lets you set one different than the default configured one if desired.
 */

SELECT time_encoder, time_decoder
INTO v_time_encoder, v_time_decoder
FROM @extschema@.part_config
WHERE parent_table = p_parent_table;

SELECT n.nspname, c.relname INTO v_child_schema, v_child_tablename
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = split_part(p_child_table, '.', 1)::name
AND c.relname = split_part(p_child_table, '.', 2)::name;

IF v_child_tablename IS NULL THEN
    IF p_parent_table IS NOT NULL THEN
        RAISE EXCEPTION 'Child table given does not exist (%) for given parent table (%)', p_child_table, p_parent_table;
    ELSE
        RAISE EXCEPTION 'Child table given does not exist (%)', p_child_table;
    END IF;
END IF;

IF p_parent_table IS NULL THEN
    SELECT n.nspname||'.'|| c.relname INTO v_parent_table
    FROM pg_catalog.pg_inherits h
    JOIN pg_catalog.pg_class c ON c.oid = h.inhparent
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE h.inhrelid::regclass = p_child_table::regclass;
ELSE
    v_parent_table := p_parent_table;
END IF;

SELECT p.partstrat INTO v_partstrat
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
JOIN pg_catalog.pg_partitioned_table p ON c.oid = p.partrelid
WHERE n.nspname = split_part(v_parent_table, '.', 1)::name
AND c.relname = split_part(v_parent_table, '.', 2)::name;

IF p_partition_interval IS NULL THEN
    SELECT control, partition_interval, epoch
    INTO v_control, v_partition_interval, v_epoch
    FROM @extschema@.part_config WHERE parent_table = v_parent_table;
ELSE
    v_partition_interval := p_partition_interval;
    SELECT control, epoch
    INTO v_control, v_epoch
    FROM @extschema@.part_config WHERE parent_table = v_parent_table;
END IF;

IF v_control IS NULL THEN
    RAISE EXCEPTION 'Parent table of given child not managed by pg_partman: %', v_parent_table;
END IF;

SELECT general_type, exact_type INTO v_control_type, v_exact_control_type FROM @extschema@.check_control_type(v_child_schema, v_child_tablename, v_control);

RAISE DEBUG 'show_partition_info: v_child_schema: %, v_child_tablename: %, v_control_type: %, v_exact_control_type: %',
            v_child_schema, v_child_tablename, v_control_type, v_exact_control_type;

-- Look at actual partition bounds in catalog and pull values from there.
IF v_partstrat = 'r' THEN
    SELECT (regexp_match(pg_get_expr(c.relpartbound, c.oid, true)
        , $REGEX$\(([^)]+)\) TO \(([^)]+)\)$REGEX$))[1]::text
    INTO v_start_string
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relname = v_child_tablename
    AND n.nspname = v_child_schema;
ELSIF v_partstrat = 'l' THEN
    SELECT (regexp_match(pg_get_expr(c.relpartbound, c.oid, true)
        , $REGEX$FOR VALUES IN \(([^)]+)\)$REGEX$))[1]::text
    INTO v_start_string
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relname = v_child_tablename
    AND n.nspname = v_child_schema;
ELSE
    RAISE EXCEPTION 'partman functions only work with list partitioning with integers and ranged partitioning with time or integers. Found partition strategy "%" for given partition set', v_partstrat;
END IF;

IF v_control_type IN ('time', 'text', 'uuid') OR (v_control_type = 'id' AND v_epoch <> 'none') THEN

    IF v_control_type = 'time' THEN
        child_start_time := v_start_string::timestamptz;
    ELSIF v_control_type IN ('text', 'uuid') THEN
        EXECUTE format('SELECT %s(%s)', v_time_decoder, v_start_string) INTO child_start_time;
    ELSIF (v_control_type = 'id' AND v_epoch <> 'none') THEN
        -- bigint data type is stored as a single-quoted string in the partition expression. Must strip quotes for valid type-cast.
        v_start_string := trim(BOTH '''' FROM v_start_string);
        IF v_epoch = 'seconds' THEN
            child_start_time := to_timestamp(v_start_string::double precision);
        ELSIF v_epoch = 'milliseconds' THEN
            child_start_time := to_timestamp((v_start_string::double precision) / 1000);
        ELSIF v_epoch = 'microseconds' THEN
            child_start_time := to_timestamp((v_start_string::double precision) / 1000000);
        ELSIF v_epoch = 'nanoseconds' THEN
            child_start_time := to_timestamp((v_start_string::double precision) / 1000000000);
        END IF;
    ELSE
        RAISE EXCEPTION 'Unexpected code path in show_partition_info(). Please report this bug with the configuration that lead to it.';
    END IF;

    child_end_time := (child_start_time + v_partition_interval::interval);

    SELECT to_char(base_timestamp, datetime_string)
    INTO suffix
    FROM @extschema@.calculate_time_partition_info(v_partition_interval::interval, child_start_time);

ELSIF v_control_type = 'id' THEN

    IF v_exact_control_type IN ('int8', 'int4', 'int2') THEN
        -- Have to do a trim here because of inconsistency in quoting different integer types. Ex: bigint boundary values are quoted but int values are not
        child_start_id := trim(BOTH $QUOTE$''$QUOTE$ FROM v_start_string)::bigint;
    ELSIF v_exact_control_type = 'numeric' THEN
        -- cast to numeric then trunc to get rid of decimal without rounding
        child_start_id := trunc(trim(BOTH $QUOTE$''$QUOTE$ FROM v_start_string)::numeric)::bigint;
    END IF;

    child_end_id := (child_start_id + v_partition_interval::bigint) - 1;

ELSE
    RAISE EXCEPTION 'Invalid partition type encountered in show_partition_info()';
END IF;

RETURN;

END
$$;
