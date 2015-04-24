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
  scheme = ngx.var.scheme
}
if vars.headers.accept and vars.headers.accept:match('application/json') then
  ngx.header.content_type = 'application/json'
  return ngx.print(json.encode(vars))
elseif vars.headers.user_agent and vars.headers.user_agent:lower():match('wget') then
  return ngx.say(vars.ip)
elseif vars.headers.user_agent and vars.headers.user_agent:lower():match('curl') then
  return ngx.say(vars.ip)
else
  return template.render("index.html", vars)
end
