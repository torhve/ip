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

-- Check if the user agent wants HTML or JSON
if vars.headers.accept and vars.headers.accept\match 'application/json'
  ngx.header.content_type = 'application/json'
  ngx.print json.encode vars
elseif vars.headers.user_agent and vars.headers.user_agent\lower!\match 'wget' -- Return just the IP to CLI
  ngx.say vars.ip
elseif vars.headers.user_agent and vars.headers.user_agent\lower!\match 'curl' -- Return just the IP to CLI
  ngx.say vars.ip
else
  -- Render our  index.html with the table of relevant info
  template.render "index.html", vars

