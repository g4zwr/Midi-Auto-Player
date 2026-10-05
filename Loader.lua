--[[
	MIT License
	Copyright (c) 2026 g4zwr
	
    [License details omitted for brevity]
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
local GuiUrl = RepoBase .. "pianista.lua"

-- How many songs are fetched at the same time. Downloading the library one
-- file at a time is painfully slow over a shared connection; running a few
-- requests in parallel overlaps the round trips. Kept modest on purpose --
-- too many concurrent HttpGet calls just make Roblox throttle every one of
-- them. Raise it if your executor and connection can take it.
--
-- Folders are still handed out one after another so "skip" always has a
-- single unambiguous target; only files inside a folder run in parallel.
local DOWNLOAD_WORKERS = 6

local REFRESH_INTERVAL = 0.1

local HttpService = game:GetService("HttpService")
local spawnFn = (task and task.spawn) or spawn
local waitFn  = (task and task.wait) or wait

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

local function FolderOf(path)
    local dir = path:match("^(.*)[/\\][^/\\]+$")
    if dir then return dir end
    return ""
end

-- true if this song is already in the workspace, including the flat layout
-- that older builds used before the loader mirrored the type folders
local function AlreadyHave(localName)
    if isfile and isfile(localName) then return true end
    local flatName = localName:match("([^/\\]+)$")
    if flatName and flatName ~= localName and isfile and isfile(flatName) then
        return true
    end
    return false
end

local function DownloadOne(item)
    -- mirror the repo's type folder so the UI can group by it
    local dir = FolderOf(item.dest)
    if dir ~= "" and makefolder then
        pcall(makefolder, dir)
    end

    local url = RepoBase .. EncodePath(RepoPath .. item.repo)
    local ok, data = pcall(game.HttpGet, game, url)
    if not ok or type(data) ~= "string" then
        return false, 0
    end

    local wrote = pcall(writefile, item.dest, data)
    if not wrote then return false, 0 end
    return true, #data
end

---------------------------------------------------------
-- REPO LISTING
---------------------------------------------------------

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

-- Groups the songs that still need downloading by folder, keeping the
-- manifest's alphabetical order. Files already in the workspace are dropped
-- so repeat runs have nothing to do.
local function BuildQueue(songList)
    local order, byFolder = {}, {}
    for _, path in ipairs(songList) do
        local localName = NormalizeToMid(path)
        if not AlreadyHave(localName) then
            local folder = FolderOf(localName)
            if not byFolder[folder] then
                byFolder[folder] = {}
                table.insert(order, folder)
            end
            table.insert(byFolder[folder], { repo = path, dest = localName, folder = folder })
        end
    end

    local queue = {}
    for _, folder in ipairs(order) do
        for _, item in ipairs(byFolder[folder]) do
            table.insert(queue, item)
        end
    end
    return queue
end

---------------------------------------------------------
-- DOWNLOAD UI
---------------------------------------------------------

local function HumanBytes(bytes)
    if bytes < 1024 then return string.format("%d B", bytes) end
    if bytes < 1024 * 1024 then return string.format("%.1f KB", bytes / 1024) end
    return string.format("%.1f MB", bytes / (1024 * 1024))
end

local function HumanTime(seconds)
    if seconds < 0 then seconds = 0 end
    if seconds < 60 then return string.format("%ds left", math.floor(seconds)) end
    if seconds < 3600 then return string.format("%dm %ds left", math.floor(seconds / 60), math.floor(seconds % 60)) end
    return string.format("%dh %dm left", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
end

-- Built inside a pcall by the caller: a GUI failure must never stop the
-- actual downloading.
local function CreateDownloadGui(total)
    local Inst = Instance.new
    local RGB = Color3.fromRGB
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local localPlayer = Players.LocalPlayer
    local targetParent = CoreGui:FindFirstChild("RobloxGui") or localPlayer:WaitForChild("PlayerGui")

    local ACCENT = RGB(100, 120, 255)
    local TEXT_DIM = RGB(130, 130, 142)

    local function ui(className, props, parent)
        local inst = Inst(className)
        for k, v in pairs(props) do inst[k] = v end
        if parent then inst.Parent = parent end
        return inst
    end
    local function corner(parent, radius)
        ui("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
    end

    local screen = ui("ScreenGui", {
        Name = "MidiAutoPlayerDownloader",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = targetParent
    })

    local card = ui("Frame", {
        Size = UDim2(0, 380, 0, 186),
        Position = UDim2(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = RGB(18, 18, 22),
        BorderSizePixel = 0,
        Parent = screen
    })
    corner(card, 12)
    ui("UIStroke", {
        Color = RGB(255, 255, 255),
        Thickness = 1,
        Transparency = 0.85,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = card
    }, card)

    local title = ui("TextLabel", {
        Size = UDim2(1, -28, 0, 22),
        Position = UDim2(0, 14, 0, 10),
        BackgroundTransparency = 1,
        TextColor3 = RGB(255, 255, 255),
        Text = "Downloading MIDI library",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local subtitle = ui("TextLabel", {
        Size = UDim2(1, -28, 0, 16),
        Position = UDim2(0, 14, 0, 32),
        BackgroundTransparency = 1,
        TextColor3 = TEXT_DIM,
        Text = total .. " song(s) left to download",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local barBack = ui("Frame", {
        Size = UDim2(1, -28, 0, 14),
        Position = UDim2(0, 14, 0, 56),
        BackgroundColor3 = RGB(38, 38, 46),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = card
    })
    corner(barBack, 7)

    local barFill = ui("Frame", {
        Size = UDim2(0, 0, 1, 0),
        BackgroundColor3 = ACCENT,
        BorderSizePixel = 0,
        Parent = barBack
    })
    corner(barFill, 7)

    local percentLabel = ui("TextLabel", {
        Size = UDim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = RGB(255, 255, 255),
        Text = "0%",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        Parent = barBack
    })

    local folderLabel = ui("TextLabel", {
        Size = UDim2(1, -28, 0, 15),
        Position = UDim2(0, 14, 0, 78),
        BackgroundTransparency = 1,
        TextColor3 = ACCENT,
        Text = "",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local fileLabel = ui("TextLabel", {
        Size = UDim2(1, -28, 0, 15),
        Position = UDim2(0, 14, 0, 94),
        BackgroundTransparency = 1,
        TextColor3 = TEXT_DIM,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card
    })

    local statsLabel = ui("TextLabel", {
        Size = UDim2(1, -28, 0, 15),
        Position = UDim2(0, 14, 0, 114),
        BackgroundTransparency = 1,
        TextColor3 = TEXT_DIM,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    local skipButton = ui("TextButton", {
        Size = UDim2(0, 170, 0, 30),
        Position = UDim2(0, 14, 0, 140),
        BackgroundColor3 = RGB(46, 46, 56),
        BorderSizePixel = 0,
        TextColor3 = RGB(255, 255, 255),
        Text = "Skip this folder",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = true,
        Parent = card
    })
    corner(skipButton, 8)

    local parallelLabel = ui("TextLabel", {
        Size = UDim2(0, 160, 0, 30),
        Position = UDim2(1, -174, 0, 140),
        BackgroundTransparency = 1,
        TextColor3 = TEXT_DIM,
        Text = DOWNLOAD_WORKERS .. " at a time",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = card
    })

    return {
        screen = screen,
        title = title,
        subtitle = subtitle,
        barFill = barFill,
        percentLabel = percentLabel,
        folderLabel = folderLabel,
        fileLabel = fileLabel,
        statsLabel = statsLabel,
        skipButton = skipButton,
        parallelLabel = parallelLabel
    }
end

---------------------------------------------------------
-- DOWNLOAD ENGINE
---------------------------------------------------------

local function RunDownloads(queue)
    local total = #queue

    local state = {
        cursor = 0,        -- next index to hand out
        active = 0,        -- workers currently holding an item
        ok = 0,
        failed = 0,
        skipped = 0,
        bytes = 0,
        folder = queue[1].folder,
        file = "",
        skipFolders = {},  -- folders the user chose to skip
        skippedFolders = 0,
        finished = false,
        startedAt = os.clock(),
    }

    -- how many files of each folder are still queued, for the skip button
    local remaining = {}
    for _, item in ipairs(queue) do
        remaining[item.folder] = (remaining[item.folder] or 0) + 1
    end

    local ui
    local uiOk, uiErr = pcall(function()
        ui = CreateDownloadGui(total)
    end)
    if not uiOk then
        ui = nil
        warn("[MidiPlayer] Download progress UI unavailable (" .. tostring(uiErr) ..
             ") - still downloading.")
    end

    local function claim()
        local i = state.cursor + 1
        if i > total then return nil end
        state.cursor = i
        state.active = state.active + 1
        return queue[i]
    end

    local function release()
        state.active = state.active - 1
    end

    local function worker()
        while true do
            local item = claim()
            if not item then return end

            -- exact count of files of this folder still queued, for the
            -- skip button. claim() never yields, so this cannot race.
            remaining[item.folder] = math.max((remaining[item.folder] or 1) - 1, 0)

            if state.skipFolders[item.folder] then
                state.skipped = state.skipped + 1
                release()
            else
                state.folder = item.folder
                state.file = item.repo
                local ok, bytes = DownloadOne(item)
                if ok then
                    state.ok = state.ok + 1
                    state.bytes = state.bytes + (bytes or 0)
                else
                    state.failed = state.failed + 1
                end
                release()
            end
        end
    end

    local function pressSkip()
        local folder = state.folder
        if not folder or state.skipFolders[folder] then return end
        state.skipFolders[folder] = true
        state.skippedFolders = state.skippedFolders + 1
    end

    if ui then
        pcall(function() ui.skipButton.MouseButton1Click:Connect(pressSkip) end)
    end

    local workers = math.min(DOWNLOAD_WORKERS, total)
    for _ = 1, workers do
        spawnFn(worker)
    end

    local function refresh()
        local settled = state.ok + state.failed + state.skipped
        local frac = total > 0 and (settled / total) or 1
        local elapsed = os.clock() - state.startedAt
        local left = total - state.cursor
        local rate = elapsed > 0 and (state.bytes / elapsed) or 0
        local eta = rate > 0 and ((left * 35000) / rate) or -1

        if ui then
            ui.barFill.Size = UDim2.new(math.min(frac, 1), 0, 1, 0)
            ui.percentLabel.Text = tostring(math.floor(frac * 100)) .. "%"
            ui.subtitle.Text = total .. " song(s) to download"
            ui.folderLabel.Text = state.folder ~= "" and ("Folder: " .. state.folder) or ""
            ui.fileLabel.Text = state.file ~= "" and state.file or "starting..."
            ui.statsLabel.Text = string.format(
                "%d/%d files  -  %s  -  %s  -  %d skipped",
                settled, total, HumanBytes(state.bytes), HumanTime(eta), state.skipped)
            ui.skipButton.Text = (remaining[state.folder] or 0) > 0
                and ("Skip this folder (" .. (remaining[state.folder]) .. " left)")
                or "Nothing left to skip"
        end
    end

    local function monitor()
        refresh()
        while not state.finished do
            -- claim()/release() never yield, so this is safe to read mid-flight
            if state.cursor >= total and state.active == 0 then
                state.finished = true
            end
            if state.finished then break end
            waitFn(REFRESH_INTERVAL)
            refresh()
        end
        refresh()

        if ui then
            ui.skipButton.Text = "Done"
            ui.title.Text = state.skipped > 0 and "Library partially downloaded" or "Library downloaded"
            ui.fileLabel.Text = string.format(
                "%d downloaded, %d failed, %d skipped (%d folder(s))",
                state.ok, state.failed, state.skipped, state.skippedFolders)
        end

        waitFn(0.8)
        if ui then pcall(function() ui.screen:Destroy() end) end
    end

    spawnFn(monitor)

    -- block until every worker has drained the queue
    while not state.finished do
        waitFn(REFRESH_INTERVAL)
    end

    print(string.format(
        "[MidiPlayer] Downloads finished: %d ok, %d failed, %d skipped (%d folder(s)), %s in %.1fs",
        state.ok, state.failed, state.skipped, state.skippedFolders,
        HumanBytes(state.bytes), os.clock() - state.startedAt))

    return state
end

---------------------------------------------------------
-- MAIN
---------------------------------------------------------

local songList = FetchSongList()
print("[MidiPlayer] Found " .. #songList .. " song(s) in repo")

local queue = BuildQueue(songList)
if #queue > 0 then
    print("[MidiPlayer] " .. #queue .. " song(s) need downloading, " ..
          DOWNLOAD_WORKERS .. " at a time")
    RunDownloads(queue)
else
    print("[MidiPlayer] Library already up to date, nothing to download")
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