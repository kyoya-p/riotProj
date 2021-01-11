var httpProxy = require('http-proxy');

var proxy = httpProxy.createProxyServer({
    target: "http://www.ieserver.net/"
})

proxy.listen(8080);
