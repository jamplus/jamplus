jam = {}

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

