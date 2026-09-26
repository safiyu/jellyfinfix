# JellyfinFix

JellyfinFix automatically manages .ignore files inside your media libraries. It places .ignore files in directories that do not contain video media so Jellyfin skips indexing empty or non-video folders, and automatically removes .ignore files when video media is added.

It supports real-time filesystem event monitoring, event debouncing, single-process mutex locking, and automatic Jellyfin library refresh API triggers.

## Features

- Real-Time Filesystem Monitoring (inotify): Triggers scans instantly when video files are created, deleted, or moved inside your mounted /media volume.
- Smart Event Debouncing: Configurable quiet window (DEBOUNCE_SECONDS) ensures file downloads or copies complete before initiating scans.
- Single-Process Mutex Locking (flock): Enforces strict sequential processing. Concurrent filesystem events or cron triggers wait in a queue for running scans to finish.
- High-Performance Early-Exit Scanning: Uses early-exit folder searching (head -n 1) to minimize disk read operations on large libraries.
- Metadata & Image Filtering: Ignores .trickplay folders, .nfo metadata, subtitle files, cover images, and hidden system directories (.git, @eaDir).
- Secure API Integration: Automatically redacts API keys from container logs and sends standard Jellyfin authentication headers (Authorization: MediaBrowser Token="...", X-Emby-Token).
- Non-Root Container: Runs under an unprivileged user (jellyfix) inside an Alpine 3.21 base image.

## Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| MODE | watch | Execution mode: watch (real-time inotify), cron (scheduled), or both (real-time + fallback cron). |
| DEBOUNCE_SECONDS | 10 | Quiet time (in seconds) to wait after a video file change before triggering scan. |
| CRON_STRING | 0 */6 * * * | Cron schedule string (used when MODE=cron or MODE=both). |
| JF_URL | (optional) | Base URL of your Jellyfin server (e.g. http://192.168.1.100:8096). |
| JF_API_KEY | (optional) | Jellyfin API key generated from Jellyfin Dashboard -> API Keys. |
| TZ | Europe/Paris | Container timezone. |

## Quick Start

### Docker Compose (Recommended)

```yaml
services:
  jellyfinfix:
    container_name: jellyfix
    image: safiyu/jellyfinfix:latest
    volumes:
      - /path/to/media:/media:rw
    environment:
      - MODE=watch
      - DEBOUNCE_SECONDS=10
      - CRON_STRING=0 */6 * * *
      - JF_URL=http://192.168.1.100:8096
      - JF_API_KEY=your_jellyfin_api_key_here
      - TZ=Europe/Paris
    restart: always
```

### Docker CLI

```bash
docker run -d \
  --name jellyfix \
  -v /path/to/media:/media:rw \
  -e MODE=watch \
  -e DEBOUNCE_SECONDS=10 \
  -e JF_URL=http://192.168.1.100:8096 \
  -e JF_API_KEY=your_jellyfin_api_key_here \
  safiyu/jellyfinfix:latest
```

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
