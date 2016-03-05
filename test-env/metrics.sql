drop table if exists azure.metrics;
create table azure.metrics (
  query_ts timestamp primary key,
  node_id string primary key,
  node_name string,
  hostname string,
  load object,
  mem object,
  heap object,
  fs object,
  thread_pools array(object),
  os object,
  os_info object,
  network object,
  process object
) with (number_of_replicas = '0-all');

drop table if exists azure.jobs_log;
create table azure.jobs_log (
  id string primary key,
  ended timestamp primary key,
  error string,
  started timestamp,
  stmt string
) with (number_of_replicas = '0-all');