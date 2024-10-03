# AES Encryption Plugin Starter Framework

This repository provides a starter framework for developing a custom plugin for performing AES encryption and decryption on the API request and response, using Kong Enterprise. You can add your custom logic for encryption and decryption for your use case on top of this.

The plugin contains two helper functions for encryption and decryption which use the `resty.openssl.cipher` lua library.

The plugin uses hardcoded values for IV, Key and Cryptographic algorithm (AES-128-CBC) to demonstrate the functionality but these should be externalized in the plugin configuration in accordance with programming best practices.

The plugin currently encrypts the request body in the access phase and logs the decrypted response body in the response phase.

# Note

The starter plugin framework is for reference, and not production ready. It shouldn't be used as is without proper externalization of plugin configuration, error handling and thorough unit/integration testing and performance testing.

# Example usage

Making a request to a route "/echo" on the Kong API Gateway, which has httpbin configured as the upstream to echo the request back. The encrypted data is present under "data" element of the API request send to the upstream

```
$ http :8000/echo name=John email=john@example.org

HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Connection: keep-alive
Content-Length: 722
Content-Type: application/json
Date: Wed, 05 Jun 2024 04:42:12 GMT
Server: gunicorn/19.9.0
Via: kong/3.4.3.4-enterprise-edition
X-Kong-Proxy-Latency: 38
X-Kong-Request-Id: c2d4b43a1e9eec0088379108b6444005
X-Kong-Upstream-Latency: 476

{
    "args": {},
    "data": "y4wi7HWt/a5sAEZeTgc+mitQ7+bmmaPY2zLDahjSgASk3YPgmoul66DZSF/KvQp3",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "application/json, */*;q=0.5",
        "Accept-Encoding": "gzip, deflate",
        "Content-Length": "64",
        "Content-Type": "application/json",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.2",
        "X-Amzn-Trace-Id": "Root=1-665feca4-10e0e74d18965c0c2586272b",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/echo",
        "X-Forwarded-Prefix": "/echo",
        "X-Kong-Request-Id": "c2d4b43a1e9eec0088379108b6444005"
    },
    "json": null,
    "method": "POST",
    "origin": "127.0.0.1, 116.15.72.106",
    "url": "http://localhost/anything"
}
```

Decrypted response is logged in error.log as follows:

```
2024/06/05 04:42:11 [notice] 224#0: *2136 [kong] handler.lua:73 [aes-encryption] Received Plaintext body:{"name": "John", "email": "john@example.org"}, client: 127.0.0.1, server: kong, request: "POST /echo HTTP/1.1", host: "localhost:8000", request_id: "c2d4b43a1e9eec0088379108b6444005"
2024/06/05 04:42:11 [notice] 224#0: *2136 [kong] handler.lua:79 [aes-encryption] Encrypted: y4wi7HWt/a5sAEZeTgc+mitQ7+bmmaPY2zLDahjSgASk3YPgmoul66DZSF/KvQp3, client: 127.0.0.1, server: kong, request: "POST /echo HTTP/1.1", host: "localhost:8000", request_id: "c2d4b43a1e9eec0088379108b6444005"
2024/06/05 04:42:11 [debug] 224#0: *2136 [lua] init.lua:1309: balancer(): setting address (try 1): 52.204.69.97:80
2024/06/05 04:42:11 [debug] 224#0: *2136 [lua] init.lua:1338: balancer(): enabled connection keepalive (pool=52.204.69.97|80, pool_size=512, idle_timeout=60, max_requests=1000)
2024/06/05 04:42:11 [debug] 236#0: *1357 [lua] init.lua:290: [cluster_events] polling events from: 1717562481.434
2024/06/05 04:42:12 [debug] 224#0: *2136 [kong] handler.lua:99 [aes-encryption] saying hi from the 'response' handler
2024/06/05 04:42:12 [notice] 224#0: *2136 [kong] handler.lua:109 [aes-encryption] Decrypted String: {"name": "John", "email": "john@example.org"} while sending to client, client: 127.0.0.1, server: kong, request: "POST /echo HTTP/1.1", host: "localhost:8000", request_id: "c2d4b43a1e9eec0088379108b6444005"
```
