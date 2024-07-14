local script_path = "C:\\Users\\10462\\Saved Games\\DCS.openbeta\\Missions\\Scripts\\Buta\\Buta's Inferno\\Scripts\\"

local script_list =
{
    -- Load order must be correct
    "mist_4_5_122.lua",
}

local function load_scripts(path, list)
    for index, value in ipairs(list) do
        dofile(path .. value)
    end
end

if lfs then
    script_path = lfs.writedir() .. "Missions\\Scripts\\Buta\\Buta's Inferno\\Scripts\\"

    env.info("Script Loader: LFS available, using relative script load path: " .. script_path)
else
    env.info("Script Loader: LFS not available, using default script load path: " .. script_path)
end

load_scripts(script_path, script_list)
