create table if not exists commoncrawl (
  ssl boolean primary key, -- http/https - byte/boolean primary key
  authority string primary key, -- xyz.hello.com:123 primary key
  path string primary key, -- /a?d=1#hello primary key
  date timestamp primary key,
  week_partition as date_trunc('week', date) primary key,
  --
  ctype string,
  clen int,
  content string INDEX using fulltext with (max_token_length = 40)
) clustered into 3 shards partitioned by (week_partition);


-- add primary key query. for showing off routing to primary key
select path from commoncrawl where authority = 'io.crate' order by 1;
select path, authority from commoncrawl  where authority like 'com.google' order by 1;

-- "get" query directly fetches stuff
select * from commoncrawl  where authority = 'com.google' and ssl = 'false' and path = '/' and date = 0 order by 1;


-- number of distinct domains, add conditions to reduce load
select count(distinct uri) / cast(count(distinct authority) as double) as "uris per domain" from commoncrawl;

-- number of distinct domains, add conditions to reduce load
select count(*), authority from commoncrawl group by 2 order by 1 desc;


select count(distinct path), authority from commoncrawl group by 2 order by 1 desc;


-- total size of indexed webpages
select sum(clen) / 1024 / 1024 / 1024 as "size in GiB" from commoncrawl limit 100;

-- trend to smaller webpages/shorter content?

-- average length + stddev per domain
select avg(clen), stddev(clen), authority from commoncrawl group by authority;

-- average length + stddev per contenttype - ARE THERE OTHER TYPES???
select avg(clen), stddev(clen), ctype from commoncrawl group by ctype;

-- average length + stddev by date (weeks? years? months?) ||| SLOW because of date_format
select date_format('%Y-%m-%d', date_trunc('week', date)) as interval, avg(clen), stddev(clen)  from commoncrawl group by date_trunc('week', date);


-- trend to shorter URLs?

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, char_length(uri), count(*) from commoncrawl group by 1, 2 order by 1, 3, 2;


-- concetenate
select date_format('%Y-%m-%d', date_trunc('week', date)) as interval, avg(char_length(uri))  from commoncrawl group by interval;

-- us election 2017
-- number of web occurrences

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl
where match(content, 'donald trump') using best_fields with (operator = 'and')
group by 1 order by 2 desc limit 100;

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl
where match(content, 'hillary clinton') using best_fields with (operator = 'and')
group by 1 order by 2 desc limit 100;

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl
where match(content, 'bernie sanders') using best_fields with (operator = 'and')
group by 1 order by 2 desc limit 100;

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl
where match(content, 'ted cruz') using best_fields with (operator = 'and')
group by 1 order by 2 desc limit 100;




-- supporting sites for more than 30 days.
select authority, count(*) from commoncrawl where match(content, 'donald trump')  using best_fields with (operator = 'and')
group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;

select authority, count(*) from commoncrawl where match(content, 'hillary clinton')  using best_fields with (operator = 'and')
group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;

select authority, count(*) from commoncrawl where match(content, 'bernie sanders')  using best_fields with (operator = 'and')
group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;

select authority, count(*) from commoncrawl where match(content, 'ted cruz')  using best_fields with (operator = 'and')
group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;


-- pages / site by week

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*)  / cast(count(distinct authority) as double) as "pages per site" from commoncrawl
where match(content, 'google')
group by 1  order by 2 desc limit 100;
