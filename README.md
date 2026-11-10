<p align="center"><img src="art/banner.svg" width="100%" alt="An astronaut floating in space with an eclipse in the visor, holding an hourglass"></p>

<h1 align="center">Fuginaut</h1>

<p align="center">
  <a href="https://fuginaut.com"><img src="https://img.shields.io/badge/fuginaut.com-Download_for_Mac-ffad1a?style=for-the-badge&logo=apple&logoColor=black" alt="fuginaut.com: Download for Mac"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-black" alt="macOS 14 or later">
  <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift 6">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license">
</p>

<p align="center"><strong>A second clock at the center of the menu bar.</strong></p>

https://github.com/user-attachments/assets/b9d006a3-d3e7-4420-8428-9e54591b704d

On a wide monitor, Apple's clock sits in the far right corner, a long way from where you are
looking. Fuginaut puts a second clock at the center of the menu bar on every display, where a
glance finds it. Click it to open settings, or turn that off so clicks pass straight through.

The clock is meant for big screens. While an external display is connected, a laptop's own screen
starts with the clock off, and you can turn it on from General. A laptop on its own shows the
clock. On a screen with a notch, the clock slides beside the notch instead of hiding under it.

## Settings

Click the clock to open settings, or right-click the eclipse in the menu bar and pick Settings.
Every change shows in the live preview at the top and on the real clock right away.

Click the eclipse to turn the clock on and off. It glows amber while the clock is on and goes plain
while it is off.

- **Size:** how big the clock reads, and a nudge off the center of the bar.
- **Text:** the font (System, Rounded, Mono, Serif, or any installed family), its weight, and
  capitals as written, all caps, or lowercase.
- **Color:** the clock's color, matched to the menu bar or picked from a grid of swatches, a hex
  value, or the color wheel. A shadow or a pill behind the text keeps it readable over busy
  wallpaper, in a color that contrasts on its own or one you pick the same three ways.
- **Format:** sixteen date styles (short, long, day first, with the year, numeric, dotted, ISO,
  ISO week, day of year, and more) or a custom date pattern with examples and a menu of pattern
  letters. Switches show or hide the weekday, date, and time, and put the date or the time first,
  joined by spaces, a dot, a bar, a comma, a slash, a dash, or the word "at". The time can be 12-hour
  or 24-hour, with or without seconds, a leading zero, and PM, pm, or neither. Text or emoji can sit
  before and after the clock.
- **World:** the language of the day and month names, the digits (Western, Arabic-Indic, Persian,
  Devanagari, Bengali, Thai, and more), and the calendar (Gregorian, Islamic, Hebrew, Persian,
  Indian, Buddhist, Japanese, Chinese, and more). Other languages write the date and time in their
  own word order. A second time zone comes from a list you search by
  city, zone name, or UTC offset.
- **General:** whether the clock shows, which displays show it, whether clicking it opens settings or passes
  through, whether it stays up in full screen apps, the menu bar icon, and opening at login.

Fuginaut asks for no permissions and makes no network requests. It sends nothing at all. The Mac App
Store and Homebrew keep it current: the store updates it in place, and `brew upgrade --cask fuginaut`
does the same for the Homebrew install. The Mac App Store build runs in Apple's sandbox and opens at
login only after you turn that on in General.

## Install

With Homebrew:

```sh
brew install --cask dcadolph/tap/fuginaut
```

Or download `fuginaut_macos_universal.dmg` from the
[latest release](https://github.com/dcadolph/fuginaut/releases/latest), open it, and drag
Fuginaut to Applications. Releases are signed with a Developer ID and notarized by Apple.

## Verify a download

Each release carries `SHA256SUMS` with a keyless cosign signature and a build provenance
attestation.

```sh
cosign verify-blob SHA256SUMS --signature SHA256SUMS.sig --certificate SHA256SUMS.pem \
  --certificate-identity-regexp '^https://github.com/dcadolph/fuginaut/\.github/workflows/release\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
shasum -a 256 -c SHA256SUMS --ignore-missing
gh attestation verify fuginaut_macos_universal.dmg --repo dcadolph/fuginaut
```

## Build from source

Requires macOS 14 or later and Xcode 16 or later.

```sh
make test     # run the tests
make run      # build the app, stop any running copy, and open the new one
make sandbox  # build the Mac App Store flavor under its sandbox, ready to run locally
```

## License

MIT. See [LICENSE](LICENSE).
