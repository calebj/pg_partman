-- ########## TIME WEEKLY EPOCH TESTS ##########
-- Other tests:
    -- combination of start_partition & constraint_cols/optimize_constraint. Requires manually running apply_constraint to set other old partitions
    -- Test millisecond epoch time partitioning

\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true

BEGIN;
SELECT set_config('search_path','partman, public',false);

SELECT plan(68);
CREATE SCHEMA partman_test;
CREATE SCHEMA partman_retention_test;

CREATE TABLE partman_test.time_taptest_table (
    col1 bigint
    , col2 text
    , col3 bigint NOT NULL DEFAULT (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP))::bigint)*1000)
    PARTITION BY RANGE (col3);
CREATE TABLE partman_test.template_time_taptest_table (LIKE partman_test.time_taptest_table);
ALTER TABLE partman_test.template_time_taptest_table ADD PRIMARY KEY (col1);

CREATE TABLE partman_test.undo_taptest (LIKE partman_test.time_taptest_table INCLUDING ALL);

SELECT create_parent('partman_test.time_taptest_table'
    , 'col3'
    , '1 week'
    , p_constraint_cols => '{"col1"}'
    , p_epoch => 'milliseconds'
    , p_premake => 2
    , p_start_partition => to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYY-MM-DD HH24:MI:SS')
    , p_template_table => 'partman_test.template_time_taptest_table'
);

INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(1,10), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '8 weeks'::interval)::bigint)*1000);

SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP), 'YYYYMMDD'), 'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP), 'YYYYMMDD')||' exists');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD')||' exists (+1 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'2 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'2 weeks'::interval, 'YYYYMMDD')||' exists (+2 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'5 weeks'::interval, 'YYYYMMDD')||' does not exist (+3 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD')||' exists (-1 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD')||' exists (-2 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD')||' exists (-3 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD')||' exists (-4 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD')||' exists (-5 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD')||' exists (-6 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD')||' exists (-7 weeks)');
SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD')||' exists (-8 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'9 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'9 weeks'::interval, 'YYYYMMDD')||' does not exist (-9 weeks)');

SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP), 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP), 'YYYYMMDD'));
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD')||' (+1 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'2 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'2 weeks'::interval, 'YYYYMMDD')||' (+2 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD')||' (-1 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD')||' (-2 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD')||' (-3 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD')||' (-4 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD')||' (-5 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD')||' (-6 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD')||' (-7 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD')||' (-8 weeks)');

SELECT is_empty('SELECT * FROM partman_test.time_taptest_table_default', 'Check that default table no data');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table', ARRAY[10], 'Check count from parent table');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP) - '8 weeks'::interval, 'YYYYMMDD'),
    ARRAY[10], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD')||' (-8 weeks)');

INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(11,20), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '7 weeks'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(21,25), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '6 weeks'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(26,30), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '5 weeks'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(31,37), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '4 week'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(38,49), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '3 week'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(50,70), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '2 weeks'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(71,85), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) - '1 week'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(86,100), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) + '1 week'::interval)::bigint)*1000);
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(101,110), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) + '2 weeks'::interval)::bigint)*1000);

SELECT is_empty('SELECT * FROM ONLY partman_test.time_taptest_table', 'Check that parent table has had no data inserted to it');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'),
    ARRAY[10], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD')||' (-7 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'),
    ARRAY[5], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD')||' (-6 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'),
    ARRAY[5], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD')||' (-5 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD'),
    ARRAY[7], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD')||' (-4 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'),
    ARRAY[12], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD')||' (-3 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD'),
    ARRAY[21], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD')||' (-2 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD'),
    ARRAY[15], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD')||' (-1 weeks)');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD'),
    ARRAY[15], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD')||' (+1 weeks)');

-- Default optimize_constraint is 30, so set it to a value that will trigger it to work for given conditions of this partition set
UPDATE part_config SET premake = 3, optimize_constraint = 5 WHERE parent_table = 'partman_test.time_taptest_table';
SELECT run_maintenance();

-- With an optimize_constraint value of 5, the automatic run of apply_constraints due to run_maintenance will put constraint on the child table that is 6 weeks behind the newest data (data two weeks ahead inserted above, so 4 weeks behind now()).
SELECT col_has_check('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD'), 'col1'
    , 'Check for additional constraint on col1 on time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD')||' (-4 weeks)');
-- Must run apply_constraints() to manually set the other older constraints

SELECT apply_constraints('partman_test.time_taptest_table', 'partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD'));
SELECT apply_constraints('partman_test.time_taptest_table', 'partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'));
SELECT apply_constraints('partman_test.time_taptest_table', 'partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'));
SELECT apply_constraints('partman_test.time_taptest_table', 'partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'));
SELECT col_has_check('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD'), 'col1'
    , 'Check for additional constraint on col1 on time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD'));
SELECT col_has_check('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'), 'col1'
    , 'Check for additional constraint on col1 on time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'));
SELECT col_has_check('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'), 'col1'
    , 'Check for additional constraint on col1 on time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'));
SELECT col_has_check('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'), 'col1'
    , 'Check for additional constraint on col1 on time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'));

INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(111,120), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) + '3 weeks'::interval)::bigint)*1000);

SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD')||' exists (+3 weeks');
-- Cannot test for next week not existing. Different lengths of months will sometimes cause an extra partition.
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD')||' (+3 weeks)');

SELECT is_empty('SELECT * FROM ONLY partman_test.time_taptest_table', 'Check that parent table has had no data inserted to it');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD'),
    ARRAY[10], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD')||' (+3 weeks)');

UPDATE part_config SET premake = 4 WHERE parent_table = 'partman_test.time_taptest_table';
SELECT run_maintenance();
INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(121,130), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) + '4 weeks'::interval)::bigint)*1000);

SELECT is_empty('SELECT * FROM partman_test.time_taptest_table_default', 'Check that default table has had no data inserted to it');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table', ARRAY[130], 'Check count from parent table');
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD'),
    ARRAY[10], 'Check count from time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD')||' (+4 weeks)');
SELECT col_has_check('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'), 'col1'
    , 'Check for additional constraint on col1 on time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'));

SELECT has_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD')||' exists (+4 weeks)');
SELECT col_is_pk('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD'), ARRAY['col1'],
    'Check for primary key in time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD')||' (+4 weeks)');

INSERT INTO partman_test.time_taptest_table (col1, col3) VALUES (generate_series(200,210), (extract('epoch' from date_trunc('week',CURRENT_TIMESTAMP) + '20 weeks'::interval)::bigint)*1000);
SELECT results_eq('SELECT count(*)::int FROM partman_test.time_taptest_table_default', ARRAY[11], 'Check that data outside scope goes to default');

SELECT drop_partition_time('partman_test.time_taptest_table', '3 weeks', p_keep_table := false);
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'4 weeks'::interval, 'YYYYMMDD')||' does not exist (-4 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'5 weeks'::interval, 'YYYYMMDD')||' does not exist (-5 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'6 weeks'::interval, 'YYYYMMDD')||' does not exist (-6 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'7 weeks'::interval, 'YYYYMMDD')||' does not exist (-7 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'8 weeks'::interval, 'YYYYMMDD')||' does not exist (-8 weeks)');

UPDATE part_config SET retention = '2 weeks'::interval WHERE parent_table = 'partman_test.time_taptest_table';
SELECT drop_partition_time('partman_test.time_taptest_table', p_retention_schema := 'partman_retention_test');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD')||' does not exist (-3 weeks)');
SELECT has_table('partman_retention_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'3 weeks'::interval, 'YYYYMMDD')||' got moved to new schema (-3 weeks)');

SELECT undo_partition('partman_test.time_taptest_table', p_loop_count => 20, p_keep_table => false, p_target_table => 'partman_test.undo_taptest');
SELECT results_eq('SELECT count(*)::int FROM ONLY partman_test.undo_taptest', ARRAY[92], 'Check count from undo table after undo');
SELECT is_empty('SELECT * FROM partman_test.time_taptest_table', 'Check that parent table no data');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP), 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP), 'YYYYMMDD')||' does not exist (now)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'1 week'::interval, 'YYYYMMDD')||' does not exist (+1 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'2 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'2 weeks'::interval, 'YYYYMMDD')||' does not exist (+2 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'3 weeks'::interval, 'YYYYMMDD')||' does not exist (+3 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)+'4 weeks'::interval, 'YYYYMMDD')||' does not exist (+4 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'1 week'::interval, 'YYYYMMDD')||' does not exist (-1 weeks)');
SELECT hasnt_table('partman_test', 'time_taptest_table_p'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD'),
    'Check time_taptest_table_'||to_char(date_trunc('week',CURRENT_TIMESTAMP)-'2 weeks'::interval, 'YYYYMMDD')||' does not exist (-2 weeks)');

SELECT * FROM finish();
ROLLBACK;
