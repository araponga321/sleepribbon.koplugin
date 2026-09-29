# SleepRibbon

SleepRibbon is a minimal sleep-screen plugin for KOReader.

It was made for readers who like having useful information on the sleep screen, such as reading progress, page or time remaining, while still wanting the book cover to remain visually dominant.

Rather than placing a large information panel over the cover, SleepRibbon styles KOReader's native sleep-screen banner and keeps it highly configurable; it can range from a subtle ribbon to just text and a thin progress bar that blends into the cover artwork.

![SleepRibbon default appearance](assets/sleep-screen-default.png)

![SleepRibbon menu demo](assets/sleepribbon-menu-demo.webp)

## Features

- Uses KOReader's native sleep-screen message system
- Configurable font family, style and size, using fonts detected by KOReader, including user-added fonts
- Left, center or right text alignment
- Adjustable horizontal padding
- Custom text and banner background colors
- The banner background can be disabled entirely
- Optional progress bar, above or below the message, with completed-only or completed + remaining styles, configurable thickness and independent colors
- Live preview of the current configuration
- Persistent fallback for KOReader's `%H` time-remaining token
- English, Portuguese and Spanish interface
- No polling, background timers or periodic tasks

## How it works

SleepRibbon does not replace KOReader's sleep-screen system. It changes how the native **Banner** message is presented.

You still use KOReader's own **Sleep screen** settings to control the message content and its basic placement.

In KOReader:

- Enable **Add custom message to sleep screen**
- Use **Edit sleep screen message** to define what is displayed
- Open **Container and position**
  - select **Banner**
  - adjust **Vertical position**
  - adjust **Message opacity**

SleepRibbon then controls the visual presentation of that banner, including its font, size, text and background colors, alignment, horizontal padding and optional progress bar.

> **SleepRibbon requires the native sleep-screen message container to be set to Banner. The Box container is not styled by the plugin.**

### Message tokens

The message itself is still configured through KOReader, so the sleep-screen tokens supported by KOReader can be used normally.

For example:

```text
%p · Page %c of %t · %H
```

SleepRibbon receives the expanded message and styles the result.

This means the plugin is not limited to progress, page count or time remaining. The information displayed is determined by the message you configure in KOReader.

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
           ├── sleepribbon_i18n.lua
           └── ...
   ```

4. Restart KOReader.

5. Open:

   **Settings → Screen → Sleep screen → SleepRibbon**

6. In KOReader's native **Sleep screen** settings:
   - enable **Add custom message to sleep screen**
   - use **Edit sleep screen message** to configure the content
   - open **Container and position** and select **Banner**

No additional patch is required.

## Settings

SleepRibbon keeps the content of the message separate from its appearance.

| Setting | Description |
|---|---|
| Font | Uses the interface font or any font detected by KOReader, including user-added fonts |
| Font size | Adjusts the message text size |
| Text alignment | Left, center or right |
| Horizontal padding | Adds horizontal space between the text and the screen edges |
| Text color | Controls the message text color |
| Background | Enables or disables the banner background |
| Background color | Controls the banner background color |
| Progress bar | Enables or disables the progress indicator |
| Progress position | Places the progress bar above or below the message |
| Progress style | Shows completed progress only, or completed + remaining progress |
| Progress thickness | Adjusts the height of the progress bar |
| Progress colors | Uses independent colors for completed and remaining progress |
| Preview | Shows the current configuration using the expanded sleep-screen message |

## Time remaining (`%H`)

KOReader can calculate the estimated reading time remaining while a book is open, but that value may not always be available after returning to the file manager.

SleepRibbon stores the last valid `%H` value for each book and can reuse it on the sleep screen when KOReader cannot provide a fresh estimate.

The cached value is updated only when KOReader already has a valid estimate available. SleepRibbon does not use polling, background timers or periodic checks to maintain it.

## Examples

The examples below use different combinations of font, color, background, opacity, alignment and progress-bar settings.

The sleep-screen message content itself remains controlled by KOReader.

| | |
|---|---|
| ![Triste Fim de Policarpo Quaresma](assets/sleep-screen-policarpo.png) | ![O Hobbit](assets/sleep-screen-hobbit.png) |
| ![Morte e Vida Severina](assets/sleep-screen-morte-e-vida.png) | ![O Alienista](assets/sleep-screen-alienista.png) |
| ![Assassinato no Expresso Oriente](assets/sleep-screen-expresso-oriente.png) | |

## Localization

SleepRibbon currently includes:

- English
- Portuguese
- Spanish

Other KOReader interface languages fall back to English.

## Battery use

SleepRibbon does not run a polling loop, background timer or recurring task.

Its work is limited to configuration, preview generation and rendering the sleep-screen message, so it should not introduce meaningful additional battery usage during normal reading.

## Compatibility

SleepRibbon has been tested with:

- KOReader emulator based on v2026.07.2
- Kindle Colorsoft

Because SleepRibbon integrates with internal KOReader UI components, future KOReader changes may occasionally require compatibility updates.

When reporting a problem, please include the device model, KOReader version and SleepRibbon version whenever possible.

## License

SleepRibbon is released under the GNU Affero General Public License v3.0 (AGPL-3.0).

Parts of the sleep-screen rendering implementation are adapted from KOReader, which is also distributed under the AGPL-3.0 license.

See [LICENSE](LICENSE) for details.

## Credits

SleepRibbon is an unofficial plugin for [KOReader](https://github.com/koreader/koreader).

Book cover artwork shown in screenshots belongs to its respective copyright holders and is used here solely to demonstrate the plugin interface.
