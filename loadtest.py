# -*- coding: utf-8; -*-
# vi: set encoding=utf-8

import os
import sys
import argparse
import random
import string
from datetime import datetime
from urllib.request import urlopen, Request
from urllib.error import HTTPError
from multiprocessing import Process

HEADERS = {
    'Content-Type': 'application/json',
}

BASE = string.ascii_letters + string.digits

def gen(num, size):
    for x in range(num):
        yield random.choice(BASE) #genascii(size)

def gen_request(id, hosts, bulk_size, payload_size):
    payload = '{"stmt":"insert into loadtest (data) values(?)","bulk_args":['
    for x in gen(bulk_size, payload_size):
        payload += '["' + x + '"],'
    payload = payload.rstrip(',')
    payload += ']}'
    r = Request("http://{}:4200/_sql".format(hosts[id%len(hosts)]),
                payload.encode('utf-8'), headers=HEADERS, method="POST")
    try:
        urlopen(r)
        return True
    except HTTPError as err:
        print(err.fp.read().decode('utf-8'))
        return False


def gen_iterations(hosts, bulk_size, payload_size, num_iterations):
    for x in range(num_iterations):
        gen_request(x, hosts, bulk_size, payload_size)


def split_list(input):
    return input.split(',')


def parse_args():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--iterations', type=int, default=100)
    parser.add_argument('--cores', type=int, default=os.cpu_count())
    parser.add_argument('--threads', type=int, default=32)
    parser.add_argument('--bulk-size', type=int, default=1000)
    parser.add_argument('--payload-size', type=int, default=512)
    parser.add_argument('--hosts', type=split_list, default='127.0.0.1')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    start = datetime.now()
    print(start)
    processes = []
    p_args = (args.hosts, args.bulk_size, args.payload_size, args.iterations,)
    for x in range(args.threads):
        p = Process(target=gen_iterations, args=p_args)
        p.start()
        processes.append(p)
    [p.join() for p in processes]
    end = datetime.now()
    print(end - start)

