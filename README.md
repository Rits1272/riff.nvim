# riff.nvim

Minimalistic Neovim plugin to stream songs straight without leaving the editor - searchable via Telescope, streamed with mpv, and controlled with simple commands. Minimal, fast, and theme‑agnostic.

https://github.com/user-attachments/assets/8f8d948f-6640-4dc7-a464-cd4f847a817d


## Features

* Search YouTube Music
* Instant audio streaming straight in vim
* Ability to create playlist [TODO]
* Ability to loop through recommended songs [TODO]
* Play songs as per suggestive of code in the file buffer [TODO]

## Requirements

* Neovim 0.8+
* nvim-telescope/telescope.nvim
* mpv in PATH
* yt-dlp in PATH

## Install

### **macOS**

```bash
brew install mpv yt-dlp
```

### **Linux (Debian/Ubuntu)**

```bash
# mpv
sudo apt update
sudo apt install mpv -y

# yt-dlp
sudo apt install python3-pip -y
pip3 install --upgrade yt-dlp
```

### **Windows**

* **mpv:** Download from [mpv.io](https://mpv.io/installation/) and add to your PATH.
* **yt-dlp:** Download the executable from [yt-dlp releases](https://github.com/yt-dlp/yt-dlp/releases) and add to your PATH.

---

### Lazy.nvim

```lua
{
  "rits1272/riff.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("riff").setup({
      ytdlp_cmd = "yt-dlp",
      status_echo_delay_ms = 10,
    })
  end,
}
```

### Packer.nvim

```lua
use {
  "rits1272/riff.nvim",
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("riff").setup({
      ytdlp_cmd = "yt-dlp",
      status_echo_delay_ms = 10,
    })
  end,
}
```

## Usage

* `:Riff <query>` – search and play a song
* `:RiffStop` – stop playback

Inside the Telescope picker:

* Press Enter in insert or normal mode on a selection to play it.

## Notes

This plugin is intentionally minimal. If you’d like richer UI, progress, or playlist support, open an issue or PR.

