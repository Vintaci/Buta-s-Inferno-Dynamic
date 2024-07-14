ScriptPath = lfs.writedir() .. "Missions\\Scripts\\Buta\\Buta's Inferno-Dynamic\\Scripts\\"

if lfs then
    dofile(ScriptPath..'Mission_Init.lua')

    env.info("Script Loader: LFS available, using relative script load path: " .. script_path)
else
    env.info("Script Loader: LFS not available, using default script load path: " .. script_path)
end