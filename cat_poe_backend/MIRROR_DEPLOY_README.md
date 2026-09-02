# Mirror (Blue-Green) Deployment Guide

This guide explains how to use the new zero-downtime Blue-Green deployment system for the Catcoin PoE Backend.

## 🏗️ Architecture Overview

The system maintains two identical backend containers:
1.  **backend_blue** (serving traffic via `upstream.inc`)
2.  **backend_green** (idle or being updated)

Nginx acts as a reverse proxy, switching between these two "mirrors" without dropping requests.

## 🚀 How to Deploy

Instead of the old `deploy.sh`, use the new `mirror_deploy.sh` script:

```bash
# On the production server (your host / path)
cd /opt/catcoin-backend
chmod +x mirror_deploy.sh
./mirror_deploy.sh
```

### What the script does:
1.  **Detects Active Environment**: Reads `upstream.inc` to see which color is live.
2.  **Builds Inactive Mirror**: Builds the Docker image for the idle color.
3.  **Runs Migrations**: Runs Alembic and unified migration scripts against the new image (before switching traffic).
4.  **Starts Inactive Mirror**: Brings up the new container and waits for Docker health (`/health` inside the stack).
5.  **Switches Traffic**: Updates `upstream.inc` and reloads Nginx (`nginx -s reload`).
6.  **External check**: `curl`s `${PUBLIC_API_BASE}/health` (see below).
7.  **Decommissions Old Mirror**: Stops the old container when the external check succeeds.

**`PUBLIC_API_BASE`:** Optional in `.env.production` — public origin with **no** trailing slash (default `https://poe.catcoin.in`). Used for the post-switch health request and final `echo` lines. Set this when your API hostname differs (forks, staging).

## 🛠️ Configuration Files

-   **`docker-compose.prod.yml`**: Defines `backend_blue` and `backend_green`.
-   **`nginx.conf`**: Configured to include `upstream.inc` dynamically.
-   **`upstream.inc`**: A small file defining which container Nginx points to.

## 🔄 Rollback Plan

If a deployment succeeds but you find issues:
1.  Overwrite `upstream.inc` with the previous color:
    ```nginx
    upstream backend {
        server backend_blue:8000; # or backend_green
    }
    ```
2.  Reload Nginx:
    ```bash
    docker exec catcoin_nginx nginx -s reload
    ```
3.  Restart the old container if it was stopped:
    ```bash
    docker compose -f docker-compose.prod.yml start backend_blue
    ```

## ⚠️ Important Notes

-   **Migrations**: Database changes must be backward-compatible (e.g., adding a column is fine, renaming a column requires a multi-step release).
-   **Resource Usage**: During the transition, two backend containers run briefly. Ensure the server has at least 500MB of free RAM.

-   **Stopped color + nginx reload:** After a successful deploy, `mirror_deploy.sh` **stops** the *previous* backend container (see Step 9). `upstream.inc` must only reference a container that is **running** on `catcoin_network`. If `upstream.inc` points at `backend_green:8000` but green is stopped, `nginx -s reload` fails with **`host not found in upstream "backend_green:8000"`** because Docker DNS has no entry for that service. **Fix:** Point `upstream.inc` at the running color (e.g. `backend_blue:8000`), `docker compose -f docker-compose.prod.yml up -d backend_blue` if needed, then reload nginx. To prepare the idle color again: `docker compose -f docker-compose.prod.yml up -d backend_green` and fix its health before switching traffic.

-   **Testing from the nginx container:** `backend` in `proxy_pass http://backend` is an **nginx upstream name**, not a hostname. `curl http://backend/health` from a shell will **not** resolve. Use the Compose **service** name and port, e.g. `curl -sS http://backend_blue:8000/health` or `http://backend_green:8000/health`.

-   **`upstream.inc` is read-only in the container** (`docker-compose.prod.yml` mounts it as `:ro`). Edit the file on the **host** only; `docker exec … > /etc/nginx/conf.d/upstream.inc` will fail with *read-only file system*.

-   **Host vs container `upstream.inc` out of sync:** With a **single-file bind mount**, replacing the file on the host (delete + new file, some editors, or deploy tools) can leave the nginx container seeing an **old inode** while `cat` on the host shows the new text — compare `sha256sum ./upstream.inc` vs `docker exec catcoin_nginx sha256sum /etc/nginx/conf.d/upstream.inc`. If they differ, run `docker compose -f docker-compose.prod.yml up -d --force-recreate nginx`, then `nginx -t` and reload.

## 🔧 Troubleshooting

| Symptom | Likely cause |
|--------|----------------|
| `host not found in upstream "backend_*:8000"` on reload | `upstream.inc` names a color whose container is **stopped** or not on the same Docker network as nginx. |
| Public `502` while `curl` from nginx to `backend_blue:8000` returns `200` | Stale nginx config (reload failed earlier), wrong host, or traffic not hitting this server. |
| Different `sha256sum` for `upstream.inc` on host vs in `catcoin_nginx` | Stale bind-mount inode; **force-recreate** the nginx container (see Important Notes). |
| One color `unhealthy` | Check `docker logs catcoin_backend_<color>`; fix DB/env/migrations before switching traffic to that color. |
