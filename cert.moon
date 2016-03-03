template = require "resty.template"
resolver = require "resty.dns.resolver"
json = require "cjson"
ngx = require 'ngx'
-- Clear cache for debugging
template.cache = {}

-- Set the returning content type just in case the default of Nginx is not html
ngx.header.content_type = 'text/html'

class Test
  new: (target) =>
    @target = target or ''
    @host, @port = @target\match '[(.+)]:(.+)'
    if @host
      return
    @host, @port = @target\match '(.+):(.+)'
    if not @host
      -- Default port 443
      @host = @target
      @port = 443
    else
      @port = tonumber @port

  _make_sock: =>
    if not @host or not @port
      return @render "Need hostname and port number separated by a :"
    @sock = ngx.socket.tcp!
    @sock\settimeout 2000
    ok, @err = @sock\connect @host, @port

  resolve: =>
    r, err = resolver\new {
      nameservers: {"127.0.0.1"},
      retrans: 5 -- on recieve timeout
      timeout: 3000 -- 3sec
    }
    if not r
      return @render "resolver failure: #{err}"

    -- Prefer IPv6 over IPv4, lookup first

    answers6, err = r\query @host, {qtype: 28} -- 28 == AAAA, CNAME = 5
    if not answers6
      return @render "failed to query DNS server: #{err}"

    if answers6.errcode
      return @render "server return error code: #{answers6.errcode}, #{answers6.errstr}"

    answers, err = r\query @host
    if not answers
      return @render "failed to query DNS server: #{err}"

    if answers.errcode
      return @render "server return error code: #{answers.errcode}, #{answers.errstr}"

    for i, ans in ipairs(answers) do
      -- use last?
      @dns = ans

    @answers = answers

    for i, ans in ipairs(answers6) do
      --append ipv6 to ipv4
      table.insert(@answers, ans)
      -- use last?
      @dns = ans


  connect: =>
    @_make_sock!
    return @sock, @err

  sslhandshake: (verify, host) =>
    reuse = false
    staple_req = false
    @sess, @err = @sock\sslhandshake(reuse, host, verify, staple_req)
    return @sess, @err

  render: (lasterr) =>
    @lasterr = lasterr
    -- Check if the user agent wants HTML or JSON
    headers = ngx.req.get_headers!
    if headers.accept and headers.accept\match 'application/json'
      @render_json(lasterr)
    else
      template.render "cert.html", {self:@}
    if @sock
      @sock\close!
    -- If someone calls render to abort early we exit here
    ngx.exit(200)

  render_json: (lasterr) =>
    res = {
      err: @lasterr
      host: @host
      port: @port
    }
    if @dns
      res.host = @dns.address

    conn, err = @connect!
    if err
      res.err = err
    else
      session, err = @sslhandshake(true, @host)
      if err
        res.err = "TLS handshake failed: #{err}"
        res.success = false
      else
        res.success = true


    ngx.say json.encode res

args = ngx.req.get_uri_args!
test = Test(args.target)
if test.host and test.port
  test\resolve!
-- No errors. Call Render
test\render!
