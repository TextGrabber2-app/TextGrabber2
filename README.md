<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/TextGrabber2-app/TextGrabber2/main/Icon.png" width="96">
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/TextGrabber2-app/TextGrabber2/main/Icon-dark.png" width="96">
  <img src="./Icon.png" width="96">
</picture>

# TextGrabber2

[![](https://img.shields.io/badge/Platform-macOS_15.0+-blue?color=007bff)](https://github.com/TextGrabber2-app/TextGrabber2/releases/latest)  [![](https://github.com/TextGrabber2-app/TextGrabber2/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/TextGrabber2-app/TextGrabber2/actions/workflows/build.yml)

TextGrabber2 is a free and **open-source** macOS menu bar app that efficiently [detects text](https://github.com/TextGrabber2-app/TextGrabber2/wiki#capture-screen-on-mac) from copied images, and [runs actions](https://github.com/TextGrabber2-app/TextGrabber2/wiki#connect-to-system-services) based on it. This eliminates the need to save images as files and then delete them solely for the purpose of text detection.

<img src="./Screenshots/01.png" width="360" alt="Screenshot 01"> <img src="./Screenshots/02.png" width="360" alt="Screenshot 02">

> [!TIP]
> Discover our other free and open-source apps at [libremac.github.io](https://libremac.github.io/).

For example, press `Control-Shift-Command-4` to capture a portion of the screen and then open TextGrabber2 from the menu bar. It also functions effectively for any form of image copying.

You can also use TextGrabber2 to automatically prune your pasteboard data. See [Content Filters](https://github.com/TextGrabber2-app/TextGrabber2/wiki#content-filters) for more details.

In macOS Tahoe and later, you can directly extract text from copied images using Spotlight, through the action called `Extract Text from Copied Image`.

See the [wiki](https://github.com/TextGrabber2-app/TextGrabber2/wiki) for more details and usage examples.

> [!NOTE]
>
> Note that keyboard shortcuts can be remapped (and it's recommended since pressing 4 keys is a bit clunky). Please check out Apple's [documentation](https://support.apple.com/guide/mac-help/mchlp2271/mac) for details.
>
> Learn more [here](https://github.com/TextGrabber2-app/TextGrabber2/wiki#capture-screen-on-mac).
>
> For information on pasteboard access issues in macOS 15.4 and later, please refer to our [wiki](https://github.com/TextGrabber2-app/TextGrabber2/wiki#limited-access).

## Installation

Get `TextGrabber2.dmg` from the <a href="https://github.com/TextGrabber2-app/TextGrabber2/releases/latest" target="_blank">latest release</a>, open it and drag `TextGrabber2.app` to `Applications`.

<img src="./Screenshots/03.png" width="540" alt="Install TextGrabber2">

> TextGrabber2 checks for updates automatically. However, it's worth noting that updates will likely be infrequent, typically limited to bug fixes.
>
> Older builds: [macos-13](https://github.com/TextGrabber2-app/TextGrabber2/releases/tag/macos-13), [macos-14](https://github.com/TextGrabber2-app/TextGrabber2/releases/tag/macos-14).

## Why TextGrabber2

TextGrabber2 is NOT a screenshot tool, meaning it doesn't require access like `Screen Recording` or `Accessibility`. It relies on the keyboard shortcuts you use daily.

TextGrabber2 utilizes the built-in [Vision](https://developer.apple.com/documentation/vision/) framework, which is on-device, secure, fast, accurate, and **free**. In fact, it's often superior to many paid services.

TextGrabber2 connects to [system services](https://github.com/TextGrabber2-app/TextGrabber2/wiki#connect-to-system-services), you can easily integrate your workflows.

TextGrabber2 does NOT have any settings; it works magically until something goes wrong.

It's simple, privacy-oriented, brutal and beautiful.

## Where is TextGrabber1

TextGrabber1 does not exist; the "2" in TextGrabber2 does not indicate a version number.

Here's the thing, there was a discontinued app called TextGrabber that I used a decade ago, I quite liked it.

When initiating this project, I couldn't think of a better name than TextGrabber, so I decided to name it:

**TextGrabber** *"too"*.
