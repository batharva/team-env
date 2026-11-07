# Team Ubuntu Environment

A shared Ubuntu 22.04 desktop that runs in Docker and opens in your browser.

**Includes:** XFCE desktop, Terminator, VS Code, ROS 2 Humble, Gazebo Harmonic, Python 3, build tools (gcc, cmake, gdb, git).

Everyone builds the same image from the same files, so the environment is identical on every machine.

---

## 1. Requirements

- **Docker** with the Compose plugin
  - Linux: `curl -fsSL https://get.docker.com | sh`
  - Windows: Docker Desktop with the WSL2 backend (extract this folder inside WSL, not on `C:\`)
  - macOS: Docker Desktop
- About **15 GB free disk space** and **8 GB RAM** recommended
- Internet connection for the first build

Check Docker works:

```bash
docker run hello-world
```

On Linux, prefix the commands below with `sudo` (or add yourself to the docker group: `sudo usermod -aG docker $USER`, then log out and in).

---

## 2. First-time setup

```bash
unzip team-env.zip
cd team-env
docker compose build
docker compose up -d
```

The first build takes **15 to 30 minutes** and downloads several GB (ROS 2 and Gazebo are large). Later builds reuse the cache and are much faster.

---

## 3. Open the desktop

1. Wait about 5 seconds after `up -d`.
2. Open **http://localhost:6080/vnc.html** in your browser.
3. Click **Connect**.
4. Password: **team1234**

The port is bound to `127.0.0.1`, so only your own machine can reach it.

---

## 4. Test the tools

Open **Terminator** (Applications menu) and run:

```bash
ros2 run demo_nodes_cpp talker     # ROS 2
gz sim shapes.sdf                  # Gazebo Harmonic
code .                             # VS Code
```

Gazebo uses software rendering (no GPU in a browser session). The first launch is slow and a black window for a short while is normal. Keep simulation scenes simple.

---

## 5. Your files

Put your work in the `workspace/` folder next to `docker-compose.yml`. It is the same folder as `~/workspace` inside the desktop.

- Files in `workspace/` **survive** stopping, removing and rebuilding the container.
- Anything installed with `apt` inside the running container is **lost** when the container is removed. If the whole team needs a tool, add it to the `Dockerfile` and rebuild.

---

## 6. Daily commands

Run **one** of these at a time (they are alternatives, not a script):

| Goal | Command |
|---|---|
| Start | `docker compose up -d` |
| Stop (keeps container) | `docker compose stop` |
| Start again after stop | `docker compose start` |
| Remove container (workspace files stay) | `docker compose down` |
| Shell inside the container | `docker exec -it team-dev bash` |
| Shell as root | `docker exec -it -u root team-dev bash` |
| View logs | `docker compose logs --tail 50 dev` |
| Rebuild after changing Dockerfile or start.sh | `docker compose build && docker compose up -d` |

Do not use `docker compose run dev`. It creates a separate throwaway container without the published port.

---

## 7. Customization

**Your own VNC password** (max 8 characters, VNC ignores the rest): create a file named `.env` next to `docker-compose.yml`:

```
VNC_PASSWORD=mypass12
```

Then run `docker compose up -d`.

**Screen size:** change `RESOLUTION: 1600x900` in `docker-compose.yml`.

**Different port:** change `"127.0.0.1:6080:6080"` to e.g. `"127.0.0.1:6081:6080"` and open port 6081.

---

## 8. Troubleshooting

| Problem | Fix |
|---|---|
| Page does not load | Run `docker compose ps`. Status must be `Up`. Check `docker compose logs dev`. |
| Container keeps restarting | Read the logs. On Windows, `start.sh` may have CRLF line endings: open it in VS Code, set the line ending to **LF**, save, rebuild. |
| `/start.sh: not found` | Same CRLF issue as above. |
| `port is already allocated` | Port 6080 is in use. Change the port as in section 7. |
| `Permission denied` in `workspace/` | Your Linux user ID is not 1000. Check with `id -u` and build with `docker compose build --build-arg UID=$(id -u)`. |
| Gazebo window black or crashes | Make sure `shm_size: "2gb"` is in `docker-compose.yml`. Try `gz sim -s` (server only) to isolate rendering problems. |
| `xauth: .Xauthority does not exist` in logs | Harmless first-run message. Ignore it. |
| Build fails while downloading packages | Check your internet connection and rerun `docker compose build`. Finished steps are cached. |
| Apple Silicon / ARM CPU | In the `Dockerfile`, change the three `arch=amd64` entries to `arch=arm64`. Some packages may not be available for ARM. |
| Out of disk space | `docker system df` to inspect, `docker builder prune` to clear the build cache. |

---

## 9. Security notes

- The default password `team1234` is shared. That is fine because the port is only reachable from your own machine.
- Do **not** change the port mapping to `0.0.0.0` or expose 6080 to the internet. If you need remote access, use an SSH tunnel:
  ```bash
  ssh -L 6080:localhost:6080 user@server
  ```
- The container user `dev` has passwordless `sudo`. This is intended for a local development container only.

---

## 10. Files in this folder

| File | Purpose |
|---|---|
| `Dockerfile` | Defines the image: Ubuntu, desktop, VNC, VS Code, ROS 2, Gazebo |
| `start.sh` | Starts the VNC server and the browser gateway when the container launches |
| `docker-compose.yml` | Ports, password default, shared memory, workspace mount |
| `.dockerignore` | Keeps `workspace/` and `.env` out of the build |
| `.gitattributes`, `.gitignore` | Only needed if this folder is put in Git |
| `workspace/` | Your files (persistent) |