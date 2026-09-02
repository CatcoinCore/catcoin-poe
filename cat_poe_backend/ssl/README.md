# TLS certificates (not committed)

Place your own certificate material here for nginx or local HTTPS testing:

- `fullchain.pem` — full certificate chain  
- `privkey.pem` — private key  

**Never commit real keys.** Generate with your CA (for example Let’s Encrypt / certbot) or local dev tools, then mount this directory into the container as described in `docs/self-hosting.md`.

If these files are missing, nginx will exit on start (`cannot load certificate`). For a **local self-signed pair** (dev/staging only), from `cat_poe_backend` run:

```bash
chmod +x generate_dev_ssl.sh && ./generate_dev_ssl.sh
```
