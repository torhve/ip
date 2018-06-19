template = require "resty.template"
resolver = require "resty.dns.resolver"
json = require "cjson"
-- Clear cache for debugging
template.cache = {}

-- Set the returning content type just in case the default of Nginx is not html
ngx.header.content_type = 'text/html'

-- Read body
ngx.req.read_body!

-- Populate vars
vars =
  ip: ngx.var.remote_addr
  method: ngx.req.get_method!
  headers: ngx.req.get_headers!
  version: ngx.req.http_version!
  args: ngx.req.get_uri_args!
  post_args: ngx.req.get_post_args!
  port: ngx.var.remote_port
  uri: ngx.var.request_uri
  scheme: ngx.var.scheme
  geo_vars:
    country_code: ngx.var.geoip_country_code,
    country_code3: ngx.var.geoip_country_code3,
    country: ngx.var.geoip_country,
    region: ngx.var.geoip_region,
    region_code: ngx.var.geoip_region_code,
    city: ngx.var.geoip_city,
    postal_code: ngx.var.geoip_postal_code,
    continent_code: ngx.var.geoip_continent_code,
    latitude: ngx.var.geoip_latitude,
    longitude: ngx.var.geoip_longitude,
    dma_code: ngx.var.geoip_dma_code,
    area_code: ngx.var.geoip_area_code,
    timezone: ngx.var.geoip_timezone,
    offset: ngx.var.geoip_offset,
    asn: ngx.var.asn,
    isp: ngx.var.isp

-- Check if the user agent wants HTML or JSON
if vars.headers.accept and vars.headers.accept\match 'application/json'
  ngx.header.content_type = 'application/json'
  ngx.print json.encode vars
elseif vars.headers.user_agent and vars.headers.user_agent\lower!\match 'wget' -- Return just the IP to CLI
  ngx.say vars.ip
elseif vars.headers.user_agent and vars.headers.user_agent\lower!\match 'curl' -- Return just the IP to CLI
  ngx.say vars.ip
elseif vars.uri\match '/ip' -- Return just the IP for this URL
  -- Firefox apparently reuses the connection because it sees certificat match
  -- I will per http2-spec send a http 421
  -- https://http2.github.io/http2-spec/#reuse
  if ngx.var.host\match'ipv4' and vars.ip\match':'
    ngx.exit(421)
  if ngx.var.host\match'ipv6' and vars.ip\match'.'
    ngx.exit(421)
  ngx.print "<h2 style=\"color: #4d8fc8; padding: 0; margin: 0; font-size:18px\">#{vars.ip}</h2>"
else
  -- Render our  index.html with the table of relevant info
  template.render "index.html", vars

