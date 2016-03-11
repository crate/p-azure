# p-azure


## Load Testing

```console
export CRATE_HOSTS=$(getent hosts $(python generate_hosts.py 3 17) | awk '{ print $1 }' | paste -sd "," -)
./start_loadtest.sh $CRATE_HOSTS
```
