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
local RepoBase = "https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/"

-- Proper percent-encoding (handles spaces, brackets, unicode, etc.)
local function UrlEncode(str)
    return (str:gsub("([^%w%-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function AddSong(f)
    if isfile(f) then return end

    local url = RepoBase .. UrlEncode(f)
    local ok, data = pcall(game.HttpGet, game, url)
    if ok then
        writefile(f, data)
    else
        warn("[MidiPlayer] Failed to fetch '" .. f .. "': " .. tostring(data))
    end
end

AddSong("Golden-Brown.mid")
AddSong("Jack - Golden hour.mid")
AddSong("rush_e_real.mid")
AddSong("DAIDAIDAIKIRAI.mid")
AddSong("(FNF)   FOR YOU SOMEDAY   [ Meiart ]   (Bikini Horrors V3) .mid.rtx")
AddSong("Coin Locker Baby (コインロッカーベイビー) - MARETU.mid.rtx")
AddSong("Looping The Rooms (FULL Piano).mid.rtx")
AddSong("Rabbit Hole - DECO_27 (feat_ Hatsune Miku [AS SAWTONE]).mid.rtx")
AddSong("The Disappearance of Hatsune Miku V2 .mid.rtx")

loadstring(game:HttpGet("https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/pianista.lua"))()
