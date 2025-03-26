<div style="display: flex; align-items: center;">
  <img src="https://github.com/bloomingchad/pnimrp/raw/main/web/ico.ico" alt="pnimrp Icon" width="90" style="margin-right: 10px;" />
  <h1>♪♫ pnimrp - Poor Man's Radio Player in Nim ♫♪</h1>
</div>

sick of opening chrome just to stream some internet radio?
i made this little terminal radio player that's saved me tons of ram

with a collection of **30+ modifiable radio station genres** (json),
you can play your favorite stations—all from the comfort of your terminal

no more fiddling with pls files

inspired by [poor man's radio player](https://github.com/hakerdefo/pmrp),
**pnimrp** aims to extend pmrp whilst keeping familiarity.

## 🎥 demo

![pnimrp demo](https://github.com/bloomingchad/pnimrp/raw/main/web/demo.gif)

made with [asciinema](https://asciinema.org/)

## 🌟 key features

- **portable**: works on unix and windows
- **easy to use**: simple intuitive interface
- **curatable stations**: edit json files to add or remove stations easily
- **now playing**: displays the currently playing song
- **lightweight**: minimal dependencies, fast and efficient
- **customizable themes**: easily switch between themes by editing `config.json`
- **checked links**: links get checked automatically so you dont waste your time.

## ⬇️  installation

  ```bash
  curl https://raw.githubusercontent.com/bloomingchad/pnimrp/main/init.sh | bash
  ```


### step 1: install **mpv** (might need development build/files)

**pnimrp** uses `mpv` for audio playback.  install both the `mpv` player *and*
  its development files

**Linux:**

*   **Debian/Ubuntu:**      `sudo apt install mpv libmpv-dev`
*   **Fedora/CentOS/RHEL:** `sudo dnf install mpv mpv-devel` (may need [RPM Fusion](https://rpmfusion.org/))
*   **Arch Linux:**         `sudo pacman -S mpv` (includes development headers)
*   **openSUSE:**           `sudo zypper install mpv libmpv-devel`
*   **other distros:** Use your package manager; search for "mpv" and a related "dev/devel/headers" package.

**Windows:**

1.  download `mpv` *and* the matching `*dev.7z` from [mpv.io](https://mpv.io/installation/) or [sourceforge](https://sourceforge.net/projects/mpv-player-windows/files/) (x86_64 usually).
2.  extract both. the `dev` archive has `libmpv-2.dll` (name may vary).
3.  **important:** after compiling `pnimrp`, copy `libmpv-2.dll` to the *same directory* as `pnimrp.exe`.

**macOS X:**
*   **Homebrew (Recommended):** `brew install mpv`
*    **MacPorts:** `sudo port install mpv`

**FreeBSD:**
`sudo pkg install mpv`

**Termux (Android):**
```pkg install mpv```

### step 2: install the nim compiler:

- **unix**:
  ```bash
  curl https://nim-lang.org/choosenim/init.sh -sSf | sh
  ```
note this wouldnt work on termux, instead do
**Termux (Android):**
```pkg install nim```

- **Windows**:
  download the latest release from [choosenim](https://github.com/dom96/choosenim/releases).
- **other distros**:
  follow the official [nim installation guide](https://nim-lang.org/install.html).

### step 3: install **pnimrp**:
```bash
nimble install pnimrp
```

or compile it manually:
```bash
nim c -d:release pnimrp
./pnimrp
```
want a simple build? (very minimal):
```bash
nim c -d:release -d:simple pnimrp
```

cant/dont want emojis?: add `-d:noEmoji`

want to use smaller bin size?: add `-d:useJsmn`

## 🎮 controls

| key          | action                      |
| ------------ | --------------------------- |
| **1-9, a-m** | select menu options         |
| **r**        | return to the previous menu |
| **q**        | quit the application        |
| **p**        | pause/resume playback       |
| **m**        | mute/unmute                 |
| **+**        | increase volume             |
| **-**        | decrease volume             |

## 📖 documentation

for detailed usage instructions, see:
- 📄 **doc/user.md**: user guide.
- 📄 **doc/installation.md**: installation instructions.

## 🤝 contributing

here is how you can help:

1. **submit pull requests**: fix bugs you found or propose and add new functionality.

please read our [Contributing Guidelines](CONTRIBUTING.md) for more details.

## 📜 license

**pnimrp** is primarily licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.
see the [LICENSE](LICENSE) file for details.

however, the following component is licensed with their respective original licences:
- **illwill.nim**: adapted from [illwill](https://github.com/johnnovak/illwill),
  this file is used for non-blocking input handling and is licensed under the WTFPL.

- **jsmn.nim**: See More [jsmn.nim](https://github.com/OpenSystemsLab/jsmn.nim)
  this file is under original licence which is MIT.

for more information about WTFPL, see: [WTFPL License](http://www.wtfpl.net/).
  the original license text is included in the file.

## 🙏 credits

- **pmrp**: inspiration and initial codebase 💡
- **libmpv**: playback functionality
- **c2nim**: wrapping objects
- **illwill**: async input handling
- **jsmn.nim**: minimal json parser impl
- **GPT-3.5 Claude-3.5-Sonnet**: documentation and code improvements
- **DeepSeek-V3**: documentation and Code improvements 🥰
- **fmstream.org and others**: for providing links
- **asciinema**: for being able to show HD demo 🎥
- **you**: for using and supporting this project! ❤️

## 🎶 happy listening!

thank you for using **pnimrp**. please do share it with your minimalist friends
