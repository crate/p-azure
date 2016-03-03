# -*- coding: utf-8; -*-
# vi: set encoding=utf-8

import os
import re
import sys
import math
import calendar
from argparse import ArgumentParser
from datetime import datetime, date
from azure.storage import AccessPolicy, AccountPermissions
from azure.storage.blob import BlockBlobService

RE_TIMESTAMP = re.compile('.*-(\d{14})-.*')
DATEFORMAT = '%Y%m%d%H%M%S'


def main(cli_args):
    account_name = cli_args.storage_account or input('Storage Account Name: ')
    account_key = cli_args.storage_account_key or input('Storage Account Key: ')
    blob_service = BlockBlobService(account_name, account_key)
    print_files(blob_service, out=cli_args.out_folder, limit=cli_args.limit)


def size_in_gb(bytes):
    return '{:.9f}'.format(bytes / math.pow(1024, 3))


def print_files(blob_service, out, limit):
    weeks = dict()
    try:
        for container in blob_service.list_containers():
            if container.name == 'vhds':
                return
            for blob in blob_service.list_blobs(container.name, num_results=limit):
                sas_token = blob_service.generate_blob_shared_access_signature(
                    container_name=container.name,
                    blob_name=blob.name,
                    permission=AccountPermissions.READ,
                    expiry='2016-12-31',
                )
                signed_url = blob_service.make_blob_url(
                    container_name=container.name,
                    blob_name=blob.name,
                    sas_token=sas_token,
                )
                ts = RE_TIMESTAMP.match(signed_url).groups()[0]
                ts = datetime.strptime(ts, DATEFORMAT)
                iso_year, iso_week, iso_weekday = ts.isocalendar()
                week = datetime.strptime('{}-{}-1'.format(iso_year, iso_week), '%Y-%W-%w')
                timestamp = str(calendar.timegm(week.timetuple()) * 1000)
                if not timestamp in weeks.keys():
                    weeks[timestamp] = [
                        0,
                        0,
                        open(os.path.join(out, '{}.txt'.format(timestamp)), 'wb'),
                        week
                    ]
                w = weeks[timestamp]
                w[0] += 1
                w[1] += blob.properties.content_length
                w[2].write(signed_url.encode('utf-8') + b'\n')
    except Exception as ex:
        print(ex)
    finally:
        TPL = '{:<20} {:>14} {:>8} {:>16} {:>20}'
        print(TPL.format('week', 'partition', 'files', 'size', 'size in gb'))
        total_files = 0
        total_size = 0
        for fn in sorted(weeks):
            w = weeks[fn]
            print(TPL.format(w[3].isoformat(), fn, w[0], w[1], size_in_gb(w[1])))
            w[2].close()
            total_files += w[0]
            total_size += w[1]
        print(TPL.format('Total', '', total_files, total_size, size_in_gb(total_size)))



if __name__ == '__main__':
    parser = ArgumentParser(description='Iterate over storage account, generate file urls and store them grouped by partition value (week).')
    parser.add_argument('--storage-account', type=str,
                        help='Name of the storage account')
    parser.add_argument('--storage-account-key', type=str,
                        help='2nd key of the storage account')
    parser.add_argument('--out-folder', default=os.path.join(os.getcwd(), 'out'),
                        help='output directory')
    parser.add_argument('--limit', type=int, default=1000,
                        help='File limit per partition')
    cli_args = parser.parse_args()
    main(cli_args)


