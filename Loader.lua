local RepoBase = "https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/"

local function AddSong(filename)
    if isfile(filename) then return end

    local url = RepoBase .. filename:gsub(" ", "%%20")
    local ok, data = pcall(game.HttpGet, game, url)
    if ok then
        writefile(filename, data)
    else
        warn("[MidiPlayer] Failed to fetch '" .. filename .. "': " .. tostring(data))
    end
end

AddSong("Golden-Brown.mid")
AddSong("Jack - Golden hour.mid")
AddSong("rush_e_real.mid")

loadstring(game:HttpGet("https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/pianista.lua"))()
