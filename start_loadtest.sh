#/bin/bash

CORES=4
THREADS=16
ITERATIONS=100
HOSTS="$1"

for x in $(seq 1 $CORES); do
  python3 loadtest.py --iterations $ITERATIONS --threads $THREADS --hosts $HOSTS &
done
