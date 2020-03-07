#!/bin/bash

# Drop the tables

for size in 100000 500000 1000000 2000000 4000000 8000000 16000000 32000000; do

cat <<END
drop table if exists t_int_$size;
END

done
