select count(*), authority from commoncrawl group by 2 order by 1 limit 10

select count(*), authority from commoncrawl group by 2 order by 1 desc limit 3

select count(distinct path), authority from commoncrawl group by 2 order by 1 desc limit 10

select sum(clen) / 1024 / 1024 / 1024 as "size in GiB" from commoncrawl

select avg(clen), stddev(clen), authority from commoncrawl group by authority order by 2 desc, 1 desc limit 10

select avg(clen), stddev(clen), ctype from commoncrawl group by ctype

select date_format('%Y-%m-%d', date_trunc('week', date)) as interval, avg(clen), stddev(clen)  from commoncrawl group by 1

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, char_length(path), count(*) from commoncrawl group by 1, 2 order by 1, 3 desc, 2 desc limit 10

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl where match(content, 'donald trump') using best_fields with (operator = 'and') group by 1 order by 2 desc limit 100

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl where match(content, 'hillary clinton') using best_fields with (operator = 'and') group by 1 order by 2 desc limit 100

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl where match(content, 'bernie sanders') using best_fields with (operator = 'and') group by 1 order by 2 desc limit 100

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*) from commoncrawl where match(content, 'ted cruz') using best_fields with (operator = 'and') group by 1 order by 2 desc limit 100

select authority, count(*) from commoncrawl where match(content, 'donald trump')  using best_fields with (operator = 'and') group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100

select authority, count(*) from commoncrawl where match(content, 'hillary clinton')  using best_fields with (operator = 'and') group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100

select authority, count(*) from commoncrawl where match(content, 'bernie sanders')  using best_fields with (operator = 'and') group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100

select authority, count(*) from commoncrawl where match(content, 'ted cruz')  using best_fields with (operator = 'and') group by authority having 30 > ((date_trunc('day', max(date)) - date_trunc('day', min(date))) / 1000 / 60 / 60 / 24) order by 2 desc limit 100

select date_format('%Y-%m-%d', date_trunc('week', date)) as week, count(*)  / cast(count(distinct authority) as double) as "pages per site" from commoncrawl where match(content, 'google') group by 1  order by 2 desc limit 100


