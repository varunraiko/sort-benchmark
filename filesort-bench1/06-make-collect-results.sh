#!/bin/bash

#for table_size in 100000 500000 1000000 2000000 4000000 8000000 ; do
#for varchar_size in 50 100 150 200 250; do

cat <<END
drop table if exists rep_by_vcsize;
create table rep_by_vcsize (
  table_size int,
END

for varchar_size in 50 100 150 200 250; do
  echo -n "  vc${varchar_size} int, "
done

cat << END
  dummy int);
END

for table_size in 100000 500000 1000000 2000000 4000000 8000000 ; do

cat << END
insert into rep_by_vcsize select
  $table_size,
END

for varchar_size in 50 100 150 200 250; do

cat <<END
  (select test_time_ms from test_runs where table_size=$table_size and varchar_size= $varchar_size),
END

done

cat << END
  0
from dual;
END

done

heading="select 'table_size"
query_str="select concat(table_size,',',  "

for varchar_size in 50 100 150 200 250; do
  heading="$heading,$varchar_size"
  query_str="$query_str vc${varchar_size},',',  "
done

heading="$heading' as H;"
query_str="$query_str 0) as H from rep_by_vcsize;"

echo $heading
echo $query_str
