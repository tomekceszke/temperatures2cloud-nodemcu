--'
-- Settings
--
-- Author: Tomasz Ceszke (tomek.ceszke.com)
--'

pin = 4 -- GPIO pin where DS18B20 sensors are connected

-- format [id] = { update_interval_in_seconds, "ts mapping field" }
known_sensors_settings = {
    [1] = { 55, "field3" },
    [2] = { 606, "field2" }
}
