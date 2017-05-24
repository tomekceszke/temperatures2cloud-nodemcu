local modname = ...
local M = {}
_G[modname] = M

setfenv(1,M)

function setup(pin)
    --print("Setup pin: "..pin)
end

function search(pin)
    --print("Setup pin: "..pin)
end

function reset(pin)
    --print("Reset pin: "..pin)
end

function select(pin,sensor)
    --print("Select pin: "..pin.." and sensor: "..sensor)
end

return M



