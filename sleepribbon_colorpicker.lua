-- SleepRibbon visual color picker.
-- A compact swatch grid with #RRGGBB input, modeled on familiar KOReader plugin dialogs.

local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local InputText = require("ui/widget/inputtext")
local LineWidget = require("ui/widget/linewidget")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TitleBar = require("ui/widget/titlebar")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Font = require("ui/font")
local Screen = Device.screen
local _ = require("sleepribbon_i18n").gettext

local M = {}

local PALETTE = {
    { "#000000", "#404040", "#808080", "#BFBFBF", "#FFFFFF" },
    { "#C00000", "#FF6600", "#8B4513", "#B8860B", "#8B0000" },
    { "#FF69B4", "#FFA07A", "#DEB887", "#FFD700", "#FF8C69" },
    { "#0000CD", "#228B22", "#008B8B", "#8B008B", "#2F4F4F" },
    { "#87CEEB", "#98FB98", "#DDA0DD", "#B0E0E6", "#FFB6C1" },
}

local function normalizeHex(value)
    if type(value) ~= "string" then return nil end
    local hex = value:gsub("%s+", ""):upper()
    if hex:sub(1, 1) ~= "#" then hex = "#" .. hex end
    if hex:match("^#%x%x%x%x%x%x$") then return hex end
    return nil
end

local function rgb(hex)
    local h = normalizeHex(hex) or "#000000"
    return Blitbuffer.ColorRGB32(
        tonumber(h:sub(2, 3), 16),
        tonumber(h:sub(4, 5), 16),
        tonumber(h:sub(6, 7), 16),
        0xFF
    )
end

local Swatch = WidgetContainer:extend{
    hex = "#000000",
    side = 40,
    selected = false,
}

function Swatch:init()
    self._color = rgb(self.hex)
end

function Swatch:setHex(hex)
    local normalized = normalizeHex(hex)
    if normalized then
        self.hex = normalized
        self._color = rgb(normalized)
    end
end

function Swatch:getSize()
    return Geom:new{ w = self.side, h = self.side }
end

function Swatch:paintTo(bb, x, y)
    self.dimen = Geom:new{ x = x, y = y, w = self.side, h = self.side }
    local radius = Size.radius.default
    if bb.paintRoundedRectRGB32 then
        bb:paintRoundedRectRGB32(x, y, self.side, self.side, self._color, radius)
    else
        bb:paintRect(x, y, self.side, self.side, self._color)
    end
    local border = self.selected and Size.border.thick or Size.border.thin
    bb:paintBorder(x, y, self.side, self.side, border, Blitbuffer.COLOR_DARK_GRAY, radius)
end

local function swatchTile(hex, selected, side, callback)
    local swatch = Swatch:new{ hex = hex, selected = selected, side = side }
    local tile = InputContainer:new{
        dimen = Geom:new{ w = side, h = side },
        swatch,
    }
    tile.ges_events = {
        TapSelect = { GestureRange:new{ ges = "tap", range = tile.dimen } },
    }
    function tile:onTapSelect()
        callback(hex)
        return true
    end
    return tile
end

local function footerButton(label, width, height, callback)
    local text = TextWidget:new{
        text = label,
        face = Font:getFace("cfont", 17),
        fgcolor = Blitbuffer.COLOR_BLACK,
    }
    local button = InputContainer:new{
        dimen = Geom:new{ w = width, h = height },
        CenterContainer:new{
            dimen = Geom:new{ w = width, h = height },
            text,
        },
    }
    button.ges_events = {
        TapSelect = { GestureRange:new{ ges = "tap", range = button.dimen } },
    }
    function button:onTapSelect()
        callback()
        return true
    end
    return button
end

local ColorPicker = FocusManager:extend{
    is_always_active = true,
    title = nil,
    selected_hex = "#FFFFFF",
    default_hex = "#FFFFFF",
    apply_callback = nil,
}

function ColorPicker:init()
    self.screen_w = Screen:getWidth()
    self.screen_h = Screen:getHeight()
    self.swatch_side = Screen:scaleBySize(54)
    self.swatch_gap = Screen:scaleBySize(8)
    self.selected_hex = normalizeHex(self.selected_hex) or "#FFFFFF"
    self.default_hex = normalizeHex(self.default_hex) or "#FFFFFF"
    self:update()
end

function ColorPicker:_keyboardVisible()
    return self.hex_input
        and self.hex_input.isKeyboardVisible
        and self.hex_input:isKeyboardVisible()
end

function ColorPicker:_closeKeyboard()
    if self:_keyboardVisible() and self.hex_input.onCloseKeyboard then
        self.hex_input:onCloseKeyboard()
    end
end

function ColorPicker:onCloseWidget()
    self:_closeKeyboard()
    if FocusManager.onCloseWidget then
        return FocusManager.onCloseWidget(self)
    end
end

function ColorPicker:_select(hex)
    local normalized = normalizeHex(hex)
    if not normalized then return end
    self.selected_hex = normalized
    self:_closeKeyboard()
    self:update()
end

function ColorPicker:_syncTypedPreview()
    if not self.hex_input or not self.preview_swatch then return end
    local value = normalizeHex(self.hex_input:getText() or "")
    if not value then return end
    self.selected_hex = value
    self.preview_swatch:setHex(value)
    UIManager:setDirty(self.preview_swatch, "ui")
end

function ColorPicker:_apply()
    local input = self.hex_input and self.hex_input:getText() or self.selected_hex
    local value = normalizeHex(input)
    if not value then
        UIManager:show(InfoMessage:new{ text = _("Invalid color. Enter six hexadecimal digits (RRGGBB).") })
        return
    end
    self.selected_hex = value
    if self.apply_callback then
        self.apply_callback(value)
    end
    UIManager:close(self)
end

function ColorPicker:update()
    local side = self.swatch_side
    local gap = self.swatch_gap
    local palette_w = side * 5 + gap * 4
    local inner_w = palette_w + Size.padding.fullscreen * 2
    local dialog_w = inner_w + 2 * Size.border.window

    local palette = VerticalGroup:new{ align = "center" }
    for row_index, row in ipairs(PALETTE) do
        if row_index > 1 then
            palette[#palette + 1] = VerticalSpan:new{ width = gap }
        end
        local hgroup = HorizontalGroup:new{ align = "center" }
        for col_index, hex in ipairs(row) do
            if col_index > 1 then
                hgroup[#hgroup + 1] = HorizontalSpan:new{ width = gap }
            end
            hgroup[#hgroup + 1] = swatchTile(
                hex,
                hex == self.selected_hex,
                side,
                function(tapped) self:_select(tapped) end
            )
        end
        palette[#palette + 1] = hgroup
    end

    local hex_face = Font:getFace("cfont", 18)
    local hash = TextWidget:new{
        text = "#",
        face = hex_face,
        fgcolor = Blitbuffer.COLOR_BLACK,
    }
    local initial = self.selected_hex:sub(2)
    self.hex_input = InputText:new{
        text = initial,
        hint = "RRGGBB",
        input_type = "string",
        width = Screen:scaleBySize(150),
        face = hex_face,
        focused = false,
        parent = self,
        enter_callback = function() self:_apply() end,
        edit_callback = function(edited)
            if edited then self:_syncTypedPreview() end
        end,
    }
    self.preview_swatch = Swatch:new{
        hex = self.selected_hex,
        selected = false,
        side = Screen:scaleBySize(38),
    }

    local hex_row = HorizontalGroup:new{
        align = "center",
        hash,
        HorizontalSpan:new{ width = Size.padding.small },
        self.hex_input,
        HorizontalSpan:new{ width = Size.padding.large },
        self.preview_swatch,
    }

    local footer_h = Screen:scaleBySize(46)
    local btn_w = math.floor(inner_w / 3)
    local cancel = footerButton(_("Cancel"), btn_w, footer_h, function()
        UIManager:close(self)
    end)
    local default = footerButton(_("Default"), btn_w, footer_h, function()
        self:_select(self.default_hex)
    end)
    local apply = footerButton(_("Apply"), btn_w, footer_h, function()
        self:_apply()
    end)
    local divider = function()
        return CenterContainer:new{
            dimen = Geom:new{ w = Size.line.thin, h = footer_h },
            LineWidget:new{
                background = Blitbuffer.COLOR_DARK_GRAY,
                dimen = Geom:new{ w = Size.line.thin, h = footer_h - Screen:scaleBySize(16) },
            },
        }
    end
    local footer = HorizontalGroup:new{
        cancel, divider(), default, divider(), apply,
    }

    local title_bar = TitleBar:new{
        width = dialog_w,
        title = self.title or _("Pick a color"),
        with_bottom_line = true,
        show_parent = self,
    }

    local body = VerticalGroup:new{
        align = "center",
        title_bar,
        VerticalSpan:new{ width = Size.padding.large },
        hex_row,
        VerticalSpan:new{ width = Size.padding.fullscreen },
        palette,
        VerticalSpan:new{ width = Size.padding.fullscreen },
        LineWidget:new{
            background = Blitbuffer.COLOR_DARK_GRAY,
            dimen = Geom:new{ w = inner_w, h = Size.line.thin },
        },
        footer,
    }

    local frame = FrameContainer:new{
        radius = Size.radius.window,
        bordersize = Size.border.window,
        padding = 0,
        margin = 0,
        background = Blitbuffer.COLOR_WHITE,
        body,
    }

    self[1] = CenterContainer:new{
        dimen = Geom:new{ x = 0, y = 0, w = self.screen_w, h = self.screen_h },
        frame,
    }
    UIManager:setDirty(self, "ui")
end

function M.show(args)
    UIManager:show(ColorPicker:new{
        title = args.title or _("Pick a color"),
        selected_hex = args.value,
        default_hex = args.default_value,
        apply_callback = args.callback,
    })
end

M.normalizeHex = normalizeHex
return M
