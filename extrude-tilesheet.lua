-- Tileset Extruder Plugin for Aseprite
-- By Ransomwave
-- Ported from https://github.com/sergiss/tileset-extruder/tree/master (original by sergiss)

-- Function to copy pixel data
local function setPixel(image, x, y, color)
  if x >= 0 and x < image.width and y >= 0 and y < image.height then
    image:drawPixel(x, y, color)
  end
end

-- Main extrusion function
local function extrudeTileset(sprite, columns, rows, pixels)
  local tileWidth = math.floor(sprite.width / columns)
  local tileHeight = math.floor(sprite.height / rows)

  -- Create a new sprite for the extruded tileset
  local newWidth = (tileWidth + pixels * 2) * columns
  local newHeight = (tileHeight + pixels * 2) * rows
  local newSprite = Sprite(newWidth, newHeight)

  -- Iterate over each tile
  for col = 0, columns - 1 do
    for row = 0, rows - 1 do
      -- Source tile bounds
      local srcX = col * tileWidth
      local srcY = row * tileHeight

      -- Destination tile bounds
      local dstX = col * (tileWidth + pixels * 2) + pixels
      local dstY = row * (tileHeight + pixels * 2) + pixels

      -- Copy the tile to the new position
      for x = 0, tileWidth - 1 do
        for y = 0, tileHeight - 1 do
          local color = sprite.cels[1].image:getPixel(srcX + x, srcY + y)
          setPixel(newSprite.cels[1].image, dstX + x, dstY + y, color)
        end
      end

      -- Perform extrusion
      for x = 0, tileWidth - 1 do
        local colorTop = sprite.cels[1].image:getPixel(srcX + x, srcY)
        local colorBottom = sprite.cels[1].image:getPixel(srcX + x, srcY + tileHeight - 1)
        for p = 1, pixels do
          setPixel(newSprite.cels[1].image, dstX + x, dstY - p, colorTop)       -- Top
          setPixel(newSprite.cels[1].image, dstX + x, dstY + tileHeight - 1 + p, colorBottom) -- Bottom
        end
      end

      for y = 0, tileHeight - 1 do
        local colorLeft = sprite.cels[1].image:getPixel(srcX, srcY + y)
        local colorRight = sprite.cels[1].image:getPixel(srcX + tileWidth - 1, srcY + y)
        for p = 1, pixels do
          setPixel(newSprite.cels[1].image, dstX - p, dstY + y, colorLeft)       -- Left
          setPixel(newSprite.cels[1].image, dstX + tileWidth - 1 + p, dstY + y, colorRight) -- Right
        end
      end

      -- Corners
      local colorTopLeft = sprite.cels[1].image:getPixel(srcX, srcY)
      local colorTopRight = sprite.cels[1].image:getPixel(srcX + tileWidth - 1, srcY)
      local colorBottomLeft = sprite.cels[1].image:getPixel(srcX, srcY + tileHeight - 1)
      local colorBottomRight = sprite.cels[1].image:getPixel(srcX + tileWidth - 1, srcY + tileHeight - 1)
      for px = 1, pixels do
        for py = 1, pixels do
          setPixel(newSprite.cels[1].image, dstX - px, dstY - py, colorTopLeft)       -- Top-left
          setPixel(newSprite.cels[1].image, dstX + tileWidth - 1 + px, dstY - py, colorTopRight) -- Top-right
          setPixel(newSprite.cels[1].image, dstX - px, dstY + tileHeight - 1 + py, colorBottomLeft) -- Bottom-left
          setPixel(newSprite.cels[1].image, dstX + tileWidth - 1 + px, dstY + tileHeight - 1 + py, colorBottomRight) -- Bottom-right
        end
      end
    end
  end

  -- Return the new sprite
  return newSprite
end

-- GUI for the plugin
local dlg = Dialog("Tileset Extruder")
dlg:label{ id="label1", text="Columns:" }
dlg:entry{ id="columns", text="4" }
dlg:label{ id="label2", text="Rows:" }
dlg:entry{ id="rows", text="4" }
dlg:label{ id="label3", text="Extrusion Pixels:" }
dlg:entry{ id="pixels", text="1" }
dlg:button{
  id="apply",
  text="Apply",
  onclick=function()
    local columns = tonumber(dlg.data.columns)
    local rows = tonumber(dlg.data.rows)
    local pixels = tonumber(dlg.data.pixels)

    if app.activeSprite then
      local newSprite = extrudeTileset(app.activeSprite, columns, rows, pixels)
      app.alert("Tileset extruded successfully!")
    else
      app.alert("No active sprite found!")
    end
  end
}
dlg:show{ wait=false }