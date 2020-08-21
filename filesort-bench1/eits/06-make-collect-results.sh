#!/bin/bash

#for table_size in 100000 500000 1000000 2000000 4000000 8000000 ; do
#for varchar_size in 50 100 150 200 250; do

cat <<END
drop table if exists rep_by_vcsize;
create table rep_by_vcsize (
  table_size int,
END

VARCHAR_SIZES="50 75 100 125 150 200 255";
for varchar_size in $VARCHAR_SIZES ; do
  echo -n "  vc${varchar_size} int, "
  echo -n "  passes${varchar_size} VARCHAR(255), "
done

cat << END
  dummy int);
END

TABLE_SIZES="25000 50000 100000 500000 1000000 2000000 4000000"
#for table_size in 100000 500000 1000000 2000000 4000000 8000000 ; do
for table_size in $TABLE_SIZES ; do

cat << END
insert into rep_by_vcsize select
  $table_size,
END

for varchar_size in $VARCHAR_SIZES ; do

cat <<END
  (select test_time_ms from test_runs where table_size=$table_size and varchar_size= $varchar_size),
  (select sort_merge_passes from test_runs where table_size=$table_size and varchar_size= $varchar_size),
END

done

cat << END
  0
from dual;
END

done

heading="select 'table_size"
query_str="select concat(table_size,',',  "

for varchar_size in $VARCHAR_SIZES ; do
  heading="$heading,$varchar_size"
  query_str="$query_str vc${varchar_size},',',  "
done

heading="$heading' as H;"
query_str="$query_str 0) as H from rep_by_vcsize;"

echo $heading
echo $query_str


heading="select 'table_size"
query_str="select concat(table_size,',',  "

for varchar_size in $VARCHAR_SIZES ; do
  heading="$heading,$varchar_size"
  query_str="$query_str passes${varchar_size},',',  "
done

heading="$heading' as Z;"
query_str="$query_str 0) as H from rep_by_vcsize;"

echo $heading
echo $query_str
