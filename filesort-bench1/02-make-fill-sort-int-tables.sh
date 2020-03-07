#!/bin/bash

# Just create the tables

for size in 100000 500000 1000000 2000000 4000000 8000000 16000000 32000000; do

cat <<END
drop table if exists t_int_$size;
create table t_int_$size (
  a int, b int
) engine=myisam;

insert into t_int_$size
select
  floor(rand() * 25), 1234
from seq_1_to_$size;

analyze table t_int_$size;
END

done
