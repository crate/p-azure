#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: set fileencodings=utf-8

import argparse

from crate import client

def parseArguments():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-c', '--hosts', nargs='+', help='hosts', required=True)
    parser.add_argument('-p', '--pattern', type=str, required=True)
    return parser.parse_args()

if __name__ == '__main__':
    args = parseArguments()
    conn = client.connect(args.hosts, error_trace=True)
    cursor = conn.cursor()
    cursor.execute("SELECT id, name FROM sys.nodes WHERE name LIKE ?",
        (args.pattern,))
    rows = cursor.fetchall()

    for row in rows:
        print("Exclude data allocation from node {}, id: {} from data nodes"
            .format(row[1], row[0]))
        cursor.execute("""SET GLOBAL TRANSIENT
            cluster.routing.allocation.exclude._id = ?""", (row[0],))

    cursor.close()
