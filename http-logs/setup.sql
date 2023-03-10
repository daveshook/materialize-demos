-- Flask request logs format
CREATE SOURCE IF NOT EXISTS requests
FROM FILE '/log/requests' WITH (tail = true)
FORMAT REGEX '(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[(?P<ts>[^]]+)\] "(?P<path>(?:GET /search/\?kw=(?P<search_kw>[^ ]*) HTTP/\d\.\d)|(?:GET /detail/(?P<product_detail_id>[a-zA-Z0-9]+) HTTP/\d\.\d)|(?:[^"]+))" (?P<code>\d{3}) -';

-- Average number of product detail pages viewed per IP that has viewed the
-- search page at least once
CREATE MATERIALIZED VIEW IF NOT EXISTS avg_dps_for_searcher AS
    SELECT avg(dp_hits) FROM (
        SELECT ip, count(product_detail_id) AS dp_hits, count(search_kw) AS search_hits
        FROM requests
        GROUP BY ip
    )
    WHERE search_hits > 0;

-- Number of unique IP hits
CREATE MATERIALIZED VIEW IF NOT EXISTS unique_visitors AS
    SELECT count(DISTINCT ip) FROM requests;

-- 40 products with the most hits
CREATE MATERIALIZED VIEW IF NOT EXISTS top_products AS
    SELECT count(product_detail_id) ct, product_detail_id
    FROM requests
    GROUP BY product_detail_id
    ORDER BY ct DESC LIMIT 40;
    