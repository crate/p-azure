# -*- coding: utf-8; -*-
# vi: set encoding=utf-8

# Usage:
# echo $(python generate_hosts.py 3 16)
import sys
print(','.join(['swarm-node-{}'.format(x) for x in range(int(sys.argv[1]), int(sys.argv[2])+1)]))
