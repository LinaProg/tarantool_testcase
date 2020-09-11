box.cfg{}

local log =require('log')

kv = box.schema.space.create(
    'KeyValue',
    {
        format = {
            {name = 'key', type = 'string'},
            {name = 'value', type = 'map'},
        },
        if_not_exists = true,
    }
)

kv:create_index('primary', {
    type = 'hash',
    parts = {'key'},
    if_not_exists = true,
})

function create_resp(request,status,value)
    local resp_json = {}
    if value then
        resp_json["value"] = value
    end
    if status == 400 then
        resp_json["message"] = "Incorrect body"
    elseif status == 404 then
        resp_json["message"] = "Not found"
    elseif status == 409 then
        resp_json["message"] = "The key is already used"
    else 
        resp_json["message"] = "OK"
    end
    local resp = request:render({json = resp_json})
    resp.status = status
    resp.headers = { ['content-type'] = 'application/json; charset=utf8' }
    return resp
end

function get_handler(req)
    local id = req:stash('id')

    local contains = kv:select{id}[1]
    log.info("GET request: trying to find tuple with key " .. id)
    if contains == nil then 
        log.info("GET request: didn't found tuple with key " .. id)
        return create_resp(req,404)
    end
    log.info("GET request: found tuple with key " .. id)
    return create_resp(req,200,contains[2])
end

function put_handler(req)
    local id = req:stash('id')

    local success, data = pcall(check_request,req)

    log.info("PUT request: checking valid body")
    if not success or  
    data['value'] == nil 
    or type(data['value']) ~= 'table' then
        log.info("PUT request: body is invalid")
        return create_resp(req,400)
    end
    log.info("PUT request: body is valid")
    log.info("PUT request: trying to find tuple with key " .. id)
    local contains = kv:select{id}[1]
    if contains == nil then 
        log.info("PUT request: didn't found tuple with key " .. id)
        return create_resp(req,404)
    end
    log.info("PUT request: found tuple with key " .. id)
    log.info("PUT request: updating data with key " .. id)
    kv:put{id,data['value']}

    return create_resp(req,200)
end

function del_handler(req)
    local id = req:stash('id')

    log.info("DELETE request: trying to find tuple with key " .. id)
    if kv:select{id}[1]== nil then 
        log.info("DELETE request: didn't found tuple with key " .. id)
        return create_resp(req,404)
    end
    log.info("DELETE request: found tuple with key " .. id)
    log.info("DELETE request: deleting tuple with key " .. id)
    kv:delete{id}

    return create_resp(req,200)
end

function check_request(req)
    return req:json()
end


function post_handler(req)

    local success, data = pcall(check_request,req)
    log.info("POST request: checking valid body")
    if not success or 
    data['key'] == nil or 
    data['value'] == nil 
    or type(data['value']) ~= 'table' then
        log.info("POST request: body is invalid")
        return create_resp(req,400)
    end
    log.info("POST request: body is valid")
    local id = data['key']
    log.info("POST request: trying to find tuple with key " .. id)
    if kv:select{id}[1] ~= nil then 
        log.info("POST request: found tuple with key " .. id)
        return create_resp(req,409)
    end
    local value = data ['value']
    log.info("POST request: didn't found tuple with key " .. id)
    log.info("POST request: inserting value with key " .. id)
    kv:insert{id,value}
    return create_resp(req,200)
end

server = require('http.server').new('0.0.0.0',8080)
router = require('http.router').new()

router:route({path = 'kv', method = 'POST' }, post_handler)
router:route({path = 'kv/:id', method = 'GET' }, get_handler)
router:route({path = '/kv/:id', method = 'PUT' }, put_handler)
router:route({path = '/kv/:id', method = 'DELETE' }, del_handler)
server:set_router(router)
server:start()

-- require('console').start()

