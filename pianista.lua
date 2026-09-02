--[[
	MIT License

	Copyright (c) 2026 g4zwr

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]


local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local wait = task.wait
local delay = task.delay
local spawn = task.spawn
local sub = string.sub
local byte = string.byte
local upper = string.upper
local lower = string.lower
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local insert = table.insert
local sort = table.sort
local uDim2 = UDim2.new
local uDim = UDim.new
local rgb = Color3.fromRGB
local tweenInfoNew = TweenInfo.new

local localPlayer = Players.LocalPlayer
local targetParent = CoreGui:FindFirstChild("RobloxGui") or localPlayer:WaitForChild("PlayerGui")

local createUI = function(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local screenGui = createUI("ScreenGui", {
    Name = "VirtualPianoPlayer",
    Parent = targetParent
})

local toggleButton = createUI("TextButton", {
    Size = uDim2(0, 30, 0, 30),
    Position = uDim2(0, 20, 0, 20),
    BackgroundColor3 = rgb(0, 0, 0),
    TextColor3 = rgb(255, 255, 255),
    Text = "VP",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Draggable = true,
    Active = true,
    Parent = screenGui
})
createUI("UICorner", { CornerRadius = uDim(0, 6), Parent = toggleButton })
createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 2, Parent = toggleButton })

local mainFrame = createUI("Frame", {
    Size = uDim2(0, 480, 0, 320),
    Position = uDim2(0.5, -240, 0.5, -160),
    BackgroundColor3 = rgb(10, 10, 10),
    Visible = false,
    Draggable = true,
    Active = true,
    Parent = screenGui
})
createUI("UICorner", { CornerRadius = uDim(0, 8), Parent = mainFrame })
createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 2, Parent = mainFrame })

local topBar = createUI("Frame", {
    Size = uDim2(1, 0, 0, 25),
    BackgroundTransparency = 1,
    Parent = mainFrame
})
createUI("TextLabel", {
    Size = uDim2(0.5, 0, 1, 0),
    Position = uDim2(0.5, -10, 0, 0),
    BackgroundTransparency = 1,
    TextColor3 = rgb(255, 255, 255),
    Text = "MIDI Player",
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = topBar
})

local visualizerContainer = createUI("Frame", {
    Size = uDim2(0, 240, 0, 90),
    Position = uDim2(0, 10, 0, 25),
    BackgroundColor3 = rgb(0, 0, 0),
    ClipsDescendants = true,
    Parent = mainFrame
})
createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 1, Parent = visualizerContainer })

local noteDropArea = createUI("Frame", {
    Size = uDim2(1, 0, 1, -30),
    Position = uDim2(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = visualizerContainer
})

local pianoKeysFrame = createUI("Frame", {
    Size = uDim2(1, 0, 0, 30),
    Position = uDim2(0, 0, 1, -30),
    BackgroundColor3 = rgb(20, 20, 20),
    Parent = visualizerContainer
})

local leftPanel = createUI("Frame", {
    Size = uDim2(0.55, -15, 1, -125),
    Position = uDim2(0, 10, 0, 120),
    BackgroundTransparency = 1,
    Parent = mainFrame
})

local statusLabel = createUI("TextLabel", {
    Size = uDim2(1, 0, 0, 20),
    BackgroundTransparency = 1,
    TextColor3 = rgb(255, 255, 255),
    Text = "No file selected",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = leftPanel
})

local transposeInput = createUI("TextBox", {
    Size = uDim2(0.48, -5, 0, 25),
    Position = uDim2(0, 0, 0, 25),
    BackgroundColor3 = rgb(0, 0, 0),
    TextColor3 = rgb(255, 255, 255),
    Text = "0",
    PlaceholderText = "Transpose (semitones)",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = leftPanel
})
createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 1, Parent = transposeInput })

local speedInput = createUI("TextBox", {
    Size = uDim2(0.48, -5, 0, 25),
    Position = uDim2(0.52, 0, 0, 25),
    BackgroundColor3 = rgb(0, 0, 0),
    TextColor3 = rgb(255, 255, 255),
    Text = "1.0",
    PlaceholderText = "Speed x",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = leftPanel
})
createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 1, Parent = speedInput })

local refreshButton = createUI("TextButton", {
    Size = uDim2(1, 0, 0, 25),
    Position = uDim2(0, 0, 0, 55),
    BackgroundColor3 = rgb(40, 40, 40),
    TextColor3 = rgb(255, 255, 255),
    Text = "Rescan Files",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = leftPanel
})
createUI("UICorner", { CornerRadius = uDim(0, 4), Parent = refreshButton })

local playButton = createUI("TextButton", {
    Size = uDim2(0.48, -5, 0, 25),
    Position = uDim2(0, 0, 1, -55),
    BackgroundColor3 = rgb(255, 255, 255),
    TextColor3 = rgb(0, 0, 0),
    Text = "Play",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Parent = leftPanel
})
createUI("UICorner", { CornerRadius = uDim(0, 4), Parent = playButton })

local pauseButton = createUI("TextButton", {
    Size = uDim2(0.48, 0, 0, 25),
    Position = uDim2(0.52, 0, 1, -55),
    BackgroundColor3 = rgb(40, 40, 40),
    TextColor3 = rgb(255, 255, 255),
    Text = "Pause",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Parent = leftPanel
})
createUI("UICorner", { CornerRadius = uDim(0, 4), Parent = pauseButton })

local rightPanel = createUI("ScrollingFrame", {
    Size = uDim2(0.45, -10, 1, -40),
    Position = uDim2(0.55, 5, 0, 30),
    BackgroundColor3 = rgb(0, 0, 0),
    CanvasSize = uDim2(0, 0, 0, 0),
    ScrollBarThickness = 4,
    Parent = mainFrame
})
createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 1, Parent = rightPanel })
createUI("UIListLayout", {
    Padding = uDim(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = rightPanel
})

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

local keyCodeMap = {
    ["1"]="One", ["2"]="Two", ["3"]="Three", ["4"]="Four", ["5"]="Five",
    ["6"]="Six", ["7"]="Seven", ["8"]="Eight", ["9"]="Nine", ["0"]="Zero",
    ["!"]="One", ["@"]="Two", ["$"]="Four", ["%"]="Five", ["^"]="Six",
    ["*"]="Eight", ["("]="Nine"
}

local chromaticNotes = {
    -- Octave 1: 1..7
    { char = "1", isBlack = false }, { char = "!", isBlack = true },
    { char = "2", isBlack = false }, { char = "@", isBlack = true },
    { char = "3", isBlack = false }, { char = "4", isBlack = false },
    { char = "$", isBlack = true },  { char = "5", isBlack = false },
    { char = "%", isBlack = true },  { char = "6", isBlack = false },
    { char = "^", isBlack = true },  { char = "7", isBlack = false },

    -- Octave 2: 8..r
    { char = "8", isBlack = false }, { char = "*", isBlack = true },
    { char = "9", isBlack = false }, { char = "(", isBlack = true },
    { char = "0", isBlack = false }, { char = "q", isBlack = false },
    { char = "Q", isBlack = true },  { char = "w", isBlack = false },
    { char = "W", isBlack = true },  { char = "e", isBlack = false },
    { char = "E", isBlack = true },  { char = "r", isBlack = false },

    -- Octave 3: t..a
    { char = "t", isBlack = false }, { char = "T", isBlack = true },
    { char = "y", isBlack = false }, { char = "Y", isBlack = true },
    { char = "u", isBlack = false }, { char = "i", isBlack = false },
    { char = "I", isBlack = true },  { char = "o", isBlack = false },
    { char = "O", isBlack = true },  { char = "p", isBlack = false },
    { char = "P", isBlack = true },  { char = "a", isBlack = false },

    -- Octave 4: s..k
    { char = "s", isBlack = false }, { char = "S", isBlack = true },
    { char = "d", isBlack = false }, { char = "D", isBlack = true },
    { char = "f", isBlack = false }, { char = "g", isBlack = false },
    { char = "G", isBlack = true },  { char = "h", isBlack = false },
    { char = "H", isBlack = true },  { char = "j", isBlack = false },
    { char = "J", isBlack = true },  { char = "k", isBlack = false },

    -- Octave 5: l..n
    { char = "l", isBlack = false }, { char = "L", isBlack = true },
    { char = "z", isBlack = false }, { char = "Z", isBlack = true },
    { char = "x", isBlack = false }, { char = "c", isBlack = false },
    { char = "C", isBlack = true },  { char = "v", isBlack = false },
    { char = "V", isBlack = true },  { char = "b", isBlack = false },
    { char = "B", isBlack = true },  { char = "n", isBlack = false },

    -- Octave 6: m, y..a (extended top keys)
    { char = "m", isBlack = false }, { char = "Y", isBlack = true },
    { char = "y", isBlack = false }, { char = "U", isBlack = true },
    { char = "u", isBlack = false }, { char = "i", isBlack = false },
    { char = "O", isBlack = true },  { char = "o", isBlack = false },
    { char = "P", isBlack = true },  { char = "p", isBlack = false },
    { char = "A", isBlack = true },  { char = "a", isBlack = false },

    -- Octave 7: s..k (extended top keys)
    { char = "s", isBlack = false }, { char = "D", isBlack = true },
    { char = "d", isBlack = false }, { char = "F", isBlack = true },
    { char = "f", isBlack = false }, { char = "g", isBlack = false },
    { char = "H", isBlack = true },  { char = "h", isBlack = false },
    { char = "J", isBlack = true },  { char = "j", isBlack = false },
    { char = "K", isBlack = true },  { char = "k", isBlack = false },

    -- Octave 8: l..m (extended top keys)
    { char = "l", isBlack = false }, { char = "L", isBlack = true },
    { char = "z", isBlack = false }, { char = "Z", isBlack = true },
    { char = "x", isBlack = false }, { char = "c", isBlack = false },
    { char = "C", isBlack = true },  { char = "v", isBlack = false },
    { char = "V", isBlack = true },  { char = "b", isBlack = false },
    { char = "B", isBlack = true },  { char = "n", isBlack = false },
    { char = "m", isBlack = false }
}

local totalWhiteKeys = 0
for _, item in ipairs(chromaticNotes) do
    if not item.isBlack then totalWhiteKeys = totalWhiteKeys + 1 end
end

local whiteKeyWidth = 1 / totalWhiteKeys
local currentWhiteIndex = 0

for _, item in ipairs(chromaticNotes) do
    if not item.isBlack then
        currentWhiteIndex = currentWhiteIndex + 1
        local keyXPos = (currentWhiteIndex - 1) * whiteKeyWidth
        local wKey = createUI("Frame", {
            Size = uDim2(whiteKeyWidth, -1, 1, 0),
            Position = uDim2(keyXPos, 0, 0, 0),
            BackgroundColor3 = rgb(255, 255, 255),
            ZIndex = 1,
            Parent = pianoKeysFrame
        })
        createUI("UIStroke", { Color = rgb(0, 0, 0), Thickness = 1, Parent = wKey })
        item.data = { frame = wKey, xPos = keyXPos, width = whiteKeyWidth, isBlack = false }
    else
        local keyXPos = (currentWhiteIndex - 1) * whiteKeyWidth + (whiteKeyWidth * 0.65)
        local bKey = createUI("Frame", {
            Size = uDim2(whiteKeyWidth * 0.7, 0, 0.6, 0),
            Position = uDim2(keyXPos, 0, 0, 0),
            BackgroundColor3 = rgb(0, 0, 0),
            ZIndex = 3,
            Parent = pianoKeysFrame
        })
        createUI("UIStroke", { Color = rgb(255, 255, 255), Thickness = 1, Parent = bKey })
        item.data = { frame = bKey, xPos = keyXPos, width = whiteKeyWidth * 0.7, isBlack = true }
    end
end

local BASE_MIDI_NOTE = 24
local KEY_RANGE = #chromaticNotes

local function midiNoteToKeyData(noteNumber, transposeSemitones)
    local n = noteNumber + (transposeSemitones or 0)
    while n < BASE_MIDI_NOTE do n = n + 12 end
    while n >= BASE_MIDI_NOTE + KEY_RANGE do n = n - 12 end
    local idx = (n - BASE_MIDI_NOTE) + 1
    if idx < 1 or idx > KEY_RANGE then return nil end
    return chromaticNotes[idx]
end

local spawnFallingNote = function(keyData, rawDuration, userSpeed)
    local baseSpeed = 100
    local effectiveSpeed = baseSpeed * userSpeed
    local dropHeight = noteDropArea.AbsoluteSize.Y
    if dropHeight <= 0 then dropHeight = 60 end

    local noteHeight = math.max(rawDuration * baseSpeed, 4)
    local totalDistance = dropHeight + noteHeight
    local fallDuration = totalDistance / effectiveSpeed

    local noteBlock = createUI("Frame", {
        Size = uDim2(keyData.width, 0, 0, noteHeight),
        Position = uDim2(keyData.xPos, 0, 0, -noteHeight),
        BackgroundColor3 = keyData.isBlack and rgb(200, 200, 200) or rgb(255, 255, 255),
        ZIndex = 2,
        Parent = noteDropArea
    })
    createUI("UICorner", { CornerRadius = uDim(0, 2), Parent = noteBlock })

    local tween = TweenService:Create(noteBlock, tweenInfoNew(fallDuration, Enum.EasingStyle.Linear), {
        Position = uDim2(keyData.xPos, 0, 1, 0)
    })
    
    tween.Completed:Connect(function()
        if noteBlock and noteBlock.Parent then noteBlock:Destroy() end
    end)
    
    tween:Play()
end

local currentPlayId = 0
local activeKeyStates = {}
local shiftedKeyCount = 0

local function isShiftedChar(char)
    if not char then return false end
    return char:match("[%u!@$%%^%*%(]") ~= nil
end

local function pressKeyChar(char, keyData)
    if not keyData then return end

    local existing = activeKeyStates[char]
    if existing then
        existing.refCount = existing.refCount + 1
        return
    end

    local mapped = keyCodeMap[char] or upper(char)
    local ok, keyCode = pcall(function() return Enum.KeyCode[mapped] end)
    if not ok or not keyCode then return end

    keyData.frame.BackgroundColor3 = rgb(120, 120, 120)

    local shifted = isShiftedChar(char)

    if shifted then
        if shiftedKeyCount == 0 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        end
        shiftedKeyCount = shiftedKeyCount + 1
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    else
        -- If shift is currently held down by other notes, temporarily release it for this white key press
        if shiftedKeyCount > 0 then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        else
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        end
    end

    activeKeyStates[char] = { keyCode = keyCode, refCount = 1, data = keyData, isShifted = shifted }
end

local function releaseKeyChar(char)
    local state = activeKeyStates[char]
    if not state then return end

    state.refCount = state.refCount - 1
    if state.refCount > 0 then return end

    VirtualInputManager:SendKeyEvent(false, state.keyCode, false, game)
    state.data.frame.BackgroundColor3 = state.data.isBlack and rgb(0, 0, 0) or rgb(255, 255, 255)

    if state.isShifted then
        shiftedKeyCount = math.max(0, shiftedKeyCount - 1)
        if shiftedKeyCount == 0 then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end
    end

    activeKeyStates[char] = nil
end

local function releaseAllKeys()
    for char in pairs(activeKeyStates) do
        activeKeyStates[char].refCount = 1
        releaseKeyChar(char)
    end
    shiftedKeyCount = 0
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
end

local function readUint16(data, pos)
    return byte(data, pos) * 256 + byte(data, pos + 1)
end

local function readUint32(data, pos)
    return byte(data, pos) * 16777216 + byte(data, pos + 1) * 65536 + byte(data, pos + 2) * 256 + byte(data, pos + 3)
end

local function readVarLen(data, pos)
    local value = 0
    local b
    repeat
        b = byte(data, pos)
        if not b then
            error("readVarLen: unexpected end of data at position " .. pos, 0)
        end
        pos = pos + 1
        value = (value * 128) + (b % 128)
    until b < 128
    return value, pos
end

local function parseMidiBytes(data)
    if sub(data, 1, 4) ~= "MThd" then
        return nil, "Not a valid MIDI file (missing MThd header)"
    end

    local headerLen = readUint32(data, 5)
    local format = readUint16(data, 9)
    local ntrks = readUint16(data, 11)
    local division = readUint16(data, 13)

    if division >= 32768 then
        return nil, "SMPTE time division is not supported"
    end

    local pos = 9 + headerLen 
    local allEvents = {}
    local seqId = 0

    for _ = 1, ntrks do
        if sub(data, pos, pos + 3) ~= "MTrk" then break end
        local trackLen = readUint32(data, pos + 4)
        local trackEnd = math.min(pos + 8 + trackLen, #data + 1)
        local cursor = pos + 8
        local tick = 0
        local runningStatus = nil

        while cursor < trackEnd do
            local delta
            delta, cursor = readVarLen(data, cursor)
            tick = tick + delta

            local statusByte = byte(data, cursor)

            if statusByte == 0xFF then
                cursor = cursor + 1
                local metaType = byte(data, cursor)
                cursor = cursor + 1
                local len
                len, cursor = readVarLen(data, cursor)
                if metaType == 0x51 and len == 3 then
                    local us = byte(data, cursor) * 65536 + byte(data, cursor + 1) * 256 + byte(data, cursor + 2)
                    seqId = seqId + 1
                    insert(allEvents, { tick = tick, kind = "tempo", usPerQuarter = us, id = seqId })
                end
                cursor = cursor + len
            elseif statusByte == 0xF0 or statusByte == 0xF7 then
                cursor = cursor + 1
                local len
                len, cursor = readVarLen(data, cursor)
                cursor = cursor + len
            else
                local status
                if statusByte >= 0x80 then
                    status = statusByte
                    runningStatus = status
                    cursor = cursor + 1
                else
                    status = runningStatus
                end
                if not status then break end

                local eventType = status - (status % 16)
                local channel = status % 16
                local data1 = byte(data, cursor)
                cursor = cursor + 1

                if eventType == 0x90 or eventType == 0x80 then
                    local velocity = byte(data, cursor)
                    cursor = cursor + 1
                    
                    seqId = seqId + 1
                    if eventType == 0x90 and velocity > 0 then
                        insert(allEvents, { tick = tick, kind = "noteOn", note = data1, velocity = velocity, channel = channel, id = seqId })
                    else
                        insert(allEvents, { tick = tick, kind = "noteOff", note = data1, channel = channel, id = seqId })
                    end
                elseif eventType == 0xA0 or eventType == 0xB0 or eventType == 0xE0 then
                    cursor = cursor + 1 
                elseif eventType == 0xC0 or eventType == 0xD0 then
                end
            end
        end

        pos = trackEnd
    end

    sort(allEvents, function(a, b)
        if a.tick ~= b.tick then
            return a.tick < b.tick
        end
        if a.kind == "tempo" and b.kind ~= "tempo" then
            return true
        elseif b.kind == "tempo" and a.kind ~= "tempo" then
            return false
        end
        return a.id < b.id
    end)

    return { division = division, events = allEvents }
end

local function buildNoteTimeline(midiData)
    local secPerTick = (500000 / 1000000) / midiData.division 
    local currentTick = 0
    local currentTime = 0

    local openNotes = {} 
    local noteEvents = {}

    for _, ev in ipairs(midiData.events) do
        local deltaTicks = ev.tick - currentTick
        currentTime = currentTime + deltaTicks * secPerTick
        currentTick = ev.tick

        if ev.kind == "tempo" then
            secPerTick = (ev.usPerQuarter / 1000000) / midiData.division
        elseif ev.kind == "noteOn" then
            local key = ev.channel .. ":" .. ev.note
            openNotes[key] = openNotes[key] or {}
            insert(openNotes[key], { startTime = currentTime, velocity = ev.velocity })
        elseif ev.kind == "noteOff" then
            local key = ev.channel .. ":" .. ev.note
            local stack = openNotes[key]
            if stack and #stack > 0 then
                local noteInfo = table.remove(stack, 1)
                insert(noteEvents, {
                    startTime = noteInfo.startTime,
                    duration = math.max(currentTime - noteInfo.startTime, 0.03),
                    note = ev.note,
                    velocity = noteInfo.velocity or 127,
                    channel = ev.channel
                })
            end
        end
    end
    
    for key, stack in pairs(openNotes) do
        local noteNum = tonumber(key:match(":(%d+)$"))
        local channelNum = tonumber(key:match("^(%d+):"))
        for _, noteInfo in ipairs(stack) do
            insert(noteEvents, {
                startTime = noteInfo.startTime,
                duration = 0.5, 
                note = noteNum,
                velocity = noteInfo.velocity or 127,
                channel = channelNum or 0
            })
        end
    end

    sort(noteEvents, function(a, b) return a.startTime < b.startTime end)
    return noteEvents
end

local midiFiles = {}

local function getDirListing(path)
    if listfiles then
        local ok, result = pcall(listfiles, path)
        if ok then return result end
    end
    if listfile then
        local ok, result = pcall(listfile, path)
        if ok then return result end
    end
    return nil
end

local function copyRtxToMid(filePath)
    local lowerPath = lower(filePath)
    local newPath = filePath
    
    if sub(lowerPath, -8) == ".mid.rtx" then
        newPath = sub(filePath, 1, -9) .. ".mid"
    elseif sub(lowerPath, -4) == ".rtx" then
        newPath = sub(filePath, 1, -5) .. ".mid"
    else
        return nil 
    end
    
    if isfile and isfile(newPath) then
        return newPath 
    end
    
    if readfile and writefile then
        local ok, data = pcall(readfile, filePath)
        if ok and data then
            pcall(writefile, newPath, data)
            return newPath
        end
    end
    
    return nil
end

local function scanDirectory(path, resultsSet, depth)
    depth = depth or 0
    if depth > 6 then return end 
    local items = getDirListing(path)
    if not items then return end
    for _, itemPath in ipairs(items) do
        local isDir = isfolder and (pcall(isfolder, itemPath) and isfolder(itemPath))
        if isDir then
            scanDirectory(itemPath, resultsSet, depth + 1)
        else
            local lowerPath = lower(itemPath)
            if sub(lowerPath, -4) == ".rtx" or sub(lowerPath, -8) == ".mid.rtx" then
                local newMid = copyRtxToMid(itemPath)
                if newMid then
                    resultsSet[newMid] = true
                end
            elseif sub(lowerPath, -4) == ".mid" or sub(lowerPath, -5) == ".midi" then
                resultsSet[itemPath] = true
            end
        end
    end
end

local selectedFilePath = nil

local function refreshFileList()
    if not (listfiles or listfile) then
        statusLabel.Text = "Executor has no listfiles()/listfile() support"
        return
    end

    statusLabel.Text = "Scanning folders..."
    local resultsSet = {}
    scanDirectory("", resultsSet)

    midiFiles = {}
    for filepath, _ in pairs(resultsSet) do
        insert(midiFiles, filepath)
    end
    sort(midiFiles)

    for _, child in pairs(rightPanel:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local yOffset = 0
    for _, filePath in ipairs(midiFiles) do
        local displayName = filePath:match("([^/\\]+)$") or filePath
        local btn = createUI("TextButton", {
            Size = uDim2(1, -8, 0, 25),
            BackgroundColor3 = rgb(25, 25, 25),
            TextColor3 = rgb(255, 255, 255),
            Text = displayName,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = rightPanel
        })
        btn.MouseButton1Click:Connect(function()
            selectedFilePath = filePath
            statusLabel.Text = "Selected: " .. displayName
        end)
        yOffset = yOffset + 30
    end
    rightPanel.CanvasSize = uDim2(0, 0, 0, yOffset)

    if #midiFiles == 0 then
        statusLabel.Text = "No .mid or .midi files found"
    else
        statusLabel.Text = "Found " .. #midiFiles .. " files"
    end
end

refreshButton.MouseButton1Click:Connect(refreshFileList)

local isPlaying = false
local isPaused = false
local currentSpeedMultiplier = 1.0

pauseButton.MouseButton1Click:Connect(function()
    if not isPlaying then return end

    if not isPaused then
        isPaused = true
        pauseButton.Text = "Resuming..."
        spawn(function()
            for speed = 10, 1, -1 do
                currentSpeedMultiplier = speed / 10
                wait(0.04)
            end
            currentSpeedMultiplier = 0
            pauseButton.Text = "Resume"
        end)
    else
        pauseButton.Text = "Starting..."
        spawn(function()
            for speed = 1, 10 do
                currentSpeedMultiplier = speed / 10
                wait(0.04)
            end
            currentSpeedMultiplier = 1.0
            isPaused = false
            pauseButton.Text = "Pause"
        end)
    end
end)

playButton.MouseButton1Click:Connect(function()
    if isPlaying then
        isPlaying = false
        isPaused = false
        currentSpeedMultiplier = 1.0
        currentPlayId = currentPlayId + 1
        releaseAllKeys()
        playButton.Text = "Play"
        playButton.BackgroundColor3 = rgb(255, 255, 255)
        playButton.TextColor3 = rgb(0, 0, 0)
        pauseButton.Text = "Pause"
        return
    end

    if not selectedFilePath then
        statusLabel.Text = "Pick a MIDI file first"
        return
    end
    if not readfile then
        statusLabel.Text = "Executor has no readfile() support"
        return
    end

    local actualFilePath = selectedFilePath

    local ok, rawData = pcall(readfile, actualFilePath)
    if not ok or not rawData then
        statusLabel.Text = "Failed to read file"
        return
    end

    local parseOk, midiData, err = pcall(parseMidiBytes, rawData)
    if not parseOk then
        statusLabel.Text = "Parse error: " .. tostring(midiData)
        return
    end
    if not midiData then
        statusLabel.Text = "Parse error: " .. tostring(err)
        return
    end

    local noteEvents = buildNoteTimeline(midiData)
    if #noteEvents == 0 then
        statusLabel.Text = "No playable notes found in file"
        return
    end

    isPlaying = true
    isPaused = false
    currentSpeedMultiplier = 1.0
    currentPlayId = currentPlayId + 1
    local thisPlayId = currentPlayId

    playButton.Text = "Stop"
    playButton.BackgroundColor3 = rgb(100, 100, 100)
    playButton.TextColor3 = rgb(255, 255, 255)
    pauseButton.Text = "Pause"

    spawn(function()
        local elapsed = 0
        for _, noteEvent in ipairs(noteEvents) do
            while isPlaying and currentPlayId == thisPlayId do
                local speedFactor = currentSpeedMultiplier > 0 and currentSpeedMultiplier or 0
                local userSpeed = tonumber(speedInput.Text) or 1.0
                if userSpeed <= 0 then userSpeed = 1.0 end

                if speedFactor == 0 then
                    wait(0.1)
                else
                    local remaining = (noteEvent.startTime - elapsed) / (speedFactor * userSpeed)
                    if remaining <= 0 then
                        elapsed = noteEvent.startTime
                        break
                    end
                    local stepWait = math.min(remaining, 0.05)
                    wait(stepWait)
                    elapsed = elapsed + stepWait * speedFactor * userSpeed
                end
            end

            if not isPlaying or currentPlayId ~= thisPlayId then break end

            local transpose = tonumber(transposeInput.Text) or 0
            local keyNote = midiNoteToKeyData(noteEvent.note, transpose)
            if keyNote then
                local userSpeed = tonumber(speedInput.Text) or 1.0
                if userSpeed <= 0 then userSpeed = 1.0 end
                local scaledDuration = noteEvent.duration / userSpeed

                local dropHeight = noteDropArea.AbsoluteSize.Y
                if dropHeight <= 0 then dropHeight = 60 end
                local leadTime = dropHeight / (100 * userSpeed)

                if keyNote.data then
                    spawnFallingNote(keyNote.data, noteEvent.duration, userSpeed)
                end

                local isDrum = (noteEvent.channel == 9)
                local isVisualNote = (noteEvent.velocity and noteEvent.velocity <= 2)
                local shouldPressKey = not isDrum and not isVisualNote

                if shouldPressKey then
                    local capturedChar = keyNote.char
                    local capturedKeyData = keyNote.data
                    local capturedPlayId = thisPlayId

                    task.delay(leadTime, function()
                        if currentPlayId == capturedPlayId and isPlaying then
                            pressKeyChar(capturedChar, capturedKeyData)
                        end
                    end)

                    task.delay(leadTime + scaledDuration, function()
                        if currentPlayId == capturedPlayId then
                            releaseKeyChar(capturedChar)
                        end
                    end)
                end
            end
        end

        if currentPlayId == thisPlayId then
            isPlaying = false
            isPaused = false
            currentSpeedMultiplier = 1.0
            playButton.Text = "Play"
            playButton.BackgroundColor3 = rgb(255, 255, 255)
            playButton.TextColor3 = rgb(0, 0, 0)
            pauseButton.Text = "Pause"
            delay(1.0, function()
                if currentPlayId == thisPlayId then
                    releaseAllKeys()
                end
            end)
        end
    end)
end)

refreshFileList()
