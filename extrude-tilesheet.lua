-- Tileset Extruder — CLI + GUI hybrid
-- Usage (CLI):
--   aseprite -b --script extrude.lua \
--     --script-param input=tileset.png \
--     --script-param output=out.png \
--     --script-param columns=4 \
--     --script-param rows=4 \
--     --script-param pixels=1 \
--     --script-param scale=2   (optional, default 1)

local function setPixel(image, x, y, color)
	if x >= 0 and x < image.width and y >= 0 and y < image.height then
		image:drawPixel(x, y, color)
	end
end

local function extrudeTileset(sprite, columns, rows, pixels)
	local tileWidth = math.floor(sprite.width / columns)
	local tileHeight = math.floor(sprite.height / rows)

	local newWidth = (tileWidth + pixels * 2) * columns
	local newHeight = (tileHeight + pixels * 2) * rows
	local newSprite = Sprite(newWidth, newHeight, sprite.colorMode)

	-- Match palette for indexed-color sprites
	if sprite.colorMode == ColorMode.INDEXED then
		newSprite:setPalette(sprite.palettes[1])
	end

	local srcImage = sprite.cels[1].image
	local dstImage = newSprite.cels[1].image

	for col = 0, columns - 1 do
		for row = 0, rows - 1 do
			local srcX = col * tileWidth
			local srcY = row * tileHeight
			local dstX = col * (tileWidth + pixels * 2) + pixels
			local dstY = row * (tileHeight + pixels * 2) + pixels

			-- Copy tile body
			for x = 0, tileWidth - 1 do
				for y = 0, tileHeight - 1 do
					setPixel(dstImage, dstX + x, dstY + y, srcImage:getPixel(srcX + x, srcY + y))
				end
			end

			-- Extrude top/bottom edges
			for x = 0, tileWidth - 1 do
				local colorTop = srcImage:getPixel(srcX + x, srcY)
				local colorBottom = srcImage:getPixel(srcX + x, srcY + tileHeight - 1)
				for p = 1, pixels do
					setPixel(dstImage, dstX + x, dstY - p, colorTop)
					setPixel(dstImage, dstX + x, dstY + tileHeight - 1 + p, colorBottom)
				end
			end

			-- Extrude left/right edges
			for y = 0, tileHeight - 1 do
				local colorLeft = srcImage:getPixel(srcX, srcY + y)
				local colorRight = srcImage:getPixel(srcX + tileWidth - 1, srcY + y)
				for p = 1, pixels do
					setPixel(dstImage, dstX - p, dstY + y, colorLeft)
					setPixel(dstImage, dstX + tileWidth - 1 + p, dstY + y, colorRight)
				end
			end

			-- Extrude corners
			local cTL = srcImage:getPixel(srcX, srcY)
			local cTR = srcImage:getPixel(srcX + tileWidth - 1, srcY)
			local cBL = srcImage:getPixel(srcX, srcY + tileHeight - 1)
			local cBR = srcImage:getPixel(srcX + tileWidth - 1, srcY + tileHeight - 1)
			for px = 1, pixels do
				for py = 1, pixels do
					setPixel(dstImage, dstX - px, dstY - py, cTL)
					setPixel(dstImage, dstX + tileWidth - 1 + px, dstY - py, cTR)
					setPixel(dstImage, dstX - px, dstY + tileHeight - 1 + py, cBL)
					setPixel(dstImage, dstX + tileWidth - 1 + px, dstY + tileHeight - 1 + py, cBR)
				end
			end
		end
	end

	return newSprite
end

-- ── Mode detection ────────────────────────────────────────────────────────────

local isCLI = (app.params["input"] ~= nil)

if isCLI then
	-- ── CLI mode ──────────────────────────────────────────────────────────────
	local inputFile = app.params["input"]
	local outputFile = app.params["output"]
	local columns = tonumber(app.params["columns"]) or 4
	local rows = tonumber(app.params["rows"]) or 4
	local pixels = tonumber(app.params["pixels"]) or 1
	local scale = tonumber(app.params["scale"]) or 1

	if not inputFile or not outputFile then
		print("ERROR: --script-param input=... and output=... are required")
		app.exit(1)
		return
	end

	local sprite = app.open(inputFile)
	if not sprite then
		print("ERROR: could not open " .. inputFile)
		app.exit(1)
		return
	end

	local result = extrudeTileset(sprite, columns, rows, pixels)

	if scale ~= 1 then
		-- nearest-neighbor resize — correct for pixel art
		result:resize(result.width * scale, result.height * scale)
	end

	result:saveAs(outputFile)
	print(
		"Saved → "
			.. outputFile
			.. "  ("
			.. result.width
			.. "×"
			.. result.height
			.. ")"
			.. (scale ~= 1 and ("  [" .. scale .. "x scale]") or "")
	)

	-- Close both sprites so Aseprite exits cleanly in -b mode
	sprite:close()
	result:close()
else
	-- ── GUI mode (opened from Aseprite's Script menu) ─────────────────────────
	local dlg = Dialog("Tileset Extruder")
	dlg:label({ id = "l1", text = "Columns:" })
	dlg:entry({ id = "columns", text = "4" })
	dlg:label({ id = "l2", text = "Rows:" })
	dlg:entry({ id = "rows", text = "4" })
	dlg:label({ id = "l3", text = "Extrusion Pixels:" })
	dlg:entry({ id = "pixels", text = "1" })
	dlg:label({ id = "l4", text = "Scale (1 = no scale):" })
	dlg:entry({ id = "scale", text = "1" })
	dlg:button({
		id = "apply",
		text = "Apply",
		onclick = function()
			local columns = tonumber(dlg.data.columns)
			local rows = tonumber(dlg.data.rows)
			local pixels = tonumber(dlg.data.pixels)
			local scale = tonumber(dlg.data.scale) or 1
			if app.activeSprite then
				local result = extrudeTileset(app.activeSprite, columns, rows, pixels)
				if scale ~= 1 then
					result:resize(result.width * scale, result.height * scale)
				end
				app.alert("Done! Output: " .. result.width .. "×" .. result.height)
			else
				app.alert("No active sprite!")
			end
		end,
	})
	dlg:show({ wait = false })
end
