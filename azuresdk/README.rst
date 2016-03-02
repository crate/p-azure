===============
Azure SDK Tools
===============

Installation
============

::

  $ virtualenv env
  $ source env/bin/activate
  $ pip install -r requirements.txt

Generate Common Crawl File URLS
===============================

First, create the output folder.
For each partition value (timestamp of the week) a text file with signed URLs
will be created inside the output folder::

  $ mkdir out/

Run ``list_blobs.py``::

  $ python list_blobs.py --help
  usage: list_blobs.py [-h] [--storage-account STORAGE_ACCOUNT]
                       [--storage-account-key STORAGE_ACCOUNT_KEY]
                       [--out-folder OUT_FOLDER]

  Iterate over storage account, generate file urls and store them grouped by
  partition value (week).

  optional arguments:
    -h, --help            show this help message and exit
    --storage-account STORAGE_ACCOUNT
                          Name of the storage account
    --storage-account-key STORAGE_ACCOUNT_KEY
                          2nd key of the storage account
    --out-folder OUT_FOLDER
                          Output directory

Example::

  $ python list_blobs.py --storage-account azure1kstorage --storage-account-key "key_that_ends_with=="
Output might look like this::

  week                      partition    files             size           size in gb
  2014-04-21T00:00:00   1398038400000     5000     521304394820    485.5025511421263
  2014-07-14T00:00:00   1405296000000     3300     210472973252   196.01823133602738
  2014-07-28T00:00:00   1406505600000      251      40478701065    37.69872809294611
  2014-08-25T00:00:00   1408924800000       17       1441725625     1.34271162096411
  2014-10-20T00:00:00   1413763200000     5000     732992597596    682.6525531671941
  2014-11-24T00:00:00   1416787200000     5000     585282441645     545.086750430055
  2014-12-22T00:00:00   1419206400000     5000     644904370192    600.6139984279871
  2015-03-02T00:00:00   1425254400000     5000     526485888364    490.3281930498779
  2015-04-20T00:00:00   1429488000000     5000     555173043324    517.0451880656183
  2015-06-29T00:00:00   1435536000000     5000     571298394944    532.0630920529366
  2015-08-31T00:00:00   1440979200000     5000     459100259945   427.57043609861284
  2015-10-05T00:00:00   1444003200000     5000     463275783846   431.45919576846063
  2015-11-30T00:00:00   1448841600000     5000     482630006935   449.48422064539045


And the files generated::

  $ ls out/
  1398038400000.txt 1406505600000.txt 1413763200000.txt 1419206400000.txt 1429488000000.txt 1440979200000.txt 1448841600000.txt
  1405296000000.txt 1408924800000.txt 1416787200000.txt 1425254400000.txt 1435536000000.txt 1444003200000.txt
