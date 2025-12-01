## Ytb-Playlist-Downloader

Small Bash helpers to download and organize YouTube Music playlists with yt-dlp, then compress the results.

## How to Use (Bash)

The primary action for a working setup is running the downloader script.

1)  Put your YouTube Music playlist URLs in `links.json`.
2)  **Activate the virtualenv** each session:

<!-- end list -->

```bash
source .venv/Scripts/activate   # on Windows Git Bash
source .venv/bin/activate       # on WSL/Linux/macOS
```

3)  **Run the downloader**:

<!-- end list -->

```bash
bash download-playlists.sh
```

   Check `download_errors.json` for any failed items; rerun the suggested command if needed.
4\) When satisfied with the downloads, **compress everything** (optional):

```bash
bash compress-playlists.sh
```

   ZIPs will be collected in `compacted-folder/`.

-----

## Setup (Command Order)

Follow these steps in order to set up your environment (run from the project root):

1)  Create the virtualenv (once):

<!-- end list -->

```bash
python -m venv .venv
```

2)  Install Python deps:

<!-- end list -->

```bash
pip install -r requirements.txt
```

3)  Ensure system tools are installed and on PATH: `ffmpeg`, `ffprobe`, `deno` (or `node`/`bun`), `jq`, `7z`.

**Workflow:** add playlist links to `links.json`, activate the venv, run `download-playlists.sh`, check `download_errors.json`, and optionally zip results with `compress-playlists.sh`.

-----

## Dependencies

  - Bash shell (Git Bash/WSL/Unix) to run the scripts
  - Python 3.10+ with a virtualenv at `.venv` and `pip install -r requirements.txt`
  - `yt-dlp` + `yt-dlp-ejs` (needs a JS runtime such as `deno`, `node`, or `bun` for YouTube cipher solving)
  - `ffmpeg`/`ffprobe` for audio merging, embedding metadata, and thumbnails
  - `jq` for reading the playlist list from JSON
  - `7z` for creating ZIP archives

-----

## Files and Purpose

  - `links.json`: Holds the playlist URLs to download (`{"links": ["url1", ...]}`).
  - `download-playlists.sh`: Main downloader.
      - Activates `.venv`, reads playlists from `links.json`, and queries each title with `yt-dlp -J --flat-playlist`.
      - Creates/sanitizes a folder per playlist (reuses it if it already exists).
      - Downloads all tracks with `yt-dlp -t mp3 --embed-metadata --embed-thumbnail --download-archive downloaded_archive.txt`, so previously grabbed items are skipped.
      - On failure, appends details to `download_errors.json` with the playlist link, folder name, last error, and a manual retry command.
  - `compress-playlists.sh`: Archiver.
      - Zips every subfolder (except `.venv` and `compacted-folder`) using `7z a -tzip -r`.
      - Moves the generated ZIPs into `compacted-folder/`.

-----

## Handling Errors (`download_errors.json`)

  - On failures, entries are appended with:
      - `link`: playlist URL attempted
      - `playlist`: folder name used locally
      - `error_message`: last yt-dlp error line
      - `download`: suggested manual command
  - Manual retry in Bash (copy the `download` value):

<!-- end list -->

```bash
yt-dlp -t mp3 --embed-metadata --embed-thumbnail "https://music.youtube.com/watch?v=VIDEO_ID"
```

  - If the retry command still fails, open the playlist URL from `link` in a browser, grab the current/working video URL, then rerun the same yt-dlp command with that updated link (sometimes the stored URL is outdated).