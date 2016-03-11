# -*- coding: utf-8; -*-
# vi: set encoding=utf-8

import sys
from crate.client import connect

def measure(cursor, stmt):
    for x in range(3):
        # warmup round
	cursor.execute(stmt)
    # execution
    cursor.execute(stmt)
    cursor.fetchall()
    return cursor.duration

if __name__ == '__main__':
    hosts = ['swarm-node-{}:4200'.format(x) for x in range(3,9)]
    conn = connect(hosts)
    cur = conn.cursor()
    with open('queries.sql') as fp:
        for line in fp:
            stmt = line.strip('\n')
            if len(stmt):
                print(stmt)
                dur = measure(cur, stmt)
                print(dur/1000.0)
