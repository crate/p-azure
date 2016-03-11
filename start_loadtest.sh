#/bin/bash

CORES=32
THREADS=32
ITERATIONS=50
HOSTS="$1"
BULK_SIZE=5000

for x in $(seq 1 $CORES); do
  python3 loadtest.py --iterations $ITERATIONS --threads $THREADS --bulk-size $BULK_SIZE --hosts $HOSTS &
done
