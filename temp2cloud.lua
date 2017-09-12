--'
-- Finds connected DS18B20 sensors, reads temperatures
-- and eventually updates  TeamSpeak channel with received values
-- Based on NODEMCU TEAM examples (nodemcu.com)
--
-- Author: Tomasz Ceszke (tomek.ceszke.com)
--'

require "settings"
require "keys"

function checkSensor(addr)
    local sensor_id = addr:byte(8, 8)
    --print("Checking "..sensor_id.." sensor")
    local crc = ow.crc8(string.sub(addr, 1, 7))
    if (crc == addr:byte(8)) then
        if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
            return true
        else
            print(sensor_id .. ": device family is not recognized.")
        end
    else
        print(sensor_id .. ": CRC is not valid!")
    end
    return false
end

function getTemp(sensor)
    ow.reset(pin)
    ow.select(pin, sensor)
    ow.write(pin, 0x44, 1)
    ow.reset(pin)
    ow.select(pin, sensor)
    ow.write(pin, 0xBE, 1)
    local data = string.char(ow.read(pin))
    for i = 1, 8 do
        --noinspection StringConcatenationInLoops
        data = data .. string.char(ow.read(pin))
    end
    local crc = ow.crc8(string.sub(data, 1, 8))
    if (crc == data:byte(9)) then
        local t = (data:byte(1) + data:byte(2) * 256)
        if (t > 0x7fff) then
            t = t - 0x10000
        end
        if (sensor:byte(1) == 0x28) then
            t = t * 625
        else
            t = t * 5000
        end
        local sign = ""
        if (t < 0) then
            sign = "-"
            t = -1 * t
        end
        local t1 = string.format("%d", t / 10000)
        local t2 = string.format("%04u", t % 10000)
        local temp = sign .. t1 .. "." .. t2
        return temp
    end
end

function postThingSpeak(value, field)
    local connout = net.createConnection(net.TCP, 0)
    connout:on("receive", function(_, payloadout)
        if (string.find(payloadout, "Status: 200 OK") ~= nil) then
            print("Posted OK");
        end
    end)

    connout:on("connection", function(connout, _)
        connout:send("GET /update?api_key=" .. ts_api_key .. "&" .. field .. "=" .. value
                .. " HTTP/1.1\r\n"
                .. "Host: api.thingspeak.com\r\n"
                .. "Connection: close\r\n"
                .. "Accept: */*\r\n"
                .. "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
                .. "\r\n")
    end)

    connout:on("disconnection", function(_, _)
        --connout:close();
        collectgarbage();
    end)

    connout:connect(80, 'api.thingspeak.com')
end


function findSensors()
    ow.setup(pin)
    local lsensors = {}
    local count = 1

    repeat
        --addr = ow.reset_search(pin)
        local addr = ow.search(pin)
        if (addr == nil) then
            break
        end
        if checkSensor(addr) then
            lsensors[count] = addr
            count = count + 1
        end
    until false

    return lsensors
end

function startJob(sensor_id, sensor_update_sec, sensor_field)
    if sensors[sensor_id] then
        print("Starting job for sensor id " .. sensor_id)
        tmr.alarm(sensor_id, sensor_update_sec * 1000, tmr.ALARM_AUTO, function()
            local temp = getTemp(sensors[sensor_id])
            if (temp~="85.0000") then
                print(sensor_id .. ": updating TS with temp: " .. temp)
                postThingSpeak(temp, sensor_field)
            else
                print(sensor_id .. ": won't update TS with temp: " .. temp)
            end
        end)
    else
        print("ERROR: Sensor id " .. sensor_id .. " not found. Ignoring.")
    end
end

