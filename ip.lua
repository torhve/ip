local template = require("resty.template")
local resolver = require("resty.dns.resolver")
local json = require("cjson")
template.cache = { }
ngx.header.content_type = 'text/html'
ngx.req.read_body()
local vars = {
  ip = ngx.var.remote_addr,
  method = ngx.req.get_method(),
  headers = ngx.req.get_headers(),
  version = ngx.req.http_version(),
  args = ngx.req.get_uri_args(),
  post_args = ngx.req.get_post_args(),
  port = ngx.var.remote_port,
  uri = ngx.var.request_uri,
  scheme = ngx.var.scheme,
  geo_vars = {
    country_code = ngx.var.geoip_country_code,
    country_code3 = ngx.var.geoip_country_code3,
    country = ngx.var.geoip_country,
    region = ngx.var.geoip_region,
    region_code = ngx.var.geoip_region_code,
    city = ngx.var.geoip_city,
    postal_code = ngx.var.geoip_postal_code,
    continent_code = ngx.var.geoip_continent_code,
    latitude = ngx.var.geoip_latitude,
    longitude = ngx.var.geoip_longitude,
    dma_code = ngx.var.geoip_dma_code,
    area_code = ngx.var.geoip_area_code,
    timezone = ngx.var.geoip_timezone,
    offset = ngx.var.geoip_offset,
    asn = ngx.var.asn,
    isp = ngx.var.isp
  }
}
if vars.headers.accept and vars.headers.accept:match('application/json') then
  ngx.header.content_type = 'application/json'
  return ngx.print(json.encode(vars))
elseif vars.headers.user_agent and vars.headers.user_agent:lower():match('wget') then
  return ngx.say(vars.ip)
elseif vars.headers.user_agent and vars.headers.user_agent:lower():match('curl') then
  return ngx.say(vars.ip)
elseif vars.uri:match('/ip') then
  return ngx.print("<h2 style=\"color: #4d8fc8; padding: 0; margin: 0; font-size:18px\">" .. tostring(vars.ip) .. "</h2>")
else
  return template.render("index.html", vars)
end
