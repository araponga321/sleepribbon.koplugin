# Changelog



## [1.2.0] - 2026-11-15

### Added

- Full-screen sleep-screen preview, displaying the configured sleep-screen image with the SleepRibbon overlay.
- Automatic preview after confirmed changes to message, typography, colors, layout, position, opacity and progress-bar settings.
- Automatic preview when switching between Global and Current book profiles.

### Changed

- Replaced the previous ribbon-only preview dialog with a full-screen representation of the sleep screen.
- Preview now follows KOReader's applicable sleep-screen image selection, scaling and rotation settings.
- Preview preserves the current frontlight state without entering sleep mode.
- Dismissing the preview returns to the previous menu. Automatic previews are skipped when settings remain unchanged.


## \[1.1.0] - 2026-09-30

### Added

* Optional per-book profiles with inheritance from the Global configuration.
* Per-book overrides for sleep-screen message, position, opacity, typography, colors, layout and progress-bar settings.
* Cover-derived 25-color palette in the color picker, cached per book and refreshable from Maintenance.
* Direct editing of the native sleep-screen message, position and opacity from the SleepRibbon menu.
* Maintenance actions for refreshing the cover palette and resetting the current book profile.

### Changed

* Moved SleepRibbon to the main **Settings** menu, at the same hierarchy level as **Screen**, using KOReader's normal plugin menu registration.
* Reorganized settings into profile, sleep-screen message, text, background, progress-bar and maintenance sections.
* Increased the horizontal-padding range dynamically according to screen width.
* The color picker opens on the **Cover** palette when a cover palette is available, with **Cover** and **Standard** palettes available side by side.
* Preview now reflects the selected Global or Current book profile.

### Fixed

* Replaced the fragile post-build submenu injection used in v1.0.0 with KOReader's normal plugin menu registration, improving menu availability across KOReader contexts.

## \[1.0.0] - 2026-09-29

* Initial public release.

