--[[
	MIT License
	Copyright (c) 2026 g4zwr
	...
]]

if getgenv().MidiAutoPlayerLoaded then
    warn("[MidiPlayer] Script is already running!")
    return
end
getgenv().MidiAutoPlayerLoaded = true

local RepoOwner = "g4zwr"
local RepoName  = "Midi-Auto-Player"
local RepoPath  = "midi/" 
local RepoBase  = "https://raw.githubusercontent.com/" .. RepoOwner .. "/" .. RepoName .. "/refs/heads/main/"
local ApiUrl    = "https://api.github.com/repos/" .. RepoOwner .. "/" .. RepoName .. "/contents/" .. RepoPath

local HttpService = game:GetService("HttpService")

local function UrlEncode(str)
    return (str:gsub("([^%w%-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function NormalizeToMid(name)
    name = name:gsub("%.mid%.rtx$", ".mid")
    name = name:gsub("%.rtx$", ".mid")
    return name
end

local function AddSong(f)
    local localName = NormalizeToMid(f)
    if isfile(localName) then return end

    local url = RepoBase .. RepoPath .. UrlEncode(f)
    local ok, data = pcall(game.HttpGet, game, url)
    if ok then
        writefile(localName, data)
        print("[MidiPlayer] Downloaded: " .. f)
    else
        warn("[MidiPlayer] Failed to fetch '" .. f .. "': " .. tostring(data))
    end
end

local function FetchSongList()
    local ok, res = pcall(game.HttpGet, game, ApiUrl)
    if not ok then
        warn("[MidiPlayer] Failed to fetch repo listing: " .. tostring(res))
        return {}
    end

    local decodeOk, entries = pcall(HttpService.JSONDecode, HttpService, res)
    if not decodeOk then
        warn("[MidiPlayer] Failed to decode repo listing JSON")
        return {}
    end

    local files = {}
    for _, entry in ipairs(entries) do
        if entry.type == "file" then
            local name = entry.name
            if name:match("%.mid$") or name:match("%.rtx$") then
                table.insert(files, name)
            end
        end
    end
    return files
end

local songList = FetchSongList()
print("[MidiPlayer] Found " .. #songList .. " song(s) in repo")

for _, f in ipairs(songList) do
    AddSong(f)
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/pianista.lua"))()
