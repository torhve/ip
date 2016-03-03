local template = require("resty.template")
local resolver = require("resty.dns.resolver")
local json = require("cjson")
local ngx = require('ngx')
template.cache = { }
ngx.header.content_type = 'text/html'
local Test
do
  local _class_0
  local _base_0 = {
    _make_sock = function(self)
      if not self.host or not self.port then
        return self:render("Need hostname and port number separated by a :")
      end
      self.sock = ngx.socket.tcp()
      self.sock:settimeout(2000)
      local ok
      ok, self.err = self.sock:connect(self.host, self.port)
    end,
    resolve = function(self)
      local r, err = resolver:new({
        nameservers = {
          "127.0.0.1"
        },
        retrans = 5,
        timeout = 3000
      })
      if not r then
        return self:render("resolver failure: " .. tostring(err))
      end
      local answers6
      answers6, err = r:query(self.host, {
        qtype = 28
      })
      if not answers6 then
        return self:render("failed to query DNS server: " .. tostring(err))
      end
      if answers6.errcode then
        return self:render("server return error code: " .. tostring(answers6.errcode) .. ", " .. tostring(answers6.errstr))
      end
      local answers
      answers, err = r:query(self.host)
      if not answers then
        return self:render("failed to query DNS server: " .. tostring(err))
      end
      if answers.errcode then
        return self:render("server return error code: " .. tostring(answers.errcode) .. ", " .. tostring(answers.errstr))
      end
      for i, ans in ipairs(answers) do
        self.dns = ans
      end
      self.answers = answers
      for i, ans in ipairs(answers6) do
        table.insert(self.answers, ans)
        self.dns = ans
      end
    end,
    connect = function(self)
      self:_make_sock()
      return self.sock, self.err
    end,
    sslhandshake = function(self, verify, host)
      local reuse = false
      local staple_req = false
      self.sess, self.err = self.sock:sslhandshake(reuse, host, verify, staple_req)
      return self.sess, self.err
    end,
    render = function(self, lasterr)
      self.lasterr = lasterr
      local headers = ngx.req.get_headers()
      if headers.accept and headers.accept:match('application/json') then
        self:render_json(lasterr)
      else
        template.render("cert.html", {
          self = self
        })
      end
      if self.sock then
        self.sock:close()
      end
      return ngx.exit(200)
    end,
    render_json = function(self, lasterr)
      local res = {
        err = self.lasterr,
        host = self.host,
        port = self.port
      }
      if self.dns then
        res.host = self.dns.address
      end
      local conn, err = self:connect()
      if err then
        res.err = err
      else
        local session
        session, err = self:sslhandshake(true, self.host)
        if err then
          res.err = "TLS handshake failed: " .. tostring(err)
          res.success = false
        else
          res.success = true
        end
      end
      return ngx.say(json.encode(res))
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, target)
      self.target = target or ''
      self.host, self.port = self.target:match('[(.+)]:(.+)')
      if self.host then
        return 
      end
      self.host, self.port = self.target:match('(.+):(.+)')
      if not self.host then
        self.host = self.target
        self.port = 443
      else
        self.port = tonumber(self.port)
      end
    end,
    __base = _base_0,
    __name = "Test"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Test = _class_0
end
local args = ngx.req.get_uri_args()
local test = Test(args.target)
if test.host and test.port then
  test:resolve()
end
return test:render()
