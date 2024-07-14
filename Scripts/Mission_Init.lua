local script_list =
{
    -- Load order must be correct
    "mist.lua", --mist_4_5_122
}

local function load_scripts(path, list)
    for index, value in ipairs(list) do
        dofile(path .. value)
    end
end

load_scripts(script_path, script_list)
