-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------



local aesEncHandler = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}

-- do initialization here, any module level code runs in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- but be available in all workers.

local cipher_lib = require("resty.openssl.cipher")
local cjson = require "cjson"

-- hardcoding the key and iv for a poc, Todo externalize this
local key = string.rep("0", 16)
local iv = string.rep("0", 16)

-- Function for encryption
-- Uses AES-128-CBC - can be changed based on requirements
local function encrypt_data(plaintext, key, iv)
  local c, err = cipher_lib.new("aes-128-cbc")
  if not c then
      return nil, "Failed to create cipher: " .. err
  end

  local encrypted, err = c:encrypt(key, iv, plaintext, false)
  if not encrypted then
      return nil, "Failed to encrypt: " .. err
  end

  return ngx.encode_base64(encrypted), nil
end

-- Function for decryption
-- Uses AES-128-CBC - can be changed based on requirements
local function decrypt_data(base64_encrypted, key, iv)
  local c, err = cipher_lib.new("aes-128-cbc")
  if not c then
      return nil, "Failed to create cipher: " .. err
  end

  local encrypted = ngx.decode_base64(base64_encrypted)
  local decrypted, err = c:decrypt(key, iv, encrypted, false)
  if not decrypted then
      return nil, "Failed to decrypt: " .. err
  end

  return decrypted, nil
end

-- runs in the 'access_by_lua_block'
function aesEncHandler:access(plugin_conf)

  -- enable buffering to access RESPONSE body later
  kong.service.request.enable_buffering()

  -- Encrypt the request body

  local body = kong.request.get_raw_body()
  kong.log("Received Plaintext body:" ..body)
  local body_string = cjson.decode(body)
  local encoded_b64, err = encrypt_data(body, key, iv)
  if err then
    kong.response.exit("Encryption Error: ", err)
  else
    kong.log("Encrypted: ", encoded_b64)
  end

  kong.service.request.set_raw_body(encoded_b64)

end --]]

local function parse_json(body)
  if body then
    local ok, res = pcall(cjson.decode, body)
    if ok then
      return res
    end
  end
end

-- runs in the PDK response phase
function aesEncHandler:response(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'response' handler")
  local response_body, err = kong.service.response.get_raw_body()

  local json_body = parse_json(response_body)
  local encrypted_string = json_body.data

  local decrypted, err = decrypt_data(encrypted_string, key, iv)
  if err then
      kong.response.exit("Decryption Error: ", err)
  else
      kong.log("Decrypted String: ", decrypted)
  end

end 

-- return our plugin object
return aesEncHandler
