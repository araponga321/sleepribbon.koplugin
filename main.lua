-- SleepRibbon
-- Configurable styling for KOReader's native sleep-screen "Banner" message.
--
-- Principles:
--   * KOReader remains responsible for the cover, message tokens, opacity and position.
--   * SleepRibbon only replaces the visual Banner widget.
--   * No polling, timers or background work.
--   * The progress bar is a separate strip outside the ribbon body.

local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local datetime = require("datetime")
local Device = require("device")
local Font = require("ui/font")
local FontList = require("fontlist")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local LuaSettings = require("luasettings")
local Notification = require("ui/widget/notification")
local RenderText = require("ui/rendertext")
local ReaderMenu = require("apps/reader/modules/readermenu")
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local ReaderMenuOrder = require("ui/elements/reader_menu_order")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local Screen = Device.screen
local Size = require("ui/size")
local SpinWidget = require("ui/widget/spinwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local util = require("util")
local ColorPicker = require("sleepribbon_colorpicker")
local KO_ = require("gettext")
local _ = require("sleepribbon_i18n").gettext

local SETTINGS_PATH = DataStorage:getSettingsDir() .. "/sleepribbon.lua"

local DEFAULTS = {
    enabled = true,
    use_ui_font = true,
    font_path = "NotoSans-Regular.ttf",
    font_index = 0,
    font_label = "Noto Sans Regular",
    font_family = "Noto Sans",
    font_style = "Regular",
    font_size = 17,

    text_color = "#FFFFFF",
    text_alignment = "center",
    horizontal_padding = 0,
    background_enabled = true,
    background_color = "#000000",
    vertical_padding = 0,

    progress_enabled = true,
    progress_position = "top",
    progress_show_remainder = false,
    progress_height = 3,
    progress_color = "#FFFFFF",
    remainder_color = "#404040",
}

local function normalizeHex(value)
    return ColorPicker.normalizeHex(value)
end

local function colorFromHex(value)
    local hex = normalizeHex(value) or "#000000"
    return Blitbuffer.ColorRGB32(
        tonumber(hex:sub(2, 3), 16),
        tonumber(hex:sub(4, 5), 16),
        tonumber(hex:sub(6, 7), 16),
        0xFF
    )
end

local function basename(path)
    if not path then return "" end
    local _, name = util.splitFilePathName(path)
    return name or path
end

local function stripExtension(name)
    return (name or ""):gsub("%.[^%.]+$", "")
end

-- ---------------------------------------------------------------------------
-- Progress strip
-- ---------------------------------------------------------------------------

local RibbonProgressBar = Widget:extend{
    width = 0,
    height = 0,
    progress = 0,
    fill_color = Blitbuffer.COLOR_WHITE,
    remainder_color = Blitbuffer.COLOR_DARK_GRAY,
    show_remainder = false,
}

function RibbonProgressBar:init()
    self.dimen = Geom:new{ w = self.width, h = self.height }
end

function RibbonProgressBar:getSize()
    return self.dimen
end

local function paintRGBRect(bb, x, y, w, h, color)
    if w <= 0 or h <= 0 then return end
    -- On color-capable KOReader buffers this keeps RGB values intact; on
    -- grayscale buffers KOReader performs the appropriate conversion.
    if bb.paintRoundedRectRGB32 then
        bb:paintRoundedRectRGB32(x, y, w, h, color, 0)
    else
        bb:paintRect(x, y, w, h, color)
    end
end

function RibbonProgressBar:paintTo(bb, x, y)
    local w = self.dimen.w
    local h = self.dimen.h
    if w <= 0 or h <= 0 then return end

    if self.show_remainder then
        paintRGBRect(bb, x, y, w, h, self.remainder_color)
    end

    local progress = math.max(0, math.min(1, tonumber(self.progress) or 0))
    local filled = math.floor(w * progress + 0.5)
    if filled > 0 then
        paintRGBRect(bb, x, y, filled, h, self.fill_color)
    end
end

-- ---------------------------------------------------------------------------
-- Transparent text box
-- ---------------------------------------------------------------------------
-- The transparent glyph-painting path below is adapted from KOReader's
-- frontend/ui/widget/textboxwidget.lua (TextBoxWidget rendering behavior).
-- KOReader is distributed under the GNU AGPL v3.0.

local TransparentTextBoxWidget = TextBoxWidget:extend{}

function TransparentTextBoxWidget:init()
    -- Let KOReader do its normal text layout once, then discard the opaque
    -- backing buffer. We keep the measured lines/metrics and paint only glyphs.
    TextBoxWidget.init(self)
    local size = TextBoxWidget.getSize(self)
    self._transparent_w = size.w
    self._transparent_h = size.h
    if self._bb then
        self._bb:free()
        self._bb = nil
    end
end

function TransparentTextBoxWidget:getSize()
    return Geom:new{
        x = 0,
        y = 0,
        w = self._transparent_w or self.width,
        h = self._transparent_h or self.line_height_px or 0,
    }
end

function TransparentTextBoxWidget:paintTo(bb, x, y)
    self.dimen.x, self.dimen.y = x, y

    local start_row_idx = self.virtual_line_num or 1
    local visible_rows = self.lines_per_page or #self.vertical_string_list
    local end_row_idx = math.min(#self.vertical_string_list, start_row_idx + visible_rows - 1)
    local baseline_y = y + self.line_glyph_baseline

    if self.use_xtext then
        local rgb_fg = not Blitbuffer.isColor8(self.fgcolor)
        for i = start_row_idx, end_row_idx do
            local line = self.vertical_string_list[i]
            self:_shapeLine(line)
            if line.xglyphs then
                for _, xglyph in ipairs(line.xglyphs) do
                    if not xglyph.no_drawing then
                        local face = self.face.getFallbackFont(xglyph.font_num)
                        local bolder = self._ptf_char_is_bold and self._ptf_char_is_bold[xglyph.text_index] or false
                        local glyph = RenderText:getGlyphByIndex(face, xglyph.glyph, self.bold, bolder)
                        local gx = x + xglyph.x0 + glyph.l + xglyph.x_offset
                        local gy = baseline_y - glyph.t - xglyph.y_offset
                        if rgb_fg and bb.colorblitFromRGB32 then
                            bb:colorblitFromRGB32(
                                glyph.bb, gx, gy,
                                0, 0, glyph.bb:getWidth(), glyph.bb:getHeight(),
                                self.fgcolor
                            )
                        else
                            bb:colorblitFrom(
                                glyph.bb, gx, gy,
                                0, 0, glyph.bb:getWidth(), glyph.bb:getHeight(),
                                self.fgcolor
                            )
                        end
                    end
                end
            end
            baseline_y = baseline_y + self.line_height_px
        end
        return
    end

    for i = start_row_idx, end_row_idx do
        local line = self.vertical_string_list[i]
        local pen_x = 0
        if self.alignment == "center" then
            pen_x = (self.width - line.width) / 2
        elseif self.alignment == "right" then
            pen_x = self.width - line.width
        end
        RenderText:renderUtf8Text(
            bb,
            x + pen_x,
            baseline_y,
            self.face,
            self:_getLineText(line),
            true,
            self.bold,
            self.fgcolor,
            nil,
            self:_getLinePads(line)
        )
        baseline_y = baseline_y + self.line_height_px
    end
end

-- ---------------------------------------------------------------------------
-- Preview
-- ---------------------------------------------------------------------------

local PreviewDialog = InputContainer:extend{
    modal = true,
    ribbon_widget = nil,
}

function PreviewDialog:init()
    self.ges_events = {
        TapClose = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{ x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight() },
            },
        },
    }

    local title = TextWidget:new{
        text = _("SleepRibbon preview"),
        face = Font:getFace("smalltfont"),
    }
    local hint = TextWidget:new{
        text = _("Tap anywhere to close"),
        face = Font:getFace("smallinfofont"),
        fgcolor = Blitbuffer.COLOR_DARK_GRAY,
    }

    local preview_holder = FrameContainer:new{
        background = Blitbuffer.COLOR_LIGHT_GRAY,
        bordersize = Size.border.thin,
        padding = Size.padding.large,
        self.ribbon_widget,
    }

    local panel = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        radius = Size.radius.window,
        bordersize = Size.border.window,
        padding = Size.padding.large,
        VerticalGroup:new{
            align = "center",
            title,
            VerticalSpan:new{ width = Size.padding.large },
            preview_holder,
            VerticalSpan:new{ width = Size.padding.large },
            hint,
        },
    }

    self[1] = CenterContainer:new{
        dimen = Screen:getSize(),
        panel,
    }
end

function PreviewDialog:onTapClose()
    UIManager:close(self)
    return true
end

-- ---------------------------------------------------------------------------
-- Plugin object and settings
-- ---------------------------------------------------------------------------

local SleepRibbon = WidgetContainer:extend{
    name = "sleepribbon",
    is_doc_only = false,
    settings = LuaSettings:open(SETTINGS_PATH),
}

local active_instance
local original_textbox_new
local original_expand_string
local patch_installed = false
local expand_hook_installed = false
local menu_hooks_installed = false
local menu_instances = setmetatable({}, { __mode = "k" })

function SleepRibbon:initDefaults()
    local changed = false
    for key, value in pairs(DEFAULTS) do
        if self.settings:hasNot(key) then
            self.settings:saveSetting(key, value)
            changed = true
        end
    end
    if changed then self.settings:flush() end
end

function SleepRibbon:init()
    self:initDefaults()
    active_instance = self
    self:installBannerHook()
    self:installExpandStringHook()
    self:installMenuHooks()

    if self.ui and self.ui.menu then
        menu_instances[self.ui.menu] = self
        -- Keep normal plugin registration/lifecycle, but menu placement itself
        -- happens after KOReader has built the real menu tree.
        self.ui.menu:registerToMainMenu(self)
        -- Force a rebuild on the next menu opening so the post-build hook runs.
        self.ui.menu.tab_item_table = nil
    end
end

function SleepRibbon:isEnabled()
    return self.settings:nilOrTrue("enabled")
end

function SleepRibbon:read(key)
    local value = self.settings:readSetting(key)
    if value == nil then return DEFAULTS[key] end
    return value
end

function SleepRibbon:save(key, value)
    self.settings:saveSetting(key, value):flush()
end

function SleepRibbon:resetDefaults()
    for key, value in pairs(DEFAULTS) do
        self.settings:saveSetting(key, value)
    end
    self.settings:flush()
end

function SleepRibbon:getUIFontFace(size)
    local ok, face = pcall(Font.getFace, Font, "cfont", size)
    if ok and face then return face end
    return Font:getFace("infofont", size)
end

function SleepRibbon:getConfiguredFace(size_override, path_override, index_override)
    local size = size_override or self:read("font_size")

    if path_override then
        local ok, face = pcall(Font.getFace, Font, path_override, size, index_override or 0)
        if ok and face then return face end
        return self:getUIFontFace(size)
    end

    if self:read("use_ui_font") then
        return self:getUIFontFace(size)
    end

    local path = self:read("font_path")
    local index = self:read("font_index") or 0
    local ok, face = pcall(Font.getFace, Font, path, size, index)
    if ok and face then return face end
    return self:getUIFontFace(size)
end

-- ---------------------------------------------------------------------------
-- Time-left (%H) fallback cache
-- ---------------------------------------------------------------------------

function SleepRibbon:isScreensaverBannerActive()
    return self:isEnabled()
        and Device.screen_saver_mode
        and G_reader_settings:readSetting("screensaver_message_container") == "banner"
end

function SleepRibbon:getTimeLeftCache()
    local cache = self.settings:readSetting("time_left_cache")
    return type(cache) == "table" and cache or {}
end

function SleepRibbon:getCachedTimeLeft(file)
    if not file then return nil end
    return tonumber(self:getTimeLeftCache()[file])
end

function SleepRibbon:saveCachedTimeLeft(file, seconds)
    if not file or type(seconds) ~= "number" then return end
    seconds = math.max(0, math.floor(seconds + 0.5))
    local cache = self:getTimeLeftCache()
    if tonumber(cache[file]) == seconds then return end
    cache[file] = seconds
    self.settings:saveSetting("time_left_cache", cache):flush()
end

function SleepRibbon:getCurrentTimeLeftSeconds(bookinfo, file)
    if not (bookinfo and file) then return nil end
    local ui = bookinfo.ui or self.ui
    local doc = bookinfo.document or (ui and ui.document)
    if not (ui and doc and doc.file == file and ui.statistics) then return nil end

    local stats = ui.statistics
    local avg_time = tonumber(stats.avg_time)
    if not (stats.settings and stats.settings.is_enabled and avg_time and avg_time == avg_time) then
        return nil
    end

    local pageno = ui.view and ui.view.footer and ui.view.footer.pageno
    if not pageno and ui.getCurrentPage then
        local ok, page = pcall(ui.getCurrentPage, ui)
        if ok then pageno = page end
    end
    if type(pageno) ~= "number" or not doc.getTotalPagesLeft then return nil end

    local ok, pages_left = pcall(doc.getTotalPagesLeft, doc, pageno)
    if not ok or type(pages_left) ~= "number" then return nil end
    return math.max(0, pages_left * avg_time)
end

function SleepRibbon:formatTimeLeft(seconds)
    local duration_format = G_reader_settings:readSetting("duration_format", "classic")
    return datetime.secondsToClockDuration(duration_format, seconds, true)
end

function SleepRibbon:installExpandStringHook()
    if expand_hook_installed then return end
    local BookInfo = require("apps/filemanager/filemanagerbookinfo")
    original_expand_string = BookInfo.expandString

    BookInfo.expandString = function(bookinfo, str, file, timestamp)
        local instance = active_instance
        if instance and instance:isScreensaverBannerActive()
                and type(str) == "string" and str:find("%H", 1, true) then
            local target_file = file
                or (bookinfo and bookinfo.document and bookinfo.document.file)
                or G_reader_settings:readSetting("lastfile")

            if target_file then
                local current_seconds = instance:getCurrentTimeLeftSeconds(bookinfo, target_file)
                if current_seconds then
                    -- Cache only when a valid native estimate is available. No timers,
                    -- polling or background work: this runs only while the sleep-screen
                    -- message is being expanded.
                    instance:saveCachedTimeLeft(target_file, current_seconds)
                else
                    local cached_seconds = instance:getCachedTimeLeft(target_file)
                    if cached_seconds then
                        local replacement = instance:formatTimeLeft(cached_seconds)
                        local patched = str:gsub("%%H", function() return replacement end)
                        return original_expand_string(bookinfo, patched, file, timestamp)
                    end
                end
            end
        end
        return original_expand_string(bookinfo, str, file, timestamp)
    end

    expand_hook_installed = true
end

function SleepRibbon:getProgress(expanded_text)
    local ui = self.ui
    if ui and ui.document and ui.getCurrentPage and ui.document.getPageCount then
        local ok_page, page = pcall(ui.getCurrentPage, ui)
        local ok_total, total = pcall(ui.document.getPageCount, ui.document)
        if ok_page and ok_total and type(page) == "number" and type(total) == "number" and total > 0 then
            return math.max(0, math.min(1, page / total))
        end
    end

    if type(expanded_text) == "string" then
        local value = expanded_text:match("(%d+[.,]?%d*)%%")
        if value then
            value = tonumber((value:gsub(",", ".")))
            if value then return math.max(0, math.min(1, value / 100)) end
        end
    end
    return 0
end

function SleepRibbon:buildRibbonWidget(text, width, progress, face_override)
    local background_enabled = self:read("background_enabled") and true or false
    local background = colorFromHex(self:read("background_color"))
    local foreground = colorFromHex(self:read("text_color"))
    local vertical_padding = math.max(0, tonumber(self:read("vertical_padding")) or 0)
    local horizontal_padding = math.max(0, tonumber(self:read("horizontal_padding")) or 0)

    local alignment = tostring(self:read("text_alignment") or "center")
    if alignment ~= "left" and alignment ~= "center" and alignment ~= "right" then
        alignment = "center"
    end

    -- Horizontal padding belongs only to the text. The ribbon background and
    -- progress bar keep the full supplied width.
    local max_hpad = math.max(0, math.floor((width - 1) / 2))
    horizontal_padding = math.min(horizontal_padding, max_hpad)
    local text_width = math.max(1, width - 2 * horizontal_padding)

    local bar_enabled = self:read("progress_enabled") and true or false
    local bar_height = bar_enabled and math.max(0, tonumber(self:read("progress_height")) or 0) or 0
    local bar_position = self:read("progress_position") == "bottom" and "bottom" or "top"

    local text_widget
    if background_enabled then
        text_widget = original_textbox_new(TextBoxWidget, {
            text = text,
            face = face_override or self:getConfiguredFace(),
            width = text_width,
            alignment = alignment,
            fgcolor = foreground,
            bgcolor = background,
            line_height = 0.15,
        })
    else
        text_widget = original_textbox_new(TransparentTextBoxWidget, {
            text = text,
            face = face_override or self:getConfiguredFace(),
            width = text_width,
            alignment = alignment,
            fgcolor = foreground,
            line_height = 0.15,
        })
    end

    local text_row = HorizontalGroup:new{
        HorizontalSpan:new{ width = horizontal_padding },
        text_widget,
        HorizontalSpan:new{ width = horizontal_padding },
    }

    local text_body
    if background_enabled then
        text_body = FrameContainer:new{
            background = background,
            bordersize = 0,
            padding = 0,
            padding_top = vertical_padding,
            padding_bottom = vertical_padding,
            text_row,
        }
    else
        local floating_children = { align = "center" }
        if vertical_padding > 0 then
            table.insert(floating_children, VerticalSpan:new{ width = vertical_padding })
        end
        table.insert(floating_children, text_row)
        if vertical_padding > 0 then
            table.insert(floating_children, VerticalSpan:new{ width = vertical_padding })
        end
        text_body = VerticalGroup:new(floating_children)
    end

    local bar
    if bar_height > 0 then
        bar = RibbonProgressBar:new{
            width = width,
            height = bar_height,
            progress = progress or 0,
            fill_color = colorFromHex(self:read("progress_color")),
            remainder_color = colorFromHex(self:read("remainder_color")),
            show_remainder = self:read("progress_show_remainder") and true or false,
        }
    end

    local children = { align = "center" }
    if bar and bar_position == "top" then table.insert(children, bar) end
    table.insert(children, text_body)
    if bar and bar_position == "bottom" then table.insert(children, bar) end
    return VerticalGroup:new(children)
end

function SleepRibbon:isNativeBannerCandidate(settings)
    if not self:isEnabled() or not Device.screen_saver_mode then return false end
    if type(settings) ~= "table" then return false end
    if settings.alignment ~= "center" or settings.width ~= Screen:getWidth() then return false end
    local container = G_reader_settings:readSetting("screensaver_message_container")
    return container == "banner"
end

function SleepRibbon:installBannerHook()
    if patch_installed then return end
    original_textbox_new = TextBoxWidget.new

    TextBoxWidget.new = function(class, settings, ...)
        local instance = active_instance
        if instance and instance:isNativeBannerCandidate(settings) then
            local text = settings.text or ""
            return instance:buildRibbonWidget(text, settings.width, instance:getProgress(text))
        end
        return original_textbox_new(class, settings, ...)
    end
    patch_installed = true
end

-- ---------------------------------------------------------------------------
-- Fonts
-- ---------------------------------------------------------------------------

local STYLE_SUFFIXES = {
    "Bold Italic", "Bold Oblique", "SemiBold Italic", "Semibold Italic",
    "SemiBold", "Semibold", "ExtraBold", "Extra Bold", "Black Italic",
    "Black", "Medium Italic", "Medium", "Light Italic", "Light",
    "Italic", "Oblique", "Bold", "Regular",
}

-- Prefer typographic family/subfamily metadata when available, then fall
-- back to the legacy family/subfamily and full-name records.
-- Numeric OpenType name-table IDs are used deliberately: KOReader's HarfBuzz
-- FFI binding does not expose every hb_ot_name_id_t enum symbol.
local NAME_ID_FAMILY = 1
local NAME_ID_SUBFAMILY = 2
local NAME_ID_FULL_NAME = 4
local NAME_ID_TYPO_FAMILY = 16
local NAME_ID_TYPO_SUBFAMILY = 17

local function cleanFontName(value)
    if type(value) ~= "string" then return nil end
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return nil end
    return value
end

local STYLE_ALIASES = {
    ["reg"] = "Regular",
    ["rg"] = "Regular",
    ["regita"] = "Regular Italic",
    ["regitalic"] = "Regular Italic",
    ["regobl"] = "Regular Oblique",
    ["regularobl"] = "Regular Oblique",
    ["ita"] = "Italic",
    ["it"] = "Italic",
    ["obl"] = "Oblique",

    ["bol"] = "Bold",
    ["bd"] = "Bold",
    ["bolita"] = "Bold Italic",
    ["bdita"] = "Bold Italic",
    ["bdit"] = "Bold Italic",
    ["bditalic"] = "Bold Italic",
    ["boldoblique"] = "Bold Oblique",
    ["bdobl"] = "Bold Oblique",

    ["med"] = "Medium",
    ["md"] = "Medium",
    ["medita"] = "Medium Italic",
    ["mdita"] = "Medium Italic",
    ["mdit"] = "Medium Italic",

    ["semibol"] = "SemiBold",
    ["semibold"] = "SemiBold",
    ["sb"] = "SemiBold",
    ["semibolita"] = "SemiBold Italic",
    ["semibolditalic"] = "SemiBold Italic",
    ["sbit"] = "SemiBold Italic",

    ["lt"] = "Light",
    ["ltit"] = "Light Italic",
    ["exlt"] = "ExtraLight",
    ["exltit"] = "ExtraLight Italic",

    ["blk"] = "Black",
    ["blkit"] = "Black Italic",
    ["exbd"] = "ExtraBold",
    ["exbdit"] = "ExtraBold Italic",
}

local function normalizeStyleName(style)
    style = cleanFontName(style)
    if not style then return nil end
    local key = style:lower():gsub("[%s%-%_]+", "")
    return STYLE_ALIASES[key] or style
end

local function getFontNameRecord(info)
    if type(info) ~= "table" or type(info.names) ~= "table" then return nil end

    local lang = G_reader_settings:readSetting("language")
    lang = type(lang) == "string" and lang:lower():gsub("_", "-") or nil
    local base_lang = lang and lang:match("^([a-z]+)") or nil

    local candidates = { lang, base_lang, "en-us", "en" }
    for _, candidate in ipairs(candidates) do
        if candidate and type(info.names[candidate]) == "table" then
            return info.names[candidate]
        end
    end

    -- Some fonts only expose a single language record. It is still more
    -- reliable than parsing an abbreviated filename.
    for _, record in pairs(info.names) do
        if type(record) == "table" then return record end
    end
end

local function getMetadataName(record, id)
    return record and cleanFontName(record[tonumber(id)])
end

local function inferFamilyAndStyle(info, path)
    local record = getFontNameRecord(info)

    local family = getMetadataName(record, NAME_ID_TYPO_FAMILY)
        or getMetadataName(record, NAME_ID_FAMILY)
        or cleanFontName(info.family_name)
        or cleanFontName(info.family)

    local style = getMetadataName(record, NAME_ID_TYPO_SUBFAMILY)
        or getMetadataName(record, NAME_ID_SUBFAMILY)
        or cleanFontName(info.style_name)
        or cleanFontName(info.style)

    local full_name = getMetadataName(record, NAME_ID_FULL_NAME)
        or cleanFontName(info.name)
        or stripExtension(basename(path))

    -- If only family/full-name metadata is available, derive the style from
    -- the full name before touching the filename.
    if family and (not style or style == "") and full_name:sub(1, #family) == family then
        style = cleanFontName(full_name:sub(#family + 1))
    end

    -- Metadata-poor fonts: retain the previous generic heuristics as fallback.
    if not family or family == "" then
        family = full_name
        for _, suffix in ipairs(STYLE_SUFFIXES) do
            local pattern = "%s+" .. suffix:gsub("(%W)", "%%%1") .. "$"
            if family:match(pattern) then
                family = family:gsub(pattern, "")
                if not style or style == "" then style = suffix end
                break
            end
        end
    end

    if not style or style == "" then
        if full_name:sub(1, #family) == family then
            style = cleanFontName(full_name:sub(#family + 1))
        end
        if not style or style == "" then
            style = stripExtension(basename(path)):match("%-(.+)$") or "Regular"
        end
    end

    style = normalizeStyleName(style) or "Regular"
    return family, style, full_name
end

function SleepRibbon:getFontFamilies()
    FontList:getFontList()
    local grouped = {}
    for path, faces in pairs(FontList.fontinfo or {}) do
        if type(faces) == "table" then
            for _, info in ipairs(faces) do
                if type(info) == "table" then
                    local family, style, full_name = inferFamilyAndStyle(info, path)
                    grouped[family] = grouped[family] or {}
                    table.insert(grouped[family], {
                        family = family,
                        style = style,
                        label = full_name,
                        path = path,
                        index = info.index or 0,
                    })
                end
            end
        end
    end

    local families = {}
    for family, faces in pairs(grouped) do
        table.sort(faces, function(a, b)
            if a.style == b.style then return a.label:lower() < b.label:lower() end
            return a.style:lower() < b.style:lower()
        end)
        table.insert(families, { family = family, faces = faces })
    end
    table.sort(families, function(a, b) return a.family:lower() < b.family:lower() end)
    return families
end

function SleepRibbon:fontFaceExists(path, index)
    if not path or path == "" then return false end
    FontList:getFontList()
    local wanted_name = basename(path)
    local wanted_index = tonumber(index) or 0
    for listed_path, faces in pairs(FontList.fontinfo or {}) do
        if listed_path == path or basename(listed_path) == wanted_name then
            if type(faces) == "table" then
                for _, info in ipairs(faces) do
                    if (tonumber(info.index) or 0) == wanted_index then return true end
                end
            end
        end
    end
    return false
end

function SleepRibbon:fontFaceIsSelected(face)
    return not self:read("use_ui_font")
        and self:read("font_path") == face.path
        and (tonumber(self:read("font_index")) or 0) == (tonumber(face.index) or 0)
end

function SleepRibbon:selectUIFont(touchmenu_instance)
    self:save("use_ui_font", true)
    if touchmenu_instance then touchmenu_instance:updateItems() end
    self:showPreview()
end

function SleepRibbon:selectFontFace(face, touchmenu_instance)
    self.settings:saveSetting("use_ui_font", false)
    self.settings:saveSetting("font_path", face.path)
    self.settings:saveSetting("font_index", face.index or 0)
    self.settings:saveSetting("font_label", face.label or face.style or basename(face.path))
    self.settings:saveSetting("font_family", face.family or "")
    self.settings:saveSetting("font_style", face.style or "")
    self.settings:flush()
    if touchmenu_instance then touchmenu_instance:updateItems() end
    self:showPreview()
end

function SleepRibbon:getFontDisplayName()
    if self:read("use_ui_font") then return _("Use interface font") end
    local family = self:read("font_family") or ""
    local style = self:read("font_style") or self:read("font_label") or ""
    local label = (family ~= "" and style ~= "") and (family .. " — " .. style)
        or (self:read("font_label") or basename(self:read("font_path")))
    if not self:fontFaceExists(self:read("font_path"), self:read("font_index")) then
        label = label .. " (" .. _("unavailable; using interface font") .. ")"
    end
    return label
end

local FAMILY_DEFAULT_STYLE_PRIORITY = {
    ["regular"] = 1,
    ["book"] = 2,
    ["roman"] = 3,
    ["normal"] = 4,
}

function SleepRibbon:getFamilyDefaultFace(faces)
    if type(faces) ~= "table" or #faces == 0 then return nil end
    local best, best_rank
    for _, face in ipairs(faces) do
        local style = tostring(face.style or ""):lower()
        local rank = FAMILY_DEFAULT_STYLE_PRIORITY[style]
        if rank and (not best_rank or rank < best_rank) then
            best, best_rank = face, rank
        end
    end
    if best then return best end

    -- Prefer a non-italic, non-oblique face before falling back to the first
    -- face reported by KOReader.
    for _, face in ipairs(faces) do
        local style = tostring(face.style or ""):lower()
        if not style:find("italic", 1, true) and not style:find("oblique", 1, true) then
            return face
        end
    end
    return faces[1]
end

function SleepRibbon:fontFuncForFace(face)
    if not face then return nil end
    return function(size)
        return self:getConfiguredFace(size, face.path, face.index)
    end
end

function SleepRibbon:buildFontMenu()
    local menu = {
        {
            text = _("Use interface font"),
            help_text = _("Follow KOReader's current UI content font. If the UI font changes, SleepRibbon follows it automatically."),
            radio = true,
            checked_func = function() return self:read("use_ui_font") and true or false end,
            font_func = function(size) return self:getUIFontFace(size) end,
            keep_menu_open = true,
            callback = function(touchmenu_instance) self:selectUIFont(touchmenu_instance) end,
        },
        {
            text = _("Preview current font"),
            keep_menu_open = true,
            callback = function() self:showPreview() end,
            separator = true,
        },
    }

    local families = self:getFontFamilies()
    for _, family_entry in ipairs(families) do
        local entry = family_entry
        local default_face = self:getFamilyDefaultFace(entry.faces)
        table.insert(menu, {
            text = entry.family,
            font_func = self:fontFuncForFace(default_face),
            sub_item_table_func = function()
                local styles = {}
                for _, face_entry in ipairs(entry.faces) do
                    local face = face_entry
                    table.insert(styles, {
                        text = face.style,
                        font_func = self:fontFuncForFace(face),
                        radio = true,
                        checked_func = function() return self:fontFaceIsSelected(face) end,
                        keep_menu_open = true,
                        callback = function(touchmenu_instance) self:selectFontFace(face, touchmenu_instance) end,
                        hold_callback = function()
                            self:showPreview(self:getConfiguredFace(self:read("font_size"), face.path, face.index))
                        end,
                    })
                end
                return styles
            end,
        })
    end

    if #families == 0 then
        table.insert(menu, { text = _("No fonts were discovered"), enabled = false })
    end
    return menu
end

function SleepRibbon:refreshFonts()
    FontList.fontlist = {}
    FontList.fontinfo = {}
    FontList.fontnames = {}
    local ok, err = pcall(FontList.getFontList, FontList)
    if ok then
        Notification:notify(_("SleepRibbon font list refreshed"))
    else
        logger.warn("SleepRibbon: failed to refresh fonts:", err)
        UIManager:show(InfoMessage:new{
            text = _("The font list could not be refreshed. KOReader's existing font cache will be used until the next restart."),
        })
    end
end

-- ---------------------------------------------------------------------------
-- Color picker / preview
-- ---------------------------------------------------------------------------

function SleepRibbon:getPreviewMessage()
    local message = G_reader_settings:readSetting("screensaver_message")
    if not message or message == "" then
        local ok, Screensaver = pcall(require, "ui/screensaver")
        message = ok and Screensaver.default_screensaver_message or KO_("Sleeping")
    end

    local ui = self.ui
    local bookinfo = ui and ui.bookinfo
    local file = (ui and ui.document and ui.document.file)
        or G_reader_settings:readSetting("lastfile")

    -- Preview is not running inside Device.screen_saver_mode, so apply the
    -- same %H fallback explicitly before asking KOReader to expand the rest.
    if type(message) == "string" and message:find("%H", 1, true) and file then
        local seconds = bookinfo and self:getCurrentTimeLeftSeconds(bookinfo, file)
        if seconds then
            self:saveCachedTimeLeft(file, seconds)
        else
            seconds = self:getCachedTimeLeft(file)
        end
        if seconds then
            local replacement = self:formatTimeLeft(seconds)
            message = message:gsub("%%H", function() return replacement end)
        end
    end

    if bookinfo and type(bookinfo.expandString) == "function" then
        local ok, expanded = pcall(bookinfo.expandString, bookinfo, message, file)
        if ok and type(expanded) == "string" and expanded ~= "" then
            return expanded
        end
    end

    return message
end

function SleepRibbon:showColorPicker(setting_key, title, touchmenu_instance)
    ColorPicker.show{
        title = title,
        value = self:read(setting_key),
        default_value = DEFAULTS[setting_key],
        callback = function(value)
            self:save(setting_key, value)
            if touchmenu_instance then touchmenu_instance:updateItems() end
        end,
    }
end

function SleepRibbon:showPreview(face_override)
    local width = math.floor(Screen:getWidth() * 0.82)
    local preview_text = self:getPreviewMessage()
    local ribbon = self:buildRibbonWidget(
        preview_text,
        width,
        self:getProgress(preview_text),
        face_override
    )
    local preview = PreviewDialog:new{ ribbon_widget = ribbon }

    -- TouchMenu may repaint itself after a keep_menu_open callback returns.
    -- Defer the preview by one UI tick so it is pushed above the retained menu.
    UIManager:nextTick(function()
        UIManager:show(preview)
    end)
end

-- ---------------------------------------------------------------------------
-- Menu
-- ---------------------------------------------------------------------------

function SleepRibbon:spinSetting(setting_key, title, min_value, max_value, default_value, unit, touchmenu_instance)
    UIManager:show(SpinWidget:new{
        title_text = title,
        value = tonumber(self:read(setting_key)) or default_value,
        value_min = min_value,
        value_max = max_value,
        value_step = 1,
        value_hold_step = 5,
        default_value = default_value,
        unit = unit,
        ok_text = _("Set"),
        callback = function(spin)
            self:save(setting_key, spin.value)
            if touchmenu_instance then touchmenu_instance:updateItems() end
        end,
    })
end

function SleepRibbon:getMenuItem()
    return {
        text = "SleepRibbon",
        help_text = _("Styles the native sleep-screen Banner. KOReader remains responsible for the cover, message tokens, opacity and vertical position."),
        sub_item_table = {
            {
                text = _("Enabled"),
                keep_menu_open = true,
                checked_func = function() return self:isEnabled() end,
                callback = function(touchmenu_instance)
                    self:save("enabled", not self:isEnabled())
                    if touchmenu_instance then touchmenu_instance:updateItems() end
                end,
            },
            {
                text = _("Preview"),
                keep_menu_open = true,
                callback = function() self:showPreview() end,
                separator = true,
            },
            {
                text_func = function() return _("Font") .. ": " .. self:getFontDisplayName() end,
                sub_item_table_func = function() return self:buildFontMenu() end,
            },
            {
                text_func = function() return _("Font size") .. ": " .. tostring(self:read("font_size")) end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    self:spinSetting("font_size", _("Font size"), 10, 48, DEFAULTS.font_size, nil, touchmenu_instance)
                end,
            },
            {
                text_func = function() return _("Text color") .. ": " .. tostring(self:read("text_color")) end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    self:showColorPicker("text_color", _("Text color"), touchmenu_instance)
                end,
            },
            {
                text_func = function()
                    local value = self:read("text_alignment")
                    local label = value == "left" and _("Left")
                        or value == "right" and _("Right")
                        or _("Center")
                    return _("Text alignment") .. ": " .. label
                end,
                sub_item_table = {
                    {
                        text = _("Left"),
                        radio = true,
                        keep_menu_open = true,
                        checked_func = function() return self:read("text_alignment") == "left" end,
                        callback = function(touchmenu_instance)
                            self:save("text_alignment", "left")
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                    {
                        text = _("Center"),
                        radio = true,
                        keep_menu_open = true,
                        checked_func = function() return self:read("text_alignment") ~= "left" and self:read("text_alignment") ~= "right" end,
                        callback = function(touchmenu_instance)
                            self:save("text_alignment", "center")
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                    {
                        text = _("Right"),
                        radio = true,
                        keep_menu_open = true,
                        checked_func = function() return self:read("text_alignment") == "right" end,
                        callback = function(touchmenu_instance)
                            self:save("text_alignment", "right")
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                },
            },
            {
                text_func = function()
                    return _("Horizontal padding") .. ": " .. tostring(self:read("horizontal_padding")) .. " px"
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    self:spinSetting(
                        "horizontal_padding",
                        _("Horizontal padding"),
                        0, 100, DEFAULTS.horizontal_padding, "px",
                        touchmenu_instance
                    )
                end,
            },
            {
                text = _("Background"),
                keep_menu_open = true,
                checked_func = function() return self:read("background_enabled") and true or false end,
                callback = function(touchmenu_instance)
                    self:save("background_enabled", not self:read("background_enabled"))
                    if touchmenu_instance then touchmenu_instance:updateItems() end
                end,
            },
            {
                text_func = function() return _("Background color") .. ": " .. tostring(self:read("background_color")) end,
                keep_menu_open = true,
                enabled_func = function() return self:read("background_enabled") and true or false end,
                callback = function(touchmenu_instance)
                    self:showColorPicker("background_color", _("Background color"), touchmenu_instance)
                end,
            },
            {
                text_func = function()
                    return _("Ribbon vertical padding") .. ": " .. tostring(self:read("vertical_padding")) .. " px"
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    self:spinSetting("vertical_padding", _("Ribbon vertical padding"), 0, 30, DEFAULTS.vertical_padding, "px", touchmenu_instance)
                end,
                separator = true,
            },
            {
                text = _("Progress bar"),
                keep_menu_open = true,
                checked_func = function() return self:read("progress_enabled") and true or false end,
                callback = function(touchmenu_instance)
                    self:save("progress_enabled", not self:read("progress_enabled"))
                    if touchmenu_instance then touchmenu_instance:updateItems() end
                end,
            },
            {
                text_func = function()
                    return _("Bar position") .. ": " .. (self:read("progress_position") == "bottom" and _("Bottom") or _("Top"))
                end,
                enabled_func = function() return self:read("progress_enabled") and true or false end,
                sub_item_table = {
                    {
                        text = _("Top"), radio = true, keep_menu_open = true,
                        checked_func = function() return self:read("progress_position") ~= "bottom" end,
                        callback = function(touchmenu_instance)
                            self:save("progress_position", "top")
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                    {
                        text = _("Bottom"), radio = true, keep_menu_open = true,
                        checked_func = function() return self:read("progress_position") == "bottom" end,
                        callback = function(touchmenu_instance)
                            self:save("progress_position", "bottom")
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                },
            },
            {
                text_func = function()
                    local mode = self:read("progress_show_remainder") and _("Completed + remaining") or _("Completed only")
                    return _("Progress display") .. ": " .. mode
                end,
                enabled_func = function() return self:read("progress_enabled") and true or false end,
                sub_item_table = {
                    {
                        text = _("Completed only"), radio = true, keep_menu_open = true,
                        checked_func = function() return not self:read("progress_show_remainder") end,
                        callback = function(touchmenu_instance)
                            self:save("progress_show_remainder", false)
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                    {
                        text = _("Completed + remaining"), radio = true, keep_menu_open = true,
                        checked_func = function() return self:read("progress_show_remainder") and true or false end,
                        callback = function(touchmenu_instance)
                            self:save("progress_show_remainder", true)
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                        end,
                    },
                },
            },
            {
                text_func = function()
                    return _("Bar thickness") .. ": " .. tostring(self:read("progress_height")) .. " px"
                end,
                keep_menu_open = true,
                enabled_func = function() return self:read("progress_enabled") and true or false end,
                callback = function(touchmenu_instance)
                    self:spinSetting("progress_height", _("Bar thickness"), 1, 20, DEFAULTS.progress_height, "px", touchmenu_instance)
                end,
            },
            {
                text_func = function() return _("Completed progress color") .. ": " .. tostring(self:read("progress_color")) end,
                keep_menu_open = true,
                enabled_func = function() return self:read("progress_enabled") and true or false end,
                callback = function(touchmenu_instance)
                    self:showColorPicker("progress_color", _("Completed progress color"), touchmenu_instance)
                end,
            },
            {
                text_func = function() return _("Remaining progress color") .. ": " .. tostring(self:read("remainder_color")) end,
                keep_menu_open = true,
                enabled_func = function()
                    return self:read("progress_enabled") and self:read("progress_show_remainder") and true or false
                end,
                callback = function(touchmenu_instance)
                    self:showColorPicker("remainder_color", _("Remaining progress color"), touchmenu_instance)
                end,
                separator = true,
            },
            {
                text = _("Refresh font list"),
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    self:refreshFonts()
                    if touchmenu_instance then touchmenu_instance:updateItems() end
                end,
            },
            {
                text = _("Restore SleepRibbon defaults"),
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    UIManager:show(ConfirmBox:new{
                        text = _("Restore SleepRibbon's default appearance?"),
                        ok_text = _("Restore"),
                        ok_callback = function()
                            self:resetDefaults()
                            if touchmenu_instance then touchmenu_instance:updateItems() end
                            Notification:notify(_("SleepRibbon defaults restored"))
                        end,
                    })
                end,
            },
        },
    }
end

local function findItemFromPath(menu, ...)
    local function findSubItem(sub_items, text)
        if type(sub_items) ~= "table" then return nil end
        for _, item in ipairs(sub_items) do
            local item_text = item.text or (item.text_func and item.text_func())
            if item_text and item_text == text then
                return item
            end
        end
        return nil
    end

    local sub_items, item
    for _, text in ipairs{ ... } do
        sub_items = item and item.sub_item_table or menu
        if not sub_items then return nil end
        item = findSubItem(sub_items, text)
        if not item then return nil end
    end
    return item
end

local function insertSleepRibbonInBuiltMenu(menu, order, instance)
    if not (menu and order and instance and menu.tab_item_table) then return false end

    local buttons = order["KOMenu:menu_buttons"]
    if type(buttons) ~= "table" then return false end

    for i, button in ipairs(buttons) do
        if button == "setting" then
            local setting_menu = menu.tab_item_table[i]
            if setting_menu then
                local sleep_screen = findItemFromPath(
                    setting_menu,
                    KO_("Screen"),
                    KO_("Sleep screen")
                )
                local items = sleep_screen and sleep_screen.sub_item_table
                if type(items) ~= "table" then return false end

                -- Idempotent: the final menu tree may be rebuilt more than once.
                for _, item in ipairs(items) do
                    if item.text == "SleepRibbon" then return true end
                end

                local insert_at = #items + 1
                for idx, item in ipairs(items) do
                    local item_text = item.text or (item.text_func and item.text_func())
                    if item_text == KO_("Container and position") then
                        insert_at = idx + 1
                        break
                    end
                end

                table.insert(items, insert_at, instance:getMenuItem())
                return true
            end
        end
    end
    return false
end

function SleepRibbon:installMenuHooks()
    if menu_hooks_installed then return end

    local original_reader_set = ReaderMenu.setUpdateItemTable
    ReaderMenu.setUpdateItemTable = function(menu, ...)
        local result = original_reader_set(menu, ...)
        local instance = menu_instances[menu] or active_instance
        if instance then
            local ok, err = pcall(insertSleepRibbonInBuiltMenu, menu, ReaderMenuOrder, instance)
            if not ok then logger.warn("SleepRibbon: Reader menu injection failed:", err) end
        end
        return result
    end

    local original_filemanager_set = FileManagerMenu.setUpdateItemTable
    FileManagerMenu.setUpdateItemTable = function(menu, ...)
        local result = original_filemanager_set(menu, ...)
        local instance = menu_instances[menu] or active_instance
        if instance then
            local ok, err = pcall(insertSleepRibbonInBuiltMenu, menu, FileManagerMenuOrder, instance)
            if not ok then logger.warn("SleepRibbon: File Manager menu injection failed:", err) end
        end
        return result
    end

    menu_hooks_installed = true
end

function SleepRibbon:addToMainMenu(_menu_items)
    -- Intentionally empty. SleepRibbon is injected only after KOReader has
    -- built the real menu tree, so it appears at:
    -- Settings > Screen > Sleep screen > SleepRibbon.
end

return SleepRibbon
