# Team Ubuntu Environment

A shared **Ubuntu 22.04 desktop that runs in Docker and opens in your web browser**. Everyone builds it from the same files, so every teammate gets the identical setup on **Windows, Linux or macOS**.

**Includes:** XFCE desktop, Terminator, VS Code, ROS 2 Humble, Gazebo Harmonic, Python 3, build tools (gcc, cmake, gdb, git).

---

## Quick start

| Step | Windows | Linux |
|---|---|---|
| 1. Install Docker | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (keep **WSL 2** ticked), restart, open it | `curl -fsSL https://get.docker.com \| sh` then `sudo usermod -aG docker $USER` and **log out/in** |
| 2. Get the files | `git clone https://github.com/batharva/team-env.git` | `git clone https://github.com/batharva/team-env.git` |
| 3. Build (once) | `cd team-env` then `docker compose build` | `cd team-env` then `docker compose build` |
| 4. Start | `docker compose up -d` | `docker compose up -d` |
| 5. Open | http://localhost:6080/vnc.html | http://localhost:6080/vnc.html |

Click **Connect**. Password: **team1234**

The first build takes **15 to 30 minutes** and downloads several GB. Later builds are much faster.

---

## 1. Requirements

- 15 GB free disk space, 8 GB RAM recommended
- Internet connection for the first build
- Git (to clone) or download the repo as a ZIP from GitHub (**Code > Download ZIP**)

---

## 2. Windows setup (detailed)

1. **Enable virtualization** in BIOS if Docker Desktop complains (look for "Intel VT-x" or "AMD-V"/"SVM").
2. **Install Docker Desktop** from docker.com. Keep **"Use WSL 2 instead of Hyper-V"** ticked. Restart when asked.
3. Open Docker Desktop and wait until it says **Engine running** (bottom-left, green).
4. **Install Git** from https://git-scm.com/download/win if you don't have it.
5. Open **PowerShell** (or Windows Terminal) and run:
   ```powershell
   cd $HOME\Documents
   git clone https://github.com/batharva/team-env.git
   cd team-env
   docker compose build
   docker compose up -d
   docker compose ps
   ```
6. Open http://localhost:6080/vnc.html, click **Connect**, password `team1234`.

**Better performance (recommended):** use the WSL Ubuntu terminal instead of PowerShell. Run `wsl --install -d Ubuntu` once in an admin PowerShell, reboot, open "Ubuntu" from the Start menu, and do the clone/build/up steps there under `~/team-env`. Files inside the WSL filesystem are much faster than files under `C:\`. In Docker Desktop, enable **Settings > Resources > WSL Integration > Ubuntu**.

**Line-ending warning:** `start.sh` must use LF line endings. The repo's `.gitattributes` handles this automatically when you use `git clone`. If you downloaded a ZIP and edited `start.sh` in Notepad, open it in VS Code, click `CRLF` at the bottom-right, switch to `LF`, save, then rebuild.

---

## 3. Linux setup (detailed)

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and log in again, then verify:
docker run hello-world

# Get and run the environment
git clone https://github.com/batharva/team-env.git
cd team-env
docker compose build
docker compose up -d
docker compose ps
```

If you skipped the `usermod` step or didn't log out and in, put `sudo` in front of every `docker` command.

**Different user ID:** the container user has UID 1000, which matches the first user on most systems. Check with `id -u`. If yours is different, build with:
```bash
docker compose build --build-arg UID=$(id -u)
```

---

## 4. Test that everything works

Open **Terminator** from the Applications menu inside the browser desktop and run:

```bash
ros2 run demo_nodes_cpp talker     # ROS 2 (Ctrl+C to stop)
gz sim shapes.sdf                  # Gazebo Harmonic
code .                             # VS Code
```

Gazebo uses software rendering (no GPU in a browser session). The first launch is slow and a black window for a while is normal. Keep scenes simple.

---

## 5. Your files

Put your work in the **`workspace/`** folder inside `team-env`. It appears as `~/workspace` in the desktop.

- Files in `workspace/` **survive** stop, remove and rebuild.
- Software you install with `apt` inside the container is **lost** when the container is removed. If the whole team needs a tool, add it to the `Dockerfile` and rebuild.

---

## 6. Daily commands

Run **one at a time** (they are alternatives, not a script). Same on Windows and Linux; add `sudo` on Linux if needed.

| Goal | Command |
|---|---|
| Start | `docker compose up -d` |
| Stop (keeps container) | `docker compose stop` |
| Start again after stop | `docker compose start` |
| Remove container (workspace stays) | `docker compose down` |
| Logs | `docker compose logs --tail 50 dev` |
| Shell inside container | `docker exec -it team-dev bash` |
| Shell as root | `docker exec -it -u root team-dev bash` |
| Rebuild after changing Dockerfile or start.sh | `docker compose build` then `docker compose up -d` |
| Get the latest version from GitHub | `git pull` then rebuild as above |

Don't use `docker compose run dev`. It creates a separate container without the port published.

---

## 7. Customization

**Your own VNC password** (max 8 characters; VNC ignores the rest). Create a file named `.env` next to `docker-compose.yml`:

```
VNC_PASSWORD=mypass12
```

Then run `docker compose up -d`.

**Screen size:** change `RESOLUTION: 1600x900` in `docker-compose.yml`.

**Different port:** change `"127.0.0.1:6080:6080"` to `"127.0.0.1:6081:6080"` and browse to port 6081.

---

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| `docker: command not found` (Windows) | Open Docker Desktop and wait for "Engine running". Reopen the terminal. |
| `error during connect` / `cannot connect to the Docker daemon` | Docker is not running. Start Docker Desktop (Windows) or run `sudo systemctl start docker` (Linux). |
| `permission denied ... docker.sock` (Linux) | Use `sudo`, or run the `usermod` step and log out/in. |
| Page does not load | Run `docker compose ps`. Status must be `Up`. Check `docker compose logs dev`. |
| Container keeps restarting | Read the logs. Check `start.sh` uses LF line endings (see Windows section). |
| `/start.sh: not found` | CRLF line endings. Fix as described in the Windows section, then rebuild. |
| `port is already allocated` | Port 6080 is in use. Change the port (section 7). |
| `Permission denied` in `workspace/` | Your Linux UID is not 1000. Rebuild with `--build-arg UID=$(id -u)`. |
| Gazebo black window or crash | Check `shm_size: "2gb"` is in `docker-compose.yml`. Try `gz sim -s` to isolate rendering problems. |
| `xauth: .Xauthority does not exist` in logs | Harmless first-run message. Ignore it. |
| Build fails while downloading | Check your internet and rerun `docker compose build`. Finished steps are cached. |
| Docker Desktop says WSL 2 is missing (Windows) | Run `wsl --update` in an admin PowerShell, then restart Docker Desktop. |
| Out of disk space | `docker system df` to inspect, `docker builder prune` to clear the build cache. |
| Apple Silicon / ARM CPU | In the `Dockerfile` change the three `arch=amd64` entries to `arch=arm64`. Some packages may not exist for ARM. |

---

## 9. Security notes

- The default password `team1234` is shared. That is fine because the port is bound to `127.0.0.1`, so only your own machine can connect.
- Do **not** change the port mapping to `0.0.0.0` or expose 6080 to the internet. For remote access, use an SSH tunnel:
  ```bash
  ssh -L 6080:localhost:6080 user@server
  ```
- The container user `dev` has passwordless `sudo`. This is intended for a local development container only.

---

## 10. What's in this repo

| File | Purpose |
|---|---|
| `Dockerfile` | Defines the image: Ubuntu, desktop, VNC, VS Code, ROS 2, Gazebo |
| `start.sh` | Starts the VNC server and browser gateway when the container launches |
| `docker-compose.yml` | Port, password default, shared memory, workspace mount |
| `.dockerignore` | Keeps `workspace/` and `.env` out of the build |
| `.gitattributes` | Forces LF line endings so `start.sh` works on Windows |
| `.gitignore` | Keeps your `.env` and workspace files out of Git |
| `setup-commands.txt` | Plain-text copy of the setup commands |
| `workspace/` | Your files (persistent) |

---

## Updating the environment (maintainers)

```bash
# edit Dockerfile / start.sh, then:
git add .
git commit -m "Describe the change"
git push
```

Teammates run `git pull`, `docker compose build`, `docker compose up -d`.
