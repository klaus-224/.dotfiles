-- LZString decompression for LuaJIT
-- Properly handles UTF-16 encoding used by JavaScript
local M = {}

local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local keyStrBase64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

local function charAt(str, index)
	return string.sub(str, index, index)
end

-- Convert UTF-16 codepoint to UTF-8
local function fromCharCode(code)
	if code < 128 then
		return string.char(code)
	elseif code < 2048 then
		return string.char(
			bor(192, rshift(code, 6)),
			bor(128, band(code, 63))
		)
	elseif code < 65536 then
		return string.char(
			bor(224, rshift(code, 12)),
			bor(128, band(rshift(code, 6), 63)),
			bor(128, band(code, 63))
		)
	else
		return string.char(
			bor(240, rshift(code, 18)),
			bor(128, band(rshift(code, 12), 63)),
			bor(128, band(rshift(code, 6), 63)),
			bor(128, band(code, 63))
		)
	end
end

function M.decompressFromBase64(input)
	if not input or input == "" then return "" end
	return M._decompress(#input, 32, function(index)
		local pos = string.find(keyStrBase64, charAt(input, index + 1), 1, true)
		return pos and (pos - 1) or nil
	end)
end

function M._decompress(length, resetValue, getNextValue)
	local dictionary = {}
	local enlargeIn = 4
	local dictSize = 4
	local numBits = 3
	local entry
	local result = {}
	local data_val = getNextValue(0)
	local data_position = resetValue
	local data_index = 1

	if not data_val then return "" end

	local function readBits(numBits)
		local res = 0
		local maxpower = 2 ^ numBits
		local power = 1

		while power ~= maxpower do
			local resb = band(data_val, data_position)
			data_position = rshift(data_position, 1)

			if data_position == 0 then
				data_position = resetValue
				data_val = getNextValue(data_index)
				data_index = data_index + 1
			end

			if resb > 0 then
				res = bor(res, power)
			end
			power = lshift(power, 1)
		end

		return res
	end

	-- Initialize dictionary with dummy entries
	for i = 0, 2 do
		dictionary[i] = fromCharCode(i)
	end

	local next = readBits(2)

	if next == 0 then
		entry = fromCharCode(readBits(8))
	elseif next == 1 then
		entry = fromCharCode(readBits(16))
	elseif next == 2 then
		return ""
	end

	dictionary[3] = entry
	local w = entry
	table.insert(result, entry)

	while true do
		if data_index > length then
			return table.concat(result)
		end

		local cc = readBits(numBits)

		if cc == 0 then
			if enlargeIn == 0 then
				enlargeIn = 2 ^ numBits
				numBits = numBits + 1
			end
			dictionary[dictSize] = fromCharCode(readBits(8))
			cc = dictSize
			dictSize = dictSize + 1
			enlargeIn = enlargeIn - 1
		elseif cc == 1 then
			if enlargeIn == 0 then
				enlargeIn = 2 ^ numBits
				numBits = numBits + 1
			end
			dictionary[dictSize] = fromCharCode(readBits(16))
			cc = dictSize
			dictSize = dictSize + 1
			enlargeIn = enlargeIn - 1
		elseif cc == 2 then
			return table.concat(result)
		else
			if enlargeIn == 0 then
				enlargeIn = 2 ^ numBits
				numBits = numBits + 1
			end
		end

		if dictionary[cc] then
			entry = dictionary[cc]
		else
			if cc == dictSize then
				entry = w .. charAt(w, 1)
			else
				return table.concat(result)
			end
		end

		table.insert(result, entry)
		dictionary[dictSize] = w .. charAt(entry, 1)
		dictSize = dictSize + 1
		enlargeIn = enlargeIn - 1
		w = entry

		if enlargeIn == 0 then
			enlargeIn = 2 ^ numBits
			numBits = numBits + 1
		end
	end
end

return M
