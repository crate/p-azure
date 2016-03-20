#!/usr/bin/python

import json
import urllib.request
import threading
import queue


from multiprocessing.pool import ThreadPool

with urllib.request.urlopen('http://54.229.141.174/hosts?Api-Token=Ws31UgzFS4m1g0np0tdZs') as response:
    host_list=response.read().decode('utf-8')
    j=json.loads(host_list)

q = queue.Queue()
def iops_request(host_id):
    with urllib.request.urlopen('http://54.229.141.174/'+ host_id +'?Api-Token=Ws31UgzFS4m1g0np0tdZs') as response:
        iops_response=response.read().decode('utf-8')
        
        if iops_response['id']:
            q.put(json.loads(iops_response))
            print("got response from :  {0}".format(host_id))

pool = ThreadPool(processes=1010)

for x in j:
    pool.apply_async(iops_request, (x['id'],))

#for thread in pool:
pool.close()
pool.join()

print("Writing results to the file..")
with open("io_result.txt", "a") as out_file:
    for a in iter(q.get, None):
        out_file.write(json.dumps(a))
        out_file.write("\n")
    out_file.close()

