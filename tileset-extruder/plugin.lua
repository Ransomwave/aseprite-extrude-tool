-- Tileset Extruder Plugin v2
-- Adds File > Tileset Extruder > Configure / Toggle Auto-Export
-- On every Ctrl+S, if auto-export is enabled, exports an extruded+scaled PNG
-- alongside the source file (e.g. tileset.aseprite → tileset_extruded.png)

local function setPixel(image, x, y, color)
	if x >= 0 and x < image.width and y >= 0 and y < image.height then
		image:drawPixel(x, y, color)
	end
end

local function extrudeTileset(sprite, tileWidth, tileHeight, pixels)
	-- Compute grid from sprite dimensions and tile size
	local columns = math.floor(sprite.width / tileWidth)
	local rows = math.floor(sprite.height / tileHeight)
	local newWidth = (tileWidth + pixels * 2) * columns
	local newHeight = (tileHeight + pixels * 2) * rows

	local newSprite = Sprite(newWidth, newHeight, sprite.colorMode)
	if sprite.colorMode == ColorMode.INDEXED then
		newSprite:setPalette(sprite.palettes[1])
	end

	-- Flatten all layers/frames into a single image for robustness
	local srcImage = Image(sprite.width, sprite.height, sprite.colorMode)
	srcImage:drawSprite(sprite, 1)
	local dstImage = newSprite.cels[1].image

	for col = 0, columns - 1 do
		for row = 0, rows - 1 do
			local srcX = col * tileWidth
			local srcY = row * tileHeight
			local dstX = col * (tileWidth + pixels * 2) + pixels
			local dstY = row * (tileHeight + pixels * 2) + pixels

			for x = 0, tileWidth - 1 do
				for y = 0, tileHeight - 1 do
					setPixel(dstImage, dstX + x, dstY + y, srcImage:getPixel(srcX + x, srcY + y))
				end
			end

			for x = 0, tileWidth - 1 do
				local cTop = srcImage:getPixel(srcX + x, srcY)
				local cBot = srcImage:getPixel(srcX + x, srcY + tileHeight - 1)
				for p = 1, pixels do
					setPixel(dstImage, dstX + x, dstY - p, cTop)
					setPixel(dstImage, dstX + x, dstY + tileHeight - 1 + p, cBot)
				end
			end

			for y = 0, tileHeight - 1 do
				local cL = srcImage:getPixel(srcX, srcY + y)
				local cR = srcImage:getPixel(srcX + tileWidth - 1, srcY + y)
				for p = 1, pixels do
					setPixel(dstImage, dstX - p, dstY + y, cL)
					setPixel(dstImage, dstX + tileWidth - 1 + p, dstY + y, cR)
				end
			end

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

-- ── Derive output path ────────────────────────────────────────────────────────
-- tileset.aseprite → tileset_extruded.png (next to source file)

local function outputPath(sprite, suffix)
	local src = sprite.filename
	-- strip extension
	local base = src:match("^(.+)%.[^%.]+$") or src
	return base .. (suffix or "_extruded") .. ".png"
end

-- ── Auto-export runner ────────────────────────────────────────────────────────

local function runExport(plugin)
	local p = plugin.preferences
	local sprite = app.activeSprite
	if not sprite or not sprite.filename or sprite.filename == "" then
		return
	end

	local ok, err = pcall(function()
		local extruded = extrudeTileset(sprite, p.tileWidth, p.tileHeight, p.pixels)

		if p.dualExport then
			-- Save extruded-only PNG
			local rawPath = outputPath(sprite, p.suffixRaw)
			extruded:saveCopyAs(rawPath)

			-- Save extruded + scaled PNG (clone the already-extruded sprite)
			local scaled = Sprite(extruded)
			if p.scale ~= 1 then
				scaled:resize(scaled.width * p.scale, scaled.height * p.scale)
			end
			local scaledPath = outputPath(sprite, p.suffix)
			scaled:saveCopyAs(scaledPath)
			scaled:close()
			extruded:close()

			app.alert({
				title = "Tileset Extruder",
				text = "Exported:\n- " .. rawPath .. "\n- " .. scaledPath,
			})
		else
			-- Legacy single-file mode: extruded + scaled in one PNG
			if p.scale ~= 1 then
				extruded:resize(extruded.width * p.scale, extruded.height * p.scale)
			end
			local outPath = outputPath(sprite, p.suffix)
			extruded:saveCopyAs(outPath)
			extruded:close()
			app.alert({ title = "Tileset Extruder", text = "Exported → " .. outPath })
		end
	end)

	if not ok then
		app.alert({ title = "Tileset Extruder Error", text = tostring(err) })
	end
end

-- ── Plugin entry points ───────────────────────────────────────────────────────

function init(plugin)
	-- Default preferences (persist between sessions automatically)
	if plugin.preferences.tileWidth == nil then
		plugin.preferences.tileWidth = 20
	end
	if plugin.preferences.tileHeight == nil then
		plugin.preferences.tileHeight = 20
	end
	if plugin.preferences.pixels == nil then
		plugin.preferences.pixels = 3
	end
	if plugin.preferences.scale == nil then
		plugin.preferences.scale = 5
	end
	if plugin.preferences.suffix == nil then
		plugin.preferences.suffix = "_extruded_scaled"
	end
	if plugin.preferences.suffixRaw == nil then
		plugin.preferences.suffixRaw = "_extruded"
	end
	if plugin.preferences.dualExport == nil then
		plugin.preferences.dualExport = true
	end
	if plugin.preferences.enabled == nil then
		plugin.preferences.enabled = false
	end

	-- Menu group under File (appears as File > Tileset Extruder > ...)
	plugin:newMenuGroup({
		id = "tileset_extruder_group",
		title = "Tileset Extruder",
		group = "file_scripts", -- puts it near the bottom of File menu
	})

	-- Configure dialog
	plugin:newCommand({
		id = "TilesetExtruderConfigure",
		title = "Configure…",
		group = "tileset_extruder_group",
		onclick = function()
			local p = plugin.preferences
			local dlg = Dialog("Tileset Extruder — Configure")

			dlg:label({ text = "Grid" })
			dlg:number({ id = "tileWidth", label = "Tile width (px):", decimals = 0, text = tostring(p.tileWidth) })
			dlg:number({ id = "tileHeight", label = "Tile height (px):", decimals = 0, text = tostring(p.tileHeight) })
			dlg:separator({})
			dlg:number({ id = "pixels", label = "Extrusion pixels:", decimals = 0, text = tostring(p.pixels) })
			dlg:number({ id = "scale", label = "Scale factor:", decimals = 0, text = tostring(p.scale) })
			dlg:separator({})
			dlg:check({
				id = "dualExport",
				label = "Dual export:",
				text = "Save extruded-only AND extruded+scaled",
				selected = p.dualExport,
			})
			dlg:entry({ id = "suffixRaw", label = "  Extruded suffix:", text = p.suffixRaw })
			dlg:entry({ id = "suffix", label = "  Scaled suffix:", text = p.suffix })
			dlg:separator({})
			dlg:label({ text = "Output: <source_name><suffix>.png  (next to your .aseprite file)" })
			dlg:separator({})
			dlg:button({ id = "ok", text = "Save", focus = true })
			dlg:button({ id = "cancel", text = "Cancel" })
			dlg:show()

			if dlg.data.ok then
				p.tileWidth = math.max(1, math.floor(dlg.data.tileWidth))
				p.tileHeight = math.max(1, math.floor(dlg.data.tileHeight))
				p.pixels = math.max(1, math.floor(dlg.data.pixels))
				p.scale = math.max(1, math.floor(dlg.data.scale))
				p.dualExport = dlg.data.dualExport
				p.suffixRaw = dlg.data.suffixRaw ~= "" and dlg.data.suffixRaw or "_extruded"
				p.suffix = dlg.data.suffix ~= "" and dlg.data.suffix or "_extruded_scaled"
			end
		end,
	})

	-- Toggle auto-export on/off
	plugin:newCommand({
		id = "TilesetExtruderToggle",
		title = "Auto-Export on Save: OFF", -- label updated at runtime below
		group = "tileset_extruder_group",
		onclick = function()
			plugin.preferences.enabled = not plugin.preferences.enabled
			-- Can't rename menu items at runtime, so we show a quick alert instead
			local state = plugin.preferences.enabled and "ENABLED ✓" or "DISABLED"
			app.alert({ title = "Tileset Extruder", text = "Auto-export " .. state })
		end,
	})

	-- Run once manually (useful for testing config without saving)
	plugin:newCommand({
		id = "TilesetExtruderRunNow",
		title = "Export Now",
		group = "tileset_extruder_group",
		onclick = function()
			runExport(plugin)
		end,
	})

	-- ── The hook ───────────────────────────────────────────────────────────────
	app.events:on("aftercommand", function(ev)
		-- "SaveFile" = Ctrl+S  |  "SaveFileAs" = Save As (also fires on first save)
		if (ev.name == "SaveFile" or ev.name == "SaveFileAs") and plugin.preferences.enabled then
			runExport(plugin)
		end
	end)
end

function exit(plugin)
	-- preferences are saved automatically; nothing to clean up
end
