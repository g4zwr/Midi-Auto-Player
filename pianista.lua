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

local wait = task.wait
local delay = task.delay
local spawn = task.spawn
local Vec2 = Vector2.new
local UDim2 = UDim2.new
local UDim = UDim.new
local RGB = Color3.fromRGB
local Inst = Instance.new

local TOGGLE_KEY = Enum.KeyCode.RightControl
local SELECTION_DEBOUNCE = 0.5-- seconds to wait after last click

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local targetParent = CoreGui:FindFirstChild("RobloxGui") or localPlayer:WaitForChild("PlayerGui")

local createUI = function(className, props, parent)
    local inst = Inst(className)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local addCorner = function(parent, radius)
    return createUI("UICorner", { CornerRadius = UDim(0, radius or 8) }, parent)
end

local addStroke = function(parent, color, thickness, transparency)
    return createUI("UIStroke", {
        Color = color or RGB(255, 255, 255),
        Thickness = thickness or 1,
        Transparency = transparency or 0.85,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local addPadding = function(parent, top, bottom, left, right)
    return createUI("UIPadding", {
        PaddingTop = UDim(0, top or 6),
        PaddingBottom = UDim(0, bottom or 6),
        PaddingLeft = UDim(0, left or 8),
        PaddingRight = UDim(0, right or 8)
    }, parent)
end

local function makeDraggable(guiObj, dragHandle)
    dragHandle = dragHandle or guiObj
    local dragging, dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObj.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObj.Position = UDim2(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local screenGui = createUI("ScreenGui", {
    Name = "VirtualPianoPlayer",
    ResetOnSpawn = false,
    Parent = targetParent
})

local uiScale = createUI("UIScale", { Scale = 1 }, screenGui)

local function updateScale()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    if viewportSize.X < 640 or viewportSize.Y < 360 then
        uiScale.Scale = math.min(viewportSize.X / 640, viewportSize.Y / 360) * 0.92
    else
        uiScale.Scale = 1
    end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
updateScale()

-- Main Master Toggle Button
local toggleButton = createUI("TextButton", {
    Size = UDim2(0, 44, 0, 44),
    Position = UDim2(0, 15, 0, 15),
    BackgroundColor3 = RGB(22, 22, 26),
    TextColor3 = RGB(255, 255, 255),
    Text = "VP",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    Active = true,
    Parent = screenGui
})
addCorner(toggleButton, 10)
addStroke(toggleButton, RGB(255, 255, 255), 1, 0.8)
makeDraggable(toggleButton)

---------------------------------------------------------
-- WINDOW 1: MIDI LIST WINDOW (1:1 Ratio: 300x300)
---------------------------------------------------------
local midiFrame = createUI("Frame", {
    Size = UDim2(0, 300, 0, 300),
    Position = UDim2(0.5, 10, 0.5, -150),
    BackgroundColor3 = RGB(15, 15, 18),
    Visible = true,
    Active = true,
    ClipsDescendants = true,
    Parent = screenGui
})
addCorner(midiFrame, 12)
addStroke(midiFrame, RGB(255, 255, 255), 1, 0.85)

local midiTopBar = createUI("Frame", {
    Size = UDim2(1, 0, 0, 32),
    BackgroundTransparency = 1,
    Parent = midiFrame
})
addPadding(midiTopBar, 0, 0, 10, 10)
makeDraggable(midiFrame, midiTopBar)

createUI("TextLabel", {
    Size = UDim2(0.7, 0, 1, 0),
    BackgroundTransparency = 1,
    TextColor3 = RGB(255, 255, 255),
    Text = "MIDI List",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = midiTopBar
})

local midiMinBtn = createUI("TextButton", {
    Size = UDim2(0, 22, 0, 22),
    Position = UDim2(1, -22, 0.5, -11),
    BackgroundColor3 = RGB(30, 30, 35),
    TextColor3 = RGB(200, 200, 200),
    Text = "−",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = midiTopBar
})
addCorner(midiMinBtn, 5)

local midiContent = createUI("Frame", {
    Size = UDim2(1, -20, 1, -40),
    Position = UDim2(0, 10, 0, 34),
    BackgroundTransparency = 1,
    Parent = midiFrame
})

local searchBox = createUI("TextBox", {
    Size = UDim2(1, 0, 0, 26),
    Position = UDim2(0, 0, 0, 0),
    BackgroundColor3 = RGB(22, 22, 26),
    TextColor3 = RGB(255, 255, 255),
    PlaceholderText = "Search MIDI...",
    Text = "",
    PlaceholderColor3 = RGB(120, 120, 130),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
    Parent = midiContent
})
addCorner(searchBox, 6)
addStroke(searchBox, RGB(255, 255, 255), 1, 0.9)
addPadding(searchBox, 0, 0, 8, 8)

local refreshButton = createUI("TextButton", {
    Size = UDim2(1, 0, 0, 26),
    Position = UDim2(0, 0, 0, 32),
    BackgroundColor3 = RGB(28, 28, 34),
    TextColor3 = RGB(220, 220, 220),
    Text = "Rescan Files",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = midiContent
})
addCorner(refreshButton, 6)

local rightPanel = createUI("ScrollingFrame", {
    Size = UDim2(1, 0, 1, -64),
    Position = UDim2(0, 0, 0, 64),
    BackgroundColor3 = RGB(10, 10, 12),
    CanvasSize = UDim2(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = RGB(80, 80, 90),
    Parent = midiContent
})
addCorner(rightPanel, 8)
addStroke(rightPanel, RGB(255, 255, 255), 1, 0.9)
createUI("UIListLayout", {
    Padding = UDim(0, 4),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = rightPanel
})
addPadding(rightPanel, 4, 4, 4, 4)


---------------------------------------------------------
-- WINDOW 2: PIANO PLAYER WINDOW (1:1 Ratio: 300x300)
---------------------------------------------------------
local pianoFrame = createUI("Frame", {
    Size = UDim2(0, 300, 0, 300),
    Position = UDim2(0.5, -310, 0.5, -150),
    BackgroundColor3 = RGB(15, 15, 18),
    Visible = true,
    Active = true,
    ClipsDescendants = true,
    Parent = screenGui
})
addCorner(pianoFrame, 12)
addStroke(pianoFrame, RGB(255, 255, 255), 1, 0.85)

local pianoTopBar = createUI("Frame", {
    Size = UDim2(1, 0, 0, 32),
    BackgroundTransparency = 1,
    Parent = pianoFrame
})
addPadding(pianoTopBar, 0, 0, 10, 10)
makeDraggable(pianoFrame, pianoTopBar)

createUI("TextLabel", {
    Size = UDim2(0.7, 0, 1, 0),
    BackgroundTransparency = 1,
    TextColor3 = RGB(255, 255, 255),
    Text = "Piano Player",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = pianoTopBar
})

local pianoMinBtn = createUI("TextButton", {
    Size = UDim2(0, 22, 0, 22),
    Position = UDim2(1, -22, 0.5, -11),
    BackgroundColor3 = RGB(30, 30, 35),
    TextColor3 = RGB(200, 200, 200),
    Text = "−",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = pianoTopBar
})
addCorner(pianoMinBtn, 5)

local pianoContent = createUI("Frame", {
    Size = UDim2(1, -20, 1, -40),
    Position = UDim2(0, 10, 0, 34),
    BackgroundTransparency = 1,
    Parent = pianoFrame
})

local statusLabel = createUI("TextLabel", {
    Size = UDim2(1, 0, 0, 16),
    Position = UDim2(0, 0, 0, 0),
    BackgroundTransparency = 1,
    TextColor3 = RGB(180, 180, 190),
    Text = "No file selected",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = pianoContent
})

local visualizerContainer = createUI("Frame", {
    Size = UDim2(1, 0, 0, 110),
    Position = UDim2(0, 0, 0, 20),
    BackgroundColor3 = RGB(8, 8, 10),
    ClipsDescendants = true,
    Parent = pianoContent
})
addCorner(visualizerContainer, 8)
addStroke(visualizerContainer, RGB(255, 255, 255), 1, 0.9)

local noteDropArea = createUI("Frame", {
    Size = UDim2(1, 0, 1, -26),
    Position = UDim2(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = visualizerContainer
})

local pianoKeysFrame = createUI("Frame", {
    Size = UDim2(1, 0, 0, 26),
    Position = UDim2(0, 0, 1, -26),
    BackgroundColor3 = RGB(18, 18, 20),
    Parent = visualizerContainer
})

local sliderContainer = createUI("Frame", {
    Size = UDim2(1, 0, 0, 22),
    Position = UDim2(0, 0, 0, 136),
    BackgroundTransparency = 1,
    Parent = pianoContent
})

local sliderTrack = createUI("TextButton", {
    Size = UDim2(1, 0, 0, 5),
    Position = UDim2(0, 0, 0, 2),
    BackgroundColor3 = RGB(35, 35, 42),
    Text = "",
    AutoButtonColor = false,
    Parent = sliderContainer
})
addCorner(sliderTrack, 3)

local sliderFill = createUI("Frame", {
    Size = UDim2(0, 0, 1, 0),
    BackgroundColor3 = RGB(255, 255, 255),
    Parent = sliderTrack
})
addCorner(sliderFill, 3)

local sliderKnob = createUI("Frame", {
    Size = UDim2(0, 12, 0, 12),
    AnchorPoint = Vec2(0.5, 0.5),
    Position = UDim2(0, 0, 0.5, 0),
    BackgroundColor3 = RGB(255, 255, 255),
    Parent = sliderTrack
})
addCorner(sliderKnob, 6)

local timeLabel = createUI("TextLabel", {
    Size = UDim2(1, 0, 0, 12),
    Position = UDim2(0, 0, 1, -10),
    BackgroundTransparency = 1,
    TextColor3 = RGB(150, 150, 160),
    Text = "00:00 / 00:00",
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = sliderContainer
})

local controlsContainer = createUI("Frame", {
    Size = UDim2(1, 0, 0, 90),
    Position = UDim2(0, 0, 0, 164),
    BackgroundTransparency = 1,
    Parent = pianoContent
})

createUI("TextLabel", {
    Size = UDim2(0.48, 0, 0, 12),
    Position = UDim2(0, 0, 0, 0),
    BackgroundTransparency = 1,
    TextColor3 = RGB(180, 180, 190),
    Text = "Transpose:",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = controlsContainer
})

createUI("TextLabel", {
    Size = UDim2(0.48, 0, 0, 12),
    Position = UDim2(0.52, 0, 0, 0),
    BackgroundTransparency = 1,
    TextColor3 = RGB(180, 180, 190),
    Text = "Speed:",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = controlsContainer
})

local transposeInput = createUI("TextBox", {
    Size = UDim2(0.48, 0, 0, 24),
    Position = UDim2(0, 0, 0, 14),
    BackgroundColor3 = RGB(22, 22, 26),
    TextColor3 = RGB(255, 255, 255),
    Text = "0",
    PlaceholderText = "0",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    Parent = controlsContainer
})
addCorner(transposeInput, 6)
addStroke(transposeInput, RGB(255, 255, 255), 1, 0.9)

local speedInput = createUI("TextBox", {
    Size = UDim2(0.48, 0, 0, 24),
    Position = UDim2(0.52, 0, 0, 14),
    BackgroundColor3 = RGB(22, 22, 26),
    TextColor3 = RGB(255, 255, 255),
    Text = "1.0",
    PlaceholderText = "1.0",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    Parent = controlsContainer
})
addCorner(speedInput, 6)
addStroke(speedInput, RGB(255, 255, 255), 1, 0.9)

local playButton = createUI("TextButton", {
    Size = UDim2(0.48, 0, 0, 30),
    Position = UDim2(0, 0, 0, 48),
    BackgroundColor3 = RGB(255, 255, 255),
    TextColor3 = RGB(10, 10, 10),
    Text = "Play",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = controlsContainer
})
addCorner(playButton, 6)

local pauseButton = createUI("TextButton", {
    Size = UDim2(0.48, 0, 0, 30),
    Position = UDim2(0.52, 0, 0, 48),
    BackgroundColor3 = RGB(28, 28, 34),
    TextColor3 = RGB(220, 220, 220),
    Text = "Pause",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = controlsContainer
})
addCorner(pauseButton, 6)


---------------------------------------------------------
-- MINIMIZE & TOGGLE LOGIC
---------------------------------------------------------
local isMidiMinimized = false
midiMinBtn.MouseButton1Click:Connect(function()
    isMidiMinimized = not isMidiMinimized
    midiContent.Visible = not isMidiMinimized
    midiFrame.Size = isMidiMinimized and UDim2(0, 300, 0, 32) or UDim2(0, 300, 0, 300)
    midiMinBtn.Text = isMidiMinimized and "+" or "−"
end)

local isPianoMinimized = false
pianoMinBtn.MouseButton1Click:Connect(function()
    isPianoMinimized = not isPianoMinimized
    pianoContent.Visible = not isPianoMinimized
    pianoFrame.Size = isPianoMinimized and UDim2(0, 300, 0, 32) or UDim2(0, 300, 0, 300)
    pianoMinBtn.Text = isPianoMinimized and "+" or "−"
end)

toggleButton.MouseButton1Click:Connect(function()
    local nextVisible = not midiFrame.Visible
    midiFrame.Visible = nextVisible
    pianoFrame.Visible = nextVisible
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and not UserInputService:GetFocusedTextBox() then
        if input.KeyCode == TOGGLE_KEY then
            local nextVisible = not midiFrame.Visible
            midiFrame.Visible = nextVisible
            pianoFrame.Visible = nextVisible
        end
    end
end)


---------------------------------------------------------
-- KEYBOARD & PIANO VISUALIZER SETUP
---------------------------------------------------------
local keyCodeMap = {
    ["1"]="One", ["2"]="Two", ["3"]="Three", ["4"]="Four", ["5"]="Five",
    ["6"]="Six", ["7"]="Seven", ["8"]="Eight", ["9"]="Nine", ["0"]="Zero",
    ["!"]="One", ["@"]="Two", ["$"]="Four", ["%"]="Five", ["^"]="Six",
    ["*"]="Eight", ["("]="Nine"
}

local chromaticNotes = {
    { char = "1", isBlack = false }, { char = "!", isBlack = true },
    { char = "2", isBlack = false }, { char = "@", isBlack = true },
    { char = "3", isBlack = false }, { char = "4", isBlack = false },
    { char = "$", isBlack = true },  { char = "5", isBlack = false },
    { char = "%", isBlack = true },  { char = "^", isBlack = true },
    { char = "6", isBlack = false }, { char = "7", isBlack = false },

    { char = "8", isBlack = false }, { char = "*", isBlack = true },
    { char = "9", isBlack = false }, { char = "(", isBlack = true },
    { char = "0", isBlack = false }, { char = "q", isBlack = false },
    { char = "Q", isBlack = true },  { char = "w", isBlack = false },
    { char = "W", isBlack = true },  { char = "e", isBlack = false },
    { char = "E", isBlack = true },  { char = "r", isBlack = false },

    { char = "t", isBlack = false }, { char = "T", isBlack = true },
    { char = "y", isBlack = false }, { char = "Y", isBlack = true },
    { char = "u", isBlack = false }, { char = "i", isBlack = false },
    { char = "I", isBlack = true },  { char = "o", isBlack = false },
    { char = "O", isBlack = true },  { char = "p", isBlack = false },
    { char = "P", isBlack = true },  { char = "a", isBlack = false },

    { char = "s", isBlack = false }, { char = "S", isBlack = true },
    { char = "d", isBlack = false }, { char = "D", isBlack = true },
    { char = "f", isBlack = false }, { char = "g", isBlack = false },
    { char = "G", isBlack = true },  { char = "h", isBlack = false },
    { char = "H", isBlack = true },  { char = "j", isBlack = false },
    { char = "J", isBlack = true },  { char = "k", isBlack = false },

    { char = "l", isBlack = false }, { char = "L", isBlack = true },
    { char = "z", isBlack = false }, { char = "Z", isBlack = true },
    { char = "x", isBlack = false }, { char = "c", isBlack = false },
    { char = "C", isBlack = true },  { char = "v", isBlack = false },
    { char = "V", isBlack = true },  { char = "b", isBlack = false },
    { char = "B", isBlack = true },  { char = "n", isBlack = false },

    { char = "m", isBlack = false }, { char = "Y", isBlack = true },
    { char = "y", isBlack = false }, { char = "U", isBlack = true },
    { char = "u", isBlack = false }, { char = "i", isBlack = false },
    { char = "O", isBlack = true },  { char = "o", isBlack = false },
    { char = "P", isBlack = true },  { char = "p", isBlack = false },
    { char = "A", isBlack = true },  { char = "a", isBlack = false },

    { char = "s", isBlack = false }, { char = "D", isBlack = true },
    { char = "d", isBlack = false }, { char = "F", isBlack = true },
    { char = "f", isBlack = false }, { char = "g", isBlack = false },
    { char = "H", isBlack = true },  { char = "h", isBlack = false },
    { char = "J", isBlack = true },  { char = "j", isBlack = false },
    { char = "K", isBlack = true },  { char = "k", isBlack = false },

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
            Size = UDim2(whiteKeyWidth, -1, 1, 0),
            Position = UDim2(keyXPos, 0, 0, 0),
            BackgroundColor3 = RGB(240, 240, 245),
            ZIndex = 1,
            Parent = pianoKeysFrame
        })
        addCorner(wKey, 2)
        item.data = { frame = wKey, xPos = keyXPos, width = whiteKeyWidth, isBlack = false }
    else
        local keyXPos = (currentWhiteIndex - 1) * whiteKeyWidth + (whiteKeyWidth * 0.65)
        local bKey = createUI("Frame", {
            Size = UDim2(whiteKeyWidth * 0.7, 0, 0.6, 0),
            Position = UDim2(keyXPos, 0, 0, 0),
            BackgroundColor3 = RGB(15, 15, 18),
            ZIndex = 3,
            Parent = pianoKeysFrame
        })
        addCorner(bKey, 2)
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

local function clearNoteVisuals()
    for _, child in pairs(noteDropArea:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local spawnFallingNote = function(keyData, rawDuration, userSpeed)
    local baseSpeed = 140
    local effectiveSpeed = baseSpeed * userSpeed
    local dropHeight = noteDropArea.AbsoluteSize.Y
    if dropHeight <= 0 then dropHeight = 84 end

    local noteHeight = math.max(rawDuration * baseSpeed, 6)
    local totalDistance = dropHeight + noteHeight
    local fallDuration = totalDistance / effectiveSpeed

    local noteBlock = createUI("Frame", {
        Size = UDim2(keyData.width, 0, 0, noteHeight),
        Position = UDim2(keyData.xPos, 0, 0, -noteHeight),
        BackgroundColor3 = keyData.isBlack and RGB(180, 180, 250) or RGB(255, 255, 255),
        ZIndex = 2,
        Parent = noteDropArea
    })
    addCorner(noteBlock, 3)

    local tween = TweenService:Create(noteBlock, TweenInfo.new(fallDuration, Enum.EasingStyle.Linear), {
        Position = UDim2(keyData.xPos, 0, 1, 0)
    })

    tween.Completed:Connect(function()
        if noteBlock and noteBlock.Parent then noteBlock:Destroy() end
    end)

    tween:Play()
end

local currentPlayId = 0
local activeKeyStates = {}
local shiftedKeyCount = 0
local stopPlayback

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

    local mapped = keyCodeMap[char] or string.upper(char)
    local ok, keyCode = pcall(function() return Enum.KeyCode[mapped] end)
    if not ok or not keyCode then return end

    keyData.frame.BackgroundColor3 = RGB(100, 120, 255)

    local shifted = isShiftedChar(char)

    if shifted then
        if shiftedKeyCount == 0 then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        end
        shiftedKeyCount = shiftedKeyCount + 1
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    else
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
    state.data.frame.BackgroundColor3 = state.data.isBlack and RGB(15, 15, 18) or RGB(240, 240, 245)

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

---------------------------------------------------------
-- MIDI PARSING & TIMELINE BUILDER
---------------------------------------------------------
local function readUint16(data, pos)
    return string.byte(data, pos) * 256 + string.byte(data, pos + 1)
end

local function readUint32(data, pos)
    return string.byte(data, pos) * 16777216 + string.byte(data, pos + 1) * 65536 + string.byte(data, pos + 2) * 256 + string.byte(data, pos + 3)
end

local function readVarLen(data, pos)
    local value = 0
    local b
    repeat
        b = string.byte(data, pos)
        if not b then error("readVarLen: unexpected end of data at position " .. pos, 0) end
        pos = pos + 1
        value = (value * 128) + (b % 128)
    until b < 128
    return value, pos
end

local function parseMidiBytes(data)
    if string.sub(data, 1, 4) ~= "MThd" then
        return nil, "Not a valid MIDI file (missing MThd header)"
    end

    local headerLen = readUint32(data, 5)
    local ntrks = readUint16(data, 11)
    local division = readUint16(data, 13)

    if division >= 32768 then return nil, "SMPTE time division is not supported" end

    local pos = 9 + headerLen
    local allEvents = {}
    local seqId = 0

    for _ = 1, ntrks do
        if string.sub(data, pos, pos + 3) ~= "MTrk" then break end
        local trackLen = readUint32(data, pos + 4)
        local trackEnd = math.min(pos + 8 + trackLen, #data + 1)
        local cursor = pos + 8
        local tick = 0
        local runningStatus = nil

        while cursor < trackEnd do
            local delta
            delta, cursor = readVarLen(data, cursor)
            tick = tick + delta

            local statusByte = string.byte(data, cursor)

            if statusByte == 0xFF then
                cursor = cursor + 1
                local metaType = string.byte(data, cursor)
                cursor = cursor + 1
                local len
                len, cursor = readVarLen(data, cursor)
                if metaType == 0x51 and len == 3 then
                    local us = string.byte(data, cursor) * 65536 + string.byte(data, cursor + 1) * 256 + string.byte(data, cursor + 2)
                    seqId = seqId + 1
                    table.insert(allEvents, { tick = tick, kind = "tempo", usPerQuarter = us, id = seqId })
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
                local data1 = string.byte(data, cursor)
                cursor = cursor + 1

                if eventType == 0x90 or eventType == 0x80 then
                    local velocity = string.byte(data, cursor)
                    cursor = cursor + 1
                    seqId = seqId + 1
                    if eventType == 0x90 and velocity > 0 then
                        table.insert(allEvents, { tick = tick, kind = "noteOn", note = data1, velocity = velocity, channel = channel, id = seqId })
                    else
                        table.insert(allEvents, { tick = tick, kind = "noteOff", note = data1, channel = channel, id = seqId })
                    end
                elseif eventType == 0xA0 or eventType == 0xB0 or eventType == 0xE0 then
                    cursor = cursor + 1
                end
            end
        end
        pos = trackEnd
    end

    table.sort(allEvents, function(a, b)
        if a.tick ~= b.tick then return a.tick < b.tick end
        if a.kind == "tempo" and b.kind ~= "tempo" then return true end
        if b.kind == "tempo" and a.kind ~= "tempo" then return false end
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
            table.insert(openNotes[key], { startTime = currentTime, velocity = ev.velocity })
        elseif ev.kind == "noteOff" then
            local key = ev.channel .. ":" .. ev.note
            local stack = openNotes[key]
            if stack and #stack > 0 then
                local noteInfo = table.remove(stack, 1)
                table.insert(noteEvents, {
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
            table.insert(noteEvents, {
                startTime = noteInfo.startTime,
                duration = 0.5,
                note = noteNum,
                velocity = noteInfo.velocity or 127,
                channel = channelNum or 0
            })
        end
    end

    table.sort(noteEvents, function(a, b) return a.startTime < b.startTime end)

    if #noteEvents > 0 and noteEvents[1].startTime > 0 then
        local leadingOffset = noteEvents[1].startTime
        for _, ev in ipairs(noteEvents) do
            ev.startTime = ev.startTime - leadingOffset
        end
    end

    return noteEvents
end

local previewPlayId = 0

local function showPreviewFreezeFrame(noteEvents)
    previewPlayId = previewPlayId + 1
    clearNoteVisuals()

    if #noteEvents == 0 then return end

    local previewWindowSeconds = 2
    local baseSpeed = 140
    local dropHeight = noteDropArea.AbsoluteSize.Y
    if dropHeight <= 0 then dropHeight = 84 end

    for _, note in ipairs(noteEvents) do
        if note.startTime > previewWindowSeconds then break end
        if note.channel ~= 9 then
            local keyData = midiNoteToKeyData(note.note, tonumber(transposeInput.Text) or 0)
            if keyData and keyData.data then
                local noteHeight = math.max(note.duration * baseSpeed, 6)
                local yOffset = dropHeight - (note.startTime * baseSpeed) - noteHeight

                local noteBlock = createUI("Frame", {
                    Size = UDim2(keyData.data.width, 0, 0, noteHeight),
                    Position = UDim2(keyData.data.xPos, 0, 0, yOffset),
                    BackgroundColor3 = keyData.data.isBlack and RGB(180, 180, 250) or RGB(255, 255, 255),
                    ZIndex = 2,
                    Parent = noteDropArea
                })
                addCorner(noteBlock, 3)
            end
        end
    end
end

---------------------------------------------------------
-- FILE SYSTEM & SEARCH LOGIC
---------------------------------------------------------
local midiFiles = {}
local selectedFilePath = nil
local cachedFilePath = nil
local cachedNoteEvents = nil
local pendingSelectionToken = 0

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
    local lowerPath = string.lower(filePath)
    local newPath = filePath

    if string.sub(lowerPath, -8) == ".mid.rtx" then
        newPath = string.sub(filePath, 1, -9) .. ".mid"
    elseif string.sub(lowerPath, -4) == ".rtx" then
        newPath = string.sub(filePath, 1, -5) .. ".mid"
    else
        return nil
    end

    if isfile and isfile(newPath) then return newPath end

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
            local lowerPath = string.lower(itemPath)
            if string.sub(lowerPath, -4) == ".rtx" or string.sub(lowerPath, -8) == ".mid.rtx" then
                local newMid = copyRtxToMid(itemPath)
                if newMid then resultsSet[newMid] = true end
            elseif string.sub(lowerPath, -4) == ".mid" or string.sub(lowerPath, -5) == ".midi" then
                resultsSet[itemPath] = true
            end
        end
    end
end

local function updateMidiListUI()
    for _, child in pairs(rightPanel:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local filter = string.lower(searchBox.Text or "")
    local yOffset = 0

    for _, filePath in ipairs(midiFiles) do
        local displayName = filePath:match("([^/\\]+)$") or filePath
        if filter == "" or string.find(string.lower(displayName), filter, 1, true) then
            local btn = createUI("TextButton", {
                Size = UDim2(1, 0, 0, 26),
                BackgroundColor3 = RGB(18, 18, 22),
                TextColor3 = RGB(220, 220, 220),
                Text = displayName,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = rightPanel
            })
            addCorner(btn, 4)

            btn.MouseButton1Click:Connect(function()
                pendingSelectionToken = pendingSelectionToken + 1
                local thisToken = pendingSelectionToken
                statusLabel.Text = "Selecting: " .. displayName .. "..."

                delay(SELECTION_DEBOUNCE, function()
                    if thisToken ~= pendingSelectionToken then return end

                    if stopPlayback then stopPlayback() end

                    selectedFilePath = filePath
                    statusLabel.Text = "Selected: " .. displayName
                    cachedFilePath = nil
                    cachedNoteEvents = nil

                    if readfile then
                        local ok, rawData = pcall(readfile, filePath)
                        if ok and rawData then
                            local parseOk, midiData = pcall(parseMidiBytes, rawData)
                            if parseOk and midiData then
                                local events = buildNoteTimeline(midiData)
                                cachedFilePath = filePath
                                cachedNoteEvents = events
                                showPreviewFreezeFrame(events)
                            else
                                statusLabel.Text = "Selected: " .. displayName .. " (preview unavailable)"
                            end
                        end
                    end
                end)
            end)
            yOffset = yOffset + 30
        end
    end
    rightPanel.CanvasSize = UDim2(0, 0, 0, yOffset)
end

local function refreshFileList()
    if not (listfiles or listfile) then
        statusLabel.Text = "No listfiles() support"
        return
    end

    statusLabel.Text = "Scanning folders..."
    local resultsSet = {}
    scanDirectory("", resultsSet)

    midiFiles = {}
    for filepath, _ in pairs(resultsSet) do table.insert(midiFiles, filepath) end
    table.sort(midiFiles)

    updateMidiListUI()

    if #midiFiles == 0 then
        statusLabel.Text = "No .mid files found"
    else
        statusLabel.Text = "Found " .. #midiFiles .. " files"
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(updateMidiListUI)
refreshButton.MouseButton1Click:Connect(refreshFileList)


---------------------------------------------------------
-- AUDIO PLAYBACK CONTROLS
---------------------------------------------------------
local isPlaying = false
local isPaused = false
local totalSongDuration = 0
local currentElapsedTime = 0
local seekTimeRequested = nil
local isScrubbing = false

local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

local function updateSliderVisual(percent)
    percent = math.clamp(percent, 0, 1)
    sliderFill.Size = UDim2(percent, 0, 1, 0)
    sliderKnob.Position = UDim2(percent, 0, 0.5, 0)
end

local function processSliderInput(input)
    local trackAbsPos = sliderTrack.AbsolutePosition.X
    local trackAbsSize = sliderTrack.AbsoluteSize.X
    if trackAbsSize <= 0 then return end
    local pct = math.clamp((input.Position.X - trackAbsPos) / trackAbsSize, 0, 1)
    updateSliderVisual(pct)
    if totalSongDuration > 0 then
        local currentSecs = pct * totalSongDuration
        timeLabel.Text = formatTime(currentSecs) .. " / " .. formatTime(totalSongDuration)
        if isScrubbing then
            seekTimeRequested = currentSecs
        end
    end
end

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isScrubbing = true
        processSliderInput(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isScrubbing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        processSliderInput(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isScrubbing = false
    end
end)

stopPlayback = function()
    if not isPlaying then return end
    isPlaying = false
    isPaused = false
    currentPlayId = currentPlayId + 1
    releaseAllKeys()
    playButton.Text = "Play"
    playButton.BackgroundColor3 = RGB(255, 255, 255)
    playButton.TextColor3 = RGB(10, 10, 10)
    pauseButton.Text = "Pause"
    updateSliderVisual(0)
    timeLabel.Text = "00:00 / 00:00"
end

pauseButton.MouseButton1Click:Connect(function()
    if not isPlaying then return end
    isPaused = not isPaused
    pauseButton.Text = isPaused and "Resume" or "Pause"
end)

playButton.MouseButton1Click:Connect(function()
    if isPlaying then
        stopPlayback()
        return
    end

    if not selectedFilePath then
        statusLabel.Text = "Pick a MIDI file first"
        return
    end

    local noteEvents

    if cachedNoteEvents and cachedFilePath == selectedFilePath then
        noteEvents = cachedNoteEvents
    else
        if not readfile then
            statusLabel.Text = "Executor has no readfile()"
            return
        end

        local ok, rawData = pcall(readfile, selectedFilePath)
        if not ok or not rawData then
            statusLabel.Text = "Failed to read file"
            return
        end

        local parseOk, midiData, err = pcall(parseMidiBytes, rawData)
        if not parseOk or not midiData then
            statusLabel.Text = "Parse error: " .. tostring(err or midiData)
            return
        end

        noteEvents = buildNoteTimeline(midiData)
    end

    if #noteEvents == 0 then
        statusLabel.Text = "No playable notes found"
        return
    end

    previewPlayId = previewPlayId + 1
    clearNoteVisuals()

    totalSongDuration = noteEvents[#noteEvents].startTime + noteEvents[#noteEvents].duration
    isPlaying = true
    isPaused = false
    currentPlayId = currentPlayId + 1
    local thisPlayId = currentPlayId

    playButton.Text = "Stop"
    playButton.BackgroundColor3 = RGB(220, 60, 60)
    playButton.TextColor3 = RGB(255, 255, 255)

    spawn(function()
        currentElapsedTime = 0
        local noteIdx = 1
        local lastClock = os.clock()

        while isPlaying and currentPlayId == thisPlayId and noteIdx <= #noteEvents do
            if seekTimeRequested then
                currentElapsedTime = seekTimeRequested
                seekTimeRequested = nil
                releaseAllKeys()
                clearNoteVisuals()
                noteIdx = 1
                while noteIdx <= #noteEvents and noteEvents[noteIdx].startTime < currentElapsedTime do
                    noteIdx = noteIdx + 1
                end
                lastClock = os.clock()
            end

            if isPaused then
                wait(0.05)
                lastClock = os.clock()
            else
                local userSpeed = tonumber(speedInput.Text) or 1.0
                if userSpeed <= 0 then userSpeed = 1.0 end

                local nextNote = noteEvents[noteIdx]
                if nextNote then
                    if currentElapsedTime >= nextNote.startTime then
                        local transpose = tonumber(transposeInput.Text) or 0
                        local keyNote = midiNoteToKeyData(nextNote.note, transpose)

                        if keyNote then
                            local scaledDuration = nextNote.duration / userSpeed
                            local dropHeight = noteDropArea.AbsoluteSize.Y
                            if dropHeight <= 0 then dropHeight = 84 end
                            local leadTime = dropHeight / (140 * userSpeed)

                            if keyNote.data then
                                spawnFallingNote(keyNote.data, nextNote.duration, userSpeed)
                            end

                            local isDrum = (nextNote.channel == 9)
                            local isVisualNote = (nextNote.velocity and nextNote.velocity <= 2)

                            if not isDrum and not isVisualNote then
                                local capturedChar = keyNote.char
                                local capturedKeyData = keyNote.data
                                local capturedPlayId = thisPlayId

                                delay(leadTime, function()
                                    if currentPlayId == capturedPlayId and isPlaying then
                                        pressKeyChar(capturedChar, capturedKeyData)
                                    end
                                end)

                                delay(leadTime + scaledDuration, function()
                                    if currentPlayId == capturedPlayId then
                                        releaseKeyChar(capturedChar)
                                    end
                                end)
                            end
                        end
                        noteIdx = noteIdx + 1
                    end
                end

                wait()

                local nowClock = os.clock()
                local realDelta = nowClock - lastClock
                lastClock = nowClock

                realDelta = math.min(realDelta, 0.25)

                currentElapsedTime = currentElapsedTime + (realDelta * userSpeed)

                if not isScrubbing and totalSongDuration > 0 then
                    local pct = currentElapsedTime / totalSongDuration
                    updateSliderVisual(pct)
                    timeLabel.Text = formatTime(currentElapsedTime) .. " / " .. formatTime(totalSongDuration)
                end
            end
        end

        if currentPlayId == thisPlayId then
            isPlaying = false
            isPaused = false
            playButton.Text = "Play"
            playButton.BackgroundColor3 = RGB(255, 255, 255)
            playButton.TextColor3 = RGB(10, 10, 10)
            pauseButton.Text = "Pause"
            updateSliderVisual(0)
            timeLabel.Text = "00:00 / 00:00"
            releaseAllKeys()
        end
    end)
end)

refreshFileList()
