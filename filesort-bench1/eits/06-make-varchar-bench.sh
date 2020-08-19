#!/bin/bash

## Setup the test

cat `dirname ${0}`/names.sql

cat <<END
drop table if exists test_runs;
drop table if exists test_run_queries;

-- 
-- Info about test runs
-- 
create table test_runs (
  test_name    varchar(255),
  test_ts      timestamp,
  test_time_ms bigint,
  sort_merge_passes varchar(255)
);


-- Individual queries that are ran as part of the test
create table test_run_queries (
  test_name    varchar(255),
  test_ts      timestamp,
  test_time_ms bigint,
  sort_merge_passes int
);
END

for i in 1 2 3 4 5 6 7 8 9 10 ; do

### query_start.sql here:
cat <<END
select variable_value into @query_start_smp from information_schema.session_status where variable_name like 'sort_merge_passes';
select current_timestamp(6) into @query_start_time;
END
###

### THE QUERY:

TEST_NAME="sort-varchar-first-names"

QUERY="ANALYZE TABLE t1 PERSISTENT FOR ALL;"

echo $QUERY

### query-end.sql here:
cat << END
set @test_name='$TEST_NAME';
set @query_time_ms= timestampdiff(microsecond, @query_start_time, current_timestamp(6))/1000;
select variable_value into @query_end_smp from information_schema.session_status where variable_name like 'sort_merge_passes';
set @query_merge_passes = @query_end_smp - @query_start_smp;
insert into test_run_queries
  (test_name, test_ts, test_time_ms, sort_merge_passes)
  values (@test_name, @query_start_time, @query_time_ms, @query_merge_passes);
END


done

# Summarize results from multiple runs of one query:
cat <<END
set @min_time = (select min(test_time_ms) from test_run_queries where test_name=@test_name);
set @sort_buffers= (select group_concat(distinct sort_merge_passes) from test_run_queries where test_name=@test_name);
insert into test_runs(test_name, test_ts, test_time_ms, sort_merge_passes) values
  (@test_name, current_timestamp(6), @min_time, @sort_buffers);
END


cat <<END
select '${QUERY/'/\\'}';
select test_name,test_time_ms,sort_merge_passes from test_runs;
select concat(test_name, ',',
              test_time_ms, ',',
              sort_merge_passes)
from test_runs;
END

