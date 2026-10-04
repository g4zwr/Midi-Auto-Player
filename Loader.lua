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

local function EncodePath(path)
    local parts = {}
    for segment in string.gmatch(path, "[^/]+") do
        table.insert(parts, UrlEncode(segment))
    end
    return table.concat(parts, "/")
end

local function AddSong(f)
    local localName = NormalizeToMid(f)
    if isfile(localName) then return end

    -- older builds stored every song flat in the workspace root
    local flatName = localName:match("([^/\\]+)$")
    if flatName and flatName ~= localName and isfile(flatName) then return end

    -- mirror the repo's type folder so the UI can group by it
    local dir = localName:match("^(.*)[/\\][^/\\]+$")
    if dir and dir ~= "" and makefolder then
        pcall(makefolder, dir)
    end

    local url = RepoBase .. EncodePath(RepoPath .. f)
    local ok, data = pcall(game.HttpGet, game, url)
    if ok then
        writefile(localName, data)
        print("[MidiPlayer] Downloaded: " .. f)
    else
        warn("[MidiPlayer] Failed to fetch '" .. f .. "': " .. tostring(data))
    end
end

local function FetchDir(url, prefix, depth)
    local files = {}
    if depth > 3 then return files end

    local ok, res = pcall(game.HttpGet, game, url)
    if not ok then
        warn("[MidiPlayer] Failed to fetch repo listing: " .. tostring(res))
        return files
    end

    local decodeOk, entries = pcall(HttpService.JSONDecode, HttpService, res)
    if not decodeOk then
        warn("[MidiPlayer] Failed to decode repo listing JSON")
        return files
    end

    for _, entry in ipairs(entries) do
        if entry.type == "file" then
            local name = prefix .. entry.name
            if name:match("%.mid$") or name:match("%.rtx$") then
                table.insert(files, name)
            end
        elseif entry.type == "dir" then
            local childUrl = "https://api.github.com/repos/" .. RepoOwner .. "/" .. RepoName .. "/contents/" .. EncodePath(RepoPath .. entry.name)
            for _, sub in ipairs(FetchDir(childUrl, prefix .. entry.name .. "/", depth + 1)) do
                table.insert(files, sub)
            end
        end
    end
    return files
end

local function FetchSongList()
    return FetchDir(ApiUrl, "", 0)
end

local songList = FetchSongList()
print("[MidiPlayer] Found " .. #songList .. " song(s) in repo")

for _, f in ipairs(songList) do
    AddSong(f)
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/pianista.lua"))()
