###  Scripts usage example 

Start azure VMs:

```bash
    ./create_vms.sh -i manager -a 1 -p Swarm1001!
    ./create_vms.sh -i agent -a 3 -p Swarm1001!

```

Start crate containers within `Docker Swarm` enviroment:

```bash 
    ./start_crate.sh master --add-instances 3
    ./start_crate.sh data --add-instances 6
```

Exlude data allocation from crate nodes:

```python
    python exclude_data_alloc.py --hosts swarm-agent-1:4200 --pattern swarm-agent-1%
```


Stop crate containers which names match a pattern:

```bash
    ./stop_crate.sh --pattern swarm-agent-6
```