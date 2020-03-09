#!/bin/bash

set -e
## Setup the test

cat `dirname ${0}`/countries.sql

cat <<END
drop table if exists test_runs;
drop table if exists test_run_queries;

-- 
-- Info about test runs
-- 
create table test_runs (
  table_size   int,
  varchar_size int,
  test_ts      timestamp,
  test_time_ms bigint,
  sort_merge_passes varchar(255)
);


-- Individual queries that are ran as part of the test
create table test_run_queries (
  table_size   int,
  varchar_size int,
  test_ts      timestamp,
  test_time_ms bigint,
  sort_merge_passes int
);
END

###


for table_size in 100000 500000 1000000 2000000 4000000 8000000 ; do
# 16000000 #32000000
# if 

for varchar_size in 50 100 150 200 250 ; do

rand_table_name="t_rand_${table_size}_${varchar_size}"
test_table_name="t_char_${table_size}_${varchar_size}"

cat <<END
set @n_countries=(select count(*) from Country) - 1;

drop table if exists $rand_table_name;
create table $rand_table_name (a int) engine=myisam;

drop table if exists $test_table_name;
create table $test_table_name (
  char_field varchar($varchar_size) character set utf8, b int
) engine=myisam;

insert into $rand_table_name select 1+floor(rand() * @n_countries) from seq_1_to_$table_size;
insert into $test_table_name
select
  (select Name from Country where id=T.a), 1234
from $rand_table_name T ;

drop table $rand_table_name;
analyze table $test_table_name;
END

for i in 1 2 3 4 5 6 7 8 9 10 ; do

### query_start.sql here:
cat <<END
select variable_value into @query_start_smp from information_schema.session_status where variable_name like 'sort_merge_passes';
select current_timestamp(6) into @query_start_time;
END
###

### THE QUERY:

TEST_NAME="group-by-sort-$table_size"

#QUERY="select a, b from t_int_$size order by a limit 100;"
QUERY="select char_field, count(distinct b) from $test_table_name group by char_field;"

echo $QUERY

### query-end.sql here:
cat << END
set @test_name='$TEST_NAME';
set @query_time_ms= timestampdiff(microsecond, @query_start_time, current_timestamp(6))/1000;
select variable_value into @query_end_smp from information_schema.session_status where variable_name like 'sort_merge_passes';
set @query_merge_passes = @query_end_smp - @query_start_smp;
insert into test_run_queries
         (table_size, varchar_size, test_ts, test_time_ms, sort_merge_passes)
  values ($table_size, $varchar_size, @query_start_time, @query_time_ms, @query_merge_passes);
END

done

# Summarize results from multiple runs of one query:
cat <<END
set @min_time = (select min(test_time_ms) from test_run_queries 
                 where table_size=$table_size and varchar_size=$varchar_size);
set @sort_buffers= (select group_concat(distinct sort_merge_passes) from test_run_queries 
                    where table_size=$table_size and varchar_size=$varchar_size);
insert into test_runs(table_size, varchar_size, test_ts, test_time_ms, sort_merge_passes) values
  ($table_size, $varchar_size, current_timestamp(6), @min_time, @sort_buffers);
drop table $test_table_name;
END

done

done


