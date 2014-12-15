local template = require("resty.template")
template.cache = { }
ngx.header.content_type = 'text/html'
ngx.req.read_body()
return template.render("index.html", {
  ip = ngx.var.remote_addr,
  method = ngx.req.get_method(),
  headers = ngx.req.get_headers(),
  version = ngx.req.http_version(),
  args = ngx.req.get_uri_args(),
  post_args = ngx.req.get_post_args()
})
