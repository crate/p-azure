# Metric Fetcher

This python app fetches system metrics from a cluster and stores them in
user-defined tables. The cluster where the data is fetched from and the cluster
to store the data can be different.

## Requirements

* Python 3.5
* [virtualenv](https://virtualenv.readthedocs.org/en/latest/)

## Usage

### Create virtualenv

```
virtualenv env
source ./env/bin/activate
pip install -r requirements.txt
```

### Create table schemas

Create table schemas on the cluster that stores the results.

```
crash --hosts <CRATE-HOST>:<PORT> < metrics.sql
```

### Parameters

A list of source and destination hosts needs to be provided as arguments.
There is also a way to specify the time interval for fetching metric data
with the optional `-t` argument:

```
python fetch_metrics.py -s localhost:4200 ... -d st1.p.fir.io:4200 ... -t 10
```

This app fetches data every 10s from localhost and stores it on staging cluster.

### Run the app

```
python fetch-metrics.py -s <SOURCE-HOSTS> ... -d <DESTINATION-HOSTS> ...
```