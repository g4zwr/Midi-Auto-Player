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
local ApiUrl    = "https://api.github.com/repos/" .. RepoOwner .. "/" .. RepoName .. "/contents/" .. RepoPath:gsub("/$", "")
-- The listing is served from midi/manifest.json on raw.githubusercontent.com.
-- Walking api.github.com once per folder used to cost one request per
-- directory, and the repo has 100 of them -- far past GitHub's 60/hour
-- unauthenticated cap, so the walk failed and the loader reported a 404/403
-- from the API instead of a song list.
local ManifestUrl = RepoBase .. RepoPath .. "manifest.json"

local HttpService = game:GetService("HttpService")

local GuiUrl = RepoBase .. "pianista.lua"

-- fetch with a readable error instead of letting a raw HTTP failure abort
-- the whole script after the songs have already downloaded
local function FetchGui()
    local ok, data = pcall(game.HttpGet, game, GuiUrl)
    if not ok then
        error("[MidiPlayer] Could not download the GUI from " .. GuiUrl ..
              "\n          reason: " .. tostring(data) ..
              "\n          Open that URL in your browser to check it, then re-run.")
    end
    return data
end

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

local function IsSafePath(path)
    -- whole segments only: a title like "Devils... Monsters....mid" is fine,
    -- but a ".." segment would climb out of the workspace
    for segment in string.gmatch(path, "[^/\\]+") do
        if segment == ".." or segment == "." then
            return false
        end
    end
    return true
end

local function ManifestEntries(files)
    local out = {}
    for _, name in ipairs(files) do
        if type(name) == "string" then
            name = name:gsub("^%./", "")
            local isSong = name:match("%.mid$") or name:match("%.rtx$")
            if isSong and name ~= "" and IsSafePath(name) then
                table.insert(out, name)
            end
        end
    end
    return out
end

local function FetchManifest()
    local ok, res = pcall(game.HttpGet, game, ManifestUrl)
    if not ok then
        warn("[MidiPlayer] Failed to fetch manifest: " .. tostring(res))
        return nil
    end

    local decodeOk, parsed = pcall(HttpService.JSONDecode, HttpService, res)
    if not decodeOk then
        warn("[MidiPlayer] Failed to decode manifest JSON")
        return nil
    end

    -- accept either {"version":1,"files":[...]} or a bare array
    local files = type(parsed) == "table" and (parsed.files or parsed) or nil
    if type(files) ~= "table" then
        warn("[MidiPlayer] Manifest has no file list")
        return nil
    end

    local songs = ManifestEntries(files)
    if #songs == 0 then
        warn("[MidiPlayer] Manifest listed 0 songs")
        return nil
    end
    return songs
end

local function FetchSongList()
    local songs = FetchManifest()
    if songs then
        print("[MidiPlayer] Manifest listed " .. #songs .. " song(s)")
        return songs
    end

    -- fallback for anyone pinned to a commit from before the manifest existed
    warn("[MidiPlayer] Falling back to GitHub API listing")
    songs = FetchDir(ApiUrl, "", 0)
    if #songs == 0 then
        warn("[MidiPlayer] No songs found. Check that " .. ManifestUrl .. " loads in your browser.")
    end
    return songs
end

local songList = FetchSongList()
print("[MidiPlayer] Found " .. #songList .. " song(s) in repo")

if #songList == 0 then
    warn("[MidiPlayer] Continuing with whatever is already in the workspace")
end

for _, f in ipairs(songList) do
    AddSong(f)
end

local guiOk, guiErr = pcall(function()
    local chunk = loadstring(FetchGui())
    if type(chunk) ~= "function" then
        error("loadstring did not return a function")
    end
    return chunk()
end)
if not guiOk then
    warn("[MidiPlayer] Failed to start the GUI: " .. tostring(guiErr))
end
