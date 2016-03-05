import threading
import time
import sys
import argparse

from crate import client
from datetime import datetime

class FetchResource:

    def __init__(self, hosts):
        self.hosts = hosts

    def open(self):
        self.conn = client.connect(self.hosts,
                            error_trace=True)
        self.cursor = self.conn.cursor()

    def close(self):
        self.cursor.close()

class StoreResource:

    METRICS_TABLE_NAME = 'azure.metrics'
    JOBS_LOG_TABLE_NAME = 'azure.jobs_log'

    def __init__(self, hosts):
        self.hosts = hosts

    def open(self):
        self.conn = client.connect(self.hosts,
                            error_trace=True)
        self.cursor = self.conn.cursor()

    def close(self):
        self.cursor.close()

class MetricFetcher():
    """
        A thread class that will fetch metrics from a cluster
        and store it in another cluster
    """

    def __init__(self, fetch_resource, store_resource, fetch_time_interval):
        if fetch_time_interval:
            self.fetch_time_interval = fetch_time_interval
        else:
            self.fetch_time_interval = 10

        self.fetch_resource = fetch_resource
        self.store_resource = store_resource
        self.start_test_ts = int(round(time.time() * 1000))

        self.fetch_resource.open()
        self.store_resource.open()

    def __del__(self):
        self._disable_stats()
        self.fetch_resource.close()
        self.store_resource.close()

    @property
    def fetch_cursor(self):
        return self.fetch_resource.cursor

    @property
    def store_cursor(self):
        return self.store_resource.cursor

    def _fetch_metrics(self):
        self.fetch_cursor.execute("""
            SELECT
            current_timestamp as query_ts, id, name, hostname, load, mem, heap, fs, thread_pools, os, os_info, network, process
            FROM sys.nodes
            """)
        return self.fetch_cursor.fetchall()

    def _fetch_jobs_log(self, last_fetch_date):
        self.fetch_cursor.execute("""
            SELECT id, ended, error, started, stmt FROM sys.jobs_log
            WHERE ended > ?
            ORDER BY ended DESC
            """, (last_fetch_date,))
        return self.fetch_cursor.fetchall()

    def _insert_metrics(self, metrics):
        if metrics:
            insert_values = [tuple(value) for value in metrics]
            self.store_cursor.executemany("""
                        INSERT INTO {0}
                        (query_ts, node_id, node_name, hostname, load, mem, heap, fs, thread_pools, os, os_info, network, process)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""".format(StoreResource.METRICS_TABLE_NAME),
                        insert_values)
        else:
            print ("metric data empty - nothing to insert")

    def _insert_jobs_log(self, jobs_log):
        if jobs_log:
            insert_values = [tuple(value) for value in jobs_log]

            self.store_cursor.executemany("""
                INSERT INTO {0}
                (id, ended, error, started, stmt)
                VALUES (?, ?, ?, ?, ?)""".format(StoreResource.JOBS_LOG_TABLE_NAME),
                insert_values)
        else:
            print ("jobs_log empty - nothing to insert")

    def _get_jobs_log_date(self):
        self.store_cursor.execute("""
            SELECT ended FROM {0}
            ORDER BY ended DESC LIMIT 1
            """.format(StoreResource.JOBS_LOG_TABLE_NAME))
        result = self.store_cursor.fetchone()
        if result:
            return int(result[0])
        else:
            return self.start_test_ts

    def _enable_stats(self):
        self.fetch_cursor.execute("""
            SET GLOBAL PERSISTENT stats.enabled = true
            """)

    def _disable_stats(self):
        self.fetch_cursor.execute("""
            SET GLOBAL PERSISTENT stats.enabled = false
            """)

    def run(self):
        try:
            ### Enable Stats
            self._enable_stats()

            while True:
                metrics = self._fetch_metrics()
                self._insert_metrics(metrics)

                last_fetch_date = self._get_jobs_log_date()
                jobs_log = self._fetch_jobs_log(last_fetch_date)
                self._insert_jobs_log(jobs_log)

                localtime = time.asctime(time.localtime(time.time()))
                print ("{0}: {1} metrics and {2} jobs inserted".format(localtime, len(metrics), len(jobs_log)))
                time.sleep(self.fetch_time_interval)

        except KeyboardInterrupt:
            print ("Test stopped!")

def run():
    try:
        args = parseArguments()
        metricFetcher = MetricFetcher(FetchResource(args.source), StoreResource(args.dest), args.interval)
        metricFetcher.run()
    except (KeyboardInterrupt):
        print ("Test stopped!")

def parseArguments():
    parser = argparse.ArgumentParser(description='Fetch system metrics and store them.')
    parser.add_argument('-s', '--source', nargs='+', help='source hosts', required=True)
    parser.add_argument('-d', '--dest', nargs='+', help='destination hosts', required=True)
    parser.add_argument('-t', '--interval', type=int, help='time interval', required=False)
    return parser.parse_args()

if __name__ == '__main__':
    run()