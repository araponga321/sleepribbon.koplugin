-- SleepRibbon full-screen preview (experimental).
-- Uses KOReader's native sleep-screen image selection and image widgets,
-- but NEVER enters sleep mode or changes the device's frontlight.

local Blitbuffer = require("ffi/blitbuffer")
local CustomPositionContainer = require("ui/widget/container/custompositioncontainer")
local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local ImageWidget = require("ui/widget/imagewidget")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local RenderImage = require("ui/renderimage")
local Screen = Device.screen
local UIManager = require("ui/uimanager")
local logger = require("logger")
local util = require("util")
local _ = require("sleepribbon_i18n").gettext

local PreviewScreen = InputContainer:extend{
    name = "SleepRibbonFullScreenPreview",
    modal = true,
    covers_fullscreen = true,
    dithered = true,
}

function PreviewScreen:init()
    local w, h = Screen:getWidth(), Screen:getHeight()

    if Device:isTouchDevice() then
        self.ges_events = {
            TapClose = {
                GestureRange:new{
                    ges = "tap",
                    range = Geom:new{ x = 0, y = 0, w = w, h = h },
                },
            },
        }
    end
    if Device:hasKeys() then
        self.key_events.AnyKeyPressed = { { Device.input.group.Any } }
    end

    self[1] = FrameContainer:new{
        radius = 0,
        bordersize = 0,
        padding = 0,
        margin = 0,
        width = w,
        height = h,
        background = self.preview_background,
        self.preview_widget,
    }
end

function PreviewScreen:onShow()
    -- A full refresh makes the e-ink preview legible. It does not control the
    -- frontlight (unlike the hardware suspend/resume process).
    UIManager:setDirty(self, "full")
    return true
end

function PreviewScreen:onTapClose()
    UIManager:close(self, "full")
    return true
end
PreviewScreen.onAnyKeyPressed = PreviewScreen.onTapClose

function PreviewScreen:onCloseWidget()
    -- Return the UI to the orientation from which preview was opened.
    if self.previous_rotation ~= nil then
        Screen:setRotationMode(self.previous_rotation)
        self.previous_rotation = nil
    end
    UIManager:setDirty(nil, "full")
end

local function saveCycleIndex()
    return {
        existed = G_reader_settings:has("screensaver_cycle_index"),
        value = G_reader_settings:readSetting("screensaver_cycle_index"),
    }
end

local function restoreCycleIndex(saved)
    -- Screensaver:setup() advances the image cycle on some configurations.
    -- Preview must not change the image selected for the NEXT real suspend.
    if saved.existed then
        G_reader_settings:saveSetting("screensaver_cycle_index", saved.value)
    else
        G_reader_settings:delSetting("screensaver_cycle_index")
    end
end

local function loadSleepScreenState()
    local Screensaver = require("ui/screensaver")
    -- The native Screensaver is a singleton. A derived state table allows
    -- setup() to choose the applicable cover/fallback WITHOUT changing its
    -- global runtime state, and without calling Screensaver:show().
    local state = setmetatable({}, { __index = Screensaver })
    local saved = saveCycleIndex()
    local ok, err = pcall(state.setup, state)
    restoreCycleIndex(saved)
    if not ok then
        logger.warn("SleepRibbon: preview cover selection failed:", err)
        if state.image and state.image.free then
            pcall(state.image.free, state.image)
        end
        return nil, err
    end
    return state
end

local function nativeBackground(state)
    if state.screensaver_background == "black" then
        return Blitbuffer.COLOR_BLACK
    elseif state.screensaver_background == "white" then
        return Blitbuffer.COLOR_WHITE
    end
    -- The native "none" setting retains the underlying pixels where an
    -- image does not cover the screen, so don't invent a new fill here.
    return nil
end

local function makeImageWidget(state, w, h, sleep_rotation)
    if state.screensaver_type ~= "cover" and state.screensaver_type ~= "random_image" then
        return nil
    end

    -- Match the native Screensaver.show() ImageWidget settings.
    local settings = {
        width = w,
        height = h,
        scale_factor = G_reader_settings:isFalse("screensaver_stretch_images") and 0 or nil,
        crop_to_fit = G_reader_settings:isTrue("screensaver_images_crop_to_fit"),
        stretch_limit_percentage = G_reader_settings:readSetting("screensaver_stretch_limit_percentage"),
    }
    if state.image then
        settings.image = state.image
        settings.image_disposable = true
    elseif state.image_file then
        if G_reader_settings:isTrue("screensaver_rotate_auto_for_best_fit") then
            if util.getFileNameSuffix(state.image_file) == "svg" then
                settings.image = RenderImage:renderSVGImageFile(state.image_file, nil, nil, 1)
            else
                settings.image = RenderImage:renderImageFile(state.image_file, false, nil, nil)
            end
            if not settings.image then
                settings.image = RenderImage:renderCheckerboard(w, h, Screen.bb:getType())
            end
            settings.image_disposable = true
        else
            settings.file = state.image_file
            settings.file_do_cache = false
        end
        settings.alpha = true
    end
    if not settings.image and not settings.file then
        return nil
    end

    if G_reader_settings:isTrue("screensaver_rotate_auto_for_best_fit") and settings.image then
        local angle = sleep_rotation == 3 and 180 or 0
        if (settings.image:getWidth() < settings.image:getHeight()) ~= (w < h) then
            angle = angle + (G_reader_settings:isTrue("imageviewer_rotation_landscape_invert") and -90 or 90)
        end
        settings.rotation_angle = angle
    end

    local image = ImageWidget:new(settings)
    -- ImageWidget decodes lazily. Catch errors before placing an invalid file
    -- on the UI stack, so the reader is never stranded with a broken preview.
    local ok, err = pcall(image.getSize, image)
    if not ok then
        logger.warn("SleepRibbon: preview image rendering failed:", err)
        pcall(image.free, image)
        return nil
    end
    return image
end

local function makePreview(plugin, face_override, state, sleep_rotation)
    local w, h = Screen:getWidth(), Screen:getHeight()
    local message = plugin:getPreviewMessage()
    local ribbon = plugin:buildRibbonWidget(message, w, plugin:getProgress(message), face_override)

    local position = math.max(0, math.min(100, plugin:getScopedMessagePosition()))
    local opacity = math.max(0, math.min(100, plugin:getScopedMessageOpacity()))
    local overlay = CustomPositionContainer:new{
        widget = ribbon,
        vertical_position = 1 - position / 100,
        alpha = opacity / 100,
    }

    local image = makeImageWidget(state, w, h, sleep_rotation)
    local content = overlay
    if image then
        content = OverlapGroup:new{
            dimen = Geom:new{ x = 0, y = 0, w = w, h = h },
            image,
            overlay,
        }
    end

    return PreviewScreen:new{
        preview_widget = content,
        preview_background = nativeBackground(state),
    }
end

local M = {}

function M.show(plugin, face_override)
    -- TouchMenu may repaint after keep_menu_open returns. Do everything
    -- (including any temporary orientation change) in the next UI tick.
    UIManager:nextTick(function()
        local state, err = loadSleepScreenState()
        if not state then
            UIManager:show(InfoMessage:new{
                text = _("Could not load the sleep-screen image for preview."),
            })
            return
        end

        local previous_rotation
        local sleep_rotation = Screen:getRotationMode()
        -- Native sleep screens generally switch to portrait for cover images.
        -- Preserve and restore the current reading/menu orientation on exit.
        if state:modeExpectsPortrait() then
            if bit.band(sleep_rotation, 1) == 1 then
                local rotated, rotation_err = pcall(Screen.setRotationMode, Screen, Screen.DEVICE_ROTATED_UPRIGHT)
                if rotated then
                    previous_rotation = sleep_rotation
                else
                    logger.warn("SleepRibbon: preview rotation failed:", rotation_err)
                end
            end
        end

        local ok, preview_or_error = pcall(makePreview, plugin, face_override, state, sleep_rotation)
        if not ok then
            if previous_rotation ~= nil then
                Screen:setRotationMode(previous_rotation)
            end
            if state.image and state.image.free then
                pcall(state.image.free, state.image)
            end
            logger.warn("SleepRibbon: preview construction failed:", preview_or_error)
            UIManager:show(InfoMessage:new{
                text = _("Could not build the SleepRibbon preview."),
            })
            return
        end

        local preview = preview_or_error
        preview.previous_rotation = previous_rotation
        local shown, show_err = pcall(UIManager.show, UIManager, preview, "full")
        if not shown then
            -- Do not retain a rotated interface after an unexpected UI error.
            if previous_rotation ~= nil then
                Screen:setRotationMode(previous_rotation)
            end
            if preview.free then pcall(preview.free, preview) end
            logger.warn("SleepRibbon: preview display failed:", show_err)
            UIManager:show(InfoMessage:new{
                text = _("Could not display the SleepRibbon preview."),
            })
        end
    end)
end

return M
