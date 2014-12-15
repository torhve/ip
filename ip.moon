template = require "resty.template"
-- Clear cache for debugging
template.cache = {}

-- Set the returning content type just in case the default of Nginx is not html
ngx.header.content_type = 'text/html'

-- Read body
ngx.req.read_body!

-- Render our  index.html with the table of relevant info
template.render "index.html",
  ip: ngx.var.remote_addr
  method: ngx.req.get_method!
  headers: ngx.req.get_headers!
  version: ngx.req.http_version!
  args: ngx.req.get_uri_args!
  post_args: ngx.req.get_post_args!
  port: ngx.var.remote_port
  uri: ngx.var.request_uri
  scheme: ngx.var.scheme

