<div style="display: flex; align-items: center;">
  <img src="https://github.com/bloomingchad/pnimrp/raw/main/web/ico.ico" alt="pnimrp Icon" width="90" style="margin-right: 10px;" />
  <h1>♪♫ pnimrp - Poor Man's Radio Player in Nim ♫♪</h1>
</div>

sick of opening Chrome just to stream some music?
I made this little terminal radio player that's saved me tons of RAM.

With a collection of **30+ modifiable radio station genres** (JSON),
you can browse, play, pause, and mute your favorite stations—all from
the comfort of your terminal. No more fiddling with PLS files! 🚀

Inspired by [Poor Man's Radio Player](https://github.com/hakerdefo/pmrp),
**pnimrp** takes things to the next level with added features and
improvements.

## 🎥 Demo

![pnimrp Demo](https://github.com/bloomingchad/pnimrp/raw/main/web/demo.gif)
made with ![asciinema](https://asciinema.org/)

## 🌟 Key Features

- **Portable**: Works seamlessly on Unix and Windows. 📦
- **Easy to Use**: Simple menu-driven interface. 💡🎮
- **Modifiable Stations**: Edit JSON files to add or remove stations.🔧
- **Now Playing**: Displays the currently playing song.📻
- **Lightweight**: Minimal dependencies, fast and efficient.⚡
- **Customizable Themes**: Easily switch between themes by editing `config.json`. 🎨

## 🚀 Installation

### Step 1: Install **mpv** with development files for your distribution.

### Step 1: Install **mpv** (including development files)

**pnimrp** uses `mpv` for audio playback.  Install both the `mpv` player *and*
  its development files

**Linux:**

*   **Debian/Ubuntu:**      `sudo apt install mpv libmpv-dev`
*   **Fedora/CentOS/RHEL:** `sudo dnf install mpv mpv-devel` (may need [RPM Fusion](https://rpmfusion.org/))
*   **Arch Linux:**         `sudo pacman -S mpv` (includes development headers)
*   **openSUSE:**           `sudo zypper install mpv libmpv-devel`
*   **Other Distros:** Use your package manager; search for "mpv" and a related "dev/devel/headers" package.

**Windows:**

1.  Download `mpv` *and* the matching `dev.7z` from [mpv.io](https://mpv.io/installation/) or [SourceForge](https://sourceforge.net/projects/mpv-player-windows/files/) (x86_64 usually).
2.  Extract both. The `dev` archive has `libmpv-2.dll` (name may vary).
3.  **Important:** After compiling `pnimrp`, copy `libmpv-2.dll` to the *same directory* as `pnimrp.exe`.

**macOS X:**
*   **Homebrew (Recommended):** `brew install mpv`
*    **MacPorts:** `sudo port install mpv`

**FreeBSD:**
`sudo pkg install mpv`

**Termux (Android):**
```pkg install mpv```

### Step 2: Install the Nim compiler:

- **Unix**:
  ```bash
  curl https://nim-lang.org/choosenim/init.sh -sSf | sh
  ```
note this wouldnt work on termux, instead do
**Termux (Android):**
```pkg install nim```

- **Windows**:
  Download the latest release from [choosenim](https://github.com/dom96/choosenim/releases).
- **Other Distros**:
  Follow the official [Nim installation guide](https://nim-lang.org/install.html).

### Step 3: Install **pnimrp**:
```bash
nimble install pnimrp
```

Or compile it manually:
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

## 🎮 Controls

| Key          | Action                      |
| ------------ | --------------------------- |
| **1-9, a-l** | Select menu options         |
| **R**        | Return to the previous menu |
| **Q**        | Quit the application        |
| **P**        | Pause/resume playback       |
| **M**        | Mute/unmute                 |
| **+**        | Increase volume             |
| **-**        | Decrease volume             |

## 📖 Documentation

For detailed usage instructions, see:
- 📄 **doc/user.md**: User guide.
- 📄 **doc/installation.md**: Installation instructions.

🤝 Contributing

We welcome contributions! Here’s how you can help:

1. **Report Bugs**: Open an issue on GitHub.
2. **Suggest Features**: Share your ideas for new features.
3. **Submit Pull Requests**: Fix bugs or add new functionality.

Please read our [Contributing Guidelines](CONTRIBUTING.md) for more details.

## 📜 License

**pnimrp** is primarily licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.
See the [LICENSE](LICENSE) file for details.

However, the following component is licensed with their respective original licences:
- **illwill.nim**: Adapted from [illwill](https://github.com/johnnovak/illwill),
  this file is used for non-blocking input handling and is licensed under the WTFPL.

- **jsmn.nim**: See More [jsmn.nim](https://github.com/OpenSystemsLab/jsmn.nim)
  this file is under original licence which is MIT.

For more information about the WTFPL, see: [WTFPL License](http://www.wtfpl.net/).
  The original license text is included in the file.

## 🙏 Credits

- **pmrp**: Inspiration and initial codebase.💡
- **libmpv**: Playback functionality.📻
- **c2nim**: Wrapping objects.
- **illwill**: Async input handling.
- **jsmn.nim**: minimal json parser impl.
- **GPT-3.5 Claude-3.5-Sonnet**: Documentation and code improvements.🤖
- **DeepSeek-V3**: Documentation and Code improvements 🥰
- **fmstream.org and others**: for providing links
- **asciinema**: for being able to show HD demo 🎥
- **You**: For using and supporting this project! ❤️

## 🎉 Happy Listening!

Thank you for using **pnimrp**! If you enjoy the project, consider giving
it a ⭐ on GitHub or sharing it with your friends.
Let’s make terminal radio awesome! 🎶
