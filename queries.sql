create table if not exitsts commoncrawl (
  uri string,
  fqdn string,
  date timestamp,
  ctype string,
  clen int,
  content string INDEX using fulltext
);

-- number of distinct domains
select count(distinct uri) / cast(count(distinct fqdn) as double) as "uris per domain" from commoncrawl;

-- total size of indexed webpages
select sum(clen) / 1024 / 1024 / 1024 as "size in GiB" from commoncrawl limit 100;

-- trend to smaller webpages/shorter content?

-- average length + stddev per domain
select avg(clen), stddev(clen), fqdn from commoncrawl group by fqdn;

-- average length + stddev per contenttype - ARE THERE OTHER TYPES???
select avg(clen), stddev(clen), ctype from commoncrawl group by ctype;

-- average length + stddev by date (weeks? years? months?)
select date_format('%Y-%m-%d', date_trunc('week', date)) as interval, avg(clen), stddev(clen)  from commoncrawl group by interval;


-- trend to shorter URLs?

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, char_length(uri), count(*) from commoncrawl group by 1, 2 order by 1, 3, 2;

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




-- supporting sites with more related content than days.
select fqdn, count(*) from commoncrawl where match(content, 'donald trump')  using best_fields with (operator = 'and')
group by 1 having count(*) > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;

select fqdn, count(*) from commoncrawl where match(content, 'hillary clinton')  using best_fields with (operator = 'and')
group by 1 having count(*) > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;

select fqdn, count(*) from commoncrawl where match(content, 'bernie sanders')  using best_fields with (operator = 'and')
group by 1 having count(*) > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;

select fqdn, count(*) from commoncrawl where match(content, 'ted cruz')  using best_fields with (operator = 'and')
group by 1 having count(*) > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100;


-- pages / site by week

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*)  / cast(count(distinct fqdn) as double) as "pages per site" from commoncrawl
where match(content, 'google')
group by 1  order by 2 desc limit 100;
