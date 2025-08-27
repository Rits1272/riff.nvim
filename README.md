# riff.nvim

Search and stream songs right inside your editor — discoverable with Telescope, played through mpv, and managed with simple commands. Fast, minimal, and theme-agnostic.

https://github.com/user-attachments/assets/8f8d948f-6640-4dc7-a464-cd4f847a817d


## Features

* Search YouTube Music
* Instant streaming through mpv (audio‑only)
* Queue - add/edit/play songs to queue persisted locally

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
```

Follow installation steps for `yt-dlp` from [here](https://github.com/yt-dlp/yt-dlp/wiki/Installation)

### **Windows**

* **mpv:** Download from [mpv.io](https://mpv.io/installation/) and add to your PATH.
* **yt-dlp:** Download the executable from [yt-dlp releases](https://github.com/yt-dlp/yt-dlp/releases) and add to your PATH.

---

### Lazy.nvim

```lua
{
  "rits1272/riff.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
      ytdlp_cmd = "yt-dlp",
      status_echo_delay_ms = 10,
  },
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

* `:Riff <query>` – search and queue/play a song
* `:RiffQueue` – check queue and add/edit/play songs
* `:RiffPause` – check queue and add/edit/play songs
* `:RiffResume` – check queue and add/edit/play songs
* `:RiffQueueNext` – play next song in the queue or if queue is exhaused, auto-play next song
* `:RiffQueueShuffle` – shuffle queue
* `:RiffQueueClear` – remove all songs from queue
* `:RiffStop` – stop playback

Inside the Telescope picker:

* Press Enter in insert or normal mode on a selection to play it.

## Notes
- This plugin is intentionally minimal. If you’d like richer UI, progress, or playlist support, open an issue or PR.
- plugin uses `yt-dlp` internally to fetch audio stream from YT. YT sometimes may block downloading audio streamings to yt-dlp

