# riff.nvim

Play YouTube Music straight from Neovim – searchable via Telescope, streamed with mpv, and controlled with simple commands. Minimal, fast, and theme‑agnostic.

## Features
- Search YouTube Music (via Python helper and ytmusicapi)
- Instant streaming through mpv (audio‑only)
- Get suggestive songs on basis of given file buffer [TODO]

## Requirements
- Neovim 0.8+
- nvim-telescope/telescope.nvim
- mpv in PATH
- yt-dlp in PATH
- Python 3 with ytmusicapi
  - Install: `pip3 install ytmusicapi`

## Install

### Lazy.nvim
```lua
{
  "rits1272/riff.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("riff").setup({
      -- optional overrides
      mpv_socket = "/tmp/nvim-mpv.sock",
      ytdlp_cmd = "yt-dlp",
      python_cmd = "python3",
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
      mpv_socket = "/tmp/nvim-mpv.sock",
      ytdlp_cmd = "yt-dlp",
      python_cmd = "python3",
      status_echo_delay_ms = 10,
    })
  end,
}
```

## Usage
- `:Riff <query>` – search and play a song
- `:RiffStop` – stop playback

Inside the Telescope picker:
- Press Enter in insert or normal mode on a selection to play it.

## How it works
- A tiny Python helper (`plugins/music.py`) searches YouTube Music using `ytmusicapi` and returns JSON to Neovim.
- The Telescope picker lists results; selecting an item starts mpv with audio‑only playback using the best audio stream URL fetched via `yt-dlp`.
- Previous mpv instances are stopped automatically before starting a new one.
- A short status message with the current track title is echoed in the command area.

## Notes
This plugin is intentionally minimal. If you’d like richer UI, progress, or playlist support, open an issue or PR.
