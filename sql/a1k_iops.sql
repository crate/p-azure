drop table if exists azure.iops;
create table azure.iops (
  id string primary key,
  name string primary key,
  query_ts timestamp,
  available boolean,
  diskwritetime array (object as (
      ts timestamp,
      value float
    )
  ),
  diskreadtime array (object as (
      ts timestamp,
      value float
    )
  ),
  diskwrites array (object as (
      ts timestamp,
      value float
    )
  ),
  diskreadbytes array (object as (
      ts timestamp,
      value float
    )
  ),
  diskwritebytes array (object as (
      ts timestamp,
      value float
    )
  )
) with (number_of_replicas = 1);
