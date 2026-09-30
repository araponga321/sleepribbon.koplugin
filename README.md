# SleepRibbon

SleepRibbon is a minimal sleep-screen plugin for KOReader.

It was made for readers who like having useful information on the sleep screen, such as reading progress, page or time remaining, while still wanting the book cover to remain visually dominant.

Rather than placing a large information panel over the cover, SleepRibbon styles KOReader's native sleep-screen banner and keeps it highly configurable; it can range from a subtle ribbon to just text and a thin progress bar that blends into the cover artwork.

![SleepRibbon default appearance](assets/sleep-screen-default.png)

![SleepRibbon menu demo](assets/sleepribbon-menu-demo-v1.1.0.webp)

## Features

- Uses KOReader's native sleep-screen message system
- Global settings with optional per-book profiles
- Direct editing of the sleep-screen message, position and opacity from SleepRibbon
- Cover-derived color palette for matching the ribbon to the current book cover
- Configurable font family, style and size, using fonts detected by KOReader, including user-added fonts
- Left, center or right text alignment
- Adjustable horizontal padding, scaled to the device screen width
- Custom text and banner background colors
- The banner background can be disabled entirely
- Optional progress bar, above or below the message, with completed-only or completed + remaining styles, configurable thickness and independent colors
- Live preview of the current global or per-book configuration
- Persistent fallback for KOReader's `%H` time-remaining token
- English, Portuguese and Spanish interface
- No polling, background timers or periodic tasks

## How it works

SleepRibbon does not replace KOReader's sleep-screen system. It changes how the native **Banner** message is presented.

KOReader still needs the native sleep-screen custom message enabled and its message container set to **Banner**. Once that is configured, the message content, position and opacity can be edited directly from SleepRibbon.

SleepRibbon provides two configuration scopes:

- **Global** — the default appearance and message used by all books.
- **Current book** — optional per-book overrides. Settings that are not overridden continue to inherit the Global configuration.

Per-book settings are stored with the book's KOReader document settings, so each book can keep its own message, typography, colors, layout and progress-bar appearance.

> **SleepRibbon requires the native sleep-screen message container to be set to Banner. The Box container is not styled by the plugin.**

### Message tokens

SleepRibbon uses KOReader's native sleep-screen message expansion, so the tokens supported by KOReader can be used normally.

For example:

```text
%p · Page %c of %t · %H
```

SleepRibbon receives the expanded message and styles the result.

This means the plugin is not limited to progress, page count or time remaining. The information displayed is determined by the message you configure.

## Installation

1. Download the latest SleepRibbon release.

2. Extract the `sleepribbon.koplugin` folder from the downloaded ZIP.

3. Copy that folder into:

   ```text
   koreader/plugins/
   ```

   The resulting structure should look like:

   ```text
   koreader/
   └── plugins/
       └── sleepribbon.koplugin/
           ├── _meta.lua
           ├── main.lua
           ├── sleepribbon_colorpicker.lua
           ├── sleepribbon_i18n.lua
           └── ...
   ```

4. Restart KOReader.

5. In KOReader's native **Sleep screen** settings:
   - enable **Add custom message to sleep screen**
   - open **Container and position** and select **Banner**

6. Open **Settings → SleepRibbon** to configure the plugin.

No additional patch is required.

## Settings

| Setting | Description |
|---|---|
| Profile | Switches between the Global configuration and the Current book profile |
| Preview | Shows the current configuration using the expanded sleep-screen message |
| Message | Edits the native sleep-screen message for the selected profile |
| Position | Adjusts the vertical position of the message |
| Opacity | Adjusts the sleep-screen message container opacity |
| Font | Uses the interface font or any font detected by KOReader, including user-added fonts |
| Font size | Adjusts the message text size |
| Text alignment | Left, center or right |
| Horizontal padding | Adds horizontal space around the text; the available range scales with screen width |
| Text color | Controls the message text color |
| Background | Enables or disables the banner background |
| Background color | Controls the banner background color |
| Ribbon vertical padding | Adjusts vertical space around the message |
| Progress bar | Enables or disables the progress indicator |
| Progress position | Places the progress bar above or below the message |
| Progress style | Shows completed progress only, or completed + remaining progress |
| Progress thickness | Adjusts the height of the progress bar |
| Progress colors | Uses independent colors for completed and remaining progress |
| Cover palette | Offers colors automatically derived from the current book cover alongside the standard palette |
| Maintenance | Refreshes the font list or cover palette, and resets the current profile or Global defaults |

## Cover palette

When a book is available, SleepRibbon can derive a 25-color palette from its cover. The **Cover** palette is shown alongside the **Standard** palette in the color picker and opens by default when available.

The palette is cached per book and can be regenerated from **Maintenance → Refresh cover palette**.

The palette only provides color choices; the user remains free to select any color manually or use the Standard palette.

## Per-book profiles

The **Global** profile remains the default for every book.

Selecting **Current book** creates a book-specific configuration. Any setting changed there overrides the corresponding Global value for that book, while untouched settings continue to inherit the Global configuration.

Use **Maintenance → Reset current book profile** to remove those overrides and return the book to the Global configuration.

## Time remaining (`%H`)

KOReader can calculate the estimated reading time remaining while a book is open, but that value may not always be available after returning to the file manager.

SleepRibbon stores the last valid `%H` value for each book and can reuse it on the sleep screen when KOReader cannot provide a fresh estimate.

The cached value is updated only when KOReader already has a valid estimate available. SleepRibbon does not use polling, background timers or periodic checks to maintain it.

## Examples

Each example pairs the resulting sleep screen with the palette automatically derived from that book's cover.

| Sleep screen | Cover palette |
|---|---|
| ![O Alienista](assets/example-alienista.png) | ![O Alienista cover palette](assets/palette-alienista.png) |
| ![Auto da Compadecida](assets/example-auto-da-compadecida.png) | ![Auto da Compadecida cover palette](assets/palette-auto-da-compadecida.png) |
| ![O Quinze](assets/example-o-quinze.png) | ![O Quinze cover palette](assets/palette-o-quinze.png) |
| ![Technofeudalism](assets/example-technofeudalism.png) | ![Technofeudalism cover palette](assets/palette-technofeudalism.png) |
| ![A Hora da Estrela](assets/example-hora-da-estrela.png) | ![A Hora da Estrela cover palette](assets/palette-hora-da-estrela.png) |
| ![Vidas Secas](assets/example-vidas-secas.png) | ![Vidas Secas cover palette](assets/palette-vidas-secas.png) |
| ![Triste Fim de Policarpo Quaresma](assets/example-policarpo.png) | ![Triste Fim de Policarpo Quaresma cover palette](assets/palette-policarpo.png) |
| ![Morte e Vida Severina](assets/example-morte-e-vida.png) | ![Morte e Vida Severina cover palette](assets/palette-morte-e-vida.png) |
| ![Graciliano Ramos — Obra Completa](assets/example-obra-completa.png) | ![Obra Completa cover palette](assets/palette-obra-completa.png) |

## Localization

SleepRibbon currently includes:

- English
- Portuguese
- Spanish

Other KOReader interface languages fall back to English.

## Battery use

SleepRibbon does not run a polling loop, background timer or recurring task.

Its work is limited to configuration, preview generation, cover-palette extraction when needed and rendering the sleep-screen message, so it should not introduce meaningful additional battery usage during normal reading.

## Compatibility

SleepRibbon v1.1.0 has been tested with:

- KOReader emulator based on v2026.07.2
- Kindle Colorsoft

Because SleepRibbon integrates with internal KOReader UI components, future KOReader changes may occasionally require compatibility updates.

When reporting a problem, please include the device model, KOReader version and SleepRibbon version whenever possible.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

SleepRibbon is released under the GNU Affero General Public License v3.0 (AGPL-3.0).

Parts of the sleep-screen rendering implementation are adapted from KOReader, which is also distributed under the AGPL-3.0 license.

See [LICENSE](LICENSE) for details.

## Credits

SleepRibbon is an unofficial plugin for [KOReader](https://github.com/koreader/koreader).

Book cover artwork shown in screenshots belongs to its respective copyright holders and is used here solely to demonstrate the plugin interface.
