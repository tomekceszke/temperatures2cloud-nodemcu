require "temp2cloud"
require "settings"

sensors = findSensors()

if (#sensors > 0) then
    print("Found " .. #sensors .. " sensor(s):")
    for k, v in pairs(sensors) do
        print(k .. " (" .. v:byte(8, 8) .. "): " .. getTemp(sensors[k]))
    end
else
    print("Found no sensors. Bye...")
    return
end

for k, v in pairs(known_sensors_settings) do
    startJob(k, v[1], v[2])
end