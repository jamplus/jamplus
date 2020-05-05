jam = {}

--[[
setmetatable(jam, {
    __index = function(t, key)
        if jam_evaluaterule('RuleExists', key, '1')[1] == 'true' then
            local f = function(...)
                return jam_evaluaterule(key, ...)
            end
            rawset(t, key, f)
            return f
        else
            local targetkey = key
            local target = {}
            setmetatable(target, {
                __index = function(t, key)
                    return jam_getvar(targetkey, key)
                end,
                __newindex = function(t, key, value)
                    jam_setvar(targetkey, key, value)
                end,
            })
            rawset(jamtarget, targetkey, target)
            return target
        end
    end,
})
--]]

local jam_with_prefix_metatable = {}
jam_with_prefix_metatable.__index = function(t, key)
    local fullRuleName = t.prefix .. key
    if jam_evaluaterule('RuleExists', fullRuleName, '1')[1] == 'true' then
        local f = function(...)
            return jam_evaluaterule(fullRuleName, ...)
        end
        rawset(t, key, f)
        return f
    else
        local namespace = { prefix = fullRuleName .. '.' }
        setmetatable(namespace, jam_with_prefix_metatable)
        rawset(t, key, namespace)
        return namespace
    end
end

local jam_metatable = {}
jam_metatable.__index = function(t, key)
    if jam_evaluaterule('RuleExists', key, '1')[1] == 'true' then
        local f = function(...)
            return jam_evaluaterule(key, ...)
        end
        rawset(t, key, f)
        return f
    else
        local namespace = { prefix = key .. '.' }
        setmetatable(namespace, jam_with_prefix_metatable)
        rawset(t, key, namespace)
        return namespace
    end
end
setmetatable(jam, jam_metatable)

jamvar = {}
setmetatable(jamvar, {
    __index = function(t, key)
        return jam_getvar(key)
    end,
    __newindex = function(t, key, value)
        jam_setvar(key, value)
    end,
})

jamtarget = {}
setmetatable(jamtarget, {
    __index = function(t, targetkey)
        local target = {}
        setmetatable(target, {
            __index = function(t, key)
                return jam_getvar(targetkey, key)
            end,
            __newindex = function(t, key, value)
                jam_setvar(targetkey, key, value)
            end,
        })
        rawset(jamtarget, targetkey, target)
        return target
    end,
})

